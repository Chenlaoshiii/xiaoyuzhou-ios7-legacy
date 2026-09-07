#import "XYZCommentCell.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"

@interface XYZCommentCell ()
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UILabel *likeLabel;
@end

@implementation XYZCommentCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _avatarView = [[UIImageView alloc] init];
        _avatarView.layer.cornerRadius = 14;
        _avatarView.clipsToBounds = YES;
        [self.contentView addSubview:_avatarView];
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:13];
        _nameLabel.textColor = [XYZUIHelpers textPrimary];
        [self.contentView addSubview:_nameLabel];
        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.font = [UIFont systemFontOfSize:13];
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.textColor = [XYZUIHelpers textPrimary];
        [self.contentView addSubview:_bodyLabel];
        _likeLabel = [[UILabel alloc] init];
        _likeLabel.font = [UIFont systemFontOfSize:11];
        _likeLabel.textColor = [XYZUIHelpers textSecondary];
        [self.contentView addSubview:_likeLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    self.avatarView.frame = CGRectMake(12, 10, 28, 28);
    self.nameLabel.frame = CGRectMake(48, 10, w - 60, 16);
    CGSize sz = [self.bodyLabel.text sizeWithFont:self.bodyLabel.font constrainedToSize:CGSizeMake(w - 60, 500) lineBreakMode:NSLineBreakByWordWrapping];
    self.bodyLabel.frame = CGRectMake(48, 30, w - 60, sz.height);
    self.likeLabel.frame = CGRectMake(48, CGRectGetMaxY(self.bodyLabel.frame) + 4, w - 60, 14);
}
- (void)configureWithComment:(XYZComment *)comment {
    self.nameLabel.text = comment.authorName.length ? comment.authorName : @"听众";
    self.bodyLabel.text = comment.text;
    self.likeLabel.text = [NSString stringWithFormat:@"赞 %ld", (long)comment.likeCount];
    [[XYZImageCache sharedCache] loadImageURL:comment.authorAvatarURL intoImageView:self.avatarView placeholder:[XYZUIHelpers placeholderCover]];
    [self setNeedsLayout];
}
+ (CGFloat)heightForComment:(XYZComment *)comment width:(CGFloat)width {
    CGSize sz = [comment.text sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(width - 60, 500) lineBreakMode:NSLineBreakByWordWrapping];
    return 30 + sz.height + 24;
}
@end
