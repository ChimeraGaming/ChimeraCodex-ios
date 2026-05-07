#import <UIKit/UIKit.h>

@interface IRMangaTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *representedMangaID;

+ (CGFloat)preferredHeight;
- (void)applyCoverImage:(UIImage *)image;
- (void)applyTitle:(NSString *)title
          metadata:(NSString *)metadata
           summary:(NSString *)summary
          progress:(NSString *)progress;

@end
