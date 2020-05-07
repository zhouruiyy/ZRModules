//
//  ZRRenderView.h
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/28.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZRRenderView : MTKView

- (instancetype)initWithFrame:(CGRect)frameRect
                       device:(id<MTLDevice>)device
                  libraryPath:(NSString *)libraryPath
                   bufferSize:(CGSize)bufferSize;

// draw call
- (void)drawPixelBuffer:(CVPixelBufferRef)pixelBuffer clearBuffer:(BOOL)clear;
- (void)drawSampleBuffer:(CMSampleBufferRef)sampleBuffer clearBuffer:(BOOL)clear;

- (void)setViewport:(MTLViewport)viewport;

- (void)renderToPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
