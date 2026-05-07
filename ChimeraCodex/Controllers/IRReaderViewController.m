#import "IRReaderViewController.h"

#import <math.h>
#import <QuartzCore/QuartzCore.h>

#import "IRAppContainer.h"
#import "IRChapter.h"
#import "IRLibraryStore.h"
#import "IRManga.h"
#import "IRPage.h"
#import "IRPageRenderer.h"
#import "IRReaderSettings.h"
#import "IRReadingProgress.h"
#import "IRRemoteImageLoader.h"
#import "IRSourceProtocol.h"

@interface IRReaderViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) IRChapter *chapter;
@property (nonatomic, strong) IRAppContainer *container;
@property (nonatomic, assign) NSInteger currentTrackedPageNumber;
@property (nonatomic, assign) BOOL didRestoreProgress;
@property (nonatomic, assign) CGFloat laidOutWidth;
@property (nonatomic, strong) IRManga *manga;
@property (nonatomic, copy) NSArray<IRPage *> *pages;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *pageViews;
@property (nonatomic, strong) IRReaderSettings *readerSettings;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, copy) NSString *requestGroup;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) CGFloat previousBrightness;
@property (nonatomic, assign) BOOL previousIdleTimerDisabled;

@end

@implementation IRReaderViewController

- (instancetype)initWithManga:(IRManga *)manga
                      chapter:(IRChapter *)chapter
                    container:(IRAppContainer *)container {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _manga = manga;
        _chapter = chapter;
        _container = container;
        _pageViews = [NSMutableArray array];
        _pages = @[];
        _readerSettings = [container.libraryStore readerSettings];
        _laidOutWidth = 0.0;
        _currentTrackedPageNumber = 0;
        _didRestoreProgress = NO;
        _requestGroup = [NSString stringWithFormat:@"reader.%@.%@", manga.sourceIdentifier ?: @"source", chapter.chapterID ?: @"chapter"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.chapter.title;
    self.navigationItem.prompt = self.manga.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Options"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(showOptions)];
    self.view.backgroundColor = [UIColor colorWithRed:0.16 green:0.17 blue:0.19 alpha:1.0];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicatorView startAnimating];
    [self.view addSubview:self.activityIndicatorView];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.text = @"Loading page list";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];

    self.retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    self.retryButton.tintColor = [UIColor whiteColor];
    self.retryButton.hidden = YES;
    [self.retryButton addTarget:self action:@selector(loadPages) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.retryButton];

    [self loadPages];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyReaderSettings];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.container.imageLoader cancelRequestsWithPrefix:self.requestGroup];
    [self restoreBrightnessState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGSize boundsSize = self.view.bounds.size;
    self.activityIndicatorView.center = CGPointMake(boundsSize.width * 0.5, boundsSize.height * 0.5 - 24.0);
    self.statusLabel.frame = CGRectMake(30.0, CGRectGetMaxY(self.activityIndicatorView.frame) + 12.0, boundsSize.width - 60.0, 44.0);
    self.retryButton.frame = CGRectMake((boundsSize.width - 120.0) * 0.5, CGRectGetMaxY(self.statusLabel.frame) + 12.0, 120.0, 36.0);

    [self layoutPagesIfNeeded];
}

- (void)loadPages {
    [self.container.imageLoader cancelRequestsWithPrefix:self.requestGroup];
    self.retryButton.hidden = YES;
    self.activityIndicatorView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    self.statusLabel.hidden = NO;
    self.statusLabel.text = @"Loading page list";
    self.didRestoreProgress = NO;
    self.currentTrackedPageNumber = 0;

    __weak typeof(self) weakSelf = self;
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:self.manga.sourceIdentifier];
    [source fetchPagesForManga:self.manga chapter:self.chapter completion:^(NSArray<IRPage *> *pages, NSError *error) {
        if (error != nil) {
            weakSelf.statusLabel.text = @"Could not load pages";
            [weakSelf.activityIndicatorView stopAnimating];
            weakSelf.retryButton.hidden = NO;
            return;
        }

        NSArray<IRPage *> *resolvedPages = pages ?: @[];
        if (weakSelf.readerSettings.reversePageOrder) {
            resolvedPages = [[resolvedPages reverseObjectEnumerator] allObjects];
        }

        weakSelf.pages = resolvedPages;
        [weakSelf.activityIndicatorView stopAnimating];
        if (weakSelf.pages.count == 0) {
            weakSelf.statusLabel.text = @"No pages found";
            weakSelf.retryButton.hidden = NO;
            return;
        }

        weakSelf.activityIndicatorView.hidden = YES;
        weakSelf.statusLabel.hidden = YES;
        weakSelf.retryButton.hidden = YES;
        [weakSelf rebuildPageViews];
    }];
}

