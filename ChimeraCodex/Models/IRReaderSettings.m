#import "IRReaderSettings.h"

@implementation IRReaderSettings

- (instancetype)initWithFitMode:(IRReaderFitMode)fitMode
                        pageGap:(CGFloat)pageGap
               reversePageOrder:(BOOL)reversePageOrder
          brightnessLockEnabled:(BOOL)brightnessLockEnabled
            preferredBrightness:(CGFloat)preferredBrightness {
    self = [super init];
    if (self) {
        _fitMode = fitMode;
        _pageGap = MAX(8.0, MIN(pageGap, 40.0));
        _reversePageOrder = reversePageOrder;
        _brightnessLockEnabled = brightnessLockEnabled;
        _preferredBrightness = MAX(0.1, MIN(preferredBrightness, 1.0));
    }
    return self;
}

+ (instancetype)defaultSettings {
    return [[IRReaderSettings alloc] initWithFitMode:IRReaderFitModeWidth
                                             pageGap:18.0
                                    reversePageOrder:NO
                               brightnessLockEnabled:NO
                                 preferredBrightness:0.85];
}

+ (instancetype)settingsWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return [self defaultSettings];
    }

    return [[IRReaderSettings alloc] initWithFitMode:[dictionary[@"fitMode"] integerValue]
                                             pageGap:[dictionary[@"pageGap"] doubleValue]
                                    reversePageOrder:[dictionary[@"reversePageOrder"] boolValue]
                               brightnessLockEnabled:[dictionary[@"brightnessLockEnabled"] boolValue]
                                 preferredBrightness:[dictionary[@"preferredBrightness"] doubleValue] > 0.0 ? [dictionary[@"preferredBrightness"] doubleValue] : 0.85];
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"fitMode": @(self.fitMode),
        @"pageGap": @(self.pageGap),
        @"reversePageOrder": @(self.reversePageOrder),
        @"brightnessLockEnabled": @(self.brightnessLockEnabled),
        @"preferredBrightness": @(self.preferredBrightness)
    };
}

- (NSString *)fitModeText {
    return self.fitMode == IRReaderFitModeHeight ? @"Fit Height" : @"Fit Width";
}

- (NSString *)readingDirectionText {
    return self.reversePageOrder ? @"Reverse" : @"Normal";
}

@end
