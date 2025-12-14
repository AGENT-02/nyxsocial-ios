#import "CryptoManager.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>

static NSString * const kKeyTagPriv = @"com.nyxsocial.identity.priv";

@implementation CryptoManager {
    SecKeyRef _privKey;
    SecKeyRef _pubKey;
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSData *> *> *_sessionKeys;
}

+ (instancetype)shared { static id m; static dispatch_once_t once; dispatch_once(&once, ^{ m=[CryptoManager new];}); return m; }

- (instancetype)init { if ((self=[super init])) { _sessionKeys=[NSMutableDictionary dictionary]; [self ensureIdentityKeypair]; } return self; }

static NSData *RandomBytes(size_t count) {
    NSMutableData *d = [NSMutableData dataWithLength:count];
    if (SecRandomCopyBytes(kSecRandomDefault, count, d.mutableBytes) != errSecSuccess) return nil;
    return d;
}

static NSData *HMAC_SHA256(NSData *key, NSData *data) {
    unsigned char mac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, data.bytes, data.length, mac);
    return [NSData dataWithBytes:mac length:sizeof(mac)];
}

static NSData *HKDF_Extract(NSData *salt, NSData *ikm) { return HMAC_SHA256(salt, ikm); }

static NSData *HKDF_Expand(NSData *prk, NSData *info, size_t outLen) {
    NSMutableData *okm = [NSMutableData dataWithCapacity:outLen];
    NSData *t = [NSData data];
    uint8_t counter = 1;

    while (okm.length < outLen) {
        NSMutableData *input = [NSMutableData data];
        [input appendData:t];
        [input appendData:info];
        [input appendBytes:&counter length:1];

        t = HMAC_SHA256(prk, input);
        [okm appendData:t];
        counter++;
    }
    return [okm subdataWithRange:NSMakeRange(0, outLen)];
}

- (BOOL)ensureIdentityKeypair {
    if (_privKey && _pubKey) return YES;

    NSData *tagPriv = [kKeyTagPriv dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *qPriv = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassKey,
        (__bridge id)kSecAttrApplicationTag: tagPriv,
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecReturnRef: @YES
    };

    SecKeyRef priv = NULL;
    OSStatus s = SecItemCopyMatching((__bridge CFDictionaryRef)qPriv, (CFTypeRef *)&priv);
    if (s == errSecSuccess && priv) {
        _privKey = priv;
        _pubKey = SecKeyCopyPublicKey(_privKey);
        return (_pubKey != NULL);
    }

    NSDictionary *attrs = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeySizeInBits: @256,
        (__bridge id)kSecPrivateKeyAttrs: @{
            (__bridge id)kSecAttrIsPermanent: @YES,
            (__bridge id)kSecAttrApplicationTag: tagPriv
        }
    };

    CFErrorRef err = NULL;
    SecKeyRef newPriv = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attrs, &err);
    if (!newPriv) return NO;

    _privKey = newPriv;
    _pubKey = SecKeyCopyPublicKey(_privKey);
    return (_pubKey != NULL);
}

- (NSData *)myPublicKeyData {
    [self ensureIdentityKeypair];
    CFErrorRef err = NULL;
    CFDataRef pubData = SecKeyCopyExternalRepresentation(_pubKey, &err);
    if (!pubData) return [NSData data];
    return CFBridgingRelease(pubData);
}

- (SecKeyRef)secKeyFromPeerPublicKeyData:(NSData *)peerData {
    NSDictionary *attrs = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
        (__bridge id)kSecAttrKeySizeInBits: @256
    };
    CFErrorRef err = NULL;
    return SecKeyCreateWithData((__bridge CFDataRef)peerData, (__bridge CFDictionaryRef)attrs, &err);
}

