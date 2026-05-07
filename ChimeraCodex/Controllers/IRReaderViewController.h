#import <UIKit/UIKit.h>

@class IRAppContainer;
@class IRChapter;
@class IRManga;

@interface IRReaderViewController : UIViewController

- (instancetype)initWithManga:(IRManga *)manga
                      chapter:(IRChapter *)chapter
                    container:(IRAppContainer *)container NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
