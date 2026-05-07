#import "IRRemoteImageLoader.h"

#import <math.h>

#import "IRChapter.h"
#import "IRManga.h"
#import "IRPage.h"
#import "IRPageRenderer.h"
#import "IRRemoteImageCache.h"
#import "IRSourceProtocol.h"

static NSString *const IRRemoteImageLoaderErrorDomain = @"IRRemoteImageLoaderErrorDomain";

@interface IRRemoteImageLoader ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDataTask *> *activeTasksByCacheKey;
@property (nonatomic, strong) IRRemoteImageCache *cache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *listenersByCacheKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *requestToCacheKey;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation IRRemoteImageLoader

- (instancetype)initWithCache:(IRRemoteImageCache *)cache
         sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    self = [super init];
    if (self) {
        _cache = cache;
        _listenersByCacheKey = [NSMutableDictionary dictionary];
        _requestToCacheKey = [NSMutableDictionary dictionary];
        _activeTasksByCacheKey = [NSMutableDictionary dictionary];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration ?: [NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (NSString *)loadCoverForManga:(IRManga *)manga
                         source:(id<IRSourceProtocol>)source
                     targetSize:(CGSize)targetSize
                   requestGroup:(NSString *)requestGroup
                     completion:(IRRemoteImageLoaderCompletion)completion {
    UIImage *fallbackImage = [IRPageRenderer coverImageForTitle:manga.name subtitle:manga.genreText size:targetSize];
    NSDictionary *headers = nil;
    if ([source respondsToSelector:@selector(headersForCoverURLString:manga:)]) {
        headers = [source headersForCoverURLString:manga.coverImageURLString manga:manga];
    }
    return [self loadImageWithURLString:manga.coverImageURLString
                               cacheKey:[NSString stringWithFormat:@"cover|%@|%.0fx%.0f", manga.coverImageURLString ?: @"", targetSize.width, targetSize.height]
                             targetSize:targetSize
                           requestGroup:requestGroup
                                headers:headers
                                cookies:[self cookiesForURLString:manga.coverImageURLString source:source]
                           fallbackImage:fallbackImage
                             completion:completion];
}

- (NSString *)loadImageForPage:(IRPage *)page
                         manga:(IRManga *)manga
                       chapter:(IRChapter *)chapter
                        source:(id<IRSourceProtocol>)source
                    targetSize:(CGSize)targetSize
                  requestGroup:(NSString *)requestGroup
                    completion:(IRRemoteImageLoaderCompletion)completion {
    UIImage *fallbackImage = [IRPageRenderer imageForPage:page size:targetSize];
    NSDictionary *headers = nil;
    if ([source respondsToSelector:@selector(headersForPage:manga:chapter:)]) {
        headers = [source headersForPage:page manga:manga chapter:chapter];
    }
    return [self loadImageWithURLString:page.remoteImageURLString
                               cacheKey:[NSString stringWithFormat:@"page|%@|%.0fx%.0f", page.remoteImageURLString ?: @"", targetSize.width, targetSize.height]
                             targetSize:targetSize
                           requestGroup:requestGroup
                                headers:headers
                                cookies:[self cookiesForURLString:page.remoteImageURLString source:source]
                           fallbackImage:fallbackImage
                             completion:completion];
}

- (void)prefetchPages:(NSArray<IRPage *> *)pages
            fromIndex:(NSUInteger)index
                manga:(IRManga *)manga
              chapter:(IRChapter *)chapter
               source:(id<IRSourceProtocol>)source
           targetSize:(CGSize)targetSize
         requestGroup:(NSString *)requestGroup {
    if (pages.count == 0 || index >= pages.count) {
        return;
    }

    NSUInteger maxIndex = MIN(index + 2, pages.count - 1);
    for (NSUInteger pageIndex = index; pageIndex <= maxIndex; pageIndex++) {
        IRPage *page = pages[pageIndex];
        [self loadImageForPage:page
                         manga:manga
                       chapter:chapter
                        source:source
                    targetSize:targetSize
                  requestGroup:[NSString stringWithFormat:@"%@.prefetch", requestGroup ?: @"prefetch"]
                    completion:nil];
    }
}

- (void)cancelRequestWithIdentifier:(NSString *)requestIdentifier {
    if (requestIdentifier.length == 0) {
        return;
    }

    NSString *cacheKey = nil;
    @synchronized (self) {
        cacheKey = self.requestToCacheKey[requestIdentifier];
        if (cacheKey.length == 0) {
            return;
        }

        NSMutableDictionary *listeners = self.listenersByCacheKey[cacheKey];
        [listeners removeObjectForKey:requestIdentifier];
        [self.requestToCacheKey removeObjectForKey:requestIdentifier];

        if (listeners.count == 0) {
            NSURLSessionDataTask *task = self.activeTasksByCacheKey[cacheKey];
            [task cancel];
            [self.activeTasksByCacheKey removeObjectForKey:cacheKey];
            [self.listenersByCacheKey removeObjectForKey:cacheKey];
        }
    }
}

- (void)cancelRequestsWithPrefix:(NSString *)requestPrefix {
    if (requestPrefix.length == 0) {
        return;
    }

    NSArray<NSString *> *allRequestIDs = nil;
    @synchronized (self) {
        allRequestIDs = [self.requestToCacheKey allKeys];
    }

    for (NSString *requestID in allRequestIDs) {
        if ([requestID hasPrefix:requestPrefix]) {
            [self cancelRequestWithIdentifier:requestID];
        }
    }
}

- (NSString *)loadImageWithURLString:(NSString *)URLString
                            cacheKey:(NSString *)cacheKey
                          targetSize:(CGSize)targetSize
                        requestGroup:(NSString *)requestGroup
                             headers:(NSDictionary<NSString *, NSString *> *)headers
                             cookies:(NSArray<NSHTTPCookie *> *)cookies
                        fallbackImage:(UIImage *)fallbackImage
                          completion:(IRRemoteImageLoaderCompletion)completion {
    NSString *requestID = [self requestIdentifierForGroup:requestGroup];
    IRRemoteImageLoaderCompletion completionBlock = completion != nil ? [completion copy] : [^(UIImage *image, NSError *error) {
        (void)image;
        (void)error;
    } copy];

    UIImage *cachedImage = [self.cache cachedImageForKey:cacheKey];
    if (cachedImage != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(cachedImage, nil);
        });
        return requestID;
    }

    NSURL *URL = [NSURL URLWithString:URLString ?: @""];
    if (URL == nil) {
        NSError *error = [NSError errorWithDomain:IRRemoteImageLoaderErrorDomain code:1 userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(fallbackImage, error);
        });
        return requestID;
    }

    BOOL shouldStartRequest = NO;
    @synchronized (self) {
        NSMutableDictionary *listeners = self.listenersByCacheKey[cacheKey];
        if (listeners == nil) {
            listeners = [NSMutableDictionary dictionary];
            self.listenersByCacheKey[cacheKey] = listeners;
            shouldStartRequest = YES;
        }

        listeners[requestID] = completionBlock;
        self.requestToCacheKey[requestID] = cacheKey;
    }

    if (!shouldStartRequest) {
        return requestID;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    request.HTTPShouldHandleCookies = NO;

    if (URL.isFileURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:URL];
            UIImage *resultImage = nil;
            NSError *resultError = nil;
            if (data.length > 0) {
                UIImage *downloadedImage = [UIImage imageWithData:data];
                if (downloadedImage != nil) {
                    resultImage = [self scaledImage:downloadedImage targetSize:targetSize];
                    [self.cache storeImage:resultImage forKey:cacheKey];
                }
            }

            if (resultImage == nil) {
                resultError = [NSError errorWithDomain:IRRemoteImageLoaderErrorDomain code:3 userInfo:nil];
                resultImage = fallbackImage;
            }

            [self finishListenersForCacheKey:cacheKey image:resultImage error:resultError];
        });
        return requestID;
    }

    for (NSString *headerKey in headers) {
        [request setValue:headers[headerKey] forHTTPHeaderField:headerKey];
    }

    if (cookies.count > 0) {
        NSDictionary *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        for (NSString *headerKey in cookieHeaders) {
            [request setValue:cookieHeaders[headerKey] forHTTPHeaderField:headerKey];
        }
    }

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *resultImage = nil;
        NSError *resultError = error;

        if (data.length > 0) {
            UIImage *downloadedImage = [UIImage imageWithData:data];
            if (downloadedImage != nil) {
                resultImage = [weakSelf scaledImage:downloadedImage targetSize:targetSize];
                [weakSelf.cache storeImage:resultImage forKey:cacheKey];
            }
        }

        if (resultImage == nil) {
            if (resultError == nil) {
                resultError = [NSError errorWithDomain:IRRemoteImageLoaderErrorDomain code:2 userInfo:nil];
            }
            resultImage = fallbackImage;
        }

        [weakSelf finishListenersForCacheKey:cacheKey image:resultImage error:resultError];
        (void)response;
    }];

    @synchronized (self) {
        self.activeTasksByCacheKey[cacheKey] = task;
    }
    [task resume];
    return requestID;
}

