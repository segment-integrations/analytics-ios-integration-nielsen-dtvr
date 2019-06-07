//
//  SEGNielsenDTVRIntegration.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import "SEGNielsenDTVRIntegration.h"
#import "SEGTrackPayload.h"
#import <NielsenAppApi/NielsenAppApi.h>

#pragma mark Event Handlers

@interface SEGNielsenEventHandler: NSObject

@property (nonatomic, strong) NSArray *events;
@property (nonatomic, copy) void (^eventHandler)(NielsenAppApi *nielsen, SEGTrackPayload *payload);

-(instancetype)initWithEvents: (NSArray *)events
                  withHandler:(void (^)(NielsenAppApi *nielsen, SEGTrackPayload *payload))eventHandler;

@end

@implementation SEGNielsenEventHandler

-(instancetype)initWithEvents: (NSArray *)events
                  withHandler:(void (^)(NielsenAppApi *nielsen, SEGTrackPayload *payload))eventHandler
{
    if (self = [super init]) {
        self.events = events;
        self.eventHandler = eventHandler;
    }
    
    return self;
}

@end

#pragma mark SEGNielsenDTVRIntegration

@interface SEGNielsenDTVRIntegration()

@property (nonatomic, strong) NSMutableArray *eventHandlers;

@end

@implementation SEGNielsenDTVRIntegration

-(instancetype)initWithSettings:(NSDictionary *)settings andNielsen:(id)nielsen
{
    if (self = [super init]) {
        self.settings = settings;
        self.nielsen = nielsen;
        
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *appId = settings[@"appId"];
        
        NSString *sfcode;
        if (settings[@"sfcode"]) {
            sfcode = @"us";
        }
        
        NSDictionary *appInfo = @{
                                  @"appname": appName,
                                  @"appversion": appVersion,
                                  @"sfcode": sfcode ?: @"",
                                  @"appid": appId ?: @""
                                  };
        
        [self setupEventHandlers];
        
        if (nielsen == nil) {
            self.nielsen = [[NielsenAppApi alloc] initWithAppInfo:appInfo delegate:nil];
        }
    }
    
    return self;
}

-(void)setupEventHandlers
{
    self.eventHandlers = [[NSMutableArray alloc] init];
    SEGNielsenEventHandler *startHandler = [[SEGNielsenEventHandler alloc]
                                           initWithEvents:@[
                                                            @"Video Content Started"
                                                            ]
                                           withHandler:^void (NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                               NSDictionary *properties = payload.properties;
                                               
                                               NSDictionary *channelInfo = [self channelInfoForPayload:payload];
                                               
                                               NSString *loadType = properties[@"load_type"];
                                               NSString *adModel;
                                               if ([loadType isEqualToString:@"linear"]) {
                                                   adModel = @"1";
                                               }
                                               else if([loadType isEqualToString:@"dynamic"]) {
                                                   adModel = @"2";
                                               }
                                               
                                               NSDictionary *metadata = @{
                                                                          @"channelName": properties[@"channel"] ?: @"",
                                                                          @"type": @"content",
                                                                          @"adModel": adModel ?: @""
                                                                          };
                                               // TODO: Retrieve ID3 Tag from stream, needs to be with timed metadata event
                                               NSString *id3Tag;
                                               
                                               [nielsen play:channelInfo];
                                               [nielsen loadMetadata:metadata];
                                               // TODO: Will need to provide this separately to coordinate with timed metadata events
                                               [nielsen sendID3:id3Tag];
    }];
    
    SEGNielsenEventHandler *playHandler = [[SEGNielsenEventHandler alloc]
                                           initWithEvents:@[
                                                            @"Video Playback Buffer Completed",
                                                            @"Video Playback Seek Completed",
                                                            @"Video Playback Resumed"
                                                            ]
                                           withHandler:^(NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                               NSDictionary *channelInfo = [self channelInfoForPayload:payload];
                                               
                                               // TODO: Retrieve ID3 Tag from stream, needs to be with timed metadata event
                                               NSString *id3Tag;
                                               
                                               [nielsen play:channelInfo];
                                               // TODO: Will need to provide this separately to coordinate with timed metadata events
                                               [nielsen sendID3:id3Tag];
                                           }];
    
    SEGNielsenEventHandler *stopHandler = [[SEGNielsenEventHandler alloc]
                                           initWithEvents:@[
                                                            @"Video Playback Paused",
                                                            @"Video Playback Interrupted",
                                                            @"Video Playback Buffer Started",
                                                            @"Video Playback Seek Started",
                                                            @"Video Content Completed",
                                                            @"Application Backgrounded"
                                                            ]
                                           withHandler:^(NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                               [nielsen stop];
                                           }];
    
    SEGNielsenEventHandler *endHandler = [[SEGNielsenEventHandler alloc]
                                          initWithEvents:@[
                                                           @"Video Playback Completed"
                                                           ]
                                          withHandler:^(NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                              [nielsen end];
                                          }];
    
    [self.eventHandlers addObject:startHandler];
    [self.eventHandlers addObject:playHandler];
    [self.eventHandlers addObject:stopHandler];
    [self.eventHandlers addObject:endHandler];
}

#pragma mark Tracking

-(void)track:(SEGTrackPayload *)payload
{
    NSString *event = payload.event;
    
    for (SEGNielsenEventHandler *handler in self.eventHandlers) {
        if ([handler.events containsObject:event]) {
            handler.eventHandler(self.nielsen, payload);
            break;
        }
    }
}

-(NSString *)optOutURL
{
    return [self.nielsen optOutURL];
}

-(void)userOptOutStatus:(NSString *)urlString
{
    [self.nielsen userOptOut:urlString];
}

-(void (^)(NSString *))sendID3Block
{
    return ^void(NSString *id3Tag) {
        [self.nielsen sendID3:id3Tag];
    };
}

#pragma mark Helpers

-(NSDictionary *)channelInfoForPayload:(SEGTrackPayload *)payload
{
    NSDictionary *properties = payload.properties;
    
    NSDictionary *channelInfo = @{
                                  @"channelName": properties[@"channel"] ?: @"",
                                  @"mediaURL": @"",
                                  };
    return channelInfo;
}

@end
