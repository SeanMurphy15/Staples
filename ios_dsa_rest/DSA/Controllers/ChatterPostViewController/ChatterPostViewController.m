//
//  ChatterPostViewController.m
//  ios_dsa
//
//  Created by Guy Umbright on 10/24/12.
//
//

#import "ChatterPostViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface ChatterPostViewController ()
@property (nonatomic, weak) IBOutlet UITextView* postBody;
@property (nonatomic, strong) IBOutlet UIView* detailContainer;  //???

//content detail
@property (nonatomic, strong) IBOutlet UIView* contentDetail;  //???
@property (nonatomic, weak) IBOutlet UIImageView* docImage;
@property (nonatomic, weak) IBOutlet UILabel* docTitle;

//link detail
@property (nonatomic, strong) IBOutlet UIView* linkDetail;  //???
@property (nonatomic, weak) IBOutlet UILabel* linkTitle;
@property (nonatomic, weak) IBOutlet UILabel* linkURL;
@end

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
@implementation ChatterPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (CGSize) contentSizeForViewInPopover
{
    return CGSizeMake(400.0, 315.0);
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.postBody becomeFirstResponder];

    self.contentSizeForViewInPopover = CGSizeMake(400.0, 315.0);

    if ([self.item isLinkContent])
    {
        [self.detailContainer addSubview:self.linkDetail];
        self.linkTitle.text = self.item.Title;
        self.linkURL.text = self.item.ContentUrl;
    }
    else
    {
        [self.detailContainer addSubview:self.contentDetail];
        self.docTitle.text = self.item.Title;
        
        CGSize thumbSize = CGSizeMake(200.f, 200.f);
        __weak typeof(self) weakSelf = self;
        [self.item generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
            weakSelf.docImage.image = image;
        }];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.contentSizeForViewInPopover = CGSizeMake(400.0, 315.0);
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [self.containerPopoverController setPopoverContentSize:self.contentSizeForViewInPopover animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelPressed:(id)sender
{
    [self.chatterPostDelegate chatterPostViewControllerCancelPressed:self];
}

- (IBAction)donePressed:(id)sender
{
    [self.chatterPostDelegate chatterPostViewController:self donePressedWithPostBody:self.postBody.text];
}

@end

#pragma clang diagnostic pop
