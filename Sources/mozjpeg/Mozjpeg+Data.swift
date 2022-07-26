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
    
    func mozjpegRepresentation(size: NSSize, quality: Float) throws -> Data {
        let encoder = MJEncoder()
        let quality = Swift.max(1, Int32(quality * 100))
        
        guard let data = encoder.compressData(self, size: size, quality: quality, progressive: true, useFastest: false) else {
            throw CannotCompressError()
        }
        
        return data
    }
    
}
