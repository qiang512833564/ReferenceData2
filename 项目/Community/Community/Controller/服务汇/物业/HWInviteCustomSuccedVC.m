//
//  HWInviteCustomSuccedVC.m
//  Community
//
//  Created by niedi on 15/6/13.
//  Copyright (c) 2015年 caijingpeng. All rights reserved.
//

#import "HWInviteCustomSuccedVC.h"
#import "QRCodeGenerator.h"
#import "MTCustomActionSheet.h"
#import "AppDelegate.h"
#import "WXApi.h"

@interface HWInviteCustomSuccedVC ()<MTCustomActionSheetDelegate>

@end

@implementation HWInviteCustomSuccedVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.titleView = [Utility navTitleView:@"访客通行证"];
    
    [self loadUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    MLNavigationController *navigation = (MLNavigationController *)self.navigationController;
    navigation.canDragBack = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    MLNavigationController *navigation = (MLNavigationController *)self.navigationController;
    navigation.canDragBack = YES;
}

- (void)backMethod
{
    if (self.isExtend)
    {
        NSArray *vcArr = self.navigationController.viewControllers;
        UIViewController *lastScdVC = [vcArr pObjectAtIndex:vcArr.count - 6];
        [self.navigationController popToViewController:lastScdVC animated:YES];
    }
    else
    {
        NSArray *vcArr = self.navigationController.viewControllers;
        UIViewController *lastScdVC = [vcArr pObjectAtIndex:vcArr.count - 3];
        [self.navigationController popToViewController:lastScdVC animated:YES];
    }
}

- (void)loadUI
{
    UIScrollView *scr = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT)];
    scr.contentSize = CGSizeMake(kScreenWidth, CONTENT_HEIGHT + 1);
    [self.view addSubview:scr];
    
    DImageV *stateImg = [DImageV imagV:@"icon_success" frameX:(kScreenWidth - 60) /2.0f y:25 w:60.0f h:60.0f];
    [scr addSubview:stateImg];
    
    DLable *stateLab = [DLable LabTxt:@"邀请成功!" txtFont:TF18 txtColor:THEME_COLOR_ORANGE frameX:0 y:CGRectGetMaxY(stateImg.frame) + 15 w:kScreenWidth h:18.0f];
    stateLab.textAlignment = NSTextAlignmentCenter;
    [scr addSubview:stateLab];
    
    DLable *titleLab = [DLable LabTxt:[NSString stringWithFormat:@"已短信通知%@", _model.visitorName] txtFont:TF15 txtColor:THEME_COLOR_TEXT frameX:0 y:CGRectGetMaxY(stateLab.frame) + 11 w:kScreenWidth h:15.0f];
    titleLab.textAlignment = NSTextAlignmentCenter;
    [scr addSubview:titleLab];
    
    NSString *titleStr;
    if ([_model.dateCount isEqualToString:@"-1"])
    {
        titleStr = [NSString stringWithFormat:@"为%@小区长期访客！", _model.villageName];
    }
    else
    {
        titleStr = [NSString stringWithFormat:@"到访日期: %@ 有效天数: %@", [self getDateStr], [self getDayStr:_model.dateCount]];
    }
    
    DLable *detailLab = [DLable LabTxt:titleStr txtFont:TF15 txtColor:THEME_COLOR_TEXT frameX:0 y:CGRectGetMaxY(titleLab.frame) + 10 w:kScreenWidth h:15.0f];
    detailLab.textAlignment = NSTextAlignmentCenter;
    [scr addSubview:detailLab];
    
    DImageV *QRCodeImg = [DImageV imagV:@"" frameX:(kScreenWidth - 173) / 2.0f y:CGRectGetMaxY(detailLab.frame) + 15 w:173 h:173];
    QRCodeImg.backgroundColor = [UIColor whiteColor];
    QRCodeImg.layer.borderColor = THEME_COLOR_LINE.CGColor;
    QRCodeImg.layer.borderWidth = 0.5f;
    QRCodeImg.image = [QRCodeGenerator qrImageForString:_model.zxing imageSize:QRCodeImg.bounds.size.width];
    [scr addSubview:QRCodeImg];
    
    DButton *shareBtn = [DButton btnTxt:@"分享二维码" txtFont:TF18 frameX:15 y:CGRectGetMaxY(QRCodeImg.frame) + 25 w:kScreenWidth - 2 * 15 h:45.0f target:self action:@selector(shareBtnClick)];
    [shareBtn setStyle:DBtnStyleMain];
    [shareBtn setRadius:3.5f];
    [scr addSubview:shareBtn];
    
    scr.contentSize = CGSizeMake(kScreenWidth, CGRectGetMaxY(shareBtn.frame) + 50.0f);
}


