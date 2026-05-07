#import <Foundation/Foundation.h>

@class IRChapter;
@class IRManga;
@class IRPage;

typedef void (^IRSourceCatalogCompletion)(NSArray<IRManga *> *mangaList, NSError *error);
typedef void (^IRSourceChaptersCompletion)(NSArray<IRChapter *> *chapters, NSError *error);
typedef void (^IRSourcePagesCompletion)(NSArray<IRPage *> *pages, NSError *error);

@protocol IRSourceProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;

- (void)fetchCatalogWithCompletion:(IRSourceCatalogCompletion)completion;
- (void)fetchChaptersForManga:(IRManga *)manga completion:(IRSourceChaptersCompletion)completion;
- (void)fetchPagesForManga:(IRManga *)manga chapter:(IRChapter *)chapter completion:(IRSourcePagesCompletion)completion;

@optional
- (NSArray<NSHTTPCookie *> *)cookiesForRequestURL:(NSURL *)requestURL;
- (NSDictionary<NSString *, NSString *> *)headersForCoverURLString:(NSString *)coverURLString manga:(IRManga *)manga;
- (NSDictionary<NSString *, NSString *> *)headersForPage:(IRPage *)page manga:(IRManga *)manga chapter:(IRChapter *)chapter;

@end
