#import <UIKit/UIKit.h>

@class IRAppContainer;
@class IRManga;

@interface IRMangaDetailViewController : UITableViewController

- (instancetype)initWithManga:(IRManga *)manga container:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