- (void)rebuildPageViews {
    for (UIImageView *pageView in self.pageViews) {
        [pageView removeFromSuperview];
    }

    [self.pageViews removeAllObjects];
    for (IRPage *page in self.pages) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        imageView.layer.shadowOpacity = 0.18f;
        imageView.layer.shadowRadius = 10.0f;
        imageView.layer.shadowOffset = CGSizeMake(0.0, 4.0);
        [self.scrollView addSubview:imageView];
        [self.pageViews addObject:imageView];
        (void)page;
    }

    self.laidOutWidth = 0.0;
    [self layoutPagesIfNeeded];
}

- (void)layoutPagesIfNeeded {
    if (self.pages.count == 0) {
        self.scrollView.contentSize = CGSizeZero;
        return;
    }

    CGFloat targetWidth = CGRectGetWidth(self.view.bounds) - 28.0;
    if (fabs(targetWidth - self.laidOutWidth) < 0.5) {
        return;
    }

    self.laidOutWidth = targetWidth;
    CGFloat pageGap = self.readerSettings.pageGap;
    CGFloat pageHeight = self.readerSettings.fitMode == IRReaderFitModeHeight
        ? MAX(280.0, floor(CGRectGetHeight(self.view.bounds) - 36.0))
        : floor(targetWidth * 1.35);
    CGFloat yOffset = 14.0;

    [self.pages enumerateObjectsUsingBlock:^(IRPage *page, NSUInteger index, BOOL *stop) {
        UIImageView *imageView = self.pageViews[index];
        CGSize targetSize = CGSizeMake(targetWidth, pageHeight);
        imageView.frame = CGRectMake(14.0, yOffset, targetWidth, pageHeight);
        imageView.image = [IRPageRenderer imageForPage:page size:targetSize];
        [self requestRemoteImageForPage:page targetSize:targetSize];
        yOffset += pageHeight + pageGap;
        (void)stop;
    }];

    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), yOffset);
    [self restoreProgressIfNeededWithPageHeight:pageHeight pageGap:pageGap];
    [self updateProgressForCurrentOffsetWithPageHeight:pageHeight pageGap:pageGap];
}

- (void)requestRemoteImageForPage:(IRPage *)page targetSize:(CGSize)targetSize {
    NSUInteger index = [self.pages indexOfObject:page];
    if (index == NSNotFound) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:self.manga.sourceIdentifier];
    [self.container.imageLoader loadImageForPage:page
                                           manga:self.manga
                                         chapter:self.chapter
                                          source:source
                                      targetSize:targetSize
                                    requestGroup:self.requestGroup
                                      completion:^(UIImage *image, NSError *error) {
        NSUInteger liveIndex = [weakSelf.pages indexOfObject:page];
        if (liveIndex == NSNotFound || liveIndex >= weakSelf.pageViews.count) {
            return;
        }

        UIImageView *imageView = weakSelf.pageViews[liveIndex];
        imageView.image = image;
        (void)error;
    }];
}

- (void)restoreProgressIfNeededWithPageHeight:(CGFloat)pageHeight pageGap:(CGFloat)pageGap {
    if (self.didRestoreProgress) {
        return;
    }

    IRReadingProgress *progress = [self.container.libraryStore readingProgressForMangaID:self.manga.mangaID sourceIdentifier:self.manga.sourceIdentifier];
    if (![progress.chapterID isEqualToString:self.chapter.chapterID]) {
        self.didRestoreProgress = YES;
        return;
    }

    NSUInteger targetIndex = NSNotFound;
    for (NSUInteger index = 0; index < self.pages.count; index++) {
        if (self.pages[index].pageNumber == progress.currentPage) {
            targetIndex = index;
            break;
        }
    }

    if (targetIndex == NSNotFound) {
        targetIndex = 0;
    }

    CGFloat targetOffset = targetIndex * (pageHeight + pageGap);
    [self.scrollView setContentOffset:CGPointMake(0.0, MAX(0.0, targetOffset)) animated:NO];
    self.didRestoreProgress = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageHeight = self.readerSettings.fitMode == IRReaderFitModeHeight
        ? MAX(280.0, floor(CGRectGetHeight(self.view.bounds) - 36.0))
        : floor((CGRectGetWidth(self.view.bounds) - 28.0) * 1.35);
    [self updateProgressForCurrentOffsetWithPageHeight:pageHeight pageGap:self.readerSettings.pageGap];
    (void)scrollView;
}

- (void)updateProgressForCurrentOffsetWithPageHeight:(CGFloat)pageHeight pageGap:(CGFloat)pageGap {
    if (self.pages.count == 0) {
        return;
    }

    CGFloat unit = MAX(1.0, pageHeight + pageGap);
    NSInteger pageIndex = (NSInteger)floor((self.scrollView.contentOffset.y + (pageHeight * 0.5)) / unit);
    pageIndex = MAX(0, MIN(pageIndex, (NSInteger)self.pages.count - 1));

    IRPage *currentPage = self.pages[pageIndex];
    if (currentPage.pageNumber == self.currentTrackedPageNumber) {
        return;
    }

    self.currentTrackedPageNumber = currentPage.pageNumber;
    [self.container.libraryStore saveReadingProgressForMangaID:self.manga.mangaID
                                              sourceIdentifier:self.manga.sourceIdentifier
                                                     mangaName:self.manga.name
                                                     chapterID:self.chapter.chapterID
                                                  chapterTitle:self.chapter.title
                                                   currentPage:currentPage.pageNumber
                                                    totalPages:self.pages.count];
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:self.manga.sourceIdentifier];
    [self.container.imageLoader prefetchPages:self.pages
                                    fromIndex:(NSUInteger)pageIndex + 1
                                        manga:self.manga
                                      chapter:self.chapter
                                       source:source
                                   targetSize:CGSizeMake(MAX(100.0, CGRectGetWidth(self.view.bounds) - 28.0), pageHeight)
                                 requestGroup:self.requestGroup];
}

