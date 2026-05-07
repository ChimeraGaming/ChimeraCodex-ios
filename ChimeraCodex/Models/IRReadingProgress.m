#import "IRReadingProgress.h"

@implementation IRReadingProgress

- (instancetype)initWithMangaID:(NSString *)mangaID
               sourceIdentifier:(NSString *)sourceIdentifier
                      mangaName:(NSString *)mangaName
                      chapterID:(NSString *)chapterID
                   chapterTitle:(NSString *)chapterTitle
                    currentPage:(NSInteger)currentPage
                     totalPages:(NSInteger)totalPages
                      updatedAt:(NSDate *)updatedAt {
    self = [super init];
    if (self) {
        _mangaID = [mangaID copy];
        _sourceIdentifier = [sourceIdentifier copy];
        _mangaName = [mangaName copy];
        _chapterID = [chapterID copy];
        _chapterTitle = [chapterTitle copy];
        _currentPage = currentPage;
        _totalPages = totalPages;
        _updatedAt = updatedAt ?: [NSDate date];
    }
    return self;
}

+ (instancetype)progressWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSNumber *timestamp = dictionary[@"updatedAt"];
    NSDate *updatedAt = [timestamp isKindOfClass:[NSNumber class]] ? [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]] : [NSDate date];
    return [[IRReadingProgress alloc] initWithMangaID:dictionary[@"mangaID"] ?: @""
                                     sourceIdentifier:dictionary[@"sourceIdentifier"] ?: @""
                                            mangaName:dictionary[@"mangaName"] ?: @""
                                            chapterID:dictionary[@"chapterID"] ?: @""
                                         chapterTitle:dictionary[@"chapterTitle"] ?: @""
                                          currentPage:[dictionary[@"currentPage"] integerValue]
                                           totalPages:[dictionary[@"totalPages"] integerValue]
                                            updatedAt:updatedAt];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"mangaID": self.mangaID ?: @"",
        @"sourceIdentifier": self.sourceIdentifier ?: @"",
        @"mangaName": self.mangaName ?: @"",
        @"chapterID": self.chapterID ?: @"",
        @"chapterTitle": self.chapterTitle ?: @"",
        @"currentPage": @(self.currentPage),
        @"totalPages": @(self.totalPages),
        @"updatedAt": @([self.updatedAt timeIntervalSince1970])
    };
}

- (BOOL)isComplete {
    return self.totalPages > 0 && self.currentPage >= self.totalPages;
}

- (NSString *)progressText {
    if (self.chapterTitle.length == 0) {
        return @"No progress";
    }

    NSString *state = [self isComplete] ? @"Finished" : @"Continue";
    return [NSString stringWithFormat:@"%@  %@  Page %@ of %@",
            state,
            self.chapterTitle,
            @(MAX(self.currentPage, 1)),
            @(MAX(self.totalPages, 1))];
}

@end
