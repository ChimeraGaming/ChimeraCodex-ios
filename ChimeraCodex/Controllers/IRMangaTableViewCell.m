#import "IRMangaTableViewCell.h"

@interface IRMangaTableViewCell ()

@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *metadataLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation IRMangaTableViewCell

+ (CGFloat)preferredHeight {
    return 98.0;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        _coverView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        _coverView.clipsToBounds = YES;
        _coverView.layer.cornerRadius = 6.0;
        [self.contentView addSubview:_coverView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.numberOfLines = 2;
        [self.contentView addSubview:_titleLabel];

        _metadataLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _metadataLabel.font = [UIFont systemFontOfSize:12.0];
        _metadataLabel.textColor = [UIColor grayColor];
        _metadataLabel.numberOfLines = 1;
        [self.contentView addSubview:_metadataLabel];

        _summaryLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _summaryLabel.font = [UIFont systemFontOfSize:12.0];
        _summaryLabel.textColor = [UIColor colorWithRed:0.25 green:0.28 blue:0.31 alpha:1.0];
        _summaryLabel.numberOfLines = 2;
        [self.contentView addSubview:_summaryLabel];

        _progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _progressLabel.font = [UIFont boldSystemFontOfSize:12.0];
        _progressLabel.textColor = [UIColor colorWithRed:0.13 green:0.33 blue:0.58 alpha:1.0];
        _progressLabel.numberOfLines = 1;
        [self.contentView addSubview:_progressLabel];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.representedMangaID = nil;
    self.coverView.image = nil;
    self.titleLabel.text = nil;
    self.metadataLabel.text = nil;
    self.summaryLabel.text = nil;
    self.progressLabel.text = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat inset = 8.0;
    CGFloat coverWidth = 56.0;
    CGFloat coverHeight = 80.0;
    self.coverView.frame = CGRectMake(inset, 9.0, coverWidth, coverHeight);

    CGFloat textX = CGRectGetMaxX(self.coverView.frame) + 10.0;
    CGFloat accessoryPadding = self.accessoryType == UITableViewCellAccessoryNone ? 12.0 : 34.0;
    CGFloat textWidth = CGRectGetWidth(self.contentView.bounds) - textX - accessoryPadding;

    self.titleLabel.frame = CGRectMake(textX, 8.0, textWidth, 38.0);
    self.metadataLabel.frame = CGRectMake(textX, 44.0, textWidth, 14.0);
    self.summaryLabel.frame = CGRectMake(textX, 58.0, textWidth, 24.0);
    self.progressLabel.frame = CGRectMake(textX, 80.0, textWidth, 14.0);
}

- (void)applyCoverImage:(UIImage *)image {
    self.coverView.image = image;
}

- (void)applyTitle:(NSString *)title
          metadata:(NSString *)metadata
           summary:(NSString *)summary
          progress:(NSString *)progress {
    self.titleLabel.text = title;
    self.metadataLabel.text = metadata;
    self.summaryLabel.text = summary;
    self.progressLabel.text = progress;
    self.progressLabel.hidden = progress.length == 0;
}

@end
