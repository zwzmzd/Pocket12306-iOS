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
    
    NSLog(@"apacheToken = %@", self.apacheToken);
    
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
            
            NSMutableArray *passengerList = [NSMutableArray new];
            for (NSUInteger i = firstPos; i < count - 1; i++) {
                //every person in order
                NSMutableArray *textNodeList = [[NSMutableArray alloc] init];
                NSMutableArray *inputNodeList = [[NSMutableArray alloc] init];
                
                TFHppleElement *personTR = [tableChildren objectAtIndex:i];
                [self parseDOM:personTR textNodeOut:textNodeList inputNodeOut:inputNodeList];
                
//                NSLog(@"[hello]");
//                for (NSString *str in textNodeList) {
//                    NSLog(@"%@", str);
//                }
                
                if (i == firstPos) { // first person
                    order.date = [textNodeList objectAtIndex:0];
                    order.trainNo = [textNodeList objectAtIndex:1];
                    order.departTime = [textNodeList objectAtIndex:3];
                    order.status = [textNodeList objectAtIndex:10];
                    
                    NSArray *trip = [[textNodeList objectAtIndex:2] componentsSeparatedByString:@"—"];
                    order.departStationName = [trip objectAtIndex:0];
                    order.arriveStationName = [trip objectAtIndex:1];
                    
                    if (inputNodeList.count > 0) {
                        TFHppleElement *input = [inputNodeList objectAtIndex:0];
                        order.orderSquence_no = [[[input.attributes objectForKey:@"name"] componentsSeparatedByString:@"_"] lastObject];
                        order.ticketKey = [input.attributes objectForKey:@"value"];
                        NSLog(@"orderSquence_no = %@, ticketKey = %@", order.orderSquence_no, order.ticketKey);
                        
                        order.unfinished = YES;
                    } else {
                        order.unfinished = NO;
                    }
                }
                
                PassengerInOrder *pio = [[PassengerInOrder alloc] init];
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
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];

            if (result == ORDER_PARSER_MSG_SUCCESS) {
                [self.tableView reloadData];
            }
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
    
    unfinished.layer.cornerRadius = 8.f;
    
    TDBOrder *order = [self.orderList objectAtIndex:indexPath.row];
    train_no.text = order.trainNo;
    from.text = order.departStationName;
    to.text = order.arriveStationName;
    time_from.text = order.departTime;
    date.text = order.date;
    firstPassengerName.text = [[order.passengers objectAtIndex:0] name];
    
    unfinished.text = order.status;
    if (order.unfinished) {
        unfinished.backgroundColor = [UIColor redColor];
    } else {
        unfinished.backgroundColor = [UIColor grayColor];
    }

    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PassengerDetailSegue"]) {
        TDBOrderDetailViewController *detailViewController = segue.destinationViewController;
        
        NSUInteger index = [self.tableView indexPathForCell:sender].row;
        TDBOrder *order = [self.orderList objectAtIndex:index];
        detailViewController.passengerList = order.passengers;
        [detailViewController.tableView reloadData];
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
@end
