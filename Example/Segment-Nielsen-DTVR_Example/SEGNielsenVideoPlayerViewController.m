//
//  SEGNielsenVideoPlayerViewController.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-11.
//

#import <AVFoundation/AVFoundation.h>
#import <Analytics/SEGAnalytics.h>
#import "SEGNielsenVideoPlayerViewController.h"

static char TimedMetadataObserverContext = 0;

/*
 This sample custom video player demonstrates firing several analytics events to Segment which have a mapping with the Nielsen SDK.
 The following events are tracked:
 - Video Content Started
 - Video Content Completed
 - Video Playback Paused
 - Video Playback Resumed
 - Video Playback Completed
 - Video Playback Seek Started
 - Video Playback Seek Completed
 - Video Playback Buffer Started
 - Video Playback Buffer Completed
 - Video Playback Interrupted *
 - Application Backgrounded
 
 *
 For this event, only the application backgrounding scenario was accounted for. Per Segment requirements, other conditions should trigger this event. See https://segment.com/docs/spec/video/ for more information.
 */
@interface SEGNielsenVideoPlayerViewController ()

@property (nonatomic, strong) NSDictionary *playbackHandlers;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) NSTimer *controlsTimer;
@property (nonatomic) BOOL showingControls;
@property (nonatomic) BOOL startedPlaying;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL startedScrubbing;
@property (nonatomic) BOOL lastKnownPlaybackLikelyToKeepUp;
@property (nonatomic) BOOL lastKnownPlaybackBufferEmpty;
@property (nonatomic) BOOL startedBuffering;

@end

@implementation SEGNielsenVideoPlayerViewController

-(void)dealloc
{
    [self teardownObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self setupHandlers];
    [self setupNotificationObservers];
    [self setupGestureHandlers];
    
    if (self.model) {
        [self setupPlayerWithModel:self.model];
        [self showLoading:YES animated:YES];
        [self resetPlayer];
        [self playFromInitial:YES resumedFromSeek:NO];
    }
}

-(void)viewDidLayoutSubviews
{
    if (self.playerLayer) {
        [self.playerLayer setFrame:self.view.bounds];
    }
}

#pragma mark - IBActions

-(IBAction)closeButtonTapped:(id)sender
{
    [self closePlayer];
}

-(IBAction)playPauseButtonTapped:(id)sender
{
    if (self.isPlaying) {
        [self pauseAndTrack:YES];
    }
    else {
        [self play];
    }
    
    [self refreshControlsTimer];
}

#pragma mark -

-(void)play
{
    [self playResumedFromSeek:NO];
}

-(void)playResumedFromSeek:(BOOL)resumedFromSeek
{
    [self playFromInitial:NO resumedFromSeek:resumedFromSeek];
}

-(void)playFromInitial:(BOOL)initial resumedFromSeek:(BOOL)resumedFromSeek
{
    self.isPlaying = YES;
    [self.player play];
    [self updatePlayPauseButton:YES];
    if (!initial && !resumedFromSeek) {
        NSLog(@"LOG: tracking Video Playback Resumed");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Resumed" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }
}

-(void)pause
{
    [self pauseAndTrack:NO];
}

-(void)pauseAndTrack:(BOOL)trackEvent
{
    self.isPlaying = NO;
    [self.player pause];
    [self updatePlayPauseButton:NO];
    if (trackEvent) {
        NSLog(@"LOG: tracking Video Playback Paused");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Paused" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }
}

-(void)closePlayer
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"LOG: tracking Video Playback Completed");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Completed" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }];
}

-(void)showControls:(BOOL)show
{
    self.showingControls = show;
    float alpha = show ? 1.0 : 0;
    [UIView animateWithDuration:0.2 animations:^{
        [self.controlsOverlay setAlpha:alpha];
    }];
    
    if (show) {
        [self refreshControlsTimer];
    }
    else {
        if (self.controlsTimer) {
            [self.controlsTimer invalidate];
            self.controlsTimer = nil;
        }
    }
}

-(void)showLoading:(BOOL)loading animated:(BOOL)animated
{
    float alpha = loading ? 1.0 : 0;
    
    void (^completion)(void) = ^void() {
        [self.activityIndicator setAlpha:alpha];
        if (loading) {
            [self.activityIndicator setHidden:NO];
            [self.activityIndicator startAnimating];
        }
        else {
            [self.activityIndicator stopAnimating];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            completion();
        }];
    }
    else {
        completion();
    }
}

