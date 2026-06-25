// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:karim_online_platform/constants/payment_options.dart';
import 'package:karim_online_platform/constants/widgets.dart';
import 'package:karim_online_platform/widgets/app_status_dialog.dart';
import 'package:parent_child_checkbox/parent_child_checkbox.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'package:karim_online_platform/bloc/platform_cubit.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/generated/l10n.dart';
import 'package:karim_online_platform/screens/main/lectures_details_details_screen.dart';
import 'package:karim_online_platform/screens/quiz/quiz_answs_screen.dart';
import 'package:karim_online_platform/screens/quiz/start_quiz_screen.dart';

import '../../constants/colors.dart';
import '../../constants/constants.dart';
import '../../constants/styles.dart';
import '../../models/question_bank_model.dart';
import '../../models/quiz_model.dart';
import '../../models/std_quiz_model.dart';
import '../../models/user_model.dart';
import '../questions_bank/questionbank_answs_screen.dart';
import '../questions_bank/start_questionbank_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  var fkey = GlobalKey<FormState>();

  bool isLoading = false;

  Map<String?, List<String?>> chapters = {};
  TextEditingController quizController = TextEditingController();

  TextEditingController queNumsController = TextEditingController();

  var scaffoldKey = GlobalKey<ScaffoldState>();
  String selectedType = 'الكل'; // 👈 الافتراضي يعرض الكل

  @override
  void initState() {
    super.initState();
    final cubit = PlatformCubit.get(context);
    if (!cubit.isLecturesExams) {
      cubit.getAvaExams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformCubit, PlatformStates>(
      listener: (context, state) {
        if (state is PlatformCheckPurchaseQuizCodeLoadingState ||
            state is PlatformCheckQuizLoadingState ||
            state is PlatformBuyQuizWalletLoadingState) {
          isLoading = true;
        }
        if (state is PlatformBuyQuizWalletFailState) {
          isLoading = false;
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.error,
            message: state.err,
            title: 'خلي بالك',
          );
        }
        if (state is PlatformBuyQuizWalletSuccessState) {
          isLoading = false;
          Navigator.pop(context);
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.success,
            title: 'تم بنجاح',
            message: 'تم شراء الامتحان بنجاح',
          );
        }

        if (state is PlatformCheckPurchaseQuizCodeFailState) {
          isLoading = false;
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.error,
            message: state.err,
            title: 'خلي بالك',
          );
        }
        if (state is PlatformCheckPurchaseQuizCodeSuccessState) {
          isLoading = false;
          Navigator.pop(context);
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.success,
            title: 'تم بنجاح',
            message: 'تم شراء الامتحان بنجاح',
          );
        }

        if (state is PlatformCheckQuizFailState) {
          isLoading = false;
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.error,
            message: state.err,
            title: 'خلي بالك',
          );
        }
        if (state is PlatformCheckQuizSuccessState) {
          isLoading = false;
          Components.push(
              context: context, widget: StartQuizScreen(title: state.title));
        }
      },
      builder: (context, state) {
        List<StdQuizModel>? filteredQuestions = [];
        UserModel? um = Constants.userBox.get('user');

        var cubit = PlatformCubit.get(context);

        filteredQuestions = um?.stdQuizes?.values.where((quiz) {
              if (cubit.isLecturesExams) {
                return quiz.id.contains(',');
              } else {
                return !quiz.id.contains(',') && quiz.id.isNotEmpty;
              }
            }).toList() ??
            [];
        filteredQuestions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        // }

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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        S.of(context).quizs,
                        style: AppTextStyles.headStyle.copyWith(
                          fontSize: 36,
                        ),
                      ),
                    ],
                  ),
                  _QuizFilterBar(
                    labels: [
                      S.of(context).shamel_quizs,
                      S.of(context).lecture_exams,
                    ],
                    icons: const [
                      Icons.fact_check_rounded,
                      Icons.school_rounded,
                    ],
                    selectedIndex: cubit.isLecturesExams ? 1 : 0,
                    isDarkMode: cubit.isDarkMode,
                    onSelected: (index) {
                      final current = cubit.isLecturesExams ? 1 : 0;
                      if (index == current) return;
                      cubit.changeLecturesExams();
                      if (index == 0) {
                        cubit.getAvaExams();
                      }
                    },
                  ),
                  const SizedBox(height: 12.0),
                  Expanded(
                    child: _buildBody(
                      context: context,
                      cubit: cubit,
                      answeredQuizzes: filteredQuestions ?? [],
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

  Widget _buildBody({
    required BuildContext context,
    required PlatformCubit cubit,
    required List<StdQuizModel> answeredQuizzes,
  }) {
    if (cubit.isLecturesExams) {
      return _buildAnsweredList(
        context: context,
        cubit: cubit,
        answeredQuizzes: answeredQuizzes,
      );
    }

    final avaExams = cubit.avaExams;
    final hasAva = avaExams.isNotEmpty;
    final hasAnswered = answeredQuizzes.isNotEmpty;

    if (!hasAva && !hasAnswered) {
      return _buildEmptyState(
        context: context,
        cubit: cubit,
        onRefresh: () => cubit.getAvaExams(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.getAvaExams(),
      child: ListView(
        controller: cubit.scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          if (hasAva) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                S.of(context).available_exams,
                style: AppTextStyles.title2Style,
              ),
            ),
            ...avaExams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AvailableExamTile(
                  cubit: cubit,
                  quiz: exam,
                  onTap: () => _onAvailableExamTap(context, cubit, exam),
                ),
              ),
            ),
          ],
          if (hasAnswered) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                S.of(context).answered_exams,
                style: AppTextStyles.title2Style,
              ),
            ),
            ...answeredQuizzes.map(
              (quiz) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _wrapAnsweredTile(context, cubit, quiz),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnsweredList({
    required BuildContext context,
    required PlatformCubit cubit,
    required List<StdQuizModel> answeredQuizzes,
  }) {
    if (answeredQuizzes.isEmpty) {
      return _buildEmptyState(
        context: context,
        cubit: cubit,
        onRefresh: () => cubit.setUserDataLocally(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.setUserDataLocally(),
      color: Components.setBgColor(cubit.isDarkMode),
      child: ListView.separated(
        controller: cubit.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) =>
            _wrapAnsweredTile(context, cubit, answeredQuizzes[index]),
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
        itemCount: answeredQuizzes.length,
      ),
    );
  }

  /// Modern, scrollable empty state that keeps pull-to-refresh available even
  /// when there is no data to show.
  Widget _buildEmptyState({
    required BuildContext context,
    required PlatformCubit cubit,
    required Future<void> Function() onRefresh,
  }) {
    final primary = Components.setBgColor(cubit.isDarkMode);
    final mutedColor = cubit.isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.45);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            padding:
                const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: cubit.isDarkMode
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.quiz_outlined,
                    size: 44,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 18.0),
                Text(
                  S.of(context).no_quizes_yet,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title2Style.copyWith(
                    color: cubit.isDarkMode
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: mutedColor),
                    const SizedBox(width: 6.0),
                    Text(
                      'اسحب للأسفل للتحديث',
                      style: AppTextStyles.body2Style.copyWith(
                        fontSize: 13.0,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapAnsweredTile(
    BuildContext context,
    PlatformCubit cubit,
    StdQuizModel quiz,
  ) {
    return GestureDetector(
      onTap: () => _onAnsweredTap(context, cubit, quiz),
      child: QuizTile(
        isDarkMode: cubit.isDarkMode,
        date: quiz.dateTime,
        chapters: chapters,
        id: quiz.id,
        grade: quiz.degree,
        fullMark: quiz.fullMark,
        title: quiz.title,
        questions: quiz.questionNums,
      ),
    );
  }

  Future<void> _onAnsweredTap(
    BuildContext context,
    PlatformCubit cubit,
    StdQuizModel quiz,
  ) async {
    /*
    if (cubit.isQuestionBank) {
      Components.push(
        context: context,
        widget: QuestionbankAnswersScreen(
          title: quiz.title,
          id: quiz.id,
        ),
      );
      return;
    }
*/
    bool showDegree = await cubit.getShowDegree(quizId: quiz.id);
    if (quiz.id.contains(',')) {
      if (showDegree) {
        int minDegree = await cubit.getMinDegree(quizId: quiz.id);
        if (quiz.degree >= minDegree) {
          Components.push(
            context: context,
            widget: QuizAnswersScreen(
              title: quiz.title,
              quizCode: quiz.id,
            ),
          );
        } else {
          AppStatusDialog.show(
            context: context,
            status: AppDialogStatus.info,
            title: 'خلي بالك',
            message: S.of(context).should_get_min_degree,
          );
        }
      } else {
        AppStatusDialog.show(
          context: context,
          status: AppDialogStatus.info,
          title: 'خلي بالك',
          message: S.of(context).wait_to_get_degree,
        );
      }
    } else {
      if (showDegree) {
        Components.push(
          context: context,
          widget: QuizAnswersScreen(
            title: quiz.title,
            quizCode: quiz.id,
          ),
        );
      } else {
        AppStatusDialog.show(
          context: context,
          status: AppDialogStatus.info,
          title: 'خلي بالك',
          message: S.of(context).wait_to_get_degree,
        );
      }
    }
  }

  Future<void> _onAvailableExamTap(
    BuildContext context,
    PlatformCubit cubit,
    QuizModel quiz,
  ) async {
    final isConnected = await Components.checkConnection();
    UserModel um = Constants.userBox.get('user');
    if (!isConnected) {
      AppStatusDialog.show(
        context: context,
        status: AppDialogStatus.error,
        title: 'مفيش نت',
        message: S.of(context).no_internet,
      );
      return;
    }
    if (Constants.userBox.get('user').code == 'guest') {
      Constants.showLoginDialog(
        isDarkMode: cubit.isDarkMode,
        context: context,
      );
      return;
    }
    if (!isLoading) {
      if (cubit.showDelAcc) {
        cubit.setQuizModel(quiz);
        Components.push(
          context: context,
          widget: StartQuizScreen(
            title: quiz.title,
          ),
        );
        return;
      }
      if ((quiz.price ?? 0) > 0) {
        if (um.stdQuizes?[quiz.id] != null) {
          if (um.stdQuizes?[quiz.id]!.status == 'paid') {
            cubit.setQuizModel(quiz);
            Components.push(
              context: context,
              widget: StartQuizScreen(
                title: quiz.title,
              ),
            );
          } else if (um.stdQuizes?[quiz.id]!.status == 'pending') {
            AppStatusDialog.show(
                context: context,
                status: AppDialogStatus.info,
                title: S.of(context).payment_pending_title,
                message: S.of(context).payment_pending_hint,
                primaryActionText: S.of(context).complete_payment,
                secondaryActionText: S.of(context).cancel,
                onSecondaryAction: () {
                  Navigator.pop(context);
                },
                onPrimaryAction: () {
                  Navigator.pop(context);
                  _showExamPaymentOptions(context, cubit, quiz);
                });
          } else {
            _showExamPaymentOptions(context, cubit, quiz);
          }
        } else {
          _showExamPaymentOptions(context, cubit, quiz);
        }
      } else {
        cubit.setQuizModel(quiz);
        Components.push(
          context: context,
          widget: StartQuizScreen(
            title: quiz.title,
          ),
        );
      }
    }
  }

  /// Shows the 3 payment options (wallet, code, online) for a paid exam,
  /// reusing the same sheet as the lecture purchase flow.
  ///
  /// NOTE: the purchase/unlock logic is intentionally left as TODOs — wire it
  /// up the same way as the lecture flow once the exam-purchase backend is ready.
  void _showExamPaymentOptions(
    BuildContext context,
    PlatformCubit cubit,
    QuizModel quiz,
  ) {
    // cubit.getIsShowOnlinePayment();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AnimatedPaymentBottomSheetContent(
          itemName: quiz.title,
          isDarkMode: cubit.isDarkMode,
          isShowOnlinePayment: cubit.isExamShowOnlinePayment,
          isAr: cubit.isAr,
          price: quiz.price ?? 0,
          quizId: quiz.id,
          codeClicked: ({required code}) async {
            await cubit.checkPurchaseQuizCode(code: code, quizId: quiz.id);
          },
          walletClicked: () async {
            await cubit.buyQuizWallet(price: quiz.price ?? 0, quizId: quiz.id);
          },
          onlineClicked: ({int? amount}) async {
            await cubit.buyQuizWallet(price: 0, quizId: quiz.id);
          },
        ),
      ),
    );
  }
}

