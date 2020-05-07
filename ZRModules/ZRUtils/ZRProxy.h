//
//  ZRProxy.h
//  Sample
//
//  Created by Zhou,Rui(ART) on 2020/5/6.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZRProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
