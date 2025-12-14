#import "KeychainTokenStore.h"
#import <Security/Security.h>

static NSString * const kTokenService = @"com.nyxsocial.api";
static NSString * const kTokenAccount = @"jwt";

@implementation KeychainTokenStore
+ (instancetype)shared { static id s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new];}); return s; }

- (void)saveToken:(NSString *)token {
    NSData *data = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *q = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrService:kTokenService,
                        (__bridge id)kSecAttrAccount:kTokenAccount};
    SecItemDelete((__bridge CFDictionaryRef)q);
    NSMutableDictionary *a = [q mutableCopy];
    a[(__bridge id)kSecValueData] = data;
    SecItemAdd((__bridge CFDictionaryRef)a, NULL);
}

- (NSString *)loadToken {
    NSDictionary *q = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrService:kTokenService,
                        (__bridge id)kSecAttrAccount:kTokenAccount,
                        (__bridge id)kSecReturnData:@YES};
    CFTypeRef out = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &out) != errSecSuccess) return nil;
    NSData *d = (__bridge_transfer NSData *)out;
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

- (void)clearToken {
    NSDictionary *q = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrService:kTokenService,
                        (__bridge id)kSecAttrAccount:kTokenAccount};
    SecItemDelete((__bridge CFDictionaryRef)q);
}
@end
