#import "ChatViewController.h"
#import "ChatService.h"

@interface ChatViewController () <UITableViewDataSource>
@property NSString *peer;
@property UITableView *table;
@property UITextField *input;
@end

@implementation ChatViewController
- (instancetype)initWithPeerUsername:(NSString *)peer { if ((self=[super init])) _peer = peer.lowercaseString; return self; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = self.peer;

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *bar = [UIView new];
    bar.translatesAutoresizingMaskIntoConstraints = NO;

    self.input = [UITextField new];
    self.input.borderStyle = UITextBorderStyleRoundedRect;
    self.input.placeholder = @"message";
    self.input.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *send = [UIButton buttonWithType:UIButtonTypeSystem];
    [send setTitle:@"Send" forState:UIControlStateNormal];
    send.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    send.translatesAutoresizingMaskIntoConstraints = NO;
    [send addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];

    [bar addSubview:self.input];
    [bar addSubview:send];
    [self.view addSubview:self.table];
    [self.view addSubview:bar];

    [NSLayoutConstraint activateConstraints:@[
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:bar.topAnchor],

        [bar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [bar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [bar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [bar.heightAnchor constraintEqualToConstant:44],

        [self.input.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],
        [self.input.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [send.leadingAnchor constraintEqualToAnchor:self.input.trailingAnchor constant:10],
        [send.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor],
        [send.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
        [self.input.heightAnchor constraintEqualToConstant:36],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"ChatServiceDidUpdate" object:nil];
    [self reload];
}

- (void)reload { [self.table reloadData]; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [ChatService shared].messagesByUser[self.peer].count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"m"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"m"];
    NSArray *arr = [ChatService shared].messagesByUser[self.peer];
    c.textLabel.text = arr[indexPath.row];
    c.textLabel.numberOfLines = 0;
    return c;
}

- (void)onSend {
    NSString *t = self.input.text ?: @"";
    if (!t.length) return;
    self.input.text = @"";
    [[ChatService shared] sendText:t toUsername:self.peer completion:^(BOOL ok, NSDictionary *resp) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reload];
            if (!ok) NSLog(@"Send failed: %@", resp);
        });
    }];
}
@end
