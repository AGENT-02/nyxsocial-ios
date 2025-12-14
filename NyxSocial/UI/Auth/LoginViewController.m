#import "LoginViewController.h"
#import "APIClient.h"
#import "CryptoManager.h"

@interface LoginViewController ()
@property UITextField *userField;
@property UITextField *passField;
@property UILabel *status;
@end

@implementation LoginViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Auth";

    self.userField = [UITextField new];
    self.userField.placeholder = @"username (lowercase)";
    self.userField.borderStyle = UITextBorderStyleRoundedRect;
    self.userField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.passField = [UITextField new];
    self.passField.placeholder = @"password (8+ chars)";
    self.passField.borderStyle = UITextBorderStyleRoundedRect;
    self.passField.secureTextEntry = YES;

    UIButton *login = [UIButton buttonWithType:UIButtonTypeSystem];
    [login setTitle:@"Login" forState:UIControlStateNormal];
    login.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [login addTarget:self action:@selector(onLogin) forControlEvents:UIControlEventTouchUpInside];

    UIButton *reg = [UIButton buttonWithType:UIButtonTypeSystem];
    [reg setTitle:@"Register" forState:UIControlStateNormal];
    reg.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [reg addTarget:self action:@selector(onRegister) forControlEvents:UIControlEventTouchUpInside];

    self.status = [UILabel new];
    self.status.numberOfLines = 0;
    self.status.textColor = [UIColor secondaryLabelColor];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.userField, self.passField, login, reg, self.status]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)onLogin {
    self.status.text = @"Logging in...";
    [[APIClient shared] login:self.userField.text password:self.passField.text completion:^(NSDictionary *json, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status.text = err ? err.localizedDescription : [NSString stringWithFormat:@"%@", json];
        });
    }];
}

- (void)onRegister {
    self.status.text = @"Registering...";
    NSString *pubB64 = [[[CryptoManager shared] myPublicKeyData] base64EncodedStringWithOptions:0];
    [[APIClient shared] registerUser:self.userField.text password:self.passField.text publicKeyB64:pubB64 completion:^(NSDictionary *json, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status.text = err ? err.localizedDescription : [NSString stringWithFormat:@"%@", json];
        });
    }];
}
@end
