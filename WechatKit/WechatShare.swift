//
//  WechatShare.swift
//  WechatKit
//
//  Created by starboychina on 2015/12/03.
//  Copyright © 2015年 starboychina. All rights reserved.
//

// MARK: Share

public enum ShareContent {
    case Text(text: String)
    case Image(image: Data, messageExt: String, action: String, thumbImage: UIImage)
    case LinkURL(urlString: String, title: String, description: String, thumbImage: UIImage)
    case MusicURL(musicURL: String, dataURL: String, title: String, description: String, thumbImage: UIImage)
    case VideoURL(videoURL: String, title: String, description: String, thumbImage: UIImage)
    case WXMediaMessage(WXMediaMessage)
}
extension ShareContent {
    fileprivate func getReq(_ scence: WXScene) -> SendMessageToWXReq {
        let req = SendMessageToWXReq()
        req.scene = Int32(scence.rawValue)
        req.bText = false
        switch self {
        case let .Text(text):
            req.text = text
            req.bText = true
        case let .Image(image, messageExt, action, thumbImage):
            break
        case let .LinkURL(urlString, title, description, thumbImage):
            break
        case let .MusicURL(musicURL, dataURL, title, description, thumbImage):
            break
        case let .VideoURL(videoURL, title, description, thumbImage):
            break
        case .WXMediaMessage(let wxmm):
            req.message = wxmm
        }
        return req
    }
}

extension WechatManager {
    
    /// 微信分享
    ///
    /// - Parameters:
    ///   - scence: 分享场景
    ///   - shareContent: 分享内容
    ///   - completionHandler: 分享成功与否回调
    /// **⚠️目前仅实现分享Text消息
    public func share(_ scence: WXScene, _ shareContent: ShareContent, completionHandler: AuthHandle? = nil) {
        self.completionHandler = completionHandler
        WXApi.send(shareContent.getReq(scence))
    }

    /**
    分享

    - parameter scence:      请求发送场景
    - parameter image:       消息缩略图
    - parameter title:       标题
    - parameter description: 描述内容
    - parameter url:         地址
    - parameter extInfo:     app分享信息
     (点击分享内容返回程序时,会传给WechatManagerShareDelegate.showMessage(message: String)
    */
    public func share(_ scence: WXScene,
                      image: UIImage?,
                      title: String,
                      description: String,
                      url: String? = "https://open.weixin.qq.com/",
                      extInfo: String? = nil) {

        var message = self.getRequestMesage(image, title: title, description: description)

        if let extInfo = extInfo {
            message = self.shareApp(message, url: url, extInfo: extInfo)
        } else {
            message = self.shareUrl(message, url: url)
        }

        self.sendReq(message, scence: scence)
    }

    //share url
    fileprivate func shareUrl(_ message: WXMediaMessage, url: String?) -> WXMediaMessage {
        message.mediaTagName = "WECHAT_TAG_JUMP_SHOWRANK"

        let ext = WXWebpageObject()
        ext.webpageUrl = url
        message.mediaObject = ext

        return message
    }
    /**
     share app

     - parameter message: message description
     - parameter url:     url description
     - parameter extInfo: extInfo description

     - returns: return value description
     */
    fileprivate func shareApp(_ message: WXMediaMessage, url: String?, extInfo: String)
        -> WXMediaMessage {
            message.messageExt = extInfo//"附加消息：Come from 現場TOMO" //返回到程序之后用
            message.mediaTagName = "WECHAT_TAG_JUMP_APP"
            //message.messageAction = "<action>\(messageAction)</action>" //不能返回  ..返回到程序之后用

            let ext = WXAppExtendObject()
            //        ext.extInfo = extInfo //返回到程序之后用
            ext.url = url;//分享到朋友圈时的链接地址
            let buffer: [UInt8] = [0x00, 0xff]
            let data = Data(bytes: UnsafePointer<UInt8>(buffer), count: buffer.count)
            ext.fileData = data

            message.mediaObject = ext

            return message
    }

    //get message
    fileprivate func getRequestMesage(_ image: UIImage?, title: String, description: String)
        -> WXMediaMessage {

            let message = WXMediaMessage()
            /** 描述内容
             * @note 长度不能超过1K
             */
            if description.characters.count > 128 {

                let startIndex = description.startIndex
                let to = description.index(after: description.index(startIndex, offsetBy: 128))

                message.description = description.substring(to: to)
            } else {
                message.description = description
            }

            /** 缩略图数据
             * @note 大小不能超过32K
             */
            let thumbImage = image == nil ? UIImage() : self.resizeImage(image!, newWidth: 100)

            message.setThumbImage(thumbImage)

            /** 标题
             * @note 长度不能超过512字节
             */
            if title.characters.count > 64 {

                let startIndex = title.startIndex
                let to = title.index(after: title.index(startIndex, offsetBy: 64))

                message.title = title.substring(to: to)
            } else {
                message.title = title
            }

            return message
    }

    fileprivate func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {

        let newHeight = image.size.height / image.size.width * newWidth
        UIGraphicsBeginImageContext( CGSize(width: newWidth, height: newHeight) )
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    //send request
    fileprivate func sendReq(_ message: WXMediaMessage, scence: WXScene) {
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(scence.rawValue)

        WXApi.send(req)
    }
}
