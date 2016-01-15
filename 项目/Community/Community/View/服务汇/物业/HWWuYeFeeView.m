//
//  HWWuYeFeeView.m
//  Community
//
//  Created by niedi on 15/6/11.
//  Copyright (c) 2015年 caijingpeng. All rights reserved.
//

#import "HWWuYeFeeView.h"
#import "HWWuYeFeeCell.h"
#import "HWPayConfirmVC.h"
#import "HWPayConfirmModel.h"

@interface HWWuYeFeeView ()
{
    NSInteger _selectedRow;
    
    NSMutableArray *monthBtnArr;
    NSInteger _monthBtnIndex;
    
    NSString *totalMoneyStr;
    NSString *toDateTimeStr;
    NSDate *toDate;
    
    DView *_tableFootView;
    
    NSString *_orderId;
    NSString *_token;
}
@end

@implementation HWWuYeFeeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _selectedRow = -1;
        
        [self queryListData];
    }
    return self;
}

- (void)queryListData
{
    /*URL:/hw-sq-app-web/wyJF/propertyList.do
     入参：
     key
     villageId
     
     出参：
     /业主名字/
     private String name;
     /楼栋/
     private String building;
     /房号/
     private String room;
     /物业费/
     private Double property;
     /当前缴纳日期/
     private Date sDate;
     /状态 --已拖欠 1 /
    private String type;
    /优惠信息/
    private String message;*/
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];//
    [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KWuYeFeeInfo parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"responese ========================= %@",responese);
         isLastPage = YES;
         
         if (self.currentPage == 0)
         {
             [self.baseListArr removeAllObjects];
         }
         
         NSArray *arr = [[responese dictionaryObjectForKey:@"data"] arrayObjectForKey:@"content"];
         
         for (int i = 0; i < arr.count; i ++)
         {
             HWWuYeFeeModel *model = [[HWWuYeFeeModel alloc] initWithDict:[arr pObjectAtIndex:i]];
             [self.baseListArr addObject:model];
         }
         
         if (self.baseListArr.count > 0)
         {
             [self hideEmptyView];
             _selectedRow = -1;
             [self loadUIForRow:_selectedRow];
         }
         else
         {
             [_tableFootView removeFromSuperview];
             _tableFootView = nil;
             _tableFootView = [DView viewFrameX:0 y:0 w:kScreenWidth h:320.0f];
             [self showEmptyView:@"您还未添加住房，请于右上角添加"];
         }
         
         [self.baseTable reloadData];
         [self doneLoadingTableViewData];
     } failure:^(NSString *code, NSString *error) {
         [self doneLoadingTableViewData];
         [Utility showToastWithMessage:error inView:self];
     }];
}

