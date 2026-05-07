#import "IRJSONSource.h"

#import "IRChapter.h"
#import "IRManga.h"
#import "IRPage.h"

static NSString *const IRJSONSourceErrorDomain = @"IRJSONSourceErrorDomain";

@interface IRJSONSource ()

@property (nonatomic, copy) NSString *baseURLString;
@property (nonatomic, copy) NSArray<NSDictionary *> *cookieDefinitions;
@property (nonatomic, copy) NSDictionary *defaultHeaders;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSDictionary *manifest;
@property (nonatomic, copy) NSString *manifestPath;
@property (nonatomic, strong) NSURL *packDirectoryURL;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSString *sourceIdentifier;

@end

@implementation IRJSONSource

- (instancetype)initWithManifest:(NSDictionary *)manifest
                    manifestPath:(NSString *)manifestPath
                           error:(NSError **)error {
    self = [super init];
    if (self) {
        NSString *sourceIdentifier = [manifest[@"id"] isKindOfClass:[NSString class]] ? manifest[@"id"] : @"";
        NSString *displayName = [manifest[@"name"] isKindOfClass:[NSString class]] ? manifest[@"name"] : @"";
        NSDictionary *catalog = [manifest[@"catalog"] isKindOfClass:[NSDictionary class]] ? manifest[@"catalog"] : nil;
        NSDictionary *chapters = [manifest[@"chapters"] isKindOfClass:[NSDictionary class]] ? manifest[@"chapters"] : nil;
        NSDictionary *pages = [manifest[@"pages"] isKindOfClass:[NSDictionary class]] ? manifest[@"pages"] : nil;

        if (sourceIdentifier.length == 0 || displayName.length == 0 || catalog == nil || chapters == nil || pages == nil) {
            if (error != nil) {
                *error = [NSError errorWithDomain:IRJSONSourceErrorDomain code:1 userInfo:nil];
            }
            return nil;
        }

        _manifest = [manifest copy];
        _manifestPath = [manifestPath copy];
        _displayName = [displayName copy];
        _sourceIdentifier = [sourceIdentifier copy];
        _defaultHeaders = [manifest[@"defaultHeaders"] isKindOfClass:[NSDictionary class]] ? [manifest[@"defaultHeaders"] copy] : @{};
        _cookieDefinitions = [manifest[@"cookies"] isKindOfClass:[NSArray class]] ? [manifest[@"cookies"] copy] : @[];
        _baseURLString = [manifest[@"baseURL"] isKindOfClass:[NSString class]] ? [manifest[@"baseURL"] copy] : @"";
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _packDirectoryURL = [NSURL fileURLWithPath:[manifestPath stringByDeletingLastPathComponent] isDirectory:YES];
    }
    return self;
}

- (void)fetchCatalogWithCompletion:(IRSourceCatalogCompletion)completion {
    NSDictionary *section = self.manifest[@"catalog"];
    [self loadItemsForSection:section tokens:@{} completion:^(NSArray *items, NSError *error) {
        if (error != nil) {
            [self completeCatalog:completion mangaList:nil error:error];
            return;
        }

        NSDictionary *fields = [section[@"fields"] isKindOfClass:[NSDictionary class]] ? section[@"fields"] : @{};
        NSMutableArray<IRManga *> *mangaList = [NSMutableArray array];
        for (id item in items) {
            NSString *mangaID = [self stringValueForField:fields[@"id"] object:item fallback:[NSString stringWithFormat:@"%@.%@", self.sourceIdentifier, @([mangaList count] + 1)]];
            NSString *name = [self stringValueForField:fields[@"name"] object:item fallback:@"Untitled"];
            NSString *summary = [self stringValueForField:fields[@"summary"] object:item fallback:@""];
            NSString *latestChapterTitle = [self stringValueForField:fields[@"latestChapterTitle"] object:item fallback:@""];
            NSString *coverImageURLString = [self resolvedResourceURLString:[self stringValueForField:fields[@"cover"] object:item fallback:@""]];
            NSInteger estimatedChapterCount = [self integerValueForField:fields[@"chapterCount"] object:item fallback:0];
            NSString *genreText = [self genreTextForField:fields[@"genres"] object:item];
            IRMangaStatus status = [self mangaStatusForValue:[self valueForField:fields[@"status"] object:item]];

            IRManga *manga = [[IRManga alloc] initWithMangaID:mangaID
                                             sourceIdentifier:self.sourceIdentifier
                                                         name:name
                                                      summary:summary
                                           latestChapterTitle:latestChapterTitle
                                         coverImageURLString:coverImageURLString
                                       estimatedChapterCount:estimatedChapterCount
                                                   genreText:genreText
                                                      status:status];
            [mangaList addObject:manga];
        }

        [self completeCatalog:completion mangaList:mangaList error:nil];
    }];
}

