#import <UIKit/UIKit.h>

@class IRAppContainer;

@interface IRSourcesViewController : UITableViewController

- (instancetype)initWithContainer:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
