//
//  RegisterVC.m
//  PUClient
//
//  Created by RRLhy on 15/7/20.
//  Copyright (c) 2015年 RRLhy. All rights reserved.
//

#import "RegisterVC.h"
#import "CompleteInformationVC.h"
#import "PsdEmailVC.h"
#import "CompleteInformationVC.h"
#import "JKCountDownButton.h"
#import "CodeValidApi.h"
#import "VerifyCodeApi.h"
#import "PsdCodeApi.h"
#import "BoundMobileApi.h"
@interface RegisterVC ()

@property (weak, nonatomic) IBOutlet UITextField *phoneTf;
@property (weak, nonatomic) IBOutlet UITextField *autoCodeTf;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet JKCountDownButton *authCodeBtn;
@property (weak, nonatomic) IBOutlet UIImageView *bottomline;
@property (nonatomic,assign)BOOL isSucces;
@end

@implementation RegisterVC

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    [_authCodeBtn stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    if (self.type==1) {
        self.titleLabel.text = @"忘记密码";
    }else if(self.type == 2){
        self.titleLabel.text = @"绑定手机";
    }else{
        self.titleLabel.text = @"马上注册";
    }
    
    UIImage * imageN = [UIImage stretchImageWithName:@"btn_me_n"];
    UIImage * imageH = [UIImage stretchImageWithName:@"btn_me_h"];
    UIImage * authN  = [UIImage stretchImageWithName:@"btn_me_resend__bg_h"];
    UIImage * authH  = [UIImage stretchImageWithName:@"btn_me_resend__bg_h"];
    
    [_nextBtn setBackgroundImage:imageN forState:UIControlStateNormal];
    [_nextBtn setBackgroundImage:imageH forState:UIControlStateHighlighted];
    [_authCodeBtn setBackgroundImage:authN forState:UIControlStateNormal];
    [_authCodeBtn setBackgroundImage:authH forState:UIControlStateDisabled];
    
    _bottomline.hidden = YES;
    _autoCodeTf.hidden = YES;
    _authCodeBtn.hidden = YES;

}

#pragma mark 下一步操作
- (IBAction)nextClick:(id)sender {
    
    BOOL isPhone = [self.phoneTf.text isTelPhoneNub:self.phoneTf.text];
    if (!isPhone) return;

    if (!self.isSucces) {
        
        if (self.type == FindPsd) {
            //找密码
//            [self requestPsdCode];
            [self requestCode];
            
        }else if(self.type == Register){
            //注册
            [self requestCode];
            
        }else if(self.type == BoundMobile){
            //绑定手机
            [self requestCode];
        }
        
    }else{
    
        NSString  * str = [self.autoCodeTf.text replaceString];
        if (str.length >0) {
            [self verifyCode];
        }
    }
}
#pragma mark  获取注册验证码
- (void)requestCode
{
    [IanAlert showloadingAllowUserInteraction:NO];
    CodeValidApi * api = [[CodeValidApi alloc]initWithUserPhone:_phoneTf.text];
    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        NSDictionary * dic = request.responseJSONObject;
        NSLog(@"手机号是否%@",dic);
        if (dic) {
            JsonModel * json = [JsonModel objectWithKeyValues:dic];

            if (json.code == SUCCESSCODE) {
                
                BOOL exist = [json.data[@"exist"] boolValue];
                
                if (self.type == Register) {
                    
                    if (exist) {
                        [IanAlert alertError:@"手机号已存在" length:1];
                        return ;
                    }
                    
                }else if(self.type == FindPsd){
                    
                    if (!exist) {
                        [IanAlert alertError:@"手机号不存在" length:1];
                        return;
                    }
                    
                }else if(self.type == BoundMobile){
                    
                    if (!exist) {
                        [IanAlert alertError:@"手机号不存在" length:1];
                        return;
                    }
                }
                
                self.isSucces = YES;
                __weak RegisterVC * weakself = self;
                [UIView animateWithDuration:0.2 animations:^{
                    _bottomline.hidden = NO;
                    _autoCodeTf.hidden = NO;
                    _authCodeBtn.hidden = NO;
                    _nextBtn.frame = CGRectMake(10, 200, Main_Screen_Width - 20, 40);
                    [weakself getCode];
                    
                } completion:^(BOOL finished) {
                    
                    
                }];

                [self requestPsdCode];
                [IanAlert hideLoading];
                
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

#pragma mark 获取验证码
- (void)requestPsdCode
{
    PsdCodeApi * api = [[PsdCodeApi alloc]initWithUserPhone:_phoneTf.text];
    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        NSDictionary * dic = request.responseJSONObject;
        NSLog(@"请求验证码%@",dic);
        if (dic) {
            JsonModel * json = [JsonModel objectWithKeyValues:dic];
            if (json.code == SUCCESSCODE) {
                //手机号可用

            }else{
                [IanAlert alertError:json.msg length:1];
            }
        }else
        {
            [IanAlert alertError:ERRORMSG1 length:1];
        }
        
    } failure:^(YTKBaseRequest *request) {
        
        [IanAlert alertError:ERRORMSG2 length:1];
        
    }];
}

#pragma mark 较对验证码
- (void)verifyCode
{
    [IanAlert showloading];
    VerifyCodeApi * api = [[VerifyCodeApi alloc]initWithUserPhone:_phoneTf.text code:_autoCodeTf.text];
    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        NSDictionary * dic = request.responseJSONObject;
        NSLog(@"较对验证码api%@",dic);
        if (dic) {
            JsonModel * json = [JsonModel objectWithKeyValues:dic];

            if (json.code == SUCCESSCODE) {
                [IanAlert hideLoading];
                if (self.type == 1) {
                    
                    [self performSegueWithIdentifier:@"findPsd1" sender:self];
                    
                }else if (self.type == 0){
                    
                    [self performSegueWithIdentifier:@"completeInformation" sender:self];
                    
                }else{
                    
                    [self boundingOldCount];
                }
                
            }else{
                
                [IanAlert alertError:json.msg length:1];
            }
        }else
        {
            [IanAlert alertError:ERRORMSG1 length:1];
        }

    } failure:^(YTKBaseRequest *request) {
        
        [IanAlert alertError:ERRORMSG2 length:1];
    }];
}

