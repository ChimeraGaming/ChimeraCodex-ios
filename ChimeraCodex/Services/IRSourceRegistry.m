#import "IRSourceRegistry.h"

#import "IRJSONSource.h"
#import "IRSourceRecord.h"
#import "IRStaticSource.h"

@interface IRSourceRegistry ()

@property (nonatomic, copy) NSString *sourcePacksDirectoryPath;
@property (nonatomic, copy) NSArray<IRSourceRecord *> *sourceRecords;

@end

@implementation IRSourceRegistry

- (instancetype)init {
    self = [super init];
    if (self) {
        _sourcePacksDirectoryPath = [[self.class documentsDirectoryPath] stringByAppendingPathComponent:@"SourcePacks"];
        [self createSourcePacksDirectoryIfNeeded];
        [self ensureSampleSourcePackIfNeeded];
        [self reloadSources];
    }
    return self;
}

- (IRSourceRecord *)sourceRecordForIdentifier:(NSString *)sourceIdentifier {
    for (IRSourceRecord *record in self.sourceRecords) {
        if ([record.sourceIdentifier isEqualToString:sourceIdentifier]) {
            return record;
        }
    }
    return nil;
}

- (void)reloadSources {
    NSMutableArray<IRSourceRecord *> *records = [NSMutableArray array];
    IRStaticSource *staticSource = [[IRStaticSource alloc] init];
    [records addObject:[[IRSourceRecord alloc] initWithSource:staticSource
                                                   detailText:@"Built in sample source"
                                                     filePath:@""
                                                      builtIn:YES]];

    for (NSString *manifestPath in [self manifestPaths]) {
        NSData *data = [NSData dataWithContentsOfFile:manifestPath];
        if (data.length == 0) {
            continue;
        }

        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![jsonObject isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        IRJSONSource *source = [[IRJSONSource alloc] initWithManifest:jsonObject manifestPath:manifestPath error:&error];
        if (source == nil) {
            continue;
        }

        NSString *detailText = [NSString stringWithFormat:@"Source pack  %@", [manifestPath lastPathComponent]];
        [records addObject:[[IRSourceRecord alloc] initWithSource:source
                                                       detailText:detailText
                                                         filePath:manifestPath
                                                          builtIn:NO]];
    }

    self.sourceRecords = [records copy];
}

+ (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject ?: NSTemporaryDirectory();
}

- (void)createSourcePacksDirectoryIfNeeded {
    [[NSFileManager defaultManager] createDirectoryAtPath:self.sourcePacksDirectoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

- (NSArray<NSString *> *)manifestPaths {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *entries = [fileManager contentsOfDirectoryAtPath:self.sourcePacksDirectoryPath error:nil];
    NSMutableArray<NSString *> *results = [NSMutableArray array];

    for (NSString *entry in entries) {
        NSString *fullPath = [self.sourcePacksDirectoryPath stringByAppendingPathComponent:entry];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (isDirectory) {
            NSString *manifestPath = [fullPath stringByAppendingPathComponent:@"manifest.json"];
            if ([fileManager fileExistsAtPath:manifestPath]) {
                [results addObject:manifestPath];
            }
            continue;
        }

        if ([[entry.pathExtension lowercaseString] isEqualToString:@"json"]) {
            [results addObject:fullPath];
        }
    }

    [results sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return [results copy];
}

- (void)ensureSampleSourcePackIfNeeded {
    NSString *packDirectory = [self.sourcePacksDirectoryPath stringByAppendingPathComponent:@"SamplePack"];
    NSString *manifestPath = [packDirectory stringByAppendingPathComponent:@"manifest.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
        return;
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:packDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    NSDictionary *manifest = @{
        @"formatVersion": @1,
        @"id": @"pack.sample.local",
        @"name": @"Sample Pack Source",
        @"catalog": @{
            @"url": @"./catalog.json",
            @"itemsKeyPath": @"titles",
            @"fields": @{
                @"id": @"id",
                @"name": @"name",
                @"summary": @"summary",
                @"latestChapterTitle": @"latestChapterTitle",
                @"chapterCount": @"estimatedChapterCount",
                @"genres": @"genres",
                @"status": @"status"
            }
        },
        @"chapters": @{
            @"urlTemplate": @"./{mangaId}-chapters.json",
            @"itemsKeyPath": @"chapters",
            @"fields": @{
                @"id": @"id",
                @"number": @"number",
                @"title": @"title",
                @"pageCount": @"pageCountHint",
                @"releaseText": @"releaseText"
            }
        },
        @"pages": @{
            @"urlTemplate": @"./{chapterId}-pages.json",
            @"itemsKeyPath": @"pages",
            @"fields": @{
                @"number": @"pageNumber",
                @"headline": @"headline",
                @"bodyText": @"bodyText"
            }
        }
    };

    NSArray<NSDictionary *> *titles = @[
        @{
            @"id": @"north-harbor",
            @"name": @"North Harbor Files",
            @"summary": @"A harbor mystery with radio logs, missing ledger pages, and late night ferry routes.",
            @"latestChapterTitle": @"Chapter 3: Tide Report",
            @"estimatedChapterCount": @3,
            @"genres": @[@"Mystery", @"Drama"],
            @"status": @"ongoing"
        },
        @{
            @"id": @"paper-lantern",
            @"name": @"Paper Lantern Club",
            @"summary": @"A quiet school archive story about reading rooms, missing shelves, and handwritten notes.",
            @"latestChapterTitle": @"Chapter 3: The Missing Shelf",
            @"estimatedChapterCount": @3,
            @"genres": @[@"Slice of Life", @"School"],
            @"status": @"complete"
        },
        @{
            @"id": @"orbit-kitchen",
            @"name": @"Orbit Kitchen",
            @"summary": @"A drifting kitchen ship feeds travelers while its crew documents each stop like a travel log.",
            @"latestChapterTitle": @"Chapter 3: Last Seating",
            @"estimatedChapterCount": @3,
            @"genres": @[@"Adventure", @"Food"],
            @"status": @"hiatus"
        }
    ];

    [self writeJSONObject:manifest toPath:manifestPath];
    [self writeJSONObject:@{@"titles": titles} toPath:[packDirectory stringByAppendingPathComponent:@"catalog.json"]];

    for (NSDictionary *title in titles) {
        NSString *mangaID = title[@"id"];
        NSArray<NSDictionary *> *chapters = @[
            @{
                @"id": [NSString stringWithFormat:@"%@-1", mangaID],
                @"number": @1,
                @"title": @"Chapter 1: Opening",
                @"pageCountHint": @6,
                @"releaseText": @"Release 1"
            },
            @{
                @"id": [NSString stringWithFormat:@"%@-2", mangaID],
                @"number": @2,
                @"title": @"Chapter 2: Crossing",
                @"pageCountHint": @6,
                @"releaseText": @"Release 2"
            },
            @{
                @"id": [NSString stringWithFormat:@"%@-3", mangaID],
                @"number": @3,
                @"title": @"Chapter 3: Return",
                @"pageCountHint": @6,
                @"releaseText": @"Release 3"
            }
        ];

        [self writeJSONObject:@{@"chapters": chapters}
                        toPath:[packDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-chapters.json", mangaID]]];

        for (NSDictionary *chapter in chapters) {
            NSMutableArray<NSDictionary *> *pages = [NSMutableArray array];
            for (NSInteger pageNumber = 1; pageNumber <= 6; pageNumber++) {
                [pages addObject:@{
                    @"pageNumber": @(pageNumber),
                    @"headline": [NSString stringWithFormat:@"%@  Page %@", chapter[@"title"], @(pageNumber)],
                    @"bodyText": [NSString stringWithFormat:@"%@ is loaded through the external source pack system. This page belongs to %@.", title[@"name"], chapter[@"title"]]
                }];
            }

            [self writeJSONObject:@{@"pages": pages}
                            toPath:[packDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-pages.json", chapter[@"id"]]]];
        }
    }
}

- (void)writeJSONObject:(id)object toPath:(NSString *)path {
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:path atomically:YES];
}

@end
