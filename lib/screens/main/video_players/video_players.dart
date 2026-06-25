/// Video Players - Multi-player support for video playback
///
/// Usage:
/// ```dart
/// // Auto-detect player from URL
/// final player = VideoPlayerFactory.createPlayerFromUrl(
///   videoUrl: 'https://www.youtube.com/watch?v=xxx',
///   onVideoEnded: () => Navigator.pop(context),
/// );
///
/// // Or specify player type explicitly
/// final player = VideoPlayerFactory.createPlayer(
///   type: VideoPlayerType.youtube,
///   videoUrl: 'https://www.youtube.com/watch?v=xxx',
/// );
/// ```
///
/// To add a new player:
/// 1. Add new type to [VideoPlayerType] enum
/// 2. Create a new player class extending [BaseVideoPlayer]
/// 3. Add URL detection logic in [VideoPlayerTypeExtension.fromUrl]
/// 4. Add case in [VideoPlayerFactory.createPlayer]
library video_players;

export 'base_video_player.dart';
export 'video_player_factory.dart';
export 'video_player_type.dart';
export 'vimeo_video_player.dart';
export 'youtube_video_player.dart';