class AvailableExamTile extends StatelessWidget {
  const AvailableExamTile({
    super.key,
    required this.quiz,
    required this.onTap,
    required this.cubit,
  });

  final PlatformCubit cubit;
  final QuizModel quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Components.setBgColor(cubit.isDarkMode);
    bool isFree = quiz.price == null || quiz.price == 0;
    bool isPaid =
        Constants.userBox.get('user').stdQuizes?[quiz.id]?.status == 'paid';

    bool isPending =
        Constants.userBox.get('user').stdQuizes?[quiz.id]?.status == 'pending';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: cubit.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
            border: Border.all(
              color: primary.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.appPrimaryColor,
                      AppColors.appSecondaryColor,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 2,
                      style: AppTextStyles.title2Style.copyWith(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: [
                        _InfoChip(
                          icon: Icons.help_outline_rounded,
                          label:
                              '${S.of(context).questions} ${quiz.questionsNum}',
                          isDarkMode: cubit.isDarkMode,
                        ),
                        if (quiz.fullMark != quiz.questionsNum)
                          _InfoChip(
                            icon: Icons.star_rounded,
                            label: '${S.of(context).fullMark} ${quiz.fullMark}',
                            isDarkMode: cubit.isDarkMode,
                          ),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${quiz.duration} ${S.of(context).mins}',
                          isDarkMode: cubit.isDarkMode,
                        ),
                        if (!cubit.showDelAcc) ...[
                          if (!isFree && isPending)
                            _InfoChip(
                              icon: Icons.hourglass_top_rounded,
                              label: S.of(context).pending,
                              color: Colors.amber,
                              isDarkMode: cubit.isDarkMode,
                            ),
                          if (!isFree && isPaid)
                            _InfoChip(
                              icon: Icons.check_circle_rounded,
                              label: S.of(context).paid,
                              color: Colors.green,
                              isDarkMode: cubit.isDarkMode,
                            ),
                          if (isFree || (!isPaid))
                            _InfoChip(
                              icon: Icons.attach_money_rounded,
                              label: isFree
                                  ? S.of(context).free
                                  : '${quiz.price} ${S.of(context).egp}',
                              isDarkMode: cubit.isDarkMode,
                            ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    if (quiz.validUntil != null)
                      _ExamCountdownChip(
                        validUntil: quiz.validUntil!,
                        isDarkMode: cubit.isDarkMode,
                      ),
                  ],
                ),
              ),

              /*
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
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

class QuizTile extends StatelessWidget {
  QuizTile({
    super.key,
    required this.isDarkMode,
    required this.date,
    required this.grade,
    required this.fullMark,
    required this.title,
    //  required this.showDegree,
    required this.id,
    required this.chapters,
    required this.questions,
  });

  bool isDarkMode;
  // bool showDegree;
  String title;
  DateTime date;
  int fullMark;
  int questions;

  Map<String?, List<String?>> chapters;
  double grade;
  String id;
  // List<StdQuestionModel> questions;
  @override
  Widget build(BuildContext context) {
    final primary = Components.setBgColor(isDarkMode);
    final percent = fullMark > 0 ? (grade / fullMark).clamp(0.0, 1.0) : 0.0;
    final scoreColor = Components.getColorFromPercentage(percent);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(
          color: primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  style: AppTextStyles.title2Style.copyWith(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _InfoChip(
                      icon: Icons.event_rounded,
                      label: DateFormat('dd-MM-yyyy', 'en').format(date),
                      isDarkMode: isDarkMode,
                    ),
                    _InfoChip(
                      icon: Icons.help_outline_rounded,
                      label: '${S.of(context).questions} $questions',
                      isDarkMode: isDarkMode,
                    ),
                    if (fullMark != questions)
                      _InfoChip(
                        icon: Icons.star_rounded,
                        label: '${S.of(context).fullMark} $fullMark',
                        isDarkMode: isDarkMode,
                      ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Icon(Icons.military_tech_rounded,
                        size: 16, color: scoreColor),
                    const SizedBox(width: 4.0),
                    Flexible(
                      child: Text(
                        '${S.of(context).your_result} ${Constants.doubletoInt(grade)}/$fullMark',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2Style.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          CircularPercentIndicator(
            radius: 38.0,
            lineWidth: 9.0,
            animation: true,
            animationDuration: 800,
            circularStrokeCap: CircularStrokeCap.round,
            percent: percent,
            center: Text(
              "${(percent * 100).round()}%",
              style: AppTextStyles.body2Style.copyWith(
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            progressColor: scoreColor,
            backgroundColor: scoreColor.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

/// Compact icon + label pill used to show quiz metadata.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDarkMode,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool isDarkMode;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.6);
    final bg = Components.setBgColor(isDarkMode)
        .withValues(alpha: isDarkMode ? 0.14 : 0.07);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color ?? bg,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color != null ? Colors.white : fg),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: AppTextStyles.body2Style.copyWith(
              fontSize: 12.0,
              color: color != null ? Colors.white : fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live, self-updating pill that shows how much time is left before an
/// available exam expires (its [validUntil]). Re-renders every second and
/// switches color as the deadline gets closer.
class _ExamCountdownChip extends StatefulWidget {
  const _ExamCountdownChip({
    required this.validUntil,
    required this.isDarkMode,
  });

  final DateTime validUntil;
  final bool isDarkMode;

  @override
  State<_ExamCountdownChip> createState() => _ExamCountdownChipState();
}

class _ExamCountdownChipState extends State<_ExamCountdownChip> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.validUntil.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.validUntil.difference(DateTime.now());
      });
      if (_remaining.isNegative) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(S s) {
    if (_remaining.isNegative || _remaining == Duration.zero) {
      return s.exam_ended;
    }
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    String body;
    if (days > 0) {
      body =
          '$days${s.unit_days} $hours${s.unit_hours} $minutes${s.unit_minutes}';
    } else if (hours > 0) {
      body =
          '$hours${s.unit_hours} $minutes${s.unit_minutes} $seconds${s.unit_seconds}';
    } else if (minutes > 0) {
      body = '$minutes${s.unit_minutes} $seconds${s.unit_seconds}';
    } else {
      body = '$seconds${s.unit_seconds}';
    }
    return '${s.time_left} $body';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ended = _remaining.isNegative || _remaining == Duration.zero;
    final urgent = !ended && _remaining.inHours < 1;
    final soon = !ended && !urgent && _remaining.inDays < 1;

    final Color color = ended || urgent
        ? const Color(0xffd64545)
        : soon
            ? const Color(0xffe0922f)
            : const Color(0xff2e9e5b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ended ? Icons.event_busy_rounded : Icons.timelapse_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4.0),
          Text(
            _format(s),
            style: AppTextStyles.body2Style.copyWith(
              fontSize: 12.0,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal, modern pill-style filter bar with a fixed set of labels.
/// Replaces the previous [ToggleSwitch] while keeping the same architecture
/// used across the app's filter screens.
class _QuizFilterBar extends StatelessWidget {
  const _QuizFilterBar({
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onSelected,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final bool isDarkMode;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          return _FilterPill(
            label: labels[index],
            icon: icons[index],
            selected: selectedIndex == index,
            isDarkMode: isDarkMode,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Components.setBgColor(isDarkMode);
    final unselectedFg = isDarkMode
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? primary : primary.withValues(alpha: 0.25),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : primary,
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: AppTextStyles.body2Style.copyWith(
                color: selected ? Colors.white : unselectedFg,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
