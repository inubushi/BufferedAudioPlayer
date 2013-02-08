//
//  AudioPlayback.m
//  OneNode
//
//  Created by Aran Mulholland on 2/08/09.
//  Copyright 2009 Aran Mulholland. All rights reserved.
//

#import "AudioPlayback.h"


#pragma mark Listeners

//this listens for changes to the audio session
void sessionPropertyListener(void *                  inClientData,
				  AudioSessionPropertyID  inID,
				  UInt32                  inDataSize,
				  const void *            inData){
	
	printf("property listener\n");
	
	if (inID == kAudioSessionProperty_AudioRouteChange){
		//this will get hit if headphones, get plugged in/unplugged on the ipod/iphone
	}
	
}

//this listens to interuptions to the audio session, possible interuptions could be the phone ringing, the phone getting locked
//and im sure there is a few more
void sessionInterruptionListener(void *inClientData, UInt32 inInterruption){
	if (inInterruption == kAudioSessionBeginInterruption) {
		NSLog(@"begin interuption");
    }
	else if (inInterruption == kAudioSessionEndInterruption) {
		NSLog(@"end interuption");
	}
}


@implementation AudioPlayback
@synthesize inMemoryAudioFile;
@synthesize packetsPlayed;

#pragma mark Callbacks

static OSStatus audioOutputCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber, 
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
	
	
	//get a reference to the Objective-C class, we need this as we are outside the class
	//in just a straight C method.
	AudioPlayback *audioPlayback = (AudioPlayback *)inRefCon;
	
	//cast the buffer as an UInt32, cause our samples are in that format
	SInt16 *frameBuffer = (SInt16*)ioData->mBuffers[0].mData;
    
    // read data now
	if (inBusNumber == 0){
        //
		//loop through the buffer and fill the frames, this is really inefficient
		//should be using a memcpy, but we will leave that for later
        
         for (int j = 0; j < 2*inNumberFrames; j++){
             // get NextPacket returns a 32 bit value, one frame.
             frameBuffer[j] = [audioPlayback.inMemoryAudioFile getNextPacket];
             // Note by Chamin: if you want to process the PCM samples while loading, this is the place
         }
        
        // Note by Chamin: You can process the PCM samples here, too
        
        // increment the index
        audioPlayback->packetsPlayed += inNumberFrames;
        
        if (audioPlayback->packetsPlayed >= audioPlayback->packetCount) {
            if (!audioPlayback->SongFinished) {
                audioPlayback->SongFinished = YES;
            }
        }
    }	
	//dodgy return :)
	return 0;
}


-(void)setupAudioSession{
	
	// Initialize and configure the audio session, and add an interuption listener
    AudioSessionInitialize(NULL, NULL, sessionInterruptionListener, self);
	
	//set the audio category, depending on your app you need different categories, look them all up in the documentation 
	//by holding the option key (cursor changes to a + sign) and double clicking on the word kAudioSessionCategory_LiveAudio
	//or here http://developer.apple.com/iPhone/library/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategories/AudioSessionCategories.html
	UInt32 audioCategory = kAudioSessionCategory_LiveAudio;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	
	//make sure we set the category
	UInt32 getAudioCategory = sizeof(audioCategory);
	AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &getAudioCategory, &getAudioCategory);
	
	//print out some diagnostics. we could throw an exception here instead.
	if(getAudioCategory == kAudioSessionCategory_LiveAudio){
		NSLog(@"kAudioSessionCategory_LiveAudio");
	}
	else{
		NSLog(@"Could not get kAudioSessionCategory_LiveAudio");
	}
	
	//add a property listener, to listen to changes to the session
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, sessionPropertyListener, self);
	
	//set the buffer size, this will affect the number of samples that get rendered every time the audio callback is fired
	//a small number will get you lower latency audio, but will make your processor work harder
	Float32 preferredBufferSize = .0025;
	AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	
	//set the audio session active
	AudioSessionSetActive(YES);
}

