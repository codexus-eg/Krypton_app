// ignore_for_file: must_be_immutable

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:karim_online_platform/constants/colors.dart';
import 'package:upgrader/upgrader.dart';
import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/layout/home_layout.dart';
import 'package:karim_online_platform/models/user_model.dart';
import 'package:karim_online_platform/services/notification_service.dart';
import 'package:karim_online_platform/screens/auth/login/login_page.dart';
import 'package:karim_online_platform/screens/main/error_screen.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({
    super.key,
    required this.cubit,
  });

  PlatformCubit cubit;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // final _updater = ShorebirdUpdater();
  final bool _isUpdating = false;

  late final AnimationController _logoController;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _logoController.forward();

    /*
    if (Platform.isWindows) {
      _checkForUpdate();
    } else {
      */
    _initializeApp();
    //   }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

/*
  Future<void> _checkForUpdate() async {
    try {
      final status = await _updater.checkForUpdate(track: UpdateTrack.stable);

      if (status == UpdateStatus.outdated) {
        // فيه تحديث
        setState(() => _isUpdating = true);

        try {
          await _updater.update(track: UpdateTrack.stable);

          // بعد التحديث مباشرة نعمل Restart
          Restart.restartApp();
        } catch (e) {
          debugPrint('Error in update(): $e');
          _initializeApp();
        }
      } else {
        // الحالة: upToDate أو غير مدعوم
        _initializeApp();
      }
    } catch (e) {
      debugPrint('Error in checkForUpdate: $e');
      _initializeApp();
    }
  }
*/
  Future<void> _initializeApp() async {
    Future.delayed(const Duration(milliseconds: 3800)).then((value) {
      if (Constants.userBox.isEmpty) {
        Components.pushReplacement(
          context: context,
          widget: UpgradeAlert(
            barrierDismissible: false,
            showIgnore: false,
            showLater: false,
            child: LoginPage(),
          ),
        );
      } else {
        UserModel sm = Constants.userBox.get('user');

        if (sm.img == null || sm.img!.isEmpty) {
          Components.pushReplacement(
            context: context,
            widget: UpgradeAlert(
              barrierDismissible: false,
              showIgnore: false,
              showLater: false,
              child: LoginPage(),
            ),
          );
        } else {
          if ((sm.enabled == null || sm.enabled == true) &&
              (sm.isActive == null || sm.isActive == true)) {
            Components.pushReplacement(
              context: context,
              widget: UpgradeAlert(
                barrierDismissible: false,
                showIgnore: false,
                showLater: false,
                child: HomeLayout(
                  cubit: widget.cubit,
                  isFirstTime: true,
                  pageController: PageController(initialPage: 0),
                ),
              ),
            );

            // إذا فُتح التطبيق من إشعار (والتطبيق كان مغلقًا) — افتح الشاشة
            // المطلوبة فوق HomeLayout بعد التوجيه إليه، حتى يعود زر الرجوع للـ Home.
            final pending = NotificationService.consumePendingInitialMessage();
            if (pending != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NotificationService.handleNotificationNavigation(pending);
              });
            }
          } else {
            Components.pushReplacement(
              context: context,
              widget: UpgradeAlert(
                barrierDismissible: false,
                showIgnore: false,
                showLater: false,
                child: ErrorScreen(
                  cubit: widget.cubit,
                  status: sm.enabled == false
                      ? Constants.accountBlocked
                      : Constants.accountPending,
                ),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isUpdating) {
      return Scaffold(
        body: Container(
          /*
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage(
                Constants.wallpaberDark,
              ),
            ),
          ),
          */
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Updating..."),
                SizedBox(height: 16),
                CircularProgressIndicator(
                  color: AppColors.appGoldPrimaryColor,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final primaryColor = Components.setBgColor(widget.cubit.isDarkMode);

    return Scaffold(
      backgroundColor: const Color(0xfffafbfd),
      body: BlocBuilder<PlatformCubit, PlatformStates>(
        builder: (context, state) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Blurred zoomed copy fills the screen so there is no
                // empty space on the sides — no cropping concerns since
                // it's only used as a backdrop.
                Positioned.fill(
                  child: Image.asset(
                    'assets/splash.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // Full image — never cropped — on top of the blurred fill.
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Image.asset(
                      'assets/splash.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),

                // Animated progress indicator at bottom
                Positioned(
                  bottom: size.height * 0.08,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Center(
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