- (NSArray<NSHTTPCookie *> *)cookiesForURLString:(NSString *)URLString source:(id<IRSourceProtocol>)source {
    NSURL *URL = [NSURL URLWithString:URLString ?: @""];
    if (URL == nil || ![source respondsToSelector:@selector(cookiesForRequestURL:)]) {
        return @[];
    }
    return [source cookiesForRequestURL:URL] ?: @[];
}

- (NSString *)requestIdentifierForGroup:(NSString *)requestGroup {
    NSString *group = requestGroup.length > 0 ? requestGroup : @"image";
    return [NSString stringWithFormat:@"%@.%@", group, [[NSUUID UUID] UUIDString]];
}

- (UIImage *)scaledImage:(UIImage *)image targetSize:(CGSize)targetSize {
    if (targetSize.width <= 0.0 || targetSize.height <= 0.0) {
        return image;
    }

    CGSize imageSize = image.size;
    if (imageSize.width <= 0.0 || imageSize.height <= 0.0) {
        return image;
    }

    CGFloat scale = MIN(targetSize.width / imageSize.width, targetSize.height / imageSize.height);
    CGSize fittedSize = CGSizeMake(floor(imageSize.width * scale), floor(imageSize.height * scale));
    CGRect drawRect = CGRectMake(floor((targetSize.width - fittedSize.width) * 0.5),
                                 floor((targetSize.height - fittedSize.height) * 0.5),
                                 fittedSize.width,
                                 fittedSize.height);

    UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0.0);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0.0, 0.0, targetSize.width, targetSize.height));
    [image drawInRect:drawRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage ?: image;
}

- (void)finishListenersForCacheKey:(NSString *)cacheKey image:(UIImage *)image error:(NSError *)error {
    NSDictionary *listeners = nil;
    @synchronized (self) {
        listeners = [[self.listenersByCacheKey objectForKey:cacheKey] copy];
        [self.activeTasksByCacheKey removeObjectForKey:cacheKey];
        [self.listenersByCacheKey removeObjectForKey:cacheKey];
        for (NSString *requestID in listeners) {
            [self.requestToCacheKey removeObjectForKey:requestID];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        for (id listener in [listeners allValues]) {
            IRRemoteImageLoaderCompletion completionBlock = (IRRemoteImageLoaderCompletion)listener;
            completionBlock(image, error);
        }
    });
}

@end
