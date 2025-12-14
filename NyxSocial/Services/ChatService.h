#import <Foundation/Foundation.h>
@interface ChatService : NSObject
+ (instancetype)shared;
- (void)prepareSessionForUsername:(NSString *)username completion:(void(^)(BOOL ok))completion;
- (void)sendText:(NSString *)text toUsername:(NSString *)username completion:(void(^)(BOOL ok, NSDictionary * _Nullable resp))completion;
- (void)handleIncomingEncrypted:(NSDictionary *)wsMsg;
@property (nonatomic, strong, readonly) NSDictionary *messagesByUser;
@end
