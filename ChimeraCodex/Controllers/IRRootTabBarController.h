#import <UIKit/UIKit.h>

@class IRAppContainer;

@interface IRRootTabBarController : UITabBarController

- (instancetype)initWithContainer:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
