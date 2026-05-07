#import "IRSourcesViewController.h"

#import "IRAppContainer.h"
#import "IRSourceRecord.h"
#import "IRSourceRegistry.h"
#import "IRSourceProtocol.h"

@interface IRSourcesViewController ()

@property (nonatomic, strong) IRAppContainer *container;

@end

@implementation IRSourcesViewController

- (instancetype)initWithContainer:(IRAppContainer *)container {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _container = container;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Sources";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                             target:self
                                                                                             action:@selector(reloadSources)];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:IRAppContainerSourceDidChangeNotification
                                               object:self.container];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadTable];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadSources {
    [self.container reloadSources];
    [self.tableView reloadData];
}

- (void)reloadTable {
    self.navigationItem.prompt = self.container.source.displayName;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (section == 0) {
        return 2;
    }
    return [[self.container availableSourceRecords] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? @"Source Packs" : @"Available Sources";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == 0) {
        return @"Copy source pack folders into the SourcePacks documents folder by using Finder or iTunes File Sharing, then tap Reload.";
    }
    return @"The active source drives Catalog and the current source specific Library list.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const identifier = @"SourceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Source pack folder";
            cell.detailTextLabel.text = self.container.sourceRegistry.sourcePacksDirectoryPath;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.textLabel.text = @"Reload source packs";
            cell.detailTextLabel.text = @"Scan the SourcePacks folder again.";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        return cell;
    }

    IRSourceRecord *record = [self.container availableSourceRecords][indexPath.row];
    cell.textLabel.text = record.displayName;
    cell.detailTextLabel.text = record.builtIn ? @"Built in source" : record.filePath;
    cell.accessoryType = [record.sourceIdentifier isEqualToString:self.container.source.sourceIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            [self reloadSources];
        }
        return;
    }

    IRSourceRecord *record = [self.container availableSourceRecords][indexPath.row];
    [self.container selectSourceWithIdentifier:record.sourceIdentifier];
    [self.tableView reloadData];
}

@end
