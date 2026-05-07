#import <Foundation/Foundation.h>

#import "IRSourceProtocol.h"

@interface IRStaticSource : NSObject <IRSourceProtocol>

@property (nonatomic, copy, readonly) NSString *displayName;
@property (nonatomic, copy, readonly) NSString *sourceIdentifier;

@end
