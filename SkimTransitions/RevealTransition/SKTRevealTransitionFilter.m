//
//  SKTRevealTransitionFilter.m
//  SkimTransitions
//
//  Created by Christiaan Hofman on 22/5/2019.
//  Copyright Christiaan Hofman 2019. All rights reserved.
//

#import "SKTRevealTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKTRevealTransitionFilter

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:0.0 Y:0.0 Z:300.0 W:300.0], kCIAttributeDefault,
            kCIAttributeTypeRectangle,          kCIAttributeType,
            nil],                               kCIInputExtentKey,
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  0.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  -M_PI], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  M_PI], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeAngle,             kCIAttributeType,
            nil],                              kCIInputAngleKey,
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeTime,              kCIAttributeType,
            nil],                              kCIInputTimeKey,

        nil];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    CGFloat t = [inputTime doubleValue];
    CGFloat angle = [inputAngle doubleValue];
    CGFloat c = cos(angle);
    CGFloat s = sin(angle);
    CGFloat d = [inputExtent Z] * t / fmax(fabs(c), fabs(s));
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:-d * c yBy:-d * s];
    
    CIFilter *transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    [transformFilter setValue:inputImage forKey:kCIInputImageKey];
    [transformFilter setValue:transform forKey:kCIInputTransformKey];
    
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[transformFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
    [compositingFilter setValue:inputTargetImage forKey:kCIInputBackgroundImageKey];
    
    return [compositingFilter valueForKey:kCIOutputImageKey];}

@end
