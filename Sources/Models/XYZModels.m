#import "XYZModels.h"

static NSString *XYZString(id obj) {
    if ([obj isKindOfClass:[NSString class]]) return obj;
    if ([obj isKindOfClass:[NSNumber class]]) return [obj stringValue];
    return @"";
}

static NSString *XYZCoverFrom(NSDictionary *dict) {
    if (![dict isKindOfClass:[NSDictionary class]]) return @"";
    id image = dict[@"image"] ?: dict[@"picture"] ?: dict[@"cover"];
    if ([image isKindOfClass:[NSString class]]) return image;
    if ([image isKindOfClass:[NSDictionary class]]) {
        NSDictionary *pic = image[@"picUrl"] ? image : (image[@"picture"] ?: image);
        if (![pic isKindOfClass:[NSDictionary class]]) pic = image;
        NSString *u = XYZString(pic[@"picUrl"]);
        if (!u.length) u = XYZString(pic[@"largePicUrl"]);
        if (!u.length) u = XYZString(pic[@"middlePicUrl"]);
        if (!u.length) u = XYZString(pic[@"smallPicUrl"]);
        if (!u.length) u = XYZString(pic[@"thumbnailUrl"]);
        return u;
    }
    // nested podcast.image
    NSDictionary *podcast = dict[@"podcast"];
    if ([podcast isKindOfClass:[NSDictionary class]]) {
        return XYZCoverFrom(podcast);
    }
    return @"";
}

@implementation XYZPodcast
+ (instancetype)podcastWithDictionary:(NSDictionary *)dict {
    XYZPodcast *p = [[XYZPodcast alloc] init];
    if (![dict isKindOfClass:[NSDictionary class]]) return p;
    // unwrap data
    if (dict[@"data"] && [dict[@"data"] isKindOfClass:[NSDictionary class]] && dict[@"data"][@"pid"]) {
        dict = dict[@"data"];
    }
    p.pid = XYZString(dict[@"pid"] ?: dict[@"id"]);
    p.title = XYZString(dict[@"title"] ?: dict[@"name"]);
    p.author = XYZString(dict[@"author"] ?: dict[@"podcaster"][@"nickname"]);
    if (!p.author.length) {
        NSDictionary *podcasters = [dict[@"podcasters"] isKindOfClass:[NSArray class]] && [dict[@"podcasters"] count] ? dict[@"podcasters"][0] : nil;
        if ([podcasters isKindOfClass:[NSDictionary class]]) p.author = XYZString(podcasters[@"nickname"]);
    }
    p.brief = XYZString(dict[@"brief"]);
    p.descriptionText = XYZString(dict[@"description"] ?: dict[@"brief"]);
    p.coverURL = XYZCoverFrom(dict);
    p.episodeCount = [dict[@"episodeCount"] integerValue];
    id sub = dict[@"subscriptionStatus"] ?: dict[@"subscribed"];
    if ([sub isKindOfClass:[NSString class]]) p.subscribed = [sub isEqualToString:@"ON"] || [sub isEqualToString:@"SUBSCRIBED"];
    else p.subscribed = [sub boolValue];
    return p;
}
@end

@implementation XYZEpisode
+ (instancetype)episodeWithDictionary:(NSDictionary *)dict {
    XYZEpisode *e = [[XYZEpisode alloc] init];
    if (![dict isKindOfClass:[NSDictionary class]]) return e;
    if (dict[@"data"] && [dict[@"data"] isKindOfClass:[NSDictionary class]] && (dict[@"data"][@"eid"] || dict[@"data"][@"id"])) {
        dict = dict[@"data"];
    }
    // discovery feed items often wrap as {type, episode/podcast}
    if (dict[@"episode"] && [dict[@"episode"] isKindOfClass:[NSDictionary class]]) {
        dict = dict[@"episode"];
    }
    e.eid = XYZString(dict[@"eid"] ?: dict[@"id"]);
    e.pid = XYZString(dict[@"pid"]);
    NSDictionary *podcast = dict[@"podcast"];
    if ([podcast isKindOfClass:[NSDictionary class]]) {
        if (!e.pid.length) e.pid = XYZString(podcast[@"pid"]);
        e.podcastTitle = XYZString(podcast[@"title"]);
    }
    e.title = XYZString(dict[@"title"]);
    e.descriptionText = XYZString(dict[@"description"]);
    e.shownotes = XYZString(dict[@"shownotes"] ?: dict[@"description"]);
    e.coverURL = XYZCoverFrom(dict);
    if (!e.coverURL.length && [podcast isKindOfClass:[NSDictionary class]]) e.coverURL = XYZCoverFrom(podcast);
    e.duration = [dict[@"duration"] doubleValue];
    e.pubDate = XYZString(dict[@"pubDate"] ?: dict[@"publishDate"]);
    e.playCount = [dict[@"playCount"] integerValue];
    e.commentCount = [dict[@"commentCount"] integerValue];

    // media URL extraction
    id media = dict[@"media"];
    if ([media isKindOfClass:[NSDictionary class]]) {
        e.mediaURL = XYZString(media[@"source"][@"url"] ?: media[@"url"] ?: media[@"mediaKey"]);
        if (!e.mediaURL.length) {
            id src = media[@"source"];
            if ([src isKindOfClass:[NSDictionary class]]) e.mediaURL = XYZString(src[@"url"]);
        }
    }
    if (!e.mediaURL.length) {
        id enc = dict[@"enclosure"];
        if ([enc isKindOfClass:[NSDictionary class]]) e.mediaURL = XYZString(enc[@"url"]);
        else if ([enc isKindOfClass:[NSString class]]) e.mediaURL = enc;
    }
    if (!e.mediaURL.length) e.mediaURL = XYZString(dict[@"mediaUrl"] ?: dict[@"audioUrl"]);
    return e;
}

