//
//  InMemoryAudioFile.h
//  
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk)
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AudioToolbox.h>
#include <sys/time.h>

// circular buffer
#import "TPCircularBuffer.h"

#define kBufferLength   8388608 //16777216  // use a multiple of 32768, for better use of virtual memory
                                //set it lower if you need to preserve memory for other stuff, or higher if you are fine with more data
                                // Note: tune this number if you hear glitches during playback

@interface InMemoryAudioFile : NSObject {
    @public
	AudioStreamBasicDescription		mDataFormat;
    AudioFileID						mAudioFile;                     
    UInt32							bufferByteSize;                 
    SInt64							mCurrentPacket;                 
    UInt32							mNumPacketsToRead;              
    AudioStreamPacketDescription	*mPacketDescs;                  
	SInt64							packetCount;
	SInt16							*audioData;
	SInt64							packetIndex;
	SInt64							leftPacketIndex;
	SInt64							rightPacketIndex;
	
    // Note that I haven't used some of these properties
	SInt16							*leftAudioData;
	SInt16							*rightAudioData;
	
	float							*monoFloatDataLeft;
	float							*monoFloatDataRight;

	Boolean		isPlaying;
    
    // additional variables for buffered input
    TPCircularBuffer circularBuffer;
    SInt64                          indexToBuffer;
    BOOL isReadyToRead;
    // additional memory space for reading in thread
    SInt16							*tempData;
    
    // for extended audio file services
    ExtAudioFileRef fileRef;
    AudioBufferList bufList;
    NSString *songPath;
}

//opens a wav file
-(OSStatus)open:(NSString *)filePath;
// opens any file with extended audio file servies
-(OSStatus)openExt:(NSString *)filePath;

//open the file to read data from a given location - for buffering
-(OSStatus)readToBufferFrom:(int) sampleIndex;
// same function with threading
-(void)readToBufferFromFile;
// same, uing extended audio file services
-(void)readToBufferFromFileExt;

//gets the info about a wav file, stores it locally
-(OSStatus)getFileInfo;

//gets the next packet from the buffer, returns -1 if we have reached the end of the buffer
-(UInt32)getNextPacket;

//gets the current index (where in the buffer are we now?)
-(SInt64)getIndex;

//reset the index to the start of the file
-(void)reset;

// play the file
-(void)play;


@end