- (void)loadUIForRow:(NSInteger)row
{
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:row];
    
    [_tableFootView removeFromSuperview];
    _tableFootView = nil;
    _tableFootView = [DView viewFrameX:0 y:0 w:kScreenWidth h:320.0f];
    
    DLable *titleLab = [DLable LabTxt:@"选择缴纳周期" txtFont:TF15 txtColor:THEME_COLOR_SMOKE frameX:15 y:10 w:kScreenWidth - 2 * 15 h:18.0f];
    [_tableFootView addSubview:titleLab];
    
    CGFloat btnHigh = 0;
    CGFloat rate = (kScreenWidth - 2 * 15) / (320 - 2 * 15);
    if (model.monthArr.count <= 4)
    {
        btnHigh = 35 * rate;
    }
    else
    {
        btnHigh = 35 * rate * 2 + 10;
    }
    
    DImageV *monthSelBackImgV;
    if (model.messageStr.length != 0)
    {
        monthSelBackImgV = [DImageV imagV:@"bg_16_08" frameX:0 y:CGRectGetMaxY(titleLab.frame) w:kScreenWidth h:75.0f + btnHigh];
    }
    else
    {
        monthSelBackImgV = [DImageV imagV:@"bg_16_08" frameX:0 y:CGRectGetMaxY(titleLab.frame) w:kScreenWidth h:35.0f + btnHigh];
    }
    monthSelBackImgV.userInteractionEnabled = YES;
    [_tableFootView addSubview:monthSelBackImgV];
    
    monthBtnArr = [NSMutableArray array];
    NSMutableArray *titleArr = [NSMutableArray array];
    for (NSString *btnTitle in model.monthArr)
    {
        if ([btnTitle isEqualToString:@"1"])
        {
            [titleArr addObject:@"一个月"];
        }
        else if ([btnTitle isEqualToString:@"2"])
        {
            [titleArr addObject:@"两个月"];
        }
        else if ([btnTitle isEqualToString:@"3"])
        {
            [titleArr addObject:@"三个月"];
        }
        else if ([btnTitle isEqualToString:@"4"])
        {
            [titleArr addObject:@"四个月"];
        }
        else if ([btnTitle isEqualToString:@"5"])
        {
            [titleArr addObject:@"五个月"];
        }
        else if ([btnTitle isEqualToString:@"6"])
        {
            [titleArr addObject:@"六个月"];
        }
        else if ([btnTitle isEqualToString:@"7"])
        {
            [titleArr addObject:@"七个月"];
        }
        else if ([btnTitle isEqualToString:@"8"])
        {
            [titleArr addObject:@"八个月"];
        }
        else if ([btnTitle isEqualToString:@"9"])
        {
            [titleArr addObject:@"九个月"];
        }
        else if ([btnTitle isEqualToString:@"10"])
        {
            [titleArr addObject:@"十个月"];
        }
        else if ([btnTitle isEqualToString:@"11"])
        {
            [titleArr addObject:@"十一个月"];
        }
        else if ([btnTitle isEqualToString:@"12"])
        {
            [titleArr addObject:@"一年"];
        }
        else if ([btnTitle isEqualToString:@"18"])
        {
            [titleArr addObject:@"一年半"];
        }
        else if ([btnTitle isEqualToString:@"24"])
        {
            [titleArr addObject:@"两年"];
        }
        else if ([btnTitle isEqualToString:@"30"])
        {
            [titleArr addObject:@"两年半"];
        }
        else if ([btnTitle isEqualToString:@"36"])
        {
            [titleArr addObject:@"三年"];
        }
        else if ([btnTitle isEqualToString:@"42"])
        {
            [titleArr addObject:@"三年半"];
        }
        else if ([btnTitle isEqualToString:@"48"])
        {
            [titleArr addObject:@"四年"];
        }
        else if ([btnTitle isEqualToString:@"54"])
        {
            [titleArr addObject:@"四年半"];
        }
        else if ([btnTitle isEqualToString:@"60"])
        {
            [titleArr addObject:@"五年"];
        }
    }
    
    DButton *timeBtn;
    for (int i = 0; i < titleArr.count; i++)
    {
        timeBtn = [DButton btnTxt:titleArr[i] txtFont:TF16 frameX:15 + (67 + 7) * (i % 4) *rate y:20 + (i / 4) * (35 * rate + 10) w:67 * rate h:35 * rate target:self action:@selector(timeBtnClick:)];
        [timeBtn setRadius:3.5f];
        [timeBtn cancleHighlighted];
        timeBtn.layer.borderWidth = 0.5f;
        timeBtn.layer.borderColor = THEME_COLOR_LINE.CGColor;
        [timeBtn setTitleColor:THEME_COLOR_GRAY_MIDDLE forState:UIControlStateNormal];
        [timeBtn setBackgroundImage:[Utility imageWithColor:BACKGROUND_COLOR andSize:timeBtn.frame.size] forState:UIControlStateNormal];
        [timeBtn setTitleColor:THEME_COLOR_ORANGE forState:UIControlStateSelected];
        [timeBtn setBackgroundImage:[Utility imageWithColor:THEME_COLOR_ORANGE_light andSize:timeBtn.frame.size] forState:UIControlStateSelected];
        [monthSelBackImgV addSubview:timeBtn];
        [monthBtnArr addObject:timeBtn];
        
        if (i == _monthBtnIndex)
        {
            [self performSelector:@selector(timeBtnClick:) withObject:timeBtn];
        }
    }
    
    DImageV *middleLine;
    if (model.messageStr.length != 0)
    {
        middleLine = [DImageV imagV:nil frameX:15 y:CGRectGetMaxY(timeBtn.frame) + 15 w:kScreenWidth - 15 h:0.5f];
        middleLine.backgroundColor = THEME_COLOR_LINE;
        [monthSelBackImgV addSubview:middleLine];
        
//        NSInteger monthNum = [[model.monthArr objectAtIndex:_monthBtnIndex] integerValue];
        if (NO)//monthNum > 11
        {
            DImageV *awardIcon = [DImageV imagV:@"icon_16_05" frameX:15 y:CGRectGetMaxY(middleLine.frame) + 10 w:15 h:15];
            [monthSelBackImgV addSubview:awardIcon];
            
            DLable *awardLab = [DLable LabTxt:model.messageStr txtFont:TF15 txtColor:THEME_COLOR_ORANGE frameX:CGRectGetMaxX(awardIcon.frame) + 5 y:CGRectGetMinY(awardIcon.frame) - 2 w:kScreenWidth - (CGRectGetMaxX(awardIcon.frame) + 5) - 5 h:19];
            awardLab.numberOfLines = 2;
            [monthSelBackImgV addSubview:awardLab];
        }
        else
        {
            DImageV *awardIcon = [DImageV imagV:@"icon_16_04" frameX:15 y:CGRectGetMaxY(middleLine.frame) + 10 w:15 h:15];
            [monthSelBackImgV addSubview:awardIcon];
            
            CGFloat height = [Utility calculateStringHeight:model.messageStr font:FONT(15) constrainedSize:CGSizeMake(kScreenWidth - (CGRectGetMaxX(awardIcon.frame) + 5) - 5, 10000)].height;
            if (height > 35)
            {
                height = 35;
            }
            
            DLable *awardLab = [DLable LabTxt:model.messageStr txtFont:TF15 txtColor:THEME_COLOR_TEXT frameX:CGRectGetMaxX(awardIcon.frame) + 5 y:CGRectGetMinY(awardIcon.frame) - 2 w:kScreenWidth - (CGRectGetMaxX(awardIcon.frame) + 5) - 5 h:height];
            awardLab.numberOfLines = 2;
            [monthSelBackImgV addSubview:awardLab];
            
            CGRect frame;
            frame = monthSelBackImgV.frame;
            frame.size.height = CGRectGetMaxY(awardLab.frame) + 10;
            monthSelBackImgV.frame = frame;
        }
    }
    
    DLable *totalLab = [DLable LabTxt:@"    总计" txtFont:TF16 txtColor:THEME_COLOR_SMOKE frameX:0 y:CGRectGetMaxY(monthSelBackImgV.frame) + 10.0f w:kScreenWidth h:45.0f];
    totalLab.backgroundColor = THEME_COLOR_White;
    [_tableFootView addSubview:totalLab];
    
    DLable *toDateLab = [DLable LabTxt:@"    缴纳至" txtFont:TF16 txtColor:THEME_COLOR_SMOKE frameX:0 y:CGRectGetMaxY(totalLab.frame) w:kScreenWidth h:45.0f];
    toDateLab.backgroundColor = THEME_COLOR_White;
    [_tableFootView addSubview:toDateLab];
    
    DLable *totalMoneyLab = [DLable LabTxt:totalMoneyStr txtFont:TF16 txtColor:THEME_COLOR_MONEY frameX:kScreenWidth - 15 - 200 y:CGRectGetMaxY(monthSelBackImgV.frame) + 10.0f w:200 h:45.0f];
    totalMoneyLab.textAlignment = NSTextAlignmentRight;
    [_tableFootView addSubview:totalMoneyLab];
    
    DLable *toDateTimeLab = [DLable LabTxt:toDateTimeStr txtFont:TF15 txtColor:THEME_COLOR_TEXT frameX:kScreenWidth - 15 - 200 y:CGRectGetMaxY(totalLab.frame) w:200 h:45.0f];
    toDateTimeLab.textAlignment = NSTextAlignmentRight;
    [_tableFootView addSubview:toDateTimeLab];
    
    for (int i = 0; i < 3; i++)
    {
        DImageV *line = [DImageV imagV:nil frameX:0 y:totalLab.frame.origin.y + 45.0f * i w:kScreenWidth h:0.5f];
        line.backgroundColor = THEME_COLOR_LINE;
        [_tableFootView addSubview:line];
    }
    
    DButton *payBtn = [DButton btnTxt:@"缴费" txtFont:TF18 frameX:15 y:CGRectGetMaxY(toDateLab.frame) + 20 w:kScreenWidth - 2 * 15 h:45 target:self action:@selector(payBtnClick)];
    [payBtn setStyle:DBtnStyleMain];
    [payBtn setRadius:3.5f];
    [_tableFootView addSubview:payBtn];
    
    CGRect frame = _tableFootView.frame;
    frame.size.height = CGRectGetMaxY(payBtn.frame) + 10;
    _tableFootView.frame = frame;
    
    self.baseTable.tableFooterView = _tableFootView;
}

