//
//  HWServiceViewController.m
//  Community
//
//  Created by caijingpeng.haowu on 14-8-28.
//  Copyright (c) 2014年 caijingpeng. All rights reserved.
//
//  功能描述：
//      懒生活首页
//  修改记录：
//      姓名         日期               修改内容
//     蔡景鹏     2015-01-21           修改布局
//     杨庆龙     2015-04-02           修改跳到1.3版砍价商品列表
//      李中强     2015-04-08          首页去掉店铺
//      聂迪       2015-07-09          添加消息中心 及 icon功能
//

#import "HWServiceViewController.h"
#import "AppDelegate.h"
#import "HWTreasureViewController.h"
#import "HWAddShopViewController.h"
#import "HWBrandViewController.h"
#import "HWApplicationModel.h"
#import "HWApplicationDetailViewController.h"
#import "HWActivityModel.h"
#import "HWTreasureRuleViewController.h"
#import "WXImageView.h"
#import "HWPriviledgeDetailVC.h"
#import "HWGameSpreadVC.h"
#import "HWShopListViewController.h"
#import "HWGoodsListViewController.h"
#import "HWSaleCenterViewController.h"
#import "HWCountDownView.h"
#import "HWMessageCenterViewController.h"
#import "HWServiceIcon.h"
#import "HWWuYeServiceVC.h"
#import "HWHomeServiceVC.h"
#import "HWServiceMoreVC.h"
#import "DCycleBanner.h"
#import "HWNetWorkManager.h"
#import "HWCommondityListController.h"

#define kAPPICON_TAG    1001
#define kShopIconTag    2001

@interface HWServiceViewController ()
{
    UIView *propertyView;
    UILabel *labelInfo;
    UIView *lineBottom;
    BOOL isInfo;
    UIView *infoView;
    NSString *_phoneNum;
    UIView *gView;
    
    UIView *shopTitleView; // 周边小店
    UIView *appView;        // 顶部广告 应用 view
    UIScrollView *bannerSV;
    UIPageControl *bannerPageCtrl;
    UIView *leftViewTap;
    UIButton *addShopPhoneBtn;
    
    UIView *_headerView;
    UIView *_cubeView;
    UIView *_appView;
    UIView *_bannerView;
//    UIView *_shopsView;             //合作商铺
//    UIView *_addShopView;
    UIView *_countView;
    NSString *_cutCount;
    HWCountDownView *countDownLab;      //下场砍价倒计时
    long _theTime;                      //倒计时计数
    NSString *_theCutTime;                   //倒计时数
    NSTimer *_theTimer;                 //砍价倒计时
    
    BOOL _isNeedRefresh;
    BOOL _isQueryFinish;        //新版物业两个接口都成功刷新页面
    BOOL _isAtCompanyVillage;
    NSMutableArray *_iconArr;
    NSMutableArray *_iconModelArr;
    HWServiceIcon *_currentIcon;
    NSInteger _selectIndex;
    CGPoint _iconTouchPoint;
    
    UIView *messageCenterRedDotView;
}

@property (nonatomic, strong) NSMutableArray *appList;
@property (nonatomic, strong) NSMutableArray *activityList;

@end

@implementation HWServiceViewController
@synthesize tipAlert;
@synthesize appList;
@synthesize activityList;

//static float bigFont = 15.0f;
//static float smallFont = 13.0f;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAppData) name:RELOAD_APP_DATA object:nil];
        //RELOAD_APP_DATA   清掉缓存再加载
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRefresh) name:@"homePageRefreshIcon" object:nil];
    }
    return self;
}
- (void)reloadAppData
{
    [self getUserInfo];
    
    AppDelegate *delegate = (AppDelegate *)SHARED_APP_DELEGATE;
    [delegate.tabBarVC showServiceMessageCenterRedDot];
    
    _currentPage = 0;
    [self queryListData];
}

- (void)getUserInfo
{
    if ([[HWUserLogin currentUserLogin].coStatus isEqualToString:@"0"])
    {
        _isAtCompanyVillage = YES;
    }
    else
    {
        _isAtCompanyVillage = NO;
    }
}

- (void)setRefresh
{
    _isNeedRefresh = YES;
}

- (void)checkRefresh
{
    [self getDynamicIndex];
    [self getUserInfo];
    
    if (_isNeedRefresh)
    {
        [self queryListData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isNeedRefresh = NO;
    _isQueryFinish = NO;
    
    [self getUserInfo];
    
    self.baseTableView.frame = CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT - 49);
    self.baseTableView.showEndFooterView = YES;
    arrShop = [[NSMutableArray alloc] init];
    _phoneNum = @"";
    _currentPage = 0;
    isLastPage = YES;
    self.isNeedHeadRefresh = YES;
    _cutCount = @"0";
    
    if (_isAtCompanyVillage)
    {
        _iconModelArr = [NSMutableArray arrayWithArray:[HWCoreDataManager searchAllIcomModelForCompanyWuYe]];
        self.activityList = [NSMutableArray arrayWithArray:[HWCoreDataManager searchAllBannerModelForCompanyWuYe]];
        [self initialHeaderView];
        [self.baseTableView reloadData];
    }
    else
    {
        //缓存
        arrShop = [NSMutableArray arrayWithArray:[HWCoreDataManager searchAllShopList]];
        proItem = [HWCoreDataManager searchAllPropertyList];
        self.appList = [NSMutableArray arrayWithArray:[HWCoreDataManager searchAllApplicaitionListItem]];
        self.activityList = [NSMutableArray arrayWithArray:[HWCoreDataManager searchAllActivityListItem]];
        [self initialHeaderView];
        [self.baseTableView reloadData];
    }
    
    [self queryListData];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notification) name:NSUserDefaultsDidChangeNotification object:nil];
    NSLog(@"%lu",[UIApplication sharedApplication].enabledRemoteNotificationTypes);
    [[UIApplication sharedApplication] addObserver:self forKeyPath:@"enabledRemoteNotificationTypes" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"-------------------------notification-----------------------");
}
- (void)notification
{
    NSLog(@"------notification--------------%lu",[UIApplication sharedApplication].enabledRemoteNotificationTypes);
}
- (void)messageCenterClick
{
    AppDelegate *del = (AppDelegate *)SHARED_APP_DELEGATE;
    if ([HWUserLogin verifyBindMobileWithPopVC:del.tabBarVC showAlert:YES])
    {
        HWMessageCenterViewController *messageCenterVC = [[HWMessageCenterViewController alloc] init];
        if ([HWUserLogin verifyIsLoginWithPresentVC:del.tabBarVC toViewController:messageCenterVC])
        {
            [self.navigationController pushViewController:messageCenterVC animated:YES];
        }
    }
}

- (void)initialBannerView
{
    CGFloat height = 0;
    if (self.activityList.count != 0)
    {
        height = 165 * kScreenRate;
    }
    
    _bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_headerView.frame), height)];
    [_headerView addSubview:_bannerView];
    
    bannerSV = [[UIScrollView alloc] initWithFrame:_bannerView.bounds];
    bannerSV.scrollEnabled = NO;
    [_bannerView addSubview:bannerSV];
    
    if (self.activityList.count != 0)
    {
        //轮播banner
        DCycleBanner *banner = [DCycleBanner cycleBannerWithFrame:CGRectMake(0, 0, kScreenWidth, 165 * kScreenRate) bannerImgCount:self.activityList.count];
        [banner setImageViewAtIndex:^(UIImageView *bannerImageView, NSUInteger indexAtBanner) {
            HWActivityModel *model = [self.activityList pObjectAtIndex:indexAtBanner];
            bannerImageView.backgroundColor = IMAGE_DEFAULT_COLOR;
            __weak UIImageView *weakImgV = bannerImageView;
            [bannerImageView setImageWithURL:[NSURL URLWithString:[Utility imageDownloadWithUrl:model.activityPictureURL]] placeholderImage:[UIImage imageNamed:IMAGE_PLACE] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (error == nil)
                {
                    weakImgV.image = image;
                }
                else
                {
                    weakImgV.image = [UIImage imageNamed:IMAGE_BREAK_CUBE];
                }
            }];
        }];
        [banner setImageTapAction:^(NSUInteger indexAtBanner) {
            HWActivityModel *model = [self.activityList objectAtIndex:indexAtBanner];
            [self pushViewControllerByActivityModel:model];
            [self bannerClickStatisticalWithModel:model];
        }];
        [banner setTimerFire:YES];
        [bannerSV addSubview:banner];
    }
}

//banner点击统计
- (void)bannerClickStatisticalWithModel:(HWActivityModel *)activityModel
{
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
    [param setPObject:activityModel.activityId forKey:@"activityId"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KBannerClickStatistical parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"banner统计 responese ========================= %@",responese);
         
     } failure:^(NSString *code, NSString *error) {
         NSLog(@"banner统计错误 %@", error);
     }];
}

