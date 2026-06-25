import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'base_video_player.dart';

/// Vimeo player implementation using InAppWebView
class VimeoVideoPlayer extends BaseVideoPlayer {
  const VimeoVideoPlayer({
    super.key,
    required super.videoUrl,
    super.onVideoEnded,
    super.autoPlay = true,
    super.isDarkMode = false,
    super.progressColor,
  });

  @override
  VimeoVideoPlayerState createState() => VimeoVideoPlayerState();
}

class VimeoVideoPlayerState extends BaseVideoPlayerState<VimeoVideoPlayer> {
  String? _videoId;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _videoId = extractVideoId(widget.videoUrl);

    // Start in fullscreen mode for Vimeo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      _isFullScreen = true;
    });
  }

  @override
  String? extractVideoId(String url) {
    final regex = RegExp(r'vimeo\.com/(?:video/)?(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  @override
  bool get isFullScreen => _isFullScreen;

  @override
  void toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void pause() {
    // WebView-based player - pause handled internally
  }

  @override
  void play() {
    // WebView-based player - play handled internally
  }

  @override
  void disposePlayer() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return const Center(
        child: Text(
          'Invalid Vimeo URL',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri("https://player.vimeo.com/video/$_videoId"),
      ),
    );
  }
}