- (void)fetchChaptersForManga:(IRManga *)manga completion:(IRSourceChaptersCompletion)completion {
    NSDictionary *section = self.manifest[@"chapters"];
    NSDictionary *tokens = @{
        @"mangaId": manga.mangaID ?: @"",
        @"mangaName": manga.name ?: @"",
        @"sourceId": self.sourceIdentifier ?: @""
    };

    [self loadItemsForSection:section tokens:tokens completion:^(NSArray *items, NSError *error) {
        if (completion == nil) {
            return;
        }

        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSDictionary *fields = [section[@"fields"] isKindOfClass:[NSDictionary class]] ? section[@"fields"] : @{};
        NSMutableArray<IRChapter *> *chapters = [NSMutableArray array];
        for (NSUInteger index = 0; index < items.count; index++) {
            id item = items[index];
            NSString *chapterID = [self stringValueForField:fields[@"id"] object:item fallback:[NSString stringWithFormat:@"%@.%@", manga.mangaID ?: @"manga", @((NSInteger)index + 1)]];
            NSInteger chapterNumber = [self integerValueForField:fields[@"number"] object:item fallback:(NSInteger)index + 1];
            NSString *title = [self stringValueForField:fields[@"title"] object:item fallback:[NSString stringWithFormat:@"Chapter %@", @(chapterNumber)]];
            NSInteger pageCountHint = [self integerValueForField:fields[@"pageCount"] object:item fallback:0];
            NSString *releaseText = [self stringValueForField:fields[@"releaseText"] object:item fallback:@""];

            IRChapter *chapter = [[IRChapter alloc] initWithChapterID:chapterID
                                                        chapterNumber:chapterNumber
                                                                title:title
                                                        pageCountHint:pageCountHint
                                                          releaseText:releaseText];
            [chapters addObject:chapter];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion([chapters copy], nil);
        });
    }];
}

- (void)fetchPagesForManga:(IRManga *)manga chapter:(IRChapter *)chapter completion:(IRSourcePagesCompletion)completion {
    NSDictionary *section = self.manifest[@"pages"];
    NSDictionary *tokens = @{
        @"mangaId": manga.mangaID ?: @"",
        @"mangaName": manga.name ?: @"",
        @"chapterId": chapter.chapterID ?: @"",
        @"chapterTitle": chapter.title ?: @"",
        @"sourceId": self.sourceIdentifier ?: @""
    };

    [self loadItemsForSection:section tokens:tokens completion:^(NSArray *items, NSError *error) {
        if (completion == nil) {
            return;
        }

        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSDictionary *fields = [section[@"fields"] isKindOfClass:[NSDictionary class]] ? section[@"fields"] : @{};
        NSMutableArray<IRPage *> *pages = [NSMutableArray array];
        for (NSUInteger index = 0; index < items.count; index++) {
            id item = items[index];
            NSInteger pageNumber = [self integerValueForField:fields[@"number"] object:item fallback:(NSInteger)index + 1];
            NSString *remoteImageURLString = [self resolvedResourceURLString:[self stringValueForField:fields[@"imageURL"] object:item fallback:@""]];
            NSString *headline = [self stringValueForField:fields[@"headline"] object:item fallback:[NSString stringWithFormat:@"%@  Page %@", chapter.title ?: @"Chapter", @(pageNumber)]];
            NSString *bodyText = [self stringValueForField:fields[@"bodyText"] object:item fallback:@""];

            IRPage *page = [[IRPage alloc] initWithPageNumber:pageNumber
                                        remoteImageURLString:remoteImageURLString
                                                    headline:headline
                                                    bodyText:bodyText];
            [pages addObject:page];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion([pages copy], nil);
        });
    }];
}

