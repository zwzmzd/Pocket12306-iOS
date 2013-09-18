//
//  TDBOrderListViewController.m
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBOrderListViewController.h"
#import "TFHpple.h"
#import "TDBSession.h"
#import "GlobalDataStorage.h"
#import "TDBOrder.h"
#import "TDBOrderDetailViewController.h"
#import "TDBOrderOperationViewController.h"
#import "SVProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "SVPullToRefresh.h"

@interface TDBOrderListViewController ()

@property (nonatomic) NSMutableArray *orderList;
@property (nonatomic, copy) NSString *apacheToken;

@property (nonatomic) BOOL refreshProcessEnable;

@end

@implementation TDBOrderListViewController

- (ORDER_PARSER_MSG)parseHTMLWithData:(NSData *)htmlData toList:(NSMutableArray *)tempList
{
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
    
    self.apacheToken = [self parseApacheToken:xpathParser];
    
    {
        NSArray *elements = [xpathParser searchWithXPathQuery:@"//title"];
        if (elements.count == 0) {
            return ORDER_PARSER_MSG_ERR;
        }
        
        TFHppleElement *e = elements.lastObject;
        if (![[e.firstChild content] isEqualToString:@"我的订单"]) {
            return ORDER_PARSER_MSG_ERR;
        }
    }
    
    {
        NSArray *elements = [xpathParser searchWithXPathQuery:@"//table[@class='table_clist']"];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        for (TFHppleElement *table in elements) {
            // every order
            TDBOrder *order = [[TDBOrder alloc] init];
            
            NSArray *tableChildren = [table children];
            NSUInteger count = tableChildren.count;
            
            // table下面的每个<tr>对应一位乘客，但在table和tr之间有很多无用信息，需要先跳过
            // 另外表格中的第1个<tr>是表格的头部信息，并无用处，一并跳过
            // 下面是表头的下一个元素在父节点(table[@class='table_clist'])上的位置
            NSUInteger firstPos = 0;
            for (NSUInteger i = 0; i < count; i++) {
                if ([[[tableChildren objectAtIndex:i] tagName] isEqualToString:@"tr"]) {
                    firstPos = i + 1;
                    break;
                }
            }
            
            // 在一些特别的情况下，比如出票失败，表头之后还会夹杂很多input标签，需要跳过
            // 直到遇到一个tr
            for (NSInteger i = firstPos; i < count; i++) {
                if ([[[tableChildren objectAtIndex:i] tagName] isEqualToString:@"tr"]) {
                    firstPos = i;
                    break;
                }
            }
            
            // 一个订单可能有多个乘客，很多信息只需要从第一个乘客中获取
            BOOL isFirstPerson = YES;
            NSMutableArray *passengerList = [NSMutableArray new];
            
            // 最后一个tr里面不是乘客的信息
            for (NSUInteger i = firstPos; i < count - 1; i++) {
                TFHppleElement *personTR = [tableChildren objectAtIndex:i];
                
                //every person in order
                NSMutableArray *textNodeList = [[NSMutableArray alloc] init];
                NSMutableArray *inputNodeList = [[NSMutableArray alloc] init];
                
                [self parseDOM:personTR textNodeOut:textNodeList inputNodeOut:inputNodeList];
                
                if (textNodeList.count < 11) {
                    order.statusDescription = @"失败";
                } else {
                    order.statusDescription = [textNodeList objectAtIndex:10];
                }
                
                // 对于改签票，先把改签前的票面信息去掉，防止干扰用户
                if ([order.statusDescription isEqualToString:@"已改签"]) {
                    continue;
                }
                
                if (isFirstPerson) { // first person
                    isFirstPerson = NO;
                    
                    order.date = [textNodeList objectAtIndex:0];
                    order.trainNo = [textNodeList objectAtIndex:1];
                    order.departTime = [textNodeList objectAtIndex:3];
                    
                    
                    NSArray *trip = [[textNodeList objectAtIndex:2] componentsSeparatedByString:@"—"];
                    order.departStationName = [trip objectAtIndex:0];
                    order.arriveStationName = [trip objectAtIndex:1];
                    
                    if (textNodeList.count < 11) {
                        order.statusDescription = @"失败";
                    } else {
                        order.statusDescription = [textNodeList objectAtIndex:10];
                    }
                    
                    TFHppleElement *input = (inputNodeList.count > 0) ? [inputNodeList objectAtIndex:0] : nil;
                    if (input && [[input.attributes objectForKey:@"id"] isEqualToString:@"checkbox_pay"]) {
                        
                        order.orderSquence_no = [[[input.attributes objectForKey:@"name"] componentsSeparatedByString:@"_"] lastObject];
                        order.ticketKey = [input.attributes objectForKey:@"value"];
                        
                        order.status = ORDER_STATUS_UNFINISHED;
                    } else if ([order.statusDescription isEqualToString:@"已支付"]) {
                        order.status = ORDER_STATUS_PAID;
                    } else if ([order.statusDescription isEqualToString:@"改签票"]) {
                        order.status = ORDER_STATUS_PAID;
                    } else {
                        order.status = ORDER_STATUS_OTHER;
                    }
                    
                    // 对于已完成的订单，订单号可以从“打印订单”按钮的JS代码中获取
                    NSString *orderSequenceFromLastTr = [self _findOrderSequenceNoFromLastTr:[tableChildren objectAtIndex:count - 1]];
                    if (orderSequenceFromLastTr) {
                        order.orderSquence_no = orderSequenceFromLastTr;
                    }
                    
                    NSString *ticketKeyFromCheckbox = [self _findTicketKeyFromCheckbox:personTR];
                    if (ticketKeyFromCheckbox) {
                        order.ticketKey = ticketKeyFromCheckbox;
                    }
                }
                
                PassengerInOrder *pio = [[PassengerInOrder alloc] init];
                
                // 若出票失败，字段会不够，补齐两个字段
                if (textNodeList.count < 11) {
                    [textNodeList insertObject:@"未分配座位" atIndex:4];
                    [textNodeList insertObject:@"" atIndex:5];
                }
                
                NSAssert(textNodeList.count >= 11, @"must be");
                
                pio.vehicle = [textNodeList objectAtIndex:4];
                pio.seatNo = [textNodeList objectAtIndex:5];
                pio.seatType = [textNodeList objectAtIndex:6];
                pio.ticketType = [textNodeList objectAtIndex:7];
                pio.name = [textNodeList objectAtIndex:8];
                pio.idcardType = [textNodeList objectAtIndex:9];
                
                [passengerList addObject:pio];
            }
            
            order.passengers = [[NSArray alloc] initWithArray:passengerList];
            [array addObject:order];
        }

        [tempList addObjectsFromArray:array];
    }

    return ORDER_PARSER_MSG_SUCCESS;
}

