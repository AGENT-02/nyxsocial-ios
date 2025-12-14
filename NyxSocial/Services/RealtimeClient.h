#import <Foundation/Foundation.h>
@interface RealtimeClient : NSObject
@property (nonatomic, copy) NSString *wsBaseURL;
+ (instancetype)shared;
- (void)connect;
- (void)disconnect;
- (void)sendJSON:(NSDictionary *)obj;
@end
