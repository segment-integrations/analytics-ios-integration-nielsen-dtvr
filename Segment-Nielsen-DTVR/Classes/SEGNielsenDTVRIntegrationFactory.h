//
//  SEGNielsenDTVRIntegrationFactory.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>

@interface SEGNielsenDTVRIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

- (NSArray *) integrationsForAppId:(NSString *)appId;

@end