- (void)initialCubeView
{
    CGFloat height = 0;
    if (self.appList.count > 0)
    {
        height = 160 * 1 + 10;//kScreenRate
    }
    
    CGFloat gapWidth = 7 * kScreenRate;//kScreenRate
    
    _cubeView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(bannerSV.frame), kScreenWidth, 350/2*kScreenRate)];
    [_cubeView setBackgroundColor:[UIColor whiteColor]];
    [_headerView addSubview:_cubeView];
    
    if (self.appList.count > 0)
    {
        NSArray *frameArr = [NSArray arrayWithObjects:
                             [NSValue valueWithCGRect:CGRectMake(gapWidth, gapWidth, 142 * kScreenRate , 160 * kScreenRate)],
                             [NSValue valueWithCGRect:CGRectMake(142 * kScreenRate + gapWidth + gapWidth, gapWidth, 157 * kScreenRate, 78 * kScreenRate)],
                             [NSValue valueWithCGRect:CGRectMake(142 * kScreenRate + gapWidth + gapWidth, 78 * kScreenRate + gapWidth + gapWidth, 75 * kScreenRate, 75 * kScreenRate)],
                             [NSValue valueWithCGRect:CGRectMake((142 * kScreenRate + 75 * kScreenRate + gapWidth + gapWidth + gapWidth), 78 * kScreenRate + gapWidth +gapWidth, 75 * kScreenRate, 75 * kScreenRate)],//kScreenRate
                             nil];
        
        for (int i = 0; i < 4; i++)
        {
            NSValue *frameValue = [frameArr pObjectAtIndex:i];
            WXImageView *imageView = [[WXImageView alloc] initWithFrame:[frameValue CGRectValue]];
            imageView.backgroundColor = IMAGE_DEFAULT_COLOR;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            HWApplicationModel *appModel = [self.appList pObjectAtIndex:i];
            
            //添加手势
            imageView.touchBlock = ^{
                
                [MobClick event:@"click_weishangdianbanner"];
                NSLog(@"点击图片");
                
                [self pushViewControllerByAppModel:appModel];
                
            };
            __weak UIImageView *weakImgV = imageView;
            
            [imageView setImageWithURL:[NSURL URLWithString:[Utility imageDownloadWithMongoDbKey:appModel.iconMongodbKey]] placeholderImage:[UIImage imageNamed:IMAGE_PLACE] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                
                if (error != nil)
                {
                    weakImgV.image = [UIImage imageNamed:IMAGE_BREAK_CUBE];
                }
                else
                {
                    weakImgV.backgroundColor = [UIColor whiteColor];
                    weakImgV.image = image;
                }
                
            }];
            [_cubeView addSubview:imageView];
        }
    }
}

- (void)initialExtendAppView
{
    int count = self.appList.count - 4;
    CGFloat height = 0;
    if (count > 0)
    {
        height = 110 * ((count + 3) / 4) * 1 + 10;//kScreenRate
    }
    CGFloat gapWidth = 10 * 1;//kScreenRate
    _appView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_cubeView.frame) + gapWidth, kScreenWidth, 110)];
    _appView.backgroundColor = self.view.backgroundColor;
    [_headerView addSubview:_appView];
    
    if (height > 0)
    {
        UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 110 * ((count + 3) / 4) * 1)];//kScreenRate
        whiteView.backgroundColor = [UIColor whiteColor];
        [_appView addSubview:whiteView];
        if (IPHONE6PLUS)
        {
            whiteView.frame = CGRectMake(0, 0, kScreenWidth, 175);
        }
        
        for (int i = 0 ; i < count ; i++)
        {
            HWApplicationModel *appModel = [self.appList pObjectAtIndex:4 + i];
            
            float btnSize = 44 * kScreenRate;//kScreenRate 60
            float space = (kScreenWidth - 4 * btnSize) / 5.0f;
            float marginTop = 13 * kScreenRate;//kScreenRate
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.backgroundColor = [UIColor clearColor];
            button.frame = CGRectMake(space + i % 4 * (btnSize + space), 20, btnSize, btnSize);//kScreenRate
            [button addTarget:self action:@selector(toAppIcon:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = kAPPICON_TAG + i + 4;
            [whiteView addSubview:button];
            
            NSString *iconUrlStr = [Utility imageDownloadWithMongoDbKey:appModel.iconMongodbKey];
            
            __weak UIButton *weakButton = button;
            [button.imageView setImageWithURL:[NSURL URLWithString:iconUrlStr] placeholderImage:[UIImage imageNamed:IMAGE_PLACE] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                
                if (error != nil)
                {
                    [weakButton setImage:[UIImage imageNamed:IMAGE_BREAK_CUBE] forState:UIControlStateNormal];
                }
                else
                {
                    [weakButton setImage:image forState:UIControlStateNormal];
                }
                
            }];
            
            UILabel *label = [UILabel newAutoLayoutView];
            [whiteView addSubview:label];
            [label autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:button withOffset:10];
            [label autoSetDimension:ALDimensionHeight toSize:THEME_FONT_SMALL13];
            [label autoSetDimension:ALDimensionWidth toSize:button.size.width relation:NSLayoutRelationGreaterThanOrEqual];
            [label autoAlignAxis:ALAxisVertical toSameAxisOfView:button];
            
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = appModel.name;
            label.textColor = THEME_COLOR_SMOKE;
            label.font = [UIFont fontWithName:FONTNAME size:THEME_FONT_SMALL13];
            
        }
    }
    
}

- (void)initialCutCountView
{
    if (_countView)
    {
        [_countView removeFromSuperview];
        _countView = nil;
    }
    
    if (countDownLab)
    {
        [countDownLab removeFromSuperview];
    }
    
    HWApplicationModel *appModel = [self.appList pObjectAtIndex:0];
    // 砍价宝 必须在第一个时显示
    if ([appModel.iconUrl isEqualToString:@"kaola:cut:index"])
    {
        _countView = [[UIView alloc] initWithFrame:CGRectMake(13 * kScreenRate, 29 * kScreenRate, 70, 15)];
        _countView.backgroundColor = [UIColor clearColor];
        [_cubeView addSubview:_countView];
        
        UIFont *font = [UIFont fontWithName:FONTNAME size:10];
        
        CGSize size = [Utility calculateStringWidth:_cutCount font:font constrainedSize:CGSizeMake(1000, 15)];

        UILabel *countLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, MAX(15.0f, size.width + 5), 15 * kScreenRate)];

        countLab.font = font;
//        countLab.backgroundColor = THEME_COLOR_RED;
        countLab.backgroundColor = [UIColor clearColor];
        countLab.text = _cutCount;
        countLab.textColor = UIColorFromRGB(0x55bb23);
        countLab.textAlignment = NSTextAlignmentCenter;
        [_countView addSubview:countLab];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(countLab.frame), 5, CGRectGetWidth(_countView.frame) - CGRectGetWidth(countLab.frame) - 2.5f, 15 * kScreenRate)];

        label.backgroundColor = [UIColor clearColor];
        label.textColor = UIColorFromRGB(0x55bb23);
        label.font = font;
        label.text = @"场进行中";
        [_countView addSubview:label];
        
        countDownLab = [HWCountDownView countDownViewFrame:CGRectMake(15 * kScreenRate, 50 * kScreenRate, CGRectGetWidth(_countView.frame), 50) first:@"00" second:@"00" third:@"00"];

        [_cubeView addSubview:countDownLab];
        
    }
}

#pragma mark - tableHeaderV
- (void)initialHeaderView
{
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT - 44)];
    _headerView.backgroundColor = [UIColor clearColor];
    
    if (_isAtCompanyVillage)
    {
        [self initBannerForCompanyWY];
        [self initWithIconView];
    }
    else
    {
        [self initialBannerView];
        [self initialCubeView];
        [self initialExtendAppView];
        [self initialCutCountView];
        
        _headerView.frame = CGRectMake(0, 0, kScreenWidth, CGRectGetMaxY(_appView.frame));
    }
    self.baseTableView.tableHeaderView = _headerView;
}

#pragma mark - icon 操作处理
- (void)queryIconData
{
    /*
     URL:/hw-sq-app-web/authenticateUserHome/listIcons.do
     入参：
     key
     villageId
     出参：
     /icon名字/
     private String name;
     /icon图标/
     private String iconMongoKey;
     /link_url/
     private String linkUrl;
     /更多 4 大类/
     private String type;*/
    
    _iconModelArr = [NSMutableArray array];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
    [param setPObject:@"1.7.0" forKey:@"wyiconversion"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KServiceIconCheck parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"responese ========================= %@",responese);
         isLastPage = YES;
         
         [_iconModelArr removeAllObjects];
         
         NSArray *arr = [[responese dictionaryObjectForKey:@"data"] arrayObjectForKey:@"content"];
         for (NSDictionary *tmpDict in arr)
         {
             HWServiceIconModel *model = [[HWServiceIconModel alloc] initWithDict:tmpDict];
             [_iconModelArr addObject:model];
         }
         
         HWServiceIconModel *moreModel = [[HWServiceIconModel alloc] init];
         moreModel.name = @"更多";
         moreModel.linkUrl = @"more";
         moreModel.iconMongoKey = @" ";
         moreModel.iconImgName = @"gengduo";
         [_iconModelArr addObject:moreModel];
         
         if (_isQueryFinish == YES)
         {
             [self initialHeaderView];
         }
         else
         {
             _isQueryFinish = YES;
         }
         
         [HWCoreDataManager removeAllIconModelForCompanyWuYe];
         [HWCoreDataManager saveServiceIcomForCompanyModelArr:_iconModelArr];
         
         [self doneLoadingTableViewData];
     } failure:^(NSString *code, NSString *error) {
         [self doneLoadingTableViewData];
         [Utility showToastWithMessage:error inView:self.view];
     }];
}

