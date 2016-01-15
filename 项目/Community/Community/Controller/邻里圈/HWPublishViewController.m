//
//  HWPublishViewController.m
//  Community
//
//  Created by zhangxun on 14-9-8.
//  Copyright (c) 2014年 caijingpeng. All rights reserved.
//
//  功能描述：发布页面
//
//  修改记录：
//      姓名         日期               修改内容
//     蔡景鹏     2015-01-15           布局修改 添加只发布语音功能 , 添加话题功能，删除匿名功能
//     蔡景鹏     2015-01-16           添加相册管理类 将读取相册功能封装 HWAlbumManager
//

#import "HWPublishViewController.h"
#import "HWInputBackView.h"
#import "GKCameraManager.h"
#import "AppDelegate.h"
#import "HWAlbumManager.h"

#define UP_SCROLLVIEW_TAG               1001
#define DOWN_SCROLLVIEW_TAG             1002
#define TEXTBACK_SCROLLERVIEW_TAG       1003
#define ANONYMOUS_TAG                   1004
#define AGAINRECORD_TAG                 1005
#define BACKALERT_TAG                   1006

#define SEPERATE_ORIGIN_Y               (CONTENT_HEIGHT / 2.0f - 2.5f)
#define INPUT_PLACEHOLDER               @"对您的邻居说点什么？"

@interface HWPublishViewController ()<UIAlertViewDelegate>
{
    UIView *_textMaskView;
    UIView *_keyboardToolView;
    UITextView *_inputTV;
    UIView *_textBackView;
    UIButton *_audioBtn;
    UILabel *_audioLab;
    UIImageView *_upScrollArrow;
    UIImageView *_downScrollArrow;
    UIScrollView *_upScrollView;
    UIScrollView *_downScrollView;
    UIView *_audioView;
    BOOL _audioViewScrollEnable;
    CGPoint _originPos;
    UIImageView *_photoImgV;
    UIView *_emptyView;         //输入为空时显示
    HWInputBackView *_seperateView;
    
    ALAssetsLibrary *_assetLibrary;
    ALAssetsFilter *_assetsFilter;
    UITableView *_albumGridTV;
    
    GKCameraManager *camManager;
    UIView *camPreview;
    UIButton *_changePicBoardBtn;
    
    BOOL _anonymous;    // 是否匿名
    HWRecorderView *_recorderV;
    UILabel *_timeLabel;
    UIButton *_againRecBtn;
    NSData *_audioData;
    int _audioDuration;
    UIButton *_closeBtn;
    NSString *_inputStr;
    UIView *gView;
    
    UIButton *_keyboardAddChannelBtn;
    UIButton *_audioAddChannelBtn;
//    HWAlbumManager *_albumManager;
}

@property (nonatomic, strong) HWAlbumManager *albumManager;

@end

@implementation HWPublishViewController
@synthesize groups;
@synthesize callId;
@synthesize callNumber;
@synthesize callSuccess;
@synthesize callTime;
@synthesize callType;
@synthesize tolerantString;
@synthesize curChannelModel;
@synthesize isOnlyAudio;
@synthesize albumManager = _albumManager;
@synthesize isWriteAndPic;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.isNeedAudio = YES;
        self.isWriteAndPic = NO;
        self.publishRoute = NeighbourRoute;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.publishRoute != PropertyRoute)
    {
        self.navigationItem.titleView = [Utility navTitleView:@"发布见闻"];
    }
    else
    {
        self.navigationItem.titleView = [Utility navTitleView:@"建议留言"];
    }
    
    self.navigationItem.leftBarButtonItem = [Utility navLeftBackBtn:self action:@selector(backMethod)];
    
    
    self.navigationItem.rightBarButtonItem = [Utility navButton:self title:@"发布" action:@selector(toPublish:)];
    
    self.publishMode = textMode;
    
//    [self initialTextView];
    [self initialTextMaskView];
    
    _audioViewScrollEnable = YES;
    _originPos = _audioView.frame.origin;
    
    self.assets = [NSMutableArray array];
    self.groups = [NSMutableArray array];
    
    _anonymous = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (self.publishRoute == NeighbourRoute)
    {
        // 发布草稿
        if ([userDefaults objectForKey:@"draft"] && ![[userDefaults objectForKey:@"draft"] isEqualToString:@""])
        {
            _inputTV.text = [userDefaults objectForKey:@"draft"];
        }
    }
    
    if (!self.isNeedAudio)
    {
//        [self toWrite:nil];
        [self toWriteNoAnimate];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.albumManager = [[HWAlbumManager alloc] init];
    self.assets = _albumManager.assets;
    
    /*
    if (self.publishRoute == NeighbourRoute && self.tolerantString.length == 0)
    {
        if (![userDefaults objectForKey:@"firstLaunch_publish"])
        {
            [userDefaults setObject:@"1" forKey:@"firstLaunch_publish"];
            [self initialGuideView];
        }
    }
     */
    
    if (self.isOnlyAudio)
    {
        _audioAddChannelBtn.hidden = YES;
        [self showRecorder];
        _downScrollView.scrollEnabled = NO;
    }
    
    if (self.publishRoute == NeighbourRoute)
    {
        _keyboardAddChannelBtn.hidden = NO;
        _audioAddChannelBtn.hidden = NO;
    }
    else
    {
        _keyboardAddChannelBtn.hidden = YES;
        _audioAddChannelBtn.hidden = YES;
    }
}

#pragma mark -
#pragma mark InitialView Method

- (void)initialGuideView
{
    gView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    gView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    AppDelegate *appDel = SHARED_APP_DELEGATE;
    [appDel.window addSubview:gView];
    
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 172, 132)];
    imgV.image = [UIImage imageNamed:@"firstLaunch_publish"];
    imgV.center = CGPointMake(kScreenWidth - 90, [UIScreen mainScreen].bounds.size.height * 0.65f);
    imgV.userInteractionEnabled = YES;
    [gView addSubview:imgV];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeGuideView:)];
    [gView addGestureRecognizer:tap];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeGuideView:)];
    [imgV addGestureRecognizer:tap1];
    
}

