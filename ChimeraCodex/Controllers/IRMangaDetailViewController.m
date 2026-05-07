#import "IRMangaDetailViewController.h"

#import "IRAppContainer.h"
#import "IRChapter.h"
#import "IRLibraryStore.h"
#import "IRManga.h"
#import "IRPageRenderer.h"
#import "IRReaderViewController.h"
#import "IRReadingProgress.h"
#import "IRRemoteImageLoader.h"
#import "IRSourceProtocol.h"

@interface IRMangaDetailViewController ()

@property (nonatomic, copy) NSArray<IRChapter *> *chapters;
@property (nonatomic, strong) IRAppContainer *container;
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) NSError *chaptersError;
@property (nonatomic, assign) BOOL isLoadingChapters;
@property (nonatomic, strong) IRManga *manga;
@property (nonatomic, strong) IRReadingProgress *progress;
@property (nonatomic, strong) UILabel *summaryLabel;

@end

@implementation IRMangaDetailViewController

- (instancetype)initWithManga:(IRManga *)manga container:(IRAppContainer *)container {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _manga = manga;
        _container = container;
        _chapters = @[];
        _isLoadingChapters = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.manga.name;
    self.navigationItem.prompt = [self.container sourceForIdentifier:self.manga.sourceIdentifier].displayName;
    self.tableView.estimatedRowHeight = 80.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    [self buildHeaderView];
    [self refreshState];
    [self loadChapters];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshState];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSString *requestPrefix = [NSString stringWithFormat:@"detail.%@", self.manga.mangaID];
    [self.container.imageLoader cancelRequestsWithPrefix:requestPrefix];
}

- (void)buildHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 180.0)];

    self.coverView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, 16.0, 96.0, 136.0)];
    self.coverView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverView.clipsToBounds = YES;
    self.coverView.layer.cornerRadius = 8.0;
    self.coverView.image = [IRPageRenderer coverImageForTitle:self.manga.name subtitle:self.manga.genreText size:self.coverView.bounds.size];
    [headerView addSubview:self.coverView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(126.0, 16.0, CGRectGetWidth(headerView.bounds) - 142.0, 46.0)];
    titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.numberOfLines = 2;
    titleLabel.text = self.manga.name;
    [headerView addSubview:titleLabel];

    UILabel *metaLabel = [[UILabel alloc] initWithFrame:CGRectMake(126.0, 68.0, CGRectGetWidth(headerView.bounds) - 142.0, 20.0)];
    metaLabel.font = [UIFont systemFontOfSize:13.0];
    metaLabel.textColor = [UIColor grayColor];
    metaLabel.text = [NSString stringWithFormat:@"%@  %@ chapters  %@", [self.manga statusText], @(self.manga.estimatedChapterCount), self.manga.genreText];
    [headerView addSubview:metaLabel];

    self.summaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(126.0, 94.0, CGRectGetWidth(headerView.bounds) - 142.0, 58.0)];
    self.summaryLabel.font = [UIFont systemFontOfSize:13.0];
    self.summaryLabel.textColor = [UIColor colorWithRed:0.22 green:0.25 blue:0.28 alpha:1.0];
    self.summaryLabel.numberOfLines = 4;
    self.summaryLabel.text = self.manga.summary;
    [headerView addSubview:self.summaryLabel];

    self.tableView.tableHeaderView = headerView;

    __weak typeof(self) weakSelf = self;
    NSString *requestGroup = [NSString stringWithFormat:@"detail.%@", self.manga.mangaID];
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:self.manga.sourceIdentifier];
    [self.container.imageLoader loadCoverForManga:self.manga
                                           source:source
                                       targetSize:self.coverView.bounds.size
                                     requestGroup:requestGroup
                                       completion:^(UIImage *image, NSError *error) {
        weakSelf.coverView.image = image ?: weakSelf.coverView.image;
        (void)error;
    }];
}

- (void)refreshState {
    self.navigationItem.prompt = [self.container sourceForIdentifier:self.manga.sourceIdentifier].displayName;
    self.progress = [self.container.libraryStore readingProgressForMangaID:self.manga.mangaID sourceIdentifier:self.manga.sourceIdentifier];
    [self updateNavigationButtons];
    [self.tableView reloadData];
}

- (void)updateNavigationButtons {
    BOOL isSaved = [self.container.libraryStore isSavedMangaID:self.manga.mangaID sourceIdentifier:self.manga.sourceIdentifier];
    NSString *buttonTitle = isSaved ? @"Remove" : @"Save";
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(toggleSaveState)];

    if (self.progress != nil) {
        UIBarButtonItem *resumeButton = [[UIBarButtonItem alloc] initWithTitle:@"Resume"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(resumeFromProgress)];
        self.navigationItem.rightBarButtonItems = @[saveButton, resumeButton];
    } else {
        self.navigationItem.rightBarButtonItems = @[saveButton];
    }
}

