//
//  HWConfirmPayViewController.m
//  Community
//
//  Created by hw500029 on 15/8/5.
//  Copyright (c) 2015年 caijingpeng. All rights reserved.
//

#import "HWConfirmPayViewController.h"
#import "HWConfirmPayView.h"
#import "HWReceiveAddressViewController.h"
#import "HWOrderSuccessViewController.h"
#import "AppDelegate.h"

@interface HWConfirmPayViewController ()<HWConfirmPayViewDelegate>
{
    UILabel *_countDownLabel;
    HWConfirmPayView *_refreshView;
    NSTimer *_timer;
    long long _countDownScd;
}
@end

@implementation HWConfirmPayViewController

- (void)dealloc
{
    [_timer invalidate];
    _timer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [Utility navTitleView:@"确认订单"];
    
    UIButton *clockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clockBtn.frame = CGRectMake(0, 0, 30, 34);
    clockBtn.backgroundColor = [UIColor clearColor];
    [clockBtn setImage:[UIImage imageNamed:@"倒计时"] forState:UIControlStateNormal];
    [clockBtn setImageEdgeInsets:UIEdgeInsetsMake(-1.5, 30, 1.5, -30)];
    [clockBtn setImage:[UIImage imageNamed:@"倒计时"] forState:UIControlStateSelected];
    
    //MYP add 用label做倒计时显示
    _countDownLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 13 * 4, TF13)];
    _countDownLabel.backgroundColor = [UIColor clearColor];
    _countDownLabel.font = FONT(TF13);
    _countDownLabel.textAlignment = NSTextAlignmentRight;
    _countDownLabel.textColor = THEME_COLOR_TEXT;
    _countDownLabel.text = @"--:--";
    
    UIBarButtonItem *clockImg = [[UIBarButtonItem alloc]initWithCustomView:clockBtn];
    UIBarButtonItem *countDown = [[UIBarButtonItem alloc]initWithCustomView:_countDownLabel];
    
    self.navigationItem.rightBarButtonItems = @[countDown,clockImg];
    
    _refreshView = [[HWConfirmPayView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT) andOrderId:_orderId];
    _refreshView.delegate = self;
    [self.view addSubview:_refreshView];
}

- (void)backMethod
{
    [super backMethod];
    
    [_timer invalidate];
    _timer = nil;
}

#pragma mark------refreshViewDelegate
-(void)pushAddressListView
{
    HWReceiveAddressViewController *addressController = [[HWReceiveAddressViewController alloc]init];
    addressController.selectedAddressId = _refreshView.addressInfo.addressId;
    [addressController setReturnSelectedAddress:^(HWAddressInfo *infoModel) {
        _refreshView.addressInfo = infoModel;
        _refreshView.model.name = infoModel.name;
        _refreshView.model.mobile = infoModel.mobile;
        _refreshView.model.address = infoModel.address;
        [_refreshView.baseTable reloadData];
    }];
    
    [self.navigationController pushViewController:addressController animated:YES];
}

- (void)pushToPaySuccessVC:(NSString *)orderId
{
    HWOrderSuccessViewController *controller = [[HWOrderSuccessViewController alloc] init];
    controller.orderId = orderId;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)startTimer
{
    long long leftTimeInterval = ([_refreshView.model.releaseWarehouseTime longLongValue] * 60 * 1000 - ([_refreshView.model.serverTime longLongValue] - [_refreshView.model.orderCreateTime longLongValue])) / 1000;
    _countDownScd = leftTimeInterval;
    
    [_timer invalidate];
    _timer = nil;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(updateTimer)
                                   userInfo:nil
                                    repeats:YES];
    //MYP add 防止tableview滚动时对timer的干扰
    [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)updateTimer
{
    if(_countDownScd <= 0)
    {
        [_timer invalidate];
        _timer = nil;
        
        AppDelegate *del = (AppDelegate *)SHARED_APP_DELEGATE;
        [Utility showToastWithMessage:@"支付超时，请重新下单" inView:del.window];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    _countDownScd--;
    
    NSInteger minutes = _countDownScd / 60;
    NSInteger seconds = _countDownScd % 60;
    
    NSString *secondString = [NSString stringWithFormat:@"%zd",seconds];
    if (seconds < 10)
    {
        secondString = [NSString stringWithFormat:@"0%zd",seconds];
    }
    
    NSString *minutesString = [NSString stringWithFormat:@"%zd",minutes];
    if (minutes < 10) {
        minutesString = [NSString stringWithFormat:@"0%zd",minutes];
    }
    
    _countDownLabel.text = [NSString stringWithFormat:@"%@:%@", minutesString,secondString];
}

@end
