#import "MGFilePreviewGenerator.h"
#import <QuickLook/QuickLook.h>
#import "MMSF_ContentVersion.h"


@implementation MGFilePreviewGenerator

static NSString *s_fileTypeAI =         @"ai";
static NSString *s_fileTypeAttachment = @"attachment";
static NSString *s_fileTypeAudio =      @"audio";
static NSString *s_fileTypeCSV =        @"csv";
static NSString *s_fileTypeEPS =        @"eps";
static NSString *s_fileTypeExcel =      @"excel";
static NSString *s_fileTypeHTML =       @"html";
static NSString *s_fileTypeKeynote =    @"keynote";
static NSString *s_fileTypeImage =      @"image";
static NSString *s_fileTypeMP4 =        @"mp4";
static NSString *s_fileTypePages =      @"pages";
static NSString *s_fileTypePDF =        @"pdf";
static NSString *s_fileTypePPT =        @"ppt";
static NSString *s_fileTypePSD =        @"psd";
static NSString *s_fileTypeRTF =        @"rtf";
static NSString *s_fileTypeTXT =        @"txt";
static NSString *s_fileTypeUnknown =    @"unknown";
static NSString *s_fileTypeURL =        @"url";
static NSString *s_fileTypeVideo =      @"video";
static NSString *s_fileTypeVisio =      @"visio";
static NSString *s_fileTypeWord =       @"word";
static NSString *s_fileTypeXML =        @"xml";
static NSString *s_fileTypeZIP =        @"zip";

static NSString *s_keyContentVersion =  @"contentVersion";
static NSString *s_keySize =            @"size";
static NSString *s_keyCompletionBlock = @"completionBlock";

NSUInteger		 s_thumbnailGeneratorFileSizeLimit = NSUIntegerMax;


#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setNoPreviewImage:[UIImage imageNamed:@"unknown_thumbnail"]];
        urlQueue = [NSMutableArray array];
        currentURLBlock = nil;

    }
    return self;
}

#pragma mark - Properties

- (BOOL)isFinished
{
    if(urlQueue && [urlQueue count]) {
        return NO;
    } else {
        if(currentURLBlock != nil) {
            return NO;
        }
    }
    return YES;
}

- (void)setThumbnailFileSizeLimit:(NSUInteger)limit {
    s_thumbnailGeneratorFileSizeLimit = limit;
}


#pragma mark - Methods

- (UIImage*)thumbnailForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets;
{
    MGFilePreviewDefinition *definition = [[MGFilePreviewDefinition alloc] initWithContentVersion:contentVersion size:size backgroundColor:backgroundColor borderColor:borderColor outsets:borderOutsets];
    UIImage *thumb = [self generatePreviewForDefinition:definition];
    return [self applyBorderToImage:thumb definition:definition];
}

