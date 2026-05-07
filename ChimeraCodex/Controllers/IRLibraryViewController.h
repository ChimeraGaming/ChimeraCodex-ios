#import <UIKit/UIKit.h>

@class IRAppContainer;

@interface IRLibraryViewController : UITableViewController

- (instancetype)initWithContainer:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
