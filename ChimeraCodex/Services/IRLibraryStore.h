#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const IRLibraryStoreDidChangeNotification;

@class IRReaderSettings;
@class IRReadingProgress;

@interface IRLibraryStore : NSObject

- (NSArray<IRReadingProgress *> *)allReadingProgress;
- (NSString *)activeSourceIdentifier;
- (BOOL)isSavedMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier;
- (IRReaderSettings *)readerSettings;
- (IRReadingProgress *)readingProgressForMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier;
- (NSArray<NSString *> *)savedMangaIDsForSourceIdentifier:(NSString *)sourceIdentifier;
- (void)saveActiveSourceIdentifier:(NSString *)sourceIdentifier;
- (void)saveReaderSettings:(IRReaderSettings *)settings;
- (void)saveReadingProgressForMangaID:(NSString *)mangaID
                     sourceIdentifier:(NSString *)sourceIdentifier
                            mangaName:(NSString *)mangaName
                            chapterID:(NSString *)chapterID
                         chapterTitle:(NSString *)chapterTitle
                          currentPage:(NSInteger)currentPage
                           totalPages:(NSInteger)totalPages;
- (void)setSaved:(BOOL)saved forMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier;

@end
