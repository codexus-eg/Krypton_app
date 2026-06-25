/// Enum representing supported video player types
enum VideoPlayerType {
  youtube,
  vimeo,
  // Add more player types here as needed
  // e.g., dailymotion, custom, etc.
}

/// Extension to get player information
extension VideoPlayerTypeExtension on VideoPlayerType {
  String get name {
    switch (this) {
      case VideoPlayerType.youtube:
        return 'YouTube';
      case VideoPlayerType.vimeo:
        return 'Vimeo';
    }
  }

  /// Detect player type from URL
  static VideoPlayerType? fromUrl(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return VideoPlayerType.youtube;
    } else if (url.contains('vimeo.com')) {
      return VideoPlayerType.vimeo;
    }
    return null;
  }
}
