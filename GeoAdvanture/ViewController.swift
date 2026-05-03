import UIKit
import ImageIO

class ViewController: UIViewController {

    var collectionView: UICollectionView!
    let images: [URL] = Array(repeating: Bundle.main.url(forResource: "big", withExtension: "jpg")!, count: 50)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 160)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        view.addSubview(collectionView)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell",
                                                      for: indexPath) as! ImageCell
        
        let url = images[indexPath.row]
        cell.configure(with: url)
        return cell
    }
}
class ImageCell: UICollectionViewCell {
    
    let normalView = UIImageView()
    let downsampleView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        normalView.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
        normalView.contentMode = .scaleAspectFill
        normalView.clipsToBounds = true
        normalView.layer.borderWidth = 1
        normalView.layer.borderColor = UIColor.red.cgColor
        
        downsampleView.frame = CGRect(x: 80, y: 0, width: 75, height: 75)
        downsampleView.contentMode = .scaleAspectFill
        downsampleView.clipsToBounds = true
        downsampleView.layer.borderWidth = 1
        downsampleView.layer.borderColor = UIColor.green.cgColor
        
        contentView.addSubview(normalView)
        contentView.addSubview(downsampleView)
    }
    
    @objc func memoryUsed() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info)) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            task_info(mach_task_self_,
                      task_flavor_t(MACH_TASK_BASIC_INFO),
                      $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                      &count)
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with url: URL) {

        DispatchQueue.global().async {
            
            // 测试普通方式耗时
            let t1 = CFAbsoluteTimeGetCurrent()
            let origin = UIImage(contentsOfFile: url.path) ?? UIImage()
            let scaled = origin.scaled(to: CGSize(width: 75, height: 75))
            let normalCost = (CFAbsoluteTimeGetCurrent() - t1) * 1000
            
            // 测试下采样耗时
            let t2 = CFAbsoluteTimeGetCurrent()
            let downsampled = self.downsample(imageAt: url,
                                              to: CGSize(width: 75, height: 75))
            let downsampleCost = (CFAbsoluteTimeGetCurrent() - t2) * 1000
            
            // 测内存
            let mem = self.memoryUsed()
            
            print("📌 普通缩略图耗时：\(normalCost) ms")
            print("📌 下采样缩略图耗时：\(downsampleCost) ms")
            print("📌 当前内存：\(mem / 1024 / 1024) MB")
            print("-----------------------------")
            
            DispatchQueue.main.async {
                self.normalView.image = scaled
                self.downsampleView.image = downsampled
            }
        }
    }
    
    // MARK: 下采样
    func downsample(imageAt imageURL: URL, to pointSize: CGSize) -> UIImage {
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let source = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!
        
        let maxDimension = max(pointSize.width, pointSize.height) * UIScreen.main.scale
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        
        let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions)!
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    func scaled(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
