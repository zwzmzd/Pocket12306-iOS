//
//  TDBOrderDetailViewController.m
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBOrderDetailViewController.h"
#import "TDBOrder.h"

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
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PassengerDetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PassengerInOrder *pio = [self.passengerList objectAtIndex:indexPath.section];
    switch (indexPath.row) {
            
        case 0:
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %@", pio.seatType, pio.vehicle, pio.seatNo];
            break;
            
        case 1:
            cell.textLabel.text = pio.ticketType;
            break;
            
        case 2:
            cell.textLabel.text = [NSString stringWithFormat:@"使用%@购票", pio.idcardType];
            break;
    }
    
    return cell;
}

-  (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *name = [[self.passengerList objectAtIndex:section] name];
    return name;
}

@end
