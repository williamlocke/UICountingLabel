#import "UICountingLabel.h"

#if !__has_feature(objc_arc)
#error UICountingLabel is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#pragma mark - UILabelCounter

#ifndef kUILabelCounterRate
#define kUILabelCounterRate 3.0
#endif

@protocol UILabelCounter<NSObject>

-(double)update:(double)t;

@end

@interface UILabelCounterLinear : NSObject<UILabelCounter>

@end

@interface UILabelCounterEaseIn : NSObject<UILabelCounter>

@end

@interface UILabelCounterEaseOut : NSObject<UILabelCounter>

@end

@interface UILabelCounterEaseInOut : NSObject<UILabelCounter>

@end

@implementation UILabelCounterLinear

-(double)update:(double)t
{
    return t;
}

@end

@implementation UILabelCounterEaseIn

-(double)update:(double)t
{
    return powf(t, kUILabelCounterRate);
}

@end

@implementation UILabelCounterEaseOut

-(double)update:(double)t{
    return 1.0-powf((1.0-t), kUILabelCounterRate);
}

@end

@implementation UILabelCounterEaseInOut

-(double) update: (double) t
{
	long int sign =1;
	long int r = (long int) kUILabelCounterRate;
	if (r % 2 == 0)
		sign = -1;
	t *= 2;
	if (t < 1)
		return 0.5f * powf(t, kUILabelCounterRate);
	else
		return sign * 0.5f * (powf(t-2, kUILabelCounterRate) + sign * 2);
}

@end

#pragma mark - UICountingLabel

@interface UICountingLabel ()

@property double startingValue;
@property double destinationValue;
@property NSTimeInterval progress;
@property NSTimeInterval lastUpdate;
@property NSTimeInterval totalTime;
@property double easingRate;

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, strong) id<UILabelCounter> counter;

@end

@implementation UICountingLabel

-(void)countFrom:(double)value to:(double)endValue {
    
    if (self.animationDuration == 0.0f) {
        self.animationDuration = 2.0f;
    }
    
    [self countFrom:value to:endValue withDuration:self.animationDuration];
}

-(void)countFrom:(double)startValue to:(double)endValue withDuration:(NSTimeInterval)duration {
    
    self.startingValue = startValue;
    self.destinationValue = endValue;
    
    // remove any (possible) old timers
    [self.timer invalidate];
    self.timer = nil;
    
    if (duration == 0.0) {
        // No animation
        [self setTextValue:endValue];
        [self runCompletionBlock];
        return;
    }

    self.easingRate = 3.0f;
    self.progress = 0;
    self.totalTime = duration;
    self.lastUpdate = [NSDate timeIntervalSinceReferenceDate];

    if(self.format == nil)
        self.format = @"%f";

    switch(self.method)
    {
        case UILabelCountingMethodLinear:
            self.counter = [[UILabelCounterLinear alloc] init];
            break;
        case UILabelCountingMethodEaseIn:
            self.counter = [[UILabelCounterEaseIn alloc] init];
            break;
        case UILabelCountingMethodEaseOut:
            self.counter = [[UILabelCounterEaseOut alloc] init];
            break;
        case UILabelCountingMethodEaseInOut:
            self.counter = [[UILabelCounterEaseInOut alloc] init];
            break;
    }

    NSTimer *timer = [NSTimer timerWithTimeInterval:(1.0f/30.0f) target:self selector:@selector(updateValue:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:UITrackingRunLoopMode];
    self.timer = timer;
}

- (void)countFromCurrentValueTo:(double)endValue {
    [self countFrom:[self currentValue] to:endValue];
}

- (void)countFromCurrentValueTo:(double)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:[self currentValue] to:endValue withDuration:duration];
}

- (void)countFromZeroTo:(double)endValue {
    [self countFrom:0.0f to:endValue];
}

- (void)countFromZeroTo:(double)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:0.0f to:endValue withDuration:duration];
}

- (void)updateValue:(NSTimer *)timer {
    
    // update progress
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    self.progress += now - self.lastUpdate;
    self.lastUpdate = now;
    
    if (self.progress >= self.totalTime) {
        [self.timer invalidate];
        self.timer = nil;
        self.progress = self.totalTime;
    }
    
    [self setTextValue:[self currentValue]];
    
    if (self.progress == self.totalTime) {
        [self runCompletionBlock];
    }
}

- (void)setTextValue:(double)value
{
    if (self.attributedFormatBlock != nil) {
        self.attributedText = self.attributedFormatBlock(value);
    }
    else if(self.formatBlock != nil)
    {
        self.text = self.formatBlock(value);
    }
    else
    {
        // check if counting with ints - cast to int
        if([self.format rangeOfString:@"%(.*)ld" options:NSRegularExpressionSearch].location != NSNotFound || [self.format rangeOfString:@"%(.*)i"].location != NSNotFound )
        {
            self.text = [NSString stringWithFormat:self.format,(long int)value];
        }
        else
        {
            self.text = [NSString stringWithFormat:self.format,value];
        }
    }
    if (self.makeDollarSignSmaller) {
        [UICountingLabel makeDollarSmaller:self];
    }
}

+(void)makeDollarSmaller:(UILabel *)label{
    CGFloat fontSize = label.font.pointSize;
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont fontWithName:@"ProximaNova-Light" size:fontSize * 0.65 ]};
    NSDictionary *regAttrs = @{NSFontAttributeName:[UIFont fontWithName:@"ProximaNova-Light" size:fontSize ] };
    NSRange range = [label.text rangeOfString:@"$"];
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:label.text
                                           attributes:regAttrs];
    [attributedText setAttributes:attrs range:range];
    [label setAttributedText:attributedText];
}

+(float)multiplierForDevice{
    if(([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UIScreen mainScreen].bounds.size.height == 1366)){
        return 2.2;
    }else if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ) {
        return 1.75;
    }
    
    return 1.0;
}

- (void)setFormat:(NSString *)format {
    _format = format;
    // update label with new format
    [self setTextValue:self.currentValue];
}

- (void)runCompletionBlock {
    
    if (self.completionBlock) {
        self.completionBlock();
        self.completionBlock = nil;
    }
}

- (double)currentValue {
    
    if (self.progress >= self.totalTime) {
        return self.destinationValue;
    }
    
    double percent = self.progress / self.totalTime;
    double updateVal = [self.counter update:percent];
    return self.startingValue + (updateVal * (self.destinationValue - self.startingValue));
}

@end