- (void)commitIconChange
{
    /*URL:/hw-sq-app-web/authenticateUserHome/updateIcon.do
     入参：
     key
     villageId
     icons ----------name,name
     jsonString ----------name,iconMongoKey,linkUrl,type/name,iconMongoKey,linkUrl,type
     出参：*/
    
    HWServiceIconModel *model = [_iconModelArr pObjectAtIndex:0];
    NSMutableString *nameStr = [NSMutableString stringWithFormat:@"%@", model.name];
    NSMutableString *jsonStr = [NSMutableString stringWithFormat:@"%@,%@,%@,%@", model.name, model.iconMongoKey, model.linkUrl, model.modelType];
    for (int i = 1; i < _iconModelArr.count - 1; i++)
    {
        HWServiceIconModel *model = [_iconModelArr pObjectAtIndex:i];
        [nameStr appendFormat:@",%@", model.name];
        [jsonStr appendFormat:@"$%@,%@,%@,%@", model.name, model.iconMongoKey, model.linkUrl, model.modelType];
    }
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
    [param setPObject:nameStr forKey:@"icons"];
    [param setPObject:jsonStr forKey:@"jsonString"];
    [param setPObject:@"1.7.0" forKey:@"wyiconversion"];
    
    //保存到缓存
    [HWCoreDataManager removeAllIconModelForCompanyWuYe];
    [HWCoreDataManager saveServiceIcomForCompanyModelArr:_iconModelArr];
    
    if (![Utility isConnectionAvailable])
    {
        [[HWNetWorkManager currentManager] saveRequestWithParameters:param requestId:[NSString stringWithFormat:@"userId=%@", [HWUserLogin currentUserLogin].userId]];
        return;
    }
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KServiceIconUpdate parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"responese ========================= %@",responese);
         
     } failure:^(NSString *code, NSString *error) {
         
         [Utility showToastWithMessage:error inView:self.view];
         
         [[HWNetWorkManager currentManager] saveRequestWithParameters:param requestId:[NSString stringWithFormat:@"userId=%@", [HWUserLogin currentUserLogin].userId]];
     }];
}

- (void)initWithIconView
{
    _selectIndex = -1;
    CGFloat width = (kScreenWidth / 3.0f - 0.5f);
    CGFloat height = width;
    _iconArr = [NSMutableArray array];
    
    for (int i = 0; i < _iconModelArr.count; i++)
    {
        if (i < 2)
        {
            UIImageView *line = [DImageV imagV:nil frameX:width * (i + 1) + i % 3 * 0.5f y:CGRectGetMaxY(bannerSV.frame) + 0 w:0.5f h:height * 3];
            line.backgroundColor = THEME_COLOR_LINE;
            [_headerView addSubview:line];
            
            UIImageView *line2 = [DImageV imagV:nil frameX:0 y:CGRectGetMaxY(bannerSV.frame) + height * i + (i - 1) * 0.5f w:kScreenWidth h:0.5f];
            line2.backgroundColor = THEME_COLOR_LINE;
            [_headerView addSubview:line2];
            
            UIImageView *line3 = [DImageV imagV:nil frameX:0 y:CGRectGetMaxY(bannerSV.frame) + height * (i + 2) + (i + 1) * 0.5f w:kScreenWidth h:0.5f];
            line3.backgroundColor = THEME_COLOR_LINE;
            [_headerView addSubview:line3];
        }
        
        HWServiceIconModel *model = [_iconModelArr pObjectAtIndex:i];
        HWServiceIcon *icon = [[HWServiceIcon alloc] initWithFrame:CGRectMake(width * (i % 3) + i % 3 * 0.5f, CGRectGetMaxY(bannerSV.frame) + height * (i / 3) + i / 3 * 0.5f, width, height) model:model isDelImg:YES];
        [icon addTarget:self action:@selector(tapAction:) forIconEvents:IconTap];
        [icon addTarget:self action:@selector(iconLongPressBegain:) forIconEvents:IconLongPressBegain];
        [icon addTarget:self action:@selector(iconLongPressEnd:) forIconEvents:IconLongPressEnd];
        [icon addTarget:self action:@selector(IconPanChange:) forIconEvents:IconPanChange];
        [icon addTarget:self action:@selector(iconPanEnd:) forIconEvents:IconPanEnd];
        [icon addTarget:self action:@selector(iconDelBtnClick:) forIconEvents:iconDel];
        [_headerView addSubview:icon];
        
        [_iconArr addObject:icon];
    }
    _headerView.frame = CGRectMake(0, 0, kScreenWidth, CGRectGetMaxY(bannerSV.frame) + 3 * height + 3 * 0.5f);
    _headerView.backgroundColor = [UIColor whiteColor];
    self.baseTableView.tableHeaderView = _headerView;
}

- (void)pushVCByIconModel:(HWServiceIconModel *)model
{
    NSString *linkUrl = [model.linkUrl lowercaseString];
    NSArray *strArr = [linkUrl componentsSeparatedByString:@":"];
    
    NSString *headStr = [strArr pObjectAtIndex:0];
    if ([headStr isEqualToString:@"kaola"])
    {
        // 应用内跳转
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"wyfw"]) //物业相关
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"jiaofei"])//缴费 KaoLa:WYFW:JIAOFEI
            {
                [self pushVCByClassStr:@"HWWuYePayVC"];
            }
            else if ([thirdStr isEqualToString:@"tousuzhongxin"])//投诉 KaoLa:WYFW:TOUSUZHONGXIN
            {
                [self pushVCByClassStr:@"HWPerpotyComplaintVC"];
            }
            else if ([thirdStr isEqualToString:@"gongwubaoxiu"])//报修 KaoLa:WYFW:GONGWUBAOXIU
            {
                [self pushVCByClassStr:@"HWPublicRepairVC"];
            }
            else if ([thirdStr isEqualToString:@"fangkeyaoqing"])//访客 KaoLa:WYFW:FANGKEYAOQING
            {
                [self pushVCByClassStr:@"HWInviteCustomVC"];
            }
            else if ([thirdStr isEqualToString:@"kuaididaishou"])//邮局 KaoLa:WYFW:KUAIDIDAISHOU
            {
                [self pushVCByClassStr:@"HWPostOfficeVC"];
            }
        }
        else if ([secStr isEqualToString:@"wysm"])//Kaola:WYSM:BAOJIEFUWU:{3}
        {
            NSString *detailStr = [strArr pObjectAtIndex:3];
            
            if ([detailStr rangeOfString:@"{"].location != NSNotFound && [detailStr hasSuffix:@"}"])
            {
                if (detailStr.length < 3)
                {
                    NSLog(@"id 不能为空");
                }
                else
                {
                    [self pushVCForShangMenFuWu:model serviceId:[detailStr substringWithRange:NSMakeRange(1, detailStr.length - 2)]];
                }
            }
        }
        else if ([secStr isEqualToString:@"daydaybuy"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushToTianTianTuan];
            }
        }
        else if ([secStr isEqualToString:@"xt"])//KaoLa:XT:CHAOSHI 超市
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            
            if ([thirdStr isEqualToString:@"chaoshi"])
            {
                HWApplicationDetailViewController *appDetailVC = [[HWApplicationDetailViewController alloc] init];
                appDetailVC.navigationItem.titleView = [Utility navTitleView:model.name];
                appDetailVC.appUrl = model.linkUrl;
                [self.navigationController pushViewController:appDetailVC animated:YES];
            }
            else if ([thirdStr isEqualToString:@"wuye"])    //物业首页 KaoLa:XT:WUYE
            {
                HWWuYeServiceVC *svc = [[HWWuYeServiceVC alloc] init];
                svc.isCompany = YES;
                svc.homePageIconArr = _iconModelArr;
                [self.navigationController pushViewController:svc animated:YES];
            }
        }
        else if ([secStr isEqualToString:@"yy"])//KaoLa:YY:WUDIXIAN
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"wudixian"])
            {
                [self pushCutApplication];
            }
            else if ([thirdStr isEqualToString:@"zushouzhongxin"])//租售中心-- KaoLa:YY:ZUSHOUZHONGXIN
            {
                [self pushSaleCenter];
            }
        }
        else if ([secStr isEqualToString:@"cut"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushCutApplication];//kaola:cut:index
            }
        }
        else if ([secStr isEqualToString:@"salecenter"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushSaleCenter];
            }
        }
        else if ([secStr isEqualToString:@"zb"])//KaoLa:ZBFW:CANTING:{206}
        {
            NSString *detailStr = [strArr pObjectAtIndex:3];
            
            if ([detailStr hasPrefix:@"{"] && [detailStr hasSuffix:@"}"])
            {
                if (detailStr.length < 3)
                {
                    NSLog(@"id 不能为空");
                }
                else
                {
                    /*餐厅--KaoLa:ZBFW:CANTING
                     家政--Kaola:ZBFW:JIAZHENG:206
                     水果--Kaola:ZBFW:SHUIGUO:204
                     洗衣--Kaola:ZBFW:XIYI:205
                     开锁换锁--Kaola:ZBFW:KAISUOHUANSUO:207
                     快递--Kaola:ZBFW:KUAIDI:208
                     收废品--Kaola:ZBFW:SHOUFEIPIN:209
                     管道疏通--Kaola:ZBFW:GUANDAOSHUTONG:210
                     洗车--Kaola:ZBFW:XICHE:212
                     送水--Kaola:ZBFW:SONGSHUI:215
                     美容护理--Kaola:ZBFW:MEIRONGHULI:216
                     家电维修--Kaola:ZBFW:JIADIANWEIXIU:217
                     婴幼儿--Kaola:ZBFW:YINGYOUER:229
                     休闲小吃
                     五金
                     银行
                     运动健身
                     */
                    
                    NSString *typeId = [detailStr substringWithRange:NSMakeRange(1, detailStr.length - 2)];
                    [self pushForShop:typeId shopName:model.name];
                }
            }
        }
    }
    else if ([headStr isEqualToString:@"more"])
    {
        HWServiceMoreVC *svc = [[HWServiceMoreVC alloc] init];
        svc.homepageIconArr = _iconModelArr;
        [self.navigationController pushViewController:svc animated:YES];
    }
    else
    {
        if ([linkUrl isEqualToString:@"www.kaola.mobi/koala/h5/tuangou/description"])
        {
            [self pushToTianTianTuan];
        }
        else
        {
            // web页面
            HWApplicationDetailViewController *appDetailVC = [[HWApplicationDetailViewController alloc] init];
            appDetailVC.navigationItem.titleView = [Utility navTitleView:model.name];
            appDetailVC.appUrl = model.linkUrl;
            [self.navigationController pushViewController:appDetailVC animated:YES];
        }
    }
}

