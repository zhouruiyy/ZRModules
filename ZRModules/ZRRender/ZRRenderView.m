//
//  ZRRenderView.m
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/28.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import "ZRRenderView.h"
#import "ShaderType.h"

@interface ZRRenderView ()

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) int numVertices;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPass;
@property (nonatomic, assign) MTLViewport viewPort;
// 渲染texture到MTKView
@property (strong, nonatomic) id<MTLRenderPipelineState> screenRenderPipelineState;

@property (assign, nonatomic) CVMetalTextureCacheRef textureCache;

@end

@implementation ZRRenderView

- (instancetype)initWithFrame:(CGRect)frameRect
                       device:(id<MTLDevice>)device
                  libraryPath:(NSString *)libraryPath
                   bufferSize:(CGSize)bufferSize {
    if (@available(iOS 10, *)) {
        self = [super initWithFrame:frameRect device:device];
        if (self) {
            _commandQueue = [self.device newCommandQueue];
            if (libraryPath) {
                NSError *error;
                _library = [self.device newLibraryWithFile:libraryPath error:&error];
                if (error) {
                    NSLog(@"[ZRRenderView init][Error]: create metal library with input path failed!");
                    return nil;
                }
            } else {
                NSError *error;
                NSBundle *frameworkBundle = [NSBundle bundleForClass:[self class]];
                _library = [self.device newDefaultLibraryWithBundle:frameworkBundle error:&error];
                if (error) {
                    NSLog(@"[ZRRenderView init error]: create metal library with input path failed!");
                    return nil;
                }
            }
            
            CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.device, NULL, &_textureCache);
            if (self.textureCache == nil) {
                NSLog(@"[ZRRenderView init error]: failed to create texture cache!");
                return nil;
            }
            // setup pipeline
            [self setupScreenRenderPipeline:bufferSize];
            [self setupVertex];
        }
        
        return self;
    } else {
        return nil;
    }
}

#pragma mark - private

- (void)setupScreenRenderPipeline:(CGSize)size {
    MTLTextureDescriptor *textureDes = [[MTLTextureDescriptor alloc] init];
    textureDes.width = size.width;
    textureDes.height = size.height;
    textureDes.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDes.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    self.texture = [self.device newTextureWithDescriptor:textureDes];
    
    MTLViewport viewPort = {0, 0, textureDes.width, textureDes.height, 0, 1};
    self.viewPort = viewPort;
    
    id<MTLFunction> vertexFunc = [self.library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunc = [self.library newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDes.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    pipelineDes.vertexFunction = vertexFunc;
    pipelineDes.fragmentFunction = fragmentFunc;
    
    NSError *error;
    self.screenRenderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDes error:&error];
    if (error) {
        NSLog(@"[ZRRenderView error]:%@", error.localizedDescription);
        abort();
    }
}

- (void)setupVertex {
    static const Vertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    self.vertices = [self.device newBufferWithBytes:quadVertices
                                                     length:sizeof(quadVertices)
                                                    options:MTLResourceStorageModeShared]; // 创建顶点缓存
    self.numVertices = sizeof(quadVertices) / sizeof(Vertex); // 顶点个数
}


#pragma mark - draw

//- (void)drawRect:(CGRect)rect {
//    if (self.currentDrawable == nil) {
//        return;
//    }
//    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
//    MTLRenderPassDescriptor *renderPassDesc = self.currentRenderPassDescriptor;
//    if (renderPassDesc) {
//        id<MTLRenderCommandEncoder> renderCmdEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
//        [renderCmdEncoder setRenderPipelineState:self.screenRenderPipelineState];
//        [renderCmdEncoder setViewport:self.viewPort];
//        [renderCmdEncoder setVertexBuffer:self.vertices offset:0 atIndex:0];
//        [renderCmdEncoder setFragmentTexture:self.texture atIndex:0];
//        [renderCmdEncoder setFragmentTexture:self.texture atIndex:1];
//        int textureType = 0;
//        [renderCmdEncoder setFragmentBytes:&textureType length:sizeof(int) atIndex:0];
//        [renderCmdEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.numVertices];
//        [renderCmdEncoder endEncoding];
//        [commandBuffer presentDrawable:self.currentDrawable];
//    }
//    [commandBuffer commit];
////    [commandBuffer waitUntilCompleted];
//}

// draw call
- (void)drawPixelBuffer:(CVPixelBufferRef)pixelBuffer clearBuffer:(BOOL)clear {
    self.renderPass = self.currentRenderPassDescriptor;
    if (clear) {
        self.renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    } else {
        self.renderPass.colorAttachments[0].loadAction = MTLLoadActionLoad;
    }
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    self.drawableSize = CGSizeMake(width, height);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    if (self.renderPass) {
        id<MTLRenderCommandEncoder> renderCmdEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:self.renderPass];
        [renderCmdEncoder setRenderPipelineState:self.screenRenderPipelineState];
        [renderCmdEncoder setViewport:self.viewPort];
        [renderCmdEncoder setVertexBuffer:self.vertices offset:0 atIndex:0];

        if(CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA) {
            id<MTLTexture> texture = [self textureFromPixelBuffer:pixelBuffer];
            [renderCmdEncoder setFragmentTexture:texture atIndex:0];
            [renderCmdEncoder setFragmentTexture:texture atIndex:1];
            int textureType = 0;
            [renderCmdEncoder setFragmentBytes:&textureType length:sizeof(int) atIndex:0];
        } else {
            NSArray* textures = [self texturesFromYUVPixelBuffer:pixelBuffer];
            [renderCmdEncoder setFragmentTexture:textures[0] atIndex:0];
            [renderCmdEncoder setFragmentTexture:textures[1] atIndex:1];
            int textureType = 1;
            [renderCmdEncoder setFragmentBytes:&textureType length:sizeof(int) atIndex:0];
        }
        
        [renderCmdEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.numVertices];
        [renderCmdEncoder endEncoding];
        [commandBuffer presentDrawable:self.currentDrawable];
    }
    [commandBuffer commit];
}

