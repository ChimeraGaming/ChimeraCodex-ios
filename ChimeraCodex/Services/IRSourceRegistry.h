#import <Foundation/Foundation.h>

@class IRSourceRecord;

@interface IRSourceRegistry : NSObject

@property (nonatomic, copy, readonly) NSString *sourcePacksDirectoryPath;
@property (nonatomic, copy, readonly) NSArray<IRSourceRecord *> *sourceRecords;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (IRSourceRecord *)sourceRecordForIdentifier:(NSString *)sourceIdentifier;
- (void)reloadSources;

@end
