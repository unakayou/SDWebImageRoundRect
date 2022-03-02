//
//  UIImageView+RoundCorner.swift
//  UIImageView
//
//  Created by unakayou on 2020/3/8.
//
//  SDWebImage 图片切圆角

import UIKit
import SDWebImage

/*
 *  1.取URL对应图片: ImageOriginal,切图片为圆形: ImageRoundCorner.
 *  2.图片'不会'被拉伸到ImageView尺寸
 *  3.会分别对ImageOriginal(原图),ImageRoundCorner(圆角图)进行缓存
 *  4.取原本图片,使用UIImageView.sd_SetImagewithURL()
 *  5.取圆形图片,使用UIImageView.sd_setRoundRectImageWithURL()
 */
extension UIImageView {
        
    /// 获取URL中图片的圆角切图.缓存到SDWebImage
    /// - Parameters:
    ///   - urlStr: 图片URL
    ///   - corners: 圆角位置,上左下右
    ///   - cornerRadius: 圆角弧度
    @objc func sd_setRoundRectImageWithURL(urlStr: String,
                                           byRoundingCorners corners: UIRectCorner,
                                           cornerRadius: CGFloat) {
        if(urlStr.count <= 0) {return}
        let url = NSURL.init(string: urlStr as String)
        if cornerRadius > 0.0 {
            // 有圆角,读圆角的缓存图片
            let cacheurlStr = urlStr.appending("cornerRadius=\(cornerRadius)&frame=\(frame)&corners=\(String(describing: corners))")
            if let mCacheImage = SDImageCache.shared.imageFromMemoryCache(forKey: cacheurlStr) {
                self.image = mCacheImage;
                return
            }
            
            if let dCacheImage = SDImageCache.shared.imageFromDiskCache(forKey: cacheurlStr) {
                self.image = dCacheImage;
                return
            }
            // 缓存没读到,请求原图,切圆角后缓存
            SDWebImageManager.shared.loadImage(with: url as URL?, options:SDWebImageOptions.retryFailed) { (receivedSize, expectedSize, targetURL)in
                
            } completed: { (image, data, error, cacheType, finished, imageURL) in
                if finished == true {
                    image?.imageWithCornerRadius(imageViewSize: self.frame.size, byRoundingCorners: corners, cornerRadius: cornerRadius, callBack: { (radiusImage) in
                        self.image = radiusImage;
                        SDImageCache.shared.store(radiusImage, forKey: cacheurlStr, completion: nil)
                    })
                }
            }
        } else {
            // 没圆角
            self.sd_setImage(with: url as URL?, placeholderImage:nil, options:SDWebImageOptions.retryFailed) { (image, error, cacheType, imageURL)in
                self.image = image
            }
        }
    }
}

// MARK: 圆角裁切
extension UIImage {

    // 防止其他对象多线程调用同一个图片的切图
    internal var isCutting: Bool {
        get {
            var isCutting = true
            objc_sync_enter(self)
            let key : UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: "UIImage.cutting".hashValue)
            isCutting = objc_getAssociatedObject(self, key) as? Bool ?? false
            objc_sync_exit(self)
            return isCutting
        }
        
        set {
            objc_sync_enter(self)
            let key : UnsafeRawPointer! = UnsafeRawPointer.init(bitPattern: "UIImage.cutting".hashValue)
            objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_ASSIGN)
            objc_sync_exit(self)
        }
    }
    
    /// 切圆  (size最好传UIImageView的尺寸,不然圆角大小会按照图片比例切)
    @objc func  imageWithCornerRadius(imageViewSize size : CGSize,
                                      byRoundingCorners corners: UIRectCorner,
                                      cornerRadius: CGFloat,
                                      callBack: ((_ _image:UIImage) -> ())?) {
        if self.isCutting { return }
        self.isCutting = true

        guard let callBack = callBack else { return }
        if cornerRadius <= 0 { callBack(self) }
        if corners.rawValue == 0 { callBack(self) }
        let viewSize = size == CGSize.zero ? self.size : size
        DispatchQueue.global().async {
            let bounds = CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height);
            UIGraphicsBeginImageContextWithOptions(viewSize, false, UIScreen.main.scale);
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            path.addClip()
            self.draw(in: bounds)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async(execute: {
                callBack(image ?? UIImage())
                self.isCutting = false
            })
        }
    }
}