- (NSDictionary<NSString *,NSData *> *)deriveSessionKeysWithPeerPublicKey:(NSData *)peerPubKey peerId:(NSString *)peerId {
    NSDictionary *cached = _sessionKeys[peerId];
    if (cached) return cached;

    [self ensureIdentityKeypair];

    SecKeyRef peerKey = [self secKeyFromPeerPublicKeyData:peerPubKey];
    if (!peerKey) return @{};

    CFErrorRef err = NULL;
    CFDataRef shared = SecKeyCopyKeyExchangeResult(
        _privKey,
        kSecKeyAlgorithmECDHKeyExchangeStandardX963SHA256,
        peerKey,
        (__bridge CFDictionaryRef)@{},
        &err
    );
    CFRelease(peerKey);
    if (!shared) return @{};

    NSData *ikm = CFBridgingRelease(shared);
    NSData *salt = [@"nyxsocial.hkdf.salt" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *prk = HKDF_Extract(salt, ikm);

    NSData *infoEnc = [[NSString stringWithFormat:@"enc:%@", peerId] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *infoMac = [[NSString stringWithFormat:@"mac:%@", peerId] dataUsingEncoding:NSUTF8StringEncoding];

    NSData *encKey = HKDF_Expand(prk, infoEnc, 32);
    NSData *macKey = HKDF_Expand(prk, infoMac, 32);

    NSDictionary *keys = @{@"enc": encKey, @"mac": macKey};
    _sessionKeys[peerId] = keys;
    return keys;
}

- (NSDictionary *)encryptMessage:(NSData *)plaintext peerId:(NSString *)peerId {
    NSDictionary *keys = _sessionKeys[peerId];
    if (!keys) return @{};

    NSData *encKey = keys[@"enc"];
    NSData *macKey = keys[@"mac"];
    NSData *iv = RandomBytes(16);

    size_t outLen = plaintext.length + kCCBlockSizeAES128;
    NSMutableData *cipher = [NSMutableData dataWithLength:outLen];
    size_t moved = 0;

    CCCryptorStatus st = CCCrypt(kCCEncrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                encKey.bytes, encKey.length, iv.bytes,
                                plaintext.bytes, plaintext.length,
                                cipher.mutableBytes, cipher.length, &moved);
    if (st != kCCSuccess) return @{};

    cipher.length = moved;

    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    NSData *header = [[NSString stringWithFormat:@"v1|%@|%.0f", peerId, ts] dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *macInput = [NSMutableData data];
    [macInput appendData:header];
    [macInput appendData:iv];
    [macInput appendData:cipher];

    NSData *tag = HMAC_SHA256(macKey, macInput);

    return @{@"v":@"1",
             @"peerId":peerId,
             @"ts":@((long long)ts),
             @"iv":[iv base64EncodedStringWithOptions:0],
             @"ct":[cipher base64EncodedStringWithOptions:0],
             @"tag":[tag base64EncodedStringWithOptions:0]};
}

- (NSData *)decryptMessagePacket:(NSDictionary *)packet peerId:(NSString *)peerId {
    NSDictionary *keys = _sessionKeys[peerId];
    if (!keys) return nil;

    NSData *encKey = keys[@"enc"];
    NSData *macKey = keys[@"mac"];

    NSData *iv = [[NSData alloc] initWithBase64EncodedString:packet[@"iv"] options:0];
    NSData *ct = [[NSData alloc] initWithBase64EncodedString:packet[@"ct"] options:0];
    NSData *tag = [[NSData alloc] initWithBase64EncodedString:packet[@"tag"] options:0];
    if (!iv || !ct || !tag) return nil;

    long long ts = [packet[@"ts"] longLongValue];
    NSData *header = [[NSString stringWithFormat:@"v1|%@|%lld", peerId, ts] dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *macInput = [NSMutableData data];
    [macInput appendData:header];
    [macInput appendData:iv];
    [macInput appendData:ct];

    NSData *expect = HMAC_SHA256(macKey, macInput);
    if (![expect isEqualToData:tag]) return nil;

    size_t outLen = ct.length + kCCBlockSizeAES128;
    NSMutableData *pt = [NSMutableData dataWithLength:outLen];
    size_t moved = 0;

    CCCryptorStatus st = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                encKey.bytes, encKey.length, iv.bytes,
                                ct.bytes, ct.length,
                                pt.mutableBytes, pt.length, &moved);
    if (st != kCCSuccess) return nil;
    pt.length = moved;
    return pt;
}
@end
