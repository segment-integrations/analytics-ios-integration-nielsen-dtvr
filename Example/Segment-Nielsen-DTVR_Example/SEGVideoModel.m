//
//  SEGVideoModel.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-12.
//

#import "SEGVideoModel.h"

@implementation SEGVideoModel

-(instancetype)initWithVideoId:(NSString *)videoId
                           url:(NSString *)url
                         title:(NSString *)title
              videoDescription:(NSString *)videoDescription
                      loadType:(NSString *)loadType
                   channelName:(NSString *)channelName
                      duration:(NSInteger )duration
{
    if (self = [super init]) {
        self.videoId = videoId;
        self.url = url;
        self.title = title;
        self.videoDescription = videoDescription;
        self.loadType = loadType;
        self.channelName = channelName;
        self.duration = duration;
    }
    return self;
}

@end
