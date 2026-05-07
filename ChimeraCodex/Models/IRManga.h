#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IRMangaStatus) {
    IRMangaStatusOngoing = 0,
    IRMangaStatusComplete = 1,
    IRMangaStatusHiatus = 2
};

@interface IRManga : NSObject

@property (nonatomic, copy, readonly) NSString *coverImageURLString;
@property (nonatomic, assign, readonly) NSInteger estimatedChapterCount;
@property (nonatomic, copy, readonly) NSString *genreText;
@property (nonatomic, copy, readonly) NSString *latestChapterTitle;
@property (nonatomic, copy, readonly) NSString *mangaID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;
@property (nonatomic, assign, readonly) IRMangaStatus status;
@property (nonatomic, copy, readonly) NSString *summary;

- (instancetype)initWithMangaID:(NSString *)mangaID
                sourceIdentifier:(NSString *)sourceIdentifier
                           name:(NSString *)name
                        summary:(NSString *)summary
                    latestChapterTitle:(NSString *)latestChapterTitle
                      coverImageURLString:(NSString *)coverImageURLString
                        estimatedChapterCount:(NSInteger)estimatedChapterCount
                              genreText:(NSString *)genreText
                                 status:(IRMangaStatus)status NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)statusText;

@end
