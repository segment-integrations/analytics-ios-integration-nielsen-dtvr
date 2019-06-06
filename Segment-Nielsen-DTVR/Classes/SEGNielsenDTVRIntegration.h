//
//  SEGNielsenDTVRIntegration.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>
#import <NielsenAppApi/NielsenAppApi.h>

@class NielsenAppApi;

@interface SEGNielsenDTVRIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) NielsenAppApi *nielsen;

- (instancetype)initWithSettings:(NSDictionary *)settings andNielsen:(NielsenAppApi *)neilsen;
- (NSString *)optOutURL;
- (void)userOptOutStatus:(NSString *)urlString;
- (void (^)(NSString *))sendID3Block;

@end
