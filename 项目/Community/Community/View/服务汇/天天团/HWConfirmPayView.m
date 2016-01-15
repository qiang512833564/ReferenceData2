//
//  HWConfirmPayView.m
//  Community
//
//  Created by hw500029 on 15/8/5.
//  Copyright (c) 2015年 caijingpeng. All rights reserved.
//

#import "HWConfirmPayView.h"
#import "HWConfirmPayCell1.h"
#import "HWConfirmPayCell2.h"

@implementation HWConfirmPayView

- (instancetype)initWithFrame:(CGRect)frame andOrderId:(NSString *)orderId
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _titleArray = @[@"订单信息",@"支付方式",@"填写备注信息"];
        _orderId = orderId;
        [self setFooterView];
        [self queryListData];
        
        //监听键盘高度
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moveUp:) name:UITextViewTextDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDown:) name:UITextViewTextDidEndEditingNotification object:nil];
    }
    return self;
}

- (void)queryListData
{
    /*接口名称：
     http://localhost:8080/hw-sq-app-web/grpBuyOrder/queryOrder.do?orderId=1&key=a79dbe5c-bf01-4c47-b4ac-ed9ca9c6b1d0
     
     输入参数：
     orderId 订单ID
     key 用户key
     
     输出参数：
     orderId 订单ID
     orderCode 订单号
     orderAmount 订单金额
     orderStatus 订单状态
     orderCreateTime 订单创建时间
     serverTime 服务器时间
     releaseWarehouseTime 自动释放库存时间(分钟)
     goodsId 商品ID
     goodsName 商品名称
     goodsCount 商品数量
     name 收货人姓名
     mobile 收货人电话
     address 收货人地址
     
     成功：
     {
     status: "1",
     data:
     { orderId: 1, orderCode: "123", orderAmount: 34, orderStatus: "已发货", orderCreateTime: 1438220883000, serverTime: 1438587685000, releaseWarehouseTime: 30, goodsId: 10349274824, goodsName: "红苹果", goodsCount: "1", name: "陈勇", mobile: "18221398089", address: "上海市宝山区呼兰路呼玛三村" }
     
     ,
     detail: "请求数据成功!",
     key: "a79dbe5c-bf01-4c47-b4ac-ed9ca9c6b1d0"
     }
     
     失败：
     {
     status: "0",
     data: "",
     detail: "订单不存在",
     key: "a79dbe5c-bf01-4c47-b4ac-ed9ca9c6b1d0"
     }
     
     {
     status: "0",
     data: "",
     detail: "查询订单出错",
     key: "a79dbe5c-bf01-4c47-b4ac-ed9ca9c6b1d0"
     }*/
    
    isLastPage = YES;//不支持上拉刷新
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [dictionary setPObject:_orderId forKey:@"orderId"];
    
    [manager POST:kTianTianTuanQueryOrder parameters:dictionary queue:nil success:^(id responese) {
        
        [self doneLoadingTableViewData];
        [self hideEmptyView];
        
        _model = [[HWConfirmOrderModel alloc] initWithdictionary:responese];
        _addressInfo = [[HWAddressInfo alloc] initWithDictionary:[responese dictionaryObjectForKey:@"data"]];
        
        [self.baseTable reloadData];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(startTimer)])
        {
            //重新加载倒计时
            [self.delegate startTimer];
        }
        
    } failure:^(NSString *code, NSString *error) {
        [self doneLoadingTableViewData];
        [self showEmptyView:@"加载失败"];
        [Utility showToastWithMessage:error inView:self];
    }];
}

- (void)setFooterView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 80)];
    view.backgroundColor = [UIColor clearColor];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(10, (80 - 45)/2, self.bounds.size.width - 20, 45)];
    btn.layer.cornerRadius = 5;
    btn.layer.masksToBounds = YES;
    [btn setTitle:@"确认支付" forState:UIControlStateNormal];
    btn.backgroundColor = THEME_COLOR_ORANGE;
    btn.titleLabel.font = FONT(TF18);
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(confirmPayMentAciton) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
    
    self.baseTable.tableFooterView = view;
}

#pragma mark-------确认支付
- (void)confirmPayMentAciton
{
    /*接口URL:http://localhost:8080/hw-sq-app-web/grpBuyOrder/confirmPay.do
     请求参数:
     orderId:订单id
     name:收货人姓名
     mobile:收货人电话
     address:收货人地址
     remark:备注
     成功返回:data里面的数据就是支付宝支付需要的参数
     { "status": "1", "data": "it_b_pay=\"50m\"&notify_url=\"http%3A%2F%2F101.231.83.157%3A8080%2Fhw-pay-web%2Fpayment%2FalipayNotifyResult.do\"&service=\"mobile.securitypay.pay\"&seller_id=\"yunying@haowu.com\"&partner=\"2088711528440514\"&payment_type=\"1\"&out_trade_no=\"122122\"&subject=\"天天团订单支付\"&body=\"天天团订单支付\"&total_fee=\"77.0\"&sign=\"GCPdZIm1fNA05KhS9c6Ihe4aCE%2FFkmksW1%2Fp%2FnriTkUInFW3k4PD6S%2BQfrFS%2F9nzkT7XG5cBQw59MDuEeb0kk9O2xyJ5atk2cRcf6HrnOjAVJLGSAs%2FAa3roTJ3rEoP2i%2BkNRObCiWy1Ilv6o%2Flay%2BxU7zRjSafPg6kv%2B3QbLaw%3D\"&sign_type=\"RSA\"", "detail": "请求数据成功!", "key": null } */
    
    [MobClick event:@"click_finish_pay_group"];//1.7
    
    if (_model.address.length <= 0)
    {
        [Utility showToastWithMessage:@"请添加收货地址" inView:self];
        return;
    }
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [dictionary setPObject:_model.name forKey:@"name"];
    [dictionary setPObject:_model.mobile forKey:@"mobile"];
    [dictionary setPObject:_model.address forKey:@"address"];
    [dictionary setPObject:_orderId forKey:@"orderId"];
    [dictionary setPObject:_textView.text forKey:@"remark"];
    
    [manager POST:kTianTianTuanConfirmPayment parameters:dictionary queue:nil success:^(id responese) {
        
        NSLog(@"支付信息请求成功:%@", responese);
        
        NSString *payUrl = [responese stringObjectForKey:@"data"];
        [self payForALiSDK:payUrl];
        
    } failure:^(NSString *code, NSString *error) {
        [Utility showToastWithMessage:error inView:self];
    }];
}

