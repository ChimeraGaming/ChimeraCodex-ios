#import "IRPage.h"

@implementation IRPage

- (instancetype)initWithPageNumber:(NSInteger)pageNumber
              remoteImageURLString:(NSString *)remoteImageURLString
                          headline:(NSString *)headline
                          bodyText:(NSString *)bodyText {
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
        _remoteImageURLString = [remoteImageURLString copy];
        _headline = [headline copy];
        _bodyText = [bodyText copy];
    }
    return self;
}

@end
