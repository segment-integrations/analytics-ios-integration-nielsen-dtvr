//
//  SEGNielsenMainViewController.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import <AVKit/AVPlayerViewController.h>
#if defined(__has_include) && __has_include(<Analytics/Analytics.h>)
#import <Analytics/SEGAnalytics.h>
#else
#import <Segment/SEGAnalytics.h>
#endif
#if defined(__has_include) && __has_include(<Analytics/Analytics.h>)
#import <Analytics/SEGIntegrationsManager.h>
#else
#import <Segment/SEGIntegrationsManager.h>
#endif
#import "SEGNielsenDTVRIntegrationFactory.h"
#import "SEGNielsenDTVRIntegration.h"
#import "SEGVideoModel.h"
#import "SEGNielsenMainViewController.h"
#import "SEGNielsenVideoPlayerViewController.h"
#import "SEGNielsenWebViewController.h"

@interface SEGNielsenMainViewController ()

@property (nonatomic, copy) NSString *optOutURL;

@end

@implementation SEGNielsenMainViewController

#pragma mark - Lifecycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self.descriptionLabel setText:@"This sample application demonstrates the integration of the Nielsen App SDK and the Segment-Nielsen DTVR Integration, with a custom sample video player to monitor and track various events according to the Segment Video Spec, as it pertains to the DTVR integration. Click the 'Launch Player' button to get started."];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIntegrationDidStart:) name:SEGAnalyticsIntegrationDidStart object:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = [segue destinationViewController];
    if ([viewController isKindOfClass:[SEGNielsenVideoPlayerViewController class]]) {
        SEGNielsenVideoPlayerViewController *playerViewController = (SEGNielsenVideoPlayerViewController *)viewController;
        playerViewController.model = [[SEGVideoModel alloc] initWithVideoId:@"1234"
                                                                        url:@"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                                                                      title:@"Big Buck Bunny"
                                                           videoDescription:@"Test Video"
                                                                   loadType:@"linear"
                                                                channelName:@"defaultChannelName"
                                                                   duration:596];
    }
    else if ([viewController isKindOfClass:[SEGNielsenWebViewController class]]) {
        SEGNielsenWebViewController *webController = (SEGNielsenWebViewController *)viewController;
        webController.urlString = self.optOutURL;
    }
    else {
        [super prepareForSegue:segue sender:sender];
    }
}

#pragma mark - Setup / Cleanup

-(void)setupUI
{
    [self.titleLabel setText:@"Segment Nielsen DTVR Sample App"];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.launchPlayerButton setTitle:@"Launch Player" forState:UIControlStateNormal];
    [[self.launchPlayerButton titleLabel] setFont:[UIFont systemFontOfSize:16]];
    [self.descriptionLabel setFont:[UIFont systemFontOfSize:16]];
    [self.descriptionLabel setNumberOfLines:0];
}

-(void)handleIntegrationDidStart:(NSNotification *)notification
{
    NSString *integrationKey = notification.object;
    
    if ([integrationKey isEqualToString:@"Nielsen DTVR"]) {
        NSArray *integrations = [[SEGNielsenDTVRIntegrationFactory instance] integrationsForAppId:@"NIELSEN_APP_ID_HERE"];
        SEGNielsenDTVRIntegration *integration = [integrations objectAtIndex:0];
        self.optOutURL = [integration optOutURL];
        [self showOptOut];
    }
}

-(void)showOptOut
{
    // Nielsen's legacy method of having user opt out/in on iOS SDK less than 5.1.1.18
    __weak SEGNielsenMainViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf performSegueWithIdentifier:@"WebViewSegue" sender:nil];
    });
}

@end
