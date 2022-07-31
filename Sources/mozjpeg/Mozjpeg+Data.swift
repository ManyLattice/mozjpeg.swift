//
//  Mozjpeg+Data.swift
//  
//
//  Created by Михаил Гудзикевич on 31.07.2022.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if SWIFT_PACKAGE
import mozjpegc
#endif

public extension Data {
    
    func mozjpegRepresentation(size: NSSize, with quality: Float) -> Data? {
        let encoder = MJEncoder()
        let quality = Swift.max(1, Int32(quality * 100))
        
        return encoder.compressData(self, size: size, quality: quality, progressive: true, useFastest: false)
    }
    
}
