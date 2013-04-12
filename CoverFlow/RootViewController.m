//
//  Created by tuo on 4/1/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "RootViewController.h"


@implementation RootViewController

@synthesize coverFlow;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }

    return self;
//To change the template use AppCode | Preferences | File Templates.
}

- (void)viewDidLoad {
    [super viewDidLoad];  //To change the template use AppCode | Preferences | File Templates.

    self.view.backgroundColor = [UIColor lightGrayColor];
    self.view.frame = CGRectMake(0, 0, 1024 , 768);

    NSMutableArray *sourceImages = [NSMutableArray arrayWithCapacity:20];
    for (int i = 1; i <7 ; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"LS%d.jpg", i]];
        [sourceImages addObject:image];
    }

    //CoverFlowView *coverFlowView = [CoverFlowView coverFlowViewWithFrame: frame andImages:_arrImages sidePieces:6 sideScale:0.35 middleScale:0.6];
    CoverFlowView *coverFlowView = [CoverFlowView coverFlowViewWithFrame:self.view.frame andImages:sourceImages sideImageCount:2 sideImageScale:0.8 middleImageScale:1.0];
    [self setCoverFlow:coverFlowView];
    [self.view addSubview:coverFlowView];
    

}

- (void)viewDidAppear:(BOOL)animated{
    NSMethodSignature * method = [[CoverFlowView class] instanceMethodSignatureForSelector:@selector(moveOneStep:)];
    NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:method];
    [invocation setTarget:self.coverFlow];
    [invocation setSelector:@selector(moveOneStep:)];
    BOOL is = YES;
    [invocation setArgument:&is atIndex:2];
    //[invocation invoke];
    [NSTimer scheduledTimerWithTimeInterval:1.5 invocation:invocation repeats:YES];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

@end