- (UIImage *)generatePreviewForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor;
{
    MGFilePreviewDefinition *definition = [[MGFilePreviewDefinition alloc] initWithContentVersion:contentVersion size:size backgroundColor:backgroundColor borderColor:nil outsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    return [self generatePreviewForDefinition:definition];
}

- (UIImage *)generatePreviewForDefinition:(MGFilePreviewDefinition *)definition
{
    MMSF_ContentVersion *contentVersion = definition.contentVersion;
    NSString *fileType = contentVersion.FileType;
    NSString *type = [[[contentVersion valueForKey:@"PathOnClient"] pathExtension] lowercaseString];
    
    if ([contentVersion valueForKey:@"ContentUrl"]!= nil || [fileType isEqualToString:@"LINK"])
        type = s_fileTypeURL;
    
    if ([type isEqual: @"mp4"])
        type = s_fileTypeMP4;
    else if ([contentVersion isMovieFile])
        type = s_fileTypeVideo;
    else if (contentVersion.isZipFile)
        type = s_fileTypeHTML;
    else if ([type isEqual: @"ai"])
        type = s_fileTypeAI;
    else if ([type isEqual: @"mp3"])
        type = s_fileTypeAudio;
    else if ([type isEqual: @"csv"])
        type = s_fileTypeCSV;
    else if ([type isEqual: @"eps"])
        type = s_fileTypeEPS;
    else if ([type isEqual: @"xls"] || [type isEqual: @"xlsx"])
        type = s_fileTypeExcel;
    else if ([type isEqual: @"html"])
        type = s_fileTypeHTML;
    else if ([type isEqualToString: @"jpg"] || [type isEqualToString: @"jpeg"] || [type isEqualToString: @"gif"] || [type isEqualToString: @"tiff"] || [type isEqualToString: @"png"])
        type = s_fileTypeImage;
    else if ([type isEqual: @"key"] || [type isEqual: @"keynote"])
        type = s_fileTypeKeynote;
    else if ([type isEqual: @"pages"])
        type = s_fileTypePages;
    else if ([type isEqual: @"pages"])
        type = s_fileTypePages;
    else if ([type isEqual: @"pdf"])
        type = s_fileTypePDF;
    else if ([type isEqual: @"ppt"] || [type isEqual: @"pptx"])
        type = s_fileTypePPT;
    else if ([type isEqual: @"psd"])
        type = s_fileTypePSD;
    else if ([type isEqual: @"rtf"])
        type = s_fileTypeRTF;
    else if ([type isEqual: @"txt"])
        type = s_fileTypeTXT;
    else if ([type isEqual: @"vsd"] || [type isEqual: @"vdx"])
        type = s_fileTypeVisio;
    else if ([type isEqual: @"doc"] || [type isEqual: @"docx"])
        type = s_fileTypeWord;
    else if ([type isEqual: @"xml"])
        type = s_fileTypeXML;

    
    UIImage *theThumb = nil;
    NSURL *fileURL = nil;
    NSString *filePath = [contentVersion fullPath];
    
    if(filePath) {
        NSString *filename = [NSString stringWithFormat:@"File: %@", filePath];
        if([filename rangeOfString:@"http"].length) {
            fileURL = [NSURL URLWithString:filename];
        } else {
            fileURL = [NSURL fileURLWithPath:filePath];
        }
    }
    
    if ([type isEqualToString:s_fileTypeImage])
    {
        theThumb = [UIImage imageWithContentsOfFile:[fileURL path]];
        theThumb = [self imageWithImage:theThumb definition:definition];
    }
    
    if ((theThumb == nil) && ([type isEqualToString:s_fileTypeVideo]))
    {
        theThumb = [self imagePreviewWithMovieFileURL:fileURL definition:definition];
    }
    
    if ((theThumb == nil) && ([type isEqualToString:s_fileTypePDF]))
    {
        theThumb = [self imagePreviewWithPDFDocumentURL:fileURL definition:definition];
    }
    
    if (theThumb == nil)
    {
        theThumb = [UIImage imageNamed: $S(@"%@_thumbnail.png", type)];
        // we don't want border and background for the stock icons.
        definition.backgroundColor = [UIColor clearColor];
        definition.borderColor = nil;
        
        theThumb = [self imageWithImage:theThumb definition:definition];
    }
    
    if (theThumb == nil)
    {
        // fall out with no-preview image.
        theThumb = [self noPreviewImage];
        theThumb = [self imageWithImage:theThumb definition:definition];
    }
    
    //  Last resort, the other preview functions don't handle this URL.  Let's hand it to
    // the UIWebView to see if it likes it...
    // [self performSelectorOnMainThread:@selector(generatePreviewForGenericWebviewURL:) withObject:url waitUntilDone:NO];
    
    return theThumb;
}

- (UIImage*)applyBorderToImage:(UIImage*)image definition:(MGFilePreviewDefinition *)definition
{
    if ((definition.borderColor == nil) || (definition.borderColor.alpha == 0))
    {
        MMLog(@"not creating a border for %@", definition.contentVersion.Title);
        return image;
    }
    
    CGSize size = image.size;
    size.width += definition.borderOutsets.left + definition.borderOutsets.right;
    size.height += definition.borderOutsets.top + definition.borderOutsets.bottom;
    
    CGRect topBorder = CGRectMake(0, 0, size.width, definition.borderOutsets.top);
    CGRect rightBorder = CGRectMake(size.width - definition.borderOutsets.right, definition.borderOutsets.top, definition.borderOutsets.right, size.height - definition.borderOutsets.top - definition.borderOutsets.bottom);
    CGRect bottomBorder = CGRectMake(0, size.height - definition.borderOutsets.bottom, size.width, definition.borderOutsets.bottom);
    CGRect leftBorder = CGRectMake(0, definition.borderOutsets.top, definition.borderOutsets.left, size.height - definition.borderOutsets.top - definition.borderOutsets.bottom);
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, definition.borderColor.CGColor);
    CGContextFillRect(context, topBorder);
    CGContextFillRect(context, rightBorder);
    CGContextFillRect(context, bottomBorder);
    CGContextFillRect(context, leftBorder);
    
    [image drawAtPoint:CGPointMake(definition.borderOutsets.left,definition.borderOutsets.top)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)imageWithImage:(UIImage *)image definition:(MGFilePreviewDefinition *)definition
{
    BOOL isOpaque = ((definition.backgroundColor != nil) && (definition.backgroundColor.alpha == 1));

    UIGraphicsBeginImageContextWithOptions(definition.size, isOpaque, 0);
    
    CGRect boundingRect = CGRectMake(0.0f, 0.0f, definition.size.width, definition.size.height);
    
    // if the image is smaller than the requested size, don't scale it up.
    // center it in the bounding rect instead.
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGRect intersection = CGRectIntersection(boundingRect, imageRect);
    CGRect rectForDrawingInto = CGRectZero;
    if (CGRectEqualToRect(intersection, boundingRect))
    {
        rectForDrawingInto = AVMakeRectWithAspectRatioInsideRect(image.size, boundingRect);
    }
    else
    {
        rectForDrawingInto = imageRect;
        rectForDrawingInto.origin.x = (boundingRect.size.width - rectForDrawingInto.size.width) / 2;
        rectForDrawingInto.origin.y = (boundingRect.size.height - rectForDrawingInto.size.height) / 2;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (definition.backgroundColor == nil)
    {
        definition.backgroundColor = [UIColor clearColor];
    }
    CGContextSetFillColorWithColor(context, definition.backgroundColor.CGColor);
    CGContextFillRect(context, boundingRect);

    [image drawInRect:rectForDrawingInto];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imagePreviewWithPDFDocumentURL:(NSURL *)url definition:(MGFilePreviewDefinition *)definition
{
    @try {
        CGPDFDocumentRef	doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef) url);
        CGPDFPageRef		page = CGPDFDocumentGetPage(doc, 1);
        CGRect				pageFrame = CGPDFPageGetBoxRect(page, kCGPDFCropBox), targetFrame = CGRectMake(0, 0, definition.size.width, definition.size.height);
        float				scale = targetFrame.size.width / pageFrame.size.width;
        CGAffineTransform	transform = CGAffineTransformIdentity;
        float				targetAspect = targetFrame.size.width / targetFrame.size.height, pageAspect = pageFrame.size.width / pageFrame.size.height;
        
        if (pageAspect < targetAspect) scale = targetFrame.size.height / pageFrame.size.height;
        
        transform = CGAffineTransformScale(transform, 1, -1);
        transform = CGAffineTransformTranslate(transform, 0, -targetFrame.size.height);
        
        transform = CGAffineTransformScale(transform, scale, scale);
        
        float xOffset = pageAspect < 1 ? (pageFrame.size.height - pageFrame.size.width) / 2 : 0;
        float yOffset = pageAspect >= 1 ? (pageFrame.size.width - pageFrame.size.height) / 2 : 0;
        
        transform = CGAffineTransformTranslate(transform, xOffset, yOffset);
        
        UIGraphicsBeginImageContext(targetFrame.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // draw the black background
        CGContextSetFillColorWithColor(context, definition.backgroundColor.CGColor);
        CGContextFillRect(context, targetFrame);
        
        // apply the transform
        CGContextConcatCTM(context, transform);
        
        // make sure the page has a white background
        CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
        CGContextFillRect(context, pageFrame);
        
        // draw the pdf page
        CGContextDrawPDFPage(context, page);
        
        UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (doc) CGPDFDocumentRelease(doc);
        
        return thumbnailImage;
        
    } @catch (id e) {
        
    } @finally {
    }
    MMLog(@"%@", @"Thumbnail Generated");

}

- (UIImage *)imagePreviewWithMovieFileURL:(NSURL *)url definition:(MGFilePreviewDefinition *)definition
{
    UIImage *image = nil;
    if(url) {
        AVAsset *asset = [AVAsset assetWithURL:url];
        if(asset) {
            CMTime time = [asset duration];
            if(time.value) {
                AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                if(imageGenerator) {
                    time.value = time.value * 0.1;
                    
                    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                    if(imageRef) {
                        image = [UIImage imageWithCGImage:imageRef];
                        CGImageRelease(imageRef);
                        if(image) {
                            image = [self imageWithImage:image definition:definition];
                            image = [self overlayPlayButtonOnImage:image size:definition.size];
                        }
                    }
                }
            }
        }
    }
    
    return image;
}

- (UIImage*)overlayPlayButtonOnImage:(UIImage*)image size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawAtPoint:CGPointMake(0,0)];

    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    int ellipseInset = rect.size.width * 0.25;
    CGRect ellipseRect = CGRectInset(rect, ellipseInset, ellipseInset);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 0.f, 0.f, 0.f, 0.8f);
    CGContextFillEllipseInRect(context, ellipseRect);
    
    CGPoint center = CGPointMake(CGRectGetMidX(ellipseRect), CGRectGetMidY(ellipseRect));
    int arrowInset = ellipseRect.size.width * 0.1;
    CGRect arrowRect = CGRectInset(ellipseRect, arrowInset, arrowInset);
    float numPoints = 3.0;
    float radiansOfSeparation = 2 * M_PI / numPoints;
    double startAngle = 0;
    float radius = (arrowRect.size.width / 2) - 1;
    float startX = center.x + radius * cos(startAngle);
    float startY = center.y + radius * sin(startAngle);
    
    CGContextMoveToPoint(context, startX, startY);
    
    float destinationAngle = startAngle + radiansOfSeparation;
    
    while (numPoints) {
        float destinationX = center.x + radius * cos(destinationAngle);
        float destinationY = center.y + radius * sin(destinationAngle);
        CGContextAddLineToPoint(context, destinationX, destinationY);
        
        destinationAngle += radiansOfSeparation;
        
        numPoints --;
    }
    
    CGContextSaveGState(context);
    CGContextSetRGBFillColor(context, 1.f, 1.f, 1.f, 1.f);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

