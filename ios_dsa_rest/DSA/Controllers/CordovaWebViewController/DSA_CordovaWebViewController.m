//
//  DSA_CordovaWebViewController
//  REST DSA + Cordova
//
//  Created by Oleksii Bilous on 9/6/12.
// 
//

#if BUILD_WITH_CORDOVA

#import <Cordova/CDVPlugin.h>
#import "DSA_CordovaWebViewController.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"

//static DSA_CordovaWebViewController  *s_controller;

@implementation DSA_CordovaWebViewController

+ (id) controller {
    DSA_CordovaWebViewController *s_controller = [[[self alloc] init] autorelease];
//        s_controller.useSplashScreen = YES;
    s_controller.wwwFolderName = @"www";
    s_controller.startPage = @"index.html";
    s_controller.inHistoryMode = NO;
    s_controller.sendDocumentTrackerNotifications = NO;
    
	return s_controller;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark Actions
////////////////////////////////////////////////////
//
////////////////////////////////////////////////////

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    for (NSUInteger i = 0; i < [self.toolbar.items count]; i++)
    {
        if(((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).tag == 1)
            ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=YES;
    }
}

////////////////////////////////////////////////////////////////
//On 21/12/2011 added by Subodh to implement open in capability
////////////////////////////////////////////////////////////////
- (IBAction) docInteractionButtonPressed
{
    self.docInteractionController = [UIDocumentInteractionController  interactionControllerWithURL:[NSURL fileURLWithPath:self.item.fullPath]];
    self.docInteractionController.delegate = self;
    
    for (NSUInteger i = 0; i < [self.toolbar.items count]; i++)
    {
        if(((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).tag == 1)
        {
            ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=NO;
            
            //[self.docInteractionController presentOptionsMenuFromBarButtonItem:[self.toolbar.items objectAtIndex:i] animated:NO];
            if (![self.docInteractionController presentOptionsMenuFromBarButtonItem:[self.toolbar.items objectAtIndex:i] animated:NO]) {
                
                [SA_AlertView showAlertWithTitle: @"Supporting applications not found" message: @""];
                ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=NO;
            }
        }
    }
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
- (IBAction) donePressed
{
//    [docInteractionController dismissMenuAnimated:YES];
    
    if (self.sendDocumentTrackerNotifications)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStopViewingNotification object:self.item];
    }
    [self.cordovaWebViewControllerDelegate donePressed:self];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) setupToolbar {
	NSMutableArray			*barButtonItems = [NSMutableArray array];
	
//    if (_inHistoryMode)
//    {
//		UIBarButtonItem			*item = [UIBarButtonItem itemWithTitle:@"History" target: self action: @selector(historyPressed:)];
//		
//		item.accessibilityLabel = @"History Button";
//        [barButtonItems addObject: item];
//    }
//    else
    {
        [barButtonItems addObject: [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemDone
                                                                target: self
                                                                action: @selector(donePressed)]];
    }
	[barButtonItems	addObject: [UIBarButtonItem SA_flexibleSpacer]];
    
    //
    
    //Added by Subodh to implement Doc Interaction
    
	
//	if (self.url) {
//		[barButtonItems addObject: self.backBarButtonItem];
//		[barButtonItems addObject: self.forwardBarButtonItem];
//		[barButtonItems addObject: [UIBarButtonItem spacerOfWidth: 20]];
//	}
	
    //	if (!self.item.isProtectedContentValue) [barButtonItems addObject: [UIBarButtonItem itemWithTitle: @"Email" target: self action: @selector(sendAsEmail:)]];
    UIBarButtonItem* bbi;
    
//    if ([self.item isProtectedContent])
//    {
//        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_forbidden"]
//                                      target: self
//                                      action: @selector(sendAsEmail:)];
//        bbi.enabled = NO;
//    }
//    else if ([g_appDelegate.documentTracker documentMarkedToSendAsEmail:[self.item Id]])
//    {
//        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_marked"]
//                                      target: self
//                                      action: @selector(clearSendAsEmail:)];
//    }
//    else
//    {
//        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail"]
//                                      target: self
//                                      action: @selector(sendAsEmail:)];
//    }
    //	if (!self.item.isProtectedContentValue) [barButtonItems addObject: [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail"]
    //                                                                                               target: self
    //                                                                                               action: @selector(sendAsEmail:)]];
#if OPENWITHSUPPORTED
    NSString *documentKeyValue = [self.item valueForKey:MNSS(@"Document_Type__c") ];
    if (!([self.item isMovieFile]) && ([self.item fullPath]!=nil) && (![documentKeyValue isEqualToString:@"ZIP"]) && (![documentKeyValue isEqualToString:@"LINK"])) {
        UIBarButtonItem *docInteractionBarButtonItem=[UIBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAction
                                                                                  target:self
                                                                                  action:@selector(docInteractionButtonPressed)];
        [docInteractionBarButtonItem setTag:1];
        
        if ([self.item isProtectedContent])
        {
            docInteractionBarButtonItem.enabled=NO;
        }
        
        [barButtonItems addObject:docInteractionBarButtonItem];
        
    }
#endif
    
    bbi.style = UIBarButtonItemStylePlain;
    
#if SHOPPING_CART_SUPPORT
	[barButtonItems addObject: [UIBarButtonItem itemWithImage: [UIImage imageNamed: @"cart.png"] block: ^(id item) {
		self.item.currentlyInCartValue = !self.item.currentlyInCartValue;
		[self.item save];
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShoppingCartContentsChanged object: self.item.objectID];
	}]];
#endif
	
    if(bbi && [self.item fullPath] !=nil)
    {
        [barButtonItems addObject:bbi];
    }
    
	self.toolbar.items = barButtonItems;
    
    self.toolbar.normalizedFrame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
}

