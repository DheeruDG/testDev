//
//  RazaDatePickerView.m
//  MonthYearDatePicker
//
//  Created by Igor on 18.03.13.
//  Copyright (c) 2013 Igor. All rights reserved.
//

#import "RazaDatePickerView.h"


// Identifiers of components
#define MONTH ( 0 )
#define YEAR ( 1 )


// Identifies for component views
#define LABEL_TAG 43


@interface RazaDatePickerView()

@property (nonatomic, strong) NSIndexPath *todayIndexPath;
@property (nonatomic, strong) NSArray *months;
@property (nonatomic, strong) NSArray *years;

-(NSArray *)nameOfYears;
-(NSArray *)nameOfMonths;
-(CGFloat)componentWidth;

-(UILabel *)labelForComponent:(NSInteger)component selected:(BOOL)selected;
-(NSString *)titleForRow:(NSInteger)row forComponent:(NSInteger)component;
-(NSIndexPath *)todayPath;
-(NSInteger)bigRowMonthCount;
-(NSInteger)bigRowYearCount;
-(NSString *)currentMonthName;
-(NSString *)currentYearName;

@end



@implementation RazaDatePickerView

const NSInteger bigRowCount = 1000;
const NSInteger minYear = 2016;
const NSInteger maxYear = 2031;
const CGFloat rowHeight = 44.f;
const NSInteger numberOfComponents = 2;

@synthesize todayIndexPath;
@synthesize months;
@synthesize years = _years;

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.months = [self nameOfMonths];
    self.years = [self nameOfYears];
    self.todayIndexPath = [self todayPath];
    
    self.delegate = self;
    self.dataSource = self;
    
    [self selectToday];
    NSDictionary *dateInfo = [self dateWithMonthYear];
    _selfselectedMonth=[dateInfo objectForKey:@"month"];
    _selfselectedYear=[dateInfo objectForKey:@"year"];
}

-(NSDate *)date{
    NSDictionary *dateInfo = [self dateWithMonthYear];
    
    NSString *month = [dateInfo objectForKey:@"month"];
    NSString *year = [dateInfo objectForKey:@"year"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init]; [formatter setDateFormat:@"MMMM:yyyy"];
    NSDate *date = [formatter dateFromString:[NSString stringWithFormat:@"%@:%@", month, year]];
    return date;
}

-(NSDictionary *)dateWithMonthYear {
    NSArray *keyArray = @[@"month",@"year"];
    NSInteger monthCount = [self.months count];
    NSString *month = [self.months objectAtIndex:([self selectedRowInComponent:MONTH] % monthCount)];
    
    NSInteger yearCount = [self.years count];
    NSString *year = [self.years objectAtIndex:([self selectedRowInComponent:YEAR] % yearCount)];
    
    NSArray *valueArray = @[month, year];
    
    NSDictionary *dateInfo = [NSDictionary dictionaryWithObjects:valueArray forKeys:keyArray];
    
    return dateInfo;
}

#pragma mark - UIPickerViewDelegate
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return [self componentWidth];
}

-(UIView *)pickerView: (UIPickerView *)pickerView
           viewForRow: (NSInteger)row
         forComponent: (NSInteger)component
          reusingView: (UIView *)view
{
    BOOL selected = NO;
    if(component == MONTH){
        NSInteger monthCount = [self.months count];
        NSString *monthName = [self.months objectAtIndex:(row % monthCount)];
        NSString *currentMonthName = [self currentMonthName];
        if([monthName isEqualToString:currentMonthName] == YES){
            selected = YES;
        }
    }
    else{
        NSInteger yearCount = [self.years count];
        NSString *yearName = [self.years objectAtIndex:(row % yearCount)];
        NSString *currenrYearName  = [self currentYearName];
        if([yearName isEqualToString:currenrYearName] == YES){
            selected = YES;
        }
    }
    
    UILabel *returnView = nil;
    if(view.tag == LABEL_TAG){
        returnView = (UILabel *)view;
    }else{
        returnView = [self labelForComponent: component selected: selected];
    }
    
    returnView.textColor = selected ? [UIColor blueColor] : [UIColor blackColor];
    returnView.text = [self titleForRow:row forComponent:component];
    return returnView;
}


-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    
    return rowHeight;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return numberOfComponents;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(component == MONTH)
    {
        return [self bigRowMonthCount];
    }
    return [self bigRowYearCount];
}

#pragma mark - Util
-(NSInteger)bigRowMonthCount{
    return [self.months count]  * bigRowCount;
}

-(NSInteger)bigRowYearCount{
    return [self.years count]  * bigRowCount;
}

-(CGFloat)componentWidth{
    return self.bounds.size.width / numberOfComponents;
}

-(NSString *)titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(component == MONTH)
    {
        NSInteger monthCount = [self.months count];
        return [self.months objectAtIndex:(row % monthCount)];
    }
    NSInteger yearCount = [self.years count];
    return [self.years objectAtIndex:(row % yearCount)];
}

-(UILabel *)labelForComponent:(NSInteger)component selected:(BOOL)selected
{
    CGRect frame = CGRectMake(0.f, 0.f, [self componentWidth],rowHeight);
    
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = selected ? [UIColor blueColor] : [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:18.f];
    label.userInteractionEnabled = NO;
    
    label.tag = LABEL_TAG;
    
    return label;
}

-(NSArray *)nameOfMonths{
    return @[@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"];
}

-(NSArray *)nameOfYears
{
    NSMutableArray *years = [NSMutableArray array];
    
    for(NSInteger year = minYear; year <= maxYear; year++)
    {
        NSString *yearStr = [NSString stringWithFormat:@"%li", (long)year];
        [years addObject:yearStr];
    }
    return years;
}

-(void)selectToday
{
    [self selectRow: self.todayIndexPath.row
        inComponent: MONTH
           animated: NO];
    
    [self selectRow: self.todayIndexPath.section
        inComponent: YEAR
           animated: NO];
}

-(NSIndexPath *)todayPath // row - month ; section - year
{
    CGFloat row = 0.f;
    CGFloat section = 0.f;
    
    NSString *month = [self currentMonthName];
    NSString *year  = [self currentYearName];
    
    //set table on the middle
    for(NSString *cellMonth in self.months)
    {
        if([cellMonth isEqualToString:month])
        {
            row = [self.months indexOfObject:cellMonth];
            row = row + [self bigRowMonthCount] / 2;
            break;
        }
    }
    
    for(NSString *cellYear in self.years)
    {
        if([cellYear isEqualToString:year])
        {
            section = [self.years indexOfObject:cellYear];
            section = section + [self bigRowYearCount] / 2;
            break;
        }
    }
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}

-(NSString *)currentMonthName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setLocale:usLocale];
    [formatter setDateFormat:@"MMMM"];
    return [formatter stringFromDate:[NSDate date]];
}

-(NSString *)currentYearName
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    return [formatter stringFromDate:[NSDate date]];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    NSDictionary *dateInfo = [self dateWithMonthYear];
    self.selectedMonth = [dateInfo objectForKey:@"month"];
    self.selectedYear = [dateInfo objectForKey:@"year"];
    
}

@end