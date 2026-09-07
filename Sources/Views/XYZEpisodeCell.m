#import "XYZEpisodeCell.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"

@interface XYZEpisodeCell ()
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@end

@implementation XYZEpisodeCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _coverView = [[UIImageView alloc] init];
        _coverView.layer.cornerRadius = 4;
        _coverView.clipsToBounds = YES;
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_coverView];
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.numberOfLines = 2;
        _titleLabel.textColor = [XYZUIHelpers textPrimary];
        [self.contentView addSubview:_titleLabel];
        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont systemFontOfSize:11];
        _metaLabel.textColor = [XYZUIHelpers textSecondary];
        [self.contentView addSubview:_metaLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    self.coverView.frame = CGRectMake(12, 12, 48, 48);
    self.titleLabel.frame = CGRectMake(72, 10, w - 86, 36);
    self.metaLabel.frame = CGRectMake(72, 48, w - 86, 14);
}
- (void)configureWithEpisode:(XYZEpisode *)episode {
    self.titleLabel.text = episode.title;
    NSString *dur = [XYZUIHelpers formatDuration:episode.duration];
    NSString *pod = episode.podcastTitle.length ? episode.podcastTitle : @"";
    self.metaLabel.text = [NSString stringWithFormat:@"%@  %@", dur, pod];
    [[XYZImageCache sharedCache] loadImageURL:episode.coverURL intoImageView:self.coverView placeholder:[XYZUIHelpers placeholderCover]];
}
@end
