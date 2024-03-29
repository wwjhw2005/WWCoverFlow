//
//  Created by tuo on 4/1/12.
//
// to change "templates" to "placeholder"
//

#import "CoverFlowView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#define DISTNACE_TO_MAKE_MOVE_FOR_SWIPE 60

@interface CoverFlowView ()

//setup templates
-(void)setupTemplateLayers;
//setup images
-(void)setupImages;
//remove sublayers (after a certain delay)
-(void)removeLayersAfterSeconds:(id)layerToBeRemoved;
//remove all sublayers
-(void)removeSublayers;
//empty imagelayers
-(void)cleanImageLayers;
//add reflections
-(void)showImageAndReflection:(CALayer *)layer;
//adjust the bounds
-(void)scaleBounds: (CALayer *) layer x:(CGFloat)scaleWidth y:(CGFloat)scaleHeight;
//add uipagecontrol
-(void)addPageControl;

@end


@implementation CoverFlowView {
@private

    NSMutableArray *_images;
    NSMutableArray *_imageLayers;
    NSMutableArray *_templateLayers;
    int _currentRenderingImageIndex;
    UIPageControl *_pageControl;
    int _sideVisibleImageCount;
    CGFloat _sideVisibleImageScale;
    CGFloat _middleImageScale;
}


@synthesize images = _images;
@synthesize imageLayers = _imageLayers;
@synthesize templateLayers = _templateLayers;
@synthesize currentRenderingImageIndex = _currentRenderingImageIndex;
@synthesize pageControl = _pageControl;
@synthesize sideVisibleImageCount = _sideVisibleImageCount;
@synthesize sideVisibleImageScale = _sideVisibleImageScale;
@synthesize middleImageScale = _middleImageScale;


- (void)adjustReflectionBounds:(CALayer *)layer scale:(CGFloat)scale {
// set originLayer's reflection bounds
    CALayer *reflectLayer = (CALayer*)[layer.sublayers objectAtIndex:0];
    [self scaleBounds:reflectLayer x:scale y:scale];
    // set originLayer's reflection bounds
    [self scaleBounds:reflectLayer.mask x:scale y:scale];
    // set originLayer's reflection bounds
    [self scaleBounds:(CALayer*)[reflectLayer.sublayers objectAtIndex:0] x:scale y:scale];
    // set originLayer's reflection position
    reflectLayer.position = CGPointMake(layer.bounds.size.width/2, layer.bounds.size.height*1.5);
    // set originLayer's mask position
    reflectLayer.mask.position = CGPointMake(reflectLayer.bounds.size.width/2, reflectLayer.bounds.size.height/2);
    // set originLayer's reflection position
    ((CALayer*)[reflectLayer.sublayers objectAtIndex:0]).position = CGPointMake(reflectLayer.bounds.size.width/2, reflectLayer.bounds.size.height/2);
}