-(void)refreshControlsTimer
{
    if (self.controlsTimer) {
        [self.controlsTimer invalidate];
    }
    
    self.controlsTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self showControls:NO];
    }];
}

-(void)updatePlayPauseButton:(BOOL)paused
{
    NSString *imageName = paused ? @"btn_pause" : @"btn_play";
    [self.playPauseButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

-(int)getCurrentPlayerTimeSeconds
{
    if (self.player) {
        CMTime currentTime = [self.player currentTime];
        int currentTimeSeconds = (int)currentTime.value / currentTime.timescale;
        return currentTimeSeconds;
    }
    
    return 0;
}

-(void)updateProgressWithCurrent:(NSInteger )current duration:(NSInteger )duration
{
    NSInteger remaining = duration - current;
    
    [self.currentProgressLabel setText:[self formatSecondsToTime:current]];
    [self.remainingProgressLabel setText:[self formatSecondsToTime:remaining]];
    [self.progressSlider setValue:(float)current];
}

-(NSString *)formatSecondsToTime:(NSInteger)seconds
{
    long h = seconds / 3600;
    long m = (seconds / 60) % 60;
    long s = seconds % 60;

    return [NSString stringWithFormat:@"%lu%@%02lu%@%02lu", h,@":",m,@":",s];
}

-(NSMutableDictionary *)trackingPropertiesForModelWithCurrentPlayProgress
{
    NSMutableDictionary *baseProperties = [self trackingPropertiesForModel];
    if (self.player && self.startedPlaying) {
        [baseProperties addEntriesFromDictionary:@{
                                                   @"position": [NSNumber numberWithInteger:[self getCurrentPlayerTimeSeconds]],
                                                   }];
    }
    
    return baseProperties;
}

-(NSMutableDictionary *)trackingPropertiesForModel
{
    if (self.model) {
        return [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                 @"asset_id" : self.model.videoId,
                                                                 @"channel": self.model.channelName,
                                                                 @"load_type": self.model.loadType,
                                                                 @"title": self.model.title,
                                                                 @"description": self.model.videoDescription,
                                                                 @"total_length": [NSNumber numberWithInteger:self.model.duration],
                                                                 }];
    }
    return [[NSMutableDictionary alloc] init];
}

#pragma mark - Handlers
#pragma mark -
#pragma mark Gesture Handlers

-(void)handleTapGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    [self showControls:!self.showingControls];
}

-(void)handleSliderChanged:(id)sender forEvent:(UIEvent *)event
{
    if (self.isPlaying) {
        [self pause];
    }
    
    [self updateProgressWithCurrent:self.progressSlider.value duration:self.model.duration];
    [self refreshControlsTimer];
    
    UITouch *touch = [[event allTouches] anyObject];
    if (touch) {
        UITouchPhase phase = [touch phase];
        switch (phase) {
            case UITouchPhaseBegan: {
                self.startedScrubbing = YES;
            }
            default: {
                break;
            }
        }
    }
}

-(void)handleSliderEnded:(id)sender
{
    NSMutableDictionary *seekStartedProperties = [self trackingPropertiesForModelWithCurrentPlayProgress];
    [seekStartedProperties addEntriesFromDictionary:@{
                                                      @"seek_position":[NSNumber numberWithFloat:self.progressSlider.value],
                                                      }];
    NSLog(@"LOG: tracking Video Playback Seek Started");
    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Seek Started"
                               properties:seekStartedProperties];
    
    [self showLoading:YES animated:YES];
    [self.player seekToTime:CMTimeMake(self.progressSlider.value, 1) completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"LOG: tracking Video Playback Seek Completed");
            [self showLoading:NO animated:YES];
            self.startedScrubbing = NO;
            [[SEGAnalytics sharedAnalytics] track:@"Video Playback Seek Completed"
                                       properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
            [self playResumedFromSeek:YES];
        }
    }];
}

