//
//  ZRMovieReader.m
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import "ZRMovieReader.h"

@implementation ZRMovieReader {
    
    AVAssetReader *_assetReader;
    AVAssetReaderTrackOutput *_assetReaderOutput;
    AVAssetTrack *_assetTrack;
    AVAsset *_asset;
    NSString *_videoPath;
    NSInteger _currentFrameIndex;
}

- (instancetype)initWithFilePath:(NSString *)path {
    if (self = [super init]) {
        _videoPath = path;
        [self setConfig];
    }
    return self;
}

- (BOOL)setConfig {
    _currentFrameIndex = -1;
    
    // URLWithString这个得到的url 没有file://
    _asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:_videoPath]];
    if (!_asset) {
        return NO;
    }
    
     NSError* error;
    _assetReader = [AVAssetReader assetReaderWithAsset:_asset error:&error];
    if (error) {
        NSLog(@"[ZRMovieReader Error]: %@", [error localizedDescription]);
        return false;
    }
    
    _assetTrack = [[_asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (!_assetTrack) {
        return NO;
    }
    
    _assetReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:_assetTrack outputSettings:@{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];
    if (!_assetReaderOutput) {
        return NO;
    }
    
    if ([_assetReader canAddOutput:_assetReaderOutput]) {
        [_assetReader addOutput:_assetReaderOutput];
        return YES;
    }
    
    return NO;
}

- (void)startReading {
    [_assetReader startReading];
}

- (void)stopReading {
    [_assetReader cancelReading];
}

- (NSInteger)getCurrentFrameIndex {
    return _currentFrameIndex;
}

- (CMSampleBufferRef)readSampleBuffer:(AVAssetReaderStatus *)status {
    CMSampleBufferRef sampleBuffer = [_assetReaderOutput copyNextSampleBuffer];
    if (sampleBuffer) {
        _currentFrameIndex++;
    } else {
        NSLog(@"[ZRMovieReader] read movie completed or failed.");
    }
    *status = _assetReader.status;
    
    return sampleBuffer;
}

@end
