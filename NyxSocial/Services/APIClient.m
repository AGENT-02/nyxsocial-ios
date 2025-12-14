#import "APIClient.h"
#import "KeychainTokenStore.h"
#import "Config.h"

@implementation APIClient
+ (instancetype)shared { static id s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new];}); return s; }

- (instancetype)init { if ((self=[super init])) _baseURL = kAPIBaseURL; return self; }

- (NSMutableURLRequest *)req:(NSString *)path method:(NSString *)method body:(NSDictionary *)body {
    NSURL *url = [NSURL URLWithString:[self.baseURL stringByAppendingString:path]];
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:url];
    r.HTTPMethod = method;
    [r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *token = [[KeychainTokenStore shared] loadToken];
    if (token) [r setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    if (body) r.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    return r;
}

- (void)doReq:(NSMutableURLRequest *)r completion:(void(^)(NSDictionary *, NSError *))completion {
    [[[NSURLSession sharedSession] dataTaskWithRequest:r completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (err) return completion(nil, err);
        NSDictionary *json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : @{};
        completion(json, nil);
    }] resume];
}

- (void)registerUser:(NSString *)username password:(NSString *)password publicKeyB64:(NSString *)publicKeyB64 completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/register" method:@"POST" body:@{@"username":username?:@"", @"password":password?:@"", @"publicKeyB64":publicKeyB64?:@""}];
    [self doReq:r completion:^(NSDictionary *json, NSError *err) {
        if (json[@"token"]) [[KeychainTokenStore shared] saveToken:json[@"token"]];
        completion(json, err);
    }];
}

- (void)login:(NSString *)username password:(NSString *)password completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/login" method:@"POST" body:@{@"username":username?:@"", @"password":password?:@""}];
    [self doReq:r completion:^(NSDictionary *json, NSError *err) {
        if (json[@"token"]) [[KeychainTokenStore shared] saveToken:json[@"token"]];
        completion(json, err);
    }];
}

- (void)fetchUserKey:(NSString *)username completion:(void (^)(NSDictionary *, NSError *))completion {
    NSString *u = [[username lowercaseString] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSMutableURLRequest *r = [self req:[@"/v1/keys/" stringByAppendingString:(u?:@"")] method:@"GET" body:nil];
    [self doReq:r completion:^(NSDictionary *json, NSError *err) { completion(json[@"user"], err); }];
}

- (void)friendRequestTo:(NSString *)username completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/friends/request" method:@"POST" body:@{@"toUsername":username?:@""}];
    [self doReq:r completion:completion];
}

- (void)friendRequests:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/friends/requests" method:@"GET" body:nil];
    [self doReq:r completion:^(NSDictionary *json, NSError *err) { completion(json[@"requests"], err); }];
}

- (void)friendAccept:(NSNumber *)requestId completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/friends/accept" method:@"POST" body:@{@"requestId":requestId?:@0}];
    [self doReq:r completion:completion];
}

- (void)friendsList:(void (^)(NSArray *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/friends" method:@"GET" body:nil];
    [self doReq:r completion:^(NSDictionary *json, NSError *err) { completion(json[@"friends"], err); }];
}

- (void)sendEncryptedPacketTo:(NSString *)toUsername packet:(NSDictionary *)packet completion:(void (^)(NSDictionary *, NSError *))completion {
    NSMutableURLRequest *r = [self req:@"/v1/messages/send" method:@"POST" body:@{@"toUsername":toUsername?:@"", @"packet":packet?:@{}}];
    [self doReq:r completion:completion];
}
@end
