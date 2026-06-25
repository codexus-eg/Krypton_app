/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class YtpPlayerScreen extends StatefulWidget {
  YtpPlayerScreen({super.key, required this.videoUrl, required this.cubit});
  String videoUrl = '';
  PlatformCubit cubit;
  @override
  State<YtpPlayerScreen> createState() => _YtpPlayerScreenState();
}

class _YtpPlayerScreenState extends State<YtpPlayerScreen> {
  late final WebViewController _controller;
  /*
  bool isFullScreen = false;
  void toggleFullScreen() async {
    if (!isFullScreen) {
      // تحويل إلى Landscape
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      // الرجوع للوضع الطبيعي
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    setState(() => isFullScreen = !isFullScreen);
  }

  @override
  void dispose() {
    // تأكد إن الاتجاه بيرجع طبيعي لما نخرج
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
*/
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse("https://player.vimeo.com/video/1131239390"),
      );

    // بدء التشغيل في وضع ملء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            if (MediaQuery.of(context).orientation == Orientation.landscape) {
              // تأكد إن الاتجاه بيرجع طبيعي لما نخرج
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitUp]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            } else {
              Navigator.pop(context);
            }
          },
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              /*
              // 🔘 زر ملء الشاشة
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: Icon(
                    isFullScreen ? null : Icons.back_hand,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () {},
                ),
              ),
          */
            ],
          ),
        ),
      ),
    );
  }
}
*/
