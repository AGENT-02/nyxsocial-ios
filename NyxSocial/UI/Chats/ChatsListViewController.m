#import "ChatsListViewController.h"
#import "ChatViewController.h"
#import "ChatService.h"

@implementation ChatsListViewController {
    NSArray<NSString *> *_users;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Chats";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(onNew)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"ChatServiceDidUpdate" object:nil];
    [self reload];
}

- (void)reload {
    _users = [[[ChatService shared].messagesByUser allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [self.tableView reloadData];
}

- (void)onNew {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"New Chat" message:@"Enter username" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf){ tf.placeholder=@"username"; tf.autocapitalizationType=UITextAutocapitalizationTypeNone; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Open" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){
        NSString *u = a.textFields.firstObject.text.lowercaseString;
        if (!u.length) return;
        [self.navigationController pushViewController:[[ChatViewController alloc] initWithPeerUsername:u] animated:YES];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _users.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"c"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"c"];
    NSString *u = _users[indexPath.row];
    c.textLabel.text = u;
    NSArray *arr = [ChatService shared].messagesByUser[u];
    c.detailTextLabel.text = arr.lastObject ?: @"";
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return c;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController pushViewController:[[ChatViewController alloc] initWithPeerUsername:_users[indexPath.row]] animated:YES];
}
@end
