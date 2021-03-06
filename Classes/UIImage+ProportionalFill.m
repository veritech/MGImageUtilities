//
//  UIImage+ProportionalFill.m
//
//  Created by Matt Gemmell on 20/08/2008.
//  Copyright 2008 Instinctive Code.
//

#import "UIImage+ProportionalFill.h"


@implementation UIImage (MGProportionalFill)


- (UIImage *)imageToFitSize:(CGSize)fitSize method:(MGImageResizingMethod)resizeMethod
{
	float imageScaleFactor = 1.0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if ([self respondsToSelector:@selector(scale)]) {
		imageScaleFactor = [self scale];
	}
#endif
	
	float sourceWidth;
	float sourceHeight;
    float targetWidth;
    float targetHeight;
	
	switch ([self imageOrientation]) {
		case UIImageOrientationUp:
		case UIImageOrientationDown:
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			sourceWidth = [self size].width * imageScaleFactor;
			sourceHeight = [self size].height * imageScaleFactor;
			targetWidth = fitSize.width;
			targetHeight = fitSize.height;
			break;
		case UIImageOrientationLeft:
		case UIImageOrientationRight:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			sourceWidth = [self size].height * imageScaleFactor;
			sourceHeight = [self size].width * imageScaleFactor;
			targetWidth = fitSize.height;
			targetHeight = fitSize.width;
			break;
	}
	
    BOOL cropping = !(resizeMethod == MGImageResizeScale);
	
    // Calculate aspect ratios
    float sourceRatio = sourceWidth / sourceHeight;
    float targetRatio = targetWidth / targetHeight;
    
    // Determine what side of the source image to use for proportional scaling
    BOOL scaleWidth = (sourceRatio <= targetRatio);
    // Deal with the case of just scaling proportionally to fit, without cropping
    scaleWidth = (cropping) ? scaleWidth : !scaleWidth;
    
    // Proportionally scale source image
    float scalingFactor, scaledWidth, scaledHeight;
    if (scaleWidth) {
        scalingFactor = 1.0 / sourceRatio;
        scaledWidth = targetWidth;
        scaledHeight = round(targetWidth * scalingFactor);
    } else {
        scalingFactor = sourceRatio;
        scaledWidth = round(targetHeight * scalingFactor);
        scaledHeight = targetHeight;
    }
    float scaleFactor = scaledHeight / sourceHeight;
    
    // Calculate compositing rectangles
	// UNTESTED: cropping may not perform correctly on images with rotated orientation
    CGRect sourceRect, destRect;
    if (cropping) {
        destRect = CGRectMake(0, 0, targetWidth, targetHeight);
        float destX, destY;
        if (resizeMethod == MGImageResizeCrop) {
            // Crop center
            destX = round((scaledWidth - targetWidth) / 2.0);
            destY = round((scaledHeight - targetHeight) / 2.0);
        } else if (resizeMethod == MGImageResizeCropStart) {
            // Crop top or left (prefer top)
            if (scaleWidth) {
				// Crop top
				destX = 0.0;
				destY = 0.0;
            } else {
				// Crop left
                destX = 0.0;
				destY = round((scaledHeight - targetHeight) / 2.0);
            }
        } else if (resizeMethod == MGImageResizeCropEnd) {
            // Crop bottom or right
            if (scaleWidth) {
				// Crop bottom
				destX = round((scaledWidth - targetWidth) / 2.0);
				destY = round(scaledHeight - targetHeight);
            } else {
				// Crop right
				destX = round(scaledWidth - targetWidth);
				destY = round((scaledHeight - targetHeight) / 2.0);
            }
        }
        sourceRect = CGRectMake(destX / scaleFactor, destY / scaleFactor, 
                                targetWidth / scaleFactor, targetHeight / scaleFactor);
    } else {
        sourceRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
        destRect = CGRectMake((targetWidth - scaledWidth) / 2.0, (targetHeight - scaledHeight) / 2.0, scaledWidth, scaledHeight);
    }
    
    // Create appropriately modified image.
	UIImage *image = nil;
	
/*
 Disable this code, as it's not clear if it is thread safe
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 4.0) {
		UIGraphicsBeginImageContextWithOptions(destRect.size, NO, 0.0); // 0.0 for scale means "correct scale for device's main screen".
		CGImageRef sourceImg = CGImageCreateWithImageInRect([self CGImage], sourceRect); // cropping happens here.
		image = [UIImage imageWithCGImage:sourceImg scale:0.0 orientation:self.imageOrientation]; // create cropped UIImage.
		[image drawInRect:destRect]; // the actual scaling happens here, and orientation is taken care of automatically.
		CGImageRelease(sourceImg);
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
#endif
*/
	if(!image) {
		// Try older method.
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL, targetWidth, targetHeight, 8, (targetWidth * 4), 
													 colorSpace, kCGImageAlphaPremultipliedLast);
		CGImageRef sourceImg = CGImageCreateWithImageInRect([self CGImage], sourceRect);
		CGContextDrawImage(context, destRect, sourceImg);
		CGImageRelease(sourceImg);
		CGImageRef finalImage = CGBitmapContextCreateImage(context);	
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
		
		//image = [UIImage imageWithCGImage:finalImage];
		
		image = [UIImage imageWithCGImage:finalImage 
									scale:imageScaleFactor
							  orientation:[self imageOrientation]
				 ];
		
		CGImageRelease(finalImage);
	}
	
    return image;
}


- (UIImage *)imageCroppedToFitSize:(CGSize)fitSize
{
    return [self imageToFitSize:fitSize method:MGImageResizeCrop];
}


- (UIImage *)imageScaledToFitSize:(CGSize)fitSize
{
    return [self imageToFitSize:fitSize method:MGImageResizeScale];
}


@end
