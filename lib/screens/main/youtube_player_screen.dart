// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:karim_online_platform/widgets/app_status_dialog.dart';

import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/constants/widgets.dart';
import 'package:karim_online_platform/models/user_model.dart';
import 'package:karim_online_platform/network/local/shared_pref_helper.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  YoutubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.cubit,
  });
  String videoUrl;
  PlatformCubit cubit;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  String? videoUrl;

  YoutubePlayerController? _ytController;

  final webViewKey = GlobalKey();

  String? extractVimeoId(String url) {
    final regex = RegExp(r'vimeo\.com/(?:video/)?(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.contains('vimeo') &&
        !widget.videoUrl.contains('player.vimeo')) {
      String? videoId = extractVimeoId(widget.videoUrl);
      if (videoId != null) {
        videoUrl = 'https://player.vimeo.com/video/$videoId';
      }

      // بدء التشغيل في وضع ملء الشاشة
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      });
    } else if (widget.videoUrl.contains('youtu')) {
      String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            hideThumbnail: true,
            forceHD: true,
            loop: false,
            hideControls: false,
            disableDragSeek: true,
            enableCaption: false,
          ),
        );
        _ytController!.addListener(() {
          if (_ytController!.value.isFullScreen) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                overlays: []);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                overlays: SystemUiOverlay.values);
          }
        });
      }
    } else {
      videoUrl = widget.videoUrl;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startMoving();
      if (!Platform.isWindows) {
        await Constants.noScreenshot.screenshotOff();
      }
    });
  }

  void _startMoving() {
    _moveTimer?.cancel();
// Cancel any existing timer
    _moveTimer = Timer.periodic(Duration(seconds: 7), (timer) {
      if (!mounted) return;
      // Check if widget is still mounted
      final screenSize = MediaQuery.of(context).size;
      final maxLeft = screenSize.width - widgetWidth;
      final maxTop = screenSize.height - widgetHeight;
      setState(() {
        _left = _random.nextDouble() * maxLeft;
        _top = _random.nextDouble() * maxTop;
      });
    });
  }

  double _left = 50;
  double _top = 100;
  final Random _random = Random();
  final double widgetWidth = 100;
  final double widgetHeight = 100;
  Timer? _moveTimer;
  // Declare timer as class variable
  @override
  void dispose() async {
    _moveTimer?.cancel();
    _ytController?.dispose();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isWindows) {
      await Constants.noScreenshot.screenshotOn();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformCubit, PlatformStates>(
      builder: (context, state) {
        var cubit = PlatformCubit.get(context);
        UserModel sm = Constants.userBox.get('user');

        return Scaffold(
          extendBodyBehindAppBar: true, // يخلي الـ Stack يملأ الشاشة
          backgroundColor: Colors.black, // مهم عشان مفيش وميض أبيض

          body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) {
                return;
              }
              if (!widget.videoUrl.contains('youtu')) {
                if (MediaQuery.of(context).orientation ==
                    Orientation.landscape) {
                  // تأكد إن الاتجاه بيرجع طبيعي لما نخرج
                  SystemChrome.setPreferredOrientations(
                      [DeviceOrientation.portraitUp]);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                } else {
                  AppStatusDialog.show(
                    context: context,
                    status: AppDialogStatus.warning,
                    title: SharedPrefHelper.getData('isAr') ?? true
                        ? 'هل أنت متأكد من الخروج؟'
                        : 'Are You Sure to Exit?',
                    primaryActionText: SharedPrefHelper.getData('isAr') ?? true
                        ? 'خروج'
                        : 'Exit',
                    onPrimaryAction: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    message: '',
                  );
                }
              } else {
                if (_ytController!.value.isFullScreen) {
                  _ytController!.toggleFullScreenMode();
                } else {
                  AppStatusDialog.show(
                    context: context,
                    status: AppDialogStatus.warning,
                    title: 'خلي بالك',
                    message: SharedPrefHelper.getData('isAr') ?? true
                        ? 'هل أنت متأكد من الخروج؟'
                        : 'Are You Sure to Exit?',
                    primaryActionText: SharedPrefHelper.getData('isAr') ?? true
                        ? 'خروج'
                        : 'Exit',
                    onPrimaryAction: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  );
                }
              }
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (MediaQuery.of(context).orientation ==
                          Orientation.portrait ||
                      !(_ytController?.value.isFullScreen ?? false))
                    DefaultBackBtn(
                      color: Colors.white,
                      onTap: () {
                        if (widget.videoUrl.contains('vimeo')) {
                          if (Platform.isWindows ||
                              MediaQuery.of(context).orientation ==
                                  Orientation.portrait) {
                            AppStatusDialog.show(
                              context: context,
                              status: AppDialogStatus.warning,
                              title: 'خلي بالك',
                              message: SharedPrefHelper.getData('isAr') ?? true
                                  ? 'هل أنت متأكد من الخروج؟'
                                  : 'Are You Sure to Exit?',
                              primaryActionText:
                                  SharedPrefHelper.getData('isAr') ?? true
                                      ? 'خروج'
                                      : 'Exit',
                              onPrimaryAction: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                            );
                          } else {
                            // تأكد إن الاتجاه بيرجع طبيعي لما نخرج
                            SystemChrome.setPreferredOrientations(
                                [DeviceOrientation.portraitUp]);
                            SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge);
                          }
                        } else {
                          AppStatusDialog.show(
                            context: context,
                            status: AppDialogStatus.warning,
                            title: 'خلي بالك',
                            message: SharedPrefHelper.getData('isAr') ?? true
                                ? 'هل أنت متأكد من الخروج؟'
                                : 'Are You Sure to Exit?',
                            primaryActionText:
                                SharedPrefHelper.getData('isAr') ?? true
                                    ? 'خروج'
                                    : 'Exit',
                            onPrimaryAction: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          );
                        }
                      },
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (!widget.videoUrl.contains('youtu'))
                          InAppWebView(
                            key: webViewKey,
                            initialSettings: InAppWebViewSettings(
                              iframeAllowFullscreen: true,
                              allowsInlineMediaPlayback: true,
                              mediaPlaybackRequiresUserGesture: false,
                              disableDefaultErrorPage: true,
                              disableLongPressContextMenuOnLinks: true,
                            ),
                            initialUrlRequest: URLRequest(
                              url: WebUri(
                                videoUrl ?? widget.videoUrl,
                              ),
                            ),
                            onEnterFullscreen: (controller) {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeRight,
                                DeviceOrientation.landscapeLeft,
                              ]);
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.immersiveSticky,
                              );
                            },
                            onExitFullscreen: (controller) {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.portraitUp,
                              ]);
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge,
                              );
                            },
                          ),
                        if (widget.videoUrl.contains('youtu'))
                          Center(
                            child: YoutubePlayer(
                              controller: _ytController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor:
                                  Components.setBgColor(cubit.isDarkMode),
                              progressColors: ProgressBarColors(
                                backgroundColor: Colors.grey,
                                playedColor:
                                    Components.setBgColor(cubit.isDarkMode),
                                handleColor:
                                    Components.setBgColor(cubit.isDarkMode),
                              ),
                              onEnded: (metaData) {
                                _ytController!.pause();
                                if (_ytController!.value.isFullScreen) {
                                  _ytController!.toggleFullScreenMode();
                                }
                                SystemChrome.setEnabledSystemUIMode(
                                    SystemUiMode.manual,
                                    overlays: SystemUiOverlay.values);

                                Navigator.pop(context);
                              },
                            ),
                          ),
                        Positioned(
                          left: _left,
                          top: _top,
                          child: Opacity(
                            opacity: 0.7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sm.code!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/*

// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/constants/widgets.dart';
import 'package:karim_online_platform/models/user_model.dart';
import 'package:karim_online_platform/network/local/shared_pref_helper.dart';

import 'video_players/video_players.dart';

/// Video Player Screen with multi-player support
///
/// Supports YouTube, Vimeo, and can be easily extended for more players.
/// The player type is auto-detected from the URL or can be specified explicitly.
class YoutubePlayerScreen extends StatefulWidget {
  YoutubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.cubit,
    this.playerType, // Optional: specify player type, otherwise auto-detected
  });

  String videoUrl;
  PlatformCubit cubit;
  VideoPlayerType? playerType;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late VideoPlayerType _playerType;
  final GlobalKey<BaseVideoPlayerState> _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Determine player type: use specified type or auto-detect from URL
    _playerType = widget.playerType ??
        VideoPlayerFactory.getTypeFromUrl(widget.videoUrl) ??
        VideoPlayerType.youtube;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startMoving();
      if (!Platform.isWindows) {
        await Constants.noScreenshot.screenshotOff();
      }
    });
  }

  void _startMoving() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(Duration(seconds: 7), (timer) {
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      final maxLeft = screenSize.width - widgetWidth;
      final maxTop = screenSize.height - widgetHeight;
      setState(() {
        _left = _random.nextDouble() * maxLeft;
        _top = _random.nextDouble() * maxTop;
      });
    });
  }

  double _left = 50;
  double _top = 100;
  final Random _random = Random();
  final double widgetWidth = 100;
  final double widgetHeight = 100;
  Timer? _moveTimer;

  @override
  void dispose() async {
    _moveTimer?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isWindows) {
      await Constants.noScreenshot.screenshotOn();
    }
    super.dispose();
  }

  /// Get the current player state for controlling playback
  BaseVideoPlayerState? get _playerState => _playerKey.currentState;

  /// Handle back navigation based on player state
  void _handleBackNavigation(BuildContext context, PlatformCubit cubit) {
    final isFullScreen = _playerState?.isFullScreen ?? false;
    final isVimeo = _playerType == VideoPlayerType.vimeo;

    if (isVimeo) {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        _showExitDialog(context, cubit);
      }
    } else {
      if (isFullScreen) {
        _playerState?.toggleFullScreen();
      } else {
        _showExitDialog(context, cubit);
      }
    }
  }

  void _showExitDialog(BuildContext context, PlatformCubit cubit) {
    Widgets.defaultAlertDialog(
      isDarkMode: cubit.isDarkMode,
      context: context,
      type: QuickAlertType.warning,
      txt: SharedPrefHelper.getData('isAr') ?? true
          ? 'هل أنت متأكد من الخروج؟'
          : 'Are You Sure to Exit?',
      confirmBtnText: SharedPrefHelper.getData('isAr') ?? true ? 'خروج' : 'Exit',
      onConfirmBtnTap: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlatformCubit, PlatformStates>(
      builder: (context, state) {
        var cubit = PlatformCubit.get(context);
        UserModel sm = Constants.userBox.get('user');

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              _handleBackNavigation(context, cubit);
            },
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (MediaQuery.of(context).orientation ==
                          Orientation.portrait ||
                      !(_playerState?.isFullScreen ?? false))
                    DefaultBackBtn(
                      color: Colors.white,
                      onTap: () => _handleBackNavigation(context, cubit),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        // Create video player using factory
                        VideoPlayerFactory.createPlayer(
                          key: _playerKey,
                          type: _playerType,
                          videoUrl: widget.videoUrl,
                          autoPlay: true,
                          isDarkMode: cubit.isDarkMode,
                          progressColor: Components.setBgColor(cubit.isDarkMode),
                          onVideoEnded: () {
                            Navigator.pop(context);
                          },
                        ),
                        // Watermark overlay
                        Positioned(
                          left: _left,
                          top: _top,
                          child: Opacity(
                            opacity: 0.7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sm.code!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
*/
