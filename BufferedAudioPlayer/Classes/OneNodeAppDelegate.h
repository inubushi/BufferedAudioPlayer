//
//  Application delegate header
//
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk )
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OneNodeViewController;

@interface OneNodeAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    OneNodeViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet OneNodeViewController *viewController;

@end