- (void)pushToTianTianTuan
{
    [MobClick event:@"click_groupon"];//1.7
    
    HWCommondityListController *controller = [[HWCommondityListController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

//普通类型（不需要传参）
- (void)pushVCByClassStr:(NSString *)classStr
{
    if (classStr.length != 0)
    {
        Class clss = NSClassFromString(classStr);
        if (clss)
        {
            if ([classStr isEqualToString:@"HWInviteCustomVC"])
            {
                if ([HWUserLogin verifyBindMobileWithPopVC:self showAlert:YES])
                {
                    HWBaseViewController *vc = [(HWBaseViewController *)[clss alloc] init];
                    
                    if ([HWUserLogin verifyIsLoginWithPresentVC:self toViewController:vc])
                    {
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                }
            }
            else if ([classStr isEqualToString:@"HWPublicRepairVC"])
            {
                if ([HWUserLogin verifyBindMobileWithPopVC:self showAlert:YES])
                {
                    HWBaseViewController *vc = [(HWBaseViewController *)[clss alloc] init];
                    if ([HWUserLogin verifyIsLoginWithPresentVC:self toViewController:vc])
                    {
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                }
            }
            else if ([classStr isEqualToString:@"HWPerpotyComplaintVC"])
            {
                if ([HWUserLogin verifyBindMobileWithPopVC:self showAlert:YES])
                {
                    HWBaseViewController *vc = [(HWBaseViewController *)[clss alloc] init];
                    if ([HWUserLogin verifyIsLoginWithPresentVC:self toViewController:vc])
                    {
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                }
            }
            else if ([classStr isEqualToString:@"HWPostOfficeVC"])
            {
                if ([HWUserLogin verifyBindMobileWithPopVC:self showAlert:YES])
                {
                    HWBaseViewController *vc = [(HWBaseViewController *)[clss alloc] init];
                    if ([HWUserLogin verifyIsLoginWithPresentVC:self toViewController:vc])
                    {
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                }
            }
            else if ([clss isSubclassOfClass:[HWBaseViewController class]])
            {
                HWBaseViewController *vc = [(HWBaseViewController *)[clss alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
    }
}

//上门服务类型
- (void)pushVCForShangMenFuWu:(HWServiceIconModel *)model serviceId:(NSString *)serviceId
{
    if ([HWUserLogin verifyBindMobileWithPopVC:self showAlert:YES])
    {
        HWHomeServiceVC *hvc = [[HWHomeServiceVC alloc] init];
        hvc.navTitleStr = model.name;
        hvc.serviceId = serviceId;
        if ([HWUserLogin verifyIsLoginWithPresentVC:self toViewController:hvc])
        {
            [self.navigationController pushViewController:hvc animated:YES];
        }
    }
}

//周边小店类型
- (void)pushForShop:(NSString *)typeId shopName:(NSString *)shopName
{
    HWShopListViewController *shopListVC = [[HWShopListViewController alloc] init];
    shopListVC.typeId = typeId;
    shopListVC.shopName = shopName;
    [self.navigationController pushViewController:shopListVC animated:YES];
}

#pragma mark - icon 操作事件
- (CGPoint)getTargetCenter:(NSInteger)index
{
    CGFloat width = (kScreenWidth / 3.0f - 0.5f);
    CGFloat x = (index % 3 + 0.5f) * width + index % 3 * 0.5f;
    CGFloat y = CGRectGetMaxY(bannerSV.frame) + (index / 3 + 0.5f) * width + index / 3 * 0.5f;
    return CGPointMake(x, y);
}

- (void)iconLongPressBegain:(UILongPressGestureRecognizer *)press
{
    NSLog(@"iconLongPressBegain");
    
    if (_selectIndex == -1)
    {
        HWServiceIcon *icon = (HWServiceIcon *)press.view;
        _iconTouchPoint = [press locationInView:icon];
        if (_currentIcon != icon)
        {
            [_currentIcon hideDelBtnAnimation];
            _currentIcon = icon;
        }
        _selectIndex = [_iconArr indexOfObject:_currentIcon];
        
        if (_selectIndex != 0 && _selectIndex != _iconArr.count -1)
        {
            [_headerView bringSubviewToFront:_currentIcon];
            self.baseTableView.scrollEnabled = NO;
            CGFloat width = kScreenWidth / 3.0f;
            
            CGPoint begainPoint = CGPointMake(_currentIcon.center.x + (_iconTouchPoint.x - width / 2.0f), _currentIcon.center.y + (_iconTouchPoint.y - width/2.0f));
            [_currentIcon longPressBegainAction:begainPoint];
        }
        else
        {
            [Utility showToastWithMessage:@"不可移动哦" inView:self.view];
            _selectIndex = -1;
        }
    }
}

- (void)iconLongPressEnd:(UILongPressGestureRecognizer *)press
{
    NSLog(@"iconLongPressEnd");
    NSInteger targetIndex = [self getTargetIndex];
    
    if (targetIndex != -1 && targetIndex != 0 && targetIndex < _iconArr.count -1)
    {
        CGPoint endPoint = [self getTargetCenter:[self getTargetIndex]];
        [_currentIcon longPressEndAction:endPoint];
    }
    else
    {
        CGPoint endPoint = [self getTargetCenter:[_iconArr indexOfObject:_currentIcon]];
        [_currentIcon longPressEndAction:endPoint];
    }
    
    //提交更改
    if (targetIndex != _selectIndex && _selectIndex != -1)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(commitIconChange) object:nil];
        [self performSelector:@selector(commitIconChange) withObject:nil afterDelay:0.3];
    }
    
    _selectIndex = -1;
    self.baseTableView.scrollEnabled = YES;
}

- (void)IconPanChange:(UIPanGestureRecognizer *)pan
{
//    NSLog(@"拖动手势Change");
    
    CGPoint offset = [pan translationInView:self.view];
    _currentIcon.center = CGPointMake(_currentIcon.center.x+offset.x, _currentIcon.center.y+offset.y);
    [pan setTranslation:CGPointZero inView:self.view];
    
    NSInteger lastIndex = [_iconArr indexOfObject:_currentIcon];
    NSInteger targetIndex = [self getTargetIndex];
//    NSLog(@"targetIndex %ld lastIndex %ld", (long)targetIndex, (long)lastIndex);
    if (targetIndex != lastIndex && targetIndex != -1 && targetIndex != 0 && targetIndex < _iconArr.count -1)
    {
        [self reloadViewAndIconArr:lastIndex targetIndex:targetIndex];
    }
}

- (void)reloadViewAndIconArr:(NSInteger)lastIndex targetIndex:(NSInteger)targetIndex
{
    if (lastIndex < targetIndex)
    {
        NSLog(@"下移");
        for (int i = (int)lastIndex + 1; i <= targetIndex; i++)
        {
            HWServiceIcon *icon = [_iconArr pObjectAtIndex:i];
            HWServiceIcon *tmpIcon = [_iconArr pObjectAtIndex:i - 1];
            
            [UIView animateWithDuration:0.2 animations:^{
                icon.center = [self getTargetCenter:i - 1];
                
            } completion:^(BOOL finished) {
                
            }];
            
            [_iconArr replaceObjectAtIndex:i-1 withObject:icon];
            [_iconArr replaceObjectAtIndex:i withObject:tmpIcon];
            [_iconModelArr replaceObjectAtIndex:i-1 withObject:icon.model];
            [_iconModelArr replaceObjectAtIndex:i withObject:tmpIcon.model];
        }
    }
    else
    {
        NSLog(@"上移");
        for (int i = (int)lastIndex - 1; i >= targetIndex; i--)
        {
            HWServiceIcon *icon = [_iconArr pObjectAtIndex:i];
            HWServiceIcon *tmpIcon = [_iconArr pObjectAtIndex:i + 1];
            
            [UIView animateWithDuration:0.2 animations:^{
                icon.center = [self getTargetCenter:i + 1];
            } completion:^(BOOL finished) {
                
            }];
            [_iconArr replaceObjectAtIndex:i + 1 withObject:icon];
            [_iconArr replaceObjectAtIndex:i withObject:tmpIcon];
            [_iconModelArr replaceObjectAtIndex:i + 1 withObject:icon.model];
            [_iconModelArr replaceObjectAtIndex:i withObject:tmpIcon.model];
        }
    }
}

- (void)iconPanEnd:(UIPanGestureRecognizer *)pan
{
    self.baseTableView.scrollEnabled = YES;
}

- (void)iconDelBtnClick:(HWServiceIcon *)icon
{
    NSLog(@"iconDelBtnClick");
    
    NSInteger lastIndex = [_iconArr indexOfObject:icon];
    NSInteger targetIndex = _iconArr.count -1;
    
    [UIView animateWithDuration:0.3 animations:^{
        icon.alpha = 0.3;
        icon.transform = CGAffineTransformScale(icon.transform, 0.3, 0.3);
        icon.center = [self getTargetCenter:_iconArr.count - 1];
    } completion:^(BOOL finished) {
        [self reloadViewAndIconArr:lastIndex targetIndex:targetIndex];
        [_iconArr removeObject:icon];
        [_iconModelArr removeObject:icon.model];
        [icon removeFromSuperview];
        [self commitIconChange];
        _currentIcon = nil;
        _selectIndex = -1;
    }];
}

- (void)tapAction:(UITapGestureRecognizer *)tap
{
    HWServiceIcon *icon = (HWServiceIcon *)tap.view;
    if (_currentIcon.isDelBtnShow)
    {
        NSLog(@"tap hideDelBtnAnimation");
        [_currentIcon hideDelBtnAnimation];
    }
    else
    {
        [self pushVCByIconModel:icon.model];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    [_currentIcon hideDelBtnAnimation];
}

- (NSInteger)getTargetIndex
{
    int width = kScreenWidth / 3.0f;
    
    int currentx = _currentIcon.center.x;
    int currenty = _currentIcon.center.y - CGRectGetMaxY(bannerSV.frame);
    
    if (currentx < 0 || currentx > kScreenWidth || currenty < 0 || currenty > kScreenWidth)
    {
        return -1;
    }
    
    NSInteger TargetIndex = (currentx / width) + 3 * (currenty / width);
    return TargetIndex;
}


#pragma mark -
- (void)pushViewControllerByAppModel:(HWApplicationModel *)appModel
{
    NSArray *strArr = [appModel.iconUrl componentsSeparatedByString:@":"];
    
    NSString *headStr = [strArr pObjectAtIndex:0];
    if ([headStr isEqualToString:@"kaola"])
    {
        // 应用内跳转
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"wy"])
        {
            if (proItem.propertyId == nil)
            {
                [self btnPerfectClick:nil];
            }
            else
            {
                [self propertyTapGesture:nil];
            }
        }
        else if ([secStr isEqualToString:@"cut"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushCutApplication];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCutDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"coupon"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushCouponList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCouponDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
                
            }
        }
        else if ([secStr isEqualToString:@"game"])
        {
            // 游戏
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushGameList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushGameDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"shops"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                HWShopListViewController *shopListVC = [[HWShopListViewController alloc] init];
                shopListVC.shopName = @"周边小店";
                [self.navigationController pushViewController:shopListVC animated:YES];
            }
            else
            {
                NSLog(@"未知路径");
            }
        }
        else if ([secStr isEqualToString:@"salecenter"])
        {
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                [self pushSaleCenter];
            }
        }
        else
        {
            NSLog(@"未知路径");
        }
        
    }
    else
    {
        // web页面
        
        if (appModel.type.intValue == 1)
        {
            HWBrandViewController *brandVC = [[HWBrandViewController alloc] init];
            brandVC.navigationItem.titleView = [Utility navTitleView:appModel.name];
            brandVC.folderId = appModel.applicationId;
            [self.navigationController pushViewController:brandVC animated:YES];
        }
        else
        {
            HWApplicationDetailViewController *appDetailVC = [[HWApplicationDetailViewController alloc] init];
            appDetailVC.navigationItem.titleView = [Utility navTitleView:appModel.name];
            appDetailVC.appUrl = appModel.iconUrl;
            [self.navigationController pushViewController:appDetailVC animated:YES];
        }
    }
}

- (void)pushViewControllerByActivityModel:(HWActivityModel *)activityModel
{
    NSArray *strArr = [activityModel.activityURL componentsSeparatedByString:@":"];
    
    NSString *headStr = [strArr pObjectAtIndex:0];
    if ([headStr isEqualToString:@"kaola"])
    {
        // 应用内跳转
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"wy"])
        {
            if (proItem.propertyId == nil)
            {
                [self btnPerfectClick:nil];
            }
            else
            {
                [self propertyTapGesture:nil];
            }
        }
        else if ([secStr isEqualToString:@"cut"])
        {
            // 无底线
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushCutApplication];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCutDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"coupon"])
        {
            // 优惠券
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushCouponList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCouponDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                    
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"game"])
        {
            // 游戏
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushGameList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushGameDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else
        {
            NSLog(@"未知路径");
        }
        
    }
    else if ([headStr isEqualToString:@"topic"])
    {
        /*"topic:coupon:index:{话题Id}"
         "topic:coupon:detail:{主题Id}"*/
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"coupon"])
        {
            //先取id
            NSString *idStr = [strArr pObjectAtIndex:3];
            if (idStr.length > 2)
            {
                idStr = [idStr substringFromIndex:1];
                if (idStr.length > 1)
                {
                    idStr = [idStr substringToIndex:idStr.length -1];
                }
                else
                {
                    idStr = nil;
                }
            }
            else
            {
                idStr = nil;
            }
            
            if (idStr != nil)
            {
                NSString *detailIdStr = [strArr pObjectAtIndex:2];
                if ([detailIdStr isEqualToString:@"index"])
                {
                    HWChannelModel *model = [[HWChannelModel alloc] init];
                    model.channelId = idStr;
                    model.channelName = activityModel.activityName;
                    model.passVillageIdArr = nil;
                    [self pushToChannelViewController:model];
                }
                else if ([detailIdStr isEqualToString:@"detail"])
                {
                    HWDetailViewController *detailVC = [[HWDetailViewController alloc] initWithCardId:idStr];
                    detailVC.resourceType = detailResourceNeighbour;
                    detailVC.chuanChuanMenCanNotHandle = NO;
                    [self.navigationController pushViewController:detailVC animated:YES];
                }
            }
            else
            {
                NSLog(@"话题或主题id错误");
            }
        }
    }
    else
    {
        // web页面
        HWApplicationDetailViewController *appDetailVC = [[HWApplicationDetailViewController alloc] init];
        appDetailVC.navigationItem.titleView = [Utility navTitleView:activityModel.activityName];
        appDetailVC.appUrl = activityModel.activityURL;
        if (activityModel.activityURL.length == 0)
        {
            return;
        }
        else
        {
            [self.navigationController pushViewController:appDetailVC animated:YES];
        }

        
    }
}

