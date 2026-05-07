#import "AppDelegate.h"

#import "IRAppContainer.h"
#import "IRLibraryStore.h"
#import "IRSourceRegistry.h"
#import "IRRemoteImageCache.h"
#import "IRRemoteImageLoader.h"
#import "IRRootTabBarController.h"

@interface AppDelegate ()

@property (nonatomic, strong) IRAppContainer *container;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    IRSourceRegistry *sourceRegistry = [[IRSourceRegistry alloc] init];
    IRLibraryStore *libraryStore = [[IRLibraryStore alloc] init];
    IRRemoteImageCache *imageCache = [[IRRemoteImageCache alloc] initWithCacheFolderName:@"ChimeraCodexImageCache"];
    [imageCache cleanupIfNeeded];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 3;
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    IRRemoteImageLoader *imageLoader = [[IRRemoteImageLoader alloc] initWithCache:imageCache
                                                              sessionConfiguration:sessionConfiguration];
    self.container = [[IRAppContainer alloc] initWithSourceRegistry:sourceRegistry
                                                       libraryStore:libraryStore
                                                        imageLoader:imageLoader];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.tintColor = [UIColor colorWithRed:0.12 green:0.25 blue:0.44 alpha:1.0];
    self.window.rootViewController = [[IRRootTabBarController alloc] initWithContainer:self.container];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
