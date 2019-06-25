//
//  SEGNielsenWebViewController.m
//  Segment-Nielsen-DTVR_Example
//
//  Created by David Hazama on 2019-06-24.
//

#import <WebKit/WKNavigationDelegate.h>
#import <Segment-Nielsen-DTVR/SEGNielsenDTVRIntegrationFactory.h>
#import <Segment-Nielsen-DTVR/SEGNielsenDTVRIntegration.h>
#import "SEGNielsenWebViewController.h"

@interface SEGNielsenWebViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation SEGNielsenWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    
    if (self.urlString) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    }
}

-(IBAction)handleCloseButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // Example of how to retrieve opt-out status via legacy opt-out method
    NSURLRequest *request = [navigationAction request];
    NSString *url = [[request URL]absoluteString];
    
    if([url isEqualToString:@"nielsenappsdk://1"] || [url isEqualToString:@"nielsenappsdk://0"]){
        NSArray *integrations = [[SEGNielsenDTVRIntegrationFactory instance] integrationsForAppId:@"NIELSEN_APP_ID_HERE"];
        SEGNielsenDTVRIntegration *integration = [integrations objectAtIndex:0];
        [integration userOptOutStatus:url];
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

-(void)setupUI
{
    [self.closeButton setTintColor:[UIColor colorWithWhite:1 alpha:1]];
    [self.closeButton setImage:[UIImage imageNamed:@"btn_close"] forState:UIControlStateNormal];
    [self.closeButton setTitle:@"" forState:UIControlStateNormal];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.webView];
    
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-[webview]-|"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:@{@"button": self.closeButton, @"webview": self.webView}];
    
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[webview]-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:@{@"webview": self.webView}];
    
    [self.view addConstraints:verticalConstraints];
    [self.view addConstraints:horizontalConstraints];
}

@end
