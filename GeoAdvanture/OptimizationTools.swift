//
//  OptimizationTools.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/12/4.
//
import UIKit
import ImageIO // 必须引入这个底层框架

class LocalImageLoader {
    
    // 异步加载并压缩本地图片
    // fileURL: 本地文件的路径
    // pointSize: 需要显示的视图大小 (比如 Cell 里的 ImageVeiw 大小)
    // scale: 屏幕缩放因子 (UIScreen.main.scale)
    static func downsample(
        imageAt fileURL: URL,
        to pointSize: CGSize,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        // 1. 利用 GCD 放入后台队列 (UserInitiated 优先级较高，适合 UI 相关任务)
        DispatchQueue.global(qos: .userInitiated).async {
            
            // 2. 创建图片源，但暂时不解码 (kCGImageSourceShouldCache: false)
            // 这一步非常快，只是读取文件头信息
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, imageSourceOptions) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // 3. 计算目标像素大小
            let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
            
            // 4. 配置下采样参数 (核心技术点)
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true, // 在这里强制解码，避免回到主线程卡顿
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
            ] as CFDictionary
            
            // 5. 生成缩略图 (这里才真正耗时，但因为在后台线程，所以不卡)
            // ImageIO 会直接读取文件中需要的那部分像素，而不会把整张 4K 图加载进内存！
            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // 6. 转回 UIImage 并回到主线程
            let finalImage = UIImage(cgImage: downsampledImage)
            
            DispatchQueue.main.async {
                completion(finalImage)
            }
        }
    }
}

// MARK: - 2. 图片圆角优化 (对应简历：解决离屏渲染)
extension UIImage {
    // 面试话术：直接设置 layer.cornerRadius 会导致 GPU 离屏渲染。
    // 我使用 CoreGraphics 在后台线程直接把图片裁切成圆角，生成一张新图。
    // 这样 GPU 只需要负责简单的混合，不再需要做昂贵的遮罩计算。
    func toCircle(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: 8).addClip() // 裁切
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
