import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_microsvc_util/flutter_microsvc_util.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = (await FlutterMicroSvcUtil.platformVersion);
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  shareOnFacebook(var url, var message) async {
    String result = (await FlutterMicroSvcUtil.share(
        type: ShareType.facebookWithoutImage, url: url, quote: message))!;
    print(result);
  }

  shareOnSMS(var message) async {
    String result = (await FlutterMicroSvcUtil.shareOnSMS(
        recipients: ["xxxxxx"], text: message))!;
    print(result);
  }

  shareOnTwitter(var url, var message) async {
    String result =
        (await FlutterMicroSvcUtil.shareOnTwitter(url: url, text: message))!;
    print(result);
  }

  shareOnLine(var message) async {
    String result = (await FlutterMicroSvcUtil.shareOnLine(text: message))!;
    print(result);
  }

  shareOnUrlCopy(var message) async {
    String result = (await FlutterMicroSvcUtil.shareOnUrlCopy(text: message))!;
    print(result);
  }

  shareOnOtherCopy(var message) async {
    String result =
        (await FlutterMicroSvcUtil.shareOnOtherCopy(text: message))!;
    print(result);
  }

  ///Build Context
  @override
  Widget build(BuildContext context) {
    var sharedMessage = 'GS Shop 공유하기';

    return MaterialApp(
      theme: ThemeData.light().copyWith(
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith(
                      (state) => Colors.blueAccent)))),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GS Shop - SNS Share'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 10)),
            Text(' Mobile O/S : $_platformVersion\n'),
            TextButton(
              child: Text("카카오톡 공유"),
              onPressed: () {
                Fluttertoast.showToast(
                    msg: "카카오톡 공유는 채널링 방식이 아니므로 플러터에서 연동해주세요.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
            ),
            TextButton(
              child: Text("카카오스토리 공유"),
              onPressed: () {
                Fluttertoast.showToast(
                    msg: "카카오스토리 공유는 채널링 방식이 아니므로 플러터에서 연동해주세요.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              },
            ),
            TextButton(
              child: Text("네이버 라인 공유"),
              onPressed: () {
                shareOnLine(sharedMessage);
              },
            ),
            TextButton(
              child: Text("SMS 공유"),
              onPressed: () {
                shareOnSMS(sharedMessage);
              },
            ),
            TextButton(
              child: Text("페이스북 공유"),
              onPressed: () {
                shareOnFacebook('http://m.gsshop.com', sharedMessage);
              },
            ),
            TextButton(
              child: Text("트위터 공유"),
              onPressed: () {
                shareOnTwitter('http://m.gsshop.com', sharedMessage);
              },
            ),
            TextButton(
              child: Text("URL 복사"),
              onPressed: () {
                shareOnUrlCopy(sharedMessage);
              },
            ),
            TextButton(
              child: Text("다른 앱으로 공유하기"),
              onPressed: () {
                shareOnOtherCopy(sharedMessage);
              },
            ),
          ],
        ),
      ),
    );
  }
}
