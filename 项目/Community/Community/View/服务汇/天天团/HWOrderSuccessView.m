//
//  HWOrderSuccessView.m
//  Community
//
//  Created by ryder on 7/28/15.
//  Copyright (c) 2015 caijingpeng. All rights reserved.
//
//  功能描述：
//      天天团支付成功页面
//  修改记录：
//      姓名         日期              修改内容
//     程耀均     2015-07-28           创建文件


#import "HWOrderSuccessView.h"
#import "AppDelegate.h"

@implementation HWOrderSuccessView

- (instancetype)init
{
    CGRect frame = CGRectMake(0, 0, kScreenWidth, kScreecHeight);
    self = [self initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initTitleView];
        [self initTitleLabel];
        [self initStrollButton];
        [self initOrderButton];
    }
    return self;
}

- (void)initTitleView
{
    CGRect frame = CGRectMake((kScreenWidth - 68)/2, kScreecHeight * 0.25, 68, 68);
    self.titleView = [[UIImageView alloc] initWithFrame:frame];
    [self.titleView setImage:[UIImage imageNamed:@"恭喜，下单成功"]];
    [self addSubview:self.titleView];
}

- (void)initTitleLabel
{
    NSUInteger padding = 25;
    CGRect frame = CGRectZero;//self.titleView.frame;
    frame.origin = CGPointMake(0, CGRectGetMaxY(self.titleView.frame) + padding);
    frame.size = CGSizeMake(kScreenWidth, 28);
    self.titleLabel = [[UILabel alloc] initWithFrame:frame];
    [self.titleLabel setFont:FONT(TITLE_BIG_SIZE)];
    [self.titleLabel setText:@"恭喜，下单成功"];
    [self.titleLabel setTextColor:THEME_COLOR_TEXT];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:self.titleLabel];
}

- (void)initStrollButton
{
//    NSInteger padindg = 30;
//    CGRect frame = CGRectZero;
//    frame.origin = CGPointMake(padindg, CGRectGetMaxY(self.titleLabel.frame) + padindg);
//    frame.size = CGSizeMake(kScreenWidth - padindg * 2, 90/2);
//    self.strollButton = [[UIButton alloc] initWithFrame:frame];
//    [self.strollButton setTitle:@"继续逛逛" forState:UIControlStateNormal];
//    [self.strollButton.titleLabel setFont:[UIFont boldSystemFontOfSize:TITLE_BIG_SIZE]];
//    [self addSubview:self.strollButton];
//    [self.strollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.strollButton setBackgroundColor:THEME_COLOR_ORANGE];
//    [self.strollButton addTarget:self action:@selector(goStrolling:) forControlEvents:UIControlEventTouchUpInside];
//    [self.strollButton.layer setCornerRadius:3.5f];
//    [self.strollButton setClipsToBounds:YES];
    
    CGRect frame = CGRectZero;
    frame.origin = CGPointMake(0, kScreecHeight - 90);
    frame.size = CGSizeMake(kScreenWidth, 90/2);
    self.strollButton = [[UIButton alloc] initWithFrame:frame];
    [self.strollButton setTitle:@"继续逛逛" forState:UIControlStateNormal];
    [self.strollButton.titleLabel setFont:[UIFont boldSystemFontOfSize:TITLE_BIG_SIZE]];
    [self addSubview:self.strollButton];
    [self.strollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.strollButton setBackgroundColor:THEME_COLOR_ORANGE];
    [self.strollButton addTarget:self action:@selector(goStrolling:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)initOrderButton
{
//    NSInteger padindg = 20;
//    CGRect frame = CGRectZero;
//    frame.origin = CGPointMake(CGRectGetMinX(self.strollButton.frame), CGRectGetMaxY(self.strollButton.frame) + padindg);
//    frame.size = self.strollButton.size;//CGSizeMake(kScreenWidth - padindg * 2, 90/2);
//    self.orderButton = [[UIButton alloc] initWithFrame:frame];
//    [self.orderButton setTitle:@"查看订单" forState:UIControlStateNormal];
//    [self.orderButton.titleLabel setFont:[UIFont boldSystemFontOfSize:TITLE_BIG_SIZE]];
//    [self addSubview:self.orderButton];
//    [self.orderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [self.orderButton addTarget:self action:@selector(goOrder:) forControlEvents:UIControlEventTouchUpInside];
//    [self.orderButton setBackgroundColor:[UIColor colorWithRed:102/255.0
//                                                         green:176/255.0
//                                                          blue:211/255.0
//                                                         alpha:1.0]];
//    [self.orderButton.layer setCornerRadius:3.5f];
//    [self.orderButton setClipsToBounds:YES];
    
//    NSInteger padindg = 20;
    CGRect frame = CGRectZero;
    frame.origin = CGPointMake(0, kScreecHeight - 40);
    frame.size = self.strollButton.size;//CGSizeMake(kScreenWidth - padindg * 2, 90/2);
    self.orderButton = [[UIButton alloc] initWithFrame:frame];
    [self.orderButton setTitle:@"查看订单" forState:UIControlStateNormal];
    [self.orderButton.titleLabel setFont:[UIFont boldSystemFontOfSize:TITLE_BIG_SIZE]];
    [self addSubview:self.orderButton];
    [self.orderButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.orderButton addTarget:self action:@selector(goOrder:) forControlEvents:UIControlEventTouchUpInside];
    [self.orderButton setBackgroundColor:[UIColor colorWithRed:208/255.0
                                                         green:68/255.0
                                                          blue:64/255.0
                                                         alpha:1.0]];
//    [self.orderButton.layer setCornerRadius:3.5f];
//    [self.orderButton setClipsToBounds:YES];
}


- (void)goStrolling:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didShowCommodityList)])
    {
        [self.delegate didShowCommodityList];
    }
}

- (void)goOrder:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didShowOrderList)])
    {
        [self.delegate didShowOrderList];
    }
}
@end
