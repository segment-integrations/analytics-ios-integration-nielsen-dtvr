//
//  SEGNielsenVideoPlayerViewController.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-11.
//

#import <UIKit/UIKit.h>
#import "SEGVideoModel.h"

@interface SEGNielsenVideoPlayerViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *playerView;
@property (nonatomic, weak) IBOutlet UIView *controlsOverlay;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UISlider *progressSlider;
@property (nonatomic, weak) IBOutlet UILabel *currentProgressLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainingProgressLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) SEGVideoModel *model;

-(IBAction)closeButtonTapped:(id)sender;
-(IBAction)playPauseButtonTapped:(id)sender;

@end
