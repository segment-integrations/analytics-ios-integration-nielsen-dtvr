//
//  SEGNielsenWebViewController.h
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-24.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface SEGNielsenWebViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet WKWebView *webView;

@property (nonatomic, weak) NSString *urlString;

-(IBAction)handleCloseButtonTapped:(id)sender;

@end
