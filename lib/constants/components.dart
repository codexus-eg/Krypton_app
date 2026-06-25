import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:karim_online_platform/constants/colors.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/models/boarding_model.dart';

class Components {
  static MaterialColor getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }

  static void pushReplacement(
      {required BuildContext context, required Widget widget}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  static void push({required BuildContext context, required Widget widget}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  static void pop({required BuildContext context}) {
    Navigator.of(context).pop();
  }

  static List<BoardingModel> boardings = [
    BoardingModel(
      image: Constants.firstOnBoarding,
      title: 'أهلاَ بيك في منصة\nبِالْعَرَبِيّ',
      body: "#لن_يسبقك_أحد",
    ),
    BoardingModel(
      image: Constants.lectures,
      title: 'الحصص',
      body: 'تقدر تتفرج علي الحصص براحتك في اي وقت.',
    ),
    BoardingModel(
      image: Constants.requests,
      title: 'الاسئلة',
      body: 'تقدر تبعت سؤال للسكرتيرة وترد عليك.',
    ),
    BoardingModel(
      image: Constants.questions,
      title: 'الامتحانات',
      body: 'هتمتحن ف اي وقت عن طريق ادخال كود الامتحان.',
    ),
    BoardingModel(
      image: Constants.questionBank,
      title: 'بنك الاسئلة',
      body: 'حل اكبر كمية اسئلة من بنك الاسئلة.',
    ),
    BoardingModel(
      image: Constants.attendence,
      title: 'الحضور',
      body: 'تقدر تتابع حضورك وغيابك وتسجل حضورك بسهولة.',
    ),
    BoardingModel(
      image: Constants.getStatred,
      title: "يلا بينا!",
      body: 'يلا بينا نبدأ.',
    ),
  ];

  static Future<bool> checkConnection() async {
    var result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none); // يعني فيه اتصال بشبكة
  }

  static String getGrade(String num) {
    if (num == '1') {
      return 'first';
    } else if (num == '2') {
      return 'second';
    } else if (num == '3') {
      return 'third';
    } else {
      return 'sec';
    }
  }

  static Color setBgColor(bool isDarkMode) =>
      isDarkMode ? AppColors.appPrimaryColor : AppColors.appSecondaryColor;
  static Color setTextColor(bool isDarkMode) => Colors.white;

  static String getGradeNum(String grade) {
    if (grade == 'first') {
      return '1';
    } else if (grade == 'second') {
      return '2';
    } else {
      return '3';
    }
  }

  String calculateVideoDuration(Duration duration) {
    final totalHour = duration.inHours == 0 ? '' : '${duration.inHours}:';
    final totalMinute = duration.toString().split(':')[1];
    final totalSeconds = (duration - Duration(minutes: duration.inMinutes))
        .inSeconds
        .toString()
        .padLeft(2, '0');
    final String videoLength = '$totalHour$totalMinute:$totalSeconds';
    return videoLength;
  }

  static Color getColorFromPercentage(double percentage) {
    if (percentage >= 0.80) {
      return Colors.green;
    } else if (percentage <= 0.30) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  static IconData lectureDataIcon(String type) {
    if (type == 'video') {
      return Icons.video_collection;
    } else if (type == 'pdf') {
      return Icons.picture_as_pdf;
    } else {
      return Icons.quiz;
    }
  }

  static String getGradeName(String selectedGrade) {
    if (selectedGrade == 'first') {
      return 'الأول الثانوي';
    } else if (selectedGrade == 'second') {
      return 'الثاني الثانوي';
    } else if (selectedGrade == 'third') {
      return 'الثالث الثانوي';
    } else {
      return 'غير محدد';
    }
  }
}
