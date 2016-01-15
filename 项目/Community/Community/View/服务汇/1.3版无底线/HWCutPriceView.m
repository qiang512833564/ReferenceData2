//
//  HWCutPriceView.m
//  Community
//
//  Created by lizhongqiang on 15/4/20.
//  Copyright (c) 2015年 caijingpeng. All rights reserved.
//

#import "HWCutPriceView.h"
#import "HWCutPriceCell.h"
#import "HWCutResultModel.h"
#import "HWLuckDrawViewController.h"
#import "HWTreasureRuleViewController.h"
#import "HWLuckDrawResultViewController.h"
#import "HWCountDownCustomView.h"
#import "AppDelegate.h"
#import "HWLuckNoAwardViewController.h"
#import "HWRechargeViewController.h"
#import "WXApi.h"
#import <TencentOpenAPI/QQApi.h>


#define AlertTag        999

@interface HWCutPriceView()
{
    //已经分享次数
    int hasShareCount;
    //剩余砍价次数
    int remainCount;
    //奖励砍价次数
    int shareCount;
    NSString *shareContent;
}
@end


@implementation HWCutPriceView
@synthesize delegate;
@synthesize productId;
@synthesize isHistory;


- (id)initWithFrame:(CGRect)frame productId:(NSString *)proId joinActivity:(HWJoinedActivityModel *)joinModel
{
    self = [super initWithFrame:frame];
    if (self)
    {
        isNeedHeadRefresh = NO;
        isHeadLoading = NO;
        isTailLoading = NO;
        refrehHeadview.hidden = YES;
        [self.baseTable setFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT + 64 - 45 + 20)];
        self.baseTable.dataSource = self;
        self.baseTable.delegate = self;
        self.productId = proId;
        activityModel = joinModel;
        
        
        [self queryHeadData];
        [self initCutPriceTF];
    }
    return self;
}

