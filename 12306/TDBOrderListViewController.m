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
#import "TDBHTTPClient.h"
#import <QuartzCore/QuartzCore.h>
#import "SVPullToRefresh.h"
#import "Macros.h"
#import "MobClick.h"

@interface TDBOrderListViewController ()

@property (nonatomic) NSMutableArray *orderList;
@property (nonatomic, copy) NSString *apacheToken;

@property (nonatomic) BOOL refreshProcessEnable;
@property (nonatomic) BOOL isFirstScene;

@end

@implementation TDBOrderListViewController

- (ORDER_PARSER_MSG)parseJSON:(NSArray *)data toList:(NSMutableArray *)tempList {
    for (NSDictionary *info in data) {
        TDBOrder *order = [[TDBOrder alloc] init];
        order.orderSequence_no = [info objectForKey:@"sequence_no"];
        order.orderDate = [info objectForKey:@"order_date"];
        order.trainNo = [info objectForKey:@"train_code_page"];
        order.departStationName = [[info objectForKey:@"from_station_name_page"] firstObject];
        order.arriveStationName = [[info objectForKey:@"to_station_name_page"] firstObject];
        order.departTime = [info objectForKey:@"start_time_page"];
        
        order.totalPrice = [info objectForKey:@"ticket_total_price_page"];
        order.names = [info objectForKey:@"array_passser_name_page"];
        order.status = ORDER_STATUS_OTHER;
        
        NSArray *yy_mm_dd = [[[[info objectForKey:@"start_train_date_page"] componentsSeparatedByString:@" "] firstObject] componentsSeparatedByString:@"-"];
        order.date = [NSString stringWithFormat:@"%@月%@日", [yy_mm_dd objectAtIndex:1], [yy_mm_dd objectAtIndex:2]];
        
        NSMutableArray *statusCode = [NSMutableArray new];
        NSMutableArray *passengers = [NSMutableArray new];
        for (NSDictionary *ticket in [info objectForKey:@"tickets"]) {
            [statusCode addObject:[ticket objectForKey:@"ticket_status_code"]];
            if (![[ticket objectForKey:@"ticket_status_code"] isEqualToString:@"d"]) {
                PassengerInOrder *passengerInOrder = [[PassengerInOrder alloc] init];
                NSDictionary *passengerDTO = [ticket objectForKey:@"passengerDTO"];
                
                passengerInOrder.name = [passengerDTO objectForKey:@"passenger_name"];
                passengerInOrder.idcardType = [passengerDTO objectForKey:@"passenger_id_type_name"];
                passengerInOrder.idcardNo = [passengerDTO objectForKey:@"passenger_id_no"];
                
                passengerInOrder.seatNo = [ticket objectForKey:@"seat_name"];
                passengerInOrder.seatType = [ticket objectForKey:@"seat_type_name"];
                passengerInOrder.vehicle = [ticket objectForKey:@"coach_no"];
                
                passengerInOrder.ticketType = [ticket objectForKey:@"ticket_type_name"];
                passengerInOrder.price = [ticket objectForKey:@"str_ticket_price_page"];
                
                passengerInOrder.status = [ticket objectForKey:@"ticket_status_name"];
                
                order.ticketKey = [ticket objectForKey:@"ticket_no"];
                [passengers addObject:passengerInOrder];
            }
            if ([[ticket objectForKey:@"ticket_status_code"] isEqualToString:@"f"]) {
                // 改签过的票面，需要使用ticket内部的新信息来覆盖
                NSDictionary *stationTrainDTO = [ticket objectForKey:@"stationTrainDTO"];
                
                order.trainNo = [stationTrainDTO objectForKey:@"station_train_code"];
                order.departStationName = [stationTrainDTO objectForKey:@"from_station_name"];
                order.arriveStationName = [stationTrainDTO objectForKey:@"to_station_name"];
                
                NSArray *componenets = [[ticket objectForKey:@"start_train_date_page"] componentsSeparatedByString:@" "];
                NSArray *yy_mm_dd = [[componenets firstObject] componentsSeparatedByString:@"-"];
                order.date = [NSString stringWithFormat:@"%@月%@日", [yy_mm_dd objectAtIndex:1], [yy_mm_dd objectAtIndex:2]];
                order.departTime = [componenets lastObject];
            }
        }
        
        order.status = ORDER_STATUS_PAID;
        order.statusDescription = @"已支付";
        BOOL b = NO, c = NO, d = NO, i = NO;
        for (NSString *code in statusCode) {
            if ([code isEqualToString:@"b"]) {
                b = YES;
            } else if ([code isEqualToString:@"c"]) {
                c = YES;
            } else if ([code isEqualToString:@"d"]) {
                d = YES;
            } else if ([code isEqualToString:@"i"]) {
                i = YES;
            }
        }
        if (b) {
            order.status = ORDER_STATUS_OTHER;
            order.statusDescription = @"已出票";
        } else if (c) {
            order.status = ORDER_STATUS_OTHER;
            order.statusDescription = @"已退票";
        } else if (d) {
            order.status = ORDER_STATUS_OTHER;
            order.statusDescription = @"已改签";
        } else if (i) {
            order.status = ORDER_STATUS_UNFINISHED;
            order.statusDescription = @"待支付";
        }
        
        order.passengers = passengers;
        [tempList addObject:order];
    }
    
    return ORDER_PARSER_MSG_SUCCESS;
}