- (void)moveOneStep:(BOOL)isSwipingToLeftDirection {
    //when move the first/last image,disable moving

    int offset = isSwipingToLeftDirection ?  0 : 1;
   // int indexOffsetFromImageLayersToTemplates = (self.currentRenderingImageIndex - self.sideVisibleImageCount < 0) ? (self.sideVisibleImageCount + 1 + offset - self.currentRenderingImageIndex) : 1 + offset;
    for (int i = 0; i < self.imageLayers.count; i++) {
        //[CATransaction setAnimationDuration:1];
        CALayer *originLayer = [self.imageLayers objectAtIndex:i];
        CALayer *targetTemplate = [self.templateLayers objectAtIndex: i + offset];
        originLayer.position = targetTemplate.position;
        originLayer.zPosition = targetTemplate.zPosition;
        originLayer.transform = targetTemplate.transform;
        //set originlayer's bounds

        CGFloat scale = 1.0f;
        if (i + offset  - 1 == self.sideVisibleImageCount) {
            scale = self.middleImageScale  / self.sideVisibleImageScale;
        } else if (((i + offset  - 1 == self.sideVisibleImageCount - 1) && isSwipingToLeftDirection) ||
                ((i + offset  - 1 == self.sideVisibleImageCount + 1) && !isSwipingToLeftDirection)) {
            scale = self.sideVisibleImageScale / self.middleImageScale;
        }

        originLayer.bounds = CGRectMake(0, 0, originLayer.bounds.size.width * scale, originLayer.bounds.size.height * scale);
        [self adjustReflectionBounds:originLayer scale:scale];

    }

    if (isSwipingToLeftDirection){
        //when current rendering index  >= sidecout
        //[CATransaction setAnimationDuration:1];
        CALayer *removeLayer = [self.imageLayers objectAtIndex:0];
        [removeLayer removeFromSuperlayer];
        [self.imageLayers removeObject:removeLayer];
        int current = self.currentRenderingImageIndex + self.sideVisibleImageCount + 1;
        if (current >= self.images.count) {
            current = (current - self.images.count) % self.images.count;
        }else if(current < 0 ){
            current = self.images.count - current;
        }
            UIImage *candidateImage = [self.images objectAtIndex:current];
            CALayer *candidateLayer = [CALayer layer];
            candidateLayer.contents = (__bridge id)candidateImage.CGImage;
            CGFloat scale = self.sideVisibleImageScale;
            candidateLayer.bounds = CGRectMake(0, 0, candidateImage.size.width * scale, candidateImage.size.height * scale);
            [self.imageLayers addObject:candidateLayer];

            CALayer *template = [self.templateLayers objectAtIndex:self.templateLayers.count - 2];
            candidateLayer.position = template.position;
            candidateLayer.zPosition = template.zPosition;
            candidateLayer.transform = template.transform;
        
            //show the layer
        [self showImageAndReflection:candidateLayer];
        

    }else{//if the right, then move the rightest layer and insert one to left (if left is full)

        //when to remove rightest, only when image in the rightest is indeed sitting in the template  imagelayer's rightes
        if (self.currentRenderingImageIndex + self.sideVisibleImageCount <= self.images.count -1) {
            CALayer *removeLayer = [self.imageLayers lastObject];
            [self.imageLayers removeObject:removeLayer];
            [removeLayer removeFromSuperlayer];
        }

        //check out whether we need to add layer to left, only when (currentIndex - sideCount > 0)
        if (self.currentRenderingImageIndex > self.sideVisibleImageCount){
            UIImage *candidateImage = [self.images objectAtIndex:self.currentRenderingImageIndex - 1 - self.sideVisibleImageCount];
            CALayer *candidateLayer = [CALayer layer];
            candidateLayer.contents = (__bridge id)candidateImage.CGImage;
            CGFloat scale = self.sideVisibleImageScale;
            candidateLayer.bounds = CGRectMake(0, 0, candidateImage.size.width * scale, candidateImage.size.height * scale);
            [self.imageLayers insertObject:candidateLayer atIndex:0];

            CALayer *template = [self.templateLayers objectAtIndex:1];
            candidateLayer.position = template.position;
            candidateLayer.zPosition = template.zPosition;
            candidateLayer.transform = template.transform;

            //show the layer
            [self showImageAndReflection:candidateLayer];
        }

    }
    //update index if you move to right, index--
    self.currentRenderingImageIndex = isSwipingToLeftDirection ? self.currentRenderingImageIndex + 1 : self.currentRenderingImageIndex - 1;

}

- (void)scaleBounds:(CALayer*)layer x:(CGFloat)scaleWidth y:(CGFloat)scaleHeight
{
    layer.bounds = CGRectMake(0, 0, layer.bounds.size.width*scaleWidth, layer.bounds.size.height*scaleHeight);
}


+ (id)coverFlowViewWithFrame:(CGRect)frame andImages:(NSMutableArray *)rawImages sideImageCount:(int)sideCount sideImageScale:(CGFloat)sideImageScale middleImageScale:(CGFloat)middleImageScale {
    CoverFlowView *flowView = [[CoverFlowView alloc] initWithFrame:frame];

    flowView.sideVisibleImageCount = sideCount;
    flowView.sideVisibleImageScale = sideImageScale;
    flowView.middleImageScale = middleImageScale;

    //default set middle image to the first image in the source images array
    flowView.currentRenderingImageIndex = 9;

    flowView.images = [NSMutableArray arrayWithArray:rawImages];
    flowView.imageLayers = [[NSMutableArray alloc] initWithCapacity:flowView.sideVisibleImageCount* 2 + 1];
    flowView.templateLayers = [[NSMutableArray alloc] initWithCapacity:(flowView.sideVisibleImageCount + 1)* 2 + 1];

    //register the pan gesture to figure out whether user has intention to move to next/previous image
   // UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:flowView action:@selector(handleGesture:)];
    //[flowView addGestureRecognizer:gestureRecognizer];

    //now almost setup
    [flowView setupTemplateLayers];

    [flowView setupImages];

    [flowView addPageControl];
    return flowView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //set up perspective
        CATransform3D transformPerspective = CATransform3DIdentity;
                        transformPerspective.m34 = -1.0 / 500.0;
                        self.layer.sublayerTransform = transformPerspective;
    }

    return self;
}

