import UIKit

class GIFParser {
    let imageCount: Int
    private let imageSource: CGImageSource
    
    var images = [UIImage]()
    var delays = [Double]()
    var currentIndex = -1
    
    init(data: Data) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ParserError.CGImageSourceCreationError
        }
        
        self.imageSource = source
        self.imageCount = CGImageSourceGetCount(source)
    }
    
    convenience init(name: String) async throws {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "gif"),
            let data = try? Data(contentsOf: url)
        else {
            throw ParserError.ImageNotFoundInMainBundle
        }
        
        try self.init(data: data)
    }
    
    func loadNextImage() async throws {
        currentIndex += 1
        
        if currentIndex == imageCount {
            currentIndex = 0
            return
        }
        
        if images.count > currentIndex {
            return
        }
        
        // image
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, currentIndex, nil) else {
            throw ParserError.ImageCreationError
        }

        images.append(UIImage(cgImage: cgImage))
        
        // delay
        let delay = delayForImage(at: currentIndex, source: imageSource)
        delays.append(delay)
    }
    
    func getCurrentImageAndDelay() -> (UIImage, Double) {
        return (images[currentIndex], delays[currentIndex])
    }
    
    enum ParserError: Error {
        case CGImageSourceCreationError
        case ImageCreationError
        case ImageNotFoundInMainBundle
    }
}

public extension UIImage {
    class func gifImages(data: Data) -> ([UIImage], [Double]) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return ([], [])
        }
        let count = CGImageSourceGetCount(source)
        let delays = (0..<count).map {
            delayForImage(at: $0, source: source)
        }
        
        var frames = [UIImage]()
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let frame = UIImage(cgImage: cgImage)
                frames.append(frame)
            } else {
                return ([], [])
            }
        }
        
        return (frames, delays)
    }
    
    class func gifImage(name: String) -> ([UIImage], [Double]) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let data = try? Data(contentsOf: url)
        else {
            return ([], [])
        }
        return gifImages(data: data)
    }
}

private func delayForImage(at index: Int, source: CGImageSource) -> Double {
    let defaultDelay = 0.05 // 20 fps
    
    let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
    let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
    defer {
        gifPropertiesPointer.deallocate()
    }
    let unsafePointer = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
    if CFDictionaryGetValueIfPresent(cfProperties, unsafePointer, gifPropertiesPointer) == false {
        return defaultDelay
    }
    let gifProperties = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
    var delayWrapper = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                         Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
                                    to: AnyObject.self)
    if delayWrapper.doubleValue == 0 {
        delayWrapper = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                         Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()),
                                    to: AnyObject.self)
    }
    
    if let delay = delayWrapper as? Double,
       delay > 0 {
        return delay
    } else {
        return defaultDelay
    }
}