- (void)parseDOM:(TFHppleElement *)element textNodeOut:(NSMutableArray *)textNodeList inputNodeOut:(NSMutableArray *)inputNodeList
{
    if (element != nil) {
        if (element.isTextNode) {
            NSString *content = element.content;
            content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if (content.length > 0) {
                [textNodeList addObject:content];
            }
        } else if ([element.tagName isEqualToString:@"input"]) {
            [inputNodeList addObject:element];
        } else if (element.hasChildren) {
            NSArray *children = [element children];
            for (TFHppleElement *e in children) {
                [self parseDOM:e textNodeOut:textNodeList inputNodeOut:inputNodeList];
            }
        }
    }
}

- (NSString *)_findOrderSequenceNoFromLastTr:(TFHppleElement *)element
{
    NSString *text = element.raw;
    NSRange range = [text rangeOfString:@"printTickets('"];
    
    if (range.length == 0) {
        return nil;
    }
    
    text = [text substringFromIndex:range.location + range.length];
    range = [text rangeOfString:@"');"];
    
    if (range.length == 0) {
        return nil;
    }
    
    return [text substringToIndex:range.location];
}

- (NSString *)_findTicketKeyFromCheckbox:(TFHppleElement *)element
{
    TFHpple *parser = [[TFHpple alloc] initWithHTMLData:[element.raw dataUsingEncoding:NSUTF8StringEncoding]];
    NSArray *elements = [parser searchWithXPathQuery:@"//input[@id='checkbox_all']"];
    if (elements.count > 0) {
        TFHppleElement *element = [elements objectAtIndex:0];
        return [[element attributes] objectForKey:@"value"];
    } else {
        return nil;
    }
}

- (NSString *)parseApacheToken:(TFHpple *)xpathParser
{
    
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//input[@name='org.apache.struts.taglib.html.TOKEN']"];
    TFHppleElement *element = [elements objectAtIndex:0];
    
    return [element.attributes objectForKey:@"value"];
}

