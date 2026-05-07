#import "IRRootTabBarController.h"

#import "IRAppContainer.h"
#import "IRCatalogViewController.h"
#import "IRLibraryViewController.h"
#import "IRSourcesViewController.h"

@implementation IRRootTabBarController

- (instancetype)initWithContainer:(IRAppContainer *)container {
    self = [super init];
    if (self) {
        IRLibraryViewController *libraryViewController = [[IRLibraryViewController alloc] initWithContainer:container];
        UINavigationController *libraryNavigationController = [[UINavigationController alloc] initWithRootViewController:libraryViewController];
        libraryNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Library" image:nil tag:0];

        IRCatalogViewController *catalogViewController = [[IRCatalogViewController alloc] initWithContainer:container];
        UINavigationController *catalogNavigationController = [[UINavigationController alloc] initWithRootViewController:catalogViewController];
        catalogNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Catalog" image:nil tag:1];

        IRSourcesViewController *sourcesViewController = [[IRSourcesViewController alloc] initWithContainer:container];
        UINavigationController *sourcesNavigationController = [[UINavigationController alloc] initWithRootViewController:sourcesViewController];
        sourcesNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Sources" image:nil tag:2];

        self.viewControllers = @[libraryNavigationController, catalogNavigationController, sourcesNavigationController];
        self.selectedIndex = 0;
    }
    return self;
}

@end
