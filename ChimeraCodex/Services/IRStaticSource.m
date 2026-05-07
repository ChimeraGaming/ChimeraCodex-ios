#import "IRStaticSource.h"

#import "IRChapter.h"
#import "IRManga.h"
#import "IRPage.h"

@interface IRStaticSource ()

@property (nonatomic, copy) NSArray<IRManga *> *catalog;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<IRChapter *> *> *chaptersByMangaID;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<IRPage *> *> *pagesByChapterID;

@end

@implementation IRStaticSource

- (instancetype)init {
    self = [super init];
    if (self) {
        _catalog = [self buildCatalog];
    }
    return self;
}

- (NSString *)displayName {
    return @"Demo Adapter";
}

- (NSString *)sourceIdentifier {
    return @"builtin.demo";
}

- (void)fetchCatalogWithCompletion:(IRSourceCatalogCompletion)completion {
    if (completion == nil) {
        return;
    }

    [self completeOnMainQueue:^{
        completion([self.catalog copy], nil);
    }];
}

- (void)fetchChaptersForManga:(IRManga *)manga completion:(IRSourceChaptersCompletion)completion {
    if (completion == nil) {
        return;
    }

    NSArray<IRChapter *> *chapters = self.chaptersByMangaID[manga.mangaID];
    [self completeOnMainQueue:^{
        completion(chapters ?: @[], nil);
    }];
}

- (void)fetchPagesForManga:(IRManga *)manga chapter:(IRChapter *)chapter completion:(IRSourcePagesCompletion)completion {
    if (completion == nil) {
        return;
    }

    NSArray<IRPage *> *pages = self.pagesByChapterID[chapter.chapterID];
    [self completeOnMainQueue:^{
        completion(pages ?: @[], nil);
    }];
    (void)manga;
}

- (NSDictionary<NSString *,NSString *> *)headersForCoverURLString:(NSString *)coverURLString manga:(IRManga *)manga {
    return @{
        @"Accept": @"image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        @"Referer": [NSString stringWithFormat:@"https://chimeracodex.example/%@/cover", manga.mangaID ?: @"title"],
        @"User-Agent": @"ChimeraCodex/1.0 (iPad; iOS 9 Compatible)",
        @"X-Reader-Cover": coverURLString ?: @""
    };
}

- (NSDictionary<NSString *,NSString *> *)headersForPage:(IRPage *)page manga:(IRManga *)manga chapter:(IRChapter *)chapter {
    return @{
        @"Accept": @"image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        @"Referer": [NSString stringWithFormat:@"https://chimeracodex.example/%@/%@", manga.mangaID ?: @"title", chapter.chapterID ?: @"chapter"],
        @"User-Agent": @"ChimeraCodex/1.0 (iPad; iOS 9 Compatible)",
        @"X-Reader-Page": [NSString stringWithFormat:@"%@", @(page.pageNumber)]
    };
}

- (NSArray<NSHTTPCookie *> *)cookiesForRequestURL:(NSURL *)requestURL {
    if (requestURL.host.length == 0) {
        return @[];
    }

    NSDictionary *cookieProperties = @{
        NSHTTPCookieName: @"chimera_codex_session",
        NSHTTPCookieValue: @"demo-source",
        NSHTTPCookieDomain: requestURL.host,
        NSHTTPCookiePath: @"/",
        NSHTTPCookieExpires: [NSDate dateWithTimeIntervalSinceNow:86400.0]
    };
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    return cookie != nil ? @[cookie] : @[];
}

- (void)completeOnMainQueue:(dispatch_block_t)block {
    dispatch_async(dispatch_get_main_queue(), block);
}

- (NSArray<IRManga *> *)buildCatalog {
    NSMutableArray<IRManga *> *catalog = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray<IRChapter *> *> *chaptersByMangaID = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSArray<IRPage *> *> *pagesByChapterID = [NSMutableDictionary dictionary];

    [self addMangaWithID:@"north-harbor"
                    name:@"North Harbor Files"
                 summary:@"A harbor mystery with radio logs, missing ledger pages, and late night ferry routes."
               genreText:@"Mystery  Drama"
                  status:IRMangaStatusOngoing
            chapterNames:@[@"Chapter 1: Fog Line", @"Chapter 2: Dry Dock", @"Chapter 3: Tide Report"]
                 catalog:catalog
        chaptersByMangaID:chaptersByMangaID
        pagesByChapterID:pagesByChapterID];

    [self addMangaWithID:@"paper-lantern"
                    name:@"Paper Lantern Club"
                 summary:@"A quiet school archive story about reading rooms, missing shelves, and handwritten notes."
               genreText:@"Slice of Life  School"
                  status:IRMangaStatusComplete
            chapterNames:@[@"Chapter 1: The Key Cabinet", @"Chapter 2: Quiet Hours", @"Chapter 3: The Missing Shelf"]
                 catalog:catalog
        chaptersByMangaID:chaptersByMangaID
        pagesByChapterID:pagesByChapterID];

    [self addMangaWithID:@"orbit-kitchen"
                    name:@"Orbit Kitchen"
                 summary:@"A drifting kitchen ship feeds travelers while its crew documents each stop like a travel log."
               genreText:@"Adventure  Food"
                  status:IRMangaStatusHiatus
            chapterNames:@[@"Chapter 1: Docking Bell", @"Chapter 2: Broth Log", @"Chapter 3: Last Seating"]
                 catalog:catalog
        chaptersByMangaID:chaptersByMangaID
        pagesByChapterID:pagesByChapterID];

    self.chaptersByMangaID = [chaptersByMangaID copy];
    self.pagesByChapterID = [pagesByChapterID copy];
    return [catalog copy];
}

