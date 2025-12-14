#import "ChatService.h"
#import "APIClient.h"
#import "CryptoManager.h"

@implementation ChatService {
    NSMutableDictionary<NSString *, NSData *> *_peerPub;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *_msgs;
}
+ (instancetype)shared { static id s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new];}); return s; }
- (instancetype)init { if ((self=[super init])) { _peerPub=[NSMutableDictionary dictionary]; _msgs=[NSMutableDictionary dictionary]; } return self; }
- (NSDictionary *)messagesByUser { return _msgs; }

- (void)prepareSessionForUsername:(NSString *)username completion:(void (^)(BOOL))completion {
    NSString *u = [username lowercaseString];
    [[APIClient shared] fetchUserKey:u completion:^(NSDictionary *user, NSError *err) {
        if (err || !user[@"public_key_b64"]) return completion(NO);
        NSData *peerPub = [[NSData alloc] initWithBase64EncodedString:user[@"public_key_b64"] options:0];
        if (!peerPub) return completion(NO);
        self->_peerPub[u] = peerPub;
        [[CryptoManager shared] deriveSessionKeysWithPeerPublicKey:peerPub peerId:u];
        completion(YES);
    }];
}

- (void)sendText:(NSString *)text toUsername:(NSString *)username completion:(void (^)(BOOL, NSDictionary * _Nullable))completion {
    NSString *u = [username lowercaseString];
    if (!self->_peerPub[u]) {
        [self prepareSessionForUsername:u completion:^(BOOL ok) {
            if (!ok) return completion(NO, nil);
            [self sendText:text toUsername:u completion:completion];
        }];
        return;
    }
    NSDictionary *packet = [[CryptoManager shared] encryptMessage:[text dataUsingEncoding:NSUTF8StringEncoding] peerId:u];
    [[APIClient shared] sendEncryptedPacketTo:u packet:packet completion:^(NSDictionary *json, NSError *err) {
        BOOL ok = (err == nil && json[@"ok"] != nil);
        if (ok) {
            NSMutableArray *arr = self->_msgs[u] ?: (self->_msgs[u] = [NSMutableArray array]);
            [arr addObject:[NSString stringWithFormat:@"me: %@", text]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatServiceDidUpdate" object:nil];
        }
        completion(ok, json);
    }];
}

- (void)handleIncomingEncrypted:(NSDictionary *)wsMsg {
    if (![wsMsg[@"type"] isEqual:@"msg_deliver"]) return;
    NSString *fromUsername = [wsMsg[@"fromUsername"] lowercaseString];
    NSDictionary *packet = wsMsg[@"packet"];
    if (!fromUsername || !packet) return;

    void (^finish)(void) = ^{
        NSData *pt = [[CryptoManager shared] decryptMessagePacket:packet peerId:fromUsername];
        if (!pt) return;
        NSString *text = [[NSString alloc] initWithData:pt encoding:NSUTF8StringEncoding] ?: @"(decode failed)";
        NSMutableArray *arr = self->_msgs[fromUsername] ?: (self->_msgs[fromUsername] = [NSMutableArray array]);
        [arr addObject:[NSString stringWithFormat:@"%@: %@", fromUsername, text]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChatServiceDidUpdate" object:nil];
    };

    if (!self->_peerPub[fromUsername]) {
        [[APIClient shared] fetchUserKey:fromUsername completion:^(NSDictionary *user, NSError *err) {
            NSData *pub = [[NSData alloc] initWithBase64EncodedString:user[@"public_key_b64"] options:0];
            if (!pub) return;
            self->_peerPub[fromUsername] = pub;
            [[CryptoManager shared] deriveSessionKeysWithPeerPublicKey:pub peerId:fromUsername];
            finish();
        }];
        return;
    }

    finish();
}
@end
