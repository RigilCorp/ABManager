//
//  ABManager.m
//  RigilPics
//
//  Created by Sean Rada on 4/9/14.
//  Copyright (c) 2014 Rigil. All rights reserved.
//

#import "ABManager.h"


@interface ABManager ()

@property (nonatomic, readwrite) NSMutableArray *contacts;

@end

@implementation ABManager

@synthesize contacts;

+ (ABManager *)sharedManager {
    static ABManager *sharedInstance;
    
    @synchronized(self) {
        if (!sharedInstance)
            sharedInstance = [ABManager new];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        
        contacts = [NSMutableArray new];
        
        [self reloadData];
        
    }
    return self;
}

- (void)requestAccess:(void(^)(BOOL accessGranted))completionHandler {
    
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            completionHandler(granted);
        });
        
    }else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted) {
        completionHandler (NO);
    }else{
        completionHandler(YES);
    }
    
}

- (void)reloadData {
    
    [contacts removeAllObjects];
    
    //Only mess with participants if the app has access to the address book
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        
        NSLog(@"ABManager - authorized");
        
        ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressbook);
        CFIndex numPeople = ABAddressBookGetPersonCount(addressbook);
        
        NSMutableSet *linkedPersonsToSkip = [[NSMutableSet alloc] init];
        
        for (NSInteger i = 0; i < numPeople; i++) {
            
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);

            if ([linkedPersonsToSkip containsObject:(__bridge id)(person)]) {
                continue;
            }
            
            ABRecordID recordID = ABRecordGetRecordID(person);
            
            //Get first/last name
            NSString *personFirstName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            
            ABManagedPerson *newPerson = [ABManagedPerson new];
            newPerson.recordID = recordID;
            newPerson.firstName = personFirstName;
            
            //Merge linked contacts
            NSArray *linked = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person);

            if ([linked count] > 1) {
                [linkedPersonsToSkip addObjectsFromArray:linked];
                
            }
            [contacts addObject:newPerson];
        }
        
        //put contacts in alphabetical order using first name
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES];
        contacts = [[contacts sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] mutableCopy];
        
        //Remove contacts with no first and last name
        NSMutableArray *personsToRemove = [NSMutableArray new];
        for (ABManagedPerson *person in contacts) {
            if ((person.firstName == nil || [person.firstName isEqualToString:@""]) &&
                (person.lastName == nil || [person.lastName isEqualToString:@""])) {
                [personsToRemove addObject:person];
            }
        }
        [contacts removeObjectsInArray:personsToRemove];
        
        CFRelease(addressbook);
        CFRelease(allPeople);
    }
    
    
}

@end

@implementation ABManagedPerson

@synthesize recordID;
@synthesize firstName = _firstName, lastName = _lastName;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)firstName {
    if (!_firstName) {
        ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressbook, self.recordID);
        _firstName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        CFRelease(addressbook);
    }
    return _firstName;
}

- (NSString *)lastName {
    if (!_lastName) {
        ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressbook, self.recordID);
        _lastName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        CFRelease(addressbook);
    }
    return _lastName;
}

- (NSString *)middleName {
    ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressbook, self.recordID);
    NSString *middleName = (NSString *)CFBridgingRelease(ABRecordCopyValue(person, kABPersonMiddleNameProperty));
    CFRelease(addressbook);
    return middleName;
}

- (NSArray *)phoneNumbers {
    ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressbook, self.recordID);
    
    //Get phone numbers from person
    ABMutableMultiValueRef phoneList = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex numPhones = ABMultiValueGetCount(phoneList);
    
    NSMutableArray *numbersMutable = [NSMutableArray new];
    for (NSInteger j = 0; j < numPhones; j++) {
        
        CFTypeRef abPhone = ABMultiValueCopyValueAtIndex(phoneList, j);
        NSString *personPhone = (NSString *)CFBridgingRelease(abPhone);
        
        [numbersMutable addObject:personPhone];
    }
    CFRelease(phoneList);
    
    //Merge linked contacts
    NSArray *linked = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person);
    
    if ([linked count] > 1) {
        
        //merge linked contact phone numbers
        for (int m = 0; m < [linked count]; m++) {
            ABRecordRef iLinkedPerson = (__bridge ABRecordRef)([linked objectAtIndex:m]);
            
            // don't merge the same contact
            if (iLinkedPerson != person) {
                ABMutableMultiValueRef linkedPhoneList = ABRecordCopyValue(person, kABPersonEmailProperty);
                CFIndex numPhones = ABMultiValueGetCount(linkedPhoneList);
                for (NSInteger j = 0; j < numPhones; j++) {
                    
                    CFTypeRef abPhone = ABMultiValueCopyValueAtIndex(linkedPhoneList, j);
                    NSString *personNumber = (NSString *)CFBridgingRelease(abPhone);
                    
                    [numbersMutable addObject:personNumber];
                }
                CFRelease(linkedPhoneList);
            }
        }
        
    }
    
    CFRelease(addressbook);
    
    return numbersMutable;
}

- (NSArray *)emails {
    ABAddressBookRef addressbook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressbook, self.recordID);
    
    //Get emails from person
    ABMutableMultiValueRef emailList = ABRecordCopyValue(person, kABPersonEmailProperty);
    CFIndex numEmails = ABMultiValueGetCount(emailList);
    
    NSMutableArray *emailsMutable = [NSMutableArray new];
    for (NSInteger j = 0; j < numEmails; j++) {
        
        CFTypeRef abEmail = ABMultiValueCopyValueAtIndex(emailList, j);
        NSString *personEmail = (NSString *)CFBridgingRelease(abEmail);
        
        [emailsMutable addObject:personEmail];
    }
    CFRelease(emailList);
    
    //Merge linked contacts
    NSArray *linked = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(person);
    
    if ([linked count] > 1) {
        
        //merge linked contact emails
        for (int m = 0; m < [linked count]; m++) {
            ABRecordRef iLinkedPerson = (__bridge ABRecordRef)([linked objectAtIndex:m]);
            
            // don't merge the same contact
            if (iLinkedPerson != person) {
                ABMutableMultiValueRef linkedEmailList = ABRecordCopyValue(person, kABPersonEmailProperty);
                CFIndex numEmails = ABMultiValueGetCount(linkedEmailList);
                for (NSInteger j = 0; j < numEmails; j++) {
                    
                    CFTypeRef abEmail = ABMultiValueCopyValueAtIndex(linkedEmailList, j);
                    NSString *personEmail = (NSString *)CFBridgingRelease(abEmail);
                    
                    [emailsMutable addObject:personEmail];
                }
                CFRelease(linkedEmailList);
            }
        }
        
    }
    
    CFRelease(addressbook);
    
    return emailsMutable;
}

@end