- (void)addMangaWithID:(NSString *)mangaID
                  name:(NSString *)name
               summary:(NSString *)summary
             genreText:(NSString *)genreText
                status:(IRMangaStatus)status
          chapterNames:(NSArray<NSString *> *)chapterNames
               catalog:(NSMutableArray<IRManga *> *)catalog
      chaptersByMangaID:(NSMutableDictionary<NSString *, NSArray<IRChapter *> *> *)chaptersByMangaID
      pagesByChapterID:(NSMutableDictionary<NSString *, NSArray<IRPage *> *> *)pagesByChapterID {
    NSString *latestChapterTitle = chapterNames.lastObject ?: @"";
    NSString *coverURLString = [self placeholderCoverURLForMangaName:name genreText:genreText];
    IRManga *manga = [[IRManga alloc] initWithMangaID:mangaID
                                      sourceIdentifier:self.sourceIdentifier
                                                 name:name
                                              summary:summary
                                   latestChapterTitle:latestChapterTitle
                                 coverImageURLString:coverURLString
                               estimatedChapterCount:chapterNames.count
                                           genreText:genreText
                                              status:status];
    [catalog addObject:manga];

    NSMutableArray<IRChapter *> *chapters = [NSMutableArray array];
    [chapterNames enumerateObjectsUsingBlock:^(NSString *chapterTitle, NSUInteger index, BOOL *stop) {
        NSString *chapterID = [NSString stringWithFormat:@"%@-%@", mangaID, @((NSInteger)index + 1)];
        NSString *releaseText = [NSString stringWithFormat:@"Release %@", @((NSInteger)index + 1)];
        IRChapter *chapter = [[IRChapter alloc] initWithChapterID:chapterID
                                                    chapterNumber:(NSInteger)index + 1
                                                            title:chapterTitle
                                                    pageCountHint:6
                                                      releaseText:releaseText];
        [chapters addObject:chapter];
        pagesByChapterID[chapterID] = [self buildPagesForMangaName:name chapterTitle:chapterTitle chapterNumber:index + 1];
        (void)stop;
    }];

    chaptersByMangaID[mangaID] = [chapters copy];
}

- (NSArray<IRPage *> *)buildPagesForMangaName:(NSString *)mangaName
                                 chapterTitle:(NSString *)chapterTitle
                                chapterNumber:(NSUInteger)chapterNumber {
    NSMutableArray<IRPage *> *pages = [NSMutableArray array];

    for (NSInteger pageNumber = 1; pageNumber <= 6; pageNumber++) {
        NSString *headline = [NSString stringWithFormat:@"%@  Page %@", chapterTitle, @(pageNumber)];
        NSString *bodyText = [NSString stringWithFormat:@"%@ uses a real source style flow with progress saving, image caching, and request headers. This chapter is item %@ in the %@ sample series.", mangaName, @((NSInteger)chapterNumber), mangaName];
        NSString *remoteImageURLString = [self placeholderPageURLForMangaName:mangaName chapterTitle:chapterTitle pageNumber:pageNumber];
        IRPage *page = [[IRPage alloc] initWithPageNumber:pageNumber
                                    remoteImageURLString:remoteImageURLString
                                                headline:headline
                                                bodyText:bodyText];
        [pages addObject:page];
    }

    return [pages copy];
}

- (NSString *)placeholderCoverURLForMangaName:(NSString *)mangaName genreText:(NSString *)genreText {
    NSString *text = [NSString stringWithFormat:@"%@\n%@", mangaName, genreText];
    NSString *encodedText = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"https://placehold.co/320x460/18344b/f0ead5.png?text=%@", encodedText];
}

- (NSString *)placeholderPageURLForMangaName:(NSString *)mangaName chapterTitle:(NSString *)chapterTitle pageNumber:(NSInteger)pageNumber {
    NSString *text = [NSString stringWithFormat:@"%@\n%@\nPage %@", mangaName, chapterTitle, @(pageNumber)];
    NSString *encodedText = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSString stringWithFormat:@"https://placehold.co/900x1200/f4f0e6/22354a.png?text=%@", encodedText];
}

@end