- (void)payBtnClick
{
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:_selectedRow];
    
    HWPayConfirmVC *pvc = [[HWPayConfirmVC alloc] init];
    HWPayConfirmModel *payModel = [[HWPayConfirmModel alloc] init];
    payModel.title0 = @"物业费收取";
    NSString *roomStr = @"";
    if (model.unitNoStr.length != 0)
    {
        roomStr = [NSString stringWithFormat:@"%@号楼%@单元%@室", model.buildingStr, model.unitNoStr, model.roomStr];
    }
    else
    {
        roomStr = [NSString stringWithFormat:@"%@号楼%@室", model.buildingStr, model.roomStr];
    }
    payModel.title1 = roomStr;
    payModel.title2 = model.nameStr;
    payModel.title3 = [NSString stringWithFormat:@"%@元/月", model.propertyStr];
    payModel.title4 = [self getDateStr:toDate];
    long long time = [model.sDateStr longLongValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    payModel.sDateStr = [self getDateStr:date];
    payModel.toDateStr = [self getDateStr:toDate];
    NSString *totalMoney = [NSString stringWithFormat:@"%.2f", model.propertyStr.doubleValue * [[model.monthArr pObjectAtIndex:_monthBtnIndex] integerValue]];
    payModel.allPayStr = totalMoney;
    payModel.wyModel = model;
    pvc.model = payModel;
    pvc.type = HWPayConfirmTypeWeYeForWyPush;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pushViewController:)])
    {
        [self.delegate pushViewController:pvc];
    }
}

