package com.gsshop.flutter_microsvc_util

import android.app.Activity
import android.content.*
import android.content.Context
import android.content.pm.PackageManager
import android.media.FaceDetector
import android.net.Uri
import androidx.annotation.NonNull
import android.os.Bundle

import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

import java.net.MalformedURLException
import java.net.URL

import com.twitter.sdk.android.tweetcomposer.TweetComposer

import com.facebook.CallbackManager
import com.facebook.share.model.ShareLinkContent
import com.facebook.share.widget.ShareDialog
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import com.facebook.GraphRequest
import com.facebook.GraphResponse
import java.util.*

/** FlutterMicroSvcUtilPlugin */
class FlutterMicroSvcUtilPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var appEventsLogger: AppEventsLogger
  private lateinit var anonymousId: String

  private var activity: Activity? = null
  private var activityContext: Context? = null

  private val logTag = "FacebookAppEvents"

  fun onAttachedToEngine(@NonNull flutterPluginBinding: BinaryMessenger) {
    channel = MethodChannel(flutterPluginBinding, "flutter_microsvc_util")
    channel.setMethodCallHandler(this)
    callbackManager = CallbackManager.Factory.create()
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "flutter_microsvc_util")
    channel.setMethodCallHandler(this)

    activityContext = binding.getApplicationContext()

    appEventsLogger = AppEventsLogger.newLogger(activityContext)
    anonymousId = AppEventsLogger.getAnonymousAppDeviceGUID(activityContext)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    Log.d(logTag, "flutter_microsvc_util onDetachedFromActivity")
    activity = null;
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    Log.d(logTag, "flutter_microsvc_util onDetachedFromActivityForConfigChanges")
    activity = null;
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "share") {
      var type: String? = call.argument("type")
      var quote: String? = call.argument("quote")
      var url: String? = call.argument("url")
      when (type) {
        "ShareType.facebookWithoutImage" -> shareToFacebook(url, quote, result)
//        "ShareType.instagramWithImageUrl" -> getImageBitmap(imageUrl, result)
        else ->             // result.notImplemented();
          shareToFacebook(url, quote, result)
      }
    } else if (call.method == "shareOnSMS") {
      var recipients: ArrayList<String>? = call.argument("recipients")
      val textMsg: String? = call.argument("text")

      shareOnSMS(recipients, textMsg, result)
    } else if (call.method == "shareOnTwitter") {
      val url: String? = call.argument("url")
      val textMsg: String? = call.argument("text")
      // val trailingText: String? = call.argument("trailingText")

      shareOnTwitter(url, textMsg, result)
    } else if (call.method == "shareOnLine") {
      val textMsg: String? = call.argument("text")

      shareOnLine(textMsg, result)
    } else if (call.method == "shareOnEmail") {
      var recipients: ArrayList<String>? = call.argument("recipients")
      var ccrecipients: ArrayList<String>? = call.argument("ccrecipients")
      var bccrecipients: ArrayList<String>? = call.argument("bccrecipients")
      var body: String? = call.argument("body")
      var subject: String? = call.argument("subject")

      shareEmail(recipients, ccrecipients, bccrecipients, subject, body, result)
    } else if (call.method == "shareOnUrlCopy") {
      val textMsg: String? = call.argument("text")

      sendUrlCopy(textMsg, result)
    } else if (call.method == "setAdvertiserTracking") {
      setAdvertiserTracking(call, result)
    } else if (call.method == "logEvent") {
      logEvent(call, result)
    } else if (call.method == "logPurchase") {
      purchased(call, result)
    } else if (call.method == "logPushNotificationOpen") {
      pushNotificationOpen(call, result)
    } else {
      result.notImplemented()
    }
  }

  /**
   * share to Facebook
   *
   * @param url    String
   * @param quote    String
   * @param result Result
   */
  private fun shareToFacebook(url: String?, quote: String?, result: Result) {
//    FacebookSdk.sdkInitialize(activityContext)

    val shareDialog = ShareDialog (activity)
    val shareLinkContent = ShareLinkContent.Builder()
            .setContentUrl(Uri.parse(url))
            .setQuote(quote)
            .build()

    if (ShareDialog.canShow(ShareLinkContent::class.java)) {
      shareDialog.show(shareLinkContent)
      result.success("Success")
    }
  }