- (void)retriveEssentialInfoUsingGCD
{
    // 这个属性就用来判断是否正在拉取
    self.refreshProcessEnable = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        ORDER_PARSER_MSG result;
        NSMutableArray *tempList = [NSMutableArray new];
        
        @try {
            NSData *htmlData = [[GlobalDataStorage tdbss] queryMyOrderNotComplete];
            result = [self parseHTMLWithData:htmlData toList:tempList];
            
            if (result == ORDER_PARSER_MSG_SUCCESS) {
                [NSThread sleepForTimeInterval:0.5];
                
                htmlData = [[GlobalDataStorage tdbss] queryMyOrder];
                result = [self parseHTMLWithData:htmlData toList:tempList];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"[EXCEPTION] %@", exception);
            result = ORDER_PARSER_MSG_ERR;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (result == ORDER_PARSER_MSG_SUCCESS) {
                self.orderList = tempList;
                [self.tableView reloadData];
            } else {
                [SVProgressHUD showErrorWithStatus:@"获取列表信息失败，请重试"];
            }
            
            // 防止刷新过速，每次刷新之后延迟2秒再启用refreshBtn
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
                sleep(2);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    self.refreshProcessEnable = YES;
                });
            });
            
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"上次更新： MM-dd HH:mm"];

            [self.tableView.pullToRefreshView setSubtitle:[formatter stringFromDate:date] forState:SVPullToRefreshStateAll];
            [self.tableView.pullToRefreshView stopAnimating];
        });
    });
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _refreshProcessEnable = YES;
    
    // 防止循环引用
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        typeof(self) mySelf = weakSelf;
        if (mySelf) {
            [mySelf iWantRefresh:nil];
        }
    }];
    [self.tableView.pullToRefreshView setTitle:@"正在载入" forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setTitle:@"松开后刷新订单" forState:SVPullToRefreshStateTriggered];
    [self.tableView.pullToRefreshView setTitle:@"下拉刷新订单" forState:SVPullToRefreshStateStopped];
    [self.tableView triggerPullToRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.orderList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OrderInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *train_no = (UILabel *)[cell viewWithTag:10];
    UILabel *from = (UILabel *)[cell viewWithTag:1];
    UILabel *to = (UILabel *)[cell viewWithTag:2];
    UILabel *time_from = (UILabel *)[cell viewWithTag:3];
    UILabel *date = (UILabel *)[cell viewWithTag:21];
    UILabel *unfinished = (UILabel *)[cell viewWithTag:22];
    UILabel *firstPassengerName = (UILabel *)[cell viewWithTag:23];
    UILabel *orderSequenceNo = (UILabel *)[cell viewWithTag:24];
    
    // 此处暂时去除圆角效果，因为经测试设置后很影响显示性能
    // unfinished.layer.cornerRadius = 8.f;
    
    TDBOrder *order = [self.orderList objectAtIndex:indexPath.row];
    train_no.text = order.trainNo;
    from.text = order.departStationName;
    to.text = order.arriveStationName;
    time_from.text = order.departTime;
    date.text = order.date;
    firstPassengerName.text = [[order.passengers objectAtIndex:0] name];
    orderSequenceNo.text = order.orderSquence_no;
    
    unfinished.text = order.statusDescription;
    
    if (order.status == ORDER_STATUS_UNFINISHED) {
        unfinished.backgroundColor = [UIColor redColor];
    } else if (order.status == ORDER_STATUS_PAID) {
        unfinished.backgroundColor = [UIColor brownColor];
    } else {
        unfinished.backgroundColor = [UIColor grayColor];
    }

    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OrderDetailSegue"]) {
        TDBOrderDetailViewController *detailViewController = segue.destinationViewController;
        
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        TDBOrder *order = [self.orderList objectAtIndex:index];
        detailViewController.passengerList = order.passengers;
        [detailViewController.tableView reloadData];
    } else if ([segue.identifier isEqualToString:@"OrderControlSegue"]) {
        TDBOrderOperationViewController *detailViewController = segue.destinationViewController;
        
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        detailViewController.apacheToken = self.apacheToken;
        detailViewController.order = [self.orderList objectAtIndex:index];
        detailViewController.receiver = self;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"OrderDetailSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = indexPath.row;
    TDBOrder *order = [self.orderList objectAtIndex:index];
    
    if (order.status == ORDER_STATUS_UNFINISHED) {
        [self performSegueWithIdentifier:@"OrderControlSegue" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
    }
}

- (void)forceRefreshOrderList
{
    // 这个方法是给完成订单支付或者取消订单后调用的，由于TDB处理有一定的延迟，所以这边延迟一段时间后再刷新
    [SVProgressHUD showWithStatus:@"正在处理"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        sleep(3.f);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [SVProgressHUD dismiss];
            self.refreshProcessEnable = YES;
            [self.tableView triggerPullToRefresh];
        });
    });
}

- (IBAction)iWantReturn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)iWantRefresh:(id)sender {
    if (self.refreshProcessEnable == YES) {
        // 由于这个方法还被ODRefreshControl调用，所以先判断一下是否正在执行
        
        // 不要在这里就self.orderList = nil了。因为对于下拉刷新来说，还可能因为滚动的原因导致Cell复用，中途会获取数组中的内容，容易出现异常
        [self retriveEssentialInfoUsingGCD];
    } else {
        [self.tableView.pullToRefreshView stopAnimating];
    }
}
@end
