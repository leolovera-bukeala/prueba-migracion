//
//  SKTFlipTransition.h
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/05/2019.
//  Copyright © 2019 Skim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface SKTFlipTransition : CIFilter {
    CIImage      *inputImage;
    CIImage      *inputTargetImage;
    CIVector     *inputExtent;
    NSNumber     *inputAngle;
    NSNumber     *inputTime;
}

@end