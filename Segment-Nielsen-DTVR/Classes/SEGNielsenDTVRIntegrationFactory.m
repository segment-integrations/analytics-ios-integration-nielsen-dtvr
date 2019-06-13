//
//  SEGNielsenDTVRIntegrationFactory.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import "SEGNielsenDTVRIntegrationFactory.h"
#import "SEGNielsenDTVRIntegration.h"
#import <Analytics/SEGIntegration.h>
#import <Analytics/SEGAnalytics.h>

@interface SEGNielsenDTVRIntegrationFactory()

@property (nonatomic, strong) NSMutableDictionary *integrationsByAppId;

@end

@implementation SEGNielsenDTVRIntegrationFactory

+(instancetype)instance
{
    static dispatch_once_t once;
    static SEGNielsenDTVRIntegrationFactory *sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        self.integrationsByAppId = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSString *)key
{
    return @"Nielsen DTVR";
}

-(id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    SEGNielsenDTVRIntegration *integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:settings andNielsen:nil];
    NSString *appId = settings[@"appId"];
    
    NSMutableArray *integrationArray = self.integrationsByAppId[appId];
    if (integrationArray == nil) {
        integrationArray = [[NSMutableArray alloc] init];
        self.integrationsByAppId[appId] = integrationArray;
    }
    
    [integrationArray addObject:integration];
    if ([integrationArray count] > 4) {
        [integrationArray removeObjectAtIndex:0];
    }
    return integration;
}

-(NSArray *)integrationsForAppId:(NSString *)appId
{
    return self.integrationsByAppId[appId];
}

@end
