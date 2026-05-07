#import <Foundation/Foundation.h>

@interface IRChapter : NSObject

@property (nonatomic, copy, readonly) NSString *chapterID;
@property (nonatomic, assign, readonly) NSInteger chapterNumber;
@property (nonatomic, assign, readonly) NSInteger pageCountHint;
@property (nonatomic, copy, readonly) NSString *releaseText;
@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithChapterID:(NSString *)chapterID
                    chapterNumber:(NSInteger)chapterNumber
                            title:(NSString *)title
                    pageCountHint:(NSInteger)pageCountHint
                      releaseText:(NSString *)releaseText NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
