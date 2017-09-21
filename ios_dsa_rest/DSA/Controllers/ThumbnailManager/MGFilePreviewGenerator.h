#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class MMSF_ContentVersion;

@interface MGFilePreviewGenerator : NSObject<UIWebViewDelegate>
{
    //void (^completionBlock)(UIImage *preview);
    NSMutableArray *urlQueue;
    NSDictionary *currentURLBlock;
}

#pragma mark - Init

//- (id)initWithSize:(CGSize)size;

#pragma mark - Properties

//@property(nonatomic)            CGSize           size;
//@property(nonatomic, strong)    UIWebView       *webView;
@property (nonatomic, strong)   UIImage         *noPreviewImage;
@property(readonly)             BOOL             isFinished;

#pragma mark - Methods
- (UIImage*)generatePreviewForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor;
- (void) setThumbnailFileSizeLimit: (NSUInteger)limit;
- (UIImage*)thumbnailForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets;

@end


@interface MGFilePreviewDefinition : NSObject

@property (nonatomic, strong) MMSF_ContentVersion  *contentVersion;
@property (nonatomic) CGSize                        size;
@property (nonatomic, strong) UIColor              *backgroundColor;
@property (nonatomic, strong) UIColor              *borderColor;
@property (nonatomic) UIEdgeInsets                  borderOutsets;

- (id)initWithContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets;

@end
