//
//  InMemoryAudioFile.h
//
//  By Chamin Morikawa (chamin@icloud.com, http://yubi-apps.tk )
//
//  Based on the application "OneNode" by Aran Mulholland
//  Original code available at https://sites.google.com/site/iphonecoreaudiodevelopment/one-node
//  Created by Aran Mulholland on 22/02/09.
//  Copyright 2013 Chamin Morikawa, 2009 Aran Mulholland. All rights reserved.
//


#import "InMemoryAudioFile.h"


@implementation InMemoryAudioFile

//overide init method
- (id)init 
{ 
    
	//set the index
	packetIndex = 0;
	leftPacketIndex = 0;
	rightPacketIndex = 0;
	isPlaying = NO;
    
	return self;
}

- (void)dealloc {
	//release the AudioBuffer
	free(audioData);
    [super dealloc];
}

-(void)play{
	if(isPlaying){
		isPlaying = NO;
	}
	else{
		isPlaying = YES;
	}
}

//open and read a wav file to the buffer - for larger files, only a portion will be read
-(OSStatus)open:(NSString *)filePath{
 
     //print out the file path
     //NSLog(@"FilePath: %@", filePath);
 
     //get a ref to the audio file, need one to open it
     CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)[filePath cStringUsingEncoding:[NSString defaultCStringEncoding]] , strlen([filePath cStringUsingEncoding:[NSString defaultCStringEncoding]]), false);
 
     //open the audio file
     OSStatus result = AudioFileOpenURL (audioFileURL, 0x01, 0, &mAudioFile);
    
     //were there any errors reading? if so deal with them first
     if (result != noErr) {
         NSLog(@"Could not open file: %@", filePath);
         packetCount = -1;
     }
     //otherwise
     else{
         //get the file info
         [self getFileInfo];
         //how many packets read? (packets are the number of stereo samples in this case)
         NSLog(@"File Opened, packet Count: %lld", packetCount);
 
         //UInt32 packetsRead = packetCount;
         UInt32 packetsRead = kBufferLength/4;
         OSStatus result = -1;
 
         //free the audioBuffer just in case it contains some data
         free(audioData);
         UInt32 numBytesRead = -1;
         //if we didn't get any packets dop nothing, nothing to read
         if (packetCount <= 0) { }
         //otherwise fill our in memory audio buffer with the whole file (i wouldnt use this with very large files btw)
         else{
             //allocate the buffer
             audioData = (SInt16 *)malloc(sizeof(SInt16) * packetsRead* 2);
             // allocate buffer now for use in thread
             tempData = (SInt16 *)malloc(sizeof(SInt16) * (kBufferLength/8)* 2);
             //read the packets
             result = AudioFileReadPackets (mAudioFile, false, &numBytesRead, NULL, 0, &packetsRead,  audioData);
         }
         
         if (result==noErr){
             //print out general info about  the file
             //NSLog(@"Packets read from file: %ld\n", packetsRead);
             //NSLog(@"Bytes read from file: %ld\n", numBytesRead);
             //for a stereo 32 bit per sample file this is ok
             //NSLog(@"Sample count: %ld\n", numBytesRead/2);
             
             //for a 32bit per stereo sample at 44100khz this is correct
             //NSLog([NSString stringWithFormat:@"Time in Seconds: %f.4\n", ((float)numBytesRead / 4.0) / 44100.0]);
             
             // set the index
             indexToBuffer = numBytesRead;
             
             // put the data in buffer
             TPCircularBufferInit(&circularBuffer, kBufferLength);
             TPCircularBufferProduceBytes(&circularBuffer, audioData, kBufferLength);
             
             // initialize flag for threading
             isReadyToRead = YES;
         }
     }

    // cleaning up
    CFRelease (audioFileURL);
 
    // we are done.
    return result;
 }