- (void)pushToChannelViewController:(HWChannelModel *)model
{
    HWTopicListViewController *vc = [[HWTopicListViewController alloc]init];
    vc.channelModel = model;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)propertyTapGesture:(UITapGestureRecognizer *)tap
{
    
//    if (tap.numberOfTapsRequired == 1)
//    {
        [MobClick event:@"click_property_card"];
        //物业详情
        HWPropertyDetailVC *property = [[HWPropertyDetailVC alloc] init];
        property.propertyId = proItem.propertyId;
        [self.navigationController pushViewController:property animated:YES];
//    }
}

//完善物业信息
- (void)btnPerfectClick:(id)sender
{
    HWWuYeServiceVC *svc = [[HWWuYeServiceVC alloc] init];
    svc.isCompany = NO;
    [self.navigationController pushViewController:svc animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self addCallStateNotification];
    self.baseTableView.frame = CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT - 49);
    [self queryCutCount];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeCallStateNotification];
}

- (void)viewDidDisappear:(BOOL)animated
{
    
}

- (void)pushCutApplication
{
    [MobClick event:@"click_bargain"];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *agreeFlag = [userDefaults objectForKey:kAgreeProtocol];
    if (agreeFlag == nil || [agreeFlag isEqualToString:@"0"])
    {
        HWTreasureRuleViewController *treasureRuleVC = [[HWTreasureRuleViewController alloc] init];
        treasureRuleVC.isAgree = YES;
        [self.navigationController pushViewController:treasureRuleVC animated:YES];
    }
    else
    {
//        HWBargainGoodsController *barganCtrl = [[HWBargainGoodsController alloc]init];
//        [self.navigationController pushViewController:barganCtrl animated:YES];
        
//        HWTreasureViewController *treasureVC = [[HWTreasureViewController alloc] init];
//        [self.navigationController pushViewController:treasureVC animated:YES];
        HWGoodsListViewController *goods = [[HWGoodsListViewController alloc] init];
        [self.navigationController pushViewController:goods animated:YES];
    }
}

