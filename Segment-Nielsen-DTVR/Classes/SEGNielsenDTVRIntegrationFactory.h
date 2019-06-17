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

/**
 Returns the array of SEGNielsenDTVRIntegration instances given an app ID
 @param appId App ID
 @return NSArray of SEGNielsenDTVRIntegration instances for the app ID
 */
- (NSArray *) integrationsForAppId:(NSString *)appId;

@end
