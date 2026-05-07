#import <UIKit/UIKit.h>

@interface IRRemoteImageCache : NSObject

- (instancetype)initWithCacheFolderName:(NSString *)cacheFolderName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (UIImage *)cachedImageForKey:(NSString *)key;
- (void)cleanupIfNeeded;
- (void)clearMemoryCache;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

@end
