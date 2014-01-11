//
//  TDBTrainTimetableViewController.m
//  12306
//
//  Created by macbook on 13-8-10.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainTimetableViewController.h"
#import "TDBTrainTimetableCell.h"
#import "SVProgressHUD.h"
#import "TDBTrainInfo.h"
#import "GlobalDataStorage.h"
#import "TDBSession.h"
#import "UIButton+TDBAddition.h"
#import "MobClick.h"

#import "Macros.h"
#import "TDBHTTPClient.h"

@interface TDBTrainTimetableViewController ()

@property (nonatomic) NSArray *dataModel;

@end

@implementation TDBTrainTimetableViewController

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
    [MobClick event:@"train timetable query"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
    
    self.title = [NSString stringWithFormat:@"%@次列车", self.train.getTrainNo];
    [self retriveEssentialDataUsingGCD];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [SVProgressHUD dismiss];
}

- (IBAction)_backPressed:(id)sender
{
    [SVProgressHUD dismiss];
    [[TDBHTTPClient sharedClient] cancelAllHTTPRequest];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)retriveEssentialDataUsingGCD
{
    [SVProgressHUD show];
    WeakSelfDefine(wself);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        CHECK_INSTANCE_EXIST(wself);
        TDBTrainInfo *train = wself.train;
        NSString *departData = wself.departDate;
        [[TDBHTTPClient sharedClient] queryaTrainStopTimeByTrainNo:train.getTrainCode
                                               fromStationTelecode:train.getDepartStationTeleCode
                                                 toStationTelecode:train.getArriveStationTeleCode
                                                        departDate:departData
                                                           success:^(NSArray *dataModel) {
                                                               CHECK_INSTANCE_EXIST(wself);
                                                               if (dataModel) {
                                                                   NSUInteger i;
                                                                   for (i = 0; i < dataModel.count; i++) {
                                                                       if ([[[dataModel objectAtIndex:i] objectForKey:@"isEnabled"] boolValue]) {
                                                                           break;
                                                                       }
                                                                   }
                                                                   
                                                                   dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                       StrongSelf(sself, wself);
                                                                       if (sself) {
                                                                           sself.dataModel = dataModel;
                                                                           [sself.tableView reloadData];
                                                                           [SVProgressHUD dismiss];
                                                                           
                                                                           NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                                                                           [sself.tableView scrollToRowAtIndexPath:indexPath
                                                                                                  atScrollPosition:UITableViewScrollPositionTop
                                                                                                          animated:NO];
                                                                       }
                                                                   });
                                                               } else {
                                                                   dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                       [SVProgressHUD showErrorWithStatus:@"信息获取失败，请重试"];
                                                                   });
                                                               }

                                                           }];
        
    });
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
    return self.dataModel.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[TDBTrainTimetableSection alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
    [header setNeedsDisplay];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TimeTableCell";
    TDBTrainTimetableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[TDBTrainTimetableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *dict = [self.dataModel objectAtIndex:indexPath.row];
    
    NSString *start_station_name = [dict objectForKey:@"start_station_name"];
    if (start_station_name) {
        cell.station_no = @"01";
        cell.station_name = start_station_name;
    } else {
        cell.station_no = [dict objectForKey:@"station_no"];
        cell.station_name = [dict objectForKey:@"station_name"];
    }
    cell.arrive_time = [dict objectForKey:@"arrive_time"];
    cell.start_time = [dict objectForKey:@"start_time"];
    cell.stopover_time = [dict objectForKey:@"stopover_time"];
    cell.is_enabled = [[dict objectForKey:@"isEnabled"] boolValue];
    [cell setNeedsLayout];
    
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TDBTrainTimetableCell heightForCell];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [TDBTrainTimetableSection heightForSection];
}

@end
