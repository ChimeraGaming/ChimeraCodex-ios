#import <Foundation/Foundation.h>

@class IRLibraryStore;
@class IRRemoteImageLoader;
@class IRSourceRecord;
@class IRSourceRegistry;
@protocol IRSourceProtocol;

FOUNDATION_EXPORT NSString *const IRAppContainerSourceDidChangeNotification;

@interface IRAppContainer : NSObject

@property (nonatomic, strong, readonly) IRRemoteImageLoader *imageLoader;
@property (nonatomic, strong, readonly) IRLibraryStore *libraryStore;
@property (nonatomic, strong, readonly) id<IRSourceProtocol> source;
@property (nonatomic, strong, readonly) IRSourceRegistry *sourceRegistry;

- (NSArray<IRSourceRecord *> *)availableSourceRecords;
- (instancetype)initWithSourceRegistry:(IRSourceRegistry *)sourceRegistry
                          libraryStore:(IRLibraryStore *)libraryStore
                           imageLoader:(IRRemoteImageLoader *)imageLoader NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)reloadSources;
- (BOOL)selectSourceWithIdentifier:(NSString *)sourceIdentifier;
- (id<IRSourceProtocol>)sourceForIdentifier:(NSString *)sourceIdentifier;

@end
