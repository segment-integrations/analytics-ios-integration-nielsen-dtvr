//
//  SEGNielsenVideoPlayerViewController.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-11.
//

#import <AVFoundation/AVFoundation.h>
#import <Analytics/SEGAnalytics.h>
#import "SEGNielsenVideoPlayerViewController.h"

@interface SEGNielsenVideoPlayerViewController ()

@property (nonatomic, strong) NSDictionary *playbackHandlers;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak) AVPlayerItem *playerItemRef;
@property (nonatomic, weak) AVAsset *asset;

@property (nonatomic, strong) NSTimer *controlsTimer;
@property (nonatomic) BOOL showingControls;
@property (nonatomic) BOOL isPlaying;

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
        [self resetPlayer];
        [self play:YES];
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    AVLayerVideoGravity gravity = size.width > size.height ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect;
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
        [self pause];
    }
    else {
        [self play];
    }
    
    [self refreshControlsTimer];
}


-(IBAction)sliderUpdated:(id)sender
{
    [self refreshControlsTimer];
}

#pragma mark -

-(void)play
{
    [self play:NO];
}

-(void)play:(BOOL)initial
{
    self.isPlaying = YES;
    [self.player play];
    [self updatePlayPauseButton:YES];
    if (!initial) {
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Resumed" properties:@{
                                                                                     @"asset_id" : self.model.videoId,
                                                                                     @"channel": self.model.channelName,
                                                                                     @"load_type": self.model.loadType,
                                                                                     }];
    }
}

-(void)pause
{
    self.isPlaying = NO;
    [self.player pause];
    [self updatePlayPauseButton:NO];
    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Paused" properties:@{
                                                                                @"asset_id" : self.model.videoId,
                                                                                @"channel": self.model.channelName,
                                                                                @"load_type": self.model.loadType,
                                                                                }];
}

-(void)closePlayer
{
    [self.player pause];
    [self dismissViewControllerAnimated:YES completion:^{
        [[SEGAnalytics sharedAnalytics] track:@"Video Playback Completed" properties:@{
                                                                                       @"asset_id" : self.model.videoId,
                                                                                       @"channel": self.model.channelName,
                                                                                       @"load_type": self.model.loadType,
                                                                                       }];
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

#pragma mark - Handlers
#pragma mark -
#pragma mark Gesture Handlers

-(void)handleTapGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    [self showControls:!self.showingControls];
}

-(void)handleSliderChanged:(id)sender forEvent:(UIEvent *)event
{
    if ([self isPlaying]) {
        [self pause];
    }
    
    [self updateProgressWithCurrent:self.progressSlider.value duration:self.model.duration];
    
    UITouch *touch = [[event allTouches] anyObject];
    if (touch) {
        UITouchPhase phase = [touch phase];
        switch (phase) {
            case UITouchPhaseEnded: {
                [[SEGAnalytics sharedAnalytics] track:@"Video Playback Seek Started" properties:@{
                                                                                                  @"asset_id" : self.model.videoId,
                                                                                                  @"channel": self.model.channelName,
                                                                                                  @"load_type": self.model.loadType,
                                                                                                  @"seek_position":[NSNumber numberWithFloat:self.progressSlider.value],
                                                                                                  @"position": [NSNumber numberWithInt:[self getCurrentPlayerTimeSeconds]]
                                                                                                  }];
                [self.player seekToTime:CMTimeMake(self.progressSlider.value, 1) completionHandler:^(BOOL finished) {
                    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Seek Completed" properties:@{
                                                                                                        @"asset_id" : self.model.videoId,
                                                                                                        @"channel": self.model.channelName,
                                                                                                        @"load_type": self.model.loadType,
                                                                                                        @"position": [NSNumber numberWithInt:[self getCurrentPlayerTimeSeconds]]
                                                                                                        }];
                    [self play];
                }];
            }
            default: {
                break;
            }
        }
    }
    
    [self refreshControlsTimer];
}

#pragma mark Notification Handlers

-(void)handlePlaybackEndedNotification:(NSNotification *)notification
{
    // Send SEG Completed
}

-(void)handleAppBackgroundedNotification:(NSNotification *)notification
{
    [[SEGAnalytics sharedAnalytics] track:@"Application Backgrounded"];
}

#pragma mark Keypath Observers

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    void (^statusHandler)(id newValue) = [self.playbackHandlers valueForKey:keyPath];
    if (statusHandler != nil) {
        statusHandler(newValue);
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
}

-(void)setupPlayerWithModel:(SEGVideoModel *)model
{
    NSString *videoUrl = model.url;
    self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:videoUrl]];
    __weak SEGNielsenVideoPlayerViewController *weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
        NSInteger current = (NSInteger)(time.value / time.timescale);
        [weakSelf updateProgressWithCurrent:current duration:weakSelf.model.duration];
    }];
    [self setupObserversForPlayerItem:[self.player currentItem]];
    
    AVPlayerLayer *layer = [[AVPlayerLayer alloc] init];
    [layer setFrame:self.view.bounds];
    [layer setVideoGravity:AVLayerVideoGravityResizeAspect];
    layer.player = self.player;
    self.playerLayer = layer;
    [self.playerView.layer addSublayer:layer];
}

-(void)setupObserversForPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem == nil) {
        return;
    }
    
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
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
                              @"status": ^(id newValue) {
                                  if (!isNumberClass(newValue)) {
                                      return;
                                  }
                                  
                                  NSNumber *statusNumber = (NSNumber *)newValue;
                                  AVPlayerStatus status = [statusNumber integerValue];
                                  switch (status) {
                                      case AVPlayerItemStatusReadyToPlay: {
                                          [[SEGAnalytics sharedAnalytics] track:@"Video Content Started" properties:@{
                                                                                                                      @"asset_id" : self.model.videoId,
                                                                                                                      @"channel": self.model.channelName,
                                                                                                                      @"load_type": self.model.loadType,
                                                                                                                      }];
                                          break;
                                      }
                                      case AVPlayerItemStatusFailed: {
                                          // Send SEG Stop?
                                          break;
                                      }
                                      case AVPlayerItemStatusUnknown: {
                                          break;
                                      }
                                  }
                              },
                              @"playbackBufferEmpty": ^(id newValue) {
                                  if (!isNumberClass(newValue)) {
                                      return;
                                  }
                                  
                                  NSNumber *newPlaybackBufferEmpty = (NSNumber *)newValue;
                                  BOOL playbackBufferEmpty = [newPlaybackBufferEmpty boolValue];
                                  NSString *event = playbackBufferEmpty ? @"Video Playback Buffer Started" : @"Video Playback Buffer Completed";
                                  [[SEGAnalytics sharedAnalytics] track:event];
                              }
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
    
    [self.progressSlider addTarget:self action:@selector(handleSliderChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
}

-(void)setupUI
{
    [self.view setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
    [self.playerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
    
    [self.currentProgressLabel setFont:[UIFont systemFontOfSize:12]];
    [self.currentProgressLabel setTextColor:[UIColor colorWithWhite:1 alpha:1]];
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
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
