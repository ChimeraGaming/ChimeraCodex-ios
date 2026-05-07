#import <Foundation/Foundation.h>

#import "IRSourceProtocol.h"

@interface IRJSONSource : NSObject <IRSourceProtocol>

@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;

- (instancetype)initWithManifest:(NSDictionary *)manifest
                    manifestPath:(NSString *)manifestPath
                           error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
