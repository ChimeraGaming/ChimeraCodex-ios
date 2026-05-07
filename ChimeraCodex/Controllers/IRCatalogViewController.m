#import "IRCatalogViewController.h"

#import "IRAppContainer.h"
#import "IRLibraryStore.h"
#import "IRManga.h"
#import "IRMangaDetailViewController.h"
#import "IRMangaTableViewCell.h"
#import "IRPageRenderer.h"
#import "IRReadingProgress.h"
#import "IRRemoteImageLoader.h"
#import "IRSourceProtocol.h"

@interface IRCatalogViewController () <UISearchBarDelegate>

@property (nonatomic, copy) NSArray<IRManga *> *allManga;
@property (nonatomic, strong) IRAppContainer *container;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UISegmentedControl *filterControl;
@property (nonatomic, copy) NSString *loadErrorText;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *sortControl;
@property (nonatomic, copy) NSArray<IRManga *> *visibleManga;

@end

@implementation IRCatalogViewController

- (instancetype)initWithContainer:(IRAppContainer *)container {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _container = container;
        _allManga = @[];
        _visibleManga = @[];
        _searchText = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Catalog";
    self.navigationItem.prompt = self.container.source.displayName;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                             target:self
                                                                                             action:@selector(reloadCatalog)];
    self.tableView.rowHeight = [IRMangaTableViewCell preferredHeight];
    [self.tableView registerClass:[IRMangaTableViewCell class] forCellReuseIdentifier:@"CatalogCell"];

    [self buildSearchAndControls];
    [self buildEmptyState];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadCatalog)
                                                 name:IRAppContainerSourceDidChangeNotification
                                               object:self.container];
    [self reloadCatalog];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.container.imageLoader cancelRequestsWithPrefix:@"catalog"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildSearchAndControls {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 44.0)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search titles or genres";
    self.tableView.tableHeaderView = self.searchBar;

    self.filterControl = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Active", @"Done"]];
    self.filterControl.selectedSegmentIndex = 0;
    [self.filterControl addTarget:self action:@selector(applyFilters) forControlEvents:UIControlEventValueChanged];

    self.sortControl = [[UISegmentedControl alloc] initWithItems:@[@"Title", @"Chaps", @"Latest"]];
    self.sortControl.selectedSegmentIndex = 0;
    [self.sortControl addTarget:self action:@selector(applyFilters) forControlEvents:UIControlEventValueChanged];
}

- (void)buildEmptyState {
    self.emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.emptyLabel.font = [UIFont systemFontOfSize:18.0];
    self.emptyLabel.textColor = [UIColor grayColor];
    self.emptyLabel.numberOfLines = 0;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;

    self.retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.retryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [self.retryButton addTarget:self action:@selector(reloadCatalog) forControlEvents:UIControlEventTouchUpInside];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(tableView.bounds), 86.0)];
    containerView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];

    self.filterControl.frame = CGRectMake(12.0, 8.0, CGRectGetWidth(tableView.bounds) - 24.0, 30.0);
    self.sortControl.frame = CGRectMake(12.0, 46.0, CGRectGetWidth(tableView.bounds) - 24.0, 30.0);
    [containerView addSubview:self.filterControl];
    [containerView addSubview:self.sortControl];
    (void)section;
    return containerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 86.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.visibleManga.count;
}