- (void)initialTextMaskView
{
    float height = CONTENT_HEIGHT / 2.0f - 5.0f;
    
    _textMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT * 2.0f)];
    _textMaskView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_textMaskView];
    
    _upScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT)];
    _upScrollView.delegate = self;
    _upScrollView.tag = UP_SCROLLVIEW_TAG;
    _upScrollView.backgroundColor = [UIColor whiteColor];
    _upScrollView.contentSize = CGSizeMake(_upScrollView.frame.size.width, _upScrollView.frame.size.height + 1) ;
    _upScrollView.scrollsToTop = NO;
    [_textMaskView addSubview:_upScrollView];
    
    _downScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CONTENT_HEIGHT, kScreenWidth, CONTENT_HEIGHT)];
    _downScrollView.delegate = self;
    _downScrollView.tag = DOWN_SCROLLVIEW_TAG;
    _downScrollView.backgroundColor = [UIColor whiteColor];
    _downScrollView.contentSize = CGSizeMake(_downScrollView.frame.size.width, _downScrollView.frame.size.height + 1) ;
    _downScrollView.scrollsToTop = NO;
    [_textMaskView addSubview:_downScrollView];
    
//    _seperateView = [[HWInputBackView alloc] initWithFrame:CGRectMake(0, SEPERATE_ORIGIN_Y, kScreenWidth, 5.0f)];
//    _seperateView.backgroundColor = UIColorFromRGB(0xdddddd);
//    [_upScrollView addSubview:_seperateView];
    
    _emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_upScrollView.frame), SEPERATE_ORIGIN_Y)];
    _emptyView.backgroundColor = [UIColor clearColor];
    [_upScrollView addSubview:_emptyView];
    
    UIButton *writeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    writeBtn.frame = CGRectMake(0, 0, 130, 130);
    writeBtn.backgroundColor = [UIColor clearColor];
    [writeBtn setImage:[UIImage imageNamed:@"write"] forState:UIControlStateNormal];
    writeBtn.center = CGPointMake(CGRectGetWidth(_textMaskView.frame) / 2.0f, height / 2.0f - 20 );
    [writeBtn addTarget:self action:@selector(toWrite:) forControlEvents:UIControlEventTouchUpInside];
    [_emptyView addSubview:writeBtn];
    
    UITapGestureRecognizer *tapEmptyView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toWrite:)];
    [_emptyView addGestureRecognizer:tapEmptyView];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
    label.center = CGPointMake(CGRectGetWidth(_textMaskView.frame) / 2.0f, height / 2.0f + 55);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = THEME_COLOR_SMOKE;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:FONTNAME size:THEME_FONT_BIG];
    label.text = @"图文";
    [_emptyView addSubview:label];
    
    _audioView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 165, 180)];
    _audioView.center = CGPointMake(CGRectGetWidth(_textMaskView.frame) / 2.0f, height + height / 3.0f);
    _audioView.backgroundColor = [UIColor clearColor];
    [_textMaskView addSubview:_audioView];
    
//    _recorderV = [[HWRecorderView alloc] initWithFrame:CGRectMake(0, 0, 165, 165)];
//    _recorderV.backgroundColor = [UIColor clearColor];
//    _recorderV.delegate = self;
//    [_audioView addSubview:_recorderV];
    
    _audioLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 165, 30)];
    _audioLab.center = CGPointMake(CGRectGetWidth(_audioView.frame) / 2.0f, 150.0f);
    _audioLab.backgroundColor = [UIColor clearColor];
    _audioLab.textColor = THEME_COLOR_SMOKE;
    _audioLab.textAlignment = NSTextAlignmentCenter;
    _audioLab.font = [UIFont fontWithName:FONTNAME size:THEME_FONT_BIG];
    _audioLab.text = @"语音";
    [_audioView addSubview:_audioLab];
    
    _againRecBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _againRecBtn.frame = CGRectMake(CGRectGetWidth(_audioView.frame) - 40, CGRectGetHeight(_audioView.frame) - 40, 40, 40);
    _againRecBtn.alpha = 0.0f;
    _againRecBtn.layer.cornerRadius = 20.0f;
    _againRecBtn.layer.masksToBounds = YES;
    [_againRecBtn setBackgroundImage:[Utility imageWithColor:UIColorFromRGB(0xbdbdbd) andSize:CGSizeMake(40, 40)] forState:UIControlStateNormal];
    [_againRecBtn setTitle:@"重录" forState:UIControlStateNormal];
    [_againRecBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _againRecBtn.titleLabel.font = [UIFont fontWithName:FONTNAME size:14.0f];
    [_againRecBtn addTarget:self action:@selector(againRecord) forControlEvents:UIControlEventTouchUpInside];
    [_audioView addSubview:_againRecBtn];
    
    [self initialTextView];
    if (self.isNeedAudio)
    {
        [self initialUpScrollDragView];
    }
    
    [self initialDownScrollDragView];
    
}

- (void)initialUpScrollDragView
{
    UIView *dragV = [[UIView alloc] initWithFrame:CGRectMake(0, _upScrollView.contentSize.height, _upScrollView.frame.size.width, 60)];
    dragV.backgroundColor = [UIColor clearColor];
    [_upScrollView addSubview:dragV];
    
    UILabel *dragLabel = [[UILabel alloc] initWithFrame:CGRectMake(-5, -15, _upScrollView.frame.size.width, 60)];
    dragLabel.backgroundColor = [UIColor clearColor];
    dragLabel.text = @"上拉录音";
    dragLabel.font = [UIFont fontWithName:FONTNAME size:12.0f];
    dragLabel.textColor = THEME_COLOR_TEXT;
    dragLabel.textAlignment = NSTextAlignmentCenter;
    [dragV addSubview:dragLabel];
    
    _upScrollArrow = [[UIImageView alloc] initWithFrame:CGRectMake(kScreenWidth / 2.0f + 25, (60 - 7) / 2.0f - 15, 12, 7)];
    _upScrollArrow.image = [UIImage imageNamed:@"downArrow"];
    [dragV addSubview:_upScrollArrow];
}

