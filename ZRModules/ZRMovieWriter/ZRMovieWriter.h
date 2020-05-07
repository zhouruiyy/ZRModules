//
//  ZRMovieWriter.h
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZRMovieWriter : NSObject

- (instancetype)initWithFilePath:(NSString *)path fileType:(AVFileType)fileType videoSize:(CGSize)videoSize frameRate:(NSInteger)frameRate bitRate:(NSInteger)bitRate;
- (NSString *)getFilePath;
- (BOOL)canAppendPixelBuffer;
- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)generatePixelBuffer;
- (void)startWriting;
- (void)finishWriting:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
