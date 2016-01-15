//
//  HWAddReceiveAddressController.m
//  Community
//
//  Created by ryder on 8/3/15.
//  Copyright (c) 2015 caijingpeng. All rights reserved.
//
//  功能描述：
//      天天团添加收货地址
//  修改记录：
//      姓名         日期              修改内容
//     程耀均     2015-07-30           创建文件

#import "HWAddReceiveAddressController.h"
#import "UIViewExt.h"
#import "BasePickView.h"
#import "NSString+Helper.h"
#import "Utility.h"
#import "AppDelegate.h"
#define kCellTextColor 65/255.0f
#define TextFieldTag 100


@interface HWAddReceiveAddressController ()

{
    UITableView *_tableView;
    UITextField *_userNameTF;
    UITextField *_userNumTF;
    UITextField *_userAddTF;
    NSMutableDictionary *dic ;
    NSMutableArray   *array; // 省市区
}



@end

@implementation HWAddReceiveAddressController

- (id)init{
    self = [super init];
    if (self) {
        self.navigationItem.titleView = [Utility navTitleView:@"创建收货地址"];
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [Utility navLeftBackBtn:self action:@selector(back)];
    dic = [[NSMutableDictionary alloc]init];
    [self initViews];
}


#pragma mark - Views

- (CGFloat )tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 45;
}

- (void)initViews{
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth,CONTENT_HEIGHT) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    
}


#pragma mark - TableViewdelegate

- (NSInteger )tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 3;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *indentify = [NSString stringWithFormat:@"cell%d%d",(int)indexPath.section,(int)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    //    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indentify];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indentify];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //底部线
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 44 - 0.5f, kScreenWidth, 0.5f)];
    line.backgroundColor = THEME_COLOR_LINE;
    [cell.contentView addSubview:line];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //编辑框
    UITextField *texfield = [[UITextField alloc]initWithFrame:CGRectMake(100, 0, 200, 45)];
    texfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    texfield.delegate = self;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"收货人姓名";
        _userNameTF = texfield;
        _userNameTF.text = [dic objectForKey:@"name"];
        
    }
    if (indexPath.row == 1) {
        cell.textLabel.text = @"手机号码";
        
        _userNumTF = texfield;
        _userNumTF.text = [dic objectForKey:@"num"];
        
        
    }
    if (indexPath.row == 2) {
        
        cell.textLabel.text = @"省市区";
        BasePickView *picker = [[BasePickView alloc] init];
        picker.showsSelectionIndicator = YES;
        picker.addressdelegate = self;
        texfield.inputView = picker;
        _userAddTF = texfield;
        _userAddTF.text = [dic objectForKey:@"address"];
        _userAddTF.textAlignment = NSTextAlignmentLeft;
        
        
        
    }
    [cell.contentView addSubview:texfield];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.textColor = [UIColor colorWithRed:kCellTextColor green:kCellTextColor blue:kCellTextColor alpha:1];
    cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
    
    return cell;
    
}

#pragma mark -- AddressDelegate

- (void)sentAddress:(NSString *)address{
    _userAddTF.text = address;
    _textView.text = [NSString stringWithFormat:@"%@",[address trimString]];
}
//头视图高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 1;
}
//尾视图高度

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 300;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 200)];
    UIView *leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 100)];
    leftView.backgroundColor = [UIColor whiteColor];
    [view addSubview:leftView];
    
    _textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 0, kScreenWidth - 10, 100)];
    _textView.contentMode = UIViewContentModeTopLeft;
    _textView.text = @"详细地址";
    _textView.font = [UIFont systemFontOfSize:15.0f];
    _textView.textColor = [UIColor blackColor];
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.delegate = self;
    [view addSubview:_textView];
    //创建按钮
    UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
    button.frame = CGRectMake(15, _textView.bottom + 20,kScreenWidth - 30,45);
    [button setTitle:@"创建" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(createAction) forControlEvents:UIControlEventTouchUpInside];
    [button setButtonOrangeStyle];
    [view addSubview:button];
    
    
    return view;
    
}

#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == _userNameTF) {
        [_userNumTF becomeFirstResponder];
    }else if (textField == _userNumTF){
        
        [_userAddTF becomeFirstResponder];
        
    }else if (textField == _userAddTF){
        [_textView becomeFirstResponder];
        
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField == _userNumTF)
    {
        NSMutableString *text = [textField.text mutableCopy];
        [text replaceCharactersInRange:range withString:string];
        
        if (text.length > 11 && range.length == 0)
        {
            return NO;
        }
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
    if (textField.text != 0)
    {
        if (textField == _userNameTF)
        {
            
            [dic setObject:textField.text forKey:@"name"];
        }
        if (textField == _userNumTF )
        {
            [dic setObject:textField.text forKey:@"num"];
            
        }
        if(textField == _userAddTF)
        {
            
            [dic setObject:textField.text forKey:@"address"];
        }
        
    }
    
    
}


- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == _userNameTF) {
        
        [MobClick event:@"click_shouhuorenxingming"];
    }
    if (textField == _userNumTF) {
        [MobClick event:@"click_shoujihaoma"];
        
    }else{
        [MobClick event:@"click_shengshiqu"];
        
    }
    
}


