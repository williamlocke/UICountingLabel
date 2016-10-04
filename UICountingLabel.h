#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UILabelCountingMethod) {
    UILabelCountingMethodEaseInOut,
    UILabelCountingMethodEaseIn,
    UILabelCountingMethodEaseOut,
    UILabelCountingMethodLinear
};

typedef NSString* (^UICountingLabelFormatBlock)(double value);
typedef NSAttributedString* (^UICountingLabelAttributedFormatBlock)(double value);

@interface UICountingLabel : UILabel

@property (nonatomic, strong) NSString *format;
@property (nonatomic, assign) UILabelCountingMethod method;
@property (nonatomic, assign) NSTimeInterval animationDuration;

@property (nonatomic, copy) UICountingLabelFormatBlock formatBlock;
@property (nonatomic, copy) UICountingLabelAttributedFormatBlock attributedFormatBlock;
@property (nonatomic, copy) void (^completionBlock)();

@property BOOL makeDollarSignSmaller;

-(void)countFrom:(double)value to:(double)endValue;
-(void)countFrom:(double)startValue to:(double)endValue withDuration:(NSTimeInterval)duration;

-(void)countFromCurrentValueTo:(double)endValue;
-(void)countFromCurrentValueTo:(double)endValue withDuration:(NSTimeInterval)duration;

-(void)countFromZeroTo:(double)endValue;
-(void)countFromZeroTo:(double)endValue withDuration:(NSTimeInterval)duration;

- (double)currentValue;

@end

