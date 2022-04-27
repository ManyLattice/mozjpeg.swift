//
//  MozjpegBinding.m
//  PDFScanner
//
//  Created by Radzivon Bartoshyk on 3.09.21.
//

#import <Foundation/Foundation.h>
#import "MozjpegBinding.h"

#import <jpeglib.h>

#define JPEG_LIB_VERSION 80

struct my_error_mgr {
    struct jpeg_error_mgr pub;    /* "public" fields */
    
    jmp_buf setjmp_buffer;    /* for return to caller */
};

typedef struct my_error_mgr * my_error_ptr;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

METHODDEF(void)
my_error_exit (j_common_ptr cinfo)
{
    /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
    my_error_ptr myerr = (my_error_ptr) cinfo->err;
    
    /* Always display the message. */
    /* We could postpone this until after returning, if we chose. */
    (*cinfo->err->output_message) (cinfo);
    
    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}

NSData * _Nullable compressJPEGData(UIImage * _Nonnull sourceImage, int quality) {
    CGImageRef imageRef = sourceImage.CGImage;
    
    size_t _bitsPerPixel           = CGImageGetBitsPerPixel(imageRef);
    size_t _bitsPerComponent       = CGImageGetBitsPerComponent(imageRef);
    size_t _width                  = CGImageGetWidth(imageRef);
    size_t _height                 = CGImageGetHeight(imageRef);
    size_t _bytesPerRow            = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *bitmapData = (unsigned char *)malloc(_bytesPerRow * _height);
    
    CGContextRef context = CGBitmapContextCreate(bitmapData,
                                                 _width,
                                                 _height,
                                                 _bitsPerComponent,
                                                 _bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    //draw image
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef);
    
    //free data
    CGContextRelease(context);
    
    
    struct jpeg_compress_struct cinfo;
    struct my_error_mgr jerr;
    cinfo.err = jpeg_std_error(&jerr.pub);
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the JPEG code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        free(bitmapData);
        jpeg_destroy_compress(&cinfo);
        return nil;
    }
    jpeg_create_compress(&cinfo);
    
    uint8_t *outBuffer = NULL;
    unsigned long outSize = 0;
    jpeg_mem_dest(&cinfo, &outBuffer, &outSize);
    
    cinfo.image_width = (uint32_t)_width;
    cinfo.image_height = (uint32_t)_height;
    cinfo.input_components = (int)_bitsPerComponent;
    cinfo.in_color_space = _bitsPerComponent == 3 ? JCS_RGB : JCS_EXT_RGBA;
    jpeg_c_set_int_param(&cinfo, JINT_COMPRESS_PROFILE, JCP_FASTEST);
    jpeg_set_defaults(&cinfo);
    cinfo.arith_code = FALSE;
    cinfo.dct_method = JDCT_ISLOW;
    cinfo.optimize_coding = TRUE;
    jpeg_set_quality(&cinfo, quality, 1);
    jpeg_simple_progression(&cinfo);
    jpeg_start_compress(&cinfo, 1);
    
    JSAMPROW rowPointer[1];
    while (cinfo.next_scanline < cinfo.image_height) {
        rowPointer[0] = (JSAMPROW)(bitmapData + cinfo.next_scanline * _bytesPerRow);
        jpeg_write_scanlines(&cinfo, rowPointer, 1);
    }
    
    jpeg_finish_compress(&cinfo);
    
    NSData *result = [[NSData alloc] initWithBytes:outBuffer length:outSize];
    
    jpeg_destroy_compress(&cinfo);

    free(bitmapData);
    
    return result;
}
