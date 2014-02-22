//
//  TDBSeatDetailViewController.m
//  12306
//
//  Created by macbook on 13-7-20.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBSeatDetailViewController.h"
#import "UIButton+TDBAddition.h"

@interface TDBSeatDetailViewController ()

@end

@implementation TDBSeatDetailViewController

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
    return [self.dataController count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EveryTicketInfo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *label1 = (UILabel *)[cell viewWithTag:1];
    UILabel *label2 = (UILabel *)[cell viewWithTag:2];
    
    //label.text = [self.dataController objectAtIndex:indexPath.section];
    NSArray *info = [[[[self.dataController objectAtIndex:indexPath.section] componentsSeparatedByString:@"("] objectAtIndex:1] componentsSeparatedByString:@")"];
    label1.text = [info objectAtIndex:1];
    label2.text = [info objectAtIndex:0];
    
    return cell;

}

-  (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *seat = [[[self.dataController objectAtIndex:section] componentsSeparatedByString:@"("] objectAtIndex:0];
    return seat;
}


@end
