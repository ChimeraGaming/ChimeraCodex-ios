#import "IRRemoteImageCache.h"

#import <CommonCrypto/CommonDigest.h>
#import <string.h>

static const NSUInteger IRRemoteImageCacheMaximumCount = 64;
static const unsigned long long IRRemoteImageCacheMaximumDiskBytes = 32ull * 1024ull * 1024ull;
static const NSTimeInterval IRRemoteImageCacheMaximumAge = 60.0 * 60.0 * 24.0 * 7.0;

@interface IRRemoteImageCache ()

@property (nonatomic, copy) NSString *cacheDirectoryPath;
@property (nonatomic, strong) NSCache *memoryCache;

@end

@implementation IRRemoteImageCache

- (instancetype)initWithCacheFolderName:(NSString *)cacheFolderName {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.countLimit = IRRemoteImageCacheMaximumCount;
        _cacheDirectoryPath = [[self.class baseCacheDirectory] stringByAppendingPathComponent:cacheFolderName];
        [self createCacheDirectoryIfNeeded];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemoryCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIImage *)cachedImageForKey:(NSString *)key {
    if (key.length == 0) {
        return nil;
    }

    UIImage *memoryImage = [self.memoryCache objectForKey:key];
    if (memoryImage != nil) {
        return memoryImage;
    }

    NSString *filePath = [self filePathForKey:key];
    NSData *imageData = [NSData dataWithContentsOfFile:filePath];
    if (imageData.length == 0) {
        return nil;
    }

    UIImage *diskImage = [UIImage imageWithData:imageData];
    if (diskImage != nil) {
        [self.memoryCache setObject:diskImage forKey:key];
    }
    return diskImage;
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    if (image == nil || key.length == 0) {
        return;
    }

    [self.memoryCache setObject:image forKey:key];
    NSString *filePath = [self filePathForKey:key];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *pngData = UIImagePNGRepresentation(image);
        NSData *imageData = pngData ?: UIImageJPEGRepresentation(image, 0.9);
        if (imageData.length == 0) {
            return;
        }

        [imageData writeToFile:filePath atomically:YES];
        [self touchFileAtPath:filePath];
        [self cleanupIfNeeded];
    });
}

- (void)clearMemoryCache {
    [self.memoryCache removeAllObjects];
}

- (void)cleanupIfNeeded {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self removeExpiredFiles];
        [self trimDiskUsageIfNeeded];
    });
}

+ (NSString *)baseCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject ?: NSTemporaryDirectory();
}

- (void)createCacheDirectoryIfNeeded {
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDirectoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

- (void)touchFileAtPath:(NSString *)filePath {
    NSDictionary *attributes = @{NSFileModificationDate: [NSDate date]};
    [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:filePath error:nil];
}

- (void)removeExpiredFiles {
    NSArray<NSURL *> *fileURLs = [self cachedFileURLs];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-IRRemoteImageCacheMaximumAge];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSURL *fileURL in fileURLs) {
        NSDate *modificationDate = nil;
        [fileURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
        if (modificationDate != nil && [modificationDate compare:expirationDate] == NSOrderedAscending) {
            [fileManager removeItemAtURL:fileURL error:nil];
        }
    }
}

- (void)trimDiskUsageIfNeeded {
    NSArray<NSURL *> *fileURLs = [self cachedFileURLs];
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];
    unsigned long long totalBytes = 0;

    for (NSURL *fileURL in fileURLs) {
        NSNumber *fileSize = nil;
        NSDate *modificationDate = nil;
        [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        [fileURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
        unsigned long long bytes = [fileSize unsignedLongLongValue];
        totalBytes += bytes;
        [entries addObject:@{
            @"url": fileURL,
            @"bytes": @(bytes),
            @"date": modificationDate ?: [NSDate distantPast]
        }];
    }

    if (totalBytes <= IRRemoteImageCacheMaximumDiskBytes) {
        return;
    }

    [entries sortUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"date"] compare:right[@"date"]];
    }];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSDictionary *entry in entries) {
        if (totalBytes <= IRRemoteImageCacheMaximumDiskBytes) {
            break;
        }

        NSURL *fileURL = entry[@"url"];
        [fileManager removeItemAtURL:fileURL error:nil];
        totalBytes -= [entry[@"bytes"] unsignedLongLongValue];
    }
}

- (NSArray<NSURL *> *)cachedFileURLs {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSURL *> *urls = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.cacheDirectoryPath]
                                        includingPropertiesForKeys:@[NSURLContentModificationDateKey, NSURLFileSizeKey]
                                                           options:0
                                                             error:nil];
    return urls ?: @[];
}

- (NSString *)filePathForKey:(NSString *)key {
    NSString *fileName = [NSString stringWithFormat:@"%@.img", [self.class MD5HashForString:key]];
    return [self.cacheDirectoryPath stringByAppendingPathComponent:fileName];
}

+ (NSString *)MD5HashForString:(NSString *)string {
    const char *bytes = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(bytes, (CC_LONG)strlen(bytes), digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger index = 0; index < CC_MD5_DIGEST_LENGTH; index++) {
        [output appendFormat:@"%02x", digest[index]];
    }
    return output;
}

@end
