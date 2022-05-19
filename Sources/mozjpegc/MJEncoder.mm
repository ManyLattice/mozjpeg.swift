//
//  MJEncoder.m
//  
//
//  Created by Radzivon Bartoshyk on 19/05/2022.
//

#import "MJEncoder.hxx"
#import "turbojpeg.h"
#import <Accelerate/Accelerate.h>
#import <CoreGraphics/CoreGraphics.h>

@implementation MJEncoder {
    tjhandle tjInstance;
}

-(nonnull id)init {
    tjInstance = tjInitCompress();

    return self;
}

-(void)dealloc {
    tjDestroy(tjInstance);
    tjInstance = nullptr;
}

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });
    return colorSpace;
}


-(nullable NSError*) compressTo:(nonnull NSURL*)url image:(nonnull MozjpegImage *)image quality:(int)quality progressive:(bool)progressive useFastest:(bool)useFastest {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return [[NSError alloc] initWithDomain:@"MJEncoder" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"Invalid image"}];
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    auto buffer = [image mjRgbaPixels];
    
    const int pixelFormat = TJPF_RGBA;
    
    int flags = useFastest ? TJFLAG_FASTDCT : TJFLAG_ACCURATEDCT;
    if (progressive) {
        flags |= TJFLAG_PROGRESSIVE;
    }
    
    auto filename = [[url path] UTF8String];
    if (!filename) {
        free(buffer);
        return [[NSError alloc] initWithDomain:@"MJEncoder" code:500 userInfo:@{ NSLocalizedDescriptionKey: @"Filename is invalid"}];
    }
    
    int result = tjSaveImage(filename, buffer, (int) width, 0, (int) height, pixelFormat, flags);
    free(buffer);
    if (result < 0) {
        return [[NSError alloc] initWithDomain:@"MJEncoder" code:500 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"JPEG encoding error with : %s", tjGetErrorStr2(tjInstance)]}];
    }

    return nil;
}

-(nullable NSData*)compress:(nonnull MozjpegImage*)image quality:(int)quality progressive:(bool)progressive useFastest:(bool)useFastest {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    auto buffer = [image mjRgbaPixels];
    
    const int pixelFormat = TJPF_RGBA;
    
    unsigned char* jpegBuf = nullptr;
    unsigned long jpegSize = 0;
    
    int flags = useFastest ? TJFLAG_FASTDCT : TJFLAG_ACCURATEDCT;
    if (progressive) {
        flags |= TJFLAG_PROGRESSIVE;
    }
    
    int result = tjCompress2(tjInstance, static_cast<const unsigned char *>(buffer), static_cast<int>(width), 0, static_cast<int>(height), pixelFormat, &jpegBuf, &jpegSize, TJSAMP_420, quality, flags);
    free(buffer);
    if (result < 0) {
        NSLog(@"%@", [NSString stringWithFormat:@"JPEG encoding error with : %s", tjGetErrorStr2(tjInstance)]);
        tjFree(jpegBuf);
        return nil;
    }
    
    auto resultData = [[NSMutableData alloc] initWithBytes:jpegBuf length:jpegSize];
    tjFree(jpegBuf);
    return resultData;
}

@end
