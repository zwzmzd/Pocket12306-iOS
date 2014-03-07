//
//  TDBOrderDetailViewController.m
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBOrderDetailViewController.h"
#import "TDBOrder.h"
#import "UIButton+TDBAddition.h"

@interface TDBOrderDetailViewController ()

@end

@implementation TDBOrderDetailViewController

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MobClickBeginLogPageView();
}

- (void)viewWillDisappear:(BOOL)animated {
    MobClickEndLogPageView();
    [super viewWillDisappear:animated];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.passengerList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OrderDetailCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    PassengerInOrder *pio = [self.passengerList objectAtIndex:indexPath.section];
    switch (indexPath.row) {
            
        case 0:
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@车 %@", pio.seatType, pio.vehicle, pio.seatNo];
            break;
            
        case 1:
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@元", pio.ticketType, pio.price];
            break;
            
        case 2:
            cell.textLabel.text = [NSString stringWithFormat:@"使用%@购票", pio.idcardType];
            break;
            
        case 3:
            cell.textLabel.text = [NSString stringWithFormat:@"%@", pio.idcardNo];
            break;
    }
    
    return cell;
}

-  (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    PassengerInOrder *pio = [self.passengerList objectAtIndex:section];
    return [NSString stringWithFormat:@"%@(%@)", pio.name, pio.status];
}

@end
