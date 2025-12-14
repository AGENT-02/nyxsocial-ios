#import <Foundation/Foundation.h>
@interface KeychainTokenStore : NSObject
+ (instancetype)shared;
- (void)saveToken:(NSString *)token;
- (NSString *)loadToken;
- (void)clearToken;
@end
