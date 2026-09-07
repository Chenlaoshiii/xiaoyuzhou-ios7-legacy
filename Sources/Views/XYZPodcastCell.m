#import "XYZPodcastCell.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"

@interface XYZPodcastCell ()
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end

@implementation XYZPodcastCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _coverView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 10, 56, 56)];
        _coverView.layer.cornerRadius = 6;
        _coverView.clipsToBounds = YES;
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        _coverView.backgroundColor = [XYZUIHelpers brandGreen];
        [self.contentView addSubview:_coverView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, 200, 20)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.textColor = [XYZUIHelpers textPrimary];
        [self.contentView addSubview:_titleLabel];

        _authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 32, 200, 16)];
        _authorLabel.font = [UIFont systemFontOfSize:12];
        _authorLabel.textColor = [XYZUIHelpers textSecondary];
        [self.contentView addSubview:_authorLabel];

        _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 50, 200, 16)];
        _descLabel.font = [UIFont systemFontOfSize:11];
        _descLabel.textColor = [XYZUIHelpers textSecondary];
        [self.contentView addSubview:_descLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    self.coverView.frame = CGRectMake(12, 10, 56, 56);
    CGFloat tw = w - 100;
    self.titleLabel.frame = CGRectMake(80, 10, tw, 20);
    self.authorLabel.frame = CGRectMake(80, 32, tw, 16);
    self.descLabel.frame = CGRectMake(80, 50, tw, 16);
}
- (void)configureWithPodcast:(XYZPodcast *)podcast {
    self.titleLabel.text = podcast.title;
    self.authorLabel.text = podcast.author.length ? podcast.author : @"播客";
    self.descLabel.text = podcast.brief.length ? podcast.brief : podcast.descriptionText;
    [[XYZImageCache sharedCache] loadImageURL:podcast.coverURL intoImageView:self.coverView placeholder:[XYZUIHelpers placeholderCover]];
}
@end
