#import <UIKit/UIKit.h>

@class IRChapter;
@class IRManga;
@class IRPage;
@class IRRemoteImageCache;
@protocol IRSourceProtocol;

typedef void (^IRRemoteImageLoaderCompletion)(UIImage *image, NSError *error);

@interface IRRemoteImageLoader : NSObject

- (instancetype)initWithCache:(IRRemoteImageCache *)cache
         sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)cancelRequestWithIdentifier:(NSString *)requestIdentifier;
- (void)cancelRequestsWithPrefix:(NSString *)requestPrefix;
- (NSString *)loadCoverForManga:(IRManga *)manga
                         source:(id<IRSourceProtocol>)source
                     targetSize:(CGSize)targetSize
                   requestGroup:(NSString *)requestGroup
                     completion:(IRRemoteImageLoaderCompletion)completion;
- (NSString *)loadImageForPage:(IRPage *)page
                         manga:(IRManga *)manga
                       chapter:(IRChapter *)chapter
                        source:(id<IRSourceProtocol>)source
                    targetSize:(CGSize)targetSize
                  requestGroup:(NSString *)requestGroup
                    completion:(IRRemoteImageLoaderCompletion)completion;
- (void)prefetchPages:(NSArray<IRPage *> *)pages
            fromIndex:(NSUInteger)index
                manga:(IRManga *)manga
              chapter:(IRChapter *)chapter
               source:(id<IRSourceProtocol>)source
           targetSize:(CGSize)targetSize
         requestGroup:(NSString *)requestGroup;

@end
