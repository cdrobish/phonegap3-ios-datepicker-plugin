/*
	Phonegap DatePicker Plugin

	Copyright (c) Greg Allen 2011
	Additional refactoring by Sam de Freyssinet
	Rewrite by Jens Krause (www.websector.de)

	MIT Licensed
*/

#import "DatePicker.h"
#import <Cordova/CDV.h>

@interface DatePicker ()

@property (nonatomic) BOOL isVisible;
@property (nonatomic) UIActionSheet* datePickerSheet;
@property (nonatomic) UIDatePicker* datePicker;
@property (nonatomic) UIPopoverController *datePickerPopover;

@end

@implementation DatePicker

#pragma mark - UIDatePicker

- (void)show:(CDVInvokedUrlCommand*)command {
	NSMutableDictionary *options = [command argumentAtIndex:0];    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
	  [self showForPhone: options];
	} else {
	  [self showForPad: options];
	}
}

- (void)showForPhone:(NSMutableDictionary *)options {
  if(!self.isVisible){
		self.datePickerSheet = [self createActionSheet:options];
		self.isVisible = TRUE;
	}
}

- (void)showForPad:(NSMutableDictionary *)options {
  if(!self.isVisible){
    self.datePickerPopover = [self createPopover:options];
    self.isVisible = TRUE;
  }    
}

- (void)hide {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.datePickerSheet dismissWithClickedButtonIndex:0 animated:YES];
    } else {
        [self.datePickerPopover dismissPopoverAnimated:YES];
    }
}

- (void)doneAction:(id)sender {
  [self jsDateSelected];
  [self hide];
}


- (void)cancelAction:(id)sender {
	[self hide];
}


- (void)dateChangedAction:(id)sender {
	[self jsDateSelected];
}

#pragma mark - JS API

- (void)jsDateSelected {
  NSTimeInterval seconds = [self.datePicker.date timeIntervalSince1970];
  NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"%f\");", seconds];
  NSLog(@"jsDateSelected");
  [super writeJavascript:jsCallback];
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {

}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.isVisible = FALSE;
}


#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.isVisible = FALSE;   
}

#pragma mark - Factory methods

- (UIActionSheet *)createActionSheet:(NSMutableDictionary *)options {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self cancelButtonTitle:nil
                                                        destructiveButtonTitle:nil 
                                                        otherButtonTitles:nil];

	[actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
  // date picker
  CGRect frame = CGRectMake(0, 40, 0, 0);
  UIDatePicker *datePicker = [self createDatePicker: options frame:frame];
	self.datePicker = datePicker;
	[actionSheet addSubview:datePicker];
  // cancel button
	NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"];
	UISegmentedControl *cancelButton = [self createCancelButton:cancelButtonLabel];
	[actionSheet addSubview:cancelButton];
  // done button
	NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"];
	UISegmentedControl *doneButton = [self createDoneButton:doneButtonLabel];    
	[actionSheet addSubview:doneButton];
    
	[actionSheet showInView:[[super webView] superview]];
	[actionSheet setBounds:CGRectMake(0, 0, 320, 485)];

	return actionSheet;
}

- (UIPopoverController *)createPopover:(NSMutableDictionary *)options {
    
  CGFloat pickerViewWidth = 320.0f;
  CGFloat pickerViewHeight = 216.0f;
  UIView *datePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerViewWidth, pickerViewHeight)];

  CGRect frame = CGRectMake(0, 0, 0, 0);
  UIDatePicker *datePicker = [self createDatePicker:options frame:frame];
  [datePicker addTarget:self action:@selector(dateChangedAction:) forControlEvents:UIControlEventValueChanged];
	self.datePicker = datePicker;
  [datePickerView addSubview:self.datePicker];
  
  UIViewController *datePickerViewController = [[UIViewController alloc]init];
  datePickerViewController.view = datePickerView;
  
  CGFloat x = [[options objectForKey:@"x"] intValue];
  CGFloat y = [[options objectForKey:@"y"] intValue];
  CGRect anchor = CGRectMake(x, y, 1, 1);
  
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:datePickerViewController];
  popover.delegate = self;
  [popover setPopoverContentSize:CGSizeMake(pickerViewWidth, pickerViewHeight) animated:NO];
  [popover presentPopoverFromRect:anchor inView:self.webView.superview  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  
  return popover;
}

- (UIDatePicker *)createDatePicker:(NSMutableDictionary *)options frame:(CGRect)frame {
	UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:frame];
    
  NSDateFormatter *formatter = [self createISODateFormatter:k_DATEPICKER_DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];
    
  NSString *mode = [options objectForKey:@"mode"];
	NSString *dateString = [options objectForKey:@"date"];
	BOOL allowOldDates = NO;
	BOOL allowFutureDates = YES;
	NSString *minDateString = [options objectForKey:@"minDate"];
	NSString *maxDateString = [options objectForKey:@"maxDate"];
    
	if ([[options objectForKey:@"allowOldDates"] intValue] == 1) {
		allowOldDates = YES;
	}
    
	if ( !allowOldDates) {
		datePicker.minimumDate = [NSDate date];
	}
    
	if(minDateString){
		datePicker.minimumDate = [formatter dateFromString:minDateString];
	}
	
	if ([[options objectForKey:@"allowFutureDates"] intValue] == 0) {
		allowFutureDates = NO;
	}
    
	if ( !allowFutureDates) {
		datePicker.maximumDate = [NSDate date];
	}
    
	if(maxDateString){
		datePicker.maximumDate = [formatter dateFromString:maxDateString];
	}
    
	datePicker.date = [formatter dateFromString:dateString];
    
	if ([mode isEqualToString:@"date"]) {
		datePicker.datePickerMode = UIDatePickerModeDate;
	}
	else if ([mode isEqualToString:@"time"]) {
		datePicker.datePickerMode = UIDatePickerModeTime;
	} else {
		datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	}
    
	return datePicker;
}

- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:timezone];
	[dateFormatter setDateFormat:format];

	return dateFormatter;
}


- (UISegmentedControl *)createCancelButton:(NSString *)title {
	UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:title]];
    
	button.momentary = YES;
	button.segmentedControlStyle = UISegmentedControlStyleBar;
	button.tintColor = [UIColor blackColor];
	button.apportionsSegmentWidthsByContent = YES;
  
  CGSize size = button.bounds.size;
  button.frame = CGRectMake(5, 7.0f, size.width, size.height);
  
	[button addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventValueChanged];
    
	return button;
}

- (UISegmentedControl *)createDoneButton:(NSString *)title {
	UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:title]];
	
  button.momentary = YES;
	button.segmentedControlStyle = UISegmentedControlStyleBar;
	button.tintColor = [UIColor blueColor];
	button.apportionsSegmentWidthsByContent = YES;
    
  CGSize size = button.bounds.size;
  CGFloat width = size.width;
  CGFloat height = size.height;
  CGFloat xPos = 320 - width - 5; // 320 == width of DatePicker, 5 == offset to right side hand
  button.frame = CGRectMake(xPos, 7.0f, width, height);
  
	[button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventValueChanged];

	return button;
}

@end