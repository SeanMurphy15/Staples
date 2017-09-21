//
//  SA_Utilities.h
//
//  Created by Ben Gottlieb on 7/2/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//
//	 Common #defines and utiliities useful in many projects
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

extern const NSUInteger				g_sa_base_version;

#define		DIM(a)				(sizeof(a) / sizeof(((a)[0])))
#define		FREE(p)				{if (p) { free(p); (p) = nil; }}
#define		SYNTHESIZE(_X_)		@synthesize _X_ = _##_X_;

#if DEBUG || AD_HOC
	#define		IF_NOT_PRODUCTION(...)					{__VA_ARGS__;}
	#define		IF_PRODUCTION(...)	
#else
	#define		IF_NOT_PRODUCTION(...)
	#define		IF_PRODUCTION(...)						{__VA_ARGS__;}
#endif

#if BUILD_USER_ben && (DEBUG || AD_HOC)
	#define		IF_IS_BENS_BUILD(...)					{__VA_ARGS__;}
#else
	#define		IF_IS_BENS_BUILD(...)					{}
#endif

#if DEBUG
	#define		IF_DEBUG(...)							{__VA_ARGS__;}
	#define		IF_NOT_DEBUG(...)						{}
#else
	#define		IF_DEBUG(...)							{}
	#define		IF_NOT_DEBUG(...)						{__VA_ARGS__;}
#endif

#if TARGET_IPHONE_SIMULATOR
	#define		IF_SIM(...)								{__VA_ARGS__;}
	#define		DISABLE_CORRECTIONS_FOR_TEXTFIELD_IN_SIM(tv)	{tv.autocapitalizationType = UITextAutocapitalizationTypeNone;tv.autocorrectionType = UITextAutocorrectionTypeNo;}
	#define		IF_DEVICE(...)							{}
#else
	#define		DISABLE_CORRECTIONS_FOR_TEXTFIELD_IN_SIM(tv)
	#define		IF_SIM(...)								{}
	#define		IF_DEVICE(...)							{__VA_ARGS__;}
#endif

#if TARGET_IPHONE_SIMULATOR
	#define				TRY(...)						{__VA_ARGS__;}
#else
	#define				TRY(...)						@try {__VA_ARGS__;} @catch (id e) {LOG(@"Got exception: %@", e);}
#endif

#ifndef __has_feature
	#define __has_feature(x) 0
#endif


#define				OS_40_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000)
#define				OS_42_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 40200)
#define				OS_50_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
#define				OS_60_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 60000)
#define				OS_70_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)
#define				OS_80_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000)
#define				RUNNING_UNDER_ARC			((__has_feature(objc_arc)))
#define				NOT_RUNNING_UNDER_ARC		(!(RUNNING_UNDER_ARC))


//=============================================================================================================================
#pragma mark ARC conversion
#if NOT_RUNNING_UNDER_ARC
	#define			BEGIN_AUTORELEASEPOOL()		NSAutoreleasePool *__autoreleasePool = [[NSAutoreleasePool alloc] init];
	#define			END_AUTORELEASEPOOL()		[__autoreleasePool release];
	#define			CFBridgingRetain(p)			(p)
	#define			CFBridgingRelease(p)		(p)
	#define         RELEASE(p)                  {[p release]; p = nil;}
	#if !OS_50_BUILD && TARGET_OS_IPHONE
		#define         objc_retainedObject(p)      ((id) (p))
		#define			objc_unretainedObject(o)			((id) o) 
	#endif
	#define			STATIC_CONSTANT(type, name, value)		static type *name = nil; if (name == nil) name = value;
	#define			IF_NOTARC(...)				{__VA_ARGS__;}
	#define			_retain						retain		
	#define			unsafe						assign
#else
	#define			BEGIN_AUTORELEASEPOOL()		@autoreleasepool {
	#define			END_AUTORELEASEPOOL()		}
//	#define         RELEASE(p)
	#define			STATIC_CONSTANT(type, name, value)		static type *name = nil; if (name == nil) name = value;
	#define			IF_NOTARC(...)
