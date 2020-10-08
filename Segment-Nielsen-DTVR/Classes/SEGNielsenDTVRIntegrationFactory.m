//
//  SEGNielsenDTVRIntegrationFactory.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import "SEGNielsenDTVRIntegrationFactory.h"
#import "SEGNielsenDTVRIntegration.h"
#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegration.h>
#import <Analytics/SEGAnalytics.h>
#else
#import <Segment/SEGIntegration.h>
#import <Segment/SEGAnalytics.h>
#endif

@interface SEGNielsenDTVRIntegrationFactory()

@property (nonatomic, strong) NSMutableDictionary *integrationsByAppId;

@end

@implementation SEGNielsenDTVRIntegrationFactory

static int MAX_NUMBER_NIELSEN_SDKS_PER_APPID = 4;

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
    NSString *appId = settings[@"appId"] ?: @"";
    
    NSMutableArray *integrationArray = self.integrationsByAppId[appId];
    if (integrationArray == nil) {
        integrationArray = [[NSMutableArray alloc] init];
        self.integrationsByAppId[appId] = integrationArray;
    }
    
    SEGNielsenDTVRIntegration *integration;
    if ([integrationArray count] >= MAX_NUMBER_NIELSEN_SDKS_PER_APPID) {
        integration = [integrationArray objectAtIndex:0];
    }
    else {
        integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:settings andNielsen:nil];
        [integrationArray addObject:integration];
    }
    return integration;
}

-(NSArray *)integrationsForAppId:(NSString *)appId
{
    return self.integrationsByAppId[appId];
}

@end
