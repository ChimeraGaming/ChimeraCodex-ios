#import "IRAppContainer.h"

#import "IRLibraryStore.h"
#import "IRRemoteImageLoader.h"
#import "IRSourceRecord.h"
#import "IRSourceRegistry.h"
#import "IRSourceProtocol.h"

NSString *const IRAppContainerSourceDidChangeNotification = @"IRAppContainerSourceDidChangeNotification";

@implementation IRAppContainer

- (instancetype)initWithSourceRegistry:(IRSourceRegistry *)sourceRegistry
                          libraryStore:(IRLibraryStore *)libraryStore
                           imageLoader:(IRRemoteImageLoader *)imageLoader {
    self = [super init];
    if (self) {
        _sourceRegistry = sourceRegistry;
        _libraryStore = libraryStore;
        _imageLoader = imageLoader;
        [self ensureCurrentSourceSelectionPostingNotification:NO];
    }
    return self;
}

- (NSArray<IRSourceRecord *> *)availableSourceRecords {
    return self.sourceRegistry.sourceRecords;
}

- (void)reloadSources {
    [self.sourceRegistry reloadSources];
    [self ensureCurrentSourceSelectionPostingNotification:YES];
}

- (BOOL)selectSourceWithIdentifier:(NSString *)sourceIdentifier {
    IRSourceRecord *record = [self.sourceRegistry sourceRecordForIdentifier:sourceIdentifier];
    if (record == nil) {
        return NO;
    }

    BOOL changed = ![self.source.sourceIdentifier isEqualToString:record.source.sourceIdentifier];
    _source = record.source;
    [self.libraryStore saveActiveSourceIdentifier:record.source.sourceIdentifier];
    if (changed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:IRAppContainerSourceDidChangeNotification object:self];
    }
    return YES;
}

- (id<IRSourceProtocol>)sourceForIdentifier:(NSString *)sourceIdentifier {
    IRSourceRecord *record = [self.sourceRegistry sourceRecordForIdentifier:sourceIdentifier];
    return record.source ?: self.source;
}

- (void)ensureCurrentSourceSelectionPostingNotification:(BOOL)shouldPostNotification {
    NSString *preferredSourceIdentifier = [self.libraryStore activeSourceIdentifier];
    IRSourceRecord *record = [self.sourceRegistry sourceRecordForIdentifier:preferredSourceIdentifier];
    if (record == nil) {
        record = self.sourceRegistry.sourceRecords.firstObject;
    }
    if (record == nil) {
        return;
    }

    id<IRSourceProtocol> previousSource = _source;
    _source = record.source;
    if (record.source.sourceIdentifier.length > 0) {
        [self.libraryStore saveActiveSourceIdentifier:record.source.sourceIdentifier];
    }

    BOOL sourceIdentifierChanged = previousSource != nil && ![previousSource.sourceIdentifier isEqualToString:_source.sourceIdentifier];
    BOOL sourceInstanceChanged = previousSource != nil && previousSource != _source;
    if (shouldPostNotification && (sourceIdentifierChanged || sourceInstanceChanged)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:IRAppContainerSourceDidChangeNotification object:self];
    }
}

@end