//	#define			autorelease					self
//	#define			release						self
	#define			_retain						self
	#define			unsafe						unsafe_unretained
#endif


//=============================================================================================================================
#pragma mark Device/OS Info
#define			PRINTING_AVAILABLE				(OS_42_BUILD && [NSClassFromString(@"UIPrintInteractionController") performSelector: @selector(isPrintingAvailable)])

#if TARGET_OS_IPHONE
	#define				MULTITASKING_AVAILABLE			(([[UIDevice currentDevice] respondsToSelector: @selector(isMultitaskingSupported)]) && ([[UIDevice currentDevice] isMultitaskingSupported]))
	#define				MAJOR_OS_VERSION				([[UIDevice currentDevice].systemVersion intValue])
	#define				GCD_AVAILABLE					(RUNNING_ON_40)
	#define				RUNNING_ON_IPAD					([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	#define				RUNNING_ON_IPHONE				([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)


	#ifdef NSFoundationVersionNumber_iOS_4_0
		#define				RUNNING_ON_40					(NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_4_0)
	#else
		#define				RUNNING_ON_40					([[UIDevice currentDevice].systemVersion intValue] >= 4)
	#endif

	#ifdef NSFoundationVersionNumber_iOS_5_0
		#define				RUNNING_ON_50					(NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_5_0)
	#else
		#define				RUNNING_ON_50					([[UIDevice currentDevice].systemVersion intValue] >= 5)
	#endif

	#ifdef NSFoundationVersionNumber_iOS_6_0
		#define				RUNNING_ON_60					(NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_6_0)
	#else
		#define				RUNNING_ON_60					([[UIDevice currentDevice].systemVersion intValue] >= 6)
	#endif

	#ifdef NSFoundationVersionNumber_iOS_7_0
		#define				RUNNING_ON_70					(NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0)
	#else
		#define				RUNNING_ON_70					([[UIDevice currentDevice].systemVersion intValue] >= 7)
	#endif

	#ifdef NSFoundationVersionNumber_iOS_8_0
		#define				RUNNING_ON_80					(NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0)
	#else
		#define				RUNNING_ON_80					([[UIDevice currentDevice].systemVersion intValue] >= 8)
	#endif

	#define				IS_RETINA_DEVICE				([UIScreen mainScreen].scale > 1.0)
	#define				IS_4INCH_SCREEN					(RUNNING_ON_IPHONE && [UIScreen mainScreen].bounds.size.height == 568)
	#define				IF_IOS(...)						{__VA_ARGS__;}
	#define				IF_MACOS(...)
#else
	#define				RUNNING_ON_40					NO
    #define				RUNNING_ON_50					NO
    #define				RUNNING_ON_60					NO
    #define				RUNNING_ON_70					NO
    #define				MULTITASKING_AVAILABLE			NO
	#define				MAJOR_OS_VERSION				10
	#define				GCD_AVAILABLE					YES
	#define				IF_IOS(...)
	#define				IF_MACOS(...)					{__VA_ARGS__;}
#endif
//=============================================================================================================================
#pragma mark String Conversion

#define			CharIsWhitespace(ch)			(ch == ' ' || ch == '\n' || ch == '\t' || ch == '\0')

//==========================================================================================
#pragma mark Logging			

void		RedirectConsoleLogToDocumentFolder(void);
NSString *	RedirectedFilePath(void);
void		ClearConsoleLog(void);


#if DEBUG
	#define			IS_DEVELOPER_BUILD								([[NSBundle mainBundle] pathForResource: @"DEVELOPER_BUILD" ofType: @"dat"].length > 0)
	#define			SA_Assert(condition, desc, ...)					IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__))
	#define			SA_AssertAndReturn(condition, desc, ...)		IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__)); if (!(condition)) return;
	#define			SA_AssertAndReturnNil(condition, desc, ...)		IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__)); if (!(condition)) return nil;
	#define			SA_AssertAndReturnNO(condition, desc, ...)		IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__)); if (!(condition)) return NO;

	#if TARGET_OS_IPHONE
		#define			SA_TRY(a)										@try {a;} @catch (id e) {[SA_AlertView showAlertWithException: e];}
	#else
		#define			SA_TRY(a)										@try {a;} @catch (id e) {LOG(@"%@", e);}
	#endif
