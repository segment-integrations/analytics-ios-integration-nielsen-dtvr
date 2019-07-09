//
//  SEGVideoModel.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-12.
//

#import <Foundation/Foundation.h>

@interface SEGVideoModel : NSObject

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *videoDescription;
@property (nonatomic, strong) NSString *loadType;
@property (nonatomic, strong) NSString *channelName;
@property (nonatomic) NSInteger duration;

-(instancetype)initWithVideoId:(NSString *)videoId
                           url:(NSString *)url
                         title:(NSString *)title
              videoDescription:(NSString *)videoDescription
                      loadType:(NSString *)loadType
                   channelName:(NSString *)channelName
                      duration:(NSInteger )duration;

@end
