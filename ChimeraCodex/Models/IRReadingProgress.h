#import <Foundation/Foundation.h>

@interface IRReadingProgress : NSObject

@property (nonatomic, copy, readonly) NSString *chapterID;
@property (nonatomic, copy, readonly) NSString *chapterTitle;
@property (nonatomic, assign, readonly) NSInteger currentPage;
@property (nonatomic, copy, readonly) NSString *mangaID;
@property (nonatomic, copy, readonly) NSString *mangaName;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;
@property (nonatomic, assign, readonly) NSInteger totalPages;
@property (nonatomic, strong, readonly) NSDate *updatedAt;

- (instancetype)initWithMangaID:(NSString *)mangaID
               sourceIdentifier:(NSString *)sourceIdentifier
                      mangaName:(NSString *)mangaName
                      chapterID:(NSString *)chapterID
                   chapterTitle:(NSString *)chapterTitle
                    currentPage:(NSInteger)currentPage
                     totalPages:(NSInteger)totalPages
                      updatedAt:(NSDate *)updatedAt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)progressWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
- (BOOL)isComplete;
- (NSString *)progressText;

@end