- (void)initialDownScrollDragView
{
    UIView *dragV = [[UIView alloc] initWithFrame:CGRectMake(0, -30, kScreenWidth, 40)];
    dragV.backgroundColor = [UIColor clearColor];
    [_downScrollView addSubview:dragV];
    
    UILabel *dragLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, kScreenWidth, 40)];
    dragLabel.backgroundColor = [UIColor clearColor];
    dragLabel.text = @"下拉输入文字";
    dragLabel.font = [UIFont fontWithName:FONTNAME size:12.0f];
    dragLabel.textColor = THEME_COLOR_TEXT;
    dragLabel.textAlignment = NSTextAlignmentCenter;
    [dragV addSubview:dragLabel];
    
    _downScrollArrow = [[UIImageView alloc] initWithFrame:CGRectMake(kScreenWidth / 2.0f - 45, (40 - 7) / 2.0f, 12, 7)];
    _downScrollArrow.image = [UIImage imageNamed:@"downArrow"];
    [dragV addSubview:_downScrollArrow];
    
    float height = (CONTENT_HEIGHT - _audioView.frame.size.height) / 2.0f;
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth - _audioView.frame.size.width) / 2.0f, height - 80, _audioView.frame.size.width, 60)];
    _timeLabel.font = [UIFont fontWithName:FONTNAME size:45.0f];
    _timeLabel.text = @"0:00";
    _timeLabel.textColor = THEME_COLOR_TEXT;
    _timeLabel.backgroundColor = [UIColor clearColor];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _timeLabel.hidden = YES;
    [_downScrollView addSubview:_timeLabel];
    
    _audioAddChannelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_audioAddChannelBtn setFrame:CGRectMake(kScreenWidth - 15 - 70, 15, 70, 25)];
    
    [_audioAddChannelBtn setGrayBorderStyle];
    _audioAddChannelBtn.tag = ANONYMOUS_TAG;
    
    if (self.curChannelModel != nil)
    {
        [_audioAddChannelBtn setTitle:self.curChannelModel.channelName forState:UIControlStateNormal];
        _audioAddChannelBtn.userInteractionEnabled = NO;
    }
    else
    {
        [_audioAddChannelBtn setTitle:@"添加话题" forState:UIControlStateNormal];
        _audioAddChannelBtn.userInteractionEnabled = YES;
    }
    
    [_audioAddChannelBtn addTarget:self action:@selector(changeAnonymous:) forControlEvents:UIControlEventTouchUpInside];
    [_downScrollView addSubview:_audioAddChannelBtn];
    
    
    
}

- (void)initialTextView
{
    _textBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, SEPERATE_ORIGIN_Y)];
    _textBackView.backgroundColor = [UIColor whiteColor];
    _textBackView.alpha = 0.0f;
    [_upScrollView addSubview:_textBackView];
    
//    UIScrollView *textBackSV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, CONTENT_HEIGHT)];
//    textBackSV.backgroundColor = [UIColor clearColor];
//    textBackSV.tag = TEXTBACK_SCROLLERVIEW_TAG;
//    textBackSV.delegate = self;
//    textBackSV.contentSize = CGSizeMake(kScreenWidth, CONTENT_HEIGHT + 1);
//    [_textBackView addSubview:textBackSV];
    
    _inputTV = [[UITextView alloc] initWithFrame:CGRectMake(15, 15, kScreenWidth - 30, 100)];
    _inputTV.backgroundColor = [UIColor clearColor];
    _inputTV.delegate = self;
    _inputTV.font = [UIFont fontWithName:FONTNAME size:14.0f];
    _inputTV.textColor = THEME_COLOR_GRAY_MIDDLE;
    _inputTV.text = INPUT_PLACEHOLDER;
    _inputTV.scrollsToTop = NO;
    [_textBackView addSubview:_inputTV];
    
    _photoImgV = [[UIImageView alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(_inputTV.frame) + 10, kScreenWidth - 30, (kScreenWidth - 30) * 0.67f)];
    _photoImgV.contentMode = UIViewContentModeScaleAspectFit;
    _photoImgV.backgroundColor = [UIColor clearColor];
    _photoImgV.layer.cornerRadius = 3.0f;
    _photoImgV.layer.masksToBounds = YES;
    [_textBackView addSubview:_photoImgV];
    
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeBtn.backgroundColor = [UIColor clearColor];
    [_closeBtn setImage:[UIImage imageNamed:@"photo_delete"] forState:UIControlStateNormal];
    [_closeBtn setImageEdgeInsets:UIEdgeInsetsMake(7.5f, 7.5f, 7.5f, 7.5f)];
    _closeBtn.frame = CGRectMake(CGRectGetMinX(_photoImgV.frame), CGRectGetMinY(_photoImgV.frame), 30, 30);
    [_closeBtn addTarget:self action:@selector(deletePhoto:) forControlEvents:UIControlEventTouchUpInside];
    _closeBtn.hidden = YES;
    [_textBackView addSubview:_closeBtn];
    
    [self initialKeyboardTool];
//    [self initialAlbum];
    
}

- (void)initialKeyboardTool
{
    _keyboardToolView = [[HWInputBackView alloc] initWithFrame:CGRectMake(0, CONTENT_HEIGHT, self.view.frame.size.width, 44) withLineCount:1];
    _keyboardToolView.alpha = 0.0f;
    _keyboardToolView.backgroundColor = [UIColor whiteColor];
    [_upScrollView addSubview:_keyboardToolView];
    
    if (!self.isNeedAudio) //1.3.0 版本 聂迪修改
    {
        _changePicBoardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _changePicBoardBtn.backgroundColor = [UIColor clearColor];
        [_changePicBoardBtn setImage:[UIImage imageNamed:@"printer"] forState:UIControlStateNormal];
        _changePicBoardBtn.frame = CGRectMake(0, 7, 59, 29);
        [_changePicBoardBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 15.0f, 0, 15.0f)];
        [_changePicBoardBtn addTarget:self action:@selector(showAlbum:) forControlEvents:UIControlEventTouchUpInside];
        [_keyboardToolView addSubview:_changePicBoardBtn];
        
        _keyboardAddChannelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_keyboardAddChannelBtn setFrame:CGRectMake(kScreenWidth - 70 - 50 - 15, 10, 70, 25)];
        [_keyboardAddChannelBtn setGrayBorderStyle];
        _keyboardAddChannelBtn.tag = ANONYMOUS_TAG;
        
        if (self.curChannelModel != nil)
        {
            [_keyboardAddChannelBtn setTitle:self.curChannelModel.channelName forState:UIControlStateNormal];
            _keyboardAddChannelBtn.userInteractionEnabled = NO;
        }
        else
        {
            [_keyboardAddChannelBtn setTitle:@"添加话题" forState:UIControlStateNormal];
            _keyboardAddChannelBtn.userInteractionEnabled = YES;
        }
        
        [_keyboardAddChannelBtn addTarget:self action:@selector(changeAnonymous:) forControlEvents:UIControlEventTouchUpInside];
        [_keyboardToolView addSubview:_keyboardAddChannelBtn];
    }

    if (self.isWriteAndPic)
    {
        if (_changePicBoardBtn == nil)
        {
            _changePicBoardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            _changePicBoardBtn.backgroundColor = [UIColor clearColor];
            [_changePicBoardBtn setImage:[UIImage imageNamed:@"printer"] forState:UIControlStateNormal];
            _changePicBoardBtn.frame = CGRectMake(0, 7, 59, 29);
            [_changePicBoardBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 15.0f, 0, 15.0f)];
            [_changePicBoardBtn addTarget:self action:@selector(showAlbum:) forControlEvents:UIControlEventTouchUpInside];
            [_keyboardToolView addSubview:_changePicBoardBtn];
        }
    }
    
    UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(kScreenWidth - 50.5f, 0, 0.5f, CGRectGetHeight(_keyboardToolView.frame))];
    verticalLine.backgroundColor = THEME_COLOR_LINE;
    [_keyboardToolView addSubview:verticalLine];
    
    UIButton *downArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    [downArrow setImage:[UIImage imageNamed:@"keyboardDown"] forState:UIControlStateNormal];
    downArrow.frame = CGRectMake(kScreenWidth - 50.0f, 0.5f, 50, CGRectGetHeight(_keyboardToolView.frame) - 1);
    [downArrow addTarget:self action:@selector(toHideKeyboard:) forControlEvents:UIControlEventTouchUpInside];
    [_keyboardToolView addSubview:downArrow];
    
}

