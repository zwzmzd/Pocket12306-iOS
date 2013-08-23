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
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
    
    self.title = [NSString stringWithFormat:@"%@次列车", self.train.getTrainNo];
    [self retriveEssentialDataUsingGCD];
}

- (IBAction)_backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)retriveEssentialDataUsingGCD
{
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        TDBSession *tdbss = [GlobalDataStorage tdbss];
        TDBTrainInfo *train = self.train;
        NSArray *dataModel = [tdbss queryaTrainStopTimeByTrainNo:train.getTrainCode
                                             fromStationTelecode:train.getDepartStationTeleCode
                                               toStationTelecode:train.getArriveStationTeleCode
                                                      departDate:self.departDate];
        
        NSUInteger i;
        for (i = 0; i < dataModel.count; i++) {
            if ([[[dataModel objectAtIndex:i] objectForKey:@"isEnabled"] boolValue]) {
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.dataModel = dataModel;
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        });
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
    cell.station_no = [dict objectForKey:@"station_no"];
    cell.station_name = [dict objectForKey:@"station_name"];
    cell.arrive_time = [dict objectForKey:@"arrive_time"];
    cell.start_time = [dict objectForKey:@"start_time"];
    cell.stopover_time = [dict objectForKey:@"stopover_time"];
    cell.is_enabled = [[dict objectForKey:@"isEnabled"] boolValue];
    [cell setNeedsDisplay];
    
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
