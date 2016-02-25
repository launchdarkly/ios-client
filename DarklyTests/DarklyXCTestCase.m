//
//  Copyright © 2015 Catamorphic Co. All rights reserved.
//

#import "DarklyXCTestCase.h"
#import "LDDataManager.h"

@implementation DarklyXCTestCase

- (void)setUp {
    [super setUp];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDictionaryStorageKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kEventDictionaryStorageKey];
}

- (void)tearDown {
    [super tearDown];
}

-(void) deleteAllEvents {
}
@end
