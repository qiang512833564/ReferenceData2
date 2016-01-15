//
//  HWOrderSuccessViewController.h
//  Community
//
//  Created by ryder on 7/30/15.
//  Copyright (c) 2015 caijingpeng. All rights reserved.
//

#import "HWRefreshBaseViewController.h"
#import "HWOrderSuccessView.h"
#import "HWTianTianTuanDetailVC.h"

@interface HWOrderSuccessViewController : HWRefreshBaseViewController<HWCommodityDelegate>

@property (nonatomic, strong) HWOrderSuccessView *orderSurccessView;
@property (nonatomic, strong) NSString *orderId;

@end
