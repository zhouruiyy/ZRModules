//
//  ZRMovieWriter.m
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import "ZRMovieWriter.h"

@implementation ZRMovieWriter {
    
    NSString *_filePath;
    CGSize _videoSize;
    NSInteger _frameRate;
    NSInteger _bitRate;
    
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWtiterInput;
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    AVFileType _fileType;
    
    NSInteger _frameCount;
    CMTime _pTime;
}

- (instancetype)initWithFilePath:(NSString *)path fileType:(AVFileType)fileType videoSize:(CGSize)videoSize frameRate:(NSInteger)frameRate bitRate:(NSInteger)bitRate {
    if (self = [super init]) {
        _filePath = path;
        _fileType = fileType;
        _videoSize = videoSize;
        _frameRate = frameRate;
        _bitRate = bitRate;
        [self setupAssetWriter];
    }
    
    return self;
}

- (void)setupAssetWriter {
    NSError *error;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:_filePath] fileType:_fileType error:&error];
    if (error) {
        NSLog(@"[ZRMovieWriter setupAssetWriter Error] %@", [error localizedDescription]);
        abort();
    }
    
    if (@available(iOS 11.0, *)) {
        NSDictionary *videoSettings = @{
            AVVideoCompressionPropertiesKey: @{AVVideoAverageBitRateKey: @(_bitRate)},
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @(_videoSize.width),
            AVVideoHeightKey: @(_videoSize.height)
        };
        _assetWtiterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    } else {
        NSDictionary *videoSettings = @{
                AVVideoCompressionPropertiesKey: @{AVVideoAverageBitRateKey: @(_bitRate)},
                AVVideoWidthKey: @(_videoSize.width),
                AVVideoHeightKey: @(_videoSize.height)
            };
        _assetWtiterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    }
    
    if ([_assetWriter canAddInput:_assetWtiterInput]) {
        [_assetWriter addInput:_assetWtiterInput];
    }
    
    NSDictionary *pixelBufferAdaptorSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferWidthKey: @(_videoSize.width),
        (id)kCVPixelBufferHeightKey: @(_videoSize.height),
    };
    _pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_assetWtiterInput sourcePixelBufferAttributes:pixelBufferAdaptorSettings];
}

- (NSString *)getFilePath {
    return _filePath;
}

- (BOOL)canAppendPixelBuffer {
    return _assetWtiterInput.isReadyForMoreMediaData;
}

- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (![self canAppendPixelBuffer]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    @try {
        [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:_pTime];
        _pTime = CMTimeAdd(_pTime, CMTimeMake(120 / _frameRate, 120));
        _frameCount++;
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[ZRMovieWriter Error]: %@", [exception description]);
        return NO;
    }
}

- (CVPixelBufferRef)generatePixelBuffer {
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferAdaptor.pixelBufferPool, &pixelBuffer);
    return pixelBuffer;
}

- (void)startWriting {
    [_assetWriter startWriting];
    _pTime = CMTimeMake(0, 120);
    [_assetWriter startSessionAtSourceTime:_pTime];
    _frameCount = 0;
}

- (void)finishWriting:(dispatch_block_t)completion {
    [_assetWriter finishWritingWithCompletionHandler:^{
        NSLog(@"[ZRMovieWriter]: finish writing. Total frame count: %ld", (long)self->_frameCount);
        if (completion) {
            completion();
        }
    }];
}

@end