- (void)payForALiSDK:(NSString *)payUrl
{
    NSString *appScheme = @"AlixPay";
    // 支付
    [[AlipaySDK defaultService] payOrder:payUrl fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        
        NSLog(@"%@",resultDic);
        //支付后的回调
        NSString *resultStatus = [resultDic stringObjectForKey:@"resultStatus"];
        if ([resultStatus isEqualToString:@"9000"])
        {
            [Utility showToastWithMessage:@"支付成功" inView:self];
            if (self.delegate && [self.delegate respondsToSelector:@selector(pushToPaySuccessVC:)])
            {
                [self.delegate pushToPaySuccessVC:_orderId];
            }
        }
        else
        {
            [Utility showToastWithMessage:@"支付失败" inView:self];
        }
    }];
}

#pragma mark ----- UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    }
    
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0) {
            return 96;
        }
        return 64;
    }
    
    return 78;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 30)];
    backView.backgroundColor = THEME_COLOR_TEXTBACKGROUND;
    
    UILabel *textLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 100,30)];
    textLabel.textColor = THEME_COLOR_TEXT;
    textLabel.font = FONT(15);
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.text = [_titleArray pObjectAtIndex:section];
    [backView addSubview:textLabel];
    return backView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0)
    {
        NSString *cellid1 = @"cellid1";
        NSString *cellid2 = @"cellid2";
        if (indexPath.row == 0)
        {
            HWConfirmPayCell1 *cell = [[HWConfirmPayCell1 alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid1];
            [cell fillDataWithInfo:_addressInfo];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [Utility topLine:cell.contentView];
            return cell;
        }
        else
        {
            HWConfirmPayCell2 *cell = [[HWConfirmPayCell2 alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid2];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            NSString *goodsInfoStr = [NSString stringWithFormat:@"%@x%@",_model.goodsName,_model.goodsCount];
            [cell fillDataWithCargoName:goodsInfoStr andPrice:_model.orderAmount];
            [Utility bottomLine:cell.contentView];
            return cell;
        }
    }
    else if (indexPath.section == 1)
    {
        NSString *cellid3 = @"cellid3";
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid3];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView *selectImgV = [[UIImageView alloc]initWithFrame:CGRectMake(18, 29, 20, 20)];
        selectImgV.image = [UIImage imageNamed:@"支付选择"];
        [cell.contentView addSubview:selectImgV];
        
        UIImageView *bigImgV = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(selectImgV.frame) + 5, (78 - 49/2)/2, 155/2, 49/2)];
        bigImgV.image = [UIImage imageNamed:@"支付宝"];
        [cell.contentView addSubview:bigImgV];

        [Utility bottomLine:cell.contentView];
        [Utility topLine:cell.contentView];
        return cell;
    }
    else
    {
        NSString *cellid4 = @"cellid4";
        
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid4];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        _textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 5, kScreenWidth - 10, 78 - 10)];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        [Utility bottomLine:cell.contentView];
        [Utility topLine:cell.contentView];
        [cell.contentView addSubview:_textView];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //选择地址
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        [MobClick event:@"click_group_logistics"];//1.7
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(pushAddressListView)])
        {
            [self.delegate pushAddressListView];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (fabs(scrollView.contentOffset.y) >= 30)
    {
        [self endEditing:YES];
    }
}

#pragma mark-----键盘出现相关操作
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [MobClick event:@"get_focus_group_remark"];//1.7
    
    [UIView animateWithDuration:0.25 animations:^{
        if (IPHONE4)
        {
            self.baseTable.frame = CGRectMake(0, -250, kScreenWidth, CONTENT_HEIGHT);
        }
        else
        {
            self.baseTable.frame = CGRectMake(0, -200, kScreenWidth, CONTENT_HEIGHT);
        }
    }completion:^(BOOL finished) {
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    
}

- (void)moveUp:(NSNotification *)not
{
    NSLog(@"not ======== %@",not);
    
        CGFloat h = [not.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height-80;
        NSLog(@"h ================ %f",h);
        [UIView animateWithDuration:0.25 animations:^{
            if (IPHONE4)
            {
                self.baseTable.frame = CGRectMake(0, -250, kScreenWidth, CONTENT_HEIGHT);
            }
            else
            {
                self.baseTable.frame = CGRectMake(0, -200, kScreenWidth, CONTENT_HEIGHT);
            }
            
        }completion:^(BOOL finished) {
        }];

    
}

- (void)moveDown:(NSNotification *)not
{
    NSLog(@"not ======== %@",not);
    
        [UIView animateWithDuration:0.25 animations:^{
            self.baseTable.frame = CGRectMake(0,0, kScreenWidth, CONTENT_HEIGHT);
        }completion:^(BOOL finished) {
        }];
    

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
}

@end