- (void)initHeadView
{
    UIView *headView = [[UIView alloc] init];
    [headView setBackgroundColor:[UIColor clearColor]];
    headView.frame = CGRectMake(0, 0, kScreenWidth, 208);
    
    
    _btnShare = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnShare setBackgroundImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    [_btnShare setFrame:CGRectMake(kScreenWidth - 50, 50, 33.5, 33.5)];
    [_btnShare addTarget:self action:@selector(btnShareClick:) forControlEvents:UIControlEventTouchUpInside];
    _btnShare.hidden = YES;
    [self addSubview:_btnShare];
    
    
    _imageTop = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 208)];
    [_imageTop setBackgroundColor:[UIColor clearColor]];
    [_imageTop setBackgroundColor:THEME_COLOR_TEXTBACKGROUND];
    __block UIImageView *blockImage = _imageTop;
    __block HWCutPriceView *weakSelf = self;
    [_imageTop setImageWithURL:[NSURL URLWithString:[Utility imageDownloadWithMongoDbKey:detailModel.bigImg]] placeholderImage:[UIImage imageNamed:IMAGE_PLACE] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (!error)
        {
            [blockImage setImage:image];
        }
        else
        {
            [blockImage setImage:[UIImage imageNamed:IMAGE_BREAK_CUBE]];
        }
    }];
    [headView addSubview:_imageTop];
    
    _smallImageTop = [[UIImageView alloc]init];
    __weak UIImageView *blockImgV = _smallImageTop;
    [_smallImageTop setImageWithURL:[NSURL URLWithString:[Utility imageDownloadWithMongoDbKey:detailModel.smallImg]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (!error)
        {
            [blockImgV setImage:image];
            weakSelf.btnShare.hidden = NO;
        }
        else
        {
            
            [blockImgV setImage:[UIImage imageNamed:@"Icon"]];
            weakSelf.btnShare.hidden = YES;
        }
        
        if ([Utility isNullQQAndWX])
        {
            weakSelf.btnShare.hidden = YES;
        }
        else
        {
            weakSelf.btnShare.hidden = NO;
        }
    }];
    
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnBack setBackgroundImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [btnBack setFrame:CGRectMake(14, 50, 33.5, 33.5)];
    [btnBack addTarget:self action:@selector(btnBackClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnBack];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 210, kScreenWidth - 30, 30)];
    [nameLabel setBackgroundColor:[UIColor clearColor]];
    [nameLabel setTextColor:THEME_COLOR_SMOKE];
    [nameLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALLTITLE]];
    [nameLabel setText:detailModel.productName];
    [headView addSubview:nameLabel];
    
    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(11, 235, kScreenWidth - 30, 30)];
    [priceLabel setBackgroundColor:[UIColor clearColor]];
    [priceLabel setTextColor:THE_COLOR_RED];
    [priceLabel setFont:[UIFont fontWithName:FONTNAME size:TITLE_BIG_SIZE]];
    double price = [detailModel.marketPrice doubleValue];
    if (price > 0)
    {
        [priceLabel setText:[NSString stringWithFormat:@"￥%.2f",price]];
    }
    else
    {
        [priceLabel setText:@"￥0"];
    }
    CGSize priceSize = [Utility calculateStringWidth:priceLabel.text font:priceLabel.font constrainedSize:CGSizeMake(CGFLOAT_MAX, 30)];
    priceLabel.frame = CGRectMake(12, 235, priceSize.width, 30);
    [headView addSubview:priceLabel];
    
    float widthX = 15 + priceSize.width + 5;
    
    UIImageView *priceImage = [[UIImageView alloc] initWithFrame:CGRectMake(widthX, 245, 31, 12)];
    [priceImage setBackgroundColor:[UIColor clearColor]];
    [priceImage setImage:[UIImage imageNamed:@"price"]];
    [headView addSubview:priceImage];
    
    widthX += priceImage.frame.size.width + 20;
    
    UILabel *shicahngjia = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, 31, 12)];
    [shicahngjia setBackgroundColor:[UIColor clearColor]];
    [shicahngjia setText:@"市场价"];
    [shicahngjia setTextColor:[UIColor whiteColor]];
    [shicahngjia setFont:[UIFont fontWithName:FONTNAME size:9]];
    [priceImage addSubview:shicahngjia];
    
    UILabel *taxLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthX, 244, 100, 14)];
    [taxLabel setBackgroundColor:[UIColor clearColor]];
    [taxLabel setText:@"手续费："];
    [taxLabel setTextColor:THEME_COLOR_TEXT];
    [taxLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL12]];
    CGSize sizeTax = [Utility calculateStringWidth:taxLabel.text font:taxLabel.font constrainedSize:CGSizeMake(CGFLOAT_MAX, 14)];
    taxLabel.frame = CGRectMake(widthX, 244, sizeTax.width, 14);
    [headView addSubview:taxLabel];
    
    widthX += sizeTax.width;
    
    UIImageView *imgKLB = [[UIImageView alloc] initWithFrame:CGRectMake(widthX, 240, 20, 20)];
    [imgKLB setBackgroundColor:[UIColor clearColor]];
    [imgKLB setImage:[UIImage imageNamed:@"KLB_small"]];
    [headView addSubview:imgKLB];
    
    widthX += imgKLB.frame.size.width + 10;
    
    UILabel *klbLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthX, 244, kScreenWidth - widthX, 14)];
    [klbLabel setBackgroundColor:[UIColor clearColor]];
    [klbLabel setTextColor:THEME_COLOR_TEXT];
    [klbLabel setText:detailModel.poundage];
    [klbLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL12]];
    [headView addSubview:klbLabel];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 244 + 20, kScreenWidth - 30, 20)];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setTextColor:THEME_COLOR_TEXT];
    [infoLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL12]];
    [infoLabel setText:detailModel.productDescribe];
    infoLabel.numberOfLines = 0;
    [infoLabel sizeToFit];
    [headView addSubview:infoLabel];
    CGSize sizeInfo = [Utility calculateStringHeight:infoLabel.text font:infoLabel.font constrainedSize:CGSizeMake(kScreenWidth - 30, CGFLOAT_MAX)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, infoLabel.frame.origin.y + sizeInfo.height + 5, kScreenWidth, 20)];
    label.textColor = THEME_COLOR_TEXT;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:FONTNAME size:THEME_FONT_SUPERSMALL];
    label.textAlignment = NSTextAlignmentLeft;
    label.adjustsFontSizeToFitWidth = YES;
    label.text = @"活动产生的任何影响均和苹果公司（Apple.Inc）无关";
    [headView addSubview:label];
    
    //@"苹果公司（Apple.Inc）并非活动赞助商，活动产生的任何影响均和苹果公司（Apple.Inc）无关。";
    
    CALayer *line1 = [[CALayer alloc] init];
    line1.frame = CGRectMake(15, label.frame.origin.y + label.height + 5, kScreenWidth - 15, 0.5f);
    [line1 setBackgroundColor:THEME_COLOR_LINE.CGColor];
    [headView.layer addSublayer:line1];
    
    float heightH = line1.frame.origin.y;
    
    UIImageView *clockImgv = [UIImageView newAutoLayoutView];
    [headView addSubview:clockImgv];
    clockImgv.image = [UIImage imageNamed:@"time4"];
    [clockImgv autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:headView withOffset:15];
    [clockImgv autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:headView withOffset:heightH + 13.5];
    
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(38, heightH + 7, 150, 30)];
    [timeLabel setBackgroundColor:[UIColor clearColor]];
    [timeLabel setTextColor:THEME_COLOR_GRAY_MIDDLE];
    [timeLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALLTITLE]];
    [headView addSubview:timeLabel];
    
    UIButton *btnTime = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnTime setFrame:CGRectMake(kScreenWidth - 70, heightH + 10, 53, 24)];
    [btnTime setTitle:@"设置" forState:UIControlStateNormal];
    [btnTime.titleLabel setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL13]];
    [btnTime setTitleColor:UIColorFromRGB(0x55bb23) forState:UIControlStateNormal];
    [btnTime addTarget:self action:@selector(btnTimeClick:) forControlEvents:UIControlEventTouchUpInside];
    btnTime.layer.cornerRadius = 5;
    btnTime.layer.masksToBounds = YES;
    btnTime.layer.borderColor = UIColorFromRGB(0x55bb23).CGColor;
    btnTime.layer.borderWidth = 1.0f;
    [headView addSubview:btnTime];
    
    CALayer *line2 = [[CALayer alloc] init];
    line2.frame = CGRectMake(0, line1.frame.origin.y + 43.5f, kScreenWidth, 0.5f);
    [line2 setBackgroundColor:THEME_COLOR_LINE.CGColor];
    [headView.layer addSublayer:line2];
    
    heightH += 44;
    
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(0, heightH, kScreenWidth, 10)];
    [grayView setBackgroundColor:UIColorFromRGB(0xf4f4f4)];
    [headView addSubview:grayView];
    
    heightH += 10;
    
    UIView *myRecordView = [[UIView alloc] initWithFrame:CGRectMake(0, heightH, kScreenWidth, 40)];
    [myRecordView setBackgroundColor:[UIColor whiteColor]];
    [headView addSubview:myRecordView];
    
    UILabel *recordLab = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, kScreenWidth - 30, 20)];
    [recordLab setBackgroundColor:[UIColor clearColor]];
    [recordLab setText:@"我的砍价记录"];
    [recordLab setTextColor:THEME_COLOR_SMOKE];
    [recordLab setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_BIG]];
    [myRecordView addSubview:recordLab];
    
    CALayer *line3 = [[CALayer alloc] init];
    line3.frame = CGRectMake(0, 39.5f, kScreenWidth, 0.5f);
    [line3 setBackgroundColor:THEME_COLOR_LINE.CGColor];
    [myRecordView.layer addSublayer:line3];
    
    heightH += 40;
    
    headView.frame = CGRectMake(0, 0, kScreenWidth, heightH);
    [self.baseTable setTableHeaderView:headView];
}