#else
	#define			IS_DEVELOPER_BUILD								0
	#define			SA_Assert(condition, desc, ...)					if (!(condition)) LOG(desc)
	#define			SA_AssertAndReturn(condition, desc, ...)		if (!(condition)) {LOG(desc); return;}
	#define			SA_AssertAndReturnNil(condition, desc, ...)		if (!(condition)) {LOG(desc); return nil;}
	#define			SA_AssertAndReturnNO(condition, desc, ...)		if (!(condition)) {LOG(desc); return NO;}

	#define			SA_TRY(a)										@try {a;} @catch (id e) {}
#endif

#if DEBUG || ADHOC
	#define			LOG							NSLog
	#if TARGET_IPHONE_SIMULATOR
		#define			SIMLOG						NSLog
	#else
		#define			SIMLOG						{}
	#endif
#else
	#define			LOG(...)					{}
	#define			SIMLOG						{}
#endif


#if DEBUG || AD_HOC
	#define			INIT_COUNT(_X_)				static NSUInteger g_##_X_##_objectCount = 0;
	#define			INCR_COUNT(_X_)				if (g_##_X_##_objectCount++ > 0) LOG(@"%d %@ objects created", g_##_X_##_objectCount, [_X_ class]);
	#define			DECR_COUNT(_X_)				g_##_X_##_objectCount--;

	#define			INCR_COUNT_LABELED(_X_, l)	if (g_##_X_##_objectCount++ > 0) LOG(@"%d %@ instances created", g_##_X_##_objectCount, l);
	#define			DECR_COUNT_RELEASE(_X_, o)	if ([o retainCount] <= 1) g_##_X_##_objectCount--; RELEASE(o);

	#define			LOG_DATA(d, n)				[d writeToFile: [[NSString stringWithFormat: @"~/tmp/%@.txt", n] stringByExpandingTildeInPath] options: 0 error: nil]

	#define			DISPLAY_ALERT(t, m)			displayAlert(t, m);
#else
	#define			INIT_COUNT(_X_)
	#define			INCR_COUNT(_X_)
	#define			DECR_COUNT(_X_)

	#define			INCR_COUNT_LABELED(_X_, l)
	#define			DECR_COUNT_RELEASE(_X_, o)	RELEASE(o)

	#define			LOG_DATA(...)				{}
	#define			DISPLAY_ALERT(...)			{}
#endif

natural_t			freeMemory(BOOL logIt);
void				displayAlert(NSString *title, NSString *message);

#define				TIMING_START					NSDate			*__timing_start = [NSDate date];
#define				TIMING_LOG(s)					LOG(@"%@ Took %.5f", s, ABS([__timing_start timeIntervalSinceNow]));

//==========================================================================================
#pragma mark Collection and Conversion
#define		IS_KIND_OF(o, c)			([o isKindOf: [c class]])

#define		$D(...)						[NSDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]
#define		$A(...)						[NSArray arrayWithObjects: __VA_ARGS__, nil]
#define		$S(format, ...)				[NSString stringWithFormat: format, ##  __VA_ARGS__]
#define		$U(format, ...)				[NSURL URLWithString: [NSString stringWithFormat: format, ##  __VA_ARGS__]]
#define		$P(format, ...)				[NSPredicate predicateWithFormat: format, ##  __VA_ARGS__]
#define		$Vrect(r)					[NSValue valueWithCGRect: r]
#define		$Vpoint(x, y)				[NSValue valueWithCGPoint: CGPointMake(x, y)]
#define		$Vsize(w, h)				[NSValue valueWithCGSize: CGSizeMake(w, h)]


