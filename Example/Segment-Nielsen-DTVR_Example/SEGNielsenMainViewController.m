//
//  SEGNielsenMainViewController.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-05-31.
//

#import <AVKit/AVPlayerViewController.h>
#import <Analytics/SEGAnalytics.h>
#import "SEGVideoModel.h"
#import "SEGNielsenMainViewController.h"
#import "SEGNielsenVideoPlayerViewController.h"

@interface SEGNielsenMainViewController ()

@end

@implementation SEGNielsenMainViewController

#pragma mark - Lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self.descriptionLabel setText:@"This sample application demonstrates the integration of the Nielsen App SDK and the Segment-Nielsen DTVR Integration, with a custom sample video player to monitor and track various events according to the Segment Video Spec, as it pertains to the DTVR integration. Click the 'Launch Player' button to get started."];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

@end