-(void)handleBufferWithPlaybackLikelyToKeepUp:(BOOL)isPlaybackLikelyToKeepUp
                        isPlaybackBufferEmpty:(BOOL)isPlaybackBufferEmpty
{
    if (!self.startedPlaying) {
        return;
    }
    
    if (self.lastKnownPlaybackBufferEmpty == isPlaybackBufferEmpty && self.lastKnownPlaybackLikelyToKeepUp == isPlaybackLikelyToKeepUp) {
        return;
    }
    
    self.lastKnownPlaybackLikelyToKeepUp = isPlaybackLikelyToKeepUp;
    self.lastKnownPlaybackBufferEmpty = isPlaybackBufferEmpty;
    
    if (!isPlaybackLikelyToKeepUp && isPlaybackBufferEmpty && !self.startedBuffering) {
        self.startedBuffering = YES;
        [self showLoading:YES animated:YES];
        NSLog(@"LOG: tracking Video Playback Buffer Started");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Buffer Started" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }
    else if (isPlaybackLikelyToKeepUp && !isPlaybackBufferEmpty && self.startedBuffering) {
        self.startedBuffering = NO;
        [self showLoading:NO animated:YES];
        NSLog(@"LOG: tracking Video Playback Buffer Completed");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Buffer Completed" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }
}

#pragma mark Notification Handlers

-(void)handlePlaybackEndedNotification:(NSNotification *)notification
{
    NSLog(@"LOG: tracking Video Content Completed");
    [[SEGAnalytics sharedAnalytics] track:@"Video Content Completed" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 500), dispatch_get_main_queue(), ^{
        [self closePlayer];
    });
}

-(void)handleAppBackgroundedNotification:(NSNotification *)notification
{
    if (self.isPlaying) {
        // Default behaviour is to pause on background, no auto-resume in this sample
        self.isPlaying = NO;
        [self updatePlayPauseButton:NO];
        NSLog(@"LOG: tracking Video Playback Interrupted");
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Interrupted" properties:[self trackingPropertiesForModelWithCurrentPlayProgress]];
    }
    NSLog(@"LOG: tracking Application Backgrounded");
    [[SEGAnalytics sharedAnalytics] track:@"Application Backgrounded"];
}

#pragma mark Keypath Observers

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    void (^statusHandler)(id newValue, void *context) = [self.playbackHandlers valueForKey:keyPath];
    if (statusHandler != nil) {
        statusHandler(newValue, context);
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark - Setup
#pragma mark -

-(void)resetPlayer
{
    if (self.model) {
        [self setupSliderWithMinimum:0 maximum:(float)self.model.duration current:0];
    }
    self.isPlaying = NO;
    self.startedScrubbing = NO;
    self.startedPlaying = NO;
}

-(void)setupPlayerWithModel:(SEGVideoModel *)model
{
    NSString *videoUrl = model.url;
    self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:videoUrl]];
    __weak SEGNielsenVideoPlayerViewController *weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
        if (!weakSelf.startedScrubbing) {
            NSInteger current = (NSInteger)(time.value / time.timescale);
            [weakSelf updateProgressWithCurrent:current duration:weakSelf.model.duration];
        }
    }];
    [self setupObserversForPlayerItem:[self.player currentItem]];
    
    AVPlayerLayer *layer = [[AVPlayerLayer alloc] init];
    [layer setFrame:self.view.bounds];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspect];
    layer.player = self.player;
    self.playerLayer = layer;
    [self.playerView.layer addSublayer:layer];
    
    [self.titleLabel setText:model.title];
}

-(void)setupObserversForPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem == nil) {
        return;
    }
    
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // Warning - the 'timedMetadata' property is deprecated after iOS 13.0
    [playerItem addObserver:self forKeyPath:@"timedMetadata" options:NSKeyValueObservingOptionNew context:&TimedMetadataObserverContext];
}

