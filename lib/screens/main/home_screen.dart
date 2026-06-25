// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:karim_online_platform/constants/colors.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/constants/styles.dart';
import 'package:karim_online_platform/constants/widgets.dart';
import 'package:karim_online_platform/generated/l10n.dart';
import 'package:karim_online_platform/models/RequsetsModel.dart';
import 'package:karim_online_platform/models/purchases_widget_data.dart';
import 'package:karim_online_platform/models/video_details_model.dart';
import 'package:karim_online_platform/models/viedo_model.dart';
import 'package:karim_online_platform/network/local/shared_pref_helper.dart';
import 'package:karim_online_platform/screens/auth/login/login_page.dart';
import 'package:karim_online_platform/screens/main/edit_profile_screen.dart';
import 'package:karim_online_platform/screens/main/error_screen.dart';
import 'package:karim_online_platform/screens/main/lecture_details_screen.dart';
import 'package:karim_online_platform/screens/main/lectures_details_details_screen.dart';
import 'package:karim_online_platform/screens/main/revision_screen.dart.dart';
import 'package:karim_online_platform/screens/main/my_code_screen.dart';
import 'package:karim_online_platform/screens/main/my_lectures_screen.dart';
import 'package:karim_online_platform/screens/main/posts/posts_screen.dart';
import 'package:karim_online_platform/screens/main/requests.dart';
import 'package:karim_online_platform/screens/main/wallet/wallet_screen.dart';
import 'package:karim_online_platform/screens/main/ytp_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/user_model.dart';
import 'Chat2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformCubit, PlatformStates>(
      listener: (context, state) {
        if (state is PlatformDeleteAccountSuccessState) {
          Components.pushReplacement(
            context: context,
            widget: LoginPage(),
          );
        }
        if (state is PlatformAccountBlockedState) {
          Components.pushReplacement(
            context: context,
            widget: ErrorScreen(
              cubit: PlatformCubit.get(context),
              status: Constants.accountBlocked,
            ),
          );
        }
        if (state is PlatformAccountPendingState) {
          Components.pushReplacement(
            context: context,
            widget: ErrorScreen(
              cubit: PlatformCubit.get(context),
              status: Constants.accountPending,
            ),
          );
        }
      },
      builder: (context, state) {
        var cubit = PlatformCubit.get(context);
        UserModel um = Constants.userBox.get('user');

        return Container(
          /*
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage(
                cubit.isDarkMode
                    ? Constants.wallpaberDark
                    : Constants.wallpaberLight,
              ),
            ),
          ),
          */
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (!cubit.isGuest()) {
                  await cubit.getVideos();
                  await cubit.setUserDataLocally();
                  cubit.getPostsCount();
                } else {
                  return;
                }
              },
              color: Components.setBgColor(cubit.isDarkMode),
              child: SingleChildScrollView(
                controller: cubit.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(
                        context, um, cubit.isDarkMode, cubit.postsCount),
                    const SizedBox(height: 12.0),
                    // Recent Lectures Section
                    _buildSectionHeader(
                      context,
                      S.of(context).chapters,
                      cubit.isDarkMode,
                      icon: Icons.collections_bookmark_rounded,
                      count: cubit.videoList
                          .where((e) => e.isChapter == true)
                          .length,
                    ),
                    const SizedBox(height: 14.0),
                    _buildRecentLectures(context, cubit),
                    const SizedBox(height: 24.0),
                    // Quick Actions Grid
                    _buildSectionHeader(
                      context,
                      S.of(context).quick_actions,
                      cubit.isDarkMode,
                      icon: Icons.flash_on_rounded,
                    ),
                    const SizedBox(height: 14.0),

                    _buildQuickActionsGrid(context, cubit, um),
                    const SizedBox(height: 8.0),

                    // Continue Watching Section
                    ContinueWatchingSection(
                      isDarkMode: cubit.isDarkMode,
                      lectures: cubit.purchasedVideosList,
                    ),
/*
                    // Recent Requests Section
                    _buildSectionHeader(
                      context,
                      S.of(context).recent_requests,
                      cubit.isDarkMode,
                    ),
                    const SizedBox(height: 12.0),
                    _buildRecentRequests(context, cubit),
                    */
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, PlatformCubit cubit, UserModel um) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cubit.isDarkMode
              ? [
                  AppColors.appPrimaryColor,
                  AppColors.appPrimaryColor.withOpacity(0.8),
                  AppColors.appSecondaryColor.withOpacity(0.9),
                ]
              : [
                  AppColors.appSecondaryColor,
                  AppColors.appPrimaryColor.withOpacity(0.9),
                  AppColors.appPrimaryColor,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.appPrimaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28.0),
          onTap: () {
            if (!cubit.isGuest()) {
              Components.push(
                context: context,
                widget: EditProfileScreen(),
              );
            } else {
              Constants.showLoginDialog(
                isDarkMode: cubit.isDarkMode,
                context: context,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Avatar with animated border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100.0),
                    clipBehavior: Clip.antiAlias,
                    child: DefaultImage(
                      imgUrl: um.img!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 18.0),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context).hey,
                        style: AppTextStyles.body2Style.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${um.ar_fname} ${um.ar_sname} ${um.ar_thname}',
                        style: AppTextStyles.title1Style.copyWith(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Edit button with glow effect
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(
      BuildContext context, UserModel um, bool isDarkMode, int postsCount) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
      child: Row(
        children: [
          // std picture
          GestureDetector(
            onTap: () {
              Components.push(context: context, widget: EditProfileScreen());
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100.0),
                    clipBehavior: Clip.antiAlias,
                    child: DefaultImage(
                      imgUrl: um.img!,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Components.setBgColor(isDarkMode),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDarkMode ? AppColors.darkBgColor : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${S.of(context).hey} 👋',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  '${um.ar_fname} ${um.ar_sname} ${um.ar_thname}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          /*
          // Edit button
          GestureDetector(
            onTap: () {
              Components.push(context: context, widget: EditProfileScreen());
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit, size: 22),
            ),
          ),
       */
          // posts button

          Stack(
            alignment: AlignmentDirectional.topEnd,
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  Components.push(context: context, widget: PostsScreen());
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications, size: 22),
                ),
              ),
              if ((SharedPrefHelper.getData('postsCount') ?? 0) != postsCount)
                PositionedDirectional(
                  start: -4,
                  top: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDarkMode, {
    int? count,
    IconData? icon,
  }) {
    final primaryColor = Components.setBgColor(isDarkMode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: AppTextStyles.title2Style.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentLectures(BuildContext context, PlatformCubit cubit) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.84).clamp(280.0, 460.0);
    // Card = (cardWidth * 9/16) thumbnail + ~130 for title/subtitle/price/padding
    final listHeight = (cardWidth * 9 / 16) + 130;
    return SizedBox(
      height: listHeight,
      child: cubit.videoList.isEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cubit.isDarkMode
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Components.setBgColor(cubit.isDarkMode)
                            .withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.video_library_outlined,
                        size: 36,
                        color: Components.setBgColor(cubit.isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      S.of(context).no_chapters_yet,
                      style: AppTextStyles.body2Style.copyWith(
                        color: cubit.isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) => LectureCard(
                cubit: cubit,
                vm: cubit.videoList
                    .where((element) => element.isChapter == true)
                    .toList()[index],
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 12.0),
              itemCount: cubit.videoList
                  .where((element) => element.isChapter == true)
                  .length,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
            ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, PlatformCubit cubit, UserModel um) {
    final actions = <BuildIconCard>[
      if (um.groupName!.isNotEmpty && um.groupName != 'Online')
        BuildIconCard(
          isDarkMode: cubit.isDarkMode,
          icon: Icons.qr_code_scanner_rounded,
          name: S.of(context).attendance,
          isQr: true,
          color: const Color(0xFF7C5CFF),
          widget: MyCodeScreen(),
        ),
      if (!cubit.showDelAcc)
        BuildIconCard(
          isDarkMode: cubit.isDarkMode,
          icon: Icons.account_balance_wallet_rounded,
          name: S.of(context).wallet_code,
          color: const Color(0xFFFF8A3D),
          widget: WalletScreen(),
        ),
      if (!cubit.showDelAcc)
        BuildIconCard(
          isDarkMode: cubit.isDarkMode,
          icon: Icons.video_collection_rounded,
          name: S.of(context).purchased_videos,
          color: const Color(0xFF22C7A0),
          widget: MyLecturesScreen(cubit: cubit),
        ),
      BuildIconCard(
        isDarkMode: cubit.isDarkMode,
        icon: Icons.question_answer_rounded,
        name: S.of(context).ask_us,
        color: const Color(0xFFFF5C7A),
        widget: RequestsScreen(),
      ),
    ];

    const rowHeight = 110.0;
    const gap = 12.0;
    final rows = <Widget>[];
    for (int i = 0; i < actions.length; i += 2) {
      final isLastSingle = i + 1 >= actions.length;
      rows.add(
        SizedBox(
          height: rowHeight,
          child: isLastSingle
              ? actions[i]
              : Row(
                  children: [
                    Expanded(child: actions[i]),
                    const SizedBox(width: gap),
                    Expanded(child: actions[i + 1]),
                  ],
                ),
        ),
      );
      if (i + 2 < actions.length) rows.add(const SizedBox(height: gap));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
/*
  Widget _buildRecentRequests(BuildContext context, PlatformCubit cubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 10,
        child: cubit.requests1.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 32,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context).no_requests_yet,
                      style: AppTextStyles.body2Style.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemBuilder: (context, index) => RequestCard(
                  statusColor: cubit.requests1[index].state == 'pending'
                      ? Colors.orange
                      : cubit.requests1[index].state == 'taken'
                          ? Colors.green
                          : Colors.grey,
                  isDarkMode: cubit.isDarkMode,
                  request: cubit.requests1[index],
                  cubb: cubit,
                  index: index,
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12.0),
                itemCount:
                    cubit.requests1.length >= 2 ? 2 : cubit.requests1.length,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
              ),
      ),
    );
  }
*/
}

class BuildIconCard extends StatelessWidget {
  BuildIconCard({
    super.key,
    required this.isDarkMode,
    this.widget,
    required this.icon,
    required this.name,
    this.isQr,
    this.onPressed,
    this.color,
  });
  UserModel um = Constants.userBox.get('user');

  bool isDarkMode;
  Widget? widget;
  IconData icon;
  String name;
  bool? isQr;
  Color? color;
  void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Components.setBgColor(isDarkMode);
    final cardColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);
    final labelColor = isDarkMode ? Colors.white : const Color(0xff1a1a1a);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isQr == true && um.code == Constants.guest) {
              Constants.showLoginDialog(
                isDarkMode: isDarkMode,
                context: context,
              );
            } else {
              if (widget != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => widget!,
                  ),
                );
              } else {
                onPressed;
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContinueWatchingSection extends StatelessWidget {
  final bool isDarkMode;
  final List<PurchasesWidgetData> lectures;

  const ContinueWatchingSection({
    super.key,
    required this.isDarkMode,
    required this.lectures,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final primaryColor = Components.setBgColor(isDarkMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.play_circle_fill_rounded,
                  color: primaryColor, size: 20),
              const SizedBox(width: 6),
              Text(
                S.of(context).continue_watching,
                style: AppTextStyles.title2Style.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          lectures.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          size: 32,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        S.of(context).no_videos_yet,
                        style: AppTextStyles.body2Style.copyWith(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lectures.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => BuildCard(
                    width: screenWidth - 32,
                    lecture: lectures[index],
                    isDarkMode: isDarkMode,
                  ),
                ),
        ],
      ),
    );
  }
}

class BuildCard extends StatelessWidget {
  const BuildCard({
    super.key,
    required this.width,
    required this.lecture,
    required this.isDarkMode,
  });

  final double width;
  final PurchasesWidgetData lecture;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Components.setBgColor(isDarkMode);
    final cardColor = isDarkMode ? AppColors.darkBorder : Colors.white;
    final titleColor = isDarkMode ? Colors.white : const Color(0xff1a1a1a);
    final progress = lecture.avaWatches == 0
        ? 0.0
        : (lecture.stdWatches / lecture.avaWatches).clamp(0.0, 1.0);

    void openLecture() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LectureDetailsDetailsScreen(
            key: ValueKey(lecture.lectureId),
            price: lecture.price,
            dep: lecture.lectureDep,
            thumbnail: lecture.lectureImg,
            title: lecture.lectureTitle,
            lecId: lecture.lectureId,
            subTitle: lecture.lectureSubTitle,
            chapId: lecture.chapterId,
          ),
          settings: const RouteSettings(name: 'lectureDetails'),
        ),
      );
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: openLecture,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            /*
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          */
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 72,
                    child: DefaultImage(
                      imgUrl: lecture.lectureImg,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lecture.lectureTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: primaryColor.withValues(alpha: 0.18),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    /*
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
               */
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LectureCard extends StatelessWidget {
  LectureCard({
    super.key,
    required this.vm,
    required this.cubit,
  });

  VideoModel vm;
  PlatformCubit cubit;
/*
  String _formatDate(DateTime d) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final month = (d.month >= 1 && d.month <= 12) ? months[d.month - 1] : '';
    return '${d.day} $month';
  }
*/
  @override
  Widget build(BuildContext context) {
    final primaryColor = Components.setBgColor(cubit.isDarkMode);
    final cardColor = cubit.isDarkMode ? AppColors.darkBorder : Colors.white;
    final titleColor =
        cubit.isDarkMode ? Colors.white : const Color(0xff1a1a1a);
    final subtitleColor = cubit.isDarkMode
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);
    final hasDiscount =
        vm.prevPrice != null && vm.price != null && vm.prevPrice! > vm.price!;

    return Container(
      width: (MediaQuery.of(context).size.width * 0.84).clamp(280.0, 460.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: cubit.isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoDetails(
                  chapId: vm.chapId,
                  thumbnail: vm.thumbnail,
                  title: vm.title,
                  subTitle: vm.subTitle,
                  cubit: cubit,
                  price: vm.price,
                  prevPrice: vm.prevPrice,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail (16:9) ──────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20.0)),
                    child: DefaultImage(
                      imgUrl: vm.thumbnail,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Discount badge (top-start)
                  if (hasDiscount && !cubit.showDelAcc)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(((vm.prevPrice! - vm.price!) / vm.prevPrice!) * 100).round()}%-',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Content (title, subtitle, price) ──────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          vm.subTitle ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                      // Price row
                      if (vm.price != null && !cubit.showDelAcc)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${vm.price}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              S.of(context).egp,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${vm.prevPrice} ${S.of(context).egp}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: subtitleColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
class RequestCard extends StatelessWidget {
  final Color statusColor;
  final bool isDarkMode;
  final RequsetsModel request;
  final int index;
  final PlatformCubit cubb;

  const RequestCard({
    super.key,
    required this.statusColor,
    required this.isDarkMode,
    required this.request,
    required this.index,
    required this.cubb,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (request.state == "taken" || request.state == "ended") {
          PlatformCubit.student = true;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                request: request,
                title: '${S.of(context).request} ${index + 1}',
              ),
            ),
          );
        } else {
          requestOverlay2(
            request,
            context,
            '${S.of(context).request} ${index + 1}',
            cubb,
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2.2,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkBorder : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      request.state == 'pending'
                          ? Icons.hourglass_top_rounded
                          : Icons.check_circle_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.request,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2Style.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (statusColor != Colors.transparent)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
*/
