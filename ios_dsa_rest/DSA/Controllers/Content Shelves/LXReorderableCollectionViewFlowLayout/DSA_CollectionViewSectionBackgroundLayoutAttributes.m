//
//  DSA_CollectionViewSectionBackgroundLayoutAttributes.m
//  DSA
//
//  Created by Mike Close on 11/4/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_CollectionViewSectionBackgroundLayoutAttributes.h"
#import "DSA_ContentShelvesModel.h"

@implementation DSA_CollectionViewSectionBackgroundLayoutAttributes

- (BOOL)isEqual:(DSA_CollectionViewSectionBackgroundLayoutAttributes*)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return [self.model isEqual:other.model];
    }
}

@end
