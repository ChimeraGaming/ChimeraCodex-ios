#import "IRSourceRecord.h"

#import "IRSourceProtocol.h"

@implementation IRSourceRecord

- (instancetype)initWithSource:(id<IRSourceProtocol>)source
                    detailText:(NSString *)detailText
                      filePath:(NSString *)filePath
                       builtIn:(BOOL)builtIn {
    self = [super init];
    if (self) {
        _source = source;
        _sourceIdentifier = [source.sourceIdentifier copy];
        _displayName = [source.displayName copy];
        _detailText = [detailText copy];
        _filePath = [filePath copy];
        _builtIn = builtIn;
    }
    return self;
}

@end
