#import <UIKit/UIKit.h>

@class IRPage;

@interface IRPageRenderer : NSObject

+ (UIImage *)coverImageForTitle:(NSString *)title subtitle:(NSString *)subtitle size:(CGSize)size;
+ (UIImage *)imageForPage:(IRPage *)page size:(CGSize)size;

@end