- (void)retriveEssentialInfoUsingGCD
{
    // 这个属性就用来判断是否正在拉取
    self.refreshProcessEnable = NO;
    
    WeakSelf(wself, self);
    [[TDBHTTPClient sharedClient] queryMyOrderNoComplete:^(NSArray *data) {
        CHECK_INSTANCE_EXIST(wself);
        __block ORDER_PARSER_MSG result;
        NSMutableArray *tempList = [NSMutableArray new];
        @try {
            result = [wself parseJSON:data toList:tempList];
        }
        @catch (NSException *exception) {
            result = ORDER_PARSER_MSG_ERR;
        }
        
        CHECK_INSTANCE_EXIST(wself);
        [NSThread sleepForTimeInterval:0.5f];
        CHECK_INSTANCE_EXIST(wself);
        
        [[TDBHTTPClient sharedClient] queryMyOrder:^(NSArray *data) {
            CHECK_INSTANCE_EXIST(wself);
            if (result == ORDER_PARSER_MSG_SUCCESS) {
                @try {
                    result = [wself parseJSON:data toList:tempList];
                }
                @catch (NSException *exception) {
                    result = ORDER_PARSER_MSG_ERR;
                }
            }
            CHECK_INSTANCE_EXIST(wself);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (result == ORDER_PARSER_MSG_SUCCESS) {
                    StrongSelf(sself, wself);
                    if (sself) {
                        sself.orderList = tempList;
                        [sself.tableView reloadData];
                    }
                } else {
                    [SVProgressHUD showErrorWithStatus:@"获取列表信息失败，请重试"];
                }
                
                StrongSelf(sself, wself);
                if (sself) {
                    // 防止刷新过速，每次刷新之后延迟2秒再启用refreshBtn
                    double delayInSeconds = 2.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        StrongSelf(sself, wself);
                        if (sself) {
                            sself.refreshProcessEnable = YES;
                        }
                    });
                    
                    NSDate *date = [NSDate date];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"上次更新： MM-dd HH:mm"];
                    
                    [sself.tableView.pullToRefreshView setSubtitle:[formatter stringFromDate:date] forState:SVPullToRefreshStateAll];
                    [sself.tableView.pullToRefreshView stopAnimating];
                }
            });
        }];
    }];
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
    [MobClick event:@"OrderList"];
    
    _refreshProcessEnable = YES;
    _isFirstScene = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isFirstScene) {
        self.isFirstScene = NO;
        
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
    
    // 主要修正iOS 7下UITableViewCellAccessoryDetailDisclosureButton样式变化的问题
    // http://stackoverflow.com/questions/18740594/in-ios7-uitableviewcellaccessorydetaildisclosurebutton-is-divided-into-two-diff
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
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
    firstPassengerName.text = [order.names firstObject];
    orderSequenceNo.text = order.orderSequence_no;
    
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
    
    WeakSelf(wself, self);
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [SVProgressHUD dismiss];
        
        StrongSelf(sself, wself);
        if (sself) {
            sself.refreshProcessEnable = YES;
            [sself.tableView triggerPullToRefresh];
        }
    });
}

- (IBAction)iWantReturn:(id)sender {
    [[TDBHTTPClient sharedClient] cancelQueryMyOrderHTTPRequest];
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

- (void)dealloc {
    NSLog(@"dealloc %@", [self class]);
}
@end
