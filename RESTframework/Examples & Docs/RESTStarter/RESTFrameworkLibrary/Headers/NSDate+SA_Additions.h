//
//  NSDate_Additions.h
//
//  Created by Ben Gottlieb on 3/28/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	extactRelativeTimeDepth_minimal = 1,
	extactRelativeTimeDepth_moderate,
	extactRelativeTimeDepth_maximum,
	extactRelativeTimeDepth_extreme
} extactRelativeTimeDepth;

#define		SECONDS_PER_DAY						(1440.0 * 60.0)
#define		SECONDS_PER_WEEK					(SECONDS_PER_DAY * 7.0)


@interface NSDate (NSDate_SA_Additions) 	

@property(readonly) NSUInteger hour, minute, second, nearestHour, nextNearestHour;
@property(readonly) NSUInteger year, month, day, weekday, numberOfDaysInMonth;
@property(readonly) NSString *weekdayAsLongString, *weekdayAsMediumString, *weekdayAsShortString, *monthName, *shortMonthName;
@property(readonly) NSTimeInterval absoluteTimeIntervalFromNow, fractionalSecond;

+ (BOOL) isIn24HourMode;

- (NSDate *) dateByAddingTimeIntervalAmount: (NSTimeInterval) interval;

- (NSDate *) dateWithHour: (NSUInteger) hour;
- (NSDate *) dateWithHour: (NSUInteger) hour minute: (NSUInteger) minute second: (NSUInteger) second ;
+ (NSDate *) dateWithNearestHour;
+ (NSDate *) dateWithNextNearestHour;

+ (NSDate *) SA_dateWithNaturalLanguageString: (NSString *) date;
- (NSString *) descriptionWithCalendarFormat: (NSString *) format;
+ (NSDate *) dateWithNaturalLanguageString: (NSString *) date andFormatHint: (NSString *) formatHint;
+ (NSDate *) dateWithUNIXString: (NSString *) string;	//@"YYYY-mm-ddTHH:mm:ss zzzz"
+ (NSDate *) dateWithXMLString: (NSString *) string;
+ (NSDate *) dateWithHTTPHeaderString: (NSString *) string;

- (NSString *) HTTPHeaderString;

- (NSString *) shortDateString;
- (NSString *) mediumDateString;
- (NSString *) longDateString;
- (NSString *) dayMonthDateString;
- (NSString *) UTCString;
- (NSString *) veryShortDateString;
- (NSString *) logString;

- (NSString *) shortRelativeString;
- (NSString *) mediumRelativeString;
- (NSString *) exactRelativeStringWithDepth: (extactRelativeTimeDepth) depth;
- (NSString *) roughRelativeString;
- (NSString *) futureRelativeDateString;

- (BOOL) isAfter: (NSDate *) date;
- (BOOL) isBefore: (NSDate *) date;


- (NSString *) veryShortTimeString;
- (NSString *) shortTimeString;
- (NSString *) mediumTimeString; 
- (NSString *) dateStringWithFormat: (NSDateFormatterStyle) dateFormat timeFormat: (NSDateFormatterStyle) timeFormat;

- (NSString *) internetFormattedDateTimeString;
- (NSString *) internetFormattedTDateTimeString;
- (NSString *) descriptionWithoutOffset;
- (NSString *) dateTimeString;

- (NSDate *) futureDateByAddingDays: (NSUInteger) days months: (NSUInteger) months years: (NSUInteger) years;

- (NSDate *) previousDay;
- (NSDate *) nextDay;

- (BOOL) isPastDate;
- (BOOL) isFutureDate;
- (BOOL) isSameDayAs: (NSDate *) date;
- (BOOL) isSameMonthAs: (NSDate *) date;
- (BOOL) isSameYearAs: (NSDate *) date;

- (BOOL) isToday;
- (BOOL) isTomorrow;
- (BOOL) isYesterday;
- (BOOL) isThisMonth;
- (BOOL) isThisYear;
- (NSInteger) daysAgo;

- (NSDate *) midnight;
- (NSDate *) noon;
- (NSDate *) lastSecond;

- (NSString *) monthDayYearDateString: (BOOL) addLeadingZeroes;
- (NSString *) yearMonthDayDateString: (BOOL) addLeadingZeroes;
- (NSDate *) firstDayOfMonth;
- (NSDate *) lastDayOfMonth;


- (NSComparisonResult) compareTimes: (NSDate *) date;
- (NSInteger) monthsSinceDate: (NSDate *) date;
- (NSInteger) timeZoneOffsetAmount;
@end