- (NSArray<NSHTTPCookie *> *)cookiesForRequestURL:(NSURL *)requestURL {
    NSMutableArray<NSHTTPCookie *> *cookies = [NSMutableArray array];
    for (NSDictionary *cookieDefinition in self.cookieDefinitions) {
        if (![cookieDefinition isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        NSString *name = [cookieDefinition[@"name"] isKindOfClass:[NSString class]] ? cookieDefinition[@"name"] : @"";
        NSString *value = [cookieDefinition[@"value"] isKindOfClass:[NSString class]] ? cookieDefinition[@"value"] : @"";
        NSString *domain = [cookieDefinition[@"domain"] isKindOfClass:[NSString class]] ? cookieDefinition[@"domain"] : requestURL.host ?: @"";
        NSString *path = [cookieDefinition[@"path"] isKindOfClass:[NSString class]] ? cookieDefinition[@"path"] : @"/";
        if (name.length == 0 || domain.length == 0) {
            continue;
        }

        NSMutableDictionary *properties = [@{
            NSHTTPCookieName: name,
            NSHTTPCookieValue: value,
            NSHTTPCookieDomain: domain,
            NSHTTPCookiePath: path
        } mutableCopy];

        NSNumber *expiresIn = [cookieDefinition[@"expiresInSeconds"] isKindOfClass:[NSNumber class]] ? cookieDefinition[@"expiresInSeconds"] : nil;
        if (expiresIn != nil) {
            properties[NSHTTPCookieExpires] = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
        }

        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:properties];
        if (cookie != nil) {
            [cookies addObject:cookie];
        }
    }
    return [cookies copy];
}

- (NSDictionary<NSString *, NSString *> *)headersForCoverURLString:(NSString *)coverURLString manga:(IRManga *)manga {
    NSDictionary *section = self.manifest[@"catalog"];
    NSDictionary *tokens = @{
        @"coverURL": coverURLString ?: @"",
        @"mangaId": manga.mangaID ?: @"",
        @"mangaName": manga.name ?: @"",
        @"sourceId": self.sourceIdentifier ?: @""
    };
    return [self headersForSection:section tokens:tokens];
}

- (NSDictionary<NSString *, NSString *> *)headersForPage:(IRPage *)page manga:(IRManga *)manga chapter:(IRChapter *)chapter {
    NSDictionary *section = self.manifest[@"pages"];
    NSDictionary *tokens = @{
        @"pageNumber": [NSString stringWithFormat:@"%@", @(page.pageNumber)],
        @"mangaId": manga.mangaID ?: @"",
        @"mangaName": manga.name ?: @"",
        @"chapterId": chapter.chapterID ?: @"",
        @"chapterTitle": chapter.title ?: @"",
        @"sourceId": self.sourceIdentifier ?: @""
    };
    return [self headersForSection:section tokens:tokens];
}

- (void)completeCatalog:(IRSourceCatalogCompletion)completion mangaList:(NSArray<IRManga *> *)mangaList error:(NSError *)error {
    if (completion == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        completion(mangaList, error);
    });
}

- (NSDictionary<NSString *, NSString *> *)headersForSection:(NSDictionary *)section tokens:(NSDictionary<NSString *, NSString *> *)tokens {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers addEntriesFromDictionary:[self resolvedHeaders:self.defaultHeaders tokens:tokens]];
    NSDictionary *sectionHeaders = [section[@"headers"] isKindOfClass:[NSDictionary class]] ? section[@"headers"] : @{};
    [headers addEntriesFromDictionary:[self resolvedHeaders:sectionHeaders tokens:tokens]];
    return [headers copy];
}