- (void)pushCutDetail:(NSString *)cutId
{
    HWTreasureViewController *treasureVC = [[HWTreasureViewController alloc] init];
    treasureVC.preProductId = cutId;
    [self.navigationController pushViewController:treasureVC animated:YES];
}

- (void)pushCouponList
{
    HWDiscountViewController *couponVC = [[HWDiscountViewController alloc] init];
    [self.navigationController pushViewController:couponVC animated:YES];
}

- (void)pushCouponDetail:(NSString *)couponId
{
    HWPriviledgeDetailVC *detailVC = [[HWPriviledgeDetailVC alloc] init];
    detailVC.priviledgeId = couponId;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)pushGameList
{
    HWGameSpreadVC *gameVC = [[HWGameSpreadVC alloc] init];
    [self.navigationController pushViewController:gameVC animated:YES];
}

- (void)pushGameDetail:(NSString *)gameId
{
    HWGameDetailViewController *gameVC = [[HWGameDetailViewController alloc] init];
    gameVC.gameId = gameId;
    [self.navigationController pushViewController:gameVC animated:YES];
}

#pragma mark - 租售中心
- (void)pushSaleCenter
{
    [Utility showMBProgress:self.view message:LOADING_TEXT];
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [manager POST:kSaleCenter parameters:param queue:nil success:^(id responese) {
//        NSLog(@"%@",responese);
        [Utility hideMBProgress:self.view];
        NSDictionary *dict = [responese dictionaryObjectForKey:@"data"];
        NSString *strToken = [dict stringObjectForKey:@"accessToken"];
        HWSaleCenterViewController *saleVC = [[HWSaleCenterViewController alloc] init];
        saleVC.strUrl = strToken;
        [self.navigationController pushViewController:saleVC animated:YES];
    } failure:^(NSString *code, NSString *error) {
        NSLog(@"%@",error);
        [Utility hideMBProgress:self.view];
        [Utility showToastWithMessage:error inView:self.view];
    }];
}

- (void)toAppIcon:(UIButton *)sender
{
    NSInteger appIndex = sender.tag - kAPPICON_TAG;
    
    HWApplicationModel *appModel = [self.appList pObjectAtIndex:appIndex];
    [self pushViewControllerByAppModel:appModel];
}

- (void)toAddShop:(id)sender
{
    [MobClick event:@"click_tianjiahaoma"];
    HWAddShopViewController *addShopVC = [[HWAddShopViewController alloc] init];
    [self.navigationController pushViewController:addShopVC animated:YES];
}

#pragma mark -
#pragma mark 数据请求

- (void)queryListData
{
    if (_isAtCompanyVillage) //请求icon数据
    {
        [self queryIconData];    //请求icon数据
        [self queryBannerData];     //请求合作物业banner
        [self getDynamicIndex];
        _isNeedRefresh = NO;
    }
    else
    {
        [self queryListDataForUnCompany];
    }
}

/**
 *	@brief	获取消息中心信息数量
 *
 *	@return	N/A
 */
-(void)getDynamicIndex

{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc]init];
    [parameters setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:kDynamicIndex parameters:parameters queue:nil success:^(id responese)
     {
         NSLog(@"首页新增信息数量%@",responese);
         NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithDictionary:[responese dictionaryObjectForKey:@"data"]];
         NSInteger countNum = 0;
         NSMutableArray *countArr = [[NSMutableArray alloc] init];
         [countArr addObject:[dict stringObjectForKey:@"atCount"]];//@我的
         [countArr addObject:[dict stringObjectForKey:@"replyCount"]];//评论
         [countArr addObject:[dict stringObjectForKey:@"praiseTopicCount"]];//赞
         [countArr addObject:[dict stringObjectForKey:@"topicCount"]];//主题
         [countArr addObject:[dict stringObjectForKey:@"wyNoticeCount"]];
         
         for (int i = 0; i < countArr.count; i++)
         {
             countNum = countNum + [[countArr pObjectAtIndex:i] integerValue];
         }
         
         if (countNum > 0)
         {
             self.isShowMessageCenterRedDot = YES;
         }
         else
         {
             self.isShowMessageCenterRedDot = NO;
         }
         
         AppDelegate *delegate = (AppDelegate *)SHARED_APP_DELEGATE;
         [delegate.tabBarVC showServiceMessageCenterRedDot];
         
     } failure:^(NSString *code, NSString *error)
     {
         
     }];
}

- (void)queryListDataForUnCompany
{
    HWUserLogin *user = [HWUserLogin currentUserLogin];
    HWHTTPRequestOperationManager *manage = [HWHTTPRequestOperationManager manager];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setPObject:user.villageId forKey:@"villageId"];
    [dict setPObject:user.key forKey:@"key"];
    [dict setPObject:[NSString stringWithFormat:@"%d",kPageCount] forKey:@"size"];
    [dict setPObject:[NSString stringWithFormat:@"%d",_currentPage] forKey:@"page"];
    
    [manage POST:kServiceHome160 parameters:dict queue:nil success:^(id responseObject)
     {
         NSLog(@"responseObject = %@",responseObject);
         [Utility hideMBProgress:self.view];
         NSDictionary *dict = [responseObject dictionaryObjectForKey:@"data"];
         HWServiceItemClass *item = [[HWServiceItemClass alloc] initWithDictionary:[dict dictionaryObjectForKey:@"serviceGatherIndexVO"]];
         
         if (_currentPage == 0)
         {
             [arrShop removeAllObjects];
             proItem = item.propertyDic;
             
             if (![proItem.propertyId isEqualToString:@""] && proItem.propertyId != nil)
             {
                 [HWUserLogin currentUserLogin].tenementId = proItem.propertyId;
                 [HWCoreDataManager saveUserInfo];
             }
             
             arrShop = [NSMutableArray arrayWithArray:item.shopArray];
             
             if (arrShop.count != 0 )
             {
                 [self hideNewEmpty];
             }
             
             [HWCoreDataManager clearShopList];
             [HWCoreDataManager saveShopList:arrShop];
             
             if ([proItem.propertyId isEqualToString:@""] && proItem.propertyId == nil && arrShop.count == 0)
             {
                 [self showNewEmpty:@"点击重新加载"];
             }
             else
             {
                 [self hideNewEmpty];
             }
             
             if (proItem.propertyId == nil)
             {
                 
                 NSLog(@"不存在物业信息");
                 
             }
             [HWCoreDataManager clearPropertyList];
             [HWCoreDataManager savePropertyList:proItem];
         }
         else
         {
             //            proItem = item.propertyDic;
             
             [arrShop addObjectsFromArray:item.shopArray];
         }
         
         
         //        if (item.shopArray.count < kPageCount)
         //        {
         //            isLastPage = YES;
         //        }
         //        else
         //        {
         //            isLastPage = NO;
         //        }
         isLastPage = YES;
         //head    物业
         
         NSArray *respList = [dict arrayObjectForKey:@"applicationShowDtoList"];
         
         NSMutableArray *resultList = [NSMutableArray array];
         for (int i = 0; i < respList.count; i++)
         {
             NSDictionary *info = [respList objectAtIndex:i];
             [resultList addObject:[[HWApplicationModel alloc] initWithApplicationInfo:info]];
         }
         
         NSArray *tmpArray = [resultList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
             
             HWApplicationModel *app1 = (HWApplicationModel *)obj1;
             HWApplicationModel *app2 = (HWApplicationModel *)obj2;
             
             if (app1.appOrFolderIndex.intValue > app2.appOrFolderIndex.intValue)
             {
                 return NSOrderedDescending;
             }
             else if (app1.appOrFolderIndex.intValue < app2.appOrFolderIndex.intValue)
             {
                 return NSOrderedAscending;
             }
             return NSOrderedSame;
             
         }];
         
         self.appList = [NSMutableArray arrayWithArray:tmpArray];
         
         [HWCoreDataManager removeAllApplicationListItem];
         [HWCoreDataManager addApplicationListItem:self.appList];
         
         //  activity List
         
         NSArray *activityResultList = [dict arrayObjectForKey:@"activityList"];
         NSMutableArray *tmppArr = [NSMutableArray array];
         for (int i = 0; i < activityResultList.count; i++)
         {
             NSDictionary *info = [activityResultList objectAtIndex:i];
             [tmppArr addObject:[[HWActivityModel alloc] initWithAcitivity:info]];
         }
         
         self.activityList = [NSMutableArray arrayWithArray:tmppArr];
         [HWCoreDataManager removeAllActivityListItem];
         [HWCoreDataManager addActivityListItem:tmppArr];
         
         if (self.activityList.count == 0 || arrShop.count == 0 || self.appList.count == 0)
         {
             [_headerView removeFromSuperview];
             _headerView = nil;  //重新布局
         }
         
         [self initialHeaderView];
         
         [self.baseTableView reloadData];
         [self doneLoadingTableViewData];
         
         [self queryCutCount];
         [self queryCutCountDown];
     } failure:^(NSString *code, NSString *error) {
         
         NSLog(@"error = %@",error);
         [Utility hideMBProgress:self.view];
         
         [self doneLoadingTableViewData];
     }];
}

