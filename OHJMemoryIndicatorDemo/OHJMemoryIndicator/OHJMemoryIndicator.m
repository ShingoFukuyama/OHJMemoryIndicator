//
//  OHJMemoryIndicator.m
//  OHJMemoryIndicatorDemo
//
//  Created by ShingoFukuyama on 7/12/15.
//  Copyright (c) 2015 ShingoFukuyama. All rights reserved.
//

#import "OHJMemoryIndicator.h"
#import <mach/mach.h>

@interface OHJMemoryIndicator ()
@property (nonatomic, strong) UILabel *labelBase;
@property (nonatomic, strong) NSTimer *timerUpdate;
@property (nonatomic, assign) BOOL indicating;
@end

@implementation OHJMemoryIndicator

static NSTimeInterval oUpdateInterval = 1.0;

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initSharedInstance];
    });
    return sharedInstance;
}

- (instancetype)initSharedInstance
{
    self = [super init];
    if (self) {

    }
    return self;
}

+ (void)start
{
    [OHJMemoryIndicator sharedInstance].indicating = YES;
    [[OHJMemoryIndicator sharedInstance] toggleProccess];
}

+ (void)stop
{
    [OHJMemoryIndicator sharedInstance].indicating = NO;
    [[OHJMemoryIndicator sharedInstance] toggleProccess];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.userInteractionEnabled = NO;
}

- (void)toggleProccess
{
    if (!self.indicating) {
        [self.timerUpdate invalidate];
        self.timerUpdate = nil;
        [self.view removeFromSuperview];
        self.labelBase = nil;
    }
    else {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self.view];
        self.timerUpdate = [NSTimer timerWithTimeInterval:oUpdateInterval target:self selector:@selector(updateStates) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timerUpdate forMode:NSRunLoopCommonModes];
    }
}

- (UILabel *)labelBase
{
    if (!_labelBase) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.layer.cornerRadius = 3.0f;
        label.layer.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.400].CGColor;
        label.textAlignment = NSTextAlignmentJustified;
        label.text = @"";
        label.font = [UIFont fontWithName:@"Menlo-Regular" size:10.0f];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        [self.view addSubview:label];
        _labelBase = label;
    }
    return _labelBase;
}