- (void)drawSampleBuffer:(CMSampleBufferRef)sampleBuffer clearBuffer:(BOOL)clear {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self drawPixelBuffer:pixelBuffer clearBuffer:clear];
}

- (void)setViewport:(MTLViewport)viewport {
    self.viewPort = viewport;
}

- (void)renderToScreen {
    [self setNeedsDisplay];
}

- (id<MTLTexture>)textureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVMetalTextureRef textureRef;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &textureRef);
    if (textureRef != nil) {
        id<MTLTexture> texture = CVMetalTextureGetTexture(textureRef);
        CFRelease(textureRef);
        return texture;
    } else {
        MTLTextureDescriptor *textureDesc = [[MTLTextureDescriptor alloc] init];
        textureDesc.width = width;
        textureDesc.height = height;
        textureDesc.pixelFormat = MTLPixelFormatBGRA8Unorm;
        id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDesc];
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        unsigned char *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        MTLRegion region = {{0, 0, 0}, {width, height, 1}};
        [texture replaceRegion:region mipmapLevel:0 withBytes:baseAddress bytesPerRow:CVPixelBufferGetBytesPerRow(pixelBuffer)];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return texture;
    }
}

- (NSArray<id<MTLTexture>> *)texturesFromYUVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    int yWidth = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    int yHeight = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    int uvWidth = (int)CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    int uvHeight = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    
    CVMetalTextureRef yTextureRef, uvTextureRef;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              self.textureCache,
                                              pixelBuffer, nil,
                                              MTLPixelFormatR8Unorm,
                                              yWidth, yHeight, 0, &yTextureRef);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              self.textureCache,
                                              pixelBuffer, nil,
                                              MTLPixelFormatRG8Unorm,
                                              uvWidth, uvHeight, 1, &uvTextureRef);
    if (yTextureRef != nil && uvTextureRef != nil) {
        id<MTLTexture> yTexture = CVMetalTextureGetTexture(yTextureRef);
        id<MTLTexture> uvTexture = CVMetalTextureGetTexture(uvTextureRef);
        CFRelease(yTextureRef);
        CFRelease(uvTextureRef);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return @[yTexture, uvTexture];
    }
    
    MTLTextureDescriptor* yTextureDesc = [[MTLTextureDescriptor alloc] init];
    yTextureDesc.width = yWidth;
    yTextureDesc.height = yHeight;
    yTextureDesc.pixelFormat = MTLPixelFormatR8Unorm;
    id<MTLTexture> yTexture = [self.device newTextureWithDescriptor:yTextureDesc];
    unsigned char* addr = (unsigned char*)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    MTLRegion yRegion = {{0, 0, 0},  {yWidth, yHeight, 1}};
    [yTexture replaceRegion:yRegion mipmapLevel:0 withBytes:addr bytesPerRow:CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)];
    
    MTLTextureDescriptor* uvTextureDesc = [[MTLTextureDescriptor alloc] init];
    uvTextureDesc.width = uvWidth;
    uvTextureDesc.height = uvHeight;
    uvTextureDesc.pixelFormat = MTLPixelFormatRG8Unorm;
    id<MTLTexture> uvTexture = [self.device newTextureWithDescriptor:uvTextureDesc];
    addr = (unsigned char*)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    MTLRegion uvRegion = {{0, 0, 0},  {uvWidth, uvHeight, 1}};
    [uvTexture replaceRegion:uvRegion mipmapLevel:0 withBytes:addr bytesPerRow:CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return @[yTexture, uvTexture];
}

@end
