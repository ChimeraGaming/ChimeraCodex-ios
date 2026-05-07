#import "IRPageRenderer.h"

#import "IRPage.h"

@implementation IRPageRenderer

+ (UIImage *)coverImageForTitle:(NSString *)title subtitle:(NSString *)subtitle size:(CGSize)size {
    CGRect bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);

    [[UIColor colorWithRed:0.16 green:0.23 blue:0.34 alpha:1.0] setFill];
    UIRectFill(bounds);

    CGRect insetRect = CGRectInset(bounds, 8.0, 8.0);
    [[UIColor colorWithRed:0.94 green:0.91 blue:0.83 alpha:1.0] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:10.0] fill];

    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.11 green:0.18 blue:0.25 alpha:1.0]
    };
    [title drawInRect:CGRectMake(CGRectGetMinX(insetRect) + 12.0,
                                 CGRectGetMinY(insetRect) + 18.0,
                                 CGRectGetWidth(insetRect) - 24.0,
                                 72.0)
       withAttributes:titleAttributes];

    NSDictionary *subtitleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.30 green:0.35 blue:0.39 alpha:1.0]
    };
    [subtitle drawInRect:CGRectMake(CGRectGetMinX(insetRect) + 12.0,
                                    CGRectGetMaxY(insetRect) - 48.0,
                                    CGRectGetWidth(insetRect) - 24.0,
                                    32.0)
          withAttributes:subtitleAttributes];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)imageForPage:(IRPage *)page size:(CGSize)size {
    CGRect bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0.0);

    [[UIColor colorWithRed:0.95 green:0.93 blue:0.87 alpha:1.0] setFill];
    UIRectFill(bounds);

    CGRect sheetRect = CGRectInset(bounds, 18.0, 18.0);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:sheetRect cornerRadius:10.0] fill];

    NSDictionary *badgeAttributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.18 green:0.23 blue:0.30 alpha:1.0]
    };

    NSString *badgeText = [NSString stringWithFormat:@"Page %@", @(page.pageNumber)];
    [badgeText drawInRect:CGRectMake(CGRectGetMinX(sheetRect) + 20.0, CGRectGetMinY(sheetRect) + 20.0, CGRectGetWidth(sheetRect) - 40.0, 28.0)
           withAttributes:badgeAttributes];

    NSDictionary *headlineAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:30.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.13 green:0.20 blue:0.27 alpha:1.0]
    };

    [page.headline drawInRect:CGRectMake(CGRectGetMinX(sheetRect) + 20.0, CGRectGetMinY(sheetRect) + 64.0, CGRectGetWidth(sheetRect) - 40.0, 72.0)
               withAttributes:headlineAttributes];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8.0;

    NSDictionary *bodyAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:20.0],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.28 green:0.31 blue:0.34 alpha:1.0],
        NSParagraphStyleAttributeName: paragraphStyle
    };

    NSString *body = [NSString stringWithFormat:@"%@\n\n%@\n\n%@",
                      page.bodyText,
                      @"This fallback page stays usable when the source image is unavailable.",
                      @"For older devices, keep images scaled, release offscreen pages early, and limit concurrent requests."];

    CGRect bodyRect = CGRectMake(CGRectGetMinX(sheetRect) + 20.0, CGRectGetMinY(sheetRect) + 164.0, CGRectGetWidth(sheetRect) - 40.0, CGRectGetHeight(sheetRect) - 190.0);
    [body drawInRect:bodyRect withAttributes:bodyAttributes];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