-(void)initAudioGraph{
	
	//first of all setup the adusio session, has nothing to do with understanding the audio graph,
	//but does set the latency and the listeners.
	[self setupAudioSession];
	
	//first describe the node, graphs are made up of nodes connected together, in this graph there is only one node.
	//the descriptions for the components
	AudioComponentDescription outputDescription;
	
	//the AUNode
	AUNode outputNode;
	
	//create the graph
	OSErr err = noErr;
	err = NewAUGraph(&graph);
	//throw an exception if the graph couldn't be created.
	NSAssert(err == noErr, @"Error creating graph.");

	//describe the node, this is our output node it is of type remoteIO
	outputDescription.componentFlags = 0;
	outputDescription.componentFlagsMask = 0;
	outputDescription.componentType = kAudioUnitType_Output;
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	//add the node to the graph.
	err = AUGraphAddNode(graph, &outputDescription, &outputNode);
	//throw an exception if we couldnt add it
	NSAssert(err == noErr, @"Error creating output node.");
	
	//there are three steps, we open the graph, initialise it and start it.
	//when we open it (from the doco) the audio units belonging to the graph are open but not initialized. Specifically, no resource allocation occurs.
	err = AUGraphOpen(graph);
	NSAssert(err == noErr, @"Error opening graph.");
	
	//now that the graph is open we can get the AudioUnits that are in the nodes (or node in this case)
	//get the output AudioUnit from the graph, we supply a node and a description and the graph creates the AudioUnit which
	//we then request back from the graph, so we can set properties on it, such as its audio format
	err = AUGraphNodeInfo(graph, outputNode, &outputDescription, &outputAudioUnit);
	NSAssert(err == noErr, @"Error getting AudioUnit.");
	
	// Set up the master fader callback
	AURenderCallbackStruct playbackCallbackStruct;
	playbackCallbackStruct.inputProc = audioOutputCallback;
	//set the reference to "self" this becomes *inRefCon in the playback callback
	//as the callback is just a straight C method this is how we can pass it an objective-C class
	playbackCallbackStruct.inputProcRefCon = self;
	
	//now set the callback on the output node, this callback gets called whenever the AUGraph needs samples
	err = AUGraphSetNodeInputCallback(graph, outputNode, 0, &playbackCallbackStruct);
	NSAssert(err == noErr, @"Error setting effects callback.");
	
	
	//so far we have not set any property descriptions on the outputAudioUnit, these describe the format of the audio being played
	
	//first of all lets see what format it is by default
	NSLog(@"No AudioStreamBasicDescription has been set.");
	
	AudioStreamBasicDescription audioStreamBasicDescription;
	UInt32 audioStreamBasicDescriptionsize = sizeof (AudioStreamBasicDescription);
	
	//get the description of the format from the audio unit, this will describe what format we are sending the AudioUnit (from our callback)
	AudioUnitGetProperty(outputAudioUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0, // input bus
						 &audioStreamBasicDescription,
						 &audioStreamBasicDescriptionsize);
	NSLog (@"Output Audio Unit: User input AudioStreamBasicDescription\n Sample Rate: %f\n Channels: %ld\n Bits Per Channel: %ld",
		   audioStreamBasicDescription.mSampleRate, audioStreamBasicDescription.mChannelsPerFrame,
		   audioStreamBasicDescription.mBitsPerChannel);
	
	//lets actually set the audio format
	AudioStreamBasicDescription audioFormat;
	
	// Describe format
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 4;
	audioFormat.mBytesPerFrame		= 4;
	
	//IMPORTANT: --- the audio unit will play without the setting of the format, it seems to default to 44100khz, 16 bit, stereo, interleaved pcm
	//but who can tell if this will always be the case?
	
	//set the outputAudioUnit input properties
	err = AudioUnitSetProperty(outputAudioUnit, 
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(err == noErr, @"Error setting RIO input property.");
	
	//now lets check the format again
	NSLog(@"AudioStreamBasicDescription has been set, notice you now see the sample rate.");
	
	//get the description of the format from the audio unit, this will describe what format we are sending the AudioUnit (from our callback)
	AudioUnitGetProperty(outputAudioUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0, // input bus
						 &audioStreamBasicDescription,
						 &audioStreamBasicDescriptionsize);
	NSLog (@"Output Audio Unit: User input AudioStreamBasicDescription\n Sample Rate: %f\n Channels: %ld\n Bits Per Channel: %ld",
		   audioStreamBasicDescription.mSampleRate, audioStreamBasicDescription.mChannelsPerFrame,
		   audioStreamBasicDescription.mBitsPerChannel);
	
	
	//we then initiailze the graph, this (from the doco):
	//Calling this function calls the AudioUnitInitialize function on each opened node or audio unit that is involved in a interaction. 
	//If a node is not involved, it is initialized after it becomes involved in an interaction.
	err = AUGraphInitialize(graph);
	NSAssert(err == noErr, @"Error initializing graph.");
	
	//this prints out a description of the graph, showing the nodes and connections, really handy.
	//this shows in the console (Command-Shift-R to see it)
	CAShow(graph); 
	
	//the final step, as soon as this is run, the graph will start requesting samples. some people would put this on the play button
	//but ive found that sometimes i get a bit of a pause so i let the callback get called from the start and only start filling the buffer
	//with samples when the play button is hit.
	//the doco says :
	//this function starts rendering by starting the head node of an audio processing graph. The graph must be initialized before it can be started.
	err = AUGraphStart(graph);
	NSAssert(err == noErr, @"Error starting graph.");
    
}

-(void)loadFile:(NSString *)filePath {
    // call the function in child
    [inMemoryAudioFile openExt:filePath];
    // record the number of packets
    packetCount = inMemoryAudioFile->packetCount;
    NSLog(@"%ld packets", packetCount);
    // we are at the beginning of the song
    packetsPlayed = 0;
    isSongLoaded = YES;
    SongFinished = NO;
}

-(void)playOrPause {
    // won't work when a file has finished playing
    if (!SongFinished) {
        if (!isPlaying)
        {
            isPlaying = YES;
            AUGraphStart(graph);
        }
        else
        {
            isPlaying = NO;
            AUGraphStop(graph);
        }
        [inMemoryAudioFile play];
    }
}

- (void)dealloc {
	[inMemoryAudioFile release];
	//i am not sure if all of these steps are neccessary. or if you just call DisposeAUGraph
	AUGraphStop(graph);
	AUGraphUninitialize(graph);
	AUGraphClose (graph);
	DisposeAUGraph(graph);
    [super dealloc];
}

@end