- (void)queryBannerData
{
    /*hw-sq-app-web/serviceGather/queryBanner.do
     * @param appVersion 版本号 1.6.0
     * @param key
     * @param publishModule 0 微商店，1福利社，2邻里圈，3合作物业首页*/
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:@"1.7.0" forKey:@"appVersion"];
    [param setPObject:@"3" forKey:@"publishModule"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KServiceBannerForCompanyWY parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"responese ========================= %@",responese);
         NSArray *arr = [[responese dictionaryObjectForKey:@"data"] arrayObjectForKey:@"content"];
         
         NSMutableArray *tmpArr = [NSMutableArray array];
         for (int i = 0; i < arr.count; i++)
         {
             NSDictionary *info = [arr pObjectAtIndex:i];
             [tmpArr addObject:[[HWActivityModel alloc] initWithAcitivity:info]];
         }
         
         self.activityList = [NSMutableArray arrayWithArray:tmpArr];
         
         if (_isQueryFinish == YES)
         {
             [self initialHeaderView];
         }
         else
         {
             _isQueryFinish = YES;
         }
         
         [HWCoreDataManager removeAllBannerModelCompany];
         [HWCoreDataManager saveServiceBannerForCompanyWuYeModelArr:self.activityList];
         
         [self doneLoadingTableViewData];
     } failure:^(NSString *code, NSString *error) {
         _isQueryFinish = NO;
         [self doneLoadingTableViewData];
         [Utility showToastWithMessage:error inView:self.view];
     }];
}

- (void)initBannerForCompanyWY
{
    CGFloat height = 0;
    if (self.activityList.count != 0)
    {
        height = 135 * kScreenRate;
    }
    
    _bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_headerView.frame), height)];
    [_headerView addSubview:_bannerView];
    
    bannerSV = [[UIScrollView alloc] initWithFrame:_bannerView.bounds];
    bannerSV.scrollEnabled = NO;
    [_bannerView addSubview:bannerSV];
    
    if (self.activityList.count != 0)
    {
        //轮播banner
        DCycleBanner *banner = [DCycleBanner cycleBannerWithFrame:CGRectMake(0, 0, kScreenWidth, 135 * kScreenRate) bannerImgCount:self.activityList.count];
        [banner setImageViewAtIndex:^(UIImageView *bannerImageView, NSUInteger indexAtBanner) {
            HWActivityModel *model = [self.activityList pObjectAtIndex:indexAtBanner];
            bannerImageView.backgroundColor = IMAGE_DEFAULT_COLOR;
            __weak UIImageView *weakImgV = bannerImageView;
            [bannerImageView setImageWithURL:[NSURL URLWithString:[Utility imageDownloadWithUrl:model.activityPictureURL]] placeholderImage:[UIImage imageNamed:IMAGE_PLACE] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (error == nil)
                {
                    weakImgV.image = image;
                }
                else
                {
                    weakImgV.image = [UIImage imageNamed:IMAGE_BREAK_CUBE];
                }
            }];
        }];
        [banner setImageTapAction:^(NSUInteger indexAtBanner) {
            HWActivityModel *model = [self.activityList objectAtIndex:indexAtBanner];
            [self pushViewControllerForCompanyWYByActivityModel:model];
            [self bannerClickStatisticalAtIndex:indexAtBanner];
        }];
        [banner setTimerFire:YES];
        [bannerSV addSubview:banner];
    }
}

//banner点击统计
- (void)bannerClickStatisticalAtIndex:(NSUInteger)index
{
    HWActivityModel *bannerModel = [self.activityList pObjectAtIndex:index];
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
    [param setPObject:bannerModel.activityId forKey:@"activityId"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KBannerClickStatistical parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"banner统计 responese ========================= %@",responese);
         
     } failure:^(NSString *code, NSString *error) {
         NSLog(@"banner统计错误 %@", error);
     }];
}

- (void)queryCutCount
{
    HWUserLogin *user = [HWUserLogin currentUserLogin];
    HWHTTPRequestOperationManager *manage = [HWHTTPRequestOperationManager cutManager];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setPObject:user.key forKey:@"key"];
    
    [manage POST:kCutCount parameters:dict queue:nil success:^(id responese) {
        
        NSLog(@"%@", responese);
        _cutCount = [[responese dictionaryObjectForKey:@"data"] stringObjectForKey:@"count"];
        
        [self initialCutCountView];
        [self queryCutCountDown];
    } failure:^(NSString *code, NSString *error) {
        
        NSLog(@"%@", error);
    }];
}

- (void)queryCutCountDown
{
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setPObject:@"1" forKey:@"source"];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager cutManager];
    [manager POST:kHomeCutDJS parameters:param queue:nil success:^(id responese) {
        NSLog(@"data = %@",[responese stringObjectForKey:@"data"]);
        
        _theTime = 0;
        [_theTimer invalidate];
        _theTimer = nil;
        _theCutTime = [responese stringObjectForKey:@"data"];
        long num = (long)[_theCutTime longLongValue] / 1000;
        if (num == 0)
        {
            [countDownLab setStr:@"00" second:@"00" third:@"00"];
        }
        else
        {
            [self startCutCountDown];
            _theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startCutCountDown) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:_theTimer forMode:NSRunLoopCommonModes];
        }
        
    } failure:^(NSString *code, NSString *error) {
        
    }];
}

- (void)startCutCountDown
{
    _theTime ++;
    long num = (long)[_theCutTime longLongValue] / 1000;
    num -= _theTime;
    if (num <= 0)
    {
        [_theTimer invalidate];
        _theTimer = nil;
        [countDownLab setStr:@"00" second:@"00" third:@"00"];
        [self queryCutCountDown];
    }
    else
    {
        [countDownLab setStr:[NSString stringWithFormat:@"%.2ld",num / 3600] second:[NSString stringWithFormat:@"%.2ld",(num % 3600) / 60] third:[NSString stringWithFormat:@"%.2ld",num % 60]];
    }
}

- (void)pushViewControllerForCompanyWYByActivityModel:(HWActivityModel *)activityModel
{
    NSArray *strArr = [activityModel.activityURL componentsSeparatedByString:@":"];
    
    NSString *headStr = [strArr pObjectAtIndex:0];
    if ([headStr isEqualToString:@"kaola"])
    {
        // 应用内跳转
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"wy"])
        {
            HWWuYeServiceVC *svc = [[HWWuYeServiceVC alloc] init];
            svc.isCompany = YES;
            svc.homePageIconArr = _iconModelArr;
            [self.navigationController pushViewController:svc animated:YES];
        }
        else if ([secStr isEqualToString:@"cut"])
        {
            // 无底线
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushCutApplication];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCutDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"coupon"])
        {
            // 优惠券
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushCouponList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushCouponDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                    
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else if ([secStr isEqualToString:@"game"])
        {
            // 游戏
            NSString *thirdStr = [strArr pObjectAtIndex:2];
            if ([thirdStr isEqualToString:@"index"])
            {
                // 列表
                [self pushGameList];
            }
            else if ([thirdStr isEqualToString:@"detail"])
            {
                // 详情
                NSString *detailIdStr = [strArr pObjectAtIndex:3];
                if ([detailIdStr hasPrefix:@"{"] && [detailIdStr hasSuffix:@"}"])
                {
                    if (detailIdStr.length < 3)
                    {
                        NSLog(@"id 不能为空");
                    }
                    else
                    {
                        [self pushGameDetail:[detailIdStr substringWithRange:NSMakeRange(1, detailIdStr.length - 2)]];
                    }
                }
                else
                {
                    NSLog(@"应用路径错误");
                }
            }
        }
        else
        {
            NSLog(@"未知路径");
        }
        
    }
    else if ([headStr isEqualToString:@"topic"])
    {
        /*"topic:coupon:index:{话题Id}"
         "topic:coupon:detail:{主题Id}"*/
        NSString *secStr = [strArr pObjectAtIndex:1];
        if ([secStr isEqualToString:@"coupon"])
        {
            //先取id
            NSString *idStr = [strArr pObjectAtIndex:3];
            if (idStr.length > 2)
            {
                idStr = [idStr substringFromIndex:1];
                if (idStr.length > 1)
                {
                    idStr = [idStr substringToIndex:idStr.length -1];
                }
                else
                {
                    idStr = nil;
                }
            }
            else
            {
                idStr = nil;
            }
            
            if (idStr != nil)
            {
                NSString *detailIdStr = [strArr pObjectAtIndex:2];
                if ([detailIdStr isEqualToString:@"index"])
                {
                    HWChannelModel *model = [[HWChannelModel alloc] init];
                    model.channelId = idStr;
                    model.channelName = activityModel.activityName;
                    model.passVillageIdArr = nil;
                    [self pushToChannelViewController:model];
                }
                else if ([detailIdStr isEqualToString:@"detail"])
                {
                    HWDetailViewController *detailVC = [[HWDetailViewController alloc] initWithCardId:idStr];
                    detailVC.resourceType = detailResourceNeighbour;
                    detailVC.chuanChuanMenCanNotHandle = NO;
                    [self.navigationController pushViewController:detailVC animated:YES];
                }
            }
            else
            {
                NSLog(@"话题或主题id错误");
            }
        }
    }
    else
    {
        // web页面
        HWApplicationDetailViewController *appDetailVC = [[HWApplicationDetailViewController alloc] init];
        appDetailVC.navigationItem.titleView = [Utility navTitleView:activityModel.activityName];
        appDetailVC.appUrl = activityModel.activityURL;
        if (activityModel.activityURL.length == 0)
        {
            return;
        }
        else
        {
            [self.navigationController pushViewController:appDetailVC animated:YES];
        }
    }
}


