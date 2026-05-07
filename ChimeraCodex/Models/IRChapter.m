#import "IRChapter.h"

@implementation IRChapter

- (instancetype)initWithChapterID:(NSString *)chapterID
                    chapterNumber:(NSInteger)chapterNumber
                            title:(NSString *)title
                    pageCountHint:(NSInteger)pageCountHint
                      releaseText:(NSString *)releaseText {
    self = [super init];
    if (self) {
        _chapterID = [chapterID copy];
        _chapterNumber = chapterNumber;
        _title = [title copy];
        _pageCountHint = pageCountHint;
        _releaseText = [releaseText copy];
    }
    return self;
}

@end
