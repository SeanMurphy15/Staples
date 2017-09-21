//
//  EmailSubjectController.m
//  DSA
//
//  Created by Adam Walters on 9/6/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "EmailSubjectController.h"
#import "EmailSubjectTableViewCell.h"

typedef NS_ENUM(NSInteger, EmailSubjectType) {
    EmailSubjectTypeMeetingRecap = 0,
    EmailSubjectTypeMeetingFollowUp,
    EmailSubjectTypeMeetingOverview,
    EmailSubjectTypeOther
};

@interface EmailSubjectController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation EmailSubjectController


+ (EmailSubjectController *)creaetEmailSubjectController {
    EmailSubjectController *controller = [[EmailSubjectController alloc] init];

	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    return controller;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *items = [[self.toolbar items] mutableCopy];

    UIBarButtonItem *leftSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:leftSpacer];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Select Email Subject";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [titleLabel sizeToFit];

    UIBarButtonItem *titleBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    [items addObject:titleBarButtonItem];

    UIBarButtonItem *rightSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:rightSpacer];

    self.toolbar.items = items;
}

- (IBAction)cancelTapped:(id)sender {
    [self.delegate emailSubjectCanceled];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"EmailSubjectTableViewCell" owner:self options:nil];

    EmailSubjectTableViewCell *cell = (EmailSubjectTableViewCell *)views[0];

    cell.label.text = [self subjectForEmailSubjectType:indexPath.row];

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *subject;

    switch (indexPath.row) {
        case EmailSubjectTypeOther:
            subject = @"";
            break;
        default:
            subject = [self subjectForEmailSubjectType:indexPath.row];
    }

    [self.delegate emailSubjectSelected:subject];
}

- (NSString *)subjectForEmailSubjectType:(EmailSubjectType)type {
    switch (type) {
        case EmailSubjectTypeMeetingRecap:
            return @"Staples Business Advantage Meeting Recap";
        case EmailSubjectTypeMeetingFollowUp:
            return @"Staples Business Advantage Meeting Follow Up";
        case EmailSubjectTypeMeetingOverview:
            return @"Staples Business Advantage Meeting Overview";
        case EmailSubjectTypeOther:
            return @"Other";
    }
}

@end
