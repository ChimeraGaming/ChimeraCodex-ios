#import "IRManga.h"

@implementation IRManga

- (instancetype)initWithMangaID:(NSString *)mangaID
                sourceIdentifier:(NSString *)sourceIdentifier
                           name:(NSString *)name
                        summary:(NSString *)summary
              latestChapterTitle:(NSString *)latestChapterTitle
            coverImageURLString:(NSString *)coverImageURLString
          estimatedChapterCount:(NSInteger)estimatedChapterCount
                      genreText:(NSString *)genreText
                         status:(IRMangaStatus)status {
    self = [super init];
    if (self) {
        _mangaID = [mangaID copy];
        _sourceIdentifier = [sourceIdentifier copy];
        _name = [name copy];
        _summary = [summary copy];
        _latestChapterTitle = [latestChapterTitle copy];
        _coverImageURLString = [coverImageURLString copy];
        _estimatedChapterCount = estimatedChapterCount;
        _genreText = [genreText copy];
        _status = status;
    }
    return self;
}

- (NSString *)statusText {
    switch (self.status) {
        case IRMangaStatusComplete:
            return @"Complete";
        case IRMangaStatusHiatus:
            return @"Hiatus";
        case IRMangaStatusOngoing:
        default:
            return @"Ongoing";
    }
}

@end
