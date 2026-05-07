#import <Foundation/Foundation.h>

@interface IRPage : NSObject

@property (nonatomic, copy, readonly) NSString *bodyText;
@property (nonatomic, copy, readonly) NSString *headline;
@property (nonatomic, assign, readonly) NSInteger pageNumber;
@property (nonatomic, copy, readonly) NSString *remoteImageURLString;

- (instancetype)initWithPageNumber:(NSInteger)pageNumber
              remoteImageURLString:(NSString *)remoteImageURLString
                          headline:(NSString *)headline
                          bodyText:(NSString *)bodyText NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
