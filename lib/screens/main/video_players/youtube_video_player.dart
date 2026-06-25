import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'base_video_player.dart';

/// YouTube player implementation using youtube_player_flutter package
class YoutubeVideoPlayer extends BaseVideoPlayer {
  const YoutubeVideoPlayer({
    super.key,
    required super.videoUrl,
    super.onVideoEnded,
    super.autoPlay = true,
    super.isDarkMode = false,
    super.progressColor,
  });

  @override
  YoutubeVideoPlayerState createState() => YoutubeVideoPlayerState();
}

class YoutubeVideoPlayerState extends BaseVideoPlayerState<YoutubeVideoPlayer> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = extractVideoId(widget.videoUrl);
    if (_videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          hideThumbnail: true,
          forceHD: true,
          loop: false,
          hideControls: false,
          disableDragSeek: true,
          enableCaption: false,
        ),
      );
      _controller!.addListener(_onControllerUpdate);
    }
  }

  void _onControllerUpdate() {
    if (_controller!.value.isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  @override
  String? extractVideoId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  @override
  bool get isFullScreen => _controller?.value.isFullScreen ?? false;

  @override
  void toggleFullScreen() {
    _controller?.toggleFullScreenMode();
  }

  @override
  void pause() {
    _controller?.pause();
  }

  @override
  void play() {
    _controller?.play();
  }

  @override
  void disposePlayer() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: Text(
          'Invalid YouTube URL',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final progressColor = widget.progressColor ?? Colors.red;

    return Center(
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: progressColor,
        progressColors: ProgressBarColors(
          backgroundColor: Colors.grey,
          playedColor: progressColor,
          handleColor: progressColor,
        ),
        onEnded: (metaData) {
          pause();
          if (isFullScreen) {
            toggleFullScreen();
          }
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          widget.onVideoEnded?.call();
        },
      ),
    );
  }
}