- (NSDictionary<NSString *, NSString *> *)resolvedHeaders:(NSDictionary *)headers tokens:(NSDictionary<NSString *, NSString *> *)tokens {
    NSMutableDictionary *resolved = [NSMutableDictionary dictionary];
    for (NSString *key in headers) {
        NSString *value = [headers[key] isKindOfClass:[NSString class]] ? headers[key] : @"";
        resolved[key] = [self stringByResolvingTemplate:value tokens:tokens];
    }
    return [resolved copy];
}

- (void)loadItemsForSection:(NSDictionary *)section
                     tokens:(NSDictionary<NSString *, NSString *> *)tokens
                 completion:(void (^)(NSArray *items, NSError *error))completion {
    NSString *URLString = [self requestURLStringForSection:section tokens:tokens];
    NSURL *URL = [NSURL URLWithString:URLString ?: @""];
    if (URL == nil) {
        completion(nil, [NSError errorWithDomain:IRJSONSourceErrorDomain code:2 userInfo:nil]);
        return;
    }

    if (URL.isFileURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:URL];
            NSArray *items = [self itemsFromResponseData:data section:section error:nil];
            NSError *error = items != nil ? nil : [NSError errorWithDomain:IRJSONSourceErrorDomain code:3 userInfo:nil];
            completion(items, error);
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = [section[@"method"] isKindOfClass:[NSString class]] ? section[@"method"] : @"GET";
    NSDictionary *headers = [self headersForSection:section tokens:tokens];
    for (NSString *headerKey in headers) {
        [request setValue:headers[headerKey] forHTTPHeaderField:headerKey];
    }

    NSArray<NSHTTPCookie *> *cookies = [self cookiesForRequestURL:URL];
    if (cookies.count > 0) {
        NSDictionary *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        for (NSString *headerKey in cookieHeaders) {
            [request setValue:cookieHeaders[headerKey] forHTTPHeaderField:headerKey];
        }
    }

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            completion(nil, error);
            return;
        }

        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
        if (statusCode < 200 || statusCode >= 300) {
            completion(nil, [NSError errorWithDomain:IRJSONSourceErrorDomain code:statusCode userInfo:nil]);
            return;
        }

        NSError *parseError = nil;
        NSArray *items = [self itemsFromResponseData:data section:section error:&parseError];
        completion(items, parseError);
    }];
    [task resume];
}

- (NSArray *)itemsFromResponseData:(NSData *)data section:(NSDictionary *)section error:(NSError **)error {
    if (data.length == 0) {
        if (error != nil) {
            *error = [NSError errorWithDomain:IRJSONSourceErrorDomain code:4 userInfo:nil];
        }
        return nil;
    }

    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (jsonObject == nil) {
        return nil;
    }

    NSString *itemsKeyPath = [section[@"itemsKeyPath"] isKindOfClass:[NSString class]] ? section[@"itemsKeyPath"] : @"";
    id itemsObject = itemsKeyPath.length > 0 ? [self objectForKeyPath:itemsKeyPath inObject:jsonObject] : jsonObject;
    if ([itemsObject isKindOfClass:[NSArray class]]) {
        return itemsObject;
    }

    if (error != nil) {
        *error = [NSError errorWithDomain:IRJSONSourceErrorDomain code:5 userInfo:nil];
    }
    return nil;
}

