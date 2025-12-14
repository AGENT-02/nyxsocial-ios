#import <Foundation/Foundation.h>
@interface CryptoManager : NSObject
+ (instancetype)shared;
- (BOOL)ensureIdentityKeypair;
- (NSData *)myPublicKeyData;
- (NSDictionary<NSString *, NSData *> *)deriveSessionKeysWithPeerPublicKey:(NSData *)peerPubKey peerId:(NSString *)peerId;
- (NSDictionary *)encryptMessage:(NSData *)plaintext peerId:(NSString *)peerId;
- (NSData *)decryptMessagePacket:(NSDictionary *)packet peerId:(NSString *)peerId;
@end
