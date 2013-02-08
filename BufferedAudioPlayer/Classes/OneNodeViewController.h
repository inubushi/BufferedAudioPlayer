//
//  View controller header
//
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk)
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//
//  circular buffer implementation by Michael Tyson ( https://github.com/michaeltyson/TPCircularBuffer )


#import <UIKit/UIKit.h>
#import "AudioPlayback.h"

@interface OneNodeViewController : UIViewController {

	AudioPlayback *audioPlayback;
}

@property (nonatomic, retain)AudioPlayback *audioPlayback;

-(IBAction)play;

@end