//open and read any audio file to the buffer - for larger files, only a portion will be read
-(OSStatus)openExt:(NSString *)filePath{
    
    //print out the file path
    //NSLog(@"FilePath: %@", filePath);
    
    songPath = [NSString stringWithString:filePath];
    
    //get a ref to the audio file, need one to open it
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation (NULL, (const UInt8 *)[filePath cStringUsingEncoding:[NSString defaultCStringEncoding]] , strlen([filePath cStringUsingEncoding:[NSString defaultCStringEncoding]]), false);
    
    OSStatus status;
    //ExtAudioFileRef fileRef;
    
    CFURLRef fileURL = (CFURLRef)[NSURL fileURLWithPath:filePath];
    status = ExtAudioFileOpenURL((CFURLRef)fileURL, &fileRef);
    
    //were there any errors reading? if so deal with them first
    if (status != noErr) {
        NSLog(@"Could not open file: %@", filePath);
    }
    else{
        AudioStreamBasicDescription dataFormat;
        dataFormat.mSampleRate = 44100;
        dataFormat.mFormatID = kAudioFormatLinearPCM;
        dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        dataFormat.mFramesPerPacket = 1;
        dataFormat.mChannelsPerFrame = 2; // used to be 1
        dataFormat.mBitsPerChannel = 16; // used to be 16
        dataFormat.mBytesPerPacket = 4; // used to be 2
        dataFormat.mBytesPerFrame = 4; // used to be 2
        
        UInt32 propDataSize;
        
        AudioStreamBasicDescription originalDataFormat;
        propDataSize = (UInt32)sizeof(originalDataFormat);
        status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileDataFormat, &propDataSize, &originalDataFormat);
        
        SInt64 numPackets;
        propDataSize = sizeof(numPackets);
        status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileLengthFrames, &propDataSize, &numPackets);
        
        propDataSize = (UInt32)sizeof(dataFormat);
        status = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, propDataSize, &dataFormat);
        
        numPackets = (SInt64)numPackets / (SInt64)(originalDataFormat.mSampleRate / 44100); // actual no. of packets
        // store this first
        packetCount = numPackets;
        // now read only just enough to fill the buffer
        numPackets = kBufferLength/4;
        
        size_t bufferSize = (size_t)(numPackets * sizeof(SInt16)*2);
        audioData = (SInt16 *)malloc(kBufferLength);
        // allocate buffer now for use in thread
        tempData = (SInt16 *)malloc(sizeof(SInt16) * (kBufferLength/8)* 2);
        
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = 2;
        bufList.mBuffers[0].mDataByteSize = bufferSize;
        bufList.mBuffers[0].mData = audioData;
        
        ExtAudioFileSeek(fileRef, 0);
        UInt32 totalFramesRead = 0;
        do {
            UInt32 framesRead = numPackets - totalFramesRead;
            bufList.mBuffers[0].mData = audioData + (totalFramesRead * (sizeof(SInt16)));
            ExtAudioFileRead(fileRef, &framesRead, &bufList);
            totalFramesRead += framesRead;
            if(framesRead == 0) {
                break;
            }
            NSLog(@"read %lu frames\n", framesRead);
        } while (totalFramesRead < numPackets);
        
        int totalPackets = totalFramesRead;
        //status = ExtAudioFileDispose(fileRef);
        
        NSLog(@"numPackets : %lld, totalPackets : %d", numPackets, totalPackets);
        
        // put the data in buffer
        TPCircularBufferInit(&circularBuffer, kBufferLength);
        TPCircularBufferProduceBytes(&circularBuffer, audioData, kBufferLength);
        
        // set the index
        indexToBuffer = kBufferLength;
        
        // flag for threading
        isReadyToRead = YES;
        
    }
    
    //open the audio file
    OSStatus result = AudioFileOpenURL (audioFileURL, 0x01, 0, &mAudioFile);
    
    //were there any errors reading? if so deal with them first
    if (result != noErr) {
        NSLog(@"Could not open file: %@", filePath);
        packetCount = -1;
    }
    //otherwise
    else{
        //get the file info
        //[self getFileInfo];
        //how many packets read? (packets are the number of stereo samples in this case)
        //NSLog(@"File Opened, packet Count: %lld", packetCount);
        
        //UInt32 packetsRead = packetCount;
        //UInt32 packetsRead = kBufferLength/4;
        //OSStatus result = -1;
        
        //free the audioBuffer just in case it contains some data
        //free(audioData);
        //UInt32 numBytesRead = -1;
        //if we didn't get any packets dop nothing, nothing to read
        //if (packetCount <= 0) { }
        //otherwise fill our in memory audio buffer with the whole file (i wouldnt use this with very large files btw)
        //else{
            //allocate the buffer
            //audioData = (SInt16 *)malloc(sizeof(SInt16) * packetsRead* 2);
            // allocate buffer now for use in thread
            //tempData = (SInt16 *)malloc(sizeof(SInt16) * (kBufferLength/8)* 2);
            //read the packets
            //result = AudioFileReadPackets (mAudioFile, false, &numBytesRead, NULL, 0, &packetsRead,  audioData);
        //}
        
        //if (result==noErr){
            //print out general info about  the file
            //NSLog(@"Packets read from file: %ld\n", packetsRead);
            //NSLog(@"Bytes read from file: %ld\n", numBytesRead);
            //for a stereo 32 bit per sample file this is ok
            //NSLog(@"Sample count: %ld\n", numBytesRead/2);
            
            //for a 32bit per stereo sample at 44100khz this is correct
            //NSLog([NSString stringWithFormat:@"Time in Seconds: %f.4\n", ((float)numBytesRead / 4.0) / 44100.0]);
            
            // set the index
            //indexToBuffer = numBytesRead;
            
            // put the data in buffer
            //TPCircularBufferInit(&circularBuffer, kBufferLength);
            //TPCircularBufferProduceBytes(&circularBuffer, audioData, kBufferLength);
            
            // initialize flag for threading
            //isReadyToRead = YES;
        //}
    }
    
    // cleaning up
    CFRelease (audioFileURL);
    
    // we are done.
    return result;
}