- (void)btnBackClick:(id)sender
{
    if (delegate) {
        [delegate backClick];
    }
}

-(void)showAlertViewWithMessage:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert showAlertViewWithCompleteBlock:^(NSInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            if (delegate)
            {
                [delegate shareUrl:detailModel.shareUrl shareImage:_smallImageTop.image ShareContent:shareContent];
            }
        }
    }];
}

- (void)btnShareClick:(id)sender
{
    //不限制砍价次数
    if (remainCount == -1)
    {
        if (delegate)
        {
            [delegate shareUrl:detailModel.shareUrl shareImage:_smallImageTop.image ShareContent:shareContent];
        }
    }
    //限制次数
    else
    {
        //奖励次数>0
        if (shareCount > 0)
        {
            //砍价次数=0
            if (remainCount == 0)
            {
                //已经分享
                if (hasShareCount > 0)
                {
                    [self showAlertViewWithMessage:@"一个人砍价不过瘾，快告诉其他父老乡亲（本次分享没有奖励）"];
                }
                //没有分享
                else
                {
                    NSString *str = [NSString stringWithFormat:@"亲，砍价次数用完了，第一次分享成功奖励%d次砍价机会！",shareCount];
                    [self showAlertViewWithMessage:str];
                }
            }
            //砍价次数>0
            else if (remainCount > 0)
            {
                //已经分享
                if (hasShareCount > 0)
                {
                    [self showAlertViewWithMessage:@"一个人砍价不过瘾，快告诉其他父老乡亲（本次分享没有奖励）"];
                }
                //没有分享
                else
                {
                    NSString *str = [NSString stringWithFormat:@"第一次分享成功奖励%d次砍价次数！",shareCount];
                    [self showAlertViewWithMessage:str];
                }
            }
            else
            {
                [self showAlertViewWithMessage:@"一个人砍价不过瘾，快告诉其他父老乡亲（本次分享没有奖励）"];
            }
        }
        else
        {
            [self showAlertViewWithMessage:@"一个人砍价不过瘾，快告诉其他父老乡亲（本次分享没有奖励）"];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == AlertTag + 3)
    {
        if (buttonIndex == 1)
        {
            HWRechargeViewController *rechargeVC = [[HWRechargeViewController alloc] init];
            rechargeVC.isCutPricePushed = YES;
            if (delegate && [delegate respondsToSelector:@selector(pushViewControllerWithDelegate:)]) {
                [delegate pushViewControllerWithDelegate:rechargeVC];
            }
        }
    }
}

#pragma mark - 设置闹钟
- (void)btnTimeClick:(id)sender
{
    [self endEditing:YES];
    
    HWCountDownCustomView * countView = [[HWCountDownCustomView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT + 64) WithType:@"开奖"];
    [countView show];
    
    
    countView.sureBtnBlock = ^(NSInteger time)
    {
        [Utility removeAlertItemWithProductId:detailModel.Id];
        if (time == 0)
        {
            [[HWUserLogin currentUserLogin] removeAlertItemById:detailModel.Id];
            [Utility showToastWithMessage:@"闹钟已关闭" inView:self];
            return ;
        }
        long long alertTime = ABS(detailModel.remainMs.longLongValue) / 1000.0f - time - _theTime;
        if (alertTime <= 0)
        {
            AppDelegate *appDel = SHARED_APP_DELEGATE;
            [Utility showToastWithMessage:[NSString stringWithFormat:@"还有%.0f分钟就结束了", ceilf(detailModel.remainMs.longLongValue / 1000.0f - _theTime) / 60.0f] inView:appDel.window];
            return;
        }
        
        long long alertTimeStamp = [[NSDate date] timeIntervalSince1970] + alertTime;
        
        HWAlertModel *model = [[HWAlertModel alloc] init];
        model.goodsId = detailModel.Id;
        model.alertTime = [NSString stringWithFormat:@"%lld", alertTimeStamp];
        [[HWUserLogin currentUserLogin] saveUserAlertTime:model];
        
        //        NSLog(@"倒计时%ld",(long)time);
        UIApplication *app = [UIApplication sharedApplication];
        
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)])
        {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
        }
        
        //        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:10];
        UILocalNotification * noti = [[UILocalNotification alloc]init];
        if (noti)
        {
            noti.fireDate = [NSDate dateWithTimeIntervalSince1970:alertTimeStamp];
            //            noti.fireDate = [NSDate dateWithTimeIntervalSince1970:alertTimeStamp];
            noti.timeZone = [NSTimeZone defaultTimeZone];
            noti.soundName = UILocalNotificationDefaultSoundName;
            noti.alertBody = [NSString stringWithFormat:@"%@ 开奖了",detailModel.productName];
            NSDictionary * infoDic = [NSDictionary dictionaryWithObject:detailModel.Id forKey:@"goodsId"];
            noti.userInfo = infoDic;
            [app scheduleLocalNotification:noti];
            //            [HWCoreDataManager removeAlertItmeByGoodsId:detailModel.Id];
        }
        [Utility showToastWithMessage:@"闹钟提醒设置成功" inView:self];
    };
}