#pragma mark 绑定老帐号
- (void)boundingOldCount
{
    [IanAlert showloading];
    BoundMobileApi * api = [[BoundMobileApi alloc]initWithUserMobile:_phoneTf.text token:[UserInfoConfig sharedUserInfoConfig].userInfo.token code:_autoCodeTf.text];
    [api startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        NSDictionary * dic = request.responseJSONObject;
        NSLog(@"绑定老帐号%@",dic);
        if (dic) {
            JsonModel * json = [JsonModel objectWithKeyValues:dic];
            if (json.code == SUCCESSCODE) {
                [IanAlert hideLoading:^(BOOL finished) {
                    [IanAlert alertSuccess:@"绑定成功" length:1];
                }];
                
                [self performSelector:@selector(popRootViewController) withObject:nil afterDelay:1];
                
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

#pragma mark 获取验证码
- (IBAction)getAuthCode:(JKCountDownButton*)sender {
    
    [self requestCode];
}

- (void)getCode{
    
    _authCodeBtn.enabled = NO;
    //button type要 设置成custom 否则会闪动
    [_authCodeBtn startWithSecond:60];
    
    [_authCodeBtn didChange:^NSString *(JKCountDownButton *countDownButton,int second) {
        NSString *title = [NSString stringWithFormat:@"重发(%d)",second];
        return title;
    }];
    [_authCodeBtn didFinished:^NSString *(JKCountDownButton *countDownButton, int second) {
        countDownButton.enabled = YES;
        return @"重新获取";
        
    }];
}

#pragma makr segue 传值
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"completeInformation"]) {
        
        CompleteInformationVC * theSegue = segue.destinationViewController;
        theSegue.mobile = _phoneTf.text;
        theSegue.code = _autoCodeTf.text;
        
    }else if([segue.identifier isEqualToString:@"findPsd1"]){
        //手机获得
        PsdEmailVC * theSegue = segue.destinationViewController;
        theSegue.isEmail = NO;
        theSegue.phone = self.phoneTf.text;
        theSegue.code = _autoCodeTf.text;
    }
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
