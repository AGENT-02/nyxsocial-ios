#import "RootTabBarController.h"
#import "ChatsListViewController.h"
#import "FriendsViewController.h"
#import "ProfileViewController.h"

@implementation RootTabBarController
- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *chats = [[UINavigationController alloc] initWithRootViewController:[ChatsListViewController new]];
    chats.tabBarItem.title = @"Chats";
    chats.tabBarItem.image = [UIImage systemImageNamed:@"message"];

    UINavigationController *friends = [[UINavigationController alloc] initWithRootViewController:[FriendsViewController new]];
    friends.tabBarItem.title = @"Friends";
    friends.tabBarItem.image = [UIImage systemImageNamed:@"person.2"];

    UINavigationController *profile = [[UINavigationController alloc] initWithRootViewController:[ProfileViewController new]];
    profile.tabBarItem.title = @"Profile";
    profile.tabBarItem.image = [UIImage systemImageNamed:@"gear"];

    self.viewControllers = @[chats, friends, profile];
}
@end
