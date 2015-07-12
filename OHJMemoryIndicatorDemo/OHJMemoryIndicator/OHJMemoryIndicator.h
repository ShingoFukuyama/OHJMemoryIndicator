//
//  OHJMemoryIndicator.h
//  OHJMemoryIndicatorDemo
//
//  Created by ShingoFukuyama on 7/12/15.
//  Copyright (c) 2015 ShingoFukuyama. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OHJMemoryIndicator : UIViewController
+ (instancetype)sharedInstance;
+ (void)start;
+ (void)stop;
@end