//  private fun instagramInstalled(): Boolean {
//    try {
//      if (activity != null) {
//        activity!!.getPackageManager()
//                .getApplicationInfo(INSTAGRAM_PACKAGE_NAME, 0)
//        return true
//      } else {
//        Log.d("App", "Instagram app is not installed on your device")
//      }
//    } catch (e: PackageManager.NameNotFoundException) {
//      return false
//    }
//    return false
//  }

  /**
   * share on SMS
   *
   * @param recipients ArrayList<String>
   * @param text    String
   * @param result Result
  </String> */
  private fun shareOnSMS(recipients: ArrayList<String>?, text: String?, result: Result) {
    try {
      val intent = Intent(Intent.ACTION_VIEW)
      intent.setData(Uri.parse("smsto:"))
      intent.setType("vnd.android-dir/mms-sms")
      intent.putExtra("address", recipients)
      intent.putExtra("sms_body", text)
      activity?.startActivity(Intent.createChooser(intent, "Send sms via:"))
      result.success("success")
    } catch (e: Exception) {
      result.success(e.localizedMessage)
    }
  }

  private fun shareOnTwitter(url: String?, text: String?, result: Result) {
    try {
//      val builder: TweetComposer.Builder = Builder(activity)
//              .text(text)
      val builder = TweetComposer.Builder(activity).text(text)

      if (url != null && url.length > 0) {
        builder.url(URL(url))
      }
      builder.show()
      result.success("success")
    } catch (e: MalformedURLException) {
      result.success(e.localizedMessage)
    }
  }

  private fun shareOnLine(text: String?, result: Result) {
    try {
      activityContext?.getPackageManager()?.getPackageInfo("jp.naver.line.android", 0)
      var lineMessage = "line://msg/text/$text"
      lineMessage = lineMessage.replace("\n", "")
      val intent = Intent()
      intent.setAction(Intent.ACTION_VIEW)
      intent.setData(Uri.parse(lineMessage))
      activity?.startActivity(intent)
      result.success("success")
    } catch (ignored: PackageManager.NameNotFoundException) {
      try {
        activity?.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=jp.naver.line.android")))
      } catch (e: ActivityNotFoundException) {
        activity?.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=jp.naver.line.android")))
      }
      result.success("line not install")
    }
  }

  /**
   * share on Email
   *
   * @param recipients ArrayList<String>
   * @param ccrecipients ArrayList<String>
   * @param bccrecipients ArrayList<String>
   * @param subject    String
   * @param body       String
   * @param result     Result
  </String></String></String> */
  private fun shareEmail(recipients: ArrayList<String>?, ccrecipients: ArrayList<String>?, bccrecipients: ArrayList<String>?, subject: String?, body: String?, result: Result) {
    val shareIntent = Intent(Intent.ACTION_SENDTO, Uri.fromParts(
            "mailto", "", null))
    shareIntent.putExtra(Intent.EXTRA_SUBJECT, subject)
    shareIntent.putExtra(Intent.EXTRA_TEXT, body)
    shareIntent.putExtra(Intent.EXTRA_EMAIL, recipients)
    shareIntent.putExtra(Intent.EXTRA_CC, ccrecipients)
    shareIntent.putExtra(Intent.EXTRA_BCC, bccrecipients)
    try {
      activity?.startActivity(Intent.createChooser(shareIntent, "Send email using..."))
      result.success("success")
    } catch (e: ActivityNotFoundException) {
      result.success("activity not found")
    }
  }

  private fun sendUrlCopy(text: String?, result: Result) {
    try {
      val clipboard: ClipboardManager = activityContext?.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
      val clip: ClipData = ClipData.newPlainText("", text)
      clipboard.setPrimaryClip(clip)
      result.success("success")
    } catch (e: Exception) {
      result.success(e.localizedMessage)
    }
  }

  private fun setAdvertiserTracking(call: MethodCall, result: Result) {
    result.success("success")
  }

  private fun purchased(call: MethodCall, result: Result) {
    var amount = (call.argument("amount") as? Double)?.toBigDecimal()
    var currency = Currency.getInstance(call.argument("currency") as? String)
    val parameters = call.argument("parameters") as? Map<String, Object>
    val parameterBundle = createBundleFromMap(parameters) ?: Bundle()

    appEventsLogger.logPurchase(amount, currency, parameterBundle)
    result.success("success")
  }

  private fun logEvent(call: MethodCall, result: Result) {
    val eventName = call.argument("name") as? String
    val parameters = call.argument("parameters") as? Map<String, Object>
    val valueToSum = call.argument("_valueToSum") as? Double

    if (valueToSum != null && parameters != null) {
      val parameterBundle = createBundleFromMap(parameters)
      appEventsLogger.logEvent(eventName, valueToSum, parameterBundle)
    } else if (valueToSum != null) {
      appEventsLogger.logEvent(eventName, valueToSum)
    } else if (parameters != null) {
      val parameterBundle = createBundleFromMap(parameters)
      appEventsLogger.logEvent(eventName, parameterBundle)
    } else {
      appEventsLogger.logEvent(eventName)
    }

    result.success("success")
  }

  private fun pushNotificationOpen(call: MethodCall, result: Result) {
    val action = call.argument("action") as? String
    val payload = call.argument("payload") as? Map<String, Object>
    val payloadBundle = createBundleFromMap(payload)

    if (action != null) {
      appEventsLogger.logPushNotificationOpen(payloadBundle, action)
    } else {
      appEventsLogger.logPushNotificationOpen(payloadBundle)
    }

    result.success("success")
  }


  private fun createBundleFromMap(parameterMap: Map<String, Any>?): Bundle? {
    if (parameterMap == null) {
      return null
    }

    val bundle = Bundle()
    for (jsonParam in parameterMap.entries) {
      val value = jsonParam.value
      val key = jsonParam.key
      if (value is String) {
        bundle.putString(key, value as String)
      } else if (value is Int) {
        bundle.putInt(key, value as Int)
      } else if (value is Long) {
        bundle.putLong(key, value as Long)
      } else if (value is Double) {
        bundle.putDouble(key, value as Double)
      } else if (value is Boolean) {
        bundle.putBoolean(key, value as Boolean)
      } else if (value is Map<*, *>) {
        val nestedBundle = createBundleFromMap(value as Map<String, Any>)
        bundle.putBundle(key, nestedBundle as Bundle)
      } else {
        throw IllegalArgumentException(
                "Unsupported value type: " + value.javaClass.kotlin)
      }
    }
    return bundle
  }

  companion object {
    private var callbackManager: CallbackManager? = null
    private const val INSTAGRAM_PACKAGE_NAME = "com.instagram.android"
    private const val WHATSAPP_PACKAGE_NAME = "com.whatsapp"
    private var registrar: PluginRegistry.Registrar? = null

    // private void onAttachedToEngine(Context context, BinaryMessenger messenger) {
    //   activityContext = context;
    // }
    // private FlutterMicroSvcUtilPlugin(Registrar registrar){
    //   this.registrar=registrar;
    // }

    private fun setRegistrar(_registrar: PluginRegistry.Registrar) {
      registrar = _registrar
    }

    /**
     * Plugin registration.
     */
//    fun registerWith(registrar: PluginRegistry.Registrar) {
//      val instance = FlutterMicroSvcUtilPlugin()
//      instance.onAttachedToEngine(registrar.messenger())
//      instance.activity = registrar.activity()
//      setRegistrar(registrar)
//    }
  }
}
