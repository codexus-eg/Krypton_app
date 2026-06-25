import 'package:flutter/material.dart';

/// Abstract base class for all video player implementations
abstract class BaseVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoEnded;
  final bool autoPlay;
  final bool isDarkMode;
  final Color? progressColor;

  const BaseVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoEnded,
    this.autoPlay = true,
    this.isDarkMode = false,
    this.progressColor,
  });
}

/// Abstract state for video players with common functionality
abstract class BaseVideoPlayerState<T extends BaseVideoPlayer> extends State<T> {
  /// Extract video ID from URL
  String? extractVideoId(String url);

  /// Check if player is in fullscreen mode
  bool get isFullScreen;

  /// Toggle fullscreen mode
  void toggleFullScreen();

  /// Pause the video
  void pause();

  /// Play the video
  void play();

  /// Dispose player resources
  void disposePlayer();
}