#pragma mark textViewDelegate



- (void)textViewDidBeginEditing:(UITextView *)textView{
    [MobClick event:@"click_xiangxidizhi"];
    if ([textView.text isEqualToString:@"详细地址"]) {
        textView.text = [_userAddTF.text trimString];
        
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.contentOffset = CGPointMake(0, 100);
        
    }];
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [_textView resignFirstResponder];
        return NO;
    }
    return YES;
}
- (void)textViewDidEndEditing:(UITextView *)textView{
    if (textView.text.length == 0) {
        textView.text = @"详细地址";
    }
    else{
        textView.text =[NSString stringWithFormat:@"%@", _textView.text];
        
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.contentOffset = CGPointMake(0, 0);
        
    }];
}




#pragma mark - scrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    [_userAddTF resignFirstResponder];
    [_userNameTF resignFirstResponder];
    [_userNumTF resignFirstResponder];
    [_textView resignFirstResponder];
    
}


#pragma mark - actions

- (void)back{
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- 保存地址
/**
 *  没有写请求参数
 */
- (void)createAction{
    
    /*接口名称：新增地址
     接口地址：hw-sq-app-web/user/addReceiveAddressByUser.do
     入参：key,mobile,name,address,province,city,area
     出参：{"status":"1","data":
     {"addressId":2069710,"userId":1030431030435,"isDefault":0,"name":"nike","province":"aa","city":"bb","area":"cc","address":"abcdeddf","mobile":"15821114540","creater":1030431030435,"createTime":1438246812676,"modifier":null,"modifyTime":null,"version":0,"disabled":0}
     
     ,"detail":"请求数据成功!","key":"788f4790-b3af-48ff-8e42-f60e30a5714e"}*/
    
    NSString *name = [_userNameTF.text trimString];
    NSString *num = [_userNumTF.text trimString];
    NSString *address = [_textView.text trimString];
    
    /**
     *  省，市，区
     */
    NSString *separated = @" ";
    NSString *city = @"";
    NSString *province = @"";
    NSString *area = @"";
    NSString *splitString = [_userAddTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 区
    NSRange range = [splitString rangeOfString:separated options:NSBackwardsSearch];
    if (range.length) {
        area = [splitString substringFromIndex:range.location + 1];
    }
    
    
    // 市
    if (range.length) {
        splitString = [splitString substringToIndex:range.location-1];
        range = [splitString rangeOfString:separated options:NSBackwardsSearch];

        city = splitString;
        if (range.length) {
            city = [splitString substringFromIndex:range.location + 1];
        }
    }
    
    
    
    // 省
    if (range.length) {
        splitString = [splitString substringToIndex:range.location-1];
        splitString = city;
        if (range.length) {
            range = [splitString rangeOfString:separated options:NSBackwardsSearch];
            province = [splitString substringFromIndex:range.location + 1];
        }
    }
        
    
    
    BOOL ret = [Utility validateMobile:num];
    if ([name length]==0)
    {
        [Utility showToastWithMessage:@"姓名不能为空" inView:self.view];
        return;
    }
    if (!ret) {
        
        [Utility showToastWithMessage:@"请输入正确的电话" inView:self.view];
        return;
    }
    if ([address isEqualToString:@"详细地址"])
    {
        [Utility showToastWithMessage:@"详细地址不能为空" inView:self.view];
        return;
    }
    [Utility showMBProgress:self.view message:@"提交中"];
    
    HWHTTPRequestOperationManager *manage = [HWHTTPRequestOperationManager manager];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    /**
     *  入参：key,mobile,name,address,province,city,area
     *  province 省,city 市, area区
     *
     */
    
    [dict setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [dict setPObject:name forKey:@"name"];
    [dict setPObject:num forKey:@"mobile"];
    [dict setPObject:address forKey:@"address"];
    [dict setPObject:province forKey:@"province"];
    [dict setPObject:city forKey:@"city"];
    [dict setPObject:area forKey:@"area"];
    
    [manage POST:kTianTianTuanAddReceiveAddressByUser
      parameters:dict queue:nil success:^(id responseObject) {
        NSLog(@"保存成功");
        
        [Utility hideMBProgress:self.view];
        
        AppDelegate *del =(AppDelegate *)[UIApplication sharedApplication].delegate;
        [Utility showToastWithMessage:@"提交成功" inView:del.window];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"refresh" object:nil];
        NSDictionary *dataDic = [responseObject objectForKey:@"data"];
        //add by gusheng
        HWAddressInfo *addressModel = [[HWAddressInfo alloc]init];
        addressModel.address = [dataDic stringObjectForKey:@"address"];
        addressModel.name = [dataDic stringObjectForKey:@"name"];
        //地址Id
        addressModel.addressId = [dataDic stringObjectForKey:@"id"];
        addressModel.mobile = [dataDic stringObjectForKey:@"mobile"];
        addressModel.userId = [dataDic stringObjectForKey:@"userId"];
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSString *code, NSString *error) {
        NSLog(@"error %@",error);
        [Utility hideMBProgress:self.view];
        [Utility showToastWithMessage:error inView:self.view];
        
    }];
    
    
}


@end
