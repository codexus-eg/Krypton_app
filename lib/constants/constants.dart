import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:karim_online_platform/constants/colors.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/generated/l10n.dart';
import 'package:karim_online_platform/screens/auth/login/login_page.dart';
import 'package:karim_online_platform/screens/main/external_books_screen.dart';
import 'package:karim_online_platform/screens/main/home_screen.dart';
import 'package:karim_online_platform/screens/main/profile_screen.dart';
import 'package:no_screenshot/no_screenshot.dart';

import '../network/local/shared_pref_helper.dart';
import '../screens/main/revision_screen.dart.dart';
import '../screens/main/quiz_screen.dart';

class Constants {
  static List<Widget> screensList = [
    const HomeScreen(),
    const ExternalBooksScreen(),
    const RevisionsScreen(),
    QuizScreen(),
    ProfileScreen(),
  ];
  static String otpMsg({required String code}) {
    String msg = '''
رمز التحقق الخاص بك هو $code،
يرجى إدخاله لتأكيد رقم الهاتف.
''';

    return msg;
  }

  static Future<http.Response?> sendMsg({
    required String phone,
    required String msg,
  }) async {
    final deviceId = await FirebaseFirestore.instance
        .collection('whatsapp')
        .doc('deviceId')
        .get();
    final url = Uri.parse('https://noti-fire.com/api/send/message');

    // البيانات المرسلة في body الطلب
    final Map<String, String> data = {
      'device_id': deviceId.data()?['deviceId'],
      'to': '+2$phone',
      'message': msg,
    };

    try {
      // إرسال الطلب POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json'
        }, // تحديد نوع المحتوى كـ JSON
        body: jsonEncode(data), // تحويل البيانات إلى JSON
      );
// التحقق من حالة الاستجابة
      return response;
    } catch (e) {
      debugPrint('Exception: $e');
      return null;
    }
  }

  static final noScreenshot = NoScreenshot.instance;

  static String guest = 'guest';
  static Map<String, FaIconData> icons = {
    'wts': FontAwesomeIcons.whatsapp,
    'fb': FontAwesomeIcons.facebook,
    'ytp': FontAwesomeIcons.youtube,
    'tel': FontAwesomeIcons.telegram,
    'tik': FontAwesomeIcons.tiktok,
    'insta': FontAwesomeIcons.instagram,
  };

  static late Box userBox;
  static String doubletoInt(double value) {
    String formatted = (value % 1 == 0)
        ? value.toInt().toString() // لو رقم صحيح
        : value.toString(); // لو فيه كسور

    return formatted;
  }

  static void showLoginDialog({
    required BuildContext context,
    required bool isDarkMode,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? AppColors.darkBorder : AppColors.lightBborder,
          title: Text(
            S.of(context).login_req,
          ),
          content: Text(
            S.of(context).must_login_access,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                S.of(context).cancel,
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Constants.userBox.delete('user');
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                S.of(context).login,
                style: TextStyle(color: Components.setBgColor(isDarkMode)),
              ),
            ),
          ],
        );
      },
    );
  }

  static String firstOnBoarding =
      'https://firebasestorage.googleapis.com/v0/b/koraiemonlineplatform.appspot.com/o/app_images%2Fon_board%2Fphoto_2024-10-17_21-33-06.png?alt=media&token=7885ccab-8644-42b4-a437-3d57463a5d73';
  static String getStatred =
      'https://firebasestorage.googleapis.com/v0/b/koraiemonlineplatform.appspot.com/o/app_images%2Fon_board%2Fphoto_2024-10-17_21-33-05.png?alt=media&token=5b5dada8-a9f0-4cf1-a0a0-9ba23626b6e9';

  static String koraiemPhoto =
      'https://firebasestorage.googleapis.com/v0/b/koraiemonlineplatform.appspot.com/o/app_images%2Fon_board%2F541bf65446f74c2599b7a9453fce4314.jpg?alt=media&token=1b38b355-9fc6-46ef-9659-ecd7e8900384';

  static String questionBank =
      'https://firebasestorage.googleapis.com/v0/b/koraiemonlineplatform.appspot.com/o/app_images%2Fon_board%2Fquestions_bank%20(2).png?alt=media&token=1e71a497-3be6-446b-aaea-9339f9e7502a';

  static String lectures =
      'https://firebasestorage.googleapis.com/v0/b/sagedonlineplatform.appspot.com/o/app_images%2Fon_board%2Flectures.png?alt=media&token=e0590979-9784-4815-acf3-8cecef128a4b';

  static String questions =
      'https://firebasestorage.googleapis.com/v0/b/sagedonlineplatform.appspot.com/o/app_images%2Fon_board%2Fquestions.png?alt=media&token=1eb873b0-b18d-4619-9dcc-c1828ca239f3';

  static String requests =
      'https://firebasestorage.googleapis.com/v0/b/sagedonlineplatform.appspot.com/o/app_images%2Fon_board%2Frequests.png?alt=media&token=6872fe54-a80a-4d75-ab77-a694270708f6';

  static String attendence =
      'https://firebasestorage.googleapis.com/v0/b/sagedonlineplatform.appspot.com/o/app_images%2Fon_board%2Fattendance.png?alt=media&token=9aed8626-379f-40c8-a628-f6c052aae889';

  static String noQuiz =
      'https://firebasestorage.googleapis.com/v0/b/karim-platform.firebasestorage.app/o/app_images%2Fno_quiz.png?alt=media&token=d8511573-4c76-4ce7-b668-52191248fe2a';
  static String quizTime =
      'https://firebasestorage.googleapis.com/v0/b/karim-platform.firebasestorage.app/o/app_images%2Fquiz_time.png?alt=media&token=d8511573-4c76-4ce7-b668-52191248fe2a';

  static String img =
      'https://firebasestorage.googleapis.com/v0/b/karim-platform.firebasestorage.app/o/user_images%2Fuser_img.jpg?alt=media&token=262ccb3a-0009-4950-84ae-60d97bf7aa4e';

  static String koraiemImg =
      'https://firebasestorage.googleapis.com/v0/b/karim-platform.firebasestorage.app/o/user_images%2Fteacher.jpeg?alt=media&token=54d13036-1fdc-41a8-a1b9-d5b5affad90c';

  static String wallpaberDark = SharedPrefHelper.getData('isPurple') ?? false
      ? wallpaberPurbleDark
      : wallpaberBlueDark;

  static String wallpaberLight = SharedPrefHelper.getData('isPurple') ?? false
      ? wallpaberPurbleLight
      : wallpaberBlueLight;
  static String wallpaberPurbleDark = 'assets/images/bg/wallpaber_dark.png';
  static String wallpaberPurbleLight = 'assets/images/bg/wallpaber_light.png';
  static String wallpaberBlueDark = 'assets/images/bg/wallpaber_dark.png';
  static String wallpaberBlueLight = 'assets/images/bg/wallpaber_light.png';

  static String accountBlocked = 'blocked';
  static String accountPending = 'pending';

  static const List<String> governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الشرقية',
    'الدقهلية',
    'القليوبية',
    'البحيرة',
    'المنوفية',
    'الغربية',
    'كفر الشيخ',
    'دمياط',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'الوادي الجديد',
    'مطروح',
    'شمال سيناء',
    'جنوب سيناء',
  ];
}