- (NSString *)getDateStr:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    return dateStr;
}

- (void)timeBtnClick:(DButton *)btn
{
    for (UIButton *tmpBtn in monthBtnArr)
    {
        tmpBtn.selected = NO;
        tmpBtn.layer.borderColor = THEME_COLOR_LINE.CGColor;
    }
    
    if (!btn.selected)
    {
        btn.selected = YES;
        btn.layer.borderColor = THEME_COLOR_ORANGE_HIGHLIGHT.CGColor;
    }
    else
    {
        btn.selected = NO;
        btn.layer.borderColor = THEME_COLOR_LINE.CGColor;
    }
    
    NSInteger currentIndex = [monthBtnArr indexOfObject:btn];
    if (currentIndex != _monthBtnIndex)
    {
        _monthBtnIndex = currentIndex;
        [self resetTotalMoneyAndDateWithRow:_selectedRow btnIndex:_monthBtnIndex];
    }
}

- (void)resetTotalMoneyAndDateWithRow:(NSInteger)selectRow btnIndex:(NSInteger)btnIndex
{
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:selectRow];
    NSInteger monthNum = [[model.monthArr pObjectAtIndex:btnIndex] integerValue];
    totalMoneyStr = [NSString stringWithFormat:@"%.2f元", model.propertyStr.doubleValue * monthNum];
    
    NSCalendar *initCalendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    long long time = [model.sDateStr longLongValue] / 1000;
    NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth: monthNum];
    toDate = [initCalendar dateByAddingComponents:comps toDate:currentDate options:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年MM月dd日"];
    NSString *strDate = [formatter stringFromDate:toDate];
    toDateTimeStr = strDate;
    
    [self loadUIForRow:selectRow];
}

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.baseListArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = @"cellId";
    HWWuYeFeeCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell = [[HWWuYeFeeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:indexPath.row];
    [cell fillDataWithModel:model];
    
    if (_selectedRow == -1)
    {
        _selectedRow = 0;
        _monthBtnIndex = 0;
        [cell cellSelect:YES];
        [self resetTotalMoneyAndDateWithRow:_selectedRow btnIndex:_monthBtnIndex];
    }
    
    if (indexPath.row == _selectedRow)
    {
        [cell cellSelect:YES];
    }
    else
    {
        [cell cellSelect:NO];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:indexPath.row];
    return [HWWuYeFeeCell getCellHeight:model];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedRow != indexPath.row)
    {
        _selectedRow = indexPath.row;
        [self.baseTable reloadData];
        [self resetTotalMoneyAndDateWithRow:_selectedRow btnIndex:_monthBtnIndex];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:indexPath.row];
    if ([model.WyHouseId isEqualToString:@"-1"])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self deleteHouseCommitQuery:indexPath.row];
}

- (void)deleteHouseCommitQuery:(NSInteger)row
{
    /*URL:/hw-sq-app-web/wyJF/deleteHouse.do
     入参：
     key
     villageId 小区Id
     WyHouseId 物业房屋Id
     出参*/
    
    HWWuYeFeeModel *model = [self.baseListArr pObjectAtIndex:row];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    [param setPObject:[HWUserLogin currentUserLogin].key forKey:@"key"];
    [param setPObject:[HWUserLogin currentUserLogin].villageId forKey:@"villageId"];
    [param setPObject:model.houseId forKey:@"WyHouseId"];
    
    HWHTTPRequestOperationManager *manager = [HWHTTPRequestOperationManager manager];
    [manager POST:KWuYeDeleteHouse parameters:param queue:nil success:^(id responese)
     {
         NSLog(@"responese 删除房屋========================= %@",responese);
         [Utility showToastWithMessage:@"删除成功" inView:self];
         [self queryListData];
         
     } failure:^(NSString *code, NSString *error) {
         
         [Utility showToastWithMessage:error inView:self];
     }];
}

@end
