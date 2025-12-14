#import <Foundation/Foundation.h>
@interface CallService : NSObject
+ (instancetype)shared;
- (NSString *)startOutgoingCallToUid:(NSNumber *)toUid media:(NSString *)media;
- (void)handleWS:(NSDictionary *)json;
@end