- (void)updateStates
{
    CGRect frame = self.view.frame;
    __unused CGFloat frameWidth = CGRectGetWidth(frame);
    __unused CGFloat frameHeight = CGRectGetHeight(frame);

    // Memory Usage of System
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
    }

    /* Stats in bytes */
    natural_t memoryUsed = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * (unsigned int)pagesize;
    natural_t memoryFree = vm_stat.free_count *(unsigned int)pagesize;
    natural_t memoryTotal = memoryUsed + memoryFree;


    // Memory Usage of App
    static int64_t lastUserTime;
    static vm_size_t lastResidentSetSize;
    struct task_basic_info t_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count) != KERN_SUCCESS) {
        NSLog(@"%s(): Error in task_info(): %s", __PRETTY_FUNCTION__, strerror(errno));
    }
    vm_size_t residentSetSize = t_info.resident_size;

    // CPU Usage
    struct task_thread_times_info threadTimeInfo;
    t_info_count = TASK_THREAD_TIMES_INFO_COUNT;
    kern_return_t status = task_info(current_task(), TASK_THREAD_TIMES_INFO,
                                     (task_info_t)&threadTimeInfo, &t_info_count);
    if (status != KERN_SUCCESS) {
        NSLog(@"%s(): Error in task_info(): %s",
              __FUNCTION__, strerror(errno));
        return;
    }

    uint64_t userTime = (threadTimeInfo.user_time.seconds * 1000) + (threadTimeInfo.user_time.microseconds * 0.001);
    int64_t userTimePerSec = (userTime - lastUserTime);
    userTimePerSec = (userTimePerSec < 0) ? 0 : userTimePerSec / oUpdateInterval;
    int64_t rssPerSec = ((int64_t)residentSetSize - lastResidentSetSize);
    rssPerSec = (rssPerSec < 0) ? 0 : rssPerSec / oUpdateInterval;
    lastUserTime = userTime;
    lastResidentSetSize = residentSetSize;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:NSTextAlignmentJustified];
    NSDictionary *attribute = @{NSParagraphStyleAttributeName:paragraphStyle};

    __weak typeof(self) weakSelf = self;
    [UIView transitionWithView:self.labelBase duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if (!weakSelf) {
            return;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;

        strongSelf.labelBase.frame = CGRectMake(25.0f, 25.0f, 120.0f, 100.0f);

        NSInteger lengthOfLine = 18;
        NSString *lineMemoryVariation = alignTextBothSides(@"USED/s[MB]", [NSString stringWithFormat:@"%0.2f", (double)(rssPerSec / (1024 * 1024))], lengthOfLine);
        NSString *lineMemoryTotal = alignTextBothSides(@"USED[MB]", [NSString stringWithFormat:@"%0.2f", (double)(residentSetSize / (1024 * 1024))], lengthOfLine);
        NSString *lineMemoryUsed = alignTextBothSides(@"USED[MB]", [NSString stringWithFormat:@"%0.2f", (double)(memoryUsed / (1024 * 1024))], lengthOfLine);
        NSString *lineMemoryUsedPercentage = alignTextBothSides(@"USED[%]", [NSString stringWithFormat:@"%0.1f%%", ((double)memoryUsed / (double)memoryTotal * 100.0)], lengthOfLine);
        NSString *lineCPUUsage = alignTextBothSides(@"CPU[ms]", [NSString stringWithFormat:@"%@", @(userTimePerSec)], lengthOfLine);
        NSString *lineNumberOfViews = alignTextBothSides(@"View:", [NSString stringWithFormat:@"%@", @([strongSelf countSubviewsInApplication])], lengthOfLine);

        NSString *text = [NSString stringWithFormat:@" %@\n %@\n %@\n %@\n SYSTEM\n %@\n %@",
                          lineMemoryVariation,
                          lineMemoryTotal,
                          lineCPUUsage,
                          lineNumberOfViews,
                          lineMemoryUsed,
                          lineMemoryUsedPercentage
                          ];

        strongSelf.labelBase.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attribute];

    } completion:^(BOOL finished) {

    }];

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.view];
    [window bringSubviewToFront:self.view];
    [self resetConstraintFillWithView:self.view];
    [self.view bringSubviewToFront:self.labelBase];
}

- (NSInteger)countSubviewsInApplication
{
    NSInteger count = 0;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        for (UIView *view in [window subviews]) {
            count++;
            count += [self countSubviewsInView:view];
        }
    }
    return count;
}

- (NSInteger)countSubviewsInView:(UIView *)view
{
    NSInteger count = 0;
    for (UIView *subview in [view subviews]) {
        count++;
        if (subview.subviews.count > 0) {
            count += [self countSubviewsInView:subview];
        }
    }
    return count;
}

NS_INLINE NSString * alignTextBothSides (NSString *title, NSString *value, NSInteger maximumLength) {
    NSString *result = value;
    NSInteger numberOfSpace = maximumLength - title.length - value.length;
    for (NSInteger i = 0; i < numberOfSpace; i++) {
        result = [@" " stringByAppendingString:result];
    }
    result = [title stringByAppendingString:result];
    return result;
};

- (void)resetConstraintFillWithView:(UIView *)view;
{
    static NSArray *constraintsHorizontal;
    static NSArray *constraintsVertical;
    static UIView *superview;

    if (constraintsHorizontal) {
        [superview removeConstraints:constraintsHorizontal];
    }
    if (constraintsVertical) {
        [superview removeConstraints:constraintsVertical];
    }

    superview = view.superview;
    if (!superview) {
        return;
    }
    view.translatesAutoresizingMaskIntoConstraints = NO;
    constraintsHorizontal = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                             options:NSLayoutFormatDirectionLeadingToTrailing
                             metrics:nil
                             views:NSDictionaryOfVariableBindings(view)];
    constraintsVertical = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                           options:NSLayoutFormatDirectionLeadingToTrailing
                           metrics:nil
                           views:NSDictionaryOfVariableBindings(view)];
    [superview addConstraints:constraintsHorizontal];
    [superview addConstraints:constraintsVertical];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
