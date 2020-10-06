//
//  SEGNielsenDTVRIntegration.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegration.h>
#else
#import <Segment/SEGIntegration.h>
#endif
#import <NielsenAppApi/NielsenAppApi.h>

@interface SEGNielsenDTVRIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) NielsenAppApi *nielsen;

- (instancetype)initWithSettings:(NSDictionary *)settings andNielsen:(NielsenAppApi *)neilsen;
- (NSString *)optOutURL;
- (void)userOptOutStatus:(NSString *)urlString;

@end