// read data from a given point in the file
-(OSStatus)readToBufferFrom:(int)sampleIndex{
    // read only a limited no. of packets
    
    //NSLog(@"Reading from %d", sampleIndex);
    UInt32 packetsRead = kBufferLength/8;
    OSStatus result = -1;
    UInt32 numBytesRead = -1;
    
    //read only if we have enough to read
    if (packetCount*4 - sampleIndex <= 0) { }
    else
    {
        // now reading data - a packet is 4 bytes
        result = AudioFileReadPackets(mAudioFile, false, &numBytesRead, NULL, sampleIndex/4, &packetsRead, tempData);

        //print some details, for debugging
        NSLog(@"Packets read from file: %ld\n", packetsRead);
        NSLog(@"Bytes read from file: %ld\n", numBytesRead);
    }
    
    // put the data in buffer
    TPCircularBufferProduceBytes(&circularBuffer, tempData, numBytesRead);
    
    // now we dont need the buffer
    //free(tempData);
    
    // set the index
    indexToBuffer += numBytesRead;
    
    // reset the flag again
    isReadyToRead = YES;
    
    // playable now
    isPlaying = YES;
    
    // we are done
	return result;
}

//Reading from the file, via thread
-(void)readToBufferFromFile{
    // read only a limited no. of packets
    //NSLog(@"Reading from %lld", indexToBuffer);
    UInt32 packetsRead = kBufferLength/8;
    OSStatus result = -1;
        
    UInt32 numBytesRead = -1;
    //if we didn't get any packets do nothing, nothing to read
    if (packetCount*4 - indexToBuffer <= 0) { }
    //otherwise fill our in memory audio buffer with the whole file (i wouldnt use this with very large files btw)
    else
    {
        // now reading only part of it - a packet is 4 bytes
        result = AudioFileReadPackets(mAudioFile, false, &numBytesRead, NULL, indexToBuffer/4, &packetsRead, tempData);
        
        //print out general info about  the file
        //NSLog(@"Packets read from file: %ld\n", packetsRead);
        //NSLog(@"Bytes read from file: %ld\n", numBytesRead);
        //for a stereo 32 bit per sample file this is ok
        //NSLog([NSString stringWithFormat:@"Sample count: %d\n", numBytesRead / 2]);
        //for a 32bit per stereo sample at 44100khz this is correct
        //NSLog([NSString stringWithFormat:@"Time in Seconds: %f.4\n", ((float)numBytesRead / 4.0) / 44100.0]);
    }
    
    // put the data in buffer
    TPCircularBufferProduceBytes(&circularBuffer, tempData, numBytesRead);
    
    // now we dont need the buffer
    //free(tempData);
    
    // set the index
    indexToBuffer += numBytesRead;
    
    // reset the flag again
    isReadyToRead = YES;
    
    // playable now
    isPlaying = YES;
    
    // finishing thread
    //[pool release];
}

