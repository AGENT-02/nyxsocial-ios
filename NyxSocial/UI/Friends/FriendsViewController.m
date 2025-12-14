#import "FriendsViewController.h"
#import "APIClient.h"

@implementation FriendsViewController {
    NSArray *_friends;
    NSArray *_requests;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Friends";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(onAdd)];
    [self refresh];
}
- (void)refresh {
    [[APIClient shared] friendsList:^(NSArray *friends, NSError *err){ self->_friends=friends?:@[]; dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; }); }];
    [[APIClient shared] friendRequests:^(NSArray *reqs, NSError *err){ self->_requests=reqs?:@[]; dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; }); }];
}
- (void)onAdd {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Add Friend" message:@"Enter username" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf){ tf.placeholder=@"username"; tf.autocapitalizationType=UITextAutocapitalizationTypeNone; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){
        NSString *u = a.textFields.firstObject.text.lowercaseString;
        if (!u.length) return;
        [[APIClient shared] friendRequestTo:u completion:^(NSDictionary *json, NSError *err){ NSLog(@"friend request: %@ err:%@", json, err); [self refresh]; }];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return section==0?@"Requests":@"Friends"; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section==0?_requests.count:_friends.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"f"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"f"];
    if (indexPath.section==0) {
        NSDictionary *r=_requests[indexPath.row];
        c.textLabel.text = r[@"from_username"] ?: r[@"fromUsername"] ?: @"(unknown)";
        c.detailTextLabel.text = [NSString stringWithFormat:@"tap i to accept (id %@)", r[@"id"]];
        c.accessoryType = UITableViewCellAccessoryDetailButton;
    } else {
        NSDictionary *f=_friends[indexPath.row];
        c.textLabel.text = f[@"username"] ?: @"";
        c.detailTextLabel.text = [NSString stringWithFormat:@"id %@", f[@"id"]];
        c.accessoryType = UITableViewCellAccessoryNone;
    }
    return c;
}
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section!=0) return;
    NSDictionary *r=_requests[indexPath.row];
    NSNumber *rid=r[@"id"];
    if (!rid) return;
    [[APIClient shared] friendAccept:rid completion:^(NSDictionary *json, NSError *err){ NSLog(@"accept: %@ err:%@", json, err); [self refresh]; }];
}
@end
