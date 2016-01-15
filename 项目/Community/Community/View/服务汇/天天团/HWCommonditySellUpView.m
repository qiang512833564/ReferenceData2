//
//  HWCommonditySellUpView.m
//  Community
//
//  Created by ryder on 7/28/15.
//  Copyright (c) 2015 caijingpeng. All rights reserved.
//
//  功能描述：
//      天天团商品售完页面
//  修改记录：
//      姓名         日期              修改内容
//     程耀均     2015-07-28           创建文件

#import "HWCommonditySellUpView.h"

@implementation HWCommonditySellUpView

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
    if (self)
    {
        [self initTitleView];
        [self initTitleLabel];
        [self initStrollButton];
        
    }
    return self;
}

- (void)initTitleView
{
    CGRect frame = CGRectMake((kScreenWidth - 68)/2, kScreecHeight * 0.2, 68, 68);
    self.titleView = [[UIImageView alloc] initWithFrame:frame];
    [self.titleView setImage:[UIImage imageNamed:@"下手慢了，商品已被抢光"]];
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
    [self.titleLabel setText:@"下手慢了，商品已被抢光"];
    [self.titleLabel setTextColor:THEME_COLOR_TEXT];
    [self.titleLabel setBackgroundColor:[UIColor clearColor]];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:self.titleLabel];
}

- (void)initStrollButton
{
    NSInteger padindg = 30;
    CGRect frame = CGRectZero;
    frame.origin = CGPointMake(padindg, CGRectGetMaxY(self.titleLabel.frame) + padindg);
    frame.size = CGSizeMake(kScreenWidth - padindg * 2, 90/2);
    self.strollButton = [[UIButton alloc] initWithFrame:frame];
    [self.strollButton setTitle:@"去逛逛其他商品" forState:UIControlStateNormal];
    [self.strollButton.titleLabel setFont:[UIFont boldSystemFontOfSize:TITLE_BIG_SIZE]];
    [self addSubview:self.strollButton];
    [self.strollButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.strollButton setBackgroundImage:[Utility imageWithColor:UIColorFromRGB(0xF2F2F2) andSize:[_strollButton size]] forState:UIControlStateNormal];
    [self.strollButton addTarget:self action:@selector(goStrolling:) forControlEvents:UIControlEventTouchUpInside];
    [self.strollButton.layer setCornerRadius:3.5f];
    [self.strollButton setClipsToBounds:YES];
}

- (void)goStrolling:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didShowCommodityList)])
    {
        [self.delegate didShowCommodityList];
    }
}


@end