- (void)bigBtnTF
{
    [txtField becomeFirstResponder];
}

- (void)initCutPriceTF
{
    UIButton *bigBtnWithTF = [UIButton buttonWithType:UIButtonTypeCustom];
    [bigBtnWithTF setBackgroundColor:[UIColor clearColor]];
    [bigBtnWithTF setFrame:CGRectMake(0, CONTENT_HEIGHT - 45 + 64, kScreenWidth - 120, 65)];
    [bigBtnWithTF addTarget:self action:@selector(bigBtnTF) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:bigBtnWithTF];
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CONTENT_HEIGHT + 64 - 45 + 20, kScreenWidth, 45)];
    [bottomView setBackgroundColor:THEME_COLOR_GRAY_HEADBACK];
    [bottomView setUserInteractionEnabled:YES];
    [self addSubview:bottomView];
    
    CALayer *line = [[CALayer alloc] init];
    line.frame = CGRectMake(0, 0, kScreenWidth, 0.5f);
    line.backgroundColor = THEME_COLOR_LINE.CGColor;
    [bottomView.layer addSublayer:line];
    
    UITextField *bgTxtField = [[UITextField alloc] initWithFrame:CGRectMake(15, 8, kScreenWidth - 120, 30)];
    [bgTxtField setBackgroundColor:[UIColor whiteColor]];
    bgTxtField.layer.borderWidth = 0.5f;
    bgTxtField.layer.borderColor = THEME_COLOR_LINE.CGColor;
    bgTxtField.layer.cornerRadius = 5;
    bgTxtField.layer.masksToBounds = YES;
    [bgTxtField setUserInteractionEnabled:NO];
    [bottomView addSubview:bgTxtField];
    
    txtField = [[UITextField alloc] initWithFrame:CGRectMake(23, 8, kScreenWidth - 120, 30)];
    [txtField setBackgroundColor:[UIColor clearColor]];
    float lowestPrice = [detailModel.lowestPrice floatValue];
    if (lowestPrice == 0)
    {
        txtField.placeholder = @"喊出你的夺宝价";
    }
    else
    {
        txtField.placeholder = [NSString stringWithFormat:@"请出大于%.2f的价格",lowestPrice];
    }
    
    [txtField setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL13]];
    [txtField setBackgroundColor:[UIColor clearColor]];
    //    txtField.layer.borderWidth = 0.5f;
    //    txtField.layer.borderColor = THEME_COLOR_LINE.CGColor;
    //    txtField.layer.cornerRadius = 5;
    //    txtField.layer.masksToBounds = YES;
    [txtField setKeyboardType:UIKeyboardTypeDecimalPad];
    txtField.delegate = self;
    [bottomView addSubview:txtField];
    
    btnCut = [HWBargainButton buttonWithFrame:CGRectMake(kScreenWidth - 95, 8, 50, 30) remainTimes:-1 delegate:self];
    [btnCut addTarget:self action:@selector(cutPrice:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:btnCut];
    //[self getRemainTimes];
}