- (void)shareBtnClick
{
    NSMutableArray *arrImage = [[NSMutableArray alloc] init];
    NSMutableArray *arrName = [[NSMutableArray alloc] init];
    if ([Utility isInstalledWX])
    {
        [arrImage addObject:@"share_weixinfriend161"];
        [arrName addObject:@"微信好友"];
    }
    
    if ([Utility isInstalledQQ])
    {
        [arrImage addObject:@"share_qq161"];
        [arrName addObject:@"QQ"];
    }
    
    MTCustomActionSheet *actionSheet = [[MTCustomActionSheet alloc] initWithFrame:CGRectZero andImageArr:arrImage nameArray:arrName orientation:0];
    actionSheet.delegate = self;
    AppDelegate *appDel = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [actionSheet showInView:appDel.window];
}

- (void)actionSheet:(MTCustomActionSheet *)actionSheet didClickButtonByIndex:(int)index
{
    if (index == 0)
    {
        [self shareToWeiXinFriend];
    }
    else
    {
        [self shareToQQFriend];
    }
}

- (NSString *)getDateStr
{
    NSString *dateStr;
    if (_model.visitorDate.length == 19)
    {
        dateStr = [_model.visitorDate substringToIndex:10];
    }
    else
    {
        dateStr = _model.visitorDate;
    }
    return dateStr;
}

- (NSString *)getDayStr:(NSString *)str
{
    NSString *returnStr = @"";
    if ([str isEqualToString:@"1"])
    {
        returnStr = @"一天";
    }
    else if ([str isEqualToString:@"2"])
    {
        returnStr = @"两天";
    }
    else if ([str isEqualToString:@"3"])
    {
        returnStr = @"三天";
    }
    else if ([str isEqualToString:@"7"])
    {
        returnStr = @"一周";
    }
    return returnStr;
}

- (void)shareToWeiXinFriend
{
    if (![WXApi isWXAppInstalled])
    {
        return;
    }
    
    NSArray *zxArr = [_model.zxing componentsSeparatedByString:@","];
    NSString *codeStr = [zxArr lastObject];
    NSString *villageStr = [zxArr pObjectAtIndex:3];
    NSString *tvIdStr = [zxArr pObjectAtIndex:2];
    NSString *shareUrl = [NSString stringWithFormat:@"%@?visitorId=%@&villageId=%@&code=%@", KShareInviteCustomUrl, tvIdStr, villageStr, codeStr];
    NSString *shareContent = [NSString stringWithFormat:@"有效期内至门卫处扫码即可入内！"];
    
    [UMSocialData defaultData].extConfig.wxMessageType = UMSocialWXMessageTypeWeb;
    [UMSocialData defaultData].extConfig.wechatSessionData.url = shareUrl;
    [UMSocialData defaultData].extConfig.title = [NSString stringWithFormat:@"邀请您%@来%@小区串门！", [self getDateStr], _model.villageName];
    [UMSocialData defaultData].urlResource.url = shareUrl;
    
    [[UMSocialDataService defaultDataService] postSNSWithTypes:@[UMShareToWechatSession] content:shareContent image:[UIImage imageNamed:@"Icon"] location:nil urlResource:nil presentedController:self completion:^(UMSocialResponseEntity *response){
        if (response.responseCode == UMSResponseCodeSuccess)
        {
            [Utility showToastWithMessage:@"分享成功" inView:self.view];
        }
        else
        {
            [Utility showToastWithMessage:@"分享失败" inView:self.view];
        }
    }];
}

- (void)shareToQQFriend
{
    if (![Utility isInstalledQQ])
    {
        return;
    }
    
    NSArray *zxArr = [_model.zxing componentsSeparatedByString:@","];
    NSString *codeStr = [zxArr lastObject];
    NSString *villageStr = [zxArr pObjectAtIndex:3];
    NSString *tvIdStr = [zxArr pObjectAtIndex:2];
    NSString *shareUrl = [NSString stringWithFormat:@"%@?visitorId=%@&villageId=%@&code=%@", KShareInviteCustomUrl, tvIdStr, villageStr, codeStr];
    NSString *shareContent = [NSString stringWithFormat:@"有效期内至门卫处扫码即可入内！"];
    
    [UMSocialData defaultData].extConfig.qqData.url = shareUrl;
    [UMSocialData defaultData].extConfig.qqData.title = [NSString stringWithFormat:@"邀请您%@来%@小区串门！", [self getDateStr], _model.villageName];
    [UMSocialData defaultData].extConfig.qqData.shareText = shareContent;
    [UMSocialData defaultData].extConfig.qqData.shareImage = UIImageJPEGRepresentation([UIImage imageNamed:@"Icon"], 0.1f);
    [[UMSocialDataService defaultDataService] postSNSWithTypes:@[UMShareToQQ] content:shareContent image:nil location:nil urlResource:nil presentedController:self completion:^(UMSocialResponseEntity *response) {
        
        if (response.responseCode == UMSResponseCodeSuccess)
        {
            [Utility showToastWithMessage:@"分享成功" inView:self.view];
            
        }
        else
        {
            [Utility showToastWithMessage:@"分享失败" inView:self.view];
        }
    }];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