- (void)applyReaderSettings {
    self.readerSettings = [self.container.libraryStore readerSettings];
    self.scrollView.pagingEnabled = self.readerSettings.fitMode == IRReaderFitModeHeight;
    self.scrollView.alwaysBounceVertical = YES;

    self.previousIdleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = self.readerSettings.brightnessLockEnabled;

    if (self.readerSettings.brightnessLockEnabled) {
        self.previousBrightness = [UIScreen mainScreen].brightness;
        [UIScreen mainScreen].brightness = self.readerSettings.preferredBrightness;
    }

    if (self.pages.count > 0) {
        NSArray<IRPage *> *pages = [self.pages sortedArrayUsingComparator:^NSComparisonResult(IRPage *left, IRPage *right) {
            if (left.pageNumber == right.pageNumber) {
                return NSOrderedSame;
            }

            if (self.readerSettings.reversePageOrder) {
                return left.pageNumber < right.pageNumber ? NSOrderedDescending : NSOrderedAscending;
            }
            return left.pageNumber < right.pageNumber ? NSOrderedAscending : NSOrderedDescending;
        }];

        self.pages = pages;
        self.laidOutWidth = 0.0;
        [self layoutPagesIfNeeded];
    }
}

- (void)restoreBrightnessState {
    [UIApplication sharedApplication].idleTimerDisabled = self.previousIdleTimerDisabled;
    if (self.readerSettings.brightnessLockEnabled) {
        [UIScreen mainScreen].brightness = self.previousBrightness;
    }
}

- (void)showOptions {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Reader Options"
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    controller.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;

    [controller addAction:[UIAlertAction actionWithTitle:@"Fit Width" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:IRReaderFitModeWidth
                                    pageGap:self.readerSettings.pageGap
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    [controller addAction:[UIAlertAction actionWithTitle:@"Fit Height" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:IRReaderFitModeHeight
                                    pageGap:self.readerSettings.pageGap
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    [controller addAction:[UIAlertAction actionWithTitle:@"Gap Tight" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:self.readerSettings.fitMode
                                    pageGap:8.0
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    [controller addAction:[UIAlertAction actionWithTitle:@"Gap Normal" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:self.readerSettings.fitMode
                                    pageGap:18.0
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    [controller addAction:[UIAlertAction actionWithTitle:@"Gap Wide" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:self.readerSettings.fitMode
                                    pageGap:28.0
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    NSString *directionTitle = self.readerSettings.reversePageOrder ? @"Reading Order Normal" : @"Reading Order Reverse";
    [controller addAction:[UIAlertAction actionWithTitle:directionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:self.readerSettings.fitMode
                                    pageGap:self.readerSettings.pageGap
                           reversePageOrder:!self.readerSettings.reversePageOrder
                      brightnessLockEnabled:self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    NSString *brightnessTitle = self.readerSettings.brightnessLockEnabled ? @"Brightness Lock Off" : @"Brightness Lock On";
    [controller addAction:[UIAlertAction actionWithTitle:brightnessTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveReaderSettingsWithFitMode:self.readerSettings.fitMode
                                    pageGap:self.readerSettings.pageGap
                           reversePageOrder:self.readerSettings.reversePageOrder
                      brightnessLockEnabled:!self.readerSettings.brightnessLockEnabled];
        (void)action;
    }]];

    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)saveReaderSettingsWithFitMode:(IRReaderFitMode)fitMode
                              pageGap:(CGFloat)pageGap
                     reversePageOrder:(BOOL)reversePageOrder
                brightnessLockEnabled:(BOOL)brightnessLockEnabled {
    CGFloat preferredBrightness = self.readerSettings.brightnessLockEnabled ? self.readerSettings.preferredBrightness : [UIScreen mainScreen].brightness;
    IRReaderSettings *settings = [[IRReaderSettings alloc] initWithFitMode:fitMode
                                                                   pageGap:pageGap
                                                          reversePageOrder:reversePageOrder
                                                     brightnessLockEnabled:brightnessLockEnabled
                                                       preferredBrightness:preferredBrightness];
    [self.container.libraryStore saveReaderSettings:settings];
    [self restoreBrightnessState];
    self.readerSettings = settings;
    [self applyReaderSettings];
}

@end
