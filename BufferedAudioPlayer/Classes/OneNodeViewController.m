//
//  <filename>
//
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk )
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//
//  circular buffer implementation by Michael Tyson ( https://github.com/michaeltyson/TPCircularBuffer )

#import "OneNodeViewController.h"

@implementation OneNodeViewController
@synthesize audioPlayback;

-(IBAction)play{
		
	//[audioPlayback.inMemoryAudioFile play];
    [audioPlayback playOrPause];
}
/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[audioPlayback release];
    [super dealloc];
}

@end