- (IBAction) goBack {
	[self.webView goBack];
}

- (IBAction) goForward {
	[self.webView goForward];
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void) configuredTitleLabel: (UILabel *) label withString: (NSString *) titleString {
    // SF_MobileAppConfig* mac = [SF_MobileAppConfig activeMobileConfigInContext:[SF_Store store].context];
    MMSF_MobileAppConfig__c *mac = [g_appDelegate selectedMobileAppConfig];
    
    label.text = titleString;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [mac titleTextColor];
}

#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];
	
    self.toolbar.frame = CGRectMake(self.toolbar.frame.origin.x, self.toolbar.frame.origin.y + 20.0, self.toolbar.frame.size.width, self.toolbar.frame.size.height);
    self.webView.frame = CGRectMake(self.webView.frame.origin.x, self.webView.frame.origin.y + 40.0, self.webView.frame.size.width, self.webView.frame.size.height);
    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + 20.0, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);

	self.navigationController.navigationBarHidden = YES;
    
    MMSF_MobileAppConfig__c * mac = [g_appDelegate selectedMobileAppConfig];
	
    self.toolbar.tintColor = [mac titleBarColor];
    
    //  if (self.contentItemTitle.length && self.item == nil) self.item = [[SF_Store store].context anyObjectOfType: [SF_ContentItem entityName] matchingPredicate: $P(@"title == %@", self.contentItemTitle)];
    //	if (self.item) [self loadItem];
    [self configuredTitleLabel: self.titleLabel withString: self.title.length ? self.title : [self.item Title]];
    
//    if (inHistoryMode)
//    {
//        //Default Content Item should not be not displayed in History Mode when "Check in" is Enabled.
//        if([g_appDelegate isTrackingDocuments])
//            isDefaultLoadedFromHistory = YES;
//        
//        NSArray* arr = [g_appDelegate.contentItemHistory contentItemHistory];
//        if (arr.count > 0)
//        {
//            NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",[arr objectAtIndex:0]];
//            NSArray *resultArray = [[[DSARestClient sharedInstance] context] allObjectsOfType:@"ContentVersion" matchingPredicate:pred];
//            MMSF_ContentVersion* ci = [resultArray objectAtIndex:0];
//            self.item = ci;
//            [self loadItem];
//        }else {
//            /*to fix the crash make the item object nil when array count is 0*/
//            self.item = nil;
//            if (self.url == nil && self.item == nil) [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]]]];
//            
//        }
//    }    
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupToolbar];
}