// TODO: see if this is feasible and make it so. Queue links at end of list?
//- (void)generatePreviewForGenericWebviewURL:(NSURL *)url
//{
//    MMLog(@"generatePreviewForGenericWebviewURL: %@", url);
//    if(url) {
//        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
//
//        //  This is a timeout - if the page can't load in ten seconds, we don't use a thumbnail
//        [self performSelector:@selector(finishWithImage:) withObject:nil afterDelay:20.0f];
//    }
//}
//
//- (void)overrideJSAlertForWebview:(UIWebView *)webview
//{
//    //  We're using the UIWebView to preview URLs that we don't know how to deal with
//    // manually.  This could include local files that UIWebView handles (like Word docs
//    // and PowerPoint files), or remote URLs (like web pages).
//    //  We don't want remote web pages to alert to the user (e.g. "Image not found!")
//    // so we override the javascript "alert()" function to do nothing.
//    if(webview) {
//        NSString *javascript = @""
//        "window.alert = function(s) { "
//        "   console.log('Javascript Alert: ' + s);"
//        "};";
//        
//        NSString *result = [webview stringByEvaluatingJavaScriptFromString:javascript];
//        MMLog(@"Javascript injection returned: %@", result);
//    }
//}


#pragma mark - UIWebViewDelegate


//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    [self overrideJSAlertForWebview:webView];
//    return YES;
//}
//
//- (void)webViewDidStartLoad:(UIWebView *)webView
//{
//    [self overrideJSAlertForWebview:webView];
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    MMLog(@"webViewDidFinishLoad: %@", [webView request]);
//    [self overrideJSAlertForWebview:webView];
//    
//    //  webViewDidFinishLoad: actually gets called multiple times for redirects and ajax
//    // requests.  Make sure the "isLoading" property is false to find the real conclusion.
//    if(webView && [webView isLoading]) {
//        return;
//    }
//    
//    UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, self.webView.opaque, 0.0);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    [self.webView.layer renderInContext:context];
//    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    [self finishWithImage:thumbnail];
//}
//
//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
//{
//    MMLog(@"didFailLoadWithError: %@", error);
//    [self finishWithImage:nil];
//}

@end


@implementation MGFilePreviewDefinition

- (id)initWithContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets
{
    if ((self = [super init]))
    {
        self.contentVersion = contentVersion;
        self.size = size;
        self.backgroundColor = backgroundColor;
        self.borderColor = borderColor;
        self.borderOutsets = borderOutsets;
    }
    return self;
}

@end