-(void)setupNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlaybackEndedNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppBackgroundedNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void)setupHandlers
{
    BOOL (^isNumberClass)(id newValue) = ^BOOL(id newValue) {
        @try{
            return [newValue isKindOfClass:[NSNumber class]];
        } @catch (NSException *exception) {
            return NO;
        }
    };
    
    self.playbackHandlers = @{
                              @"status": ^(id newValue, void *context) {
                                  if (!isNumberClass(newValue)) {
                                      return;
                                  }
                                  
                                  NSNumber *statusNumber = (NSNumber *)newValue;
                                  AVPlayerStatus status = [statusNumber integerValue];
                                  switch (status) {
                                      case AVPlayerItemStatusReadyToPlay: {
                                          [self showLoading:NO animated:YES];
                                          NSLog(@"tracking Video Content Started");
                                          [[SEGAnalytics sharedAnalytics] track:@"Video Content Started" properties:[self trackingPropertiesForModel]];
                                          self.startedPlaying = YES;
                                          break;
                                      }
                                      case AVPlayerItemStatusFailed: {
                                          // Handle failure here
                                          break;
                                      }
                                      case AVPlayerItemStatusUnknown: {
                                          break;
                                      }
                                  }
                              },
                              @"playbackBufferEmpty": ^(id newValue, void *context) {
                                  if (!isNumberClass(newValue)) {
                                      return;
                                  }
                                  
                                  NSNumber *newPlaybackBufferEmpty = (NSNumber *)newValue;
                                  BOOL playbackBufferEmpty = [newPlaybackBufferEmpty boolValue];
                                  [self handleBufferWithPlaybackLikelyToKeepUp:[[self.player currentItem] isPlaybackLikelyToKeepUp] isPlaybackBufferEmpty:playbackBufferEmpty];
                              },
                              @"playbackLikelyToKeepUp": ^(id newValue, void *context) {
                                  if (!isNumberClass(newValue)) {
                                      return;
                                  }
                                  
                                  NSNumber *newPlaybackLikelyToKeepUp = (NSNumber *)newValue;
                                  BOOL playbackLikelyToKeepUp = [newPlaybackLikelyToKeepUp boolValue];
                                  [self handleBufferWithPlaybackLikelyToKeepUp:playbackLikelyToKeepUp isPlaybackBufferEmpty:[[self.player currentItem] isPlaybackBufferEmpty]];
                              },
                              @"timedMetadata": ^(id newValue, void *context) {
                                  if (context != &TimedMetadataObserverContext || newValue != [NSNull null]) {
                                      return;
                                  }
                                  
                                  NSArray<AVMetadataItem *> *timedMetadata = (NSArray *)newValue;
                                  for (AVMetadataItem *metadataItem in timedMetadata) {
                                      id extraAttributeType = [metadataItem extraAttributes];
                                      
                                      NSString *extraString = nil;
                                      if ([extraAttributeType isKindOfClass:[NSDictionary class]]) {
                                          // Expecting content to contain plists encoded as timed metadata
                                          extraString = [extraAttributeType valueForKey:@"info"];
                                      }
                                      else if ([extraAttributeType isKindOfClass:[NSString class]]) {
                                          extraString = extraAttributeType;
                                      }
                                      
                                      NSString *key = [NSString stringWithFormat:@"%@", [metadataItem key]];
                                      
                                      if ([key isEqualToString:@"PRIV"] && [extraString rangeOfString:@"www.nielsen.com"].length > 0) {
                                          // TODO Add sendID3 here
                                      }
                                  }
                              },
                              };
}

-(void)setupSliderWithMinimum:(float)minimum maximum:(float)maximum current:(float)current
{
    [self.progressSlider setMinimumValue:minimum];
    [self.progressSlider setMaximumValue:maximum];
    [self.progressSlider setValue:current];
}

-(void)setupGestureHandlers
{
    UIGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    [self.progressSlider addTarget:self
                            action:@selector(handleSliderChanged:forEvent:)
                  forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self
                            action:@selector(handleSliderEnded:)
                  forControlEvents:(UIControlEventTouchUpOutside | UIControlEventTouchUpInside)];
}

-(void)setupUI
{
    [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
    [self.playerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
    
    [self.activityIndicator setColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.activityIndicator setTintColor:[UIColor colorWithWhite:1 alpha:1]];
    
    [self.titleLabel setText:@""];
    [self.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.titleLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
    
    [self.currentProgressLabel setText:@""];
    [self.currentProgressLabel setFont:[UIFont systemFontOfSize:12]];
    [self.currentProgressLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.remainingProgressLabel setText:@""];
    [self.remainingProgressLabel setFont:[UIFont systemFontOfSize:12]];
    [self.remainingProgressLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
    
    [self.controlsOverlay setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.3]];
    [self.controlsOverlay setAlpha:0];
    self.showingControls = NO;
    
    [self.closeButton setTintColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.closeButton setImage:[UIImage imageNamed:@"btn_close"] forState:UIControlStateNormal];
    [self.closeButton setTitle:@"" forState:UIControlStateNormal];
    
    [self.playPauseButton setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
    [self.playPauseButton setTintColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.playPauseButton setTitle:@"" forState:UIControlStateNormal];
}

-(void)teardownObservers
{
    if (self.player) {
        AVPlayerItem *playerItem = [self.player currentItem];
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [playerItem removeObserver:self forKeyPath:@"timedMetadata"];
    }
    if (self.progressSlider) {
        [self.progressSlider removeTarget:self action:@selector(handleSliderChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
        [self.progressSlider removeTarget:self action:@selector(handleSliderEnded:) forControlEvents:(UIControlEventTouchUpOutside | UIControlEventTouchUpInside)];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
