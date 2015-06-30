# ABManager
``ABManager`` is a wrapper for the native iOS AddressBook framework.  Included is an example project that fills a table with the devices contact list.

###Usage

```
//Checks and asks for the user access to their contact list
[[ABManager sharedManager] requestAccess:^(BOOL accessGranted) {}];

//An array of ABManagedPerson objects sorted alphabetically by first name, with linked contacts merged
[ABManager sharedManager].contacts


ABManagedPerson *person = [[ABManager sharedManager].contacts objectAtIndex:i];
NSString *firstName = person.firstName;
NSString *lastName = person.lastName;
NSArray *emails = person.emails;
NSArray *numbers = person.phoneNumbers;

```

###Installation

Add ```ABManager.h``` and ```ABManager.m``` to your project.

```#import "ABManager.h"``` and have access to ```ABManager``` and ```ABManagedPerson``` objects.