#pragma mark -
#pragma mark scrollview delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    [super scrollViewDidEndDecelerating:scrollView];
    
    if (scrollView == bannerSV)
    {
        bannerPageCtrl.currentPage = bannerSV.contentOffset.x / bannerSV.frame.size.width;
    }
}

#pragma mark -
#pragma mark tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
//    return [arrShop count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HWServeTableViewCell *cell = (HWServeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        cell = [[HWServeTableViewCell alloc] init];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.delegate = self;
    cell.tag = indexPath.row;
    [cell setCellDataWithShopItem:[arrShop objectAtIndex:indexPath.row]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"置顶";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (indexPath.row != 0)
//    {
        return UITableViewCellEditingStyleDelete;
//    }
//    else
//        return UITableViewCellEditingStyleNone;
//    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


//置顶事件
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [MobClick event:@"click_giveup_follow"];
    NSInteger row = indexPath.row;
    HWShopItemClass *shop = arrShop[row];
    NSString *strShopId = shop.shopId;
    HWUserLogin *user = [HWUserLogin currentUserLogin];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setPObject:strShopId forKey:@"shopId"];
    [dict setPObject:user.key forKey:@"key"];
    [dict setPObject:@"1" forKey:@"type"];
    
    HWHTTPRequestOperationManager *manage = [HWHTTPRequestOperationManager manager];
    [manage POST:kShopSort parameters:dict queue:nil success:^(id responseObject) {
        NSDictionary *dic = (NSDictionary *)responseObject;
        NSString *strStatus = [dic stringObjectForKey:@"status"];
        if ([strStatus isEqualToString:@"1"])
        {
//            _currentPage = 0;
            HWServeTableViewCell *cell = (HWServeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            UIImage *imgCell = [self imageWithView:cell];
            UIImageView *imgView = [[UIImageView alloc] init];
            imgView.image = imgCell;
            imgView.frame = CGRectMake(0, cell.frame.origin.y, cell.bounds.size.width, cell.bounds.size.height);
            [self.view addSubview:imgView];
            
            
//            [arrShop removeObjectAtIndex:row];
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            [arrShop replaceObjectAtIndex:indexPath.row withObject:@""];
            
            [tableView reloadData];
////            cell.editingStyle = UITableViewCellEditingStyleNone;
//            [UIView animateWithDuration:.6f animations:^{
//                [cell loadingAnimate];
//            } completion:^(BOOL finished) {
//                
//            }];
            

            
            for (int i = 0; i < indexPath.row; i ++)
            {
                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                HWServeTableViewCell *moveCell = (HWServeTableViewCell *)[tableView cellForRowAtIndexPath:path];
                [moveCell moveDownAnimate];
            }
            
            
//            [tableView setContentOffset:CGPointMake(0, 0) animated:YES];
            
//            [UIView animateWithDuration:.6f animations:^{
//                CGPoint p = [self.view convertPoint:CGPointMake(0, CGRectGetMaxY(self.baseTableView.tableHeaderView.frame)) fromView:baseTableView];
//                imgView.frame = CGRectMake(0, p.y, cell.bounds.size.width, cell.bounds.size.height);
//            } completion:^(BOOL finished) {
//                [imgView removeFromSuperview];
                [arrShop removeObjectAtIndex:row];
                [arrShop insertObject:shop atIndex:0];
                [self.baseTableView reloadData];
//            }];
        }
    } failure:^(NSString *code, NSString *error) {
        [Utility showToastWithMessage:error inView:self.view];
    }];
}

//获取快照
- (UIImage *)imageWithView:(UIView *)selectView
{
    UIGraphicsBeginImageContextWithOptions(selectView.bounds.size, selectView.opaque, 0.0);
    [selectView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark -
#pragma mark HWServerCellDelegate

- (void)addCallStateNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dialingNotify:) name:HWCallDetectCenterStateDialingNotification object:nil];
}

- (void)removeCallStateNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HWCallDetectCenterStateDialingNotification object:nil];
}

//index 表格的行
- (void)callPhone:(int)index
{
    [MobClick event:@"click_call_commerce"];
    strCallType = @"0";
    HWShopItemClass *shopItem = [arrShop objectAtIndex:index];
    
    // *** 拨打电话
    if (callWebview == nil)
    {
        callWebview = [[UIWebView alloc] init];
        [self.view addSubview:callWebview];
    }
    //先手机后座机
    NSString *strPhone = @"";
    if (shopItem.mobileNumber.length > 0)
    {
        BOOL isPhone = [Utility validateMobile:shopItem.mobileNumber];
        if (isPhone)
        {
            strPhone = shopItem.mobileNumber;
        }
    }
    else if (shopItem.phoneNumber.length > 0)
    {
//        BOOL isPhone = [Utility validatePhoneTel:shopItem.phoneNumber];
//        if (isPhone)
//        {
            strPhone = shopItem.phoneNumber;
//        }
    }
    
    
    if (strPhone.length <= 0)
    {
        [Utility showToastWithMessage:@"这个商店还没有电话哦~" inView:self.view];
        return;
    }
    
    
    //这里赋全局
    strShopPhone = strPhone;
    
    NSURL *telURL =[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",strPhone]];//@"tel:10086"];
    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
    
    callItem = shopItem;
    
}

//物业电话
- (void)btnCallClick:(id)sender
{
    [MobClick event:@"click_call_property"];
    
    strCallType = @"1";
    
    // *** 拨打电话
    if (callWebview == nil)
    {
        callWebview = [[UIWebView alloc] init];
        [self.view addSubview:callWebview];
    }
    //phoneNumber = "1111111,18717969652";
    NSString *strPhone = proItem.phoneNumber;
    if (strPhone.length <= 0)
    {
        [Utility showToastWithMessage:@"这个物业还没有电话哦~" inView:self.view];
        return;
    }
    //这里赋全值
    strPropertyPhone = strPhone;
    
    NSURL *telURL =[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",strPhone]];
    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
    
//    proItem = propertyItem;
}


#pragma mark -
#pragma mark HWCallDetectCenter Notification

- (void)dialingNotify:(NSNotification *)notification
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"1" forKey:kHaveDialing];
    
    // *** 发送接口
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    if ([strCallType isEqualToString:@"0"])
    {
        [param setPObject:strShopPhone forKey:@"phoneCalled"];
        [param setPObject:callItem.shopId forKey:@"toId"];
    }
    else
    {
        [param setPObject:proItem.propertyId forKey:@"toId"];
        [param setPObject:strPropertyPhone forKey:@"phoneCalled"];
    }
    
    [param setPObject:strCallType forKey:@"type"];         //0:拨打给店铺,1是拨打给物业
    [param setPObject:[HWUserLogin currentUserLogin].residendId forKey:@"residentId"];
    
    HWHTTPRequestOperationManager *manage = [HWHTTPRequestOperationManager manager];
    [manage POST:kMakeTelContent parameters:param queue:nil success:^(id responseObject) {
        
        NSLog(@"%@", responseObject);
//        [Utility showToastWithMessage:@"cheng gong" inView:self.view];
        
    } failure:^(NSString *code, NSString *error) {
        NSLog(@"%@", error);
//        [Utility showToastWithMessage:@"shi bai" inView:self.view];
    }];
    
    _phoneNum = @"";
}


//表格的行

- (void)selectCell:(int)index
{
//    MyTestViewController *test = [[MyTestViewController alloc] init];
//    [self.navigationController pushViewController:test animated:YES];
    
    
    
    [MobClick event:@"click_keep_follow"];
    HWShopItemClass *shopItem = (HWShopItemClass *)[arrShop objectAtIndex:index];
    //商户
    HWShopsDetailVC *shops = [[HWShopsDetailVC alloc] init];
    shops.shopId = shopItem.shopId;
    [self.navigationController pushViewController:shops animated:YES];

}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RELOAD_APP_DATA object:nil];
}


@end
