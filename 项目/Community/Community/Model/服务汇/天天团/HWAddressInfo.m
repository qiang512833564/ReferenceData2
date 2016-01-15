//
//  HWAddressInfo.m
//  Community
//
//  Created by ryder on 8/3/15.
//  Copyright (c) 2015 caijingpeng. All rights reserved.
//

#import "HWAddressInfo.h"

@implementation HWAddressInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.isSelected = @"0";
        self.addressId = [dictionary stringObjectForKey:@"addressId"];
        self.userId = [dictionary stringObjectForKey:@"userId"];
        self.name = [dictionary stringObjectForKey:@"name"];
        self.address = [dictionary stringObjectForKey:@"address"];
        self.mobile = [dictionary stringObjectForKey:@"mobile"];
        self.isDefault = [dictionary stringObjectForKey:@"isDefault"];
        self.province= [dictionary stringObjectForKey:@"province"];
        self.city= [dictionary stringObjectForKey:@"city"];
        self.area= [dictionary stringObjectForKey:@"area"];
    }
    return self;
}


@end