#define		CGRectCenter(r)					(CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r)))
#define		CGRectScale(r, xF, yF)			(CGRectMake(r.origin.x * xF, r.origin.y * yF, r.size.width * xF, r.size.height * yF))
#define		CGRectScaleAndCenter(r, xF, yF)	(CGRectMake(r.origin.x * xF + r.size.width * (1.0 - xF) * 0.5, r.origin.y * yF + r.size.height * (1.0 - yF) * 0.5, r.size.width * xF, r.size.height * yF))
#define		CGPointScale(p, xF, yF)			(CGPointMake(p.x * xF, p.y * yF))
#define		CGSizeScale(p, xF, yF)			(CGSizeMake(p.width * xF, p.height * yF))
#define		CGDistanceBetweenPoints(a, b)	(sqrt(pow(a.x - b.x, 2) + (pow(a.y - b.y, 2))))
#define		CGPointOffsetFromPoint(a, b)	(CGPointMake(a.x - b.x, a.y - b.y))
#define		CGPointAddPoint(a, b)			(CGPointMake(a.x + b.x, a.y + b.y))	
#define		CGPointSubtractPoint(a, b)		(CGPointMake(a.x - b.x, a.y - b.y))	
#define		CGRectIntegerize(r)				(CGRectMake(round(r.origin.x), round(r.origin.y), round(r.size.width), round(r.size.height)))
#define		CGSizeCenterInRect(s, r)		(CGRectMake(r.origin.x + (r.size.width - s.width) / 2, r.origin.y + (r.size.height - s.height) / 2, s.width, s.height))
#define		CGRectFromSize(s)				(CGRectMake(0, 0, s.width, s.height))
#define		CGRectMidpoint(r)				(CGPointMake(r.origin.x + r.size.width / 2, r.origin.y + r.size.height / 2))

#define		RAD_TO_DEG(r)					((r) * 360 / (2 * M_PI))
#define		DEG_TO_RAD(d)					((d) * (2 * M_PI) / 360)

#define		REPORT_ERROR(e, m)						if (e) LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e)
#define		REPORT_ERROR_AND_RETURN(e, m)			if (e) {LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e); return;}
#define		REPORT_ERROR_AND_RETURN_VALUE(e, m, v)	if (e) {LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e); return v;}

#if TARGET_OS_IPHONE
CGSize CGSizeScaledWithinLimitSize(CGSize size, CGSize limitSize);
CGRect ConvertFrameFromPortraitToLandscape(CGRect frame);
CGRect ConvertFrameFromLandscapeToPortrait(CGRect frame);
CGRect CGRectPlacedInRectWithContentMode(CGRect child, CGRect parent, UIViewContentMode mode);
#endif


#define AssertCast(CLS_, OBJ_) ({ NSAssert2([(OBJ_) isKindOfClass:[CLS_ class]], @"Object %@ not of class %@", OBJ_, NSStringFromClass([CLS_ class])); (CLS_ *)(OBJ_); })

//==========================================================================================
#pragma mark Graphics
extern const CGPoint		CGPointNone;			


//==========================================================================================
#pragma mark Defines
typedef enum {dir_left, dir_up, dir_right, dir_down} direction;


//==========================================================================================
#pragma mark Private Structures/Functions

#if TARGET_OS_IPHONE
	NSString *				NSStringFromInterfaceOrientation(UIInterfaceOrientation orientation);
#endif



void					MailDataWithTitle(NSData *data, NSString *title);

#define				UIInterfaceOrientationUnknown				((UIInterfaceOrientation) 0)

#if BACKGROUND_THREAD_SUPPORT
	#warning BACKGROUND_THREAD_SUPPORT has been deprecated
#endif

#define				PERFORM_ON_MAIN_THREAD(f)				{simpleBlock	b = ^{f}; if ([NSThread isMainThread]) b(); else dispatch_async(dispatch_get_main_queue(), b); }
#define				CLASS_PROPERTY(type, name, uname)		+ (void) set##uname: (type) name; + (type) name;

