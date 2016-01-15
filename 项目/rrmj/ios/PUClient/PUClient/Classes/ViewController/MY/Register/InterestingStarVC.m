//
//  InterestingStarVC.m
//  PUClient
//
//  Created by RRLhy on 15/7/20.
//  Copyright (c) 2015年 RRLhy. All rights reserved.
//

#import "InterestingStarVC.h"
#import "StarItem.h"
#import "MyPageVC.h"
#import "HotStarApi.h"
#import "AddHotStarApi.h"

@interface InterestingStarVC ()
//@property (weak, nonatomic) IBOutlet UIButton *skipBtn;

@property(nonatomic,retain)UIScrollView * mainScrollView;

@property (nonatomic,retain)NSMutableArray * sourceArray;

@property (nonatomic,retain)NSMutableArray * starArray;

@property (nonatomic,copy)NSString * starString;

@end

@implementation InterestingStarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = @"你的兴趣";
    self.rightBtn.hidden = NO;
    [self.rightBtn setTitle:@"跳  过" forState:UIControlStateNormal];
    
    UILabel * introlLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 22, App_Frame_Width, 20)];
    introlLab.text = @"关注我喜爱的明星";
    introlLab.textAlignment = NSTextAlignmentCenter;
    introlLab.font = SYSTEMFONT(14);
    introlLab.textColor = GRAYCOLOR;
    [self.mainScrollView addSubview:introlLab];

    self.starArray = [[NSMutableArray alloc]init];
    
    HotStarApi * api = [[HotStarApi alloc]initWithUserToken:[UserInfoConfig sharedUserInfoConfig].userInfo.token SeriesIdArr:self.seriersIdString];
    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        [IanAlert hideLoading];
        NSDictionary * dic = request.responseJSONObject;
        NSLog(@"热门明星列表%@",dic);
        if (dic) {
            JsonModel * json = [JsonModel objectWithKeyValues:dic];
            
            if (json.code == SUCCESSCODE) {
                [IanAlert hideLoading];
                self.sourceArray = json.data[@"groups"];
                [self configureStarItem];
                
            }else{
                
                [IanAlert alertError:json.msg length:1];
            }
        }else{
            [IanAlert alertError:ERRORMSG1 length:1];
        }
        
    } failure:^(YTKBaseRequest *request) {
        
        [IanAlert alertError:ERRORMSG2 length:1];
        
    }];
}

- (UIScrollView*)mainScrollView
{
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 64, App_Frame_Width, App_Frame_Height - kTopBarHeight-kStatusBarHeight)];
        [self.view addSubview:_mainScrollView];
    }
    return _mainScrollView;
}

- (void)rightBtnClick {
    
    _starString = @"";
    
    if (self.starArray.count > 0) {
        for (int i = 0; i< self.starArray.count; i++) {
            id obj = [self.starArray objectAtIndex:i];
            if (i == 0) {
                _starString = [obj copy];
            }else
            {
                _starString = [[NSString stringWithFormat:@"%@,%@",_starString,obj] copy];
            }
        }
        
        [IanAlert showloading];
        AddHotStarApi * api = [[AddHotStarApi alloc]initWithUserToken:[UserInfoConfig sharedUserInfoConfig].userInfo.token groupIdStr:_starString];
        [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
            NSDictionary * dic = request.responseJSONObject;
            if (dic) {
                JsonModel * json = [JsonModel objectWithKeyValues:dic];

                if (json.code == SUCCESSCODE) {
                    
                    [IanAlert alertSuccess:@"马上进入" length:1];
                    [self performSelector:@selector(popRootViewController) withObject:nil afterDelay:1];
                    
                }else{
                    
                    [IanAlert alertError:json.msg length:1];
                }
            }else{
                [IanAlert alertError:ERRORMSG1 length:1];
            }
            
        } failure:^(YTKBaseRequest *request) {
            
        }];
        
    }else{
        
         [self popRootViewController];
    }
}

- (void)configureStarItem
{
    float spaceH = 20;
    float spaceV = 10;
    float w = (App_Frame_Width - 4*spaceH)/3;
    float h = w + 17 + 12*2;
   
    for (int i = 0; i < self.sourceArray.count; i++) {
        int m = i%3;//行
        int n = i/3;//列
        
        StarItem * itemView = [[StarItem alloc]initWithFrame:CGRectMake((w + spaceH)* m + spaceH, 60 + (h + spaceV) * n , w, h)];
        HotStarModel * star = [HotStarModel objectWithKeyValues:self.sourceArray[i]];
        itemView.star = star;
        itemView.selectBlok = ^(NSInteger index,BOOL isSelected){
            
            if (isSelected) {
                [self.starArray addObject:@(index)];
            }else{
                [self.starArray removeObject:@(index)];
            }
            if (self.starArray.count > 0) {
                
                [self.rightBtn setTitle:@"完成" forState:UIControlStateNormal];
                
            }else{
                [self.rightBtn setTitle:@"跳过" forState:UIControlStateNormal];
            }
            
        };
        [_mainScrollView addSubview:itemView];
    }
    
    _mainScrollView.contentSize = CGSizeMake(App_Frame_Width, 5*(h + spaceV) + 60);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
