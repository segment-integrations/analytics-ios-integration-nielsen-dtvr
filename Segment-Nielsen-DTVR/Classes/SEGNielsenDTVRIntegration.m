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

/**
 Constructor method
 @param events Array of Segment event names for which to fire the block in 'eventHandler'.
 @param eventHandler Block that is intended to be executed when the appropriate Segment event is fired.
 
 @discussion
 @b nielsen Instance of the Nielsen App API - this should be passed in from the integration instance, and not retained. The instance's API methods will be invoked.
 
 @b payload Segment tracking payload.
 
 @return Instance of an event handler to map Segment events to Nielsen events.
*/
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

@property (nonatomic, strong) NSArray *eventHandlers;
@property (nonatomic, strong) NSString *lastSeenID3Tag;

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
        
        NSMutableDictionary *appInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                         @"appname": appName,
                                                                                         @"appversion": appVersion,
                                                                                         @"sfcode": settings[@"sfcode"] ?: @"us",
                                                                                         @"appid": appId ?: @""
                                                                                         }];
        
        if ([settings[@"debug"] boolValue]) {
            [appInfo addEntriesFromDictionary:@{@"nol_devDebug": @"DEBUG"}];
        }
        
        [self setupEventHandlers];
        
        if (nielsen == nil) {
            self.nielsen = [[NielsenAppApi alloc] initWithAppInfo:appInfo delegate:nil];
        }
    }
    
    return self;
}

-(void)setupEventHandlers
{
    __weak SEGNielsenDTVRIntegration *weakSelf = self;
    SEGNielsenEventHandler *startHandler = [[SEGNielsenEventHandler alloc]
                                           initWithEvents:@[
                                                            @"Video Content Started"
                                                            ]
                                           withHandler:^void (NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                               NSDictionary *properties = payload.properties;
                                               
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
                                               
                                               [nielsen play:[weakSelf channelInfoForPayload:payload]];
                                               [nielsen loadMetadata:metadata];
    }];
    
    SEGNielsenEventHandler *playHandler = [[SEGNielsenEventHandler alloc]
                                           initWithEvents:@[
                                                            @"Video Playback Buffer Completed",
                                                            @"Video Playback Seek Completed",
                                                            @"Video Playback Resumed"
                                                            ]
                                           withHandler:^(NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                               [nielsen play:[weakSelf channelInfoForPayload:payload]];
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
    
    // This is marked as required in the destination settings
    NSArray<NSString *> *sendID3EventNames = self.settings[@"sendId3Events"] ?: @[];
    SEGNielsenEventHandler *sendID3Handler = [[SEGNielsenEventHandler alloc]
                                              initWithEvents:sendID3EventNames
                                              withHandler:^(NielsenAppApi *nielsen, SEGTrackPayload *payload) {
                                                  NSString *id3TagPropertyKey = weakSelf.settings[@"id3Property"] ?: @"id3";
                                                  
                                                  NSString *id3Tag = payload.properties[id3TagPropertyKey] ?: @"";
                                                  if (weakSelf.lastSeenID3Tag == nil || ![id3Tag isEqualToString:weakSelf.lastSeenID3Tag]) {
                                                      weakSelf.lastSeenID3Tag = id3Tag;
                                                      [weakSelf.nielsen sendID3:id3Tag];
                                                  }
                                              }];
    
    self.eventHandlers = @[
                           startHandler,
                           playHandler,
                           stopHandler,
                           endHandler,
                           sendID3Handler
                           ];
}

#pragma mark Tracking

-(void)track:(SEGTrackPayload *)payload
{
    for (SEGNielsenEventHandler *handler in self.eventHandlers) {
        if ([self arrayContainsStringIgnoreCase:payload.event
                                       forArray:handler.events]) {
            handler.eventHandler(self.nielsen, payload);
            break;
        }
    }
}

/**
 @return Opt-out URL string from the Nielsen App API to display in a web view.
 */
-(NSString *)optOutURL
{
    return [self.nielsen optOutURL];
}

/**
 @param urlString URL string from user's action to denote opt-out status for the Nielsen App API. Should be one of `nielsenappsdk://1` or `nielsenappsdk://0` for opt-out and opt-in, respectively
 @seealso https://engineeringportal.nielsen.com/docs/DTVR_iOS_SDK#The_legacy_opt-out_method_works_as_follows:
 */
-(void)userOptOutStatus:(NSString *)urlString
{
    [self.nielsen userOptOut:urlString];
}

#pragma mark Helpers

/**
 Creates channel info object for the Nielsen App API's `loadMetadata` method
 @param payload Segment tracking payload
 @return NSDictionary of properties to send to the `loadMetadata` method
 */
-(NSDictionary *)channelInfoForPayload:(SEGTrackPayload *)payload
{
    NSDictionary *properties = payload.properties;
    
    NSDictionary *channelInfo = @{
                                  @"channelName": properties[@"channel"] ?: @"",
                                  @"mediaURL": @"",
                                  };
    return channelInfo;
}

/**
 Checks a given array of strings to determine whether 'compare' is found, ignoring case
 @param compare NSString to compare. If not provided, 'NO' is returned
 @param array NSArray of strings to check against
 @return BOOL 'YES' if 'compare' is found within the array of strings, otherwise 'NO'
 */
-(BOOL)arrayContainsStringIgnoreCase:(NSString *)compare forArray:(NSArray<NSString *> *)array
{
    if (compare == nil || [compare isEqual:[NSNull null]]) {
        return NO;
    }
    
    for (NSString *string in array) {
        if ([[string lowercaseString] isEqualToString:[compare lowercaseString]]) {
            return YES;
        }
    }
    
    return NO;
}

@end