+ (NSArray *)episodesFromDataArray:(NSArray *)array {
    NSMutableArray *out = [NSMutableArray array];
    if (![array isKindOfClass:[NSArray class]]) return out;
    for (id item in array) {
        NSDictionary *d = item;
        if ([item isKindOfClass:[NSDictionary class]] && item[@"episode"]) d = item[@"episode"];
        if ([d isKindOfClass:[NSDictionary class]]) {
            XYZEpisode *e = [XYZEpisode episodeWithDictionary:d];
            if (e.eid.length) [out addObject:e];
        }
    }
    return out;
}
@end

@implementation XYZComment
+ (instancetype)commentWithDictionary:(NSDictionary *)dict {
    XYZComment *c = [[XYZComment alloc] init];
    if (![dict isKindOfClass:[NSDictionary class]]) return c;
    c.cid = XYZString(dict[@"id"] ?: dict[@"cid"]);
    c.text = XYZString(dict[@"text"] ?: dict[@"content"]);
    NSDictionary *author = dict[@"author"] ?: dict[@"user"];
    if ([author isKindOfClass:[NSDictionary class]]) {
        c.authorName = XYZString(author[@"nickname"] ?: author[@"name"]);
        c.authorAvatarURL = XYZCoverFrom(author);
        if (!c.authorAvatarURL.length) {
            id av = author[@"avatar"];
            if ([av isKindOfClass:[NSDictionary class]]) c.authorAvatarURL = XYZCoverFrom(@{@"picture": av});
            else c.authorAvatarURL = XYZString(av);
        }
    }
    c.likeCount = [dict[@"likeCount"] integerValue];
    c.createdAt = XYZString(dict[@"createdAt"] ?: dict[@"time"]);
    return c;
}
+ (NSArray *)commentsFromDataArray:(NSArray *)array {
    NSMutableArray *out = [NSMutableArray array];
    if (![array isKindOfClass:[NSArray class]]) return out;
    for (id item in array) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            // primary comment list may nest under "comment"
            NSDictionary *d = item[@"comment"] ?: item;
            XYZComment *c = [XYZComment commentWithDictionary:d];
            if (c.text.length || c.cid.length) [out addObject:c];
        }
    }
    return out;
}
@end

@implementation XYZUserProfile
+ (instancetype)profileWithDictionary:(NSDictionary *)dict {
    XYZUserProfile *u = [[XYZUserProfile alloc] init];
    if (![dict isKindOfClass:[NSDictionary class]]) return u;
    NSDictionary *data = dict[@"data"] ?: dict;
    if ([data[@"user"] isKindOfClass:[NSDictionary class]]) data = data[@"user"];
    u.uid = XYZString(data[@"uid"] ?: data[@"id"]);
    u.nickname = XYZString(data[@"nickname"] ?: data[@"name"]);
    u.bio = XYZString(data[@"bio"]);
    u.avatarURL = XYZCoverFrom(data);
    if (!u.avatarURL.length) {
        id av = data[@"avatar"];
        if ([av isKindOfClass:[NSDictionary class]]) {
            id pic = av[@"picture"] ?: av;
            if ([pic isKindOfClass:[NSDictionary class]]) u.avatarURL = XYZString(pic[@"picUrl"] ?: pic[@"smallPicUrl"]);
        } else {
            u.avatarURL = XYZString(av);
        }
    }
    NSDictionary *phone = data[@"phoneNumber"];
    if ([phone isKindOfClass:[NSDictionary class]]) {
        u.phoneMasked = XYZString(phone[@"mobilePhoneNumber"]);
    }
    return u;
}
@end
