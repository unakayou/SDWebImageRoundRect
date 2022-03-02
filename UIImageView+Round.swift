//
//  UIImageView+Round.swift
//  UIImageView
//
//  Created by unakayou on 2020/3/8.
//
//  SDWebImage 图片切圆

import UIKit
import SDWebImage

/*
 *  1.取URL对应图片: ImageOriginal,切图片为圆形: ImageRound.
 *  2.图片'会'被拉伸到ImageView尺寸
 *  2.会分别对ImageOriginal(原图),ImageRound(⭕️图)进行缓存
 *  3.取原本图片,使用UIImageView.sd_SetImagewithURL()
 *  4.取圆形图片,使用UIImageView.sd_setRoundImageWithURL()
 */
extension UIImageView {
    
    /// 获取URL中图片的圆形切图.缓存到SDWebImage
    /// - Parameter urlStr: Image URL
    @objc func sd_setRoundImageWithURL(urlStr: String) {
        if(urlStr.count <= 0) {return}
        let url = NSURL.init(string: urlStr as String)
        let cacheurlStr = urlStr.appending("Round=true&frame=\(frame)")
        if let mCacheImage = SDImageCache.shared.imageFromMemoryCache(forKey: cacheurlStr) {
            self.image = mCacheImage;
            return
        }
        
        if let dCacheImage = SDImageCache.shared.imageFromDiskCache(forKey: cacheurlStr) {
            self.image = dCacheImage;
            return
        }
        
        // 缓存没读到,请求原图切圆角后缓存
        SDWebImageManager.shared.loadImage(with: url as URL?, options:SDWebImageOptions.retryFailed) { (receivedSize, expectedSize, targetURL)in
            
        } completed: { (image, data, error, cacheType, finished, imageURL) in
            if finished == true {
                image?.round(imageViewSize: self.frame.size, callBack: { (roundImage) in
                    self.image = roundImage;
                    SDImageCache.shared.store(roundImage, forKey: cacheurlStr, completion: nil)
                })
            }
        }
    }
}

extension UIImage {
    
    /// 切圆
    /// - Parameters:
    ///   - size: UIImageView 尺寸
    ///   - callBack: 返回圆形 Image
    /// - Returns: Void
    @objc func round(imageViewSize size: CGSize, callBack: ((_ _image : UIImage) -> ())?) {
        if self.isCutting { return }
        self.isCutting = true
        
        guard let callBack = callBack else { return }
        let viewSize = size == CGSize.zero ? self.size : size
        // 容器范围内上下文
        UIGraphicsBeginImageContextWithOptions(CGSize(width: viewSize.width, height: viewSize.height),
                                               false,
                                               UIScreen.main.scale)
        // 按照容器最短边作为半径绘圆
        let diameter = min(viewSize.width, viewSize.height)
        let path = UIBezierPath(arcCenter: CGPoint(x: viewSize.width / 2, y: viewSize.height / 2),
                                radius: diameter / 2,
                                startAngle: 0,
                                endAngle: CGFloat(Double.pi * 2),
                                clockwise: true)
        path.addClip()
        
        var imageScaleWidth :CGFloat = 0.0
        var imageScaleHeight : CGFloat = 0.0
        // 将min(image.width, image.height)拉伸或者放大到圆圈直径,另外的按比例缩放
        if self.size.width < self.size.height {
            imageScaleWidth = diameter
            imageScaleHeight = diameter / self.size.width * self.size.height
        } else {
            imageScaleWidth = diameter / self.size.height * self.size.width
            imageScaleHeight = diameter
        }
        // 绘制到容器尺寸上
        self.draw(in: CGRect(x: (viewSize.width - imageScaleWidth) / 2,
                             y: (viewSize.height - imageScaleHeight) / 2,
                             width: imageScaleWidth,
                             height: imageScaleHeight))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        DispatchQueue.main.async {
            callBack(image ?? UIImage())
            self.isCutting = false
        }
    }
}