#pragma mark - 数据请求
//获取砍价记录
- (void)queryListData
{
    //    [Utility showMBProgress:self message:LOADING_TEXT];
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:productId forKey:@"productId"];
    [param setPObject:@"1" forKey:@"source"];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [manager POST:kCutProductPrice parameters:param queue:nil success:^(id responese) {
        NSLog(@"%@",responese);
        [Utility hideMBProgress:self];
        emptyView.hidden = YES;
        [self.baseListArr removeAllObjects];
        NSDictionary *dict = [responese dictionaryObjectForKey:@"data"];
        NSArray *arrU = [dict arrayObjectForKey:@"u"];
        for (int i = 0; i < arrU.count; i ++)
        {
            HWCutPriceModel *model = [[HWCutPriceModel alloc] initWithDict:arrU[i]];
            [self.baseListArr addObject:model];
        }
        
        NSArray *arrS = [dict arrayObjectForKey:@"s"];
        for (int i = 0; i < arrS.count; i ++)
        {
            HWCutPriceModel *model = [[HWCutPriceModel alloc] initWithDict:arrS[i]];
            [self.baseListArr addObject:model];
        }
        
        if (self.baseListArr.count == 0)
        {
            [self showCutEmptyView];
        }
        
        [self.baseTable reloadData];
        
    } failure:^(NSString *code, NSString *error) {
        [Utility hideMBProgress:self];
        [self.baseTable reloadData];
    }];
    
}
//获取商品详情
- (void)queryHeadData
{
    [Utility showMBProgress:self message:LOADING_TEXT];
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:@"1" forKey:@"source"];
    [param setPObject:productId forKey:@"productId"];
    [manager POST:kCutProductDetail parameters:param queue:nil success:^(id responese) {
        NSLog(@"%@",responese);
        [Utility hideMBProgress:self];
        detailModel = [[HWProductDetailModel alloc] initWithDict:[responese dictionaryObjectForKey:@"data"]];
        shareContent = [NSString stringWithFormat:@"原价%@元的%@，1分钱砍砍砍！快来和我一起无底线！",detailModel.marketPrice,detailModel.productName];
        shareCount = [detailModel.shareCount intValue];
        [self initHeadView];
        
        _theTime = 0;
        [_theTimer invalidate];
        _theTimer = nil;
        [self startTimer];
        _theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startTimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_theTimer forMode:NSRunLoopCommonModes];
        
        [self queryListData];
    } failure:^(NSString *code, NSString *error) {
        NSLog(@"%@",error);
        if (self.delegate && [self.delegate respondsToSelector:@selector(popToDetailViewController)])
        {
            [self.delegate popToDetailViewController];
        }
        [Utility hideMBProgress:self];
        [Utility showToastWithMessage:error inView:self];
    }];
}


