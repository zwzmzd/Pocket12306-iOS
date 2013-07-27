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
#import "MBProgressHUD.h"

@interface TDBListViewController ()

@end

@implementation TDBListViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)retriveTrainInfoListUsingGCD
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_queue_t downloadVerifyCode = dispatch_queue_create("12306 traininfo", NULL);
    dispatch_async(downloadVerifyCode, ^(void) {
        
        NSArray *array = [[GlobalDataStorage tdbss] queryLeftTickWithDate:self.dateInString
                                                                     from:self.departStationTelecode
                                                                       to:self.arriveStationTelecode];
        
        TDBTrainInfoController *controller = [[TDBTrainInfoController alloc] init];
        NSUInteger count = [array count];
        for (NSUInteger i = 0; i < count; i++) {
            [controller addTrainInfoWithDataArray:[array objectAtIndex:i]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.dataController = controller;
            [self.tableView reloadData];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if ([self.dataController count] == 0) {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"获取车次信息失败，请重试";
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:2];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel *train_no = (UILabel *)[cell viewWithTag:10];
    UILabel *from = (UILabel *)[cell viewWithTag:1];
    UILabel *to = (UILabel *)[cell viewWithTag:2];
    UILabel *time_from = (UILabel *)[cell viewWithTag:3];
    UILabel *time_to = (UILabel *)[cell viewWithTag:4];
    UILabel *time_duration = (UILabel *)[cell viewWithTag:5];
    
    TDBTrainInfo *train = [self.dataController getTrainInfoForIndex:indexPath.row];
    
    train_no.text = [train getTrainNo];
    from.text = [train getDapartStationName];;
    to.text = [train getArriveStationName];
    time_from.text = [train getDepartTime];
    time_to.text = [train getArriveTime];
    
    time_duration.text = [train getDuration];
    
    // Configure the cell...
    
    return cell;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"TicketDetail"]) {
        TDBTicketDetailViewController *detail = [segue destinationViewController];
        detail.train = [self.dataController getTrainInfoForIndex:[self.tableView indexPathForCell:sender].row];
        detail.departDate = self.dateInString;
    }
}

@end
