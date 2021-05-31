import Flutter
import UIKit
import FBSDKShareKit
import Photos
import MessageUI

public class SwiftFlutterMicroSvcUtilPlugin: NSObject, FlutterPlugin {
  var result: FlutterResult?
  var shareURL:String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_microsvc_util", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterMicroSvcUtilPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  //MARK: FLUTTER HANDLER CALL
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.result = result
    if call.method == "getPlatformVersion" {
        result("iOS " + UIDevice.current.systemVersion)
    } else if call.method == "share"{
        if let arguments = call.arguments as? [String:Any] {
            let type = arguments["type"] as? String ?? "ShareType.more"
            let shareQuote = arguments["quote"] as? String ?? ""
            let shareUrl = arguments["url"] as? String ?? ""
            let shareImageUrl = arguments["imageUrl"] as? String ?? ""
            _ = arguments["imageName"] as? String ?? ""
            
            switch type {
            case "ShareType.facebookWithoutImage":
                shareFacebookWithoutImage(withQuote: shareQuote, withUrl: shareUrl)
                break
                
            case "ShareType.instagramWithImageUrl":
                let url = URL(string: shareImageUrl)
                if let urlData = url {
                    let data = try? Data(contentsOf: urlData)
                    if let datas = data {
                        shareInstagramWithImageUrl(image: UIImage(data: datas) ?? UIImage()) { (flag) in
                        }
                    }else{
                        self.result?("Something went wrong")
                    }
                }
                else{
                    self.result?("Could not load the image")
                }
                break
            case "ShareType.more":
                // self.result?("Method not implemented")
                shareFacebookWithoutImage(withQuote: shareQuote, withUrl: shareUrl)
                break
            default:
                break
            }
        }
    } else if (call.method == "shareOnSMS") {
        if let arguments = call.arguments as? [String:Any] {
            let recipients = arguments["recipients"] as? [String] ?? []
            let text = arguments["text"] as? String ?? ""
            sendSMSMessage(withRecipient: recipients,withTxtMsg: text)
        }
    } else if (call.method == "shareOnTwitter") {
        if let arguments = call.arguments as? [String:Any] {
            let url = arguments["url"] as? [String] ?? []
            let text = arguments["text"] as? String ?? ""
            sendTwitterMessage(withUrl: url, withTxtMsg: text)
        }
    } else if (call.method == "shareOnLine") {
        if let arguments = call.arguments as? [String:Any] {
            let text = arguments["text"] as? String ?? ""
            sendLineMessage(withTxtMsg: text)
        }
    } else if (call.method == "shareOnEmail") {
        if let arguments = call.arguments as? [String:Any] {
            let recipients = arguments["recipients"] as? [String] ?? []
            let ccrecipients = arguments["ccrecipients"] as? [String] ?? []
            let bccrecipients = arguments["bccrecipients"] as? [String] ?? []
            let subject = arguments["subject"] as? String ?? ""
            let body = arguments["body"] as? String ?? ""
            let isHTML = arguments["isHTML"] as? Bool ?? false
            sendEmail(withRecipient: recipients, withCcRecipient: ccrecipients, withBccRecipient: bccrecipients, withBody: body, withSubject: subject, withisHTML: isHTML)
        }
    } else if (call.method == "shareOnUrlCopy") {
        if let arguments = call.arguments as? [String:Any] {
            let text = arguments["text"] as? String ?? ""
            sendUrlCopy (withTxtMsg: text)
        }
    }
  }

  //MARK: SHARE POST ON FACEBOOK WITHOUT IMAGE
  private func shareFacebookWithoutImage(withQuote quote: String?, withUrl urlString: String?) {
      DispatchQueue.main.async {
          let shareContent = ShareLinkContent()
          let shareDialog = ShareDialog()
          if let url = urlString {
              shareContent.contentURL = URL.init(string: url)!
          }
          if let quoteString = quote {
              shareContent.quote = quoteString.htmlToString
          }
          shareDialog.shareContent = shareContent
          if let flutterAppDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
              shareDialog.fromViewController = flutterAppDelegate.window.rootViewController
              shareDialog.mode = .automatic
              shareDialog.show()
              self.result?("Success")
          } else{
              self.result?("Failure")
          }
      }
  }
  
  //MARK: SHARE POST ON INSTAGRAM WITH IMAGE NETWORKING URL
  private func shareInstagramWithImageUrl(image: UIImage, result:((Bool)->Void)? = nil) {
      guard let instagramURL = NSURL(string: "instagram://app") else {
          if let result = result {
              self.result?("Instagram app is not installed on your device")
              result(false)
          }
          return
      }
      
      //Save image on device
      do {
          try PHPhotoLibrary.shared().performChangesAndWait{
              let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
              let assetID = request.placeholderForCreatedAsset?.localIdentifier ?? ""
              self.shareURL = "instagram://library?LocalIdentifier=" + assetID
              
              //Share image
              if UIApplication.shared.canOpenURL(instagramURL as URL) {
                  if let sharingUrl = self.shareURL {
                      if let urlForRedirect = NSURL(string: sharingUrl) {
                          if #available(iOS 10.0, *) {
                              UIApplication.shared.open(urlForRedirect as URL, options: [:], completionHandler: nil)
                          }
                          else{
                              UIApplication.shared.openURL(urlForRedirect as URL)
                          }
                      }
                      self.result?("Success")
                  }
              } else{
                  self.result?("Instagram app is not installed on your device")
              }
          }
      } catch {
          if let result = result {
              self.result?("Failure")
              result(false)
          }
      }
  }
  
  func sendSMSMessage (withRecipient recipent: [String],withTxtMsg txtMsg: String) {
      let string = txtMsg
      if (MFMessageComposeViewController.canSendText()) {
          self.result?("Success")
          let controller = MFMessageComposeViewController()
          controller.body = string.htmlToString
          controller.recipients = recipent
          controller.messageComposeDelegate = self
          UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true, completion: nil)
      } else {
          self.result?("Message service is not available")
      }
  }

  func sendTwitterMessage (withUrl url: [String], withTxtMsg txtMsg: String) {
      let shareString = "https://twitter.com/intent/tweet?text=\(txtMsg)&url=\(url)"
      let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
      let url = URL(string: escapedShareString)
      UIApplication.shared.openURL(url!)

      self.result?("Success")
  }

  func sendLineMessage (withTxtMsg txtMsg: String) {
      print (txtMsg)

      do {
          let shareString = "line://msg/text/\(txtMsg)"
          let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
          let url = URL(string: escapedShareString)
          let isOpen = UIApplication.shared.openURL(url!)

          if (!isOpen) {
              guard let url = URL(string: "https://apps.apple.com/us/app/line/id443904275")
              // guard let url = URL(string: "itms-apps://itunes.apple.com/app/id443904275")
              else {
                  self.result?("address invalid")
                  return
              }

              if #available(iOS 10.0, *) {
                  UIApplication.shared.open(url, options: [:])
              } else {
                  UIApplication.shared.openURL (url)
              }

              self.result?("line not install")
          } else {
              self.result?("Success")
          }

      } catch {
          print (error)
      }
  }
  
  func sendEmail (withRecipient recipent: [String], withCcRecipient ccrecipent: [String],withBccRecipient bccrecipent: [String],withBody body: String, withSubject subject: String, withisHTML isHTML:Bool ) {
      if MFMailComposeViewController.canSendMail() {
          let mail = MFMailComposeViewController()
          mail.mailComposeDelegate = self
          mail.setSubject(subject)
          mail.setMessageBody(body, isHTML: isHTML)
          mail.setToRecipients(recipent)
          mail.setCcRecipients(ccrecipent)
          mail.setBccRecipients(bccrecipent)
          UIApplication.shared.keyWindow?.rootViewController?.present(mail, animated: true, completion: nil)
      } else {
          self.result?("Mail services are not available")
      }
  }

  func sendUrlCopy (withTxtMsg txtMsg: String) {
      UIPasteboard.general.string = txtMsg
      self.result?("Success")
  }  
}

//MARK: EXTENSIONS FOR STRING
extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

//MARK: MFMessageComposeViewControllerDelegate
extension SwiftFlutterMicroSvcUtilPlugin:MFMessageComposeViewControllerDelegate{
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let map: [MessageComposeResult: String] = [
            MessageComposeResult.sent: "sent",
            MessageComposeResult.cancelled: "cancelled",
            MessageComposeResult.failed: "failed",
        ]
        if let callback = self.result {
            callback(map[result])
        }
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}

//MARK: MFMailComposeViewControllerDelegate
extension SwiftFlutterMicroSvcUtilPlugin: MFMailComposeViewControllerDelegate{
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}
