#import <UIKit/UIKit.h>

@class IRAppContainer;

@interface IRCatalogViewController : UITableViewController

- (instancetype)initWithContainer:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