- (void)initialAlbum
{
    if (_albumGridTV == nil)
    {
        _albumGridTV = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_keyboardToolView.frame), kScreenWidth, CONTENT_HEIGHT - CGRectGetMaxY(_keyboardToolView.frame))];
        _albumGridTV.backgroundColor = [UIColor whiteColor];
        _albumGridTV.delegate = self;
        _albumGridTV.dataSource = self;
        _albumGridTV.separatorStyle = UITableViewCellSeparatorStyleNone;
        _albumGridTV.alpha = 1.0f;
        _albumGridTV.scrollsToTop = NO;
        //    _albumGridTV.userInteractionEnabled = NO;
        [_upScrollView addSubview:_albumGridTV];
    }
    
}

#pragma mark -
#pragma mark UIAlertDelegate Method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == AGAINRECORD_TAG)
    {
        if (buttonIndex == 1)
        {
            [_recorderV resetRecord];
            _audioData = nil;
            [UIView animateWithDuration:0.3f animations:^{
                _againRecBtn.alpha = 0.0f;
            }];
        }
    }
    else if (alertView.tag == BACKALERT_TAG)
    {
        if (buttonIndex == 1)
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:_inputTV.text forKey:@"draft"];
            
            [self.navigationController popViewControllerAnimated:YES];
            
            dispatch_async(dispatch_queue_create("loadCamera", DISPATCH_QUEUE_SERIAL), ^{
                if ([camManager isRunning])
                {
                    [camManager stopRuning];
                    //            [camManager performSelectorInBackground:@selector(startRuning) withObject:nil];
                }
            });
        }
    }
    else if (alertView.tag == 345)
    {
        if (buttonIndex == 0)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
}

#pragma mark -
#pragma mark Private Method

- (void)removeGuideView:(id)sender
{
    if (gView != nil)
    {
        [UIView animateWithDuration:0.3f animations:^{
            gView.alpha = 0;
        }completion:^(BOOL finished) {
            [gView removeFromSuperview];
        }];
    }
}
- (void)backMethod
{
    if (self.publishRoute == NeighbourRoute)
    {
        if (self.publishMode == textMode && _inputTV.text.length != 0 && ![_inputTV.text isEqualToString:INPUT_PLACEHOLDER] && _photoImgV.image == nil)
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:_inputTV.text forKey:@"draft"];
            
            [self.navigationController popViewControllerAnimated:YES];
            
            dispatch_async(dispatch_queue_create("loadCamera", DISPATCH_QUEUE_SERIAL), ^{
                if ([camManager isRunning])
                {
                    [camManager stopRuning];
                    //            [camManager performSelectorInBackground:@selector(startRuning) withObject:nil];
                }
            });
        }
        else if (self.publishMode == textMode && ((_inputTV.text.length != 0 && ![_inputTV.text isEqualToString:INPUT_PLACEHOLDER]) || _photoImgV.image != nil))
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"退出此次编辑?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"退出", nil];
            alert.tag = BACKALERT_TAG;
            [alert show];
//            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//            [userDefaults setObject:_inputTV.text forKey:@"draft"];
        }
        else if (self.publishMode == audioMode && _audioData != nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"退出此次编辑?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"退出", nil];
            alert.tag = BACKALERT_TAG;
            [alert show];
//            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//            [userDefaults setObject:_inputTV.text forKey:@"draft"];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
            dispatch_async(dispatch_queue_create("loadCamera", DISPATCH_QUEUE_SERIAL), ^{
                if ([camManager isRunning])
                {
                    [camManager stopRuning];
                    //            [camManager performSelectorInBackground:@selector(startRuning) withObject:nil];
                }
            });
        }
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
        dispatch_async(dispatch_queue_create("loadCamera", DISPATCH_QUEUE_SERIAL), ^{
            if ([camManager isRunning])
            {
                [camManager stopRuning];
                //            [camManager performSelectorInBackground:@selector(startRuning) withObject:nil];
            }
        });
    }
    
}