- (IRMangaTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IRMangaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CatalogCell" forIndexPath:indexPath];
    IRManga *manga = self.visibleManga[indexPath.row];
    IRReadingProgress *progress = [self.container.libraryStore readingProgressForMangaID:manga.mangaID sourceIdentifier:manga.sourceIdentifier];
    NSString *metadata = [NSString stringWithFormat:@"%@  %@ chapters", [manga statusText], @(manga.estimatedChapterCount)];
    NSString *summary = [NSString stringWithFormat:@"%@  Latest: %@", manga.genreText, manga.latestChapterTitle];
    [cell applyTitle:manga.name
            metadata:metadata
             summary:summary
            progress:[progress progressText]];
    cell.representedMangaID = manga.mangaID;

    UIImage *placeholder = [IRPageRenderer coverImageForTitle:manga.name subtitle:manga.genreText size:CGSizeMake(56.0, 80.0)];
    [cell applyCoverImage:placeholder];

    __weak typeof(cell) weakCell = cell;
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:manga.sourceIdentifier];
    [self.container.imageLoader loadCoverForManga:manga
                                           source:source
                                       targetSize:CGSizeMake(56.0, 80.0)
                                     requestGroup:@"catalog"
                                       completion:^(UIImage *image, NSError *error) {
        if ([weakCell.representedMangaID isEqualToString:manga.mangaID]) {
            [weakCell applyCoverImage:image ?: placeholder];
        }
        (void)error;
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    IRManga *manga = self.visibleManga[indexPath.row];
    IRMangaDetailViewController *detailViewController = [[IRMangaDetailViewController alloc] initWithManga:manga container:self.container];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)reloadCatalog {
    self.navigationItem.prompt = self.container.source.displayName;
    self.loadErrorText = nil;
    __weak typeof(self) weakSelf = self;
    [self.container.source fetchCatalogWithCompletion:^(NSArray<IRManga *> *mangaList, NSError *error) {
        if (error != nil) {
            weakSelf.loadErrorText = @"Could not load catalog. Tap Retry to try again.";
            weakSelf.allManga = @[];
            weakSelf.visibleManga = @[];
            [weakSelf.tableView reloadData];
            [weakSelf updateBackgroundState];
            return;
        }

        weakSelf.allManga = mangaList ?: @[];
        [weakSelf applyFilters];
    }];
}

- (void)applyFilters {
    NSString *query = [self.searchText lowercaseString];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(IRManga *manga, NSDictionary *bindings) {
        BOOL matchesText = query.length == 0
            || [[manga.name lowercaseString] containsString:query]
            || [[manga.summary lowercaseString] containsString:query]
            || [[manga.genreText lowercaseString] containsString:query];

        BOOL matchesFilter = YES;
        if (self.filterControl.selectedSegmentIndex == 1) {
            matchesFilter = manga.status != IRMangaStatusComplete;
        } else if (self.filterControl.selectedSegmentIndex == 2) {
            matchesFilter = manga.status == IRMangaStatusComplete;
        }

        (void)bindings;
        return matchesText && matchesFilter;
    }];

    NSArray<IRManga *> *results = [self.allManga filteredArrayUsingPredicate:predicate];
    results = [results sortedArrayUsingComparator:^NSComparisonResult(IRManga *left, IRManga *right) {
        switch (self.sortControl.selectedSegmentIndex) {
            case 1:
                if (left.estimatedChapterCount == right.estimatedChapterCount) {
                    return [left.name compare:right.name];
                }
                return left.estimatedChapterCount < right.estimatedChapterCount ? NSOrderedDescending : NSOrderedAscending;
            case 2:
                return [right.latestChapterTitle compare:left.latestChapterTitle];
            case 0:
            default:
                return [left.name compare:right.name];
        }
    }];

    self.visibleManga = results;
    [self.tableView reloadData];
    [self updateBackgroundState];
}

- (void)updateBackgroundState {
    if (self.loadErrorText.length > 0) {
        UIView *stateView = [self stateViewWithText:self.loadErrorText showRetry:YES];
        self.tableView.backgroundView = stateView;
        return;
    }

    if (self.visibleManga.count == 0) {
        NSString *text = self.allManga.count == 0 ? @"No catalog titles are available." : @"No titles match the current search or filters.";
        UIView *stateView = [self stateViewWithText:text showRetry:NO];
        self.tableView.backgroundView = stateView;
        return;
    }

    self.tableView.backgroundView = nil;
}

- (UIView *)stateViewWithText:(NSString *)text showRetry:(BOOL)showRetry {
    UIView *containerView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    self.emptyLabel.text = text;
    self.emptyLabel.frame = CGRectMake(24.0, 120.0, CGRectGetWidth(containerView.bounds) - 48.0, 64.0);
    [containerView addSubview:self.emptyLabel];

    if (showRetry) {
        self.retryButton.frame = CGRectMake((CGRectGetWidth(containerView.bounds) - 140.0) * 0.5, CGRectGetMaxY(self.emptyLabel.frame) + 12.0, 140.0, 36.0);
        [containerView addSubview:self.retryButton];
    }
    return containerView;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText = searchText ?: @"";
    [self applyFilters];
    (void)searchBar;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end
