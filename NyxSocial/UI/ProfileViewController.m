#import "ProfileViewController.h"
#import "LoginViewController.h"
#import "KeychainTokenStore.h"
#import "RealtimeClient.h"
#import "CryptoManager.h"

@implementation ProfileViewController {
    UILabel *_tokenLabel;
    UILabel *_pubLabel;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor systemBackgroundColor];
    self.title=@"Profile";

    UIButton *auth=[UIButton buttonWithType:UIButtonTypeSystem];
    [auth setTitle:@"Open Auth Screen" forState:UIControlStateNormal];
    auth.titleLabel.font=[UIFont boldSystemFontOfSize:17];
    [auth addTarget:self action:@selector(onAuth) forControlEvents:UIControlEventTouchUpInside];

    UIButton *ws=[UIButton buttonWithType:UIButtonTypeSystem];
    [ws setTitle:@"Connect WebSocket" forState:UIControlStateNormal];
    ws.titleLabel.font=[UIFont boldSystemFontOfSize:17];
    [ws addTarget:self action:@selector(onConnect) forControlEvents:UIControlEventTouchUpInside];

    UIButton *logout=[UIButton buttonWithType:UIButtonTypeSystem];
    [logout setTitle:@"Logout (clear token)" forState:UIControlStateNormal];
    [logout addTarget:self action:@selector(onLogout) forControlEvents:UIControlEventTouchUpInside];

    _tokenLabel=[UILabel new]; _tokenLabel.numberOfLines=0; _tokenLabel.textColor=[UIColor secondaryLabelColor];
    _pubLabel=[UILabel new]; _pubLabel.numberOfLines=0; _pubLabel.textColor=[UIColor secondaryLabelColor];

    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[auth, ws, logout, _tokenLabel, _pubLabel]];
    stack.axis=UILayoutConstraintAxisVertical; stack.spacing=12; stack.translatesAutoresizingMaskIntoConstraints=NO;

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20]
    ]];

    [self refreshLabels];
}

- (void)refreshLabels {
    NSString *t=[[KeychainTokenStore shared] loadToken];
    _tokenLabel.text=[NSString stringWithFormat:@"JWT: %@", t.length?@"(saved)":@"(none)"];
    NSString *pubB64=[[[CryptoManager shared] myPublicKeyData] base64EncodedStringWithOptions:0];
    _pubLabel.text=[NSString stringWithFormat:@"PublicKeyB64 (first 40): %@", [pubB64 substringToIndex:MIN(40, pubB64.length)]];
}

- (void)onAuth { [self.navigationController pushViewController:[LoginViewController new] animated:YES]; }
- (void)onConnect { [[RealtimeClient shared] connect]; }
- (void)onLogout { [[KeychainTokenStore shared] clearToken]; [[RealtimeClient shared] disconnect]; [self refreshLabels]; }
@end