- (void) viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {
	[super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
	[self updateForOrientation: toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
	[self updateForOrientation: self.interfaceOrientation];
//	[self.webView performSelector: @selector(reload) withObject: nil afterDelay: 0.1];
}

- (void) updateForOrientation: (UIInterfaceOrientation) newOrientation {
	CGRect					bounds = self.view.bounds;

	bounds.origin.y = self.webView.frame.origin.y;
	bounds.size.height = bounds.size.height - bounds.origin.y;
	self.webView.normalizedFrame = bounds;
	return;
	
	self.view.frame = bounds;
	self.toolbar.normalizedFrame = CGRectMake(0, 40, bounds.size.width, 44);
	self.webView.normalizedFrame = CGRectMake(0, 44, bounds.size.width, bounds.size.height - 94);
}

/* Comment out the block below to over-ride */
/*
 - (CDVCordovaView*) newCordovaViewWithFrame:(CGRect)bounds
 {
 return[super newCordovaViewWithFrame:bounds];
 }
 */

/* Comment out the block below to over-ride */
/*
 #pragma CDVCommandDelegate implementation
 
 - (id) getCommandInstance:(NSString*)className
 {
 return [super getCommandInstance:className];
 }
 
 - (BOOL) execute:(CDVInvokedUrlCommand*)command
 {
 return [super execute:command];
 }
 
 - (NSString*) pathForResource:(NSString*)resourcepath;
 {
 return [super pathForResource:resourcepath];
 }
 
 - (void) registerPlugin:(CDVPlugin*)plugin withClassName:(NSString*)className
 {
 return [super registerPlugin:plugin withClassName:className];
 }
 */

#pragma UIWebDelegate implementation

- (void) webViewDidFinishLoad:(UIWebView*) theWebView
{
    if (_item) {
        
        // Need to unzip the file and set the URL of the unzipped file to view
        if ([self.item fullPath ].length)
        {
            NSString *htmlBundleDataPath;
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [paths objectAtIndex:0];
            NSError				*e = nil;
            NSString *directoryPath = [documentPath stringByAppendingPathComponent:@"Test"];
            NSString * itemFileName = [NSString stringWithFormat:@"%@.htmlbundle", self.item.Title];
            NSString * newPath = [NSString stringWithFormat:@"%@/%@", directoryPath, itemFileName];
            
            BOOL isDir;
            if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&e];
            }
            
            
			//htmlBundleDataPath = [NSString tempFileNameWithSeed: self.item.Title ofType: @"htmlbundle"];
            
            
//            if (![[NSFileManager defaultManager] fileExistsAtPath:newPath])
//            {
//                
                [SSZipArchive unzipFileAtPath:[self.item fullPath] toDestination:newPath];
                
//            }
//            else {
//                //NSLog(@"found html5 bundle... already unzipped");
//            }
            
            
            htmlBundleDataPath = newPath;
            // this is passed before the deviceready event is fired, so you can access it in js when you receive deviceready
            NSString* jsString = [NSString stringWithFormat:@"var filePath = \"%@\";", htmlBundleDataPath];
            [theWebView stringByEvaluatingJavaScriptFromString:jsString];
        }
    }

    // Black base color for background matches the native apps
    theWebView.backgroundColor = [UIColor blackColor];
    
//    [self.spinner stopAnimating];
    if (self.sendDocumentTrackerNotifications && !self.isDefaultLoadedFromHistory && [self.item ContentUrl])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: DocumentTrackerStartViewingNotification object:self.item.Id];
    }
//	self.spinnerHolder.alpha = 0.0;

    
	return [super webViewDidFinishLoad:theWebView];
}

/* Comment out the block below to over-ride */
/*
 
 - (void) webViewDidStartLoad:(UIWebView*)theWebView
 {
 return [super webViewDidStartLoad:theWebView];
 }
 
 - (void) webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
 {
 return [super webView:theWebView didFailLoadWithError:error];
 }
 
 - (BOOL) webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
 {
 return [super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
 }
 */

@end

#endif