- (void)startTimer
{
    _theTime ++;
    long num = (long)[detailModel.remainMs longLongValue] / 1000;
    num -= _theTime;
    if (num <= 0)
    {
        timeLabel.text = @"00:00:00";
        [_theTimer invalidate];
        _theTimer = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(popToDetailViewControllerWithFefresh)])
        {
            [self.delegate popToDetailViewControllerWithFefresh];
        }
    }
    else
    {
        timeLabel.text = [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld",num / 3600, (num % 3600) / 60, num % 60];
    }
}

- (void)showCutEmptyView
{
    if (emptyView == nil)
    {
        emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, self.baseTable.tableHeaderView.frame.size.height, kScreenWidth, 100)];
        [emptyView setBackgroundColor:[UIColor clearColor]];
        [self.baseTable addSubview:emptyView];
        
        CALayer *line2 = [[CALayer alloc] init];
        line2.frame = CGRectMake(25, 0, 0.5f, 60);
        [line2 setBackgroundColor:THEME_COLOR_LINE.CGColor];
        [emptyView.layer addSublayer:line2];
        
        UIImageView *imgDot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 9, 9)];
        [imgDot setCenter:CGPointMake(25, 30)];
        [imgDot setImage:[UIImage imageNamed:@"grayDot"]];
        [emptyView addSubview:imgDot];
        
        UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(50, 25, kScreenWidth - 50 - 15, 24)];
        [detail setBackgroundColor:[UIColor clearColor]];
        [detail setFont:[UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL]];
        [detail setTextColor:THEME_COLOR_GRAY_MIDDLE];
        [detail setText:@"还没有砍价记录"];
        [emptyView addSubview:detail];
    }
}

#pragma mark - 砍价
- (void)cutPrice:(id)sender
{
    if (!([HWUserLogin currentUserLogin].telephoneNum.length > 0))
    {
        //添加代理 跳转绑定手机
        if (delegate && [delegate respondsToSelector:@selector(toBindMobile)])
        {
            [delegate toBindMobile];
        }
        return;
    }
    
    if (txtField.text.length <= 0)
    {
        [Utility showToastWithMessage:@"请输入砍价金额" inView:self yoffest:40];
        return;
    }
    [txtField resignFirstResponder];
    float price = [txtField.text floatValue];
    float lowestPrice = [detailModel.lowestPrice floatValue];
    if (price < lowestPrice) {
        [Utility showToastWithMessage:[NSString stringWithFormat:@"请输入大于%.2f的价格",lowestPrice] inView:self];
        return;
    }
    [self queryCutPrice:price];
}

//获取砍价手续费
- (void)queryCutPrice:(float)price
{
    if (![HWUserLogin currentUserLogin].telephoneNum.length > 0)
    {
        //添加代理 跳转绑定手机
        if (delegate && [delegate respondsToSelector:@selector(toBindMobile)])
        {
            [delegate toBindMobile];
        }
    }
    else
    {
        [Utility showMBProgress:self message:LOADING_TEXT];
        HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        [param setPObject:self.productId forKey:@"productId"];
        [param setPObject:[NSString stringWithFormat:@"%.2f",price] forKey:@"cutPrice"];
        [param setPObject:@"1" forKey:@"source"];
        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [manager POST:kHandlingFee parameters:param queue:nil success:^(id responese) {
            NSLog(@"%@",responese);
            poundageStr = [responese stringObjectForKey:@"data"];
            [self cutPriceAndGetResult:price];
        } failure:^(NSString *code, NSString *error) {
            NSLog(@"%@",error);
            [Utility hideMBProgress:self];
            [Utility showToastWithMessage:error inView:self];
        }];
    }
}

