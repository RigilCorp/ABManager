//
//  ViewController.m
//  ABManagerExample
//
//  Created by Sean Rada on 6/19/15.
//  Copyright (c) 2015 Rigil Corp. All rights reserved.
//

#import "ViewController.h"
#import "ABManager.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *table;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[ABManager sharedManager] requestAccess:^(BOOL accessGranted) {
        [table reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    ABManagedPerson *person = [[ABManager sharedManager].contacts objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", person.firstName, person.lastName];
    NSString *emails = @"";
    for (NSString *email in person.phoneNumbers) {
        emails = [NSString stringWithFormat:@"%@%@, ", emails, email];
    }
    cell.detailTextLabel.text = emails;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[ABManager sharedManager].contacts count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

@end
