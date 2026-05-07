#import <Foundation/Foundation.h>

@protocol IRSourceProtocol;

@interface IRSourceRecord : NSObject

@property (nonatomic, copy, readonly) NSString *detailText;
@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) BOOL builtIn;
@property (nonatomic, strong, readonly) id<IRSourceProtocol> source;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;

- (instancetype)initWithSource:(id<IRSourceProtocol>)source
                    detailText:(NSString *)detailText
                      filePath:(NSString *)filePath
                       builtIn:(BOOL)builtIn NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
