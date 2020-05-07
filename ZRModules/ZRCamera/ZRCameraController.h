//
//  ZRCameraController.h
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZRCameraControllerDelegate <NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate>

@end

@interface ZRCameraController : NSObject

- (BOOL)setInputDevice:(AVCaptureDevice *)device;

// camera control
- (void)startCapture;
- (void)stopCapture;

// camera setting
- (void)setSessionPreset:(AVCaptureSessionPreset)preset;
- (void)setVideoDataOrientation:(AVCaptureVideoOrientation)orientation;
- (void)setVideoMirror:(BOOL)mirror;
- (void)setVideoDataOutputSettings:(NSDictionary *)settings;
- (BOOL)changeDevicePosition:(AVCaptureDevicePosition)position;

// delegate
- (void)addOutputDelegate:(id<ZRCameraControllerDelegate>)delegate;
- (void)removeOutputDelegate:(id<ZRCameraControllerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
