//
//  ZRMovieReader.h
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/4/20.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZRMovieReader : NSObject

- (instancetype)initWithFilePath:(NSString *)path;
- (void)startReading;
- (void)stopReading;
- (CMSampleBufferRef)readSampleBuffer:(AVAssetReaderStatus *)status;
- (NSInteger)getCurrentFrameIndex;

@end

NS_ASSUME_NONNULL_END
