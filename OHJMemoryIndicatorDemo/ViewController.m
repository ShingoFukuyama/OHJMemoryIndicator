//
//  ViewController.m
//  OHJMemoryIndicatorDemo
//
//  Created by ShingoFukuyama on 7/12/15.
//  Copyright (c) 2015 ShingoFukuyama. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *viewBase;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self viewBase];
    [self button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIView *)viewBase
{
    if (!_viewBase) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view insertSubview:view atIndex:0];
        view.alpha = 0.9;

        UIView *superview = view.superview;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [superview addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(view)]];
        [superview addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(view)]];
        _viewBase = view;
    }
    return _viewBase;
}

- (UIButton *)button
{
    if (!_button) {
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectZero;
        button.backgroundColor = [UIColor colorWithRed:0.285 green:0.641 blue:1.000 alpha:1.000];
        button.layer.cornerRadius = 5.0f;
        [button setTitle:@"Tap!" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];

        UIView *view = button;
        UIView *superview = button.superview;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:200.0f]];
        [superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:superview
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0f
                                                               constant:0.0f]];
        [superview addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:@"V:[view(60.0)]-100-|"
                                       options:NSLayoutFormatDirectionLeadingToTrailing
                                       metrics:nil
                                       views:NSDictionaryOfVariableBindings(view)]];


        _button = button;
    }
    return _button;
}

- (void)didTapButton
{
    static BOOL toggle;
    static NSTimer *timer;
    if (toggle) {
        toggle = NO;
        [timer invalidate];
        [_viewBase removeFromSuperview];
        _viewBase = nil;
        [_button setTitle:@"Tap!" forState:UIControlStateNormal];
    } else {
        toggle = YES;
        [_button setTitle:@"Stop" forState:UIControlStateNormal];
        __weak typeof(self) weakSelf = self;
        timer = [NSTimer timerWithTimeInterval:0.5 target:[NSBlockOperation blockOperationWithBlock:^{
            if (!weakSelf) {
                return;
            }
            __strong typeof(weakSelf) strongSelf = weakSelf;
            for (NSInteger i = 0; i < 1000; i++) {
                [strongSelf addView];
            }

        }] selector:@selector(main) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)addView
{
    CGRect frame = self.view.frame;
    __unused CGFloat frameWidth = CGRectGetWidth(frame);
    __unused CGFloat frameHeight = CGRectGetHeight(frame);

    CGFloat radius = (arc4random() % 100) / 100.0f * 50.0f + 5.0f;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, radius, radius)];
    view.layer.cornerRadius = radius * 0.5f;
    [self.viewBase addSubview:view];

    CGFloat centerX = ((arc4random() % 100) / 100.0f) * frameWidth;
    CGFloat centerY = ((arc4random() % 100) / 100.0f) * frameHeight;

    view.center = CGPointMake(centerX, centerY);

    CGFloat r = (arc4random() % 100) / 100.0f;
    CGFloat g = (arc4random() % 100) / 100.0f;
    CGFloat b = (arc4random() % 100) / 100.0f;
    view.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.9];
}

@end