#define FACTOR 0.8
#define CenterX 1024/2
#define CenterY  -500
-(void)setupTemplateLayers {
    CGFloat centerX = self.bounds.size.width/2;
    CGFloat centerY = self.bounds.size.height/2 ;
    CGFloat radius = centerY - CenterY;
    
    UIImage * tempImage = [self.images objectAtIndex:0];
    //the angle to rotate
    //CGFloat leftRadian = M_PI/3;
    //CGFloat rightRadian = -M_PI/3;
    CGFloat sizeX = tempImage.size.width;
    CGFloat totalWidth = self.sideVisibleImageCount * 2 * sizeX * self.sideVisibleImageScale + sizeX * self.middleImageScale;
    CGFloat sub = totalWidth - self.bounds.size.width;
    //gap between images in side
    CGFloat gapBetweenMiddleAndSide= sub/ (2 + (self.sideVisibleImageCount - 1) * FACTOR);

    //gap between middle one and neigbour(this word is so hard to type wrong: WTF)
    CGFloat gapAmongSideImages  = gapBetweenMiddleAndSide * FACTOR;

    //setup the layer templates
    //let's start from left side
    for(int i = 0; i <= self.sideVisibleImageCount; i++){
       CALayer *layer = [CALayer layer];
        CGFloat  pointX = centerX - gapBetweenMiddleAndSide - gapAmongSideImages * (self.sideVisibleImageCount - i);
        CGFloat pointY = sqrtf(radius*radius - (pointX - centerX)*(pointX - centerX)) + CenterY;
       layer.position = CGPointMake(pointX, pointY );
       layer.zPosition = (i - self.sideVisibleImageCount - 1) * 10;
       //layer.transform = CATransform3DMakeRotation(leftRadian, 0, 1, 0);
       [self.templateLayers addObject:layer];
    }

    //middle

    CALayer *layer = [CALayer layer];
    layer.position = CGPointMake(centerX, centerY + 40 / self.sideVisibleImageScale);
    [self.templateLayers addObject:layer];
    //right
    for(int i = 0; i <= self.sideVisibleImageCount; i++){
        CALayer *layer = [CALayer layer];
        CGFloat  pointX = centerX + gapBetweenMiddleAndSide + gapAmongSideImages * i;
        CGFloat  pointY =  sqrtf(radius*radius - (pointX - centerX)*(pointX - centerX)) + CenterY;
        layer.position = CGPointMake(pointX, pointY);
        layer.zPosition = (i + 1) * -10;
       // layer.transform = CATransform3DMakeRotation(rightRadian, 0, 1, 0);
        [self.templateLayers addObject:layer];
    }
}

- (void)setupImages {
    // setup the visible area, and start index and end index
    int startingImageIndex = self.currentRenderingImageIndex - self.sideVisibleImageCount;
    int endImageIndex = (self.currentRenderingImageIndex + self.sideVisibleImageCount);

    //step2: set up images that ready for rendering
    for (int i = startingImageIndex; i <= endImageIndex; i++) {
        UIImage *image;
        if (i < 0) {
            image = [self.images objectAtIndex:self.images.count + i];
        }else  if (i >= [self.images count]) {
            image = [self.images objectAtIndex:i - self.images.count];
        }else {
            image = [self.images objectAtIndex:i];
        }
       CALayer *imageLayer = [CALayer layer];
       imageLayer.contents = (__bridge id)image.CGImage;
       CGFloat scale = (i == self.currentRenderingImageIndex) ? self.middleImageScale : self.sideVisibleImageScale;
       imageLayer.bounds = CGRectMake(0, 0, image.size.width * scale, image.size.height*scale);
       [self.imageLayers addObject:imageLayer];
    }

    //step3 : according to templates, set its geometry info to corresponding image layer
    //1 means the extra layer in templates layer
    //damn mathmatics
    for (int i = 0; i < self.imageLayers.count; i++) {
        CALayer *correspondingTemplateLayer = [self.templateLayers objectAtIndex:i + 1];
        CALayer *imageLayer = [self.imageLayers objectAtIndex:i];
        imageLayer.position = correspondingTemplateLayer.position;
        imageLayer.zPosition = correspondingTemplateLayer.zPosition;
        imageLayer.transform = correspondingTemplateLayer.transform;
        //show its reflections
        [self showImageAndReflection:imageLayer];
    }

}

// 添加layer及其“倒影”
- (void)showImageAndReflection:(CALayer*)layer
{
    // 制作reflection
    CALayer *reflectLayer = [CALayer layer];
    reflectLayer.contents = layer.contents;
    reflectLayer.bounds = layer.bounds;
    reflectLayer.position = CGPointMake(layer.bounds.size.width/2, layer.bounds.size.height*1.5);
    reflectLayer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);

    // 给该reflection加个半透明的layer
    CALayer *blackLayer = [CALayer layer];
    blackLayer.backgroundColor = [UIColor blackColor].CGColor;
    blackLayer.bounds = reflectLayer.bounds;
    blackLayer.position = CGPointMake(blackLayer.bounds.size.width/2, blackLayer.bounds.size.height/2);
    blackLayer.opacity = 0.6;
    [reflectLayer addSublayer:blackLayer];

    // 给该reflection加个mask
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.bounds = reflectLayer.bounds;
    mask.position = CGPointMake(mask.bounds.size.width/2, mask.bounds.size.height/2);
    mask.colors = [NSArray arrayWithObjects:
                   (__bridge id)[UIColor clearColor].CGColor,
                   (__bridge id)[UIColor whiteColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0.35);
    mask.endPoint = CGPointMake(0.5, 1.0);
    reflectLayer.mask = mask;

    // 作为layer的sublayer
    [layer addSublayer:reflectLayer];
    // 加入UICoverFlowView的sublayers
    [self.layer addSublayer:layer];
}

- (void)addPageControl {


}


- (int)getIndexForMiddle {

    return 0;
}



@end