typedef void (^simpleBlock)(void);
typedef void (^booleanArgumentBlock)(BOOL value);
typedef void (^intArgumentBlock)(NSInteger index);
typedef void (^floatArgumentBlock)(float value);
typedef void (^idArgumentBlock)(id arg);
typedef void (^stringArgumentBlock)(NSString *arg);
typedef void (^errorArgumentBlock)(NSError *error);
typedef void (^idErrorArgumentBlock)(id arg, NSError *error);
typedef id (^idReturnBlock)(void);
typedef id (^idArgumentBlockReturningID)(id arg);
typedef void (^simpleArrayBlock)(NSArray *array);
typedef void (^simpleDictionaryBlock)(NSDictionary *dictionary);
typedef void (^simpleSetBlock)(NSSet *set);
typedef void (^simpleStringBlock)(NSString *string);

#if TARGET_OS_IPHONE
typedef void (^viewArgumentBlock)(UIView *view);
#endif
#ifdef NSManagedObjectContext
	typedef void (^mocArgumentBlock)(NSManagedObjectContext *moc);
#endif
typedef void (^simpleDateBlock)(NSDate *date);
typedef void (^mocArgumentBlock)(NSManagedObjectContext *moc);

BOOL		SA_Base_DebugMode(void);
void		set_SA_Base_DebugMode(BOOL debug);

#if TARGET_OS_IPHONE
	typedef void (^simpleImageBlock)(UIImage *image);
 #endif

#define	SWAP_OBJ(a, b)				{id ____tempSwap = a; a = b; b = ____tempSwap; }
#define	ENSURE_MAIN_THREAD(b)		if (![NSThread isMainThread]) dispatch_async(dispatch_get_main_queue(), ^{b}); else ^{b}();

#define SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(classname, methodName)			+ (classname *) methodName;

#define SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(classname, methodName) \
	static classname *s_##methodName = nil; \
	+ (classname *) methodName {\
		static dispatch_once_t  once; dispatch_once(&once, ^ { s_##methodName = [[self alloc] init]; });\
		return s_##methodName; \
	}

#define	STATIC_OBJECT_PROPERTY(name, value)	- (id) name {static id name = nil; if (name == nil) {static dispatch_once_t  once; dispatch_once(&once, ^ { name = value; });}
#define	PROPERTY_PASS_THROUGH(lower, upper, type, dest)  - (void) set##upper: (type) v { [dest set##upper: v]; }  - (type) lower { return [dest lower]; }

#define SINGLETON_IMPLEMENTATION_FOR_CLASS_METHOD_AND_INITIALIZER(classname, methodName, initializer) \
	static classname *s_##methodName = nil; \
	+ (classname *) methodName {\
		static dispatch_once_t  once; dispatch_once(&once, ^ { s_##methodName = [[self alloc] initializer]; });\
		return s_##methodName; \
	}

#define	DEFAULT_VIEW_INIT_METHODS - (id) initWithFrame: (CGRect) frame { return [[super initWithFrame: frame] postInitSetup]; } - (id) initWithCoder: (NSCoder *) aDecoder { return [[super initWithCoder: aDecoder] postInitSetup]; }

typedef NS_ENUM(UInt8, XCodeBuildType) {
	XCodeBuildType_dev,
	XCodeBuildType_adhoc,
	XCodeBuildType_appStore
};
XCodeBuildType XCODE_BUILD_TYPE(void);

#define weakify(s)				__weak typeof(s)		w##_s = s
#define strongify(s)			w##_s



@protocol SA_JSONEncoding <NSObject>
@property (nonatomic, readonly) NSDictionary *JSONDictionary;
@optional
- (id) initWithJSONDictionary: (NSDictionary *) JSONDictionary;
@end



#define SUPPRESS_LEAK_WARNING(STUFF) do { \
	_Pragma("clang diagnostic push") \
	_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
	STUFF; \
	_Pragma("clang diagnostic pop") \
} while (0)