- (void)toggleSaveState {
    BOOL isSaved = [self.container.libraryStore isSavedMangaID:self.manga.mangaID sourceIdentifier:self.manga.sourceIdentifier];
    [self.container.libraryStore setSaved:!isSaved forMangaID:self.manga.mangaID sourceIdentifier:self.manga.sourceIdentifier];
    [self refreshState];
}

- (void)loadChapters {
    self.isLoadingChapters = YES;
    self.chaptersError = nil;

    __weak typeof(self) weakSelf = self;
    id<IRSourceProtocol> source = [self.container sourceForIdentifier:self.manga.sourceIdentifier];
    [source fetchChaptersForManga:self.manga completion:^(NSArray<IRChapter *> *chapters, NSError *error) {
        weakSelf.isLoadingChapters = NO;
        weakSelf.chaptersError = error;
        weakSelf.chapters = chapters ?: @[];
        [weakSelf.tableView reloadData];
    }];
}

- (void)resumeFromProgress {
    if (self.progress == nil) {
        return;
    }

    IRChapter *targetChapter = nil;
    for (IRChapter *chapter in self.chapters) {
        if ([chapter.chapterID isEqualToString:self.progress.chapterID]) {
            targetChapter = chapter;
            break;
        }
    }

    if (targetChapter == nil && self.chapters.count > 0) {
        targetChapter = self.chapters.firstObject;
    }

    if (targetChapter != nil) {
        IRReaderViewController *readerViewController = [[IRReaderViewController alloc] initWithManga:self.manga chapter:targetChapter container:self.container];
        [self.navigationController pushViewController:readerViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.progress != nil ? 2 : 1;
    }

    if (self.isLoadingChapters || self.chaptersError != nil || self.chapters.count == 0) {
        return 1;
    }
    return self.chapters.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? @"Overview" : @"Chapters";
}

- (UITableViewCell *)resumeCellForTableView:(UITableView *)tableView {
    static NSString *const identifier = @"ResumeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 2;
    }
    cell.textLabel.text = @"Continue reading";
    cell.detailTextLabel.text = [self.progress progressText];
    return cell;
}

- (UITableViewCell *)summaryCellForTableView:(UITableView *)tableView {
    static NSString *const identifier = @"SummaryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    cell.textLabel.text = self.manga.summary;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Latest: %@  %@ chapters expected", self.manga.latestChapterTitle, @(self.manga.estimatedChapterCount)];
    return cell;
}

- (UITableViewCell *)statusCellForTableView:(UITableView *)tableView {
    static NSString *const identifier = @"StatusCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 2;
    }

    if (self.isLoadingChapters) {
        cell.textLabel.text = @"Loading chapters";
        cell.detailTextLabel.text = @"The source is resolving the chapter list.";
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (self.chaptersError != nil) {
        cell.textLabel.text = @"Could not load chapters";
        cell.detailTextLabel.text = @"Tap to retry the chapter request.";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = @"No chapters found";
        cell.detailTextLabel.text = @"Tap to retry in case the source returned an empty result.";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (UITableViewCell *)chapterCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    static NSString *const identifier = @"ChapterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 2;
    }

    IRChapter *chapter = self.chapters[indexPath.row];
    cell.textLabel.text = chapter.title;
    if ([self.progress.chapterID isEqualToString:chapter.chapterID]) {
        cell.detailTextLabel.text = [self.progress progressText];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@ pages expected", chapter.releaseText, @(chapter.pageCountHint)];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.progress != nil && indexPath.row == 0) {
            return [self resumeCellForTableView:tableView];
        }
        return [self summaryCellForTableView:tableView];
    }

    if (self.isLoadingChapters || self.chaptersError != nil || self.chapters.count == 0) {
        return [self statusCellForTableView:tableView];
    }
    return [self chapterCellForTableView:tableView atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if (self.progress != nil && indexPath.row == 0) {
            [self resumeFromProgress];
        }
        return;
    }

    if (self.isLoadingChapters || self.chaptersError != nil || self.chapters.count == 0) {
        [self loadChapters];
        return;
    }

    IRChapter *chapter = self.chapters[indexPath.row];
    IRReaderViewController *readerViewController = [[IRReaderViewController alloc] initWithManga:self.manga chapter:chapter container:self.container];
    [self.navigationController pushViewController:readerViewController animated:YES];
}

@end
