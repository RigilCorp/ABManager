//
//  ABManager.h
//  RigilPics
//
//  Created by Sean Rada on 4/9/14.
//  Copyright (c) 2014 Rigil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface ABManager : NSObject

/**Contacts is an array of ABManagedPerson objects.  All linked contacts are merged into a single contact*/
@property (nonatomic, readonly) NSMutableArray *contacts;

+ (ABManager *)sharedManager;

/**Requests access to the devices native contact list*/
- (void)requestAccess:(void(^)(BOOL accessGranted))completionHandler;

/**loads the contacts from the native AddressBook*/
- (void)reloadData;

@end

@interface ABManagedPerson : NSObject

@property (nonatomic) ABRecordID recordID;

//All properties of are lazy loaded except for recordID
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;

- (NSString *)middleName;

/**Returns an array of phone numbers as strings, including numbers from linked contacts*/
- (NSArray *)phoneNumbers;

/**Returns an array of emails as strings, including emails from linked contacts*/
- (NSArray *)emails;

@end