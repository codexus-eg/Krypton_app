import 'package:flutter/material.dart';

import 'base_video_player.dart';
import 'video_player_type.dart';
import 'vimeo_video_player.dart';
import 'youtube_video_player.dart';

/// Factory class to create video player instances based on type or URL
class VideoPlayerFactory {
  /// Create a video player widget based on the specified type
  static BaseVideoPlayer createPlayer({
    required VideoPlayerType type,
    required String videoUrl,
    Key? key,
    VoidCallback? onVideoEnded,
    bool autoPlay = true,
    bool isDarkMode = false,
    Color? progressColor,
  }) {
    switch (type) {
      case VideoPlayerType.youtube:
        return YoutubeVideoPlayer(
          key: key,
          videoUrl: videoUrl,
          onVideoEnded: onVideoEnded,
          autoPlay: autoPlay,
          isDarkMode: isDarkMode,
          progressColor: progressColor,
        );
      case VideoPlayerType.vimeo:
        return VimeoVideoPlayer(
          key: key,
          videoUrl: videoUrl,
          onVideoEnded: onVideoEnded,
          autoPlay: autoPlay,
          isDarkMode: isDarkMode,
          progressColor: progressColor,
        );
    }
  }

  /// Create a video player widget by auto-detecting the type from URL
  static BaseVideoPlayer? createPlayerFromUrl({
    required String videoUrl,
    Key? key,
    VoidCallback? onVideoEnded,
    bool autoPlay = true,
    bool isDarkMode = false,
    Color? progressColor,
  }) {
    final type = VideoPlayerTypeExtension.fromUrl(videoUrl);
    if (type == null) return null;

    return createPlayer(
      type: type,
      videoUrl: videoUrl,
      key: key,
      onVideoEnded: onVideoEnded,
      autoPlay: autoPlay,
      isDarkMode: isDarkMode,
      progressColor: progressColor,
    );
  }

  /// Check if a URL is supported by any player
  static bool isUrlSupported(String url) {
    return VideoPlayerTypeExtension.fromUrl(url) != null;
  }

  /// Get the player type for a given URL
  static VideoPlayerType? getTypeFromUrl(String url) {
    return VideoPlayerTypeExtension.fromUrl(url);
  }
}
