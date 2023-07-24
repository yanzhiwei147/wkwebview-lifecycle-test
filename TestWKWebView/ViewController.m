//
//  ViewController.m
//  TestWKWebView
//
//  Created by arida on 2023/7/21.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, _WKProcessTerminationReason) {
    _WKProcessTerminationReasonExceededMemoryLimit,
    _WKProcessTerminationReasonExceededCPULimit,
    _WKProcessTerminationReasonRequestedByClient,
    _WKProcessTerminationReasonCrash,
};

typedef NS_OPTIONS(NSUInteger, _WKRenderingProgressEvents) {
    _WKRenderingProgressEventFirstLayout = 1 << 0,
    _WKRenderingProgressEventFirstVisuallyNonEmptyLayout = 1 << 1,
    _WKRenderingProgressEventFirstPaintWithSignificantArea = 1 << 2,
    _WKRenderingProgressEventReachedSessionRestorationRenderTreeSizeThreshold  = 1 << 3,
    _WKRenderingProgressEventFirstLayoutAfterSuppressedIncrementalRendering = 1 << 4,
    _WKRenderingProgressEventFirstPaintAfterSuppressedIncrementalRendering = 1 << 5,
    _WKRenderingProgressEventFirstPaint = 1 << 6,
    _WKRenderingProgressEventDidRenderSignificantAmountOfText = 1 << 7,
    _WKRenderingProgressEventFirstMeaningfulPaint = 1 << 8,
};

void printLog(SEL selector) {
    NSLog(@"[Native] lifecycle: '%@'", NSStringFromSelector(selector));
}

void printLog2(SEL selector, NSString *ext) {
    NSLog(@"[Native] lifecycle: '%@'%@", NSStringFromSelector(selector), ext);
}

@interface ViewController()<WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ViewController

- (void)dealloc {
    [self.webView stopLoading];
    self.webView.navigationDelegate = nil;
    [self.webView removeFromSuperview];
    self.webView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    printLog(NSSelectorFromString(@"addUserScript:"));
    [userContentController addUserScript:[self demoUserScript]];
    printLog(NSSelectorFromString(@"addScriptMessageHandler:"));
    [userContentController addScriptMessageHandler:self name:@"demo"];
    config.userContentController = userContentController;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    
    // 添加手势识别器
    UISwipeGestureRecognizer *swipeGestureBack = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeGestureBack.direction = UISwipeGestureRecognizerDirectionRight;
    [self.webView addGestureRecognizer:swipeGestureBack];

    UISwipeGestureRecognizer *swipeGestureForward = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeGestureForward.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.webView addGestureRecognizer:swipeGestureForward];
    
#if 1
    NSURL *htmlFileURL = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"html"];
    if (htmlFileURL) {
        NSURL *htmlFileBaseURL = [htmlFileURL URLByDeletingLastPathComponent];
        printLog(NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:"));
        [self.webView loadFileURL:htmlFileURL allowingReadAccessToURL:htmlFileBaseURL];
    }
#else
    NSURL *url = [NSURL URLWithString:@"https://www.example.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
#endif
}

- (WKUserScript *)demoUserScript {
    NSURL *jsFileURL = [[NSBundle mainBundle] URLForResource:@"inject" withExtension:@"js"];
    NSString *scriptSource = [NSString stringWithContentsOfURL:jsFileURL encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *script = [[WKUserScript alloc] initWithSource:scriptSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    return script;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"demo"]) {
        NSLog(@"[JS] %@", message.body);
    }
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        // 如果手势方向为右，执行返回操作
        if ([self.webView canGoBack]) {
            printLog(NSSelectorFromString(@"goBack"));
            [self.webView goBack];
        }
    } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        // 如果手势方向为左，执行前进操作
        if ([self.webView canGoForward]) {
            printLog(NSSelectorFromString(@"goForward"));
            [self.webView goForward];
        }
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    printLog(_cmd);
}

- (void)_webView:(WKWebView *)webView webContentProcessDidTerminateWithReason:(_WKProcessTerminationReason)reason {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    printLog(_cmd);
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    printLog(_cmd);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)_webView:(WKWebView *)webView renderingProgressDidChange:(_WKRenderingProgressEvents)progressEvents {
    printLog2(_cmd, [NSString stringWithFormat:@" => '%lu'", (unsigned long)progressEvents]);
}

- (void)_webView:(WKWebView *)webView contentRuleListWithIdentifier:(NSString *)identifier performedAction:(id)action forURL:(NSURL *)url {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    printLog(_cmd);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    printLog(_cmd);
}
@end
