#import "IRLibraryStore.h"

#import "IRReaderSettings.h"
#import "IRReadingProgress.h"

NSString *const IRLibraryStoreDidChangeNotification = @"IRLibraryStoreDidChangeNotification";

static NSString *const IRLibraryMangaIDsKey = @"IRLibraryMangaIDsKey";
static NSString *const IRLibraryReaderSettingsKey = @"IRLibraryReaderSettingsKey";
static NSString *const IRLibraryReadingProgressKey = @"IRLibraryReadingProgressKey";
static NSString *const IRLibraryActiveSourceKey = @"IRLibraryActiveSourceKey";

@implementation IRLibraryStore

- (NSArray<NSString *> *)savedMangaIDsForSourceIdentifier:(NSString *)sourceIdentifier {
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryMangaIDsKey];
    NSArray *savedIDs = [dictionary objectForKey:[self keyPrefixForSourceIdentifier:sourceIdentifier]];
    if ([savedIDs isKindOfClass:[NSArray class]]) {
        return savedIDs;
    }
    return @[];
}

- (BOOL)isSavedMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier {
    return [[self savedMangaIDsForSourceIdentifier:sourceIdentifier] containsObject:mangaID];
}

- (void)setSaved:(BOOL)saved forMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier {
    if (mangaID.length == 0 || sourceIdentifier.length == 0) {
        return;
    }

    NSDictionary *storedDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryMangaIDsKey];
    NSMutableDictionary *dictionary = [storedDictionary isKindOfClass:[NSDictionary class]] ? [storedDictionary mutableCopy] : [NSMutableDictionary dictionary];
    NSString *sourceKey = [self keyPrefixForSourceIdentifier:sourceIdentifier];
    NSMutableOrderedSet *updatedIDs = [NSMutableOrderedSet orderedSetWithArray:[dictionary objectForKey:sourceKey] ?: @[]];
    if (saved) {
        [updatedIDs addObject:mangaID];
    } else {
        [updatedIDs removeObject:mangaID];
    }

    [dictionary setObject:[updatedIDs array] forKey:sourceKey];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:IRLibraryMangaIDsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postChange];
}

- (NSArray<IRReadingProgress *> *)allReadingProgress {
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryReadingProgressKey];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return @[];
    }

    NSMutableArray<IRReadingProgress *> *results = [NSMutableArray array];
    for (NSDictionary *progressDictionary in [dictionary allValues]) {
        IRReadingProgress *progress = [IRReadingProgress progressWithDictionary:progressDictionary];
        if (progress != nil) {
            [results addObject:progress];
        }
    }

    [results sortUsingComparator:^NSComparisonResult(IRReadingProgress *left, IRReadingProgress *right) {
        return [right.updatedAt compare:left.updatedAt];
    }];
    return [results copy];
}

- (IRReadingProgress *)readingProgressForMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier {
    if (mangaID.length == 0 || sourceIdentifier.length == 0) {
        return nil;
    }

    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryReadingProgressKey];
    NSDictionary *progressDictionary = [dictionary objectForKey:[self compositeKeyForMangaID:mangaID sourceIdentifier:sourceIdentifier]];
    return [IRReadingProgress progressWithDictionary:progressDictionary];
}

- (void)saveReadingProgressForMangaID:(NSString *)mangaID
                     sourceIdentifier:(NSString *)sourceIdentifier
                            mangaName:(NSString *)mangaName
                            chapterID:(NSString *)chapterID
                         chapterTitle:(NSString *)chapterTitle
                          currentPage:(NSInteger)currentPage
                           totalPages:(NSInteger)totalPages {
    if (mangaID.length == 0 || sourceIdentifier.length == 0 || chapterID.length == 0 || totalPages <= 0) {
        return;
    }

    NSDictionary *storedDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryReadingProgressKey];
    NSMutableDictionary *dictionary = [storedDictionary isKindOfClass:[NSDictionary class]] ? [storedDictionary mutableCopy] : [NSMutableDictionary dictionary];
    IRReadingProgress *progress = [[IRReadingProgress alloc] initWithMangaID:mangaID
                                                            sourceIdentifier:sourceIdentifier
                                                                   mangaName:mangaName
                                                                   chapterID:chapterID
                                                                chapterTitle:chapterTitle
                                                                 currentPage:MAX(1, currentPage)
                                                                  totalPages:totalPages
                                                                   updatedAt:[NSDate date]];
    [dictionary setObject:[progress dictionaryRepresentation] forKey:[self compositeKeyForMangaID:mangaID sourceIdentifier:sourceIdentifier]];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:IRLibraryReadingProgressKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postChange];
}

- (NSString *)activeSourceIdentifier {
    NSString *sourceIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:IRLibraryActiveSourceKey];
    return sourceIdentifier ?: @"";
}

- (void)saveActiveSourceIdentifier:(NSString *)sourceIdentifier {
    if (sourceIdentifier.length == 0) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:sourceIdentifier forKey:IRLibraryActiveSourceKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postChange];
}

- (IRReaderSettings *)readerSettings {
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:IRLibraryReaderSettingsKey];
    return [IRReaderSettings settingsWithDictionary:dictionary];
}

- (void)saveReaderSettings:(IRReaderSettings *)settings {
    if (settings == nil) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:[settings dictionaryRepresentation] forKey:IRLibraryReaderSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postChange];
}

- (void)postChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:IRLibraryStoreDidChangeNotification object:self];
}

- (NSString *)compositeKeyForMangaID:(NSString *)mangaID sourceIdentifier:(NSString *)sourceIdentifier {
    return [NSString stringWithFormat:@"%@|%@", [self keyPrefixForSourceIdentifier:sourceIdentifier], mangaID ?: @""];
}

- (NSString *)keyPrefixForSourceIdentifier:(NSString *)sourceIdentifier {
    return sourceIdentifier.length > 0 ? sourceIdentifier : @"unknown";
}

@end
