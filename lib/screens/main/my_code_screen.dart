// ignore_for_file: must_be_immutable

import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:karim_online_platform/models/attende_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:karim_online_platform/constants/colors.dart';
import 'package:karim_online_platform/constants/widgets.dart';
import 'package:karim_online_platform/generated/l10n.dart';

import '../../bloc/platform_cubit.dart';
import '../../bloc/platform_states.dart';
import '../../constants/components.dart';
import '../../constants/constants.dart';
import '../../constants/styles.dart';
import '../../models/user_model.dart';

class MyCodeScreen extends StatelessWidget {
  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('yyyy-MM-dd', 'en').format(dateTime);
  }

  MyCodeScreen({super.key});
  late UserModel um;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlatformCubit()..getAttendance(),
      child: BlocBuilder<PlatformCubit, PlatformStates>(
        builder: (context, state) {
          um = Constants.userBox.get('user');

          var cubit = PlatformCubit.get(context);
          return Scaffold(
            body: Container(
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
                      DefaultBackBtn(
                        txt: S.of(context).attendance,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Components.setBgColor(cubit.isDarkMode),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QrImageView(
                              data: um.code ?? '',
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    um.code ?? '',
                                    style: AppTextStyles.title1Style.copyWith(
                                      color: Components.setTextColor(
                                          cubit.isDarkMode),
                                    ),
                                  ),
                                  Text(
                                    um.groupName ?? '',
                                    style: AppTextStyles.body2Style.copyWith(
                                      fontFamily: 'Cairo',
                                      overflow: TextOverflow.ellipsis,
                                      color: Components.setTextColor(
                                          cubit.isDarkMode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (um.groupName != 'online')
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 22.0),
                              Text(
                                S.of(context).attendance,
                                style: AppTextStyles.title1Style,
                              ),
                              const SizedBox(height: 4.0),
                              Expanded(
                                child: RefreshIndicator(
                                  color:
                                      Components.setBgColor(cubit.isDarkMode),
                                  onRefresh: () => cubit.getAttendance(),
                                  child: ConditionalBuilder(
                                      condition:
                                          cubit.stdAttendanceList.isEmpty,
                                      builder: (context) => ListView(
                                            children: [
                                              Center(
                                                child: Text(
                                                  S
                                                      .of(context)
                                                      .no_attendance_yet,
                                                  style:
                                                      AppTextStyles.title2Style,
                                                ),
                                              ),
                                            ],
                                          ),
                                      fallback: (context) {
                                        return ListView.separated(
                                          itemCount:
                                              cubit.stdAttendanceList.length,
                                          itemBuilder: (context, index) {
                                            return AttendanceItem(
                                              lecName: cubit
                                                  .stdAttendanceList.keys
                                                  .elementAt(index),
                                              isDarkMode: cubit.isDarkMode,
                                              attendeModel: cubit
                                                  .stdAttendanceList.values
                                                  .elementAt(index),
                                            );
                                          },
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 12.0),
                                        );
                                      }),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AttendanceItem extends StatelessWidget {
  final AttendeModel attendeModel;
  final bool isDarkMode;
  final String lecName;
  UserModel get um => Constants.userBox.get('user');

  const AttendanceItem({
    super.key,
    required this.lecName,
    required this.attendeModel,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    bool isSub = attendeModel.groupName != null &&
        attendeModel.groupName != um.groupName;
    final Color statusColor = isSub
        ? Colors.orange
        : (attendeModel.isAttend ? Colors.green : Colors.red);

    final IconData statusIcon = isSub
        ? Icons.check_circle_outline_outlined // أيقونة خاصة بالـ Sub
        : (attendeModel.isAttend
            ? Icons.check_circle_outline_outlined
            : Icons.cancel_outlined);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBorder : AppColors.lightBborder,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: BorderDirectional(
          start: BorderSide(
            color: statusColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                lecName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8.0),
              //  Spacer(),
              if (isSub)
                Expanded(
                  child: Text(
                    '( ${attendeModel.groupName!} )',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body2Style.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '${S.of(context).lecture_date}:',
                        style: AppTextStyles.body2Style,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('EEEE').format(attendeModel.date)} ${DateFormat('(MM - dd)', 'en').format(attendeModel.date)}',
                        style: AppTextStyles.body2Style,
                      )
                    ],
                  ),
                ),
                if (attendeModel.arrivalTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          '${S.of(context).arrival_time}:',
                          style: AppTextStyles.body2Style,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('hh:mm', 'en').format(attendeModel.arrivalTime!)} ${DateFormat('a').format(attendeModel.arrivalTime!)}',
                          style: AppTextStyles.body2Style,
                        )
                      ],
                    ),
                  ),
                if (attendeModel.examDegree != null &&
                    attendeModel.fullExamDegree != null &&
                    attendeModel.fullExamDegree != '0')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          '${S.of(context).quiz_degree}:',
                          style: AppTextStyles.body2Style,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          attendeModel.fullExamDegree!.isEmpty
                              ? S.of(context).no_exam
                              : '${attendeModel.examDegree!} / ${attendeModel.fullExamDegree!}',
                          style: AppTextStyles.body2Style,
                        )
                      ],
                    ),
                  ),
                if (attendeModel.hwDegree != null &&
                    attendeModel.fullHWDegree != null &&
                    attendeModel.fullHWDegree != '0')
                  Row(
                    children: [
                      Text(
                        '${S.of(context).homework}:',
                        style: AppTextStyles.body2Style,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        attendeModel.fullHWDegree!.isEmpty
                            ? S.of(context).no_hw
                            : '${attendeModel.hwDegree!} / ${attendeModel.fullHWDegree!}',
                        style: AppTextStyles.body2Style,
                      )
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
class MyCodeScreen extends StatelessWidget {
  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('yyyy-MM-dd', 'en').format(dateTime);
  }

  MyCodeScreen({super.key});
  late UserModel um;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlatformCubit()..getAttendance(),
      child: BlocBuilder<PlatformCubit, PlatformStates>(
        builder: (context, state) {
          um = Constants.userBox.get('user');

          var cubit = PlatformCubit.get(context);
          return Scaffold(
            body: Container(
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultBackBtn(
                        txt: S.of(context).attendance,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Components.setBgColor(cubit.isDarkMode),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QrImageView(
                              data: um.code ?? '',
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    um.code ?? '',
                                    style: AppTextStyles.title1Style.copyWith(
                                      color: Components.setTextColor(
                                          cubit.isDarkMode),
                                    ),
                                  ),
                                  Text(
                                    um.groupName ?? '',
                                    style: AppTextStyles.body2Style.copyWith(
                                      fontFamily: 'Cairo',
                                      overflow: TextOverflow.ellipsis,
                                      color: Components.setTextColor(
                                          cubit.isDarkMode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (um.groupName != 'online')
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 22.0),
                              Text(
                                S.of(context).attendance,
                                style: AppTextStyles.title1Style,
                              ),
                              const SizedBox(height: 4.0),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => cubit.getAttendance(),
                                  child: ConditionalBuilder(
                                      condition:
                                          cubit.stdAttendanceList.isEmpty,
                                      builder: (context) => ListView(
                                            children: [
                                              Center(
                                                child: Text(
                                                  S
                                                      .of(context)
                                                      .no_attendance_yet,
                                                  style:
                                                      AppTextStyles.title2Style,
                                                ),
                                              ),
                                            ],
                                          ),
                                      fallback: (context) {
                                        return ListView.builder(
                                          itemCount:
                                              cubit.stdAttendanceList.length,
                                          itemBuilder: (context, index) {
                                            return AttendanceItem(
                                              index: index + 1,
                                              isSub: cubit
                                                      .stdAttendanceList.values
                                                      .elementAt(index)
                                                      .groupName !=
                                                  null,
                                              attended: cubit
                                                  .stdAttendanceList.values
                                                  .elementAt(index)
                                                  .isAttend,
                                              group: cubit
                                                      .stdAttendanceList.values
                                                      .elementAt(index)
                                                      .groupName ??
                                                  um.groupName!,
                                              lecName:
                                                  '${cubit.stdAttendanceList.length - index}   (${DateFormat('d/M', 'en').format(cubit.stdAttendanceList.values.elementAt(index).date)})',
                                              isDarkMode: cubit.isDarkMode,
                                            );
                                          },
                                        );
                                      }),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AttendanceItem extends StatelessWidget {
  final int index;
  final bool attended;
  final String group;
  final String lecName;
  final bool isDarkMode;
  final bool isSub;
  const AttendanceItem({
    super.key,
    required this.index,
    required this.attended,
    required this.isSub,
    required this.group,
    required this.lecName,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkBorder : AppColors.lightBborder,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                lecName,
                style: AppTextStyles.title2Style,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(group,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isSub
                      ? AppTextStyles.body2Style.copyWith(
                          color: Colors.red,
                        )
                      : AppTextStyles.body2Style),
            ),
            const SizedBox(width: 8.0),
            Icon(
              attended ? Icons.check_circle : Icons.cancel,
              color: attended ? Colors.green : Colors.red,
            ),
          ],
        ));
  }
}
*/