- (void)toPublish:(id)sender
{
//    [self toHideKeyboard:nil];
    
    [_inputTV resignFirstResponder];
    
    NSString *publishStr = [[_inputTV.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    
    if (self.publishRoute == NeighbourPhoneRoute)
    {
        if (publishStr.length == 0)
        {
            [Utility showToastWithMessage:@"写点内容再发吧~" inView:self.view];
            return;
        }
        
        //电话卡片 发布内容  纯文字
        [Utility showMBProgress:self.view.window message:@"发送数据"];
        HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
        
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [param setPObject:[HWUserLogin currentUserLogin].residendId forKey:@"residentId"]; // 住户id
        [param setPObject:self.callType forKey:@"type"];      // 类型  0 ：店铺  1：物业
//        [param setPObject:self.callNumber forKey:@"phoneCalled"]; // 拨打的电话号码
        [param setPObject:self.callId forKey:@"toId"];  // 接听关联id(拨打电话对象IDeg.店铺、物业ID)
//        [param setPObject:self.callTime forKey:@"callTime"];      // 拨打时间
        [param setPObject:self.callSuccess forKey:@"isDialUp"];      // 是否拨通0：未拨通，1：拨通
        [param setPObject:publishStr forKey:@"comment"];       // 点评
//        [param setPObject:(_anonymous ? @"1" : @"0") forKey:@"isAnonymous"];
        [param setPObject:self.historyCardId forKey:@"phoneHistoryId"];
//        [param setPObject:[HWUserLogin currentUserLogin].nickname forKey:@"nickName"];
        [manager POST:kTelResult parameters:param queue:nil success:^(id responseObject) {
            [Utility hideMBProgress:self.view.window];
            
            
            if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"])
            {
                [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                return ;
            }
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
            
            AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
            [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
            //发布成功 设置引导页步骤
            [self updateGuideStep];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSString *code, NSString *error) {
            [Utility hideMBProgress:self.view.window];
            [Utility showToastWithMessage:error inView:self.view];
        }];
        
        return;
    }
    else if (self.publishRoute == PropertyRoute)
    {
        [self publishWithPropertyFeedback];
    }
    else
    {
        [self publishWithNeighbourRoute];
    }
}

- (void)publishWithPropertyFeedback
{
    NSString *publishStr = [[_inputTV.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //附件类型1：文字 0：文字+图片2：语音
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    
    if (self.publishMode == textMode)
    {
        if (publishStr == nil || [publishStr isEqualToString:@""] || [publishStr isEqualToString:INPUT_PLACEHOLDER])
        {
            [Utility showToastWithMessage:@"写点内容再发吧~" inView:self.view];
            return;
        }
        
        [Utility showMBProgress:self.view.window message:@"发送数据"];
        
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
//        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
        [param setPObject:publishStr forKey:@"text"];
        [param setPObject:(_anonymous ? @"1" : @"0") forKey:@"isAnonymous"];
        [param setPObject:[HWUserLogin currentUserLogin].tenementId forKey:@"tenementId"];
        [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
        [param setPObject:[HWUserLogin currentUserLogin].nickname forKey:@"nickName"];
        if (_photoImgV.image != nil)
        {
            [param setPObject:@"23" forKey:@"releaseType"];
            [param setPObject:[NSString stringWithFormat:@"%@%g",[HWUserLogin currentUserLogin].userId, [[NSDate date] timeIntervalSinceNow]] forKey:@"fileName"];
            [param setPObject:UIImageJPEGRepresentation(_photoImgV.image, 1.0f) forKey:@"file"];
            [manager POSTImage:kPropertyFeedback parameters:param queue:nil success:^(id responseObject) {
                
                [Utility hideMBProgress:self.view.window];
                
                if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                    [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                    return ;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
                
                AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
                [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
                //发布成功 设置引导页步骤
                [self updateGuideStep];
                [self.navigationController popViewControllerAnimated:YES];
                
            } failure:^(NSString *error) {
                [Utility hideMBProgress:self.view.window];
                [Utility showToastWithMessage:error inView:self.view];
            }];
        }
        else
        {
            [param setPObject:@"24" forKey:@"releaseType"];
            [manager POSTImage:kPropertyFeedback parameters:param queue:nil success:^(id responseObject) {
                [Utility hideMBProgress:self.view.window];
                
                if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                    [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                    return ;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
                
                AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
                [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
                //发布成功 设置引导页步骤
                [self updateGuideStep];
                [self.navigationController popViewControllerAnimated:YES];
            } failure:^(NSString *error) {
                [Utility hideMBProgress:self.view.window];
                [Utility showToastWithMessage:error inView:self.view];
            }];
        }
    }
    else if (self.publishMode == audioMode)
    {
        if (_audioData == nil)
        {
            [Utility showToastWithMessage:@"请录制语音" inView:self.view];
            return;
        }
        
        [_recorderV stopPlay];
        
        [Utility showMBProgress:self.view message:@"发送数据"];
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
//        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
        [param setPObject:(_anonymous ? @"1" : @"0") forKey:@"isAnonymous"];
        [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
        [param setPObject:@"25" forKey:@"releaseType"];
        [param setPObject:_audioData forKey:@"file"];
        [param setPObject:[NSString stringWithFormat:@"%d",_audioDuration] forKey:@"soundTime"];
        [param setPObject:[HWUserLogin currentUserLogin].tenementId forKey:@"tenementId"];
        [param setPObject:[NSString stringWithFormat:@"%@%g",[HWUserLogin currentUserLogin].userId, [[NSDate date] timeIntervalSinceNow]] forKey:@"fileName"];
        [param setPObject:[HWUserLogin currentUserLogin].nickname forKey:@"nickName"];
        
        [manager POSTAudio:kPropertyFeedback parameters:param queue:nil success:^(id responseObject) {
            [Utility hideMBProgress:self.view];
            
            if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                return ;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
            
            AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
            [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
            //发布成功 设置引导页步骤
            [self updateGuideStep];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSString *error) {
            [Utility hideMBProgress:self.view.window];
            [Utility showToastWithMessage:error inView:self.view];
        }];
    }
}

- (void)publishWithNeighbourRoute
{
    NSString *publishStr = [[_inputTV.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    //附件类型0：文字1：文字+图片2：语音
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    
    if (self.publishMode == textMode)
    {
        [MobClick event:@"click_send"];
        if (publishStr == nil || [publishStr isEqualToString:@""] || [publishStr isEqualToString:INPUT_PLACEHOLDER])
        {
            [Utility showToastWithMessage:@"写点内容再发吧~" inView:self.view];
            return;
        }
        
        [Utility showMBProgress:self.view.window message:@"发送数据"];
        
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
//        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
        [param setPObject:publishStr forKey:@"content"];
        [param setPObject:(_anonymous ? @"1" : @"0") forKey:@"isAnonymous"];
        if (curChannelModel != nil)
        {
            [param setPObject:curChannelModel.channelId forKey:@"channelId"];
        }
        [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"valliageId"];
        [param setPObject:[HWUserLogin currentUserLogin].nickname forKey:@"nickName"];
        if (_photoImgV.image != nil)
        {
            [param setPObject:@"0" forKey:@"releaseType"];
            [param setPObject:[NSString stringWithFormat:@"%@%g",[HWUserLogin currentUserLogin].userId, [[NSDate date] timeIntervalSinceNow]] forKey:@"fileName"];
            [param setPObject:[Utility convertImgTo256K:_photoImgV.image] forKey:@"pubFile"];
            [manager POSTImage:kPublishFile parameters:param queue:nil success:^(id responseObject) {
                [Utility hideMBProgress:self.view.window];
                
                if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                    [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                    return ;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
                
                AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
                [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
                //发布成功 设置引导页步骤
                [self updateGuideStep];
                [self.navigationController popViewControllerAnimated:YES];
                
            } failure:^(NSString *error) {
                [Utility hideMBProgress:self.view.window];
                [Utility showToastWithMessage:error inView:self.view];
            }];
        }
        else
        {
            [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
            [param setPObject:@"1" forKey:@"releaseType"];
            
            if (self.topic != nil)
            {
                [param setPObject:self.topic forKey:@"topic"];
                [param setPObject:@"4" forKey:@"releaseType"];
            }
            
            [manager POST:kPublishContent parameters:param queue:nil success:^(id responseObject) {
                [Utility hideMBProgress:self.view.window];
                
                if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                    [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                    return ;
                }
                // 清空草稿
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:@"" forKey:@"draft"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
                
                AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
                [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
                //发布成功 设置引导页步骤
                [self updateGuideStep];
                
                [self.navigationController popViewControllerAnimated:YES];
            } failure:^(NSString *code, NSString *error) {
                [Utility hideMBProgress:self.view.window];
                [Utility showToastWithMessage:error inView:self.view];
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }
    else if (self.publishMode == audioMode)
    {
        
        if (_audioData == nil)
        {
            [Utility showToastWithMessage:@"请录制语音" inView:self.view];
            return;
        }
        
        [MobClick event:@"click_sendmic"];
        
        [_recorderV stopPlay];
        
        [Utility showMBProgress:self.view.window message:@"发送数据"];
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
//        [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
        [param setPObject:[HWUserLogin currentUserLogin].userId forKey:@"userId"];
        [param setPObject:(_anonymous ? @"1" : @"0") forKey:@"isAnonymous"];
        if (curChannelModel != nil)
        {
            [param setPObject:curChannelModel.channelId forKey:@"channelId"];
        }
        [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"valliageId"];
        [param setPObject:@"2" forKey:@"releaseType"];
        [param setPObject:_audioData forKey:@"pubFile"];
        [param setPObject:[NSString stringWithFormat:@"%d",_audioDuration] forKey:@"soundTime"];
        [param setPObject:[NSString stringWithFormat:@"%@%g",[HWUserLogin currentUserLogin].userId, [[NSDate date] timeIntervalSinceNow]] forKey:@"fileName"];
        [param setPObject:[HWUserLogin currentUserLogin].nickname forKey:@"nickName"];
        [manager POSTAudio:kPublishFile parameters:param queue:nil success:^(id responseObject) {
            [Utility hideMBProgress:self.view.window];
            
            if ([[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"status"] isEqualToString:@"1"]) {
                [Utility showToastWithMessage:[[responseObject dictionaryObjectForKey:@"data"] stringObjectForKey:@"returnInfo"] inView:self.view];
                return ;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:HWNeighbourDragRefresh object:nil];
            
            AppDelegate *appDel = (AppDelegate *)SHARED_APP_DELEGATE;
            [Utility showToastWithMessage:@"发布成功" inView:appDel.window];
            //发布成功 设置引导页步骤
            [self updateGuideStep];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSString *error) {
            [Utility hideMBProgress:self.view.window];
            [Utility showToastWithMessage:error inView:self.view];
        }];
    }
}

-(void)updateGuideStep
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults integerForKey:kGuideStep] == 1)
    {
        [userDefaults setInteger:2 forKey:kGuideStep];
        [userDefaults synchronize];
        //[[NSNotificationCenter defaultCenter] postNotificationName:InitialGuideViewAfterPublish object:nil];
    }
}

- (void)toWriteNoAnimate
{
    self.navigationItem.rightBarButtonItem = [Utility navButton:self title:@"发布" action:@selector(toPublish:)];
    _emptyView.alpha = 0.0f;
    _textBackView.alpha = 1.0f;
    _audioView.alpha = 0.0f;
//    [_inputTV becomeFirstResponder];
}

- (void)toWrite:(id)sender
{
    [MobClick event:@"click_textphoto"];
    self.navigationItem.rightBarButtonItem = [Utility navButton:self title:@"发布" action:@selector(toPublish:)];
    [UIView animateWithDuration:0.5f animations:^{
        _emptyView.alpha = 0.0f;
        _textBackView.alpha = 1.0f;
        _audioView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [_inputTV becomeFirstResponder];
    }];
}

- (void)showAlbum:(UIButton *)sender
{
    [MobClick event:@"click_camera"];
    UIImage *image = [_changePicBoardBtn imageForState:UIControlStateNormal];
    if ([image isEqual:[UIImage imageNamed:@"printer"]])
    {
        [_changePicBoardBtn setImage:[UIImage imageNamed:@"pencil"] forState:UIControlStateNormal];
        [self resetScrollViewFrameByKeyboardHeight:216.0f];
        [_inputTV resignFirstResponder];
    }
    else
    {
        [_changePicBoardBtn setImage:[UIImage imageNamed:@"printer"] forState:UIControlStateNormal];
        [_inputTV becomeFirstResponder];
    }
    
    
}

- (void)resetScrollViewFrameByKeyboardHeight:(float)height
{
    CGRect frame = _keyboardToolView.frame;
    frame.origin.y = CONTENT_HEIGHT - height - frame.size.height;
    _keyboardToolView.alpha = 1.0f;
//    _albumGridTV.alpha = 1.0f;
//    _albumGridTV.userInteractionEnabled = YES;
    [self initialAlbum];
    
//    CGRect scrollFrame = _selBoardSV.frame;
//    scrollFrame.origin.y = CGRectGetMaxY(_keyboardToolView.frame);
//    scrollFrame.size.height = self.view.frame.size.height - CGRectGetMaxY(_keyboardToolView.frame);
    
    [UIView animateWithDuration:0.3f animations:^{
        _keyboardToolView.frame = frame;
        [self reloadAlbumTableViewFrame];
        
        
        CGRect frame2 = _audioView.frame;
        frame2.origin.y = CONTENT_HEIGHT;
        _audioView.frame = frame2;
        _audioView.alpha = 0.0f;
//        _selBoardSV.frame = scrollFrame;
    }];
}

- (void)toChangeMaskView:(id)sender
{
    [_inputTV resignFirstResponder];
    [UIView animateWithDuration:0.5f animations:^{
        _textMaskView.alpha = 1.0f;
        
        CGRect frame = _keyboardToolView.frame;
        frame.origin.y = CONTENT_HEIGHT - frame.size.height;
        _keyboardToolView.frame = frame;
        
        CGRect frame1 = _albumGridTV.frame;
        frame1.origin.y = CGRectGetMaxY(_keyboardToolView.frame);
        _albumGridTV.frame = frame1;
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)doSwipe:(UIGestureRecognizer *)sender
{
    [MobClick event:@"slide_down"];
    [self hideRecorder];
}

- (void)showRecorder
{
    [MobClick event:@"click_mic"];
    self.publishMode = audioMode;
    _audioViewScrollEnable = NO;
    
    self.navigationItem.rightBarButtonItem = [Utility navButton:self title:@"发布" action:@selector(toPublish:)];
    
    [UIView animateWithDuration:0.5f animations:^{
        
        CGRect frame = _upScrollView.frame;
        frame.origin.y = -frame.size.height;
        _upScrollView.frame = frame;
        
        CGRect frame1 = _downScrollView.frame;
        frame1.origin.y = 0;
        _downScrollView.frame = frame1;
        
        CGRect frame2 = _audioView.frame;
        frame2.origin.y = (CONTENT_HEIGHT - frame2.size.height) / 2.0f;
        _audioView.frame = frame2;
        _audioView.alpha = 1.0f;
        
        _originPos = frame2.origin;
        
        _recorderV.state = RecorderStart;
        _audioLab.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)hideRecorder
{
    self.publishMode = textMode;
    float height = CONTENT_HEIGHT / 2.0f - 5.0f;
    _audioViewScrollEnable = YES;
    
    [self showPublishButton];
    
    [UIView animateWithDuration:0.5f animations:^{
        
        CGRect frame = _upScrollView.frame;
        frame.origin.y = 0;
        _upScrollView.frame = frame;
        
        CGRect frame1 = _downScrollView.frame;
        frame1.origin.y = CONTENT_HEIGHT;
        _downScrollView.frame = frame1;
        
        CGRect frame2 = _audioView.frame;
        frame2.origin.y = height + height / 3.0f - 90;
        _audioView.frame = frame2;
        
        if (_photoImgV.image == nil)
        {
            _audioView.alpha = 1.0f;
        }
        else
        {
            _audioView.alpha = 0.0f;
        }
        
        _originPos = frame2.origin;
        
        _recorderV.state = Inactive;
        _audioLab.alpha = 1.0f;
        _againRecBtn.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        // label 隐藏
//        [_audioBtn setImage:[UIImage imageNamed:@"voice"] forState:UIControlStateNormal];
    }];
}

- (void)reloadAlbumTableViewFrame
{
    _albumGridTV.frame = CGRectMake(0,
                                    CGRectGetMaxY(_keyboardToolView.frame),
                                    kScreenWidth,
                                    CONTENT_HEIGHT - CGRectGetMaxY(_keyboardToolView.frame));
}

- (void)deletePhoto:(id)sender
{
    [MobClick event:@"click_delete_photo"];
    _photoImgV.image = nil;
    _closeBtn.hidden = YES;
//    [self toHideKeyboard:nil];
    [_inputTV becomeFirstResponder];
}

- (void)changeAnonymous:(UIButton *)sender
{
    if (self.isNeedAudio)
    {
        [MobClick event:@"click_tianjiapingdaotuwen"]; //maidian_1.2.1
    }
    else
    {
        [MobClick event:@"click_tianjiapingdaoluyin"]; //maidian_1.2.1
    }
    // push 搜索 页面
    [self didDeleteSelectedChannel];
    HWAddChannelViewController *addChannelVC = [[HWAddChannelViewController alloc] init];
//    addChannelVC.currentChannel = self.curChannelModel;
    addChannelVC.delegate = self;
    [self.navigationController pushViewController:addChannelVC animated:YES];
    
}

- (void)againRecord
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"重录会删除刚才的录音" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    alert.tag = AGAINRECORD_TAG;
    [alert show];
}

- (void)toHideKeyboard:(id)sender
{
    
    [MobClick event:@"click_downwards"];
    [_inputTV resignFirstResponder];
    [UIView animateWithDuration:0.5f animations:^{
        
        CGRect frame = _keyboardToolView.frame;
        frame.origin.y = CONTENT_HEIGHT;
        _keyboardToolView.frame = frame;
        
        
        CGRect frame1 = _albumGridTV.frame;
        frame1.origin.y = CGRectGetMaxY(_keyboardToolView.frame);
        _albumGridTV.frame = frame1;
        
        
        if (_photoImgV.image == nil && self.isNeedAudio)
        {
            CGRect frame2 = _textBackView.frame;
            frame2.size.height = _emptyView.frame.size.height;
            _textBackView.frame = frame2;
            
            if (self.publishMode != audioMode)
            {
                float height = CONTENT_HEIGHT / 2.0f - 5.0f;
                CGRect frame3 = _audioView.frame;
                frame3.origin.y = height + height / 3.0f - 90.0f;
                _audioView.frame = frame3;
                _audioView.alpha = 1.0f;
            }
            
//            self.navigationItem.rightBarButtonItem = nil;
        }
        else
        {
            CGRect frame2 = _textBackView.frame;
            frame2.size.height = CONTENT_HEIGHT;
            _textBackView.frame = frame2;
            
            if (self.publishMode != audioMode)
            {
                CGRect frame3 = _audioView.frame;
                frame3.origin.y = CONTENT_HEIGHT;
                _audioView.frame = frame3;
                _audioView.alpha = 0.0f;
            }
        }
        
        [self showPublishButton];
        
        
    } completion:^(BOOL finished) {
        _keyboardToolView.alpha = 0.0f;
        _albumGridTV.alpha = 0.0f;
        [_albumGridTV removeFromSuperview];
        _albumGridTV = nil;
    }];
}

- (void)showPublishButton
{
    if ([_inputTV.text isEqualToString:INPUT_PLACEHOLDER] && _photoImgV.image == nil && self.isNeedAudio)
    {
        _emptyView.alpha = 1.0f;
        _textBackView.alpha = 0.0f;
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        _emptyView.alpha = 0.0f;
        _textBackView.alpha = 1.0f;
        self.navigationItem.rightBarButtonItem = [Utility navButton:self title:@"发布" action:@selector(toPublish:)];
    }
}

#pragma mark -
#pragma mark UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:INPUT_PLACEHOLDER])
    {
        textView.text = @"";
    }
    return YES;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""])
    {
        textView.text = INPUT_PLACEHOLDER;
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSMutableString *resultText = [textView.text mutableCopy];
    [resultText replaceCharactersInRange:range withString:text];
    
    NSLog(@"text : %d %@ ",[Utility calculateTextLength:resultText], resultText);
    
    if (resultText.length > 200 && range.length == 0)
    {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark HWRecorderView Delegate

- (void)moveToRecordState
{
    [self showRecorder];
}

- (void)recordState:(RecorderState)state
{
    if (state == Recordering)
    {
        [UIView animateWithDuration:0.3f animations:^{
            _timeLabel.hidden = NO;
        }];
    }
    else if (state == RecorderStart)
    {
        [UIView animateWithDuration:0.3f animations:^{
            _timeLabel.hidden = YES;
            _timeLabel.text = @"0:00";
            _againRecBtn.alpha = 0.0f;
        }];
    }
    else if (state == Playing)
    {
        if ([_timeLabel.text isEqualToString:[NSString stringWithFormat:@"%d:%02d", _audioDuration / 60, _audioDuration % 60]])
        {
            _timeLabel.text = @"0:00";
        }
    }
    else if (state == Stop)
    {
//        _timeLabel.text = @"0:00";
        [UIView animateWithDuration:0.3f animations:^{
            _againRecBtn.alpha = 1.0f;
        }];
    }
}

- (void)recordTiming:(int)time
{
    _timeLabel.text = [NSString stringWithFormat:@"%d:%02d", time / 60, time % 60];
}

- (void)finishRecordWithData:(NSData *)audioData andDuration:(int)time
{
    _audioData = audioData;
    _audioDuration = time;
}

#pragma mark -
#pragma mark ScrollView Delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.tag == UP_SCROLLVIEW_TAG)
    {
        if (scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height + 40 && self.isNeedAudio)
        {
            [self showRecorder];
        }
    }
    else if (scrollView.tag == DOWN_SCROLLVIEW_TAG)
    {
        if (scrollView.contentOffset.y < -40)
        {
            [MobClick event:@"slide_up"];
            [self hideRecorder];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.tag == UP_SCROLLVIEW_TAG && _audioViewScrollEnable)
    {
        CGRect frame = _audioView.frame;
        frame.origin.y = _originPos.y - scrollView.contentOffset.y ;
        _audioView.frame = frame;
        
        if (_keyboardToolView.frame.origin.y < CONTENT_HEIGHT)
        {
//            NSLog(@"*****************************");
            [self toHideKeyboard:nil];
        }
        
    }
    else if (scrollView.tag == DOWN_SCROLLVIEW_TAG && !_audioViewScrollEnable)
    {
        CGRect frame = _audioView.frame;
        frame.origin.y = _originPos.y - scrollView.contentOffset.y ;
        _audioView.frame = frame;
    }
    else if (scrollView.tag == TEXTBACK_SCROLLERVIEW_TAG)
    {
        
        
    }
}

#pragma mark -
#pragma mark TableView Delegate Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.assets.count + 4) / 4.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    static NSString *cellIdentifier1 = @"cell1";
    HWPublishAlbumCell *cell = nil;
    
    if (indexPath.row == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier1];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }
    
    if (!cell)
    {
        if (indexPath.row == 0)
        {
            cell = [[HWPublishAlbumCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier1];
        }
        else
        {
            cell = [[HWPublishAlbumCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }
    cell.delegate = self;
    
    if (indexPath.row == 0)
    {
        
        [cell setImage:self.assets withIndex:0];
        if (camPreview == nil)
        {
            camPreview = cell.imgBtnOne;
            [self updateCamera];
        }
    }
    else
    {
        long index = 3 + (indexPath.row - 1) * 4;
        [cell setImage:self.assets withIndex:index];
    }
    return cell;
}

#pragma mark -
#pragma mark HWPublishAlbumCellDelegate 

- (void)didSelectTakePhoto
{
    // 打开相机
    
    [MobClick event:@"click_screen_photo"];
    GKImagePickerController *imagePicker = [[GKImagePickerController alloc] init];
    imagePicker.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didSelectAlbumPicture:(UIImage *)image
{
    [MobClick event:@"click_choose_photo"];
    
    HWCropImageViewController *imagePicker = [[HWCropImageViewController alloc] init];
    imagePicker.delegate = self;
    imagePicker.stillImage = image;
    HWBaseNavigationController *nav = [[HWBaseNavigationController alloc] initWithRootViewController:imagePicker];
    [nav setNavigationBarBlackColor];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark -
#pragma mark GKImagePickerControllerDelegate

- (void)didFinishedSelectImage:(UIImage *)image
{
    [_albumGridTV reloadData];
    _photoImgV.image = image;
    _closeBtn.hidden = NO;
    [self toHideKeyboard:nil];
}

#pragma mark -
#pragma mark HWCropImageViewControllerDelegate

- (void)didCropImage:(UIImage *)image
{
    _photoImgV.image = image;
    _closeBtn.hidden = NO;
    [self toHideKeyboard:nil];
}

#pragma mark -
#pragma mark        HWAddChannelViewController Delegate

- (void)didSelectChannel:(HWChannelModel *)model
{
    if (_audioAddChannelBtn)
    {
        [_audioAddChannelBtn setTitle:model.channelName forState:UIControlStateNormal];
    }
    if (_keyboardAddChannelBtn)
    {
        [_keyboardAddChannelBtn setTitle:model.channelName forState:UIControlStateNormal];
    }
    
    self.curChannelModel = model;
}

- (void)didDeleteSelectedChannel
{
    if (_audioAddChannelBtn)
    {
        [_audioAddChannelBtn setTitle:@"添加话题" forState:UIControlStateNormal];
    }
    if (_keyboardAddChannelBtn)
    {
        [_keyboardAddChannelBtn setTitle:@"添加话题" forState:UIControlStateNormal];
    }
    self.curChannelModel = nil;
}

#pragma mark -
#pragma mark Notification Method

- (void)addKeyboardAbserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(keyboardWasHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)removeKeyboardAbserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    [_changePicBoardBtn setImage:[UIImage imageNamed:@"printer"] forState:UIControlStateNormal];
    
    NSDictionary *info = [notification userInfo];
    NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;

    [self resetScrollViewFrameByKeyboardHeight:keyboardSize.height];
}

- (void)keyboardWasHidden:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    [self resetScrollViewFrameByKeyboardHeight:keyboardSize.height];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    
    [self resetScrollViewFrameByKeyboardHeight:keyboardSize.height];
}

- (void)loadAlbumSuccess:(NSNotification *)notification
{
    self.assets = _albumManager.assets;
    if (_albumGridTV != nil)
    {
        [_albumGridTV reloadData];
    }
}

#pragma mark -
#pragma mark System Method

- (void)viewWillDisappear:(BOOL)animated
{
    if (_recorderV)
    {
        [_recorderV stopPlay];
    }
    [self removeKeyboardAbserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HWAlbumManagerLoadSuccess object:nil];
    
    MLNavigationController *navigation = (MLNavigationController *)self.navigationController;
    navigation.canDragBack = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAlbumSuccess:) name:HWAlbumManagerLoadSuccess object:nil];
    [_albumManager loadAlbum];
    
    MLNavigationController *navigation = (MLNavigationController *)self.navigationController;
    navigation.canDragBack = NO;
//    [self addKeyboardAbserver];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self addKeyboardAbserver];
    if (!self.isNeedAudio)
    {
        [_inputTV becomeFirstResponder];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults objectForKey:@"draft"] && ![[userDefaults objectForKey:@"draft"] isEqualToString:@""])
        {
            _inputTV.text = [userDefaults objectForKey:@"draft"];
        }
    }
}

- (void)updateCamera
{
    camManager = [GKCameraManager manager];
    [camManager setup];
    [camManager embedPreviewInView:camPreview];
    
    dispatch_async(dispatch_queue_create("loadCamera", DISPATCH_QUEUE_SERIAL), ^{
        if (![camManager isRunning])
        {
            [camManager startRuning];
        }
    });
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