- (id)objectForKeyPath:(NSString *)keyPath inObject:(id)object {
    if (keyPath.length == 0 || object == nil) {
        return object;
    }

    id current = object;
    NSArray<NSString *> *components = [keyPath componentsSeparatedByString:@"."];
    for (NSString *component in components) {
        if (![current isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        current = [current objectForKey:component];
        if (current == nil) {
            return nil;
        }
    }
    return current;
}

- (id)valueForField:(NSString *)field object:(id)object {
    if (field.length == 0) {
        return nil;
    }
    return [self objectForKeyPath:field inObject:object];
}

- (NSString *)stringValueForField:(NSString *)field object:(id)object fallback:(NSString *)fallback {
    id value = [self valueForField:field object:object];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        for (id item in value) {
            if ([item isKindOfClass:[NSString class]]) {
                [parts addObject:item];
            } else if ([item isKindOfClass:[NSNumber class]]) {
                [parts addObject:[item stringValue]];
            }
        }
        if (parts.count > 0) {
            return [parts componentsJoinedByString:@"  "];
        }
    }
    return fallback ?: @"";
}

- (NSInteger)integerValueForField:(NSString *)field object:(id)object fallback:(NSInteger)fallback {
    id value = [self valueForField:field object:object];
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return fallback;
}

- (NSString *)genreTextForField:(NSString *)field object:(id)object {
    NSString *value = [self stringValueForField:field object:object fallback:@""];
    return value.length > 0 ? value : @"Unknown";
}

- (IRMangaStatus)mangaStatusForValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        NSInteger numericValue = [value integerValue];
        if (numericValue == IRMangaStatusComplete) {
            return IRMangaStatusComplete;
        }
        if (numericValue == IRMangaStatusHiatus) {
            return IRMangaStatusHiatus;
        }
        return IRMangaStatusOngoing;
    }

    NSString *text = [[value description] lowercaseString];
    if ([text containsString:@"complete"] || [text containsString:@"finished"]) {
        return IRMangaStatusComplete;
    }
    if ([text containsString:@"hiatus"] || [text containsString:@"paused"]) {
        return IRMangaStatusHiatus;
    }
    return IRMangaStatusOngoing;
}

- (NSString *)requestURLStringForSection:(NSDictionary *)section tokens:(NSDictionary<NSString *, NSString *> *)tokens {
    NSString *rawValue = [section[@"url"] isKindOfClass:[NSString class]] ? section[@"url"] : nil;
    if (rawValue.length == 0) {
        rawValue = [section[@"urlTemplate"] isKindOfClass:[NSString class]] ? section[@"urlTemplate"] : @"";
    }

    NSString *resolved = [self stringByResolvingTemplate:rawValue tokens:tokens];
    return [self resolvedResourceURLString:resolved];
}

- (NSString *)resolvedResourceURLString:(NSString *)rawValue {
    if (rawValue.length == 0) {
        return @"";
    }

    NSURL *absoluteURL = [NSURL URLWithString:rawValue];
    if (absoluteURL.scheme.length > 0) {
        return absoluteURL.absoluteString;
    }

    if (self.baseURLString.length > 0) {
        NSURL *baseURL = [NSURL URLWithString:self.baseURLString];
        NSURL *resolvedURL = [NSURL URLWithString:rawValue relativeToURL:baseURL];
        return resolvedURL.absoluteString ?: rawValue;
    }

    NSString *normalizedPath = rawValue;
    if ([normalizedPath hasPrefix:@"./"]) {
        normalizedPath = [normalizedPath substringFromIndex:2];
    }

    NSURL *fileURL = [self.packDirectoryURL URLByAppendingPathComponent:normalizedPath];
    return fileURL.absoluteString ?: rawValue;
}

- (NSString *)stringByResolvingTemplate:(NSString *)templateString tokens:(NSDictionary<NSString *, NSString *> *)tokens {
    NSMutableString *result = [NSMutableString stringWithString:templateString ?: @""];
    NSMutableDictionary *allTokens = [tokens mutableCopy] ?: [NSMutableDictionary dictionary];
    allTokens[@"baseURL"] = self.baseURLString ?: @"";

    for (NSString *key in allTokens) {
        NSString *placeholder = [NSString stringWithFormat:@"{%@}", key];
        [result replaceOccurrencesOfString:placeholder
                                withString:allTokens[key] ?: @""
                                   options:0
                                     range:NSMakeRange(0, result.length)];
    }
    return [result copy];
}

@end
