//
//  TDBListViewController.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBListViewController.h"
#import "TDBTrainInfo.h"
#import "TDBTrainInfoController.h"
#import "GlobalDataStorage.h"
#import "TDBSession.h"
#import "TDBTicketDetailViewController.h"
#import "SVProgressHUD.h"
#import "TDBLeftTicketForList.h"
#import "TDBTrainTimetableViewController.h"
#import "UIButton+TDBAddition.h"

@interface TDBListViewController ()

@property (nonatomic) TDBTrainInfoController *dataController;
@property (nonatomic, readonly) NSString *dateInString;

@end

@implementation TDBListViewController

- (NSString *)dateInString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self.orderDate];
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
    
    self.title = [NSString stringWithFormat:@"%@车票", self.dateInString];
    [self retriveTrainInfoListUsingGCD];
    
    UIButton *button = [UIButton arrowBackButtonWithSelector:@selector(_backPressed:) target:self];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton animated:NO];
}

- (IBAction)_backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)retriveTrainInfoListUsingGCD
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 traininfo", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        NSArray *array = [[GlobalDataStorage tdbss] queryLeftTickWithDate:self.dateInString
                                                                     from:self.departStationTelecode
                                                                       to:self.arriveStationTelecode];
        BOOL dataIsError = (array == nil);
        
        NSString *userInputDepartStationName = [GlobalDataStorage userInputDepartStation];
        NSString *userInputArriveStationName = [GlobalDataStorage userInputArriveStation];
        
        TDBTrainInfoController *controller = [[TDBTrainInfoController alloc] init];
        NSUInteger count = [array count];
        for (NSUInteger i = 0; i < count; i++) {
            TDBTrainInfo *train = [[TDBTrainInfo alloc] initWithArray:[array objectAtIndex:i]];
            
            if (self.stationNameExactlyMatch && (![userInputArriveStationName isEqualToString:[train getArriveStationName]]
                || ![userInputDepartStationName isEqualToString:[train getDapartStationName]])) {
                continue;
            }
            
            [controller addTrainInfo:train];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.dataController = controller;
            [self.tableView reloadData];
            
            if ( dataIsError) { // 未正确获取数据
                [SVProgressHUD showErrorWithStatus:@"获取车次信息失败，请重试"];
            } else if ([self.dataController count] == 0) { // 获取的数据长度为0
                [SVProgressHUD showErrorWithStatus:@"没有符合条件的列车了"];
            } else {
                [SVProgressHUD dismiss];
            }
        });
    });

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataController count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TrainInfo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UIButton *train_no = (UIButton *)[cell viewWithTag:10];
    UILabel *from = (UILabel *)[cell viewWithTag:1];
    UILabel *to = (UILabel *)[cell viewWithTag:2];
    UILabel *time_from = (UILabel *)[cell viewWithTag:3];
    UILabel *time_to = (UILabel *)[cell viewWithTag:4];
    UILabel *time_duration = (UILabel *)[cell viewWithTag:5];
    TDBLeftTicketForList *leftTicketView = (TDBLeftTicketForList *)[cell viewWithTag:20];
    
    
    TDBTrainInfo *train = [self.dataController getTrainInfoForIndex:indexPath.row];
    
    [train_no setTitle:[train getTrainNo] forState:UIControlStateNormal];
    from.text = [train getDapartStationName];;
    to.text = [train getArriveStationName];
    time_from.text = [train getDepartTime];
    time_to.text = [train getArriveTime];
    
    time_duration.text = [train getDuration];
    
    
    NSRange range = NSMakeRange(1, train.original.count - 1);
    NSArray *a = [train.original subarrayWithRange:range];
    leftTicketView.dataModel = a;
    
    return cell;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"TicketDetail"]) {
        TDBTicketDetailViewController *detail = [segue destinationViewController];
        detail.train = [self.dataController getTrainInfoForIndex:[self.tableView indexPathForCell:sender].row];
        detail.orderDate = self.orderDate;
    } else if ([segue.identifier isEqualToString:@"TrainTimetableSegue"]) {
        UITableViewCell *clickedCell = (UITableViewCell *)[[sender superview] superview];
        NSIndexPath *clickedButtonPath = [self.tableView indexPathForCell:clickedCell];
        TDBTrainTimetableViewController *detailVC = [segue destinationViewController];
        detailVC.train = [self.dataController getTrainInfoForIndex:clickedButtonPath.row];
        detailVC.departDate = self.dateInString;
    }
}

@end
