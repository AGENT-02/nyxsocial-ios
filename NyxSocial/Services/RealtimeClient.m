#import "RealtimeClient.h"
#import "KeychainTokenStore.h"
#import "ChatService.h"
#import "CallService.h"
#import "Config.h"

@implementation RealtimeClient {
    NSURLSession *_session;
    NSURLSessionWebSocketTask *_ws;
    BOOL _shouldRun;
}
+ (instancetype)shared { static id s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new];}); return s; }

- (instancetype)init { if ((self=[super init])) { _wsBaseURL = kWSBaseURL; _session=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]]; } return self; }

- (void)connect {
    NSString *token = [[KeychainTokenStore shared] loadToken];
    if (!token.length) { NSLog(@"No token; login first"); return; }
    _shouldRun = YES;
    NSString *urlStr = [NSString stringWithFormat:@"%@/ws?token=%@", self.wsBaseURL, token];
    _ws = [_session webSocketTaskWithURL:[NSURL URLWithString:urlStr]];
    [_ws resume];
    [self listen];
}

- (void)disconnect {
    _shouldRun = NO;
    [_ws cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    _ws = nil;
}

- (void)listen {
    if (!_ws) return;
    __weak typeof(self) weakSelf = self;
    [_ws receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *msg, NSError *err) {
        __strong typeof(self) self = weakSelf;
        if (!self || !self->_shouldRun) return;
        if (!err) {
            NSString *text = msg.string;
            if (!text && msg.data) text = [[NSString alloc] initWithData:msg.data encoding:NSUTF8StringEncoding];
            if (text.length) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[text dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                if ([json isKindOfClass:[NSDictionary class]]) {
                    [[ChatService shared] handleIncomingEncrypted:json];
                    [[CallService shared] handleWS:json];
                }
            }
        } else {
            NSLog(@"WS receive err: %@", err);
        }
        [self listen];
    }];
}

- (void)sendJSON:(NSDictionary *)obj {
    if (!_ws) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSURLSessionWebSocketMessage *m = [[NSURLSessionWebSocketMessage alloc] initWithString:text];
    [_ws sendMessage:m completionHandler:^(NSError *err) { if (err) NSLog(@"WS send err: %@", err); }];
}
@end
