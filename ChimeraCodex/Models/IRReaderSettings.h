#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IRReaderFitMode) {
    IRReaderFitModeWidth = 0,
    IRReaderFitModeHeight = 1
};

@interface IRReaderSettings : NSObject

@property (nonatomic, assign, readonly) BOOL brightnessLockEnabled;
@property (nonatomic, assign, readonly) IRReaderFitMode fitMode;
@property (nonatomic, assign, readonly) CGFloat pageGap;
@property (nonatomic, assign, readonly) CGFloat preferredBrightness;
@property (nonatomic, assign, readonly) BOOL reversePageOrder;

- (instancetype)initWithFitMode:(IRReaderFitMode)fitMode
                        pageGap:(CGFloat)pageGap
               reversePageOrder:(BOOL)reversePageOrder
          brightnessLockEnabled:(BOOL)brightnessLockEnabled
            preferredBrightness:(CGFloat)preferredBrightness NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)defaultSettings;
+ (instancetype)settingsWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSString *)fitModeText;
- (NSString *)readingDirectionText;

@end
