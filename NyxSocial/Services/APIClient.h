#import <Foundation/Foundation.h>
@interface APIClient : NSObject
@property (nonatomic, copy) NSString *baseURL;
+ (instancetype)shared;

- (void)registerUser:(NSString *)username password:(NSString *)password publicKeyB64:(NSString *)publicKeyB64 completion:(void(^)(NSDictionary * _Nullable json, NSError * _Nullable err))completion;
- (void)login:(NSString *)username password:(NSString *)password completion:(void(^)(NSDictionary * _Nullable json, NSError * _Nullable err))completion;

- (void)fetchUserKey:(NSString *)username completion:(void(^)(NSDictionary * _Nullable user, NSError * _Nullable err))completion;

- (void)friendRequestTo:(NSString *)username completion:(void(^)(NSDictionary * _Nullable json, NSError * _Nullable err))completion;
- (void)friendRequests:(void(^)(NSArray * _Nullable reqs, NSError * _Nullable err))completion;
- (void)friendAccept:(NSNumber *)requestId completion:(void(^)(NSDictionary * _Nullable json, NSError * _Nullable err))completion;
- (void)friendsList:(void(^)(NSArray * _Nullable friends, NSError * _Nullable err))completion;

- (void)sendEncryptedPacketTo:(NSString *)toUsername packet:(NSDictionary *)packet completion:(void(^)(NSDictionary * _Nullable json, NSError * _Nullable err))completion;
@end
