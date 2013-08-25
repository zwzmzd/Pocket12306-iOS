//
//  TDBPassengerInfoViewController.m
//  12306
//
//  Created by Wenzhe Zhou on 13-8-25.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBPassengerInfoViewController.h"
#import "TDBSession.h"
#import "GlobalDataStorage.h"
#import "FMDatabase.h"
#import "SVProgressHUD.h"

#define SQL_TABLE_NAME @"passenger"

@interface TDBPassengerInfoViewController ()

@property (nonatomic, strong) NSArray *dataModel;

@end

@implementation TDBPassengerInfoViewController

+ (NSString *)databasePath
{
    static NSString *_path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _path = [docsdir stringByAppendingPathComponent:@"user.sqlite"];
    });
    return _path;
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
     
    [self getInformationFromDatabaseUsingGCD];
}

- (void)getInformationFromDatabaseUsingGCD
{
    [SVProgressHUD show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        NSString *dbPath = [self.class databasePath];
        FMDatabase* db = [FMDatabase databaseWithPath:dbPath];
        
        [db open];
        FMResultSet *rs = [db executeQuery:@"select * from " SQL_TABLE_NAME @" order by first_letter asc"];
        while ([rs next]) {
            NSDictionary *dict = @{
                                   @"name": [rs stringForColumn:@"name"],
                                   @"mobile_no": [rs stringForColumn:@"mobile_no"],
                                   @"passenger_id_no": [rs stringForColumn:@"passenger_id_no"],
                                   @"first_letter": [rs stringForColumn:@"first_letter"]
                                   };
            [array addObject:dict];
            
        }
        [db close];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.dataModel = array;
            [self.tableView reloadData];
            
            [SVProgressHUD dismiss];
        });
    });
    
}

- (void)getInformationFromNetworkUsingGCD
{
    [SVProgressHUD show];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        TDBSession *tdbss = [GlobalDataStorage tdbss];
        NSDictionary *dict = [tdbss getPassengersWithIndex:0 size:100];
        
        NSString *dbPath = [self.class databasePath];
        FMDatabase* db = [FMDatabase databaseWithPath:dbPath];
        
        [db open];
        [db executeUpdate:@"drop table " SQL_TABLE_NAME];
        [db executeUpdate:@"create table " SQL_TABLE_NAME @" (name text, mobile_no text, passenger_id_no text, first_letter text)"];
        NSArray *rows = [dict objectForKey:@"rows"];
        for (NSDictionary *row in rows) {
            BOOL result = [db executeUpdate:@"insert into " SQL_TABLE_NAME " (name, mobile_no, passenger_id_no, first_letter) values (?, ?, ?, ?)", [row objectForKey:@"passenger_name"], [row objectForKey:@"mobile_no"], [row objectForKey:@"passenger_id_no"], [row objectForKey:@"first_letter"]];
            if (!result) {
                NSLog(@"[warning] FMDB not inserted");
            }
        }
        [db close];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self getInformationFromDatabaseUsingGCD];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PassengerInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSDictionary *dict = [self.dataModel objectAtIndex:indexPath.row];
    
    UILabel *title = (UILabel *)[cell viewWithTag:1];
    UILabel *subTitle = (UILabel *)[cell viewWithTag:2];
    
    title.text = [dict objectForKey:@"name"];
    subTitle.text = [dict objectForKey:@"passenger_id_no"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate didSelectPassenger:@[[self.dataModel objectAtIndex:indexPath.row]]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)retrivePassengerList:(UIBarButtonItem *)sender {
    [self getInformationFromNetworkUsingGCD];
}
@end
