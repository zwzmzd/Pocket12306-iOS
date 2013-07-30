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
#import "TDBEPayEntryViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface TDBOrderListViewController ()

@property (nonatomic) NSMutableArray *orderList;
@property (nonatomic, copy) NSString *apacheToken;

@end

@implementation TDBOrderListViewController

- (NSArray *)orderList
{
    if (_orderList == nil) {
        _orderList = [[NSMutableArray alloc] init];
    }
    return _orderList;
}

- (ORDER_PARSER_MSG)parseHTMLWithData:(NSData *)htmlData
{
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
    
    self.apacheToken = [self parseApacheToken:xpathParser];
    
    {
        NSArray *elements = [xpathParser searchWithXPathQuery:@"//table[@class='table_clist']"];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        for (TFHppleElement *table in elements) {
            // every order
            TDBOrder *order = [[TDBOrder alloc] init];
            
            NSArray *tableChildren = [table children];
            NSUInteger count = tableChildren.count;
            
            NSUInteger firstPos = 0;
            for (NSUInteger i = 0; i < count; i++) {
                if ([[[tableChildren objectAtIndex:i] tagName] isEqualToString:@"tr"]) {
                    firstPos = i + 1;
                    break;
                }
            }
            
            BOOL isFirstPerson = YES;
            NSMutableArray *passengerList = [NSMutableArray new];
            for (NSUInteger i = firstPos; i < count - 1; i++) {
                
                // 在一些特别的情况下，比如出票失败，页面中间会夹杂很多input标签
                TFHppleElement *personTR = [tableChildren objectAtIndex:i];
                if (![personTR.tagName isEqualToString:@"tr"]) {
                    continue;
                }
                //every person in order
                NSMutableArray *textNodeList = [[NSMutableArray alloc] init];
                NSMutableArray *inputNodeList = [[NSMutableArray alloc] init];
                
                [self parseDOM:personTR textNodeOut:textNodeList inputNodeOut:inputNodeList];
                
//                NSLog(@"[hello]");
//                for (NSString *str in textNodeList) {
//                    NSLog(@"%@", str);
//                }
//                NSLog(@"[finish]");
                
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
                    } else {
                        order.status = ORDER_STATUS_OTHER;
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

        [self.orderList addObjectsFromArray:array];
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

- (NSString *)parseApacheToken:(TFHpple *)xpathParser
{
    
    NSArray *elements = [xpathParser searchWithXPathQuery:@"//input[@name='org.apache.struts.taglib.html.TOKEN']"];
    TFHppleElement *element = [elements objectAtIndex:0];
    
    return [element.attributes objectForKey:@"value"];
}

- (void)retriveEssentialInfoUsingGCD
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 orderList", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        ORDER_PARSER_MSG result;
        NSData *htmlData = [[GlobalDataStorage tdbss] queryMyOrderNotComplete];
        result = [self parseHTMLWithData:htmlData];
        
        
        NSDate *now = [NSDate date];
        NSDate *a_month_ago = [NSDate dateWithTimeIntervalSinceNow: -30 * 24 * 3600];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        
        htmlData = [[GlobalDataStorage tdbss] queryMyOrderWithFromOrderDate:[formatter stringFromDate:a_month_ago]
                                                               endOrderDate:[formatter stringFromDate:now]];
        result = [self parseHTMLWithData:htmlData];
        
//        htmlData = [[GlobalDataStorage tdbss] laterEpayWithOrderSequenceNo:@"E440314790" apacheToken:self.apacheToken ticketKey:@"E4403147901110022"];
//        NSLog(@"%@", [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding]);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {

            if (result == ORDER_PARSER_MSG_SUCCESS) {
                [self.tableView reloadData];
            }
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.refreshBtn.enabled = YES;
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
    
    self.refreshBtn.enabled = NO;
    [self retriveEssentialInfoUsingGCD];
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
    static NSString *CellIdentifier = @"OrderInfo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel *train_no = (UILabel *)[cell viewWithTag:10];
    UILabel *from = (UILabel *)[cell viewWithTag:1];
    UILabel *to = (UILabel *)[cell viewWithTag:2];
    UILabel *time_from = (UILabel *)[cell viewWithTag:3];
    UILabel *date = (UILabel *)[cell viewWithTag:21];
    UILabel *unfinished = (UILabel *)[cell viewWithTag:22];
    UILabel *firstPassengerName = (UILabel *)[cell viewWithTag:23];
    
    // 此处暂时去除圆角效果，因为经测试设置后很影响显示性能
    // unfinished.layer.cornerRadius = 8.f;
    
    TDBOrder *order = [self.orderList objectAtIndex:indexPath.row];
    train_no.text = order.trainNo;
    from.text = order.departStationName;
    to.text = order.arriveStationName;
    time_from.text = order.departTime;
    date.text = order.date;
    firstPassengerName.text = [[order.passengers objectAtIndex:0] name];
    
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"EpaySegue"]) {
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        TDBOrder *order = [self.orderList objectAtIndex:index];
        
        return (order.status == ORDER_STATUS_UNFINISHED);
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PassengerDetailSegue"]) {
        TDBOrderDetailViewController *detailViewController = segue.destinationViewController;
        
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        TDBOrder *order = [self.orderList objectAtIndex:index];
        detailViewController.passengerList = order.passengers;
        [detailViewController.tableView reloadData];
    } else if ([segue.identifier isEqualToString:@"EpaySegue"]) {
        TDBEPayEntryViewController *epayViewController = segue.destinationViewController;
        
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        TDBOrder *order = [self.orderList objectAtIndex:index];
        epayViewController.apacheToken = self.apacheToken;
        epayViewController.ticketKey = order.ticketKey;
        epayViewController.orderSequenceNo = order.orderSquence_no;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)iWantReturn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)iWantRefresh:(id)sender {
    self.refreshBtn.enabled = NO;
    self.orderList = nil;
    [self retriveEssentialInfoUsingGCD];
}
@end