#pragma mark - 砍价获得结果
- (void)cutPriceAndGetResult:(float)price
{
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:[NSString stringWithFormat:@"%.2f",price] forKey:@"amt"];
    [param setPObject:self.productId forKey:@"productId"];
    [param setPObject:[HWUserLogin currentUserLogin].telephoneNum forKey:@"mobileNumber"];
    [param setPObject:@"1" forKey:@"source"];
    [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
    [param setPObject:poundageStr forKey:@"fee"];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[Utility getUUIDWithoutSymbol] forKey:@"deviceInfo"];
    
    [manager POST:kCutProduct parameters:param queue:nil success:^(id responese) {
        NSLog(@"%@",responese);
        [Utility hideMBProgress:self];
        
        txtField.text = @"";
        [self queryListData];
        //        [self getRemainTimes];
        HWCutResultModel *resultModel = [[HWCutResultModel alloc] initWithDict:[responese dictionaryObjectForKey:@"data"]];
        if ([resultModel.award isEqualToString:@"1"])
        {
            HWLuckDrawViewController *luckVC = [[HWLuckDrawViewController alloc] init];
            luckVC.resultModel = resultModel;
            if (delegate && [delegate respondsToSelector:@selector(pushViewControllerWithDelegate:)]) {
                [delegate pushViewControllerWithDelegate:luckVC];
            }
        }
        else
        {
            HWLuckNoAwardViewController *noAwardVC = [[HWLuckNoAwardViewController alloc]init];
            noAwardVC.resultModel = resultModel;
            if (delegate && [delegate respondsToSelector:@selector(pushViewControllerWithDelegate:)]) {
                [delegate pushViewControllerWithDelegate:noAwardVC];
            }
            
        }
        
    } failure:^(NSString *code, NSString *error) {
        
        NSLog(@"%@",error);
        [Utility hideMBProgress:self];
        if ([code isEqualToString:@"-1"])//-1表示两种情况：考拉币不足 游客没走引导导致无考拉币账户的情况
        {
            //考拉币不足
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"考拉币不足，去充值考拉币" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去充值", nil];
            alert.tag = AlertTag + 3;
            [alert show];
        }
        else
        {
            [Utility showToastWithMessage:error inView:self];
        }
        
    }];
}

#pragma mark - 获取剩余砍价次数
//HWGoodsDetailViewController.m 已有[cutPrice getRemainTimes];
- (void)getRemainTimes
{
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:@"1" forKey:@"source"];
    [param setPObject:self.productId forKey:@"productId"];
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
    [manager POST:kCutRemainTimes parameters:param queue:nil success:^(id responese) {
        NSLog(@"%@",responese);
        hasShareCount = [[[responese dictionaryObjectForKey:@"data"] stringObjectForKey:@"hasShareCount"] intValue];
        NSString *times = [[responese dictionaryObjectForKey:@"data"] stringObjectForKey:@"times"];
        remainCount = [times intValue];
        if ([times isEqualToString:@""])
        {
            [btnCut setBargainButtonRemainTime:-1];
        }
        else
        {
            [btnCut setBargainButtonRemainTime:[times intValue]];
        }
        
        //不限次数 砍价次数为0 奖励砍价次数>0 没有分享
        if (remainCount == 0 && shareCount > 0 && !(hasShareCount > 0))
        {
            NSString *str = [NSString stringWithFormat:@"亲，砍价次数用完了，第一次分享成功奖励%d次砍价机会！",shareCount];
            [self showAlertViewWithMessage:str];
        }
        
    } failure:^(NSString *code, NSString *error) {
        //        NSLog(@"%@",error);
        [Utility showToastWithMessage:error inView:self];
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.baseListArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HWCutPriceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[HWCutPriceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    [cell setCellWithModel:self.baseListArr[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    [txtField resignFirstResponder];
}

@end