//Reading from the file, via thread - now using extended file services
-(void)readToBufferFromFileExt{
    // read only a limited no. of packets
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
    // testing
    NSLog(@"Reading from %lld", indexToBuffer);
    UInt32 packetsRead = kBufferLength/32;

    //if we didn't get any packets do nothing, nothing to read
    if (packetCount*4 - indexToBuffer <= 0) { }
    //otherwise fill our in memory audio buffer with the whole file (i wouldnt use this with very large files btw)
    else
    {
        OSStatus result = -1;
        result = ExtAudioFileRead(fileRef, &packetsRead, &bufList);
                
        //print out general info about  the file
        //NSLog(@"Packets read from file: %ld\n", packetsRead);
        //NSLog(@"Bytes read from file: %ld\n", numBytesRead);
        //for a stereo 32 bit per sample file this is ok
        //NSLog([NSString stringWithFormat:@"Sample count: %d\n", numBytesRead / 2]);
        //for a 32bit per stereo sample at 44100khz this is correct
        //NSLog([NSString stringWithFormat:@"Time in Seconds: %f.4\n", ((float)numBytesRead / 4.0) / 44100.0]);
    }
    
    // put the data in buffer
    TPCircularBufferProduceBytes(&circularBuffer, audioData, packetsRead*4);
    
    // now we dont need the buffer
    //free(tempData);
    
    // set the index
    indexToBuffer += packetsRead*4;
    
    // reset the flag again
    isReadyToRead = YES;
    
    // playable now
    isPlaying = YES;
    
}



- (OSStatus) getFileInfo {
	
	OSStatus	result = -1;
	double duration;
	
	if (mAudioFile == nil){}
	else{
		UInt32 dataSize = sizeof packetCount;
		result = AudioFileGetProperty(mAudioFile, kAudioFilePropertyAudioDataPacketCount, &dataSize, &packetCount);
		if (result==noErr) {
			duration = ((double)packetCount * 2) / 44100;
		}
		else{
			packetCount = -1;
		}
	}
	return result;
}


//gets the next packet from the buffer, if we have reached the end of the buffer return 0
-(UInt32)getNextPacket{
	
	SInt16 returnValue = 0;
    //NSLog(@"Read %lld of %lld", packetIndex, packetCount);
	
	//if the packetCount has gone to the end of the file, reset it. Audio will loop.
	//if (packetIndex >= packetCount){
    if (packetIndex >= packetCount*2){
        // stop playing
        isPlaying = NO;
        isReadyToRead = NO;
        
        
        // reset index - old code
        packetIndex = 0;
        indexToBuffer =0;
        
        NSLog(@"End of Song");
        // To do: modify here if you want to loop the song
        return 0;
       
	}
    else
    {
        //i always like to set a variable and then return it during development so i can
        //see the value while debugging
        if(isPlaying){
            int32_t availableBytes;
            SInt16 *buffer = TPCircularBufferTail(&circularBuffer, &availableBytes);
            if (availableBytes % 1000 == 0) {
                 //NSLog(@"Available bytes: %d", availableBytes);
            }
            if (availableBytes < 3*kBufferLength/4 && isReadyToRead && indexToBuffer < packetCount*4) {
                NSLog(@"Available Bytes not enough: %d", availableBytes);
                isReadyToRead = NO;
                //isPlaying = NO;
                // later use a thread
                //[self readToBufferFrom:indexToBuffer];
                [NSThread detachNewThreadSelector:@selector(readToBufferFromFileExt) toTarget:self withObject:nil];
            }
            SInt16 *temp = malloc(sizeof(SInt16));
            memcpy(temp, buffer, 2);
            TPCircularBufferConsume(&circularBuffer, 2);
            returnValue = *temp; //audioData[packetIndex++];
            packetIndex++;
            free(temp);
            return returnValue;
        }
        else{
            return 0;
        }

    }	
	
}

//gets the current index (where we are up to in the buffer)
-(SInt64)getIndex{
	return packetIndex;
}

-(void)reset{
	packetIndex = 0;
}

@end
