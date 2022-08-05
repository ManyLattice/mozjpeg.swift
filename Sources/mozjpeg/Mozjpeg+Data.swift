//
//  File.swift
//  
//
//  Created by Михаил Гудзикевич on 26.07.2022.
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif
#if SWIFT_PACKAGE
import mozjpegc
#endif

public extension Data {
    
    func mozjpegRepresentation(size: NSSize, quality: Float) -> Data? {
        guard let imageRep = NSBitmapImageRep(data: self) else { return nil }
        let quality = Swift.max(1, Int32(quality * 100))

        let handle = tjInitCompress()
        
        let width = Int32(size.width)
        let height = Int32(size.height)
        let bufferSize = TJBUFSIZE(width, height)
        
        let pixelFormat: Int32 = Int32(imageRep.bitsPerPixel / 8)
        let subsampling: Int32 = Int32(TJSAMP_420.rawValue)
        let flags = TJFLAG_ACCURATEDCT
        
        let dstBuf = malloc(Int(bufferSize))
        var jpegSize: UInt = 0
                
        tjCompress(handle, imageRep.bitmapData, width, 0, height, pixelFormat, dstBuf, &jpegSize, subsampling, Int32(quality), flags)
        
        guard let dstBuf = dstBuf else { return nil }
        
        let dstData = Data(bytes: dstBuf, count: Int(jpegSize))
         
        free(dstBuf)
        
        guard dstData.count != 0 else { return nil }
        
        return dstData
    }
    
}
