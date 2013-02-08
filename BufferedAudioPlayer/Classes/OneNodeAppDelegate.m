//
//  Application Delegate source
//
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk )
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//


#import "OneNodeAppDelegate.h"
#import "OneNodeViewController.h"
#import "AudioPlayback.h"
#import "InMemoryAudioFile.h"

@implementation OneNodeAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    	
	OneNodeViewController *oneNodeViewController = [[OneNodeViewController alloc] initWithNibName:@"OneNodeViewController" bundle:[NSBundle mainBundle]];
	
	InMemoryAudioFile *inMemoryAudioFile = [[InMemoryAudioFile alloc]init];
    
    //[inMemoryAudioFile open:[[NSBundle mainBundle] pathForResource:@"midnight-ride" ofType:@"wav"]];
    //[inMemoryAudioFile openExt:[[NSBundle mainBundle] pathForResource:@"midnight-ride" ofType:@"mp3"]];

	//set up the audio playback
	oneNodeViewController.audioPlayback = [[AudioPlayback alloc]init];	
		
	oneNodeViewController.audioPlayback.inMemoryAudioFile = inMemoryAudioFile;
    
    // now try loading the file using the new function
    [oneNodeViewController.audioPlayback loadFile:[[NSBundle mainBundle] pathForResource:@"midnight-ride" ofType:@"mp3"]];
	
	//init the audio, this usually takes a little bit of time, it should probably be done on a seperate thread
	[oneNodeViewController.audioPlayback initAudioGraph];
	
	// show the view
	[window addSubview:oneNodeViewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
