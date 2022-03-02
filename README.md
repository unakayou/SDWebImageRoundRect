# SDWebImageRoundRect
SDWebImage category, draw round and rect on imageView

SDWebImage category, 将下载的图片直接切为圆形或者圆角进行缓存。

用法：

```swift
// 圆
self.backgroundImageView.sd_setRoundImageWithURL(urlStr: self.rabbit)

// 圆角
let cornerRadius : CGFloat = 50.0
self.backgroundImageView.sd_setRoundRectImageWithURL(urlStr: self.brushTeeth, byRoundingCorners: .allCorners, cornerRadius: cornerRadius)
```

