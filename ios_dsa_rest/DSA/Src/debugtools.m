#import "debugtools.h"

/////////////////////////////////////////////
//
/////////////////////////////////////////////
void dumpViews(UIView* view, NSString *text, NSString *indent) 
{
    Class cl = [view class];
    NSString *classDescription = [cl description];
    while ([cl superclass]) 
    {
        cl = [cl superclass];
        classDescription = [classDescription stringByAppendingFormat:@":%@", [cl description]];
    }
    
    if ([text compare:@""] == NSOrderedSame)
        NSLog(@"%@ %@ h=%@ a=%.02f", classDescription, NSStringFromCGRect(view.frame),view.hidden ? @"yes" : @"no",view.alpha);
    else
    {
        if ([view isKindOfClass:[UIScrollView class]])
        {
            UIScrollView* sv = (UIScrollView*) view;
            NSLog(@"%@ %@ %@  h=%@ a=%.02f sz=%@ offset=%@", text, classDescription, NSStringFromCGRect(view.frame),view.hidden ? @"yes" : @"no",view.alpha,
                  NSStringFromCGSize(sv.contentSize),NSStringFromCGPoint(sv.contentOffset));
            
        }
        else
        {
            NSLog(@"%@ %@ %@  h=%@ a=%.02f", text, classDescription, NSStringFromCGRect(view.frame),view.hidden ? @"yes" : @"no",view.alpha);
        }
    }
    
    for (NSUInteger i = 0; i < [view.subviews count]; i++)
    {
        UIView *subView = [view.subviews objectAtIndex:i];
        NSString *newIndent = [[NSString alloc] initWithFormat:@"  %@", indent];
        NSString *msg = [[NSString alloc] initWithFormat:@"%@%d:", newIndent, (UInt16) i];
        dumpViews(subView, msg, newIndent);
    }
}
