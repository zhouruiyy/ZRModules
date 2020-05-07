//
//  ZRCameraController.m
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import "ZRCameraController.h"

@interface ZRCameraController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *currentDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, assign) BOOL isMirrored;

@property (nonatomic, strong) dispatch_queue_t opQueue;
@property (nonatomic, strong) NSMutableArray<id<ZRCameraControllerDelegate>> *delegates;

@end

@implementation ZRCameraController

- (instancetype)init {
    if (self = [super init]) {
        [self setupSession:AVCaptureSessionPreset1280x720];
        [self changeDevicePosition:AVCaptureDevicePositionBack];
        _delegates = [@[] mutableCopy];
    }
    return self;
}

- (dispatch_queue_t)opQueue {
    if (_opQueue == nil) {
        _opQueue = dispatch_queue_create("com.ZRModules.camera.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _opQueue;
}

#pragma mark - setting
- (void)setupSession:(AVCaptureSessionPreset)preset {
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = preset;
}

- (void)resetConnectionConfig {
    if ([[self.videoDataOutput connections] count] > 0) {
        AVCaptureConnection *connection = [self.videoDataOutput.connections firstObject];
        connection.videoOrientation = self.videoOrientation;
        connection.videoMirrored = self.isMirrored;
    }
}

- (BOOL)setInputDevice:(AVCaptureDevice *)device {
    if (self.currentDevice == device) {
        return YES;
    }
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"[ZRCameraController %s error]:%@", __func__, [error localizedDescription]);
        return NO;
    }
    [self.session beginConfiguration];
    [self.session removeInput:self.deviceInput];
    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
        self.deviceInput = deviceInput;
        self.currentDevice = device;
        [self resetConnectionConfig];
        [self.session commitConfiguration];
        return YES;
    } else {
        [self.session addInput:self.deviceInput];
        [self resetConnectionConfig];
        [self.session commitConfiguration];
        return NO;
    }
}

- (void)setVideoDataOutputSettings:(NSDictionary *)settings {
    [self.session beginConfiguration];
    if (self.videoDataOutput) {
        [self.session removeOutput:self.videoDataOutput];
        self.videoDataOutput = nil;
    }
    AVCaptureVideoDataOutput* videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutput setSampleBufferDelegate:self queue:self.opQueue];
    videoDataOutput.videoSettings = settings;
    if ([self.session canAddOutput:videoDataOutput]) {
        [self.session addOutput:videoDataOutput];
        self.videoDataOutput = videoDataOutput;
    }
    [self resetConnectionConfig];
    [self.session commitConfiguration];
}

- (BOOL)changeDevicePosition:(AVCaptureDevicePosition)position {
    if (@available(iOS 10.0, *)) {
        [self.session beginConfiguration];
        AVCaptureDevice *device = [[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position].devices firstObject];
        AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        [self.session removeInput:self.deviceInput];
        if ([self.session canAddInput:deviceInput]) {
            self.currentDevice = device;
            self.deviceInput = deviceInput;
            [self.session addInput:self.deviceInput];
            [self resetConnectionConfig];
            [self.session commitConfiguration];
            return YES;
        } else {
            [self.session addInput:self.deviceInput];
            [self resetConnectionConfig];
            [self.session commitConfiguration];
            return NO;
        }
    } else {
        return NO;
    }
}

#pragma mark - delegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @synchronized (self.delegates) {
        for (id<ZRCameraControllerDelegate> delegate in self.delegates) {
            [delegate captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}

- (void)addOutputDelegate:(id<ZRCameraControllerDelegate>)delegate {
    @synchronized (self.delegates) {
        if (![self.delegates containsObject:delegate]) {
            [self.delegates addObject:delegate];
        }
    }
}

- (void)removeOutputDelegate:(id<ZRCameraControllerDelegate>)delegate {
    @synchronized (self.delegates) {
        if ([self.delegates containsObject:delegate]) {
            [self.delegates removeObject:delegate];
        }
    }
}

#pragma mark - public

- (void)setSessionPreset:(AVCaptureSessionPreset)preset {
    [self.session beginConfiguration];
    self.session.sessionPreset = preset;
    
    [self.session commitConfiguration];
}

- (void)setVideoDataOrientation:(AVCaptureVideoOrientation)orientation {
    if (self.videoOrientation != orientation) {
        self.videoOrientation = orientation;
        [self resetConnectionConfig];
    }
}

- (void)setVideoMirror:(BOOL)mirror {
    if (self.isMirrored != mirror) {
        self.isMirrored = mirror;
        [self resetConnectionConfig];
    }
}

- (void)startCapture {
    [self.session startRunning];
}

- (void)stopCapture {
    [self.session stopRunning];
}

@end
