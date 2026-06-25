// ignore_for_file: non_constant_identifier_names, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:karim_online_platform/models/comment_model.dart';
import 'package:karim_online_platform/models/comment_std_data.dart';
import 'package:karim_online_platform/models/group_model.dart';
import 'package:karim_online_platform/models/invoice_model.dart';
import 'package:karim_online_platform/models/like_std_data.dart';
import 'package:karim_online_platform/models/otp_model.dart';
import 'package:karim_online_platform/models/payment_model.dart';
import 'package:karim_online_platform/models/posts_model.dart';
import 'package:karim_online_platform/models/purchased_exam_model.dart';
import 'package:karim_online_platform/models/purchases_widget_data.dart';
import 'package:karim_online_platform/models/user_purchased_chapter_model.dart';
import 'package:karim_online_platform/models/watches_video_model.dart';
import 'package:karim_online_platform/models/written_answs_model.dart';

import 'package:path_provider/path_provider.dart';
import 'package:karim_online_platform/bloc/platform_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:karim_online_platform/constants/colors.dart';
import 'package:karim_online_platform/constants/components.dart';
import 'package:karim_online_platform/constants/constants.dart';
import 'package:karim_online_platform/generated/l10n.dart';
import 'package:karim_online_platform/models/attende_model.dart';
import 'package:karim_online_platform/models/purchased_vid_model.dart';
import 'package:karim_online_platform/models/social_media_model.dart';
import 'package:karim_online_platform/models/std_quiz_model.dart';
import 'package:karim_online_platform/models/user_model.dart';
import 'package:karim_online_platform/models/user_purchase_model.dart';
import 'package:karim_online_platform/models/video_details_model.dart';
import 'package:karim_online_platform/network/local/shared_pref_helper.dart';
import 'package:karim_online_platform/services/notification_service.dart';

import '../models/AllStudentsModel 2.dart';
import '../models/ChatModel.dart';
import '../models/GroupsModel2.dart';
import '../models/RequsetsModel.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/viedo_model.dart';

class _LocalLectureSortWrapper {
  final String chapId;
  final String lecId;
  int? stdWatches;
  int? avaWatches;
  final DateTime purchaseDate;

  _LocalLectureSortWrapper({
    required this.chapId,
    required this.lecId,
    this.stdWatches,
    this.avaWatches,
    required this.purchaseDate,
  });
}

class PlatformCubit extends Cubit<PlatformStates> {
  PlatformCubit() : super(PaltformAppInitialState()) {
    isShowDelAccount();
    // حدّث الـ pushToken في Firestore تلقائيًا عند تجديده من FCM.
    NotificationService.onTokenRefreshCallback = updateCurrentUserPushToken;
  }

  /// تحديث الـ pushToken للطالب الحالي في Firestore عند تجديده.
  Future<void> updateCurrentUserPushToken(String token) async {
    if (Platform.isWindows) return;
    final UserModel? sm = Constants.userBox.get('user');
    if (sm == null || sm.code == null || sm.grade == null) return;
    if (sm.code == Constants.guest) return;
    try {
      await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(sm.grade!)
          .doc(sm.code)
          .update({'pushToken': token});
    } catch (e) {
      debugPrint('Failed to update refreshed pushToken: $e');
    }
  }

  static PlatformCubit get(BuildContext context) => BlocProvider.of(context);
  var scaffoldKey = GlobalKey<ScaffoldState>();
  var scrollController = ScrollController();

  bool isSecure = true;
  void changePassSecure() {
    isSecure = !isSecure;

    emit(PaltformChangePasswordSecureState());
  }

  bool isGuest() {
    UserModel sm = Constants.userBox.get('user');
    return sm.code == Constants.guest;
  }

  List<QuestionModel> questionbankQuestions = [];
  late Map<String, int?> stdQuestionbankAnsws;
/*
  Future<void> generateQuestions(
    String title,
    int questionsnum,
    Map<String?, List<String?>> chapters,
    int num,
    int fill,
  ) async {
    emit(PlatformQuizGetQuestionBankLoadingState());
    questionbankQuestions = [];
    UserModel um = Constants.userBox.get('user');

    for (int i = 0; i < chapters.length; i++) {
      String? key = chapters.entries.elementAt(i).key;
      List<String?> value = chapters.entries.elementAt(i).value;

      List<String> nonNullValues = value.whereType<String>().toList();

      for (int k = 0; k < nonNullValues.length; k++) {
        try {
          QuerySnapshot questionSnapshot = await FirebaseFirestore.instance
              .collection('data')
              .doc('questions_bank')
              .collection(um.grade!)
              .doc(key)
              .collection('content')
              .doc(nonNullValues[k])
              .collection('questions')
              .get();

          if (questionSnapshot.docs.isNotEmpty) {
            List<DocumentSnapshot> docs = questionSnapshot.docs;

            // Shuffle the list to randomize order
            docs.shuffle();

            // Add the first `num` or `(num + (number - fill))` random questions
            for (int j = 0;
                ((i == chapters.length - 1 && k == nonNullValues.length - 1)
                    ? j <
                        (j < docs.length
                            ? (num + ((number - (num * fill))).abs())
                            : docs.length)
                    : j < (j < docs.length ? num : docs.length));
                j++) {
              questionbankQuestions.add(QuestionModel.fromJson(
                  docs[j].data() as Map<String, dynamic>));
            }
            docs = [];
          }
        } catch (onError) {
          debugPrint(onError.toString());
          emit(PlatformQuizGetQuestionBankFailState(onError.toString()));
        }
      }
    }
    // TODO add to add std points
    // emit(PlatformQuizGetQuestionBankSuccessState(questionbankQuestions));
    questionbankQuestions.shuffle();
    stdQuestionbankAnsws = {};
    addStdQuestionbankPoints(
      isComplete: false,
      chapters: chapters,
    );
  }
*/
  bool isQuestionBank = false;
  void changeQuestionBank() {
    isQuestionBank = !isQuestionBank;
    emit(PlatformChangeQuestionBankState());
  }

  List<QuizModel> avaExams = [];
  Future<void> getAvaExams() async {
    emit(PlatformGetAvaExamsLoadingState());
    try {
      UserModel um = Constants.userBox.get('user');
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('data')
          .doc('quizes')
          .collection(um.grade!)
          .where('isShamel', isEqualTo: true)
          .where('isValid', isEqualTo: true)
          .get();

      final answeredIds = (um.stdQuizes ?? {}).values.map((e) => e.id).toSet();

      avaExams = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final lecId = data['lecId'];
            final id = data['id'] ?? doc.id;
            if (lecId != null && lecId.toString().isNotEmpty) return false;
            if (answeredIds.contains(id)) return false;
            final validUntil = data['validUntil'];
            if (validUntil != null) {
              final validDate = (validUntil as Timestamp).toDate();
              if (validDate.isBefore(DateTime.now())) return false;
            }
            return true;
          })
          .map((doc) => QuizModel.fromJson(doc.data()))
          .toList();

      emit(PlatformGetAvaExamsSuccessState());
    } catch (onError) {
      debugPrint(onError.toString());
      emit(PlatformGetAvaExamsFailState(onError.toString()));
    }
  }

  bool isLecturesExams = false;
  void changeLecturesExams() {
    isLecturesExams = !isLecturesExams;
    emit(PlatformChangeLecturesExamsState());
  }
  // List<QuestionModel> questionbankQuestions = [];
  // void generateQuestions(Map<String?, List<String?>> chapters, int num) {
  //   questionbankQuestions = [];
  //   UserModel um = Constants.userBox.get('user');
  //   chapters.forEach((key, value) {
  //     // Check if the value list is not empty
  //     if (value.isNotEmpty) {
  //       // Filter out any null values from the list
  //       List<String> nonNullValues = value.whereType<String>().toList();

  //       if (nonNullValues.isNotEmpty) {
  //         for (String val in nonNullValues) {
  //           FirebaseFirestore.instance
  //               .collection('data')
  //               .doc('questions_bank')
  //               .collection(um.grade!)
  //               .doc(key)
  //               .collection('content')
  //               .doc(val)
  //               .collection('questions')
  //               .get()
  //               .then((value) {
  //             for (int i = 0; i < num; i++) {
  //               questionbankQuestions
  //                   .add(QuestionModel.fromJson(value.docs[i].data()));
  //             }
  //           }).catchError((onError) {
  //             debugPrint(onError.toString());
  //           });
  //         }
  //       }
  //     }
  //   });
  //   debugPrint(questionbankQuestions.toString());
  // }

  int number = 10;
  void incrementQuestionsNum() {
    if (number < 60) {
      number += 10;
      emit(PlatformChangeQuestionsNumsState());
    }
  }

  void decrementQuestionsNum() {
    if (number > 10) {
      number -= 10;
      emit(PlatformChangeQuestionsNumsState());
    }
  }

  bool isOldPassSecure = true;
  void changeOldPassSecure() {
    isOldPassSecure = !isOldPassSecure;
    emit(PaltformChangeOldPasswordSecureState());
  }

  bool isNewPassSecure = true;
  void changeNewPassSecure() {
    isNewPassSecure = !isNewPassSecure;
    emit(PaltformChangeNewPasswordSecureState());
  }

  double sliderVal = 10;
  void changeSlider(double val) {
    sliderVal = val;
    emit(PlatformChangeSliderState());
  }

/*
// Student Register
  void platformStudentSignup({
    required ar_fname,
    required ar_sname,
    required ar_thname,
    required fname,
    required grade,
    required phoneNum,
    required sname,
    required thname,
    required password,
  }) {
    emit(PlatformCreateUserLoadingState());
    FirebaseFirestore.instance
        .collection('data')
        .doc('year')
        .get()
        .then((value) {
      String stdIndex =
          '${Random.secure().nextInt(10).toString()}${Random.secure().nextInt(10).toString()}${Random.secure().nextInt(10).toString()}${Random.secure().nextInt(10).toString()}${Random.secure().nextInt(10).toString()}';

      String stdCode =
          '${Components.getGradeNum(grade)}${value.data()!['year']}$stdIndex';

      FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: '$stdCode@gmail.com', password: password)
          .then((value) {
        FirebaseFirestore.instance
            .collection('data')
            .doc('init_balance')
            .get()
            .then((value) {
          createStudent(
            userModel: UserModel(
              parentPhoneNum: '',
              ar_fname: ar_fname,
              ar_sname: ar_sname,
              ar_thname: ar_thname,
              code: stdCode,
              fname: fname,
              grade: grade,
              enabled: true,
              pushToken: '',
              phoneNum: phoneNum,
              sname: sname,
              thname: thname,
              img: Constants.img,
              balance: value.data()!['value'],
              password: password,
              purchasedVideos: {},
              purchasedPdfs: {},
              stdQuizes: [],
              groupId: '3E0YUrRnB9zLdhPgH0Mf',
              groupName: 'لطفي',
              attendance: {},
            ),
          );
        }).catchError((onError) {
          emit(PlatformCreateUserFailState(onError.toString()));
        });
      }).catchError((onError) {
        debugPrint(onError.toString());
        emit(PlatformCreateUserFailState(onError.toString()));
      });
    }).catchError((onError) {
      emit(PlatformCreateUserFailState(onError.toString()));
    });
  }
*/
  Future<String> getPhoneNum(String s) async {
    DocumentSnapshot<Map<String, dynamic>> phone =
        await FirebaseFirestore.instance.collection('phoneNums').doc(s).get();
    return phone.data()!['phone'];
  }

  List<SocialMediaModel> socialMedia = [];
  void getSocialMedia() {
    socialMedia.clear();
    FirebaseFirestore.instance.collection('socialMedia').get().then((onValue) {
      for (var social in onValue.docs) {
        if (social.data()['linkUrl'] == null ||
            social.data()['linkUrl'].isEmpty) {
          continue;
        }
        socialMedia.add(SocialMediaModel.fromJson(social.data()));
      }
      emit(PlatfomrRefreshState());
    }).catchError((onError) {
      debugPrint(onError.toString());
    });
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var info = await deviceInfo.androidInfo;
      return info.id ?? '';
    } else if (Platform.isIOS) {
      var info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? '';
    } else {
      var info = await deviceInfo.windowsInfo;
      return info.deviceId ?? '';
    }
  }

  String _getDeviceType() {
    return (Platform.isAndroid || Platform.isIOS) ? 'mobile' : 'pc';
  }

  void platformLogin({
    required String password,
    required String phoneNum,
  }) async {
    emit(PlatformLoginLoadingState());

    try {
      /*
      // 1️⃣ تسجيل الدخول بالبريد وكلمة المرور
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '$code@gmail.com',
        password: password,
      );
*/

      DocumentReference<Map<String, dynamic>>? docRef;
      List<String> grades = ['second', 'third'];
      for (var grade in grades) {
        var data = await FirebaseFirestore.instance
            .collection('data')
            .doc('students')
            .collection(grade)
            .where('phoneNum', isEqualTo: phoneNum)
            .get();
        if (data.docs.isNotEmpty) {
          var code = data.docs.first.id;
          docRef = FirebaseFirestore.instance
              .collection('data')
              .doc('students')
              .collection(Components.getGrade(code[0]))
              .doc(code);
          break;
        }
      }
      if (docRef == null) {
        emit(PlatformLoginFailState(
          'رقم الهاتف غير مسجل لدينا، تأكد من الرقم أو سجّل حساب جديد.',
          type: LoginErrorType.userNotFound,
        ));
        return;
      }
      var snapshot = await docRef.get();
      Map<String, dynamic> userData = snapshot.data()!;

      if (password != userData['password']) {
        emit(PlatformLoginFailState(
          'كلمة المرور غير صحيحة.',
          type: LoginErrorType.invalidCredentials,
        ));
        return;
      }
      if (userData['code'] != '327587375') {
        // 2️⃣ تحديد نوع الجهاز ومعرفه
        String deviceType = _getDeviceType();
        String deviceId = await _getDeviceId();

        List devices = userData['devices'] ?? [];

        // 4️⃣ التحقق من الحد المسموح
        bool typeExists = devices.any((d) => d['type'] == deviceType);
        bool sameDeviceExists = devices.any((d) => d['id'] == deviceId);

        if (!sameDeviceExists && typeExists) {
          emit(PlatformLoginFailState(
            'لا يمكنك تسجيل الدخول من ${deviceType == 'mobile' ? 'موبايل' : 'كمبيوتر'} آخر، حسابك مرتبط بجهاز مختلف.',
            type: LoginErrorType.deviceLimit,
          ));
          return;
        }

        // 5️⃣ لو الجهاز جديد → أضفه
        if (!sameDeviceExists) {
          devices.add({'type': deviceType, 'id': deviceId});
          await docRef.update({'devices': devices});
        }
      }
      String? oldGroupId = Constants.userBox.get('user')?.groupName;
      // 6️⃣ تخزين بيانات المستخدم محليًا
      await Constants.userBox.put('user', UserModel.fromJson(userData));
      await manageUserTopics(oldGroupId: oldGroupId);
      isShowDelAccount();

      emit(
        PlatformLoginSuccessState(
          enabled: UserModel.fromJson(userData).enabled ?? true,
          active: UserModel.fromJson(userData).isActive ?? true,
        ),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      debugPrint(msg);
      emit(PlatformLoginFailState(msg));
    }
  }

  Future<void> manageUserTopics({String? oldGroupId}) async {
    UserModel um = Constants.userBox.get('user');

    String enhGroupId = um.groupId!.isEmpty ? 'online' : um.groupId!;
    debugPrint('enhGroupId: $enhGroupId');

    if (oldGroupId != null) {
      String enhOldGroupId = oldGroupId.isEmpty ? 'online' : oldGroupId;

      //remove previous group's topic
      if (enhOldGroupId != enhGroupId) {
        debugPrint('enhOldGroupId: $enhOldGroupId');

        await FirebaseMessaging.instance.unsubscribeFromTopic(enhOldGroupId);
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('${um.grade}_${enhOldGroupId}_lectures');
        debugPrint('removed');
      }
    }

    //add new group's topic
    await FirebaseMessaging.instance.subscribeToTopic(um.grade!);
    await FirebaseMessaging.instance
        .subscribeToTopic('${um.grade}_$enhGroupId');
    await FirebaseMessaging.instance.subscribeToTopic('${um.grade}_exams');
    await FirebaseMessaging.instance.subscribeToTopic(
        '${um.grade}_${enhGroupId == 'online' ? 'online' : 'center'}_lectures');
    debugPrint('added');
  }

  Future<void> removeUserTopics() async {
    UserModel um = Constants.userBox.get('user');
    String enhGroupId = um.groupId!.isEmpty ? 'online' : um.groupId!;

    await FirebaseMessaging.instance.unsubscribeFromTopic(um.grade!);
    await FirebaseMessaging.instance
        .unsubscribeFromTopic('${um.grade}_$enhGroupId');
    await FirebaseMessaging.instance.unsubscribeFromTopic('${um.grade}_exams');
    await FirebaseMessaging.instance.unsubscribeFromTopic(
        '${um.grade}_${enhGroupId == 'online' ? 'online' : 'center'}_lectures');
  }

/*
// login
  void platformLogin({
    required String password,
    required String code,
  }) {
    emit(PlatformLoginLoadingState());
    FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: '$code@gmail.com',
      password: password,
    )
        .then((value) {
      FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(Components.getGrade(code[0]))
          .doc(code)
          .get()
          .then((value) {
        debugPrint(value.data().toString());
        Constants.userBox
            .put('user', UserModel.fromJson(value.data()!))
            .then((valuee) {
          isShowDelAccount();
          emit(
            PlatformLoginSuccessState(
              enabled: UserModel.fromJson(value.data()!).enabled ?? true,
              active: UserModel.fromJson(value.data()!).isActive ?? true,
            ),
          );
        }).catchError((onError) {
          debugPrint('ahmed ${onError.toString()}');
          emit(PlatformLoginFailState(' ${onError.toString()}'));
        });
      }).catchError((onError) {
        debugPrint('ahmed2 ${onError.toString()}');
        emit(PlatformLoginFailState(onError.toString()));
      });
    }).catchError((onError) {
      debugPrint('ahmed3 ${onError.toString()}');
      emit(PlatformLoginFailState(onError.toString()));
    });
  }
*/
  Future<void> setUserDataLocally() async {
    emit(PlatformGetUserDataLoadingState());
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code)
        .get()
        .then((value) async {
      debugPrint(value.data().toString());

      if (value.exists && value.data() != null) {
        Map<String, dynamic> userData = value.data()!;
        if (userData['enabled'] == false) {
          Constants.userBox.put(
            'user',
            UserModel.fromJson(userData),
          );
          emit(PlatformAccountBlockedState());
          return;
        }

        if (!Platform.isWindows) {
          // احفظ الـ pushToken بشكل صحيح لـ Android و iOS (يتعامل مع APNs على iOS).
          final String? newPushToken =
              await NotificationService.saveTokenForUser(
            grade: um.grade!,
            code: um.code!,
            currentToken: userData['pushToken'],
          );
          if (newPushToken != null) {
            userData['pushToken'] = newPushToken;
          }
        }
        // قم بتحديث البيانات محليًا
        String? oldGroupId = Constants.userBox.get('user')?.groupId;
        // 6️⃣ تخزين بيانات المستخدم محليًا

        Constants.userBox
            .put('user', UserModel.fromJson(userData))
            .then((_) async {
          await manageUserTopics(oldGroupId: oldGroupId);
          await getPurchasedVideosList();
          emit(PlatformGetUserDataSuccessState());
        }).catchError((onError) {
          debugPrint('Error updating local data: ${onError.toString()}');
          emit(PlatformGetUserDataFailState(' ${onError.toString()}'));
        });
      } else {
        await Constants.userBox.delete('user').then((onValue) {
          emit(PlatformDeleteAccountSuccessState());
        });
      }
    }).catchError((onError) {
      debugPrint('Firestore error: ${onError.toString()}');
      emit(PlatformGetUserDataFailState(onError.toString()));
    });
  }
/*
  void setVideosData() async {
    CollectionReference<Map<String, dynamic>> col = FirebaseFirestore.instance
        .collection('data')
        .doc('videos')
        .collection('third')
        .doc('nhkIGQJklA4qkWU1CTFX')
        .collection('lectures');

    QuerySnapshot<Map<String, dynamic>> videosCol = await col.get();

    for (var vid in videosCol.docs) {
      col.doc(vid.id).update({
        'hide': true,
        'dep': false,
      });
    }
    debugPrint('Doneeee');
  }
  */
/*
  void resetStdVideos() async {
    CollectionReference<Map<String, dynamic>> stdCol = FirebaseFirestore
        .instance
        .collection('data')
        .doc('students')
        .collection('second');
    QuerySnapshot<Map<String, dynamic>> stds = await stdCol.get();

    for (var std in stds.docs) {
      DocumentSnapshot<Map<String, dynamic>> get =
          await stdCol.doc(std.id).get();
      if (get.data()!['balance'] >= 2) {
        stdCol.doc(std.id).update({'balance': FieldValue.increment(-2)});
      } else {
        stdCol.doc(std.id).update({'balance': 0});
      }
    }

    debugPrint('Doneee');
  }
*/

//logout

  void platformLogout() async {
    emit(PlatformLogoutLoadingState());
    removeUserTopics();
    // FirebaseAuth.instance.signOut().then((value) {
    Constants.userBox.delete('user').then((value) {
      emit(PlatformLogoutSuccessState());
    }).catchError((onError) {
      emit(PlatformLogoutFailState(' ${onError.toString()}'));
    });
    /*
    }).catchError((onError) {
      emit(PlatformLogoutFailState(onError.toString()));
    });
    */
  }

  void setLocalData() {
    UserModel sm = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(sm.grade!)
        .doc(sm.code)
        .get()
        .then((onValue) async {
      if (onValue.exists) {
        Map<String, dynamic> userData = onValue.data()!;
        if (userData['enabled'] == false) {
          emit(PlatformAccountBlockedState());
          Constants.userBox.put('user', UserModel.fromJson(userData));
          return;
        }
        if (userData['isActive'] == false) {
          emit(PlatformAccountPendingState());
          Constants.userBox.put('user', UserModel.fromJson(userData));
          return;
        }
        if (!Platform.isWindows) {
          // احفظ الـ pushToken بشكل صحيح لـ Android و iOS (يتعامل مع APNs على iOS).
          final String? newPushToken =
              await NotificationService.saveTokenForUser(
            grade: sm.grade!,
            code: sm.code!,
            currentToken: userData['pushToken'],
          );
          if (newPushToken != null) {
            userData['pushToken'] = newPushToken;
          }
        }
        String? oldGroupId = Constants.userBox.get('user')?.groupId;
        // 6️⃣ تخزين بيانات المستخدم محليًا
        await Constants.userBox.put('user', UserModel.fromJson(userData));
        await manageUserTopics(oldGroupId: oldGroupId);
        await getPurchasedVideosList();
        debugPrint('Account Exist!');
      } else {
        await Constants.userBox.delete('user').then((onValue) {
          emit(PlatformDeleteAccountSuccessState());
        });
        debugPrint('Account Deleted!');
      }
      emit(PlatfomrRefreshState());
    }).catchError((onError) {
      debugPrint(onError.toString());
    });
  }

  Future<void> setErrScreenData() async {
    UserModel sm = Constants.userBox.get('user');
    await FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(sm.grade!)
        .doc(sm.code)
        .get()
        .then((onValue) async {
      if (onValue.exists) {
        Map<String, dynamic> userData = onValue.data()!;
        String? oldGroupId = Constants.userBox.get('user')?.groupId;
        await Constants.userBox.put('user', UserModel.fromJson(userData));
        if (userData['enabled'] == true && userData['isActive'] == true) {
          emit(PlatformAccountNotBlockedAndPendingState());

          await manageUserTopics(oldGroupId: oldGroupId);
          return;
        }
      } else {
        await Constants.userBox.delete('user').then((onValue) {
          emit(PlatformDeleteAccountSuccessState());
        });
        debugPrint('Account Deleted!');
      }
      emit(PlatfomrRefreshState());
    }).catchError((onError) {
      debugPrint(onError.toString());
    });
  }

/*
// codes
  void getStdPurchasedVideos() {
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code)
        .get()
        .then((value) {
      Map<String, Map<String, List<String>>> purchasedPdfs = {};
      Map<String, Map<String, List<UserPurchasedModel>>> purchasedVideos = {};
      if (value.data()!['purchased_videos'] != null) {
        value.data()!['purchased_videos'].forEach((chapterKey, chapterValue) {
          Map<String, List<UserPurchasedModel>> lectures = {};
          (chapterValue as Map<String, dynamic>)
              .forEach((lectureKey, lectureValue) {
            List<dynamic> list = lectureValue as List<dynamic>;
            lectures[lectureKey] = list
                .map((item) =>
                    UserPurchasedModel.fromJson(item as Map<String, dynamic>))
                .toList();
          });
          purchasedVideos[chapterKey] = lectures;
        });
      }

      if (value.data()!['purchased_pdfs'] != null) {
        value.data()!['purchased_pdfs'].forEach((chapterKey, chapterValue) {
          Map<String, List<String>> lectures = {};
          (chapterValue as Map<String, dynamic>)
              .forEach((lectureKey, lectureValue) {
            List<dynamic> list = lectureValue as List<dynamic>;
            lectures[lectureKey] = list.map((item) => item as String).toList();
          });
          purchasedPdfs[chapterKey] = lectures;
        });
      }
      um.purchasedPdfs = purchasedPdfs;
      um.purchasedVideos = purchasedVideos;
      um.save().then((value) {
        emit(PlatformGetPurchasedVideosSuccessState());
      }).catchError((onError) {
        debugPrint(onError.toString());
      });
    }).catchError((onError) {
      debugPrint(onError.toString());
    });
  }
*/
  bool showDelAcc = true;
  void isShowDelAccount() {
    if (Constants.userBox.isNotEmpty) {
      UserModel um = Constants.userBox.get('user');
      showDelAcc = (um.code == '327587375');
      //  getStdPurchasedVideos();
      emit(PlatformGetIsDelAccShowSuccessState());
    }

/*
    FirebaseFirestore.instance
        .collection('data')
        .doc('isDelAcc')
        .get()
        .then((value) {
      showDelAcc = value.data()!['isDelAccShown'];
      emit(PlatformGetIsDelAccShowSuccessState());
    }).catchError((onError) {
      debugPrint(onError.toString());
    });
    */
  }

  void deleteAccount() {
    /*
    final user = FirebaseAuth.instance.currentUser;
    user!.delete().then((value) {
      */
    Constants.userBox.delete('user').then((value) {
      emit(PlatformDeleteAccountSuccessState());
    }).catchError((onError) {
      emit(PlatformDeleteAccountFailState(' ${onError.toString()}'));
    });
    /*
    }).catchError((onError) {
      emit(PlatformDeleteAccountFailState(onError.toString()));
    });
    */
  }

  Future<void> checkPurchaseQuizCode({
    required String code,
    required String quizId,
    context,
  }) async {
    emit(PlatformCheckPurchaseQuizCodeLoadingState());
    final um = Constants.userBox.get('user');

    try {
      final codeDoc =
          await FirebaseFirestore.instance.collection('codes').doc(code).get();

      if (!codeDoc.exists) {
        emit(PlatformCheckPurchaseQuizCodeFailState(
            ' ${S.current.enter_valid_code}'));
        return;
      }

      final data = codeDoc.data()!;
      final stdCode = data['stdCode'];

      if (stdCode != null && stdCode.toString().isNotEmpty) {
        if (stdCode == um.code) {
          emit(PlatformCheckPurchaseQuizCodeFailState(
              ' ${S.current.u_charge_code}'));
        } else {
          emit(PlatformCheckPurchaseQuizCodeFailState(
              ' ${S.current.code_used}'));
        }
        return;
      }

      final codeChapId = data['chapId'];
      final codeLecId = data['lecId'];
      final codeValue = data['value'];

      if (codeChapId != null && codeLecId != null) {
        emit(PlatformCheckPurchaseQuizCodeFailState(
            ' ده كود شحن حصة مش امتحان!'));
        return;
      }

      if (codeValue != null) {
        emit(PlatformCheckPurchaseQuizCodeFailState(
            ' ده كود شحن محفظة مش امتحان!'));
        return;
      }

      final quizCode = data['quizCode'];

      if (quizCode == null || quizCode.toString().isEmpty) {
        emit(PlatformCheckPurchaseQuizCodeFailState(
            ' ${S.current.enter_valid_code}'));
        return;
      }

      if (quizId != quizCode) {
        emit(PlatformCheckPurchaseQuizCodeFailState(
            ' ${S.current.code_not_for_quiz}'));
        return;
      }
      await redeemExamCode(quizId: quizId);

      // ✅ Save code usage
      await FirebaseFirestore.instance.collection('codes').doc(code).update({
        'stdCode': um.code,
        'date': DateTime.now(),
      });
      emit(PlatformCheckPurchaseQuizCodeSuccessState());
    } catch (e) {
      emit(PlatformCheckPurchaseQuizCodeFailState(e.toString()));
    }
  }

  Future<void> redeemExamCode({required String quizId, int? price}) async {
    UserModel user = Constants.userBox.get('user');
    await FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(user.grade!)
        .doc(user.code!)
        .update({
      'balance': FieldValue.increment(-(price ?? 0)),
      'stdQuizes.$quizId.status': 'paid',
      'stdQuizes.$quizId.purchaseDateTime': DateTime.now(),
    });
    user.stdQuizes?[quizId] = StdQuizModel(
      id: '',
      title: '',
      dateTime: DateTime.now(),
      questionNums: 0,
      triesNum: 0,
      fullMark: 0,
      degree: 0,
      userAnsIdx: {},
      purchaseDateTime: DateTime.now(),
      status: 'paid',
    );
    await FirebaseFirestore.instance
        .collection('data')
        .doc('purchases')
        .collection(user.grade!)
        .doc()
        .set(PurchaseExamModel(
          date: DateTime.now(),
          stdCode: user.code,
          quizId: quizId,
        ).toMap());
    user.balance = (user.balance ?? 0) - (price ?? 0);
    await user.save();
    debugPrint('stdQuiz: ${user.stdQuizes?[quizId]?.toJson().toString()}');
    emit(PlatfomrRefreshState());
  }

  Future<void> checkChapterCode({
    required String code,
    String? chapId,
    context,
  }) async {
    emit(PlatformCheckCodeLoadingState());
    final um = Constants.userBox.get('user');

    try {
      final codeDoc =
          await FirebaseFirestore.instance.collection('codes').doc(code).get();

      if (!codeDoc.exists) {
        emit(PlatformCheckCodeFailState(' ${S.current.enter_valid_code}'));
        return;
      }

      final data = codeDoc.data()!;
      final stdCode = data['stdCode'];

      if (stdCode != null && stdCode.toString().isNotEmpty) {
        if (stdCode == um.code) {
          emit(PlatformCheckCodeFailState(' ${S.current.u_charge_code}'));
        } else {
          emit(PlatformCheckCodeFailState(' ${S.current.code_used}'));
        }
        return;
      }

      final codeChapId = data['chapId'];
      final codeLecId = data['lecId'];

      // Wallet code - Add to balance
      if (codeChapId == null) {
        // General
        if (chapId == null) {
          await applyGeneralCodeToBalance(value: data['value']);
        } else {
          emit(PlatformCheckCodeFailState(' ده كود شحن محفظة مش حصة!'));

          return;
        }
      }
      // Lecture code - Validate and Purchase
      else {
        // General
        if (chapId == null) {
          emit(PlatformCheckCodeFailState(' ده كود شحن حصة مش محفظة!'));
          return;
        } else {
          // Lecture
          if (chapId == codeChapId && codeLecId == null) {
            final success = await _validateChapterCode(chapId, um.grade!);
            if (!success) {
              emit(
                  PlatformCheckCodeFailState(' ${S.current.enter_valid_code}'));
              return;
            }

            await _purchaseChapterWithCode(
              chapId: chapId,
              um: um,
            );
          } else {
            emit(PlatformCheckCodeFailState(' ${S.current.code_not_for_chap}'));
            return;
          }
        }
      }

      // ✅ Save code usage
      await FirebaseFirestore.instance.collection('codes').doc(code).update({
        'stdCode': um.code,
        'date': DateTime.now(),
      });
      emit(PlatformCheckCodeSuccessState(videoDetailsModel: videoDetailsModel));
    } catch (e) {
      emit(PlatformCheckCodeFailState(e.toString()));
    }
  }

  Future<bool> _validateChapterCode(
    String chapId,
    String grade,
  ) async {
    final chapterRef = FirebaseFirestore.instance
        .collection('data')
        .doc('videos')
        .collection(grade)
        .doc(chapId);

    final chapterSnap = await chapterRef.get();
    if (!chapterSnap.exists) return false;
    if (chapterSnap.data()?['hide'] == true) return false;

    return true;
  }

  Future<void> _purchaseChapterWithCode({
    required String chapId,
    required UserModel um,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Safe nested Map initialization
    if (!um.purchasedVideos!.containsKey(chapId)) {
      um.purchasedVideos![chapId] = UserPurchasedChapterModel(
        lectures: {},
        status: 'paid',
        purchaseDateTime: DateTime.now(),
      );
    }
    // Firebase Database Payload
    final studentRef = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code);

    batch.update(studentRef, {
      'purchased_videos.$chapId.status': 'paid',
      'purchased_videos.$chapId.purchaseDateTime': DateTime.now(),
    });

    final purchaseRef = FirebaseFirestore.instance
        .collection('data')
        .doc('purchases')
        .collection(um.grade!)
        .doc();

    batch.set(
      purchaseRef,
      PurchaseVideoModel(
        date: DateTime.now(),
        stdCode: um.code,
        chapId: chapId,
      ).toMap(),
    );

    // 5. Commit Cloud Database changes then write to local storage
    await batch.commit();
    await um.save();
  }

  Future<void> checkCode({
    required String code,
    String? lecId,
    String? chapId,
    context,
  }) async {
    emit(PlatformCheckCodeLoadingState());
    videoDetailsModel = null;
    final um = Constants.userBox.get('user');

    try {
      final codeDoc =
          await FirebaseFirestore.instance.collection('codes').doc(code).get();

      if (!codeDoc.exists) {
        emit(PlatformCheckCodeFailState(' ${S.current.enter_valid_code}'));
        return;
      }

      final data = codeDoc.data()!;
      final stdCode = data['stdCode'];

      if (stdCode != null && stdCode.toString().isNotEmpty) {
        if (stdCode == um.code) {
          emit(PlatformCheckCodeFailState(' ${S.current.u_charge_code}'));
        } else {
          emit(PlatformCheckCodeFailState(' ${S.current.code_used}'));
        }
        return;
      }

      final codeChapId = data['chapId'];
      final codeLecId = data['lecId'];

      // Wallet code - Add to balance
      if (codeChapId == null && codeLecId == null) {
        // General
        if (chapId == null && lecId == null) {
          await applyGeneralCodeToBalance(value: data['value']);
        } else {
          emit(PlatformCheckCodeFailState(' ده كود شحن محفظة مش حصة!'));

          return;
        }
      }
      // Lecture code - Validate and Purchase
      else {
        // General
        if (chapId == null && lecId == null) {
          emit(PlatformCheckCodeFailState(' ده كود شحن حصة مش محفظة!'));
          return;
        } else {
          // Lecture
          if (chapId == codeChapId && lecId == codeLecId) {
            final success =
                await _validateLectureCode(chapId!, lecId!, um.grade!);
            if (!success) {
              emit(
                  PlatformCheckCodeFailState(' ${S.current.enter_valid_code}'));
              return;
            }

            await _purchaseLectureWithCode(
              chapId: chapId,
              lecId: lecId,
              um: um,
            );
          } else {
            emit(PlatformCheckCodeFailState(' ${S.current.code_not_for_lec}'));
            return;
          }
        }
      }

      // ✅ Save code usage
      await FirebaseFirestore.instance.collection('codes').doc(code).update({
        'stdCode': um.code,
        'date': DateTime.now(),
      });
      emit(PlatformCheckCodeSuccessState(videoDetailsModel: videoDetailsModel));
    } catch (e) {
      emit(PlatformCheckCodeFailState(e.toString()));
    }
  }

  VideoDetailsModel? videoDetailsModel;

  Future<void> applyGeneralCodeToBalance({
    required int value,
    bool? isOnline,
  }) async {
    try {
      UserModel user = Constants.userBox.get('user');
      await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(user.grade!)
          .doc(user.code!)
          .update({
        'balance': FieldValue.increment(value),
        'walletBalanceStatus': 'paid',
        'lastwalletBalanceTransaction': DateTime.now(),
      });

      user.balance = (user.balance ?? 0) + value;
      user.walletBalanceStatus = 'paid';
      user.lastwalletBalanceTransaction = DateTime.now();
      await user.save();
      if (isOnline ?? false) {
        emit(PlatformApplyGeneralCodeToBalanceSuccessState());
      } else {
        emit(PlatfomrRefreshState());
      }
    } catch (e) {
      debugPrint("apply general code to balance fail : ${e.toString()}");
      if (isOnline ?? false) {
        emit(PlatformApplyGeneralCodeToBalanceFailState(e.toString()));
      }
    }
  }

  Future<bool> _validateLectureCode(
    String chapId,
    String lecId,
    String grade,
  ) async {
    final chapterRef = FirebaseFirestore.instance
        .collection('data')
        .doc('videos')
        .collection(grade)
        .doc(chapId);

    final chapterSnap = await chapterRef.get();
    if (!chapterSnap.exists) return false;
    if (chapterSnap.data()?['hide'] == true) return false;

    final lectureRef = chapterRef.collection('lectures').doc(lecId);
    final lectureSnap = await lectureRef.get();
    if (!lectureSnap.exists) return false;

    if (lectureSnap.data()?['hide'] == true) return false;

    final dataSnap = await lectureRef.collection('data').get();
    if (dataSnap.docs.isEmpty) return false;
    videoDetailsModel = VideoDetailsModel.fromJson(lectureSnap.data()!);

    return true;
  }

  Future<void> _purchaseLectureWithCode({
    required String chapId,
    required String lecId,
    required UserModel um,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Safe nested Map initialization
    if (!um.purchasedVideos!.containsKey(chapId)) {
      um.purchasedVideos![chapId] = UserPurchasedChapterModel(lectures: {});
    }
    um.purchasedVideos![chapId]!.lectures ??= {};

    if (!um.purchasedVideos![chapId]!.lectures!.containsKey(lecId)) {
      um.purchasedVideos![chapId]!.lectures![lecId] =
          UserPurchasedLectureModel(videos: {});
    }
    um.purchasedVideos![chapId]!.lectures![lecId]!.videos ??= {};

    Map<String, UserPurchasedModel> videosMap =
        um.purchasedVideos![chapId]!.lectures![lecId]!.videos!;

    // 2. Fetch all missing lecture videos from Firestore FIRST (Single Fetch)
    // This handles the case where the local map is empty because it's a first-time purchase
    if (videosMap.isEmpty) {
      // videosMap =  await _fetchLectureVideosFromNetwork(um.grade!, chapId, lecId);
      //   um.purchasedVideos?[chapId]!.lectures![lecId]!.videos = videosMap;
      um.purchasedVideos?[chapId]!.lectures![lecId]!.videos = {};
    }

    // 3. Parallel Network Requests Optimization (No serial waiting loops!)
    List<Future<void>> updateTasks = [];

    for (var entry in videosMap.entries) {
      final vidId = entry.key;
      final video = entry.value;

      // Launch all network operations simultaneously
      updateTasks.add(
        getAvaWatches(chapId: chapId, lecId: lecId, vidId: vidId).then((extra) {
          video.avaWatches = (video.avaWatches ?? 4) + extra;
        }),
      );
    }

    // Wait for all async operations to finish in parallel
    await Future.wait(updateTasks);

    // 4. Firebase Database Payload
    final studentRef = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code);

    batch.update(studentRef, {
      'purchased_videos.$chapId.lectures.$lecId.purchaseDateTime':
          DateTime.now(),
      // Clear any leftover "pending" flag from an abandoned online attempt.
      'purchased_videos.$chapId.lectures.$lecId.status': 'paid',
      'purchased_videos.$chapId.lectures.$lecId.videos':
          videosMap.map((key, value) => MapEntry(key, value.toMap())),
    });

    final purchaseRef = FirebaseFirestore.instance
        .collection('data')
        .doc('purchases')
        .collection(um.grade!)
        .doc();

    batch.set(
      purchaseRef,
      PurchaseVideoModel(
        date: DateTime.now(),
        stdCode: um.code,
        chapId: chapId,
        lecId: lecId,
      ).toMap(),
    );

    // 5. Commit Cloud Database changes then write to local storage
    um.purchasedVideos![chapId]!.lectures![lecId]!.status = 'paid';
    await batch.commit();
    await um.save();
  }

  /// Helper to fetch fallback base video structure if the student is purchasing this for the first time
  Future<Map<String, UserPurchasedModel>> _fetchLectureVideosFromNetwork(
    String grade,
    String chapId,
    String lecId,
  ) async {
    Map<String, UserPurchasedModel> fallbackMap = {};
    try {
      QuerySnapshot<Map<String, dynamic>> videosDocs = await FirebaseFirestore
          .instance
          .collection('data')
          .doc('videos')
          .collection(grade)
          .doc(chapId)
          .collection('lectures')
          .doc(lecId)
          .collection('data')
          .get();

      for (var doc in videosDocs.docs) {
        fallbackMap[doc.id] = UserPurchasedModel(
          vidId: doc.id,
          stdWatches: 0,
          avaWatches: doc.data()['avaWatches'] ?? 4,
          dateTime: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint("Failed to fetch initial lecture videos: $e");
    }
    return fallbackMap;
  }

  Future<int> getAvaWatches({
    required String chapId,
    required String lecId,
    required String vidId,
  }) async {
    UserModel um = Constants.userBox.get('user');
    DocumentSnapshot<Map<String, dynamic>> vid = await FirebaseFirestore
        .instance
        .collection('data')
        .doc('videos')
        .collection(um.grade!)
        .doc(chapId)
        .collection('lectures')
        .doc(lecId)
        .collection('data')
        .doc(vidId)
        .get();

    if (!vid.exists || vid.data() == null) return 4;
    return vid.data()!['avaWatches'] ?? 4;
  }

/*
  Future<void> _purchaseLectureWithCode({
    required String chapId,
    required String lecId,
    required UserModel um,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // Init maps if needed
    um.purchasedVideos ??= {};
    um.purchasedVideos![chapId]?.lectures ??= {};
    um.purchasedVideos![chapId]!.lectures![lecId]?.videos ??= {};

    // Loop to update avaWatches
    for (var video
        in um.purchasedVideos![chapId]!.lectures![lecId]!.videos!.values) {
      final extra = await getAvaWatches(
        chapId: chapId,
        lecId: lecId,
        vidId: video.key,
      );

      video.avaWatches = (video.avaWatches ?? 4) + extra;
    }

    // Firebase: update student
    final studentRef = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code);

    batch.update(studentRef, {
      'purchased_videos.$chapId.lectures.$lecId.videos': um
          .purchasedVideos![chapId]!.lectures![lecId]!.videos!
          .map((key, value) => MapEntry(key, value.toMap())),
    });

    // Firebase: log purchase
    final purchaseRef = FirebaseFirestore.instance
        .collection('data')
        .doc('purchases')
        .collection(um.grade!)
        .doc();

    batch.set(
        purchaseRef,
        PurchaseVideoModel(
          date: DateTime.now(),
          stdCode: um.code,
          chapId: chapId,
          lecId: lecId,
        ).toMap());

    // Save locally after Firebase completes
    await batch.commit();
    await um.save();
  }

  Future<int> getAvaWatches({
    required String chapId,
    required String lecId,
    required String vidId,
  }) async {
    UserModel um = Constants.userBox.get('user');
    DocumentSnapshot<Map<String, dynamic>> vid = await FirebaseFirestore
        .instance
        .collection('data')
        .doc('videos')
        .collection(um.grade!)
        .doc(chapId)
        .collection('lectures')
        .doc(lecId)
        .collection('data')
        .doc(vidId)
        .get();

    return vid.data()!['avaWatches'] ?? 4;
  }
*/
  List<VideoModel> videoList = [];

  Future<void> getVideos() async {
    videoList = [];
    emit(PlatformGetVideosLoadingState());
    UserModel um = Constants.userBox.get('user');

    try {
      var videosSnapshot = await FirebaseFirestore.instance
          .collection('data')
          .doc('videos')
          .collection(um.grade ?? '')
          .orderBy('date', descending: true)
          .get();

      for (var doc in videosSnapshot.docs) {
        final data = doc.data();

        // لو الفيديو مخفي
        if (data['hide'] == true) {
          debugPrint('Ahmedddd');
          continue;
        }

        // لو الطالب أونلاين (Online أو فاضي)
        final isOnlineStudent =
            (um.groupName?.isEmpty ?? true) || um.groupName == 'Online';

        if (isOnlineStudent) {
          // الطالب أونلاين يشوف online و both
          if (data['type'] != 'both' && data['type'] != 'online') {
            continue;
          }
        } else {
          // الطالب سنتر يشوف center و both
          if (data['type'] != 'both' && data['type'] == 'online') {
            continue;
          }
        }

        videoList.add(VideoModel.fromJson(data));
      }

      print(videoList.length);

// TODO
      // await getRecentLectures(um);
      emit(PlatformGetVideosSuccessState());
    } catch (error) {
      debugPrint(error.toString());
      emit(PlatformGetVideosFailState(error.toString()));
    }
  }

/*
  List<VideoDetailsModel> recentVideosList = [];
  Future<void> getRecentLectures(UserModel um) async {
    recentVideosList = [];
    emit(PlatformGetRecentVideosLoadingState());

    try {
      for (var video in videoList) {
        debugPrint(video.chapId);
        var lecturesSnapshot = await FirebaseFirestore.instance
            .collection('data')
            .doc('videos')
            .collection(um.grade!)
            .doc(video.chapId)
            .collection('lectures')
            .orderBy('date', descending: true)
            .get();
        for (var doc in lecturesSnapshot.docs) {
          if (doc.data()['hide'] ?? false) {
            continue;
          }
          debugPrint(doc.data().toString());
          recentVideosList.add(VideoDetailsModel.fromJson(doc.data()));
        }
      }
      // await getPurchasedVideosList();
      recentVideosList.sort((a, b) => b.date.compareTo(a.date));
      //  debugPrint(recentVideosList.first.toString());

      emit(PlatformGetRecentVideosSuccessState());
    } catch (error) {
      debugPrint(error.toString());
      emit(PlatformGetRecentVideosFailState(error.toString()));
    }
  }
*/
  List<VideoDetailsModel> myVideos = [];

  Future<void> getMyVideos() async {
    myVideos = [];
    UserModel um = Constants.userBox.get('user');

    if (um.purchasedVideos!.isEmpty) {
      debugPrint('No purchased videos found.');
      return;
    }

    // 1. Gather all purchased lectures locally across all chapters
    List<_LocalLectureSortWrapper> localLectures = [];

    for (String chapId in um.purchasedVideos!.keys) {
      final chapter = um.purchasedVideos![chapId];
      if (chapter?.lectures == null) continue;

      for (String lecId in chapter!.lectures!.keys) {
        final lectureData = chapter.lectures![lecId];
        if (lectureData?.status == 'pending') continue;
        localLectures.add(
          _LocalLectureSortWrapper(
            chapId: chapId,
            lecId: lecId,
            // Fallback to epoch if date is missing
            purchaseDate: lectureData?.purchaseDateTime ?? DateTime.now(),
          ),
        );
      }
    }

    // 2. Sort them locally right away!
    // Change to b.purchaseDate.compareTo(a.purchaseDate) for Newest First
    localLectures.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    // 3. Fire parallel Firestore requests based on the already sorted list
    List<Future<void>> fetchTasks = [];

    // We use a thread-safe map or ordered placeholder to maintain the sort order after async operations complete
    List<VideoDetailsModel?> orderedResults =
        List.filled(localLectures.length, null);

    for (int i = 0; i < localLectures.length; i++) {
      final target = localLectures[i];

      fetchTasks.add(FirebaseFirestore.instance
          .collection('data')
          .doc('videos')
          .collection(um.grade!)
          .doc(target.chapId)
          .collection('lectures')
          .doc(target.lecId)
          .get()
          .then((lectureDoc) {
        if (lectureDoc.exists && lectureDoc.data() != null) {
          final data = lectureDoc.data()!;

          // Skip if hidden
          if (data['hide'] ?? false) return;

          // Insert directly into its pre-sorted index slot!
          orderedResults[i] = VideoDetailsModel.fromJson(data);
        }
      }).catchError((error) {
        debugPrint('Error fetching metadata for ${target.lecId}: $error');
      }));
    }

    try {
      // Wait for all cloud data to populate concurrently
      await Future.wait(fetchTasks);

      // 4. Filter out any null entries (from hidden videos or failed fetches)
      myVideos = orderedResults.whereType<VideoDetailsModel>().toList();
      debugPrint(myVideos.first.title);
      emit(PlatformGetMyLecturesDataSuccessState());
    } catch (error) {
      debugPrint('Error populating video data details: $error');
    }
  }

/*
  Future<void> getMyVideos() async {
    myVideos = [];
    UserModel um = Constants.userBox.get('user');

    if (um.purchasedVideos == null || um.purchasedVideos!.isEmpty) {
      debugPrint('No purchased videos found.');
      return;
    }

    for (String chapId in um.purchasedVideos!.keys) {
      DocumentReference<Map<String, dynamic>> doc = FirebaseFirestore.instance
          .collection('data')
          .doc('videos')
          .collection(um.grade!)
          .doc(chapId);

      try {
        for (String lecId in um.purchasedVideos![chapId]!.lectures!.keys) {
          // Check if there's at least one video that matches the condition
          DocumentSnapshot<Map<String, dynamic>> lectureDoc =
              await doc.collection('lectures').doc(lecId).get();
          if (lectureDoc.exists) {
            if (lectureDoc.data()?['hide'] ?? false) {
              continue;
            }
            myVideos.add(VideoDetailsModel.fromJson(lectureDoc.data()!));
          }
        }
        emit(PlatformGetMyLecturesDataSuccessState());
      } catch (error) {
        debugPrint(error.toString());
      }
    }

    debugPrint(myVideos.toString());
  }
*/
// old myVideos
/*
  List<VideoDetailsModel> myVideos = [];
  Future<void> getMyVideos() async {
    myVideos = [];
    UserModel um = Constants.userBox.get('user');

    if (um.purchasedVideos != null && um.purchasedVideos!.isNotEmpty) {
      um.purchasedVideos!.forEach((key, purchasedVideos) {
        for (UserPurchasedModel video in purchasedVideos) {
          FirebaseFirestore.instance
              .collection('data')
              .doc('videos')
              .collection(um.grade!)
              .doc(key)
              .collection('lectures')
              .doc(video.vidId)
              .get()
              .then((value) {
            myVideos.add(VideoDetailsModel.fromJson(value.data()!));
            emit(PlatformGetMyLecturesDataSuccessState());
          }).catchError((onError) {
            print(onError.toString());
          });
        }
      });
      print(myVideos);
    } else {
      print('No purchased videos found.');
    }
  }
*/

  List<VideoDetailsModel> videoDetailsList = [];
  Future<void> getVideoDetails({
    required String chapId,
  }) async {
    videoDetailsList = [];
    emit(PlatformGetVideoDetailsLoadingState());
    UserModel um = Constants.userBox.get('user');
    try {
      var lecturesSnapshot = await FirebaseFirestore.instance
          .collection('data')
          .doc('videos')
          .collection(um.grade!)
          .doc(chapId)
          .collection('lectures')
          .orderBy('date', descending: true)
          .get();

      for (var doc in lecturesSnapshot.docs) {
        if (doc.data()['hide'] ?? false) {
          continue;
        }
        videoDetailsList.add(VideoDetailsModel.fromJson(doc.data()));
      }

      emit(PlatformGetVideoDetailsSuccessState(videoDetailsList));
    } catch (error) {
      debugPrint(error.toString());
      emit(PlatformGetVideoDetailsFailState(error.toString()));
    }
  }

  List<Map<String, dynamic>> lectureData = [];
  Future<void> getLectureData({
    required String chapId,
    required String lecId,
  }) async {
    List<WatchesVideoModel> vidds = [];
    emit(PlatformGetLecturesDataLoadingState());

    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('videos')
        .collection(um.grade!)
        .doc(chapId)
        .collection('lectures')
        .doc(lecId)
        .collection('data')
        .orderBy('index')
        .get()
        .then((value) {
      lectureData = [];
      for (int i = 0; i < value.docs.length; i++) {
        lectureData.add(value.docs[i].data());
        if (lectureData[i]['type'] == 'video') {
          vidds.add(WatchesVideoModel.fromMap(lectureData[i]));
        }
      }

      debugPrint('Lecture data: $lectureData');
      emit(PlatformGetLecturesDataSuccessState(lectureData, vidds));
    }).catchError((onError) {
      debugPrint(onError.toString());
      emit(PlatformGetLecturesDataFailState(onError.toString()));
    });
  }

/*
  void addIndextoVid() async {
    QuerySnapshot<Map<String, dynamic>> chapCol = await FirebaseFirestore
        .instance
        .collection('data')
        .doc('videos')
        .collection('second')
        .get();

    for (var chap in chapCol.docs) {
      QuerySnapshot<Map<String, dynamic>> lecCol = await FirebaseFirestore
          .instance
          .collection('data')
          .doc('videos')
          .collection('second')
          .doc(chap.id)
          .collection('lectures')
          .get();
      for (var lec in lecCol.docs) {
        QuerySnapshot<Map<String, dynamic>> dataCol = await FirebaseFirestore
            .instance
            .collection('data')
            .doc('videos')
            .collection('second')
            .doc(chap.id)
            .collection('lectures')
            .doc(lec.id)
            .collection('data')
            .get();
        for (int i = 0; i < dataCol.docs.length; i++) {
          FirebaseFirestore.instance
              .collection('data')
              .doc('videos')
              .collection('second')
              .doc(chap.id)
              .collection('lectures')
              .doc(lec.id)
              .collection('data')
              .doc(dataCol.docs[i].id)
              .update({'index': i});
        }
      }
    }
    debugPrint('doneeee!');
  }
*/
  Map<String, AttendeModel> stdAttendanceList = {};
  Future<void> getAttendance() async {
    emit(PlatformGetAttendenceDataLoadingState());
    UserModel um = Constants.userBox.get('user');

    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('data')
              .doc('students')
              .collection(um.grade!)
              .doc(um.code)
              .get();

      if (documentSnapshot.exists) {
        // attendance map من الطالب
        Map<String, dynamic> data = documentSnapshot.data()!['attendance'];

        // نحولها ل Map<lecName, AttendeModel>
        List<MapEntry<String, AttendeModel>> sortedEntries = data.entries.map(
          (entry) {
            return MapEntry(entry.key, AttendeModel.fromJson(entry.value));
          },
        ).toList();

        // sort by date
        sortedEntries.sort(
          (a, b) => b.value.date.compareTo(a.value.date),
        );

        // stdAttendanceList النهائي
        stdAttendanceList = Map.fromEntries(sortedEntries);

        debugPrint('stdAttendanceList: ${stdAttendanceList.length}');

        // 👇 هنا نكمل ونجيب درجات الامتحان/الواجب
        for (var lecName in stdAttendanceList.keys) {
          var groupDoc = await FirebaseFirestore.instance
              .collection('Attendance')
              .doc(um.grade) // بدل third حسب الصف
              .collection("Groups")
              .where('Name',
                  isEqualTo:
                      stdAttendanceList[lecName]?.groupName ?? um.groupName)
              /*
              .doc(stdAttendanceList[lecName]!.groupName ??
                  um.groupId) // groupId بتاع الطالب
                  */
              .get();

          if (groupDoc.docs.isNotEmpty) {
            var lectures =
                groupDoc.docs.first.data()['lectures'] as List<dynamic>?;

            if (lectures != null) {
              var targetLecture = lectures.firstWhere(
                (lec) => lec['lecName'] == lecName,
                orElse: () => null,
              );

              if (targetLecture != null) {
                stdAttendanceList[lecName] =
                    stdAttendanceList[lecName]!.copyWith(
                  fullExamDegree: targetLecture['fullMark'],
                  fullHWDegree: targetLecture['hwDegree'],
                );
              }
            }
          }
        }

        emit(PlatformGetAttendanceDataSuccessState());
      } else {
        emit(PlatformGetAttendanceDataFailState('Document does not exist'));
      }
    } catch (onError) {
      emit(PlatformGetAttendanceDataFailState(onError.toString()));
      print(onError.toString());
    }
  }

  Future<void> buyQuizWallet({
    required String quizId,
    required int price,
  }) async {
    try {
      emit(PlatformBuyQuizWalletLoadingState());
      UserModel um = Constants.userBox.get('user');
      if (price > (um.balance ?? 0)) {
        emit(PlatformBuyQuizWalletFailState(S.current.no_balance_avl));
        return;
      }
      await redeemExamCode(quizId: quizId, price: price);
      emit(PlatformBuyQuizWalletSuccessState());
    } catch (e) {
      debugPrint(e.toString());
      emit(PlatformBuyQuizWalletFailState(e.toString()));
    }
  }

  void buyChapter({
    required int price,
    required String chapId,
    required bool pop,
  }) async {
    emit(PlatformBuyLecturesLoadingState());
    UserModel um = Constants.userBox.get('user');

    // 2. Guest Mode handling
    if (isGuest()) {
      await um.save();
      emit(PlatformBuyChaptersSuccessState(pop: pop));
      return;
    }

    // 3. Balance verification
    if (price > (um.balance ?? 0)) {
      emit(PlatformBuyLecturesFailState(S.current.no_balance_avl));
      return;
    }

    // 4. Firebase Operations utilizing WriteBatch
    WriteBatch batch = FirebaseFirestore.instance.batch();

    PurchaseVideoModel purchaseVideoModel = PurchaseVideoModel(
      date: DateTime.now(),
      stdCode: um.code,
      chapId: chapId,
    );

    // Deduct balance on Firestore
    DocumentReference studentRef = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code!);

    batch.update(studentRef, {'balance': FieldValue.increment(-price)});

    // Generate new entry in purchases log
    DocumentReference purchaseRef = FirebaseFirestore.instance
        .collection('data')
        .doc('purchases')
        .collection(um.grade!)
        .doc();

    batch.set(purchaseRef, purchaseVideoModel.toMap());

    // Update purchased_videos structure on Firestore using dot notation
    batch.update(
      studentRef,
      {
        'purchased_videos.$chapId.purchaseDateTime': DateTime.now(),
        'purchased_videos.$chapId.status': 'paid',
      },
    );

    try {
      // Commit to cloud database first
      await batch.commit();

      // 5. Finalize local state modifications on success
      um.purchasedVideos![chapId] = UserPurchasedChapterModel(
        lectures: {},
        status: 'paid',
        purchaseDateTime: DateTime.now(),
      );
      um.balance = (um.balance ?? 0) - price;

      await um.save();

      emit(PlatformBuyChaptersSuccessState(pop: pop));
    } catch (error) {
      debugPrint('Error during purchase execution: $error');
      emit(PlatformBuyLecturesFailState(error.toString()));
    }
  }

  void buyLectures({
    required int price,
    required String lecId,
    required String chapId,
    bool? isChapPaid,
    required List<WatchesVideoModel> newVids,
    required bool pop,
  }) async {
    emit(PlatformBuyLecturesLoadingState());
    UserModel um = Constants.userBox.get('user');

    // 1. Process local updates & merge new videos safely
    Map<String, UserPurchasedModel> updatedVideos =
        _mergeAndGetVideos(um, chapId, lecId, newVids);

    // 2. Guest Mode handling
    if (isGuest()) {
      await um.save();
      emit(PlatformBuyLecturesSuccessState(pop: pop));
      return;
    }

    // 3. Balance verification
    if (price > (um.balance ?? 0)) {
      emit(PlatformBuyLecturesFailState(S.current.no_balance_avl));
      return;
    }

    // 4. Firebase Operations utilizing WriteBatch
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Deduct balance on Firestore
    DocumentReference studentRef = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code!);

    batch.update(studentRef, {'balance': FieldValue.increment(-price)});
    if (isChapPaid != true) {
      // Generate new entry in purchases log
      DocumentReference purchaseRef = FirebaseFirestore.instance
          .collection('data')
          .doc('purchases')
          .collection(um.grade!)
          .doc();
      PurchaseVideoModel purchaseVideoModel = PurchaseVideoModel(
        date: DateTime.now(),
        stdCode: um.code,
        chapId: chapId,
        lecId: lecId,
      );

      batch.set(purchaseRef, purchaseVideoModel.toMap());
    }
    // Update purchased_videos structure on Firestore using dot notation
    batch.update(
      studentRef,
      {
        'purchased_videos.$chapId.lectures.$lecId.purchaseDateTime':
            DateTime.now(),
        // Clear any leftover "pending" flag from an abandoned online attempt.
        'purchased_videos.$chapId.lectures.$lecId.status': 'paid',
        'purchased_videos.$chapId.lectures.$lecId.videos':
            updatedVideos.map((key, value) => MapEntry(key, value.toMap()))
      },
    );

    try {
      // Commit to cloud database first
      await batch.commit();

      // 5. Finalize local state modifications on success
      um.purchasedVideos![chapId]!.lectures![lecId]!.purchaseDateTime =
          DateTime.now(); // Assumes your model has a date property
      um.purchasedVideos![chapId]!.lectures![lecId]!.status = 'paid';
      um.purchasedVideos![chapId]!.lectures![lecId]!.videos = updatedVideos;
      um.balance = (um.balance ?? 0) - price;

      await um.save();

      emit(PlatformBuyLecturesSuccessState(pop: pop));
    } catch (error) {
      debugPrint('Error during purchase execution: $error');
      emit(PlatformBuyLecturesFailState(error.toString()));
    }
  }

  /// Helper method to initialize nested structures safely, merge videos, and prevent duplicate logic.
  Map<String, UserPurchasedModel> _mergeAndGetVideos(
    UserModel um,
    String chapId,
    String lecId,
    List<WatchesVideoModel> newVids,
  ) {
    // Step A: Ensure the root Chapter model exists in the map
    if (!um.purchasedVideos!.containsKey(chapId)) {
      um.purchasedVideos![chapId] = UserPurchasedChapterModel(lectures: {});
    }

    // Step B: Ensure the Lectures map is initialized
    um.purchasedVideos![chapId]!.lectures ??= {};

    // Step C: Ensure the specific Lecture model exists in the map
    if (!um.purchasedVideos![chapId]!.lectures!.containsKey(lecId)) {
      um.purchasedVideos![chapId]!.lectures![lecId] =
          UserPurchasedLectureModel(videos: {});
    }

    // Step D: Ensure the Videos map inside the lecture is initialized
    um.purchasedVideos![chapId]!.lectures![lecId]!.videos ??= {};

    // Extract reference to working videos map
    Map<String, UserPurchasedModel> currentVideos =
        um.purchasedVideos![chapId]!.lectures![lecId]!.videos!;

    // Step E: Loop and merge/add new videos
    for (var vid in newVids) {
      if (vid.vidId == null) continue;

      if (currentVideos.containsKey(vid.vidId)) {
        // Use copyWith if your model supports it to preserve immutable integrity,
        // or modify the reference field safely as done here:
        final existingVid = currentVideos[vid.vidId]!;
        existingVid.avaWatches =
            (existingVid.avaWatches ?? 0) + (vid.avaWatches ?? 4);
      } else {
        currentVideos[vid.vidId!] = UserPurchasedModel(
          vidId: vid.vidId,
          stdWatches: 0,
          avaWatches: vid.avaWatches ?? 4,
          dateTime: DateTime.now(),
        );
      }
    }

    return currentVideos;
  }

  void addPdf({
    required String chapId,
    required String lecId,
    required String pdfId,
  }) async {
    emit(PlatformaddPdfLoadingState());

    UserModel um = Constants.userBox.get('user');
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Initialize purchased videos if null
    um.purchasedPdfs ??= {};
    um.purchasedPdfs![chapId] ??= {};
    um.purchasedPdfs![chapId]![lecId] ??= [];

    um.purchasedPdfs![chapId]![lecId]!.add(pdfId);

    // Prepare to update purchased videos in Firestore
    batch.update(
      FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code),
      {
        'purchased_pdfs': um.purchasedPdfs!.map((chapterKey, lectures) {
          return MapEntry(chapterKey, lectures.map((lecKey, purchases) {
            return MapEntry(
                lecKey, purchases.map((purchase) => purchase).toList());
          }));
        }),
      },
    );

    try {
      // Commit the batch
      await batch.commit();

      // Save updated user model
      await um.save();

      emit(PlatformaddPdfSuccessState());
    } catch (error) {
      debugPrint('Error during purchase: $error');
      emit(PlatformBuyLecturesFailState(error.toString()));
    }
  }

  bool checkVideoPurchased({
    required String vidId,
    required String lecId,
    required String chapId,
    // required int avaWatch,
  }) {
    UserModel um = Constants.userBox.get('user');

    // Check if the video has been purchased in the specified chapter and lecture
    UserPurchasedLectureModel? userPurchasedLectureModel =
        um.purchasedVideos?[chapId]?.lectures?[lecId];
    if (userPurchasedLectureModel != null &&
        userPurchasedLectureModel.status == 'paid') {
      UserPurchasedModel? userPurchasedModel =
          userPurchasedLectureModel.videos?[vidId];
      if (userPurchasedModel != null) {
        if ((userPurchasedModel.avaWatches ?? 4) >
            (userPurchasedModel.stdWatches ?? 0)) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } else {
      return false;
    }
    /*
    return um.purchasedVideos?[chapId]?[lecId] != null &&
        um.purchasedVideos![chapId]![lecId]!.any((element) =>
            element.vidId == vidId &&
            (element.stdWatches != element.avaWatches));
            */
  }

  bool checkPackagePurchased({
    required List<WatchesVideoModel> vidds,
    required String lecId,
    required String chapId,
  }) {
    UserModel? um = Constants.userBox.get('user');

    // التحقق من أن المستخدم ليس null وأن البيانات موجودة
    if (um == null || um.purchasedVideos == null) return false;

    var purchasedLecVideos =
        um.purchasedVideos![chapId]?.lectures?[lecId]?.videos;
    if (purchasedLecVideos == null) return false;

    if (um.purchasedVideos![chapId]?.lectures?[lecId]?.status != 'paid') {
      return false;
    }
    // التحقق مما إذا كانت القائمة موجودة
    if (purchasedLecVideos.isEmpty) return true;

    // التأكد من أن عدد الفيديوهات مطابق
    if (vidds.length > purchasedLecVideos.length) return true;

    // التحقق من كل فيديو في vidds
    for (var video in vidds) {
      // البحث عن الفيديو المطابق في purchasedLecVideos
      var purchasedVideo = purchasedLecVideos[video.vidId];

      // إذا لم يتم العثور على الفيديو في purchasedLecVideos
      if (purchasedVideo == null) {
        return true;
      }

      // مقارنة avaWatches القادم من vidds مع stdWatches القادم من purchasedLecVideos
      if ((purchasedVideo.avaWatches ?? 4) > (purchasedVideo.stdWatches ?? 0)) {
        return true; // إذا كان عدد المشاهدات المستهلكة وصل للحد الأقصى، نرجع false
      }
    }

    return false; // إذا نجحت كل التحققّات، نرجع true
  }

  bool checkPurchased({required String lecId, required String chapId}) {
    UserModel um = Constants.userBox.get('user');

    // Check if the purchasedVideos map contains the chapter ID and then the lecture ID
    return um.purchasedVideos?[chapId]?.lectures?[lecId] != null &&
        um.purchasedVideos?[chapId]?.lectures?[lecId]?.status == 'paid';
  }

  bool checkChapterPurchased({required String chapId}) {
    UserModel um = Constants.userBox.get('user');

    // Check if the purchasedVideos map contains the chapter ID.
    return um.purchasedVideos?[chapId] != null &&
        um.purchasedVideos![chapId]?.status == 'paid';
  }

  /// Whether the given lecture is currently waiting for an online payment to be
  /// confirmed (the student started an online/Fawry flow but didn't finish it).
  bool isLecturePending({required String chapId, required String lecId}) {
    UserModel um = Constants.userBox.get('user');
    return um.purchasedVideos?[chapId]?.lectures?[lecId]?.status == 'pending';
  }

  /// Whether the given chapter is currently waiting for an online payment.
  bool isChapPending({required String chapId}) {
    UserModel um = Constants.userBox.get('user');
    return um.purchasedVideos?[chapId]?.status == 'pending';
  }

/*
  /// Flags a lecture (or a whole chapter when [lecId] is null) as `pending`
  /// right after an online invoice is created, so the student sees an
  /// "awaiting payment" hint and can resume or start a fresh payment later.
  ///
  /// The flag is written both to Firestore and to the local Hive copy. A
  /// successful wallet/code/online purchase later overwrites it with `paid`.
  Future<void> markPaymentPending({
    required String chapId,
    String? lecId,
  }) async {
    if (isGuest()) return;
    UserModel um = Constants.userBox.get('user');

    try {
      final studentRef = FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code);

      // Ensure the nested local structure exists before flipping the status.
      um.purchasedVideos ??= {};
      if (lecId == null) {
        um.purchasedVideos![chapId] ??= UserPurchasedChapterModel(lectures: {});
        // Don't override an already-paid chapter.
        if (um.purchasedVideos![chapId]!.status == 'paid') return;
        um.purchasedVideos![chapId]!.status = 'pending';
        um.purchasedVideos![chapId]!.purchaseDateTime = DateTime.now();

        await studentRef.update({
          'purchased_videos.$chapId.status': 'pending',
          'purchased_videos.$chapId.purchaseDateTime': DateTime.now(),
        });
      } else {
        um.purchasedVideos![chapId] ??= UserPurchasedChapterModel(lectures: {});
        um.purchasedVideos![chapId]!.lectures ??= {};
        um.purchasedVideos![chapId]!.lectures![lecId] ??=
            UserPurchasedLectureModel(videos: {});
        if (um.purchasedVideos![chapId]!.lectures![lecId]!.status == 'paid') {
          return;
        }
        um.purchasedVideos![chapId]!.lectures![lecId]!.status = 'pending';
        um.purchasedVideos![chapId]!.lectures![lecId]!.purchaseDateTime =
            DateTime.now();

        await studentRef.update({
          'purchased_videos.$chapId.lectures.$lecId.status': 'pending',
          'purchased_videos.$chapId.lectures.$lecId.purchaseDateTime':
              DateTime.now(),
        });
      }

      await um.save();
      emit(PlatfomrRefreshState());
    } catch (error) {
      debugPrint('markPaymentPending error: $error');
    }
  }
*/
  void watchVideo({
    required String vidId,
    required bool valid,
    required int avaWatches,
    required String lecId,
    required String chapId,
  }) {
    emit(PlatformRemoveLecturesLoadingState());
    UserModel um = Constants.userBox.get('user');

    // 1. Safe deep lookups to prevent null-pointer crashes
    final chapter = um.purchasedVideos?[chapId];
    if (chapter == null || chapter.lectures == null) {
      emit(PlatformRemoveLecturesFailState(
          'Chapter or Lectures structure not found'));
      return;
    }

    final lecture = chapter.lectures![lecId];
    if (lecture == null) {
      emit(PlatformRemoveLecturesFailState('Lecture not found'));
      return;
    }

    // Ensure the videos map inside the lecture is initialized
    lecture.videos ??= {};
    Map<String, UserPurchasedModel> videosMap = lecture.videos!;

    // 2. Core watch verification and progression logic
    UserPurchasedModel updatedVideo;

    if (videosMap.containsKey(vidId)) {
      final existingVideo = videosMap[vidId]!;

      // Stop if the video has already been watched and the state is invalid
      if ((existingVideo.stdWatches ?? 0) != 0 && !valid) {
        emit(PlatformRemoveLecturesFailState(
            'Invalid state: cannot watch video'));
        return;
      }

      // Increment watch counts safely
      existingVideo.stdWatches = (existingVideo.stdWatches ?? 0) + 1;
      existingVideo.dateTime = DateTime.now();
      updatedVideo = existingVideo;
    } else {
      // If it's a completely new video record, create a new model instance
      updatedVideo = UserPurchasedModel(
        vidId: vidId,
        stdWatches: 1,
        avaWatches: avaWatches,
        dateTime: DateTime.now(),
      );
      videosMap[vidId] = updatedVideo;
    }

    // 3. Update local UI list state cleanly if tracking it concurrently
    int lecIdx =
        purchasedVideosList.indexWhere((element) => element.lectureId == lecId);
    if (lecIdx != -1) {
      purchasedVideosList[lecIdx].stdWatches += 1;
    }

    // 4. Sequence database persistence: Local Hive first, then sync to Firestore
    um.save().then((_) {
      FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code!)
          .update({
        'purchased_videos.$chapId.lectures.$lecId.videos.$vidId':
            updatedVideo.toMap(),
      }).then((_) {
        emit(PlatformRemoveLecturesSuccessState());
      }).catchError((error) {
        debugPrint('Firestore Update Error: $error');
        emit(PlatformRemoveLecturesFailState(error.toString()));
      });
    }).catchError((error) {
      debugPrint('Hive Save Error: $error');
      emit(PlatformRemoveLecturesFailState(
          'Error saving user model locally: ${error.toString()}'));
    });
  }

/*
  void watchVideo({
    required String vidId,
    required bool valid,
    required int avaWatches,
    required String lecId,
    required String chapId,
  }) {
    emit(PlatformRemoveLecturesLoadingState());
    UserModel um = Constants.userBox.get('user');

    // Check if the chapter and lecture exist in purchased videos
    if (um.purchasedVideos?[chapId]?.lectures?[lecId] != null) {
      Map<String, UserPurchasedModel>? purchases =
          um.purchasedVideos![chapId]!.lectures![lecId]!.videos;

      if (purchases![vidId] != null) {
        UserPurchasedModel? video = purchases[vidId];
        if ((video?.stdWatches ?? 0) != 0 && !valid) return;

        video?.stdWatches = ((video.stdWatches)! + 1);
        video?.dateTime = DateTime.now();
      } else {
        um.purchasedVideos![chapId]!.lectures![lecId]!.videos![vidId] =
            UserPurchasedModel(
          vidId: vidId,
          stdWatches: 1,
          avaWatches: avaWatches,
          dateTime: DateTime.now(),
        );
      }
      int lecIdx = purchasedVideosList
          .indexWhere((element) => element.lectureId == lecId);
      if (lecIdx != -1) {
        purchasedVideosList[lecIdx].stdWatches += 1;
      }

      // Save updated user model and Firestore in sequence
      um.save().then((_) {
        FirebaseFirestore.instance
            .collection('data')
            .doc('students')
            .collection(um.grade!)
            .doc(um.code!)
            .update({
          'purchased_videos.$chapId.lectures.$lecId.videos.$vidId': um
              .purchasedVideos![chapId]!.lectures![lecId]!.videos![vidId]!
              .toMap(),
        }).then((_) {
          emit(PlatformRemoveLecturesSuccessState());
        }).catchError((error) {
          emit(PlatformRemoveLecturesFailState(error.toString()));
        });
      }).catchError((error) {
        emit(PlatformRemoveLecturesFailState(
            'Error saving user model: ${error.toString()}'));
      });
    } else {
      emit(PlatformRemoveLecturesFailState('Lecture not found'));
    }
  }
*/
  int curIdx = 0;
  void changeBottomIndex(int idx) {
    curIdx = idx;
    emit(PaltformChangeIndexState());
  }

  /// مرجع لـ PageController الخاص بـ HomeLayout (يُسجَّل في initState).
  /// يُستخدم للتنقّل بين تبويبات الـ Home برمجيًا (مثلاً من الإشعارات).
  PageController? homePageController;

  /// الانتقال إلى تبويب معيّن في HomeLayout (0=home ... 3=quizzes ... 4=profile).
  /// يعيد المحاولة حتى يصبح الـ PageView جاهزًا (مفيد عند فتح التطبيق من إشعار).
  void navigateToHomeTab(int index, {int attempt = 0}) {
    changeBottomIndex(index);
    if (homePageController != null && homePageController!.hasClients) {
      homePageController!.jumpToPage(index);
    } else if (attempt < 20) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToHomeTab(index, attempt: attempt + 1);
      });
    }
  }

  bool isDarkMode = SharedPrefHelper.getData('isDarkMode') ?? false;
  void changeDarkMode() {
    isDarkMode = !isDarkMode;
    if (isPurple) {
      if (isDarkMode) {
        Constants.wallpaberDark = Constants.wallpaberPurbleDark;
      } else {
        Constants.wallpaberLight = Constants.wallpaberPurbleLight;
      }
    } else {
      if (isDarkMode) {
        Constants.wallpaberDark = Constants.wallpaberBlueDark;
      } else {
        Constants.wallpaberLight = Constants.wallpaberBlueLight;
      }
    }
    SharedPrefHelper.saveData(key: 'isDarkMode', value: isDarkMode)
        .then((value) {
      emit(PlatformChangeModeState());
    }).catchError((onError) {
      debugPrint('Error change mode');
    });
  }

  bool isPurple = SharedPrefHelper.getData('isPurple') ?? false;

  void changeAppColor() {
    isPurple = !isPurple;
    if (isPurple) {
      AppColors.appPrimaryColor = AppColors.appPurblePrimaryColor;
      AppColors.appSecondaryColor = AppColors.appPurbleSecondaryColor;
      if (isDarkMode) {
        Constants.wallpaberDark = Constants.wallpaberPurbleDark;
      } else {
        Constants.wallpaberLight = Constants.wallpaberPurbleLight;
      }
    } else {
      AppColors.appPrimaryColor = AppColors.appGoldPrimaryColor;
      AppColors.appSecondaryColor = AppColors.appGoldSecondaryColor;
      if (isDarkMode) {
        Constants.wallpaberDark = Constants.wallpaberBlueDark;
      } else {
        Constants.wallpaberLight = Constants.wallpaberBlueLight;
      }
    }
    SharedPrefHelper.saveData(key: 'isPurple', value: isPurple).then((value) {
      emit(PlatformChangeAppColorState());
    }).catchError((onError) {
      debugPrint('Error change mode');
    });
  }

  Future<String> getLink(String platform) async {
    DocumentSnapshot<Map<String, dynamic>> ds = await FirebaseFirestore.instance
        .collection('social_links')
        .doc('${platform}_link')
        .get();

    return ds.data()!['link'].toString();
  }

  bool isAr = SharedPrefHelper.getData('isAr') ?? true;
  void changeLang() {
    isAr = !isAr;
    SharedPrefHelper.saveData(key: 'isAr', value: isAr).then((value) {
      emit(PlatformChangeLanguageState());
    }).catchError((onError) {
      debugPrint('Error change lang');
    });
  }

  void rebuild() {
    emit(PlatformRebuildStateState());
  }

// edit profile

  File? userImage;

  Future<File?>? pickImageFromGallery(context) async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = (await file.readAsBytes()).lengthInBytes;
      final kb = bytes / 1024;
      if ((kb / 1024) <= 1.5) {
        emit(PlatformPickImageFromGallerySuccessState());
        return File(file.path);
      } else {
        emit(PlatformPickImageFromGalleryFailState(
            S.of(context).choose_less_img));
        return null;
      }
    }
    emit(PlatformPickImageFromGalleryFailState(S.of(context).no_img_selc));
    return null;
  }

  Future<String> uplaodImage({
    required File? file,
    String? childName,
    required String img,
  }) async {
    emit(PlatformUplaodImageLoadingState());
    if (file != null) {
      Reference ref = FirebaseStorage.instance.ref().child(
          '${childName ?? 'user_images'}/${Uri.file(file.path).pathSegments.last}');
      TaskSnapshot snapShot = await ref.putFile(file);
      String downloadUrl = await snapShot.ref.getDownloadURL();

      if (img != Constants.img) {
        await FirebaseStorage.instance.refFromURL(img).delete();
      }
      return downloadUrl;
    }
    emit(PlatformUplaodImageFailState());
    return '';
  }

  void updatePassword({
    required String oldPass,
    required String newPass,
  }) {
    emit(PlatformUpdatePasswordLoadingState());
    // final user = FirebaseAuth.instance.currentUser;
    UserModel um = Constants.userBox.get('user');

    try {
      /*
      // Re-authenticate the user
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPass,
      );
      user.reauthenticateWithCredential(credential).then((value) {
        user.updatePassword(newPass).then((value) {
          */
      FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code)
          .update({'password': newPass}).then((value) {
        um.password = newPass;
        um.save().then((value) {
          emit(PlatformUpdatePasswordSuccessState());
        }).catchError((onError) {
          emit(PlatformUpdatePasswordFailState(' ${onError.toString()}'));
        });
      }).catchError((onError) {
        emit(PlatformUpdatePasswordFailState(onError.toString()));
      });
      /*
        }).catchError((onError) {
          emit(PlatformUpdatePasswordFailState(onError.toString()));
        });
        
      }).catchError((onError) {
        emit(PlatformUpdatePasswordFailState(onError.toString()));
      });
      */
    } catch (e) {
      emit(PlatformUpdatePasswordFailState(e.toString()));
    }
  }

  void uplaodUpdatedUserData({
    required ar_fname,
    required ar_sname,
    required ar_thname,
    required fname,
    required sname,
    required String img,
    required thname,
  }) {
    emit(PlatformUplaodUpdatedDataLoadingState());
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code)
        .update({
      "ar_fname": ar_fname,
      "ar_sname": ar_sname,
      "ar_thname": ar_thname,
      "fname": fname,
      "sname": sname,
      "thname": thname,
      "img": img.isEmpty ? um.img : img,
    }).then((value) {
      um.ar_fname = ar_fname;
      um.ar_sname = ar_sname;
      um.ar_thname = ar_thname;
      um.fname = fname;
      um.sname = sname;
      um.thname = thname;
      um.img = img.isEmpty ? um.img : img;
      um.save().then((value) {
        emit(PlatformUplaodUpdatedDataSuccessState());
      }).catchError((onError) {
        emit(PlatformUplaodUpdatedDataFailState(' ${onError.toString()}'));
      });
    }).catchError((onError) {
      emit(PlatformUplaodUpdatedDataFailState(onError.toString()));
    });
  }

  // quizes
  Future<int> getMinDegree({
    required String quizId,
  }) async {
    String handleQuizId =
        quizId.contains(',') ? quizId.split(',').last : quizId;
    debugPrint(quizId.split(',').last);

    final quizDoc = await FirebaseFirestore.instance
        .collection('data')
        .doc('quizes')
        .collection(Components.getGrade(handleQuizId[0]))
        .doc(handleQuizId)
        .get();
    final doc = await FirebaseFirestore.instance
        .collection('data')
        .doc('videos')
        .collection(Components.getGrade(handleQuizId[0]))
        .doc(quizDoc.data()?['chapId'])
        .collection('lectures')
        .doc(quizDoc.data()?['lecId'])
        .collection('data')
        .doc(quizDoc.data()?['quizId'])
        .get();

    return doc.data()?['minDegree'] ?? 0;
  }

  Future<bool> getShowDegree({required String quizId}) async {
    String handleQuizId =
        quizId.contains(',') ? quizId.split(',').last : quizId;
    final doc = await FirebaseFirestore.instance
        .collection('data')
        .doc('quizes')
        .collection(Components.getGrade(handleQuizId[0]))
        .doc(handleQuizId)
        .get();

    return doc.data()?['showDegree'] ?? true;
  }

  void checkQuiz({
    required String quizCode,
    context,
    String? title,
    String? vidId,
    int? minDegree,
  }) {
    emit(PlatformCheckQuizLoadingState());
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('quizes')
        .collection(um.grade!)
        .doc(quizCode)
        .get()
        .then((value) {
      if (value.data() != null) {
        FirebaseFirestore.instance
            .collection('data')
            .doc('quizes')
            .collection(um.grade!)
            .doc(quizCode)
            .get()
            .then((value) {
          if (value.data()!['isValid']) {
            //  debugPrint(vidId);
            // TODO
            if (vidId != null) {
              getQuestionData(
                  quizCode: quizCode, vidId: vidId, minDegree: minDegree);
            } else {
              bool isinList = um.stdQuizes?[quizCode] != null &&
                  um.stdQuizes![quizCode]!.id.isNotEmpty;
              if (isinList) {
                emit(
                  PlatformCheckQuizFailState(' You Answered this Quiz Before'),
                );
              } else {
                if (value.data()?['validUntil'] != null) {
                  if ((value.data()?['validUntil'] as Timestamp)
                      .toDate()
                      .isAfter(DateTime.now())) {
                    getQuestionData(quizCode: quizCode);
                  } else {
                    emit(PlatformCheckQuizFailState(
                        ' ${S.current.exam_expired}'));
                  }
                } else {
                  getQuestionData(quizCode: quizCode);
                }
              }
            }
          } else {
            emit(PlatformCheckQuizFailState(' Not Valid Code'));
          }
        }).catchError((onError) {
          emit(PlatformCheckQuizFailState(onError.toString()));
        });
      } else {
        emit(PlatformCheckQuizFailState(' Not Valid Code'));
      }
    }).catchError((onError) {
      emit(PlatformCheckQuizFailState(onError.toString()));
    });
  }

  // quiz
  static QuizModel? quizModel;
  void setQuizModel(QuizModel quiz) {
    quizModel = quiz;
  }

  void getQuestionData({
    required String quizCode,
    String? vidId,
    int? minDegree,
  }) {
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('quizes')
        .collection(um.grade!)
        .doc(quizCode)
        .get()
        .then((value) {
      setQuizModel(QuizModel.fromJson(value.data()!));
      debugPrint(vidId);
      if (vidId != null) {
        emit(PlatformCheckLectureQuizSuccessState(vidId, minDegree));
      } else {
        emit(PlatformCheckQuizSuccessState(title: quizModel?.title ?? ''));
      }
    }).catchError((onError) {
      debugPrint(onError.toString());
      emit(PlatformCheckQuizFailState(onError.toString()));
    });
  }

  List<QuestionModel> quizQuestions = [];
  late Map<String, dynamic> stdQuizAnsws;
  void getQuestions({
    required String quizCode,
    required bool isInQuizScreen,
    String? lecId,
  }) {
    debugPrint(quizModel!.title);
    quizQuestions = [];
    emit(PlatformQuizGetQuizesLoadingState());
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('quizes')
        .collection(um.grade!)
        .doc(quizCode)
        .collection('questions')
        .get()
        .then((value) {
      debugPrint(value.docs.length.toString());
      for (int i = 0; i < value.docs.length; i++) {
        quizQuestions.add(QuestionModel.fromJson(value.docs[i].data()));
      }

      if (isInQuizScreen) {
        emit(PlatformQuizGetQuizesSuccessState(quizQuestions));
      } else {
        stdQuizAnsws = {};
        writtenAnswsMap = {};
        if (quizModel!.isRand) {
          quizQuestions.shuffle();
          debugPrint('shuffled');
        } else {
          quizQuestions.sort((a, b) {
            if (a.index != null && b.index != null) {
              return a.index!.compareTo(b.index!);
            }
            return a.date.compareTo(b.date);
          });
          debugPrint('sorted');
        }
        addStdPoints(isComplete: false, lecId: lecId);
      }
    }).catchError((onError) {
      debugPrint(onError.toString());
      emit(PlatformQuizGetQuizesFailState(onError.toString()));
    });
  }

  List<QuestionModel> questionbankAnswsQuestions = [];
  void getQuestionbankQuestions({
    required String id,
  }) {
    questionbankAnswsQuestions = [];
    emit(PlatformQuizGetQuestionBankLoadingState());
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code)
        .collection('questionbank')
        .doc(id)
        .collection('questions')
        .orderBy(FieldPath.documentId)
        .get()
        .then((value) {
      for (var doc in value.docs) {
        questionbankAnswsQuestions.add(QuestionModel.fromJson(doc.data()));
      }

      emit(PlatformQuizGetQuestionBankSuccessState(questionbankAnswsQuestions));
    }).catchError((onError) {
      debugPrint('Error: $onError');
      emit(PlatformQuizGetQuestionBankFailState(onError.toString()));
    });
  }

  void getAnswsChapters(String id) {
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(um.grade!)
        .doc(um.code)
        .collection('questionbank')
        .doc(id)
        .get()
        .then((snapshot) {
      // Directly cast the data to the desired type
      Map<String?, List<String?>>? chaptersMap =
          (snapshot.data()?['chapters'] as Map<String?, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String?>.from(value)),
      );

      emit(PlatformQuizGetQuestionBankChaptersSuccessState(chaptersMap ?? {}));
    }).catchError((onError) {});
  }

  void selectAnswer(String queId, int ansIdx) {
    stdQuizAnsws[queId] = ansIdx;
    emit(PlatformQuizSelectAnswerState());
  }

  void selectQuestionbankAnswer(String queId, int ansIdx) {
    stdQuestionbankAnsws[queId] = ansIdx;
    emit(PlatformQuestionbankSelectAnswerState());
  }

  bool isLast = false;
  void changeIsLast(bool isLastt) {
    isLast = isLastt;
    emit(PlatformQuizCheckIsLastState());
  }

  bool isStart = true;
  void changeIsStart(bool isStartt) {
    isStart = isStartt;
    emit(PlatformQuizCheckIsStartState());
  }

  double getResult() {
    double score = 0;
    for (int i = 0; i < quizQuestions.length; i++) {
      if (stdQuizAnsws[quizQuestions[i].id] is int &&
          stdQuizAnsws[quizQuestions[i].id] == quizQuestions[i].ansIdx) {
        score += quizQuestions[i].degree;
      }
    }
    return score;
  }

  Future<void> addStdPoints({
    required bool isComplete,
    String? lecId,
  }) async {
    emit(PlatformAddStdPointsLoadingState());

    try {
      UserModel um = Constants.userBox.get('user');
      String targetId =
          lecId == null ? quizModel!.id : '$lecId,${quizModel!.id}';

      // 1. Ensure map is initialized
      um.stdQuizes ??= {};
      final existingQuiz = um.stdQuizes![targetId];
      final now = DateTime.now();

      // 2. Prepare user answers map safely
      Map<String, dynamic> userAnsIdx = Map<String, dynamic>.from(stdQuizAnsws);
      writtenAnswsMap.forEach((questionId, model) {
        final combinedValue = [model.text, ...model.imagesUrl].join(',');
        userAnsIdx[questionId] = combinedValue;
      });

      StdQuizModel updatedQuizModel;

      // 3. Create or Update model safely without risking null pointer crashes
      if (existingQuiz != null && existingQuiz.id.isNotEmpty) {
        int triesNum = existingQuiz.triesNum;

        updatedQuizModel = existingQuiz.copyWith(
          dateTime: isComplete ? existingQuiz.dateTime : now,
          degree: isComplete ? getResult() : 0,
          triesNum: isComplete ? triesNum : triesNum + 1,
          userAnsIdx: userAnsIdx,
          submitTime: isComplete ? now : null,
        );
      } else {
        // If completely new, get status/purchase date from payment phase defaults if any
        updatedQuizModel = StdQuizModel(
          id: targetId,
          title: quizModel!.title,
          dateTime: now,
          fullMark: quizModel!.fullMark,
          questionNums: quizModel!.questionsNum,
          degree: isComplete ? getResult() : 0,
          triesNum: 1,
          userAnsIdx: userAnsIdx,
          submitTime: isComplete ? now : null,
          status: existingQuiz?.status,
          purchaseDateTime: existingQuiz?.purchaseDateTime,
        );
      }

      // 4. Update the local copy
      um.stdQuizes![targetId] = updatedQuizModel;

      // 5. Sequence saves securely using async/await
      await um.save();

      await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code)
          .update({
        'stdQuizes.$targetId': updatedQuizModel.toJson(),
      });

      // 6. Emit corresponding final state
      if (isComplete) {
        emit(PlatformAddStdPointsSuccessState());
      } else {
        emit(PlatformQuizGetQuizesSuccessState(quizQuestions));
      }
    } catch (onError) {
      debugPrint("Error inside addStdPoints: ${onError.toString()}");
      emit(PlatformAddStdPointsFailState(onError.toString()));
    }
  }

  double getQuestionbankResult() {
    double score = 0;
    for (int i = 0; i < questionbankQuestions.length; i++) {
      if (stdQuestionbankAnsws[questionbankQuestions[i].id] ==
          questionbankQuestions[i].ansIdx) {
        score++;
      }
    }
    return score;
  }

/*
  void addStdQuestionbankPoints({
    required bool isComplete,
    Map<String?, List<String?>>? chapters,
  }) {
    emit(PlatformAddStdQuestionbankPointsLoadingState());
    UserModel um = Constants.userBox.get('user');
    int idx = 1;

    for (var e in um.stdQuizes!) {
      if (e.id.startsWith('qb')) {
        idx++;
      }
    }

    StdQuizModel stdQuizModel = StdQuizModel(
      id: isComplete ? 'qb ${idx - 1}' : 'qb $idx',
      title: isComplete ? 'Exam ${idx - 1}' : 'Exam $idx',
      dateTime: DateTime.now(),
      fullMark: questionbankQuestions.length,
      questionNums: questionbankQuestions.length,
      degree: isComplete ? getQuestionbankResult() : 0,
      triesNum: 1,
      userAnsIdx: stdQuestionbankAnsws,
      //  isGetMinDegree: true,
    );
    debugPrint(stdQuizModel.id);

    if (isComplete) {
      // TODO

      int index = um.stdQuizes!.indexOf(
          um.stdQuizes!.firstWhere((element) => element.id == stdQuizModel.id));
      print('wahba $index');

      um.stdQuizes![index] = stdQuizModel;
    } else {
      DocumentReference<Map<String, dynamic>> doc = FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code)
          .collection('questionbank')
          .doc('qb $idx');
      doc.set({"chapters": chapters}).then((value) {
        for (int i = 0; i < questionbankQuestions.length; i++) {
          String paddedIndex = i.toString().padLeft(4, '0');
          doc
              .collection('questions')
              .doc(paddedIndex)
              .set(questionbankQuestions[i].toMap())
              .then((value) {})
              .catchError((onError) {
            emit(PlatformQuizGetQuestionBankFailState(onError.toString()));
            debugPrint(onError.toString());
          });
        }
        um.stdQuizes!.add(stdQuizModel);
      }).catchError((onError) {
        emit(PlatformQuizGetQuestionBankFailState(onError.toString()));
      });
    }
    um.save().then((value) {
      FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code)
          .update({
        'stdQuizes': um.stdQuizes!.map((quiz) => quiz.toJson()).toList()
      }).then((value) {
        if (isComplete) {
          emit(PlatformAddStdQuestionbankPointsSuccessState());
        } else {
          emit(PlatformQuizGetQuestionBankSuccessState(questionbankQuestions));
        }
      }).catchError((onError) {
        emit(PlatformAddStdQuestionbankPointsFailState(onError.toString()));
      });
    }).catchError((onError) {
      emit(PlatformAddStdQuestionbankPointsFailState(' ${onError.toString()}'));
    });
  }
*/
  Map<String, WrittenAnswsModel> writtenAnswsMap = {};

  void deleteQuiz() {
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection('third')
        .doc('32640640')
        .update({'stdQuizes': []});
    debugPrint('quiz deleted');
  }

// 🟢 Save written text
  void saveWrittenAnswer(String questionId, String text) {
    // if map doesn't have entry yet → create one
    if (writtenAnswsMap[questionId] == null) {
      writtenAnswsMap[questionId] = WrittenAnswsModel(text, []);
    } else {
      writtenAnswsMap[questionId]!.text = text;
    }

    emit(WrittenAnswerUpdated());
  }

// 🟢 Add image URL after upload
  void addWrittenImage(String questionId, String url) {
    // if map doesn't have entry yet → create one
    if (writtenAnswsMap[questionId] == null) {
      writtenAnswsMap[questionId] = WrittenAnswsModel('', [url]);
    } else {
      writtenAnswsMap[questionId]!.imagesUrl.add(url);
    }

    emit(WrittenAnswerUpdated());
  }

  // 🟢 Remove image
  void removeWrittenImage(String questionId, String url) {
    writtenAnswsMap[questionId]?.imagesUrl.remove(url);
    emit(WrittenAnswerUpdated());
  }

  // 🟢 Upload progress states
  void setUploading(bool isUploading) {
    emit(WrittenAnswerUploading(isUploading));
  }

  Future<void> saveStdToExcel() async {
    String grade = 'second';
    final CollectionReference usersCollection = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(grade);

    // Fetch all documents in the collection
    QuerySnapshot snapshot = await usersCollection.get();

    // Map to store unique phone numbers with corresponding name and age
    Map<String, Map<String, dynamic>> uniqueUsersMap = {};

    for (var doc in snapshot.docs) {
      String phoneNumber = doc['phoneNum'] as String;
      String name =
          '${doc['ar_fname'] ?? ''} ${doc['ar_sname'] ?? ''} ${doc['ar_thname'] ?? ''}';
      String groupName = doc['groupName'] as String;

      // If the phone number is not already in the map, add it
      if (!uniqueUsersMap.containsKey(phoneNumber)) {
        debugPrint('Ahmedd');
        uniqueUsersMap[phoneNumber] = {
          'phoneNumber': phoneNumber,
          'name': name,
          'groupName': groupName,
        };
      }
    }

    // Convert the map values to a list
    List<Map<String, dynamic>> uniqueUsersList = uniqueUsersMap.values.toList();

    // Create an Excel document
    var excel = Excel.createExcel();
    Sheet sheetObject = excel[grade];

    // Add header row
    sheetObject.appendRow([
      TextCellValue('Name'),
      TextCellValue('Phone Number'),
      TextCellValue('Group Name'),
    ]);

    // Add data rows
    for (var user in uniqueUsersList) {
      sheetObject.appendRow([
        TextCellValue(user['name']),
        TextCellValue(user['phoneNumber']),
        TextCellValue(user['groupName']),
      ]);
    }

    // Save the file locally
    Directory? directory = await getDownloadsDirectory();
    String filePath = '${directory!.path}/${grade}Students.xlsx';
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    debugPrint('Excel file saved at: $filePath');
  }

  // Requests (Wahba)

  List<RequsetsModel> requests1 = [];
  List<RequsetsModel> filterRequests1 = [];

  List<RequsetsModel> grade3 = [];
  List<RequsetsModel> requests3 = [];
  List<ChatModel> messages = [];

  static bool student = true;
  int choice = 0;
  int? code;

  TextEditingController requestController = TextEditingController();
  TextEditingController chatController = TextEditingController();
  TextEditingController createLectureAttendanceController =
      TextEditingController();

  Future<void> addRequest(
    List<String> imagaeUrl, {
    @required String? senderId,
    required String request,
    required String State,
    required String stdToken,
    required String title,
  }) async {
    emit(AddRequestLoadingState());
    UserModel? um = Constants.userBox.get('user');
    String? grade = um!.grade;
    String id = FirebaseFirestore.instance
        .collection('Requests')
        .doc(grade)
        .collection('data')
        .doc()
        .id;
    print(grade);
    try {
      await FirebaseFirestore.instance
          .collection('Requests')
          .doc(grade)
          .collection('data')
          .doc(id)
          .set({
        'message': request,
        'receiver_id': '0000',
        'sender_id': senderId,
        'state': State,
        'id': id,
        'stdToken': stdToken,
        'imageurl': imagaeUrl,
        'date': DateTime.now().toString(),
        'grade': grade,
        'title': title,
      });
      getRequests();
      emit(AddRequestSuccessState());
    } catch (error) {
      emit(AddRequestErrorState());
      print('error');
      debugPrint(error.toString());
    }
  }
/*
  List<RequsetsModel> recentRequests = [];
  void getRecentRequests() {
    for (int i = 0; i < requests1.length; i++) {
      while (recentRequests.length <= 2) {
        if (requests1[i].state != 'ended') {
          recentRequests.add(requests1[i]);
        }
      }
    }
  }
  */

  Future<void> getRequests() async {
    print('ahmed');
    UserModel? um = Constants.userBox.get('user');
    requests1 = [];
    FirebaseFirestore.instance
        .collection('Requests')
        // TODO change to um.grade
        .doc(um!.grade!)
        .collection('data')
        // TODO change to um.code
        .where('sender_id', isEqualTo: um.code)
        .orderBy("date", descending: true)
        .get()
        .then((value) {
      for (int i = 0; i < value.docs.length; i++) {
        requests1.add(RequsetsModel.fromJson(value.docs[i].data()));
      }
      filterRequests1 = requests1;
      print('$filterRequests1 Ahmed');

      // print(requests1);
      filteredRequests(choice);
      emit(PlatformGetRequestsSuccessState());
      print('Done');
    }).catchError((error) {
      //  emit(PlatformGetRequestsFailState(error.toString()));
      print(error.toString());
    });
  }

  // Future<void> getRequests2() {
  //   emit(GetRequests2state());
  //   requests2 = [];

  //   FirebaseFirestore.instance
  //       .collection('Requests').doc(requestsGroup).collection('data')
  //       .where('receiver_id', isEqualTo: "0000")
  //       // .orderBy("date")
  //       .get()
  //       .then((value) {
  //     for (int i = 0; i < value.docs.length; i++) {
  //       requests2.add(RequsetsModel.fromJson(value.docs[i].data()));
  //     }
  //     // print(requests1);
  //     emit(states());
  //     print('Done');
  //   }).catchError((error) {
  //     print(error);
  //     emit(states());
  //   });
  //   return Future(() => null);
  // }
  Future<void> getRequests2() async {
    emit(GetRequests2state());
    print(requestsGroup);

    FirebaseFirestore.instance
        .collection('Requests')
        .doc(requestsGroup)
        .collection('data')
        .where('receiver_id', isEqualTo: "0000")
        // .orderBy("date")
        .snapshots()
        .listen((snapshot) {
      choosenRequestsGrade = [];
      for (var doc in snapshot.docs) {
        choosenRequestsGrade.add(RequsetsModel.fromJson(doc.data()));
      }
      print(choosenRequestsGrade.length);
      emit(states());
    }, onError: (error) {
      print(error);
      emit(states());
    });
  }

  void createChat(RequsetsModel request) {
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(request.grade)
        .collection('data')
        .doc(request.id)
        .collection("Chat")
        .doc()
        .set({
          'type': false,
          'message': request.request,
          'id': request.senderId,
          'time': DateTime.now().toString()
        })
        .then((value) => emit(states()))
        .catchError((error) {
          print(error);
        });
  }

  Future<void> addMessage(
      ReqId, String? message, String id, String type, String? imagaeUrl) {
    UserModel um = Constants.userBox.get('user');
    emit(AddMessageLoadingState());
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(um.grade)
        .collection('data')
        .doc(ReqId)
        .collection("Chat")
        .doc()
        .set({
      'message': message,
      'id': id,
      'time': DateTime.now(),
      "imagaeUrl": imagaeUrl,
      'type': type
    }).then((value) {
      chatController.clear;
      img = null;
      swap();
      // getChat(model);
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }

  void getChat(String requestId) {
    messages = [];
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(um.grade)
        .collection('data')
        .doc(requestId)
        .collection("Chat")
        .orderBy('time')
        .snapshots()
        .listen((snapshot) {
      messages = snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data()))
          .toList()
          .reversed
          .toList();

      emit(states());
    });
  }

  void updateRequest(id, newState, recId) {
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(requestsGroup)
        .collection('data')
        .doc(id)
        .update({"state": newState, 'receiver_id': "$recId"}).then((value) {
      emit(PlatformUpdateRequestStatueState());
      // getRequests2();
      emit(states());
    }).catchError((error) {
      emit(states());
    });
  }

/*
  void createChat(RequsetsModel request) {
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(request.grade)
        .collection('data')
        .doc(request.id)
        .collection("Chat")
        .doc()
        .set({
          'type': false,
          'message': request.request,
          'id': request.senderId,
          'time': DateTime.now().toString()
        })
        .then((value) => emit(states()))
        .catchError((error) {
          print(error);
        });
  }
  

  Future<void> addMessage(ReqId, String? message, String id,
      RequsetsModel model, bool type, String? imagaeUrl) {
    emit(AddMessageLoadingState());
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(model.grade)
        .collection('data')
        .doc(ReqId)
        .collection("Chat")
        .doc()
        .set({
      'message': message,
      'id': id,
      'time': DateTime.now().toString(),
      "imagaeUrl": imagaeUrl,
      'type': type
    }).then((value) {
      chatController.clear;
      img = null;
      swap();
      // getChat(model);
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }

  void getChat(RequsetsModel? request) {
    messages = [];
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(request!.grade)
        .collection('data')
        .doc(request.id)
        .collection("Chat")
        .orderBy('time')
        .snapshots()
        .listen((snapshot) {
      messages = snapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data()))
          .toList()
          .reversed
          .toList();

      emit(states());
    });
  }

  void updateRequest(id, newState, recId) {
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(requestsGroup)
        .collection('data')
        .doc(id)
        .update({"state": newState, 'receiver_id': "$recId"}).then((value) {
      emit(PlatformUpdateRequestStatueState());
      // getRequests2();
      emit(states());
    }).catchError((error) {
      emit(states());
    });
  }
*/
  List<File?> images = [];

  void pick(ImageSource source) async {
    final picker = ImagePicker();
    emit(ImageLoadingState());

    await picker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        // return await file.readAsBytes();
        images.add(File(value.path));
        emit(PickImageState());
      }
    });
  }

  File? img;
  void pickChatImage(ImageSource source) async {
    final picker = ImagePicker();
    emit(ImageLoadingState());
    await picker.pickImage(source: ImageSource.gallery).then((value) {
      if (value != null) {
        // return await file.readAsBytes();
        img = File(value.path);
        emit(PickImageState2());
      }
      print("Image Picked");
    });
  }

  String chatImageUrl = "";
  Future<String> uploadChatimage({
    required File? file,
    String? id,
  }) async {
    emit(uploadChatimagestate());
    String url = '$id/${Uri.file(file!.path)}';
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('$id/${Uri.file(file.path).pathSegments.last}');
    TaskSnapshot snapShot = await ref.putFile(file);
    String downloadURL = await snapShot.ref.getDownloadURL();
    url = downloadURL;
    print("Url is $url");
    return url;
  }

  Future<String>? url;

  Future<List<String>> uplaodImage2({
    required List<File?> files,
  }) async {
    emit(AddRequestLoadingState());
    UserModel? um = Constants.userBox.get('user');
    List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      Reference ref = FirebaseStorage.instance.ref().child(
          'requests/${um!.grade}/${um.code!}/${Uri.file(files[i]!.path).pathSegments.last}');
      TaskSnapshot snapShot = await ref.putFile(files[i]!);
      String downloadURL = await snapShot.ref.getDownloadURL();
      urls.add(downloadURL);
    }

    return urls;
  }

  void filteredRequests(int filter) {
    if (filter == 0) {
      choice = 0;
      filterRequests1 = requests1;
      emit(PlatformChangeRequestFilterState());
    } else if (filter == 1) {
      choice = 1;

      filterRequests1 = [];
      for (int i = 0; i < requests1.length; i++) {
        if (requests1[i].state == "taken") {
          filterRequests1.add(requests1[i]);
        }
      }
      emit(PlatformChangeRequestFilterState());
    } else if (filter == 2) {
      choice = 2;

      filterRequests1 = [];

      for (int i = 0; i < requests1.length; i++) {
        if (requests1[i].state == "pending") {
          filterRequests1.add(requests1[i]);
        }
      }
      emit(PlatformChangeRequestFilterState());
    } else if (filter == 3) {
      choice = 3;

      filterRequests1 = [];
      for (int i = 0; i < requests1.length; i++) {
        if (requests1[i].state == "ended") {
          filterRequests1.add(requests1[i]);
        }
      }

      emit(PlatformChangeRequestFilterState());
    }
    print("done swapping");
  }

  int len = 10;
  void deleteImage(index) {
    images.removeAt(index);

    emit(DeleteImage());
  }

  Icon icon = Icon(
    Icons.add,
    size: 32.0,
    color: Colors.white,
  );
  bool down = false;

  void changing(context) {
    if (down) {
      down = false;
      icon = Icon(
        Icons.add,
        size: 32.0,
        color: Components.setTextColor(isDarkMode),
      );

      emit(ChangeIcon1State());
      images = [];
      requestController.clear();
      Navigator.pop(context);
    } else {
      down = true;
      icon = Icon(
        Icons.check,
        size: 32.0,
        color: Components.setTextColor(isDarkMode),
      );
      emit(ChangeIcon2State());
    }
  }

  Icon icon2 = Icon(
    Icons.add,
    size: 32.0,
    color: Colors.white,
  );
  bool down2 = false;

  void changing2(context) {
    if (down2) {
      down2 = false;
      icon2 = Icon(
        Icons.add,
        size: 32.0,
        color: Components.setTextColor(isDarkMode),
      );

      emit(ChangeIcon21State());
      Navigator.pop(context);
    } else {
      down2 = true;
      icon2 = Icon(
        Icons.check,
        size: 32.0,
        color: Components.setTextColor(isDarkMode),
      );
      emit(ChangeIcon22State());
    }
  }

/////////Change send icon
  bool isTyping = false;
  void ChangeSendIcon(String value) {
    isTyping = value.trim().isNotEmpty;

    emit(ChangeSendIconstate());
  }

/////////////////change img to null when sending message
  void swap() {
    img = null;
    emit(SwapState());
  }

  //////////////////////formate date
  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return DateFormat('yyyy-MM-dd/hh:mm', 'en').format(dateTime);
  }

//////
  Map<String, List<String>> chapters = {};
  void getChapters() {
    chapters = {};
    emit(PlatformgetChaptersLoadingState());
    UserModel um = Constants.userBox.get('user');
    CollectionReference cr = FirebaseFirestore.instance
        .collection('data')
        .doc('questions_bank')
        .collection(um.grade!);

    cr.get().then((value) async {
      // Iterate over each chapter document
      for (int i = 0; i < value.docs.length; i++) {
        String chapterId = value.docs[i].id;
        // Initialize the list for the current chapter if not already initialized
        chapters.putIfAbsent(chapterId, () => []);

        // Fetch content sub-collection for the current chapter
        QuerySnapshot contentSnapshot =
            await cr.doc(chapterId).collection('content').get();

        // Iterate over each content document and add its ID to the chapter list
        for (int j = 0; j < contentSnapshot.docs.length; j++) {
          String contentId = contentSnapshot.docs[j].id;

          chapters[chapterId]!.add(contentId);
        }
      }
      emit(PlatformgetChaptersSuccessState());
    }).catchError((onError) {
      emit(PlatformgetChaptersFailState());
      debugPrint(onError.toString());
    });
  }

  void getChaptersCheck() {}
  //////////////////Add attendance
  ///Old
  Future<void> createLectureAttendance(
      {required String LectureName, required List<String>? groups}) async {
    // emit(AddRequestLoadingState());
    String id = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(Lecturesgrade)
        .collection("Lecture")
        .doc()
        .id;

    try {
      await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(Lecturesgrade)
          .collection("Lecture")
          .doc(id)
          .set({'Name': LectureName, 'id': id, 'groups': groups});
      // emit(AddRequestSuccessState());
    } catch (error) {
      // emit(AddRequestErrorState());
      print('error');
      debugPrint(error.toString());
    }
  }

  //////////////////  New
  void createGroup(
      {required String groupName, required List<String>? lectures}) async {
    String id = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(Lecturesgrade)
        .collection("Groups")
        .doc()
        .id;

    await FirebaseFirestore.instance
        .collection('Attendance')
        .doc(Lecturesgrade)
        .collection("Groups")
        .doc(id)
        .set({'id': id, 'Name': groupName, 'lectures': lectures}).then((value) {
      emit(states());
    }).catchError((onError) {
      print(onError);
    });
    // emit(AddRequestSuccessState());
  }

  void updateRequest2(String id, String newState) {
    UserModel um = Constants.userBox.get('user');
    FirebaseFirestore.instance
        .collection('Requests')
        .doc(um.grade)
        .collection('data')
        .doc(id)
        .update({"state": newState}).then((value) {
      print('wahba');
      // emit(PlatformUpdateRequestStatueState());
      getRequests();
    }).catchError((error) {
      print(error.toString());
      // emit(states());
    });
  }

  String requestsGroup = "first";
  int requestsChoice = 0;
  List<RequsetsModel> choosenRequestsGrade = [];
  List<RequsetsModel> grade1 = [];
  List<RequsetsModel> grade2 = [];
  List<RequsetsModel> requests2 = [];

  void changeChoice2(value) {
    switch (value) {
      case 0:
        requestsChoice = 0;
        requestsGroup = "first";
        getRequests2();

        break;
      case 1:
        requestsChoice = 1;
        requestsGroup = "second";
        getRequests2();

        break;
      case 2:
        requestsChoice = 2;
        requestsGroup = "third";
        getRequests2();

        break;
    }
    emit(RequestChoicesStates());
  }

  int LecturesChoice = 0;
  String Lecturesgrade = "first";

  void changeChoice(value) {
    switch (value) {
      case 0:
        LecturesChoice = 0;
        Lecturesgrade = "first";
        ChoosenList = groups1;
        break;
      case 1:
        LecturesChoice = 1;
        Lecturesgrade = "second";
        ChoosenList = groups2;

        break;
      case 2:
        LecturesChoice = 2;
        Lecturesgrade = "third";
        ChoosenList = groups3;

        break;
    }
    emit(LecturesChoicesStates());
  }

  // List<LectureModel> Lectures = [];
  // List<LectureModel> Lectures2 = [];
  // List<LectureModel> Lectures3 = [];
  List<GroupAttendanceModel2> ChoosenList = [];

  // Future<void> getFirstLectureAttendance() {
  //   Lectures = [];
  //   FirebaseFirestore.instance
  //       .collection('Attendance')
  //       .doc("First")
  //       .collection("Lecture")
  //       .get()
  //       .then((value) {
  //     for (int i = 0; i < value.docs.length; i++) {
  //       Lectures.add(LectureModel.fromJson(value.docs[i].data()));
  //     }

  //     // print(requests1);
  //     print('Done');
  //     emit(states());
  //   }).catchError((error) {
  //     print(error);
  //   });
  //   return Future(() => null);
  // }

////////////////// New
  ///
  List<GroupAttendanceModel2> groups1 = [];
  List<GroupAttendanceModel2> groups2 = [];
  List<GroupAttendanceModel2> groups3 = [];

  Future<void> getFirstGroupsAttendance2() {
    groups1 = [];
    FirebaseFirestore.instance
        .collection('Attendance')
        .doc("first")
        .collection("Groups")
        .get()
        .then((value) {
      for (int i = 0; i < value.docs.length; i++) {
        groups1.add(GroupAttendanceModel2.fromJson(value.docs[i].data()));
      }
      print('Done');
      emit(states());
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }

  Future<void> getThirdGroupsAttendance2() {
    groups3 = [];
    FirebaseFirestore.instance
        .collection('Attendance')
        .doc("third")
        .collection("Groups")
        .get()
        .then((value) {
      for (int i = 0; i < value.docs.length; i++) {
        groups3.add(GroupAttendanceModel2.fromJson(value.docs[i].data()));
      }
      print('Done');
      emit(states());
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }

  Future<void> getSecondGroupsAttendance2() {
    groups2 = [];
    FirebaseFirestore.instance
        .collection('Attendance')
        .doc("second")
        .collection("Groups")
        .get()
        .then((value) {
      for (int i = 0; i < value.docs.length; i++) {
        groups2.add(GroupAttendanceModel2.fromJson(value.docs[i].data()));
      }
      print('Done');
      emit(states());
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }
/////////////////

  // Future<void> getSecondLectureAttendance() {
  //   Lectures2 = [];
  //   FirebaseFirestore.instance
  //       .collection('Attendance')
  //       .doc("Second")
  //       .collection("Lecture")
  //       .get()
  //       .then((value) {
  //     for (int i = 0; i < value.docs.length; i++) {
  //       Lectures2.add(LectureModel.fromJson(value.docs[i].data()));
  //     }

  //     // print(requests1);
  //     print('Done');
  //   }).catchError((error) {
  //     print(error);
  //   });
  //   return Future(() => null);
  // }

  // Future<void> getThirdLectureAttendance() {
  //   Lectures3 = [];
  //   FirebaseFirestore.instance
  //       .collection('Attendance')
  //       .doc("Third")
  //       .collection("Lecture")
  //       .get()
  //       .then((value) {
  //     for (int i = 0; i < value.docs.length; i++) {
  //       Lectures3.add(LectureModel.fromJson(value.docs[i].data()));
  //     }

  //     // print(requests1);
  //     print('Done');
  //   }).catchError((error) {
  //     print(error);
  //   });
  //   return Future(() => null);
  // }

  // List<GroupAttendanceModel> Attendance = [];

  // Future<void> getAttendance(idd, String groupid) async {
  //   Attendance = [];
  //   // print(group);
  //   await FirebaseFirestore.instance
  //       .collection('Attendance')
  //       .doc(Lecturesgrade)
  //       .collection("Lecture")
  //       .doc(idd)
  //       .collection("Groups")
  //       .doc(groupid)
  //       .collection("Codes")
  //       .get()
  //       .then((value) {
  //     // print(value.toString());
  //     for (int i = 0; i < value.docs.length; i++) {
  //       Attendance.add(GroupAttendanceModel.fromJson(value.docs[i].data()));
  //     }
  //     print(Attendance);
  //   }).catchError((onError) {});

  //   emit(GetAttendanceGroupsState());
  //   return Future(() => null);
  // }

// List<StdAttendanceModel>StdAttendance =[];
//     Future<void> getStdAttendance( String group,String StdId,String LectureName)  {
//     print(group);
//      FirebaseFirestore.instance
//         .collection('Attendance')
//         .doc(Lecturesgrade)
//         .collection("Lecture")
//         .doc()
//         .collection("Groups")
//         .doc(group)
//         .collection("Codes").where('Code', isEqualTo: StdId)
//         .get()
//         .then((value) {
//       // print(value.toString());
//         StdAttendance.add(StdAttendanceModel(Absent:value.size>0?false:true ,Group:group ,Lecture:  ));
//       print(Attendance);
//     }).catchError((onError) {});

//     emit(GetAttendanceGroupsState());
//     return Future(() => null);
//   }
  List<StudentsModel> Stds = [];
  Future<void> getAllStds(String groupid) {
    Stds = [];
    print(Lecturesgrade);
    FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(Lecturesgrade)
        .where('groupId', isEqualTo: groupid)
        .get()
        .then((value) {
      // print(value.toString());

      for (int i = 0; i < value.docs.length; i++) {
        // print(value.docs[i].data());
        Stds.add(StudentsModel.fromJson(value.docs[i].data()));
        print(i);
      }
      emit(GetAttendanceGroupsState());
      print(Stds[0].Name);
      print(Stds.length);
    }).catchError((onError) {});

    return Future(() => null);
  }

  // Future<void> getAllStds(String groupName) async {
  //   Stds = [];
  //   try {
  //     var value = await FirebaseFirestore.instance
  //         .collection('Students')
  //         .where('Group', isEqualTo: groupName)
  //         .get();
  //     for (var doc in value.docs) {
  //       Stds.add(StudentsModel.fromJson(doc.data()));
  //       print(doc.id);
  //     }
  //     emit(GetAttendanceGroupsState());
  //     print(Stds);
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }
  List<dynamic> groupLectures = [];
  Future<void> addLecture(
      {required String LectureName, required String groupid}) async {
    try {
      await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(Lecturesgrade)
          .collection("Groups")
          .doc(groupid)
          .update({
        'lectures': FieldValue.arrayUnion([LectureName])
      });
      updateAttendanceForGroup(groupid, LectureName, false);
      refreshGroupLectures(groupid, groupLectures);
      switch (LecturesChoice) {
        case 0:
          getFirstGroupsAttendance2();
          changeChoice(0);
          break;
        case 1:
          getSecondGroupsAttendance2();
          changeChoice(1);

          break;
        case 2:
          getThirdGroupsAttendance2();
          changeChoice(2);

          break;
      }
      print('Value added to array successfully');
    } catch (e) {
      print('Error adding value to array: $e');
    }
  }

  /* Future<void> addLectureToStds(
      {required String LectureName, required String groupName}) async {
    try {
      await FirebaseFirestore.instance
          .collection("Stuedents")
          .where('Group', isEqualTo: groupName)
          .update({
    'Attendance.$LectureName': false,
      });
      print('Value added to array successfully');
    } catch (e) {
      print('Error adding value to array: $e');
    }
  }
  */

  Future<void> updateAttendanceForGroup(
      String groupid, String lectureName, bool attendanceStatus) async {
    // Reference to the Firestore collection

    CollectionReference studentsCollection = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(Lecturesgrade);

    try {
      // Query for all students in the specified group
      QuerySnapshot querySnapshot =
          await studentsCollection.where('groupId', isEqualTo: groupid).get();

      // Loop through the query results and update the Attendance map field for each document
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        // Get the document reference
        DocumentReference docRef = studentsCollection.doc(doc.id);

        // Update the Attendance map field
        await docRef.update({
          'attendance.$lectureName': attendanceStatus,
        });
      }
      emit(states());
      print(
          "Attendance updated successfully for all students in group $groupid!");
    } catch (error) {
      print("Error updating attendance: $error");
    }
  }

  Future<void> updateAttendanceForStd(String StdId, String lectureName,
      bool attendanceStatus, List<dynamic> Lecturess, String groupid) async {
    // Reference to the Firestore collection

    CollectionReference studentsCollection = FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(Lecturesgrade);

    try {
      // Query for all students in the specified group
      QuerySnapshot querySnapshot =
          await studentsCollection.where('code', isEqualTo: StdId).get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        DocumentReference docRef = studentsCollection.doc(doc.id);

        await docRef.update({
          'attendance.$lectureName': attendanceStatus,
        });
        refreshGroupLectures(groupid, groupLectures);
        getAllStds(groupid);
      }
      emit(states());
    } catch (error) {
      print("Error updating attendance: $error");
    }
  }

  Future<void> refreshGroupLectures(String groupid, List<dynamic> Lecturess) {
    FirebaseFirestore.instance
        .collection('Attendance')
        .doc(Lecturesgrade)
        .collection("Groups")
        .doc(groupid)
        .get()
        .then((value) {
      print("gg");
      groupLectures = value.data()!['lectures'];
      // TODO
      getFirstGroupsAttendance2();
      print('Done');
      emit(states());
    }).catchError((error) {
      print(error);
    });
    return Future(() => null);
  }

  bool isExamTaken({required String lectureId, required quizCode}) {
    UserModel sm = Constants.userBox.get('user');
    return sm.stdQuizes?['$lectureId,$quizCode'] != null;
  }

  Future<String?> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "karim-platform",
      "private_key_id": "d157dfcb30ddfa4c40dd2e88f3889a2fc0f2600f",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC5t0JcSHrC1kqJ\nSp0FlhRMqEVMTtsDR7n9fGEHnHNXyBVAHpP+8OkeE4vfN9J6YnLcemCFqM1tPfme\nCwNEwOEoQT1TbaLPvGoYyB1hX7YoyF+6SaWFdTm/ln+XS3BGclKEDEEJG/PlurmW\nepK4QXmYHPuJITlw/DWuJF2yeb6TTo7M6qVFQsamwTYF/EQsLbfoOVs4Lc8F1D3n\nv4+ybkMMaJxfNtNJjZ1uzKxMxvSFhkcq4XyRHR95RQ8BaXthBRIDM7LhKfen6xJu\nnzdwcd2pqJ35H06TkKYIrXFRUEt7Vqgq85AB0foL4mFTLoMuhW866+ruM11fkQLS\nzjoT7k6jAgMBAAECggEAFWXPCJD1TAOivOTS6LTdC+QLb/pZ86vM+y7cgyL8iy2r\nfSLIzIP3aBa6c/KblqxHLa4P9vZ3DNIqM5JzQvWyO5Agv78PFj5QPyC3eeOsOlCz\n7uPTZWgXSkLN2qG/gu5jIYHD8Ie+90YnYfYnd4FbwDH+rVMdqi31BWZ9QTYTxicB\nwCRh1xKVhYiHVwJmkSnylwNWL8B9vUB5rYB5oD3CCxPa/nSOOYsZCbh0w3Rpp37a\nKFneA2aMQRzs0BiLZ4qS3ChWdA4d9Cn1fv5sDRqeCmwKMtonDgz3o/lwZCKS50wU\nnzCWkDd78Sn9dqKQky/GR8oaqDRrpiTgZ26J+WBn+QKBgQDaOIl/x+R1fa9m4cy4\nn6pqjFrfCyF13YslAQ1pWg/q2t5kvgAyCBEiJYsXVe9nqbxmUX62i1qll/bjJ8uD\npA2nKdJc0ApzIKg8PNllXaWo7XRHMT3+YB5ELnkWkO3Ql5L7KoIJfctz0v+/KIVP\nJLsCTAGaVTnR8SI3N0NFzoHvXwKBgQDZ3h0R+u4UIaSlfY/x8ziOC/ZylBb6IvSd\nKB+ED+e+Lb8JEhdQh6dzW+t8fUtkcxRf4ERrDV5oIGRyrBt+KOnpFA8rRKuAhK/7\nN8a8BM6bslYEbz8Owv2QTRkvm5FDu/aIYKcITV9gzjIL42V1V+zA0tSrclKuGESa\nB//wYA7bPQKBgQCl6EoRjkYRVYcfbxiYXTvRWfhUjz/XPqJlddFegYyMf+6JJTM8\n1olALs765OjpJVEJcXgnDPfT4h9gQIcoBHgk2VUIH1tygCen9JNLz9D9B9tZrQR2\n+1jHeZWyJGnKJxMmRgEreipOWuL50LLZoxFTA7pMPfOBvBTJagiJcCG1fQKBgQDC\nh92jEVAFL6kIjx25JrfHtYy+79W4UP/jV1EUpPMCT2x01+9zWzy790ZDqMhpj4uQ\ns/nDMHOsO8gUz/HYawW4tM16j90matOLV1kexpgIU2sUmJRQRPENKJoldR12wl01\nlj9uXU+da18qWEdeSDzASz/TOcfzZP3UHvJ7GfoJ7QKBgQCjO1LQ3ue/9t/jH15h\nyvB87U5kaYDeZ3f+bWqSQmaQH7+eL+Nmia3pqOoLoYBnGkkyelTToKonrhylz9bW\nhnrv3FlOFpjJz0W/MSX9x3G/FoFWljR686+unXdujJjxitsKjuR51gRVNzxVh6kF\naBamN4168Yxrdr8dp6PuEbx/tg==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@karim-platform.iam.gserviceaccount.com",
      "client_id": "104686239035079253309",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40karim-platform.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    try {
      http.Client client = await auth.clientViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
              auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
              scopes,
              client);

      client.close();
      debugPrint(
          "Access Token: ${credentials.accessToken.data}"); // Print Access Token
      return credentials.accessToken.data;
    } catch (e) {
      debugPrint("Error getting access token: $e");
      return null;
    }
  }

  Map<String, dynamic> getBody({
    required String fcmToken,
    required String title,
    required String body,
    String? imageUrl, // Add imageUrl as an optional parameter
    String? type,
  }) {
    return {
      "message": {
        "token": fcmToken, // Target device token
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "notification": {
            "notification_priority": "PRIORITY_MAX",
            "sound": "default",
            "image": imageUrl, // Add image URL for Android
          },
        },
        "apns": {
          "payload": {
            "aps": {
              "content_available": true,
              "mutable_content": true, // Required for rich notifications on iOS
            },
          },
          "fcm_options": {
            "image": imageUrl, // Add image URL for iOS
          },
        },
        "data": {
          "image": imageUrl, // Pass image URL in the data payload
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };
  }

  Future<void> sendNotifications({
    required String fcmToken,
    required String title,
    required String body,
    // required String userId,
    String? imgUrl,
    String? type,
  }) async {
    try {
      var serverKeyAuthorization = await getAccessToken();

      // change your project id
      const String urlEndPoint =
          'https://fcm.googleapis.com/v1/projects/karim-platform/messages:send';

      Dio dio = Dio();
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.headers['Authorization'] = 'Bearer $serverKeyAuthorization';

      var response = await dio.post(
        urlEndPoint,
        data: getBody(
          //  userId: userId,
          fcmToken: fcmToken,
          title: title,
          body: body,
          imageUrl: imgUrl,
          type: type,
        ),
      );

      // Print response status code and body for debugging
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  List<PostModel> posts = [];
  DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  bool isLoadingMore = false;
  int postsCount = SharedPrefHelper.getData('postsCount') ?? 0;
  Future<void> getPosts({bool loadMore = false}) async {
    if (isLoadingMore) return;
    isLoadingMore = true;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true)
        .limit(15);

    if (loadMore && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    query.get().then((value) {
      if (value.docs.isNotEmpty) {
        lastDocument = value.docs.last;

        if (loadMore) {
          posts.addAll(value.docs.map((e) => PostModel.fromMap(e.data())));
        } else {
          posts = value.docs.map((e) => PostModel.fromMap(e.data())).toList();
        }

        emit(PlatformGetPostsSuccessState());
      }
      isLoadingMore = false;
    }, onError: (error) {
      isLoadingMore = false;
      debugPrint(error.toString());
      emit(PlatformGetPostsFailState(error.toString()));
    });
  }

  Future<void> getPostsCount() async {
    await FirebaseFirestore.instance.collection('posts').get().then((value) {
      postsCount = value.docs.length;
    });
  }

  Future<void> removeLike({
    required String postId,
    required String code,
  }) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await postRef.update({'likes.$code': FieldValue.delete()});
    emit(PlatformTogglePostLikeSuccessState());
  }

  Future<void> addLike({
    required String postId,
    required String code,
  }) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await postRef.update({'likes.$code': DateTime.now()});
    emit(PlatformTogglePostLikeSuccessState());
  }

  Future<void> addComment({
    required String postId,
    required CommentModel cm,
    required String code,
  }) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await postRef.update({
      'comments.$code': FieldValue.arrayUnion([
        cm.toMap(),
      ])
    });
    emit(PlatformTogglePostLikeSuccessState());
  }

  String commentVal = '';
  void changeCommentVal(String value) {
    commentVal = value;
    emit(PlatformChangeCommentValue());
  }

  Future<void> addPost() async {
    DocumentReference<Map<String, dynamic>> post =
        FirebaseFirestore.instance.collection('posts').doc();

    post.set(
      PostModel(
        id: post.id,
        comments: {},
        likes: {},
        text: 'تم الغاء حصة اليوم!',
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/koraiemonlineplatform.appspot.com/o/notifications%2F2%2F1742098642976.jpg?alt=media&token=08cf212e-ff21-44e7-bd41-743ce5b331e9',
        date: DateTime.now(),
      ).toMap(),
    );
  }

  Map<String, CommentStdData> commentstds = {};

  Future<void> getCommentUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;

    // استخدم 'where in' لو العدد ≤ 10 لتقليل عدد الاستعلامات
    if (userIds.length <= 10) {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(Components.getGrade(userIds.first[0]))
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      commentstds = {
        for (var doc in querySnapshot.docs)
          doc.id: CommentStdData(
            imgUrl: doc.data()['img'] ?? '',
            name:
                '${doc.data()['ar_fname'] ?? ''} ${doc.data()['ar_sname'] ?? ''} ${doc.data()['ar_thname'] ?? ''}',
          ),
      };
    } else {
      // لو العدد أكثر من 10، استعلم كل مستخدم على حدة
      var futures = userIds.map((code) async {
        var std = await FirebaseFirestore.instance
            .collection('data')
            .doc('students')
            .collection(Components.getGrade(code[0]))
            .doc(code)
            .get();

        var data = std.data();
        if (data != null) {
          return MapEntry(
            code,
            CommentStdData(
              imgUrl: data['img'] ?? '',
              name:
                  '${data['ar_fname'] ?? ''} ${data['ar_sname'] ?? ''} ${data['ar_thname'] ?? ''}',
            ),
          );
        }
        return null; // تجاهل المستخدمين غير الموجودين
      });

      commentstds = Map.fromEntries((await Future.wait(futures))
          .whereType<MapEntry<String, CommentStdData>>());
    }
  }

  List<LikeStdData> likesUsers = [];

  Future<void> getLikesUsers(Map<String, DateTime> likes) async {
    if (likes.isEmpty) return;

    List<String> userIds = likes.keys.toList();

    if (userIds.length <= 10) {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(Components.getGrade(userIds.first[0]))
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      likesUsers = querySnapshot.docs.map((doc) {
        var data = doc.data();
        return LikeStdData(
          imgUrl: data['img'] ?? '',
          name:
              '${data['ar_fname'] ?? ''} ${data['ar_sname'] ?? ''} ${data['ar_thname'] ?? ''}',
          date: likes[doc.id] ?? DateTime.now(), // استخدم تاريخ اللايك
        );
      }).toList();
    } else {
      var futures = userIds.map((code) async {
        var std = await FirebaseFirestore.instance
            .collection('data')
            .doc('students')
            .collection(Components.getGrade(code[0]))
            .doc(code)
            .get();

        var data = std.data();
        if (data != null) {
          return LikeStdData(
            imgUrl: data['img'] ?? '',
            name:
                '${data['ar_fname'] ?? ''} ${data['ar_sname'] ?? ''} ${data['ar_thname'] ?? ''}',
            date: likes[code] ?? DateTime.now(),
          );
        }
        return null;
      });

      likesUsers =
          (await Future.wait(futures)).whereType<LikeStdData>().toList();
    }

    // ترتيب البيانات بناءً على تاريخ اللايك من الأحدث إلى الأقدم
    likesUsers.sort((a, b) => b.date!.compareTo(a.date!));
  }

  List<PurchasesWidgetData> purchasedVideosList = [];
  Future<void> getPurchasedVideosList() async {
    UserModel um = Constants.userBox.get('user');

    if (um.purchasedVideos?.isEmpty ?? true) {
      purchasedVideosList = [];
      return;
    }

    // 1. Gather all active local purchases across chapters
    List<_LocalLectureSortWrapper> activePurchases = [];

    um.purchasedVideos?.forEach((chapId, chapterModel) {
      final lecturesMap = chapterModel.lectures;
      if (lecturesMap == null) return;

      lecturesMap.forEach((lecId, lectureModel) {
        int totalStdWatches = 0;
        int totalAvaWatches = 0;

        // Calculate watch totals safely from the internal nested map
        final videosMap = lectureModel.videos;
        if (videosMap != null) {
          for (var videoModel in videosMap.values) {
            totalStdWatches += videoModel.stdWatches ?? 0;
            totalAvaWatches += videoModel.avaWatches ?? 4;
          }
        }

        // Check if the student still has remaining watch counts left
        if (totalStdWatches < totalAvaWatches) {
          activePurchases.add(
            _LocalLectureSortWrapper(
                chapId: chapId,
                lecId: lecId,
                stdWatches: totalStdWatches,
                avaWatches: totalAvaWatches,
                purchaseDate: lectureModel.purchaseDateTime ?? DateTime.now()),
          );
        }
      });
    });

    // 2. Sort all eligible purchases by date (Newest First)
    activePurchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    // 3. Take ONLY the latest 2 items to minimize Firestore reads
    final latestTwoPurchases = activePurchases.take(2).toList();
    if (latestTwoPurchases.isEmpty) {
      purchasedVideosList = [];
      return;
    }

    // 4. Fire parallel Firestore fetches for just those 2 specific lectures
    List<Future<void>> fetchTasks = [];
    List<PurchasesWidgetData?> orderedWidgets =
        List.filled(latestTwoPurchases.length, null);

    for (int i = 0; i < latestTwoPurchases.length; i++) {
      final purchase = latestTwoPurchases[i];

      fetchTasks.add(FirebaseFirestore.instance
          .collection('data')
          .doc('videos')
          .collection(um.grade!)
          .doc(purchase.chapId)
          .collection('lectures')
          .doc(purchase.lecId)
          .get()
          .then((lectureDoc) {
        if (lectureDoc.exists && lectureDoc.data() != null) {
          final data = lectureDoc.data()!;

          // Map incoming server properties to your UI widget class
          orderedWidgets[i] = PurchasesWidgetData(
            lectureImg: data['thumbnail'] ?? '',
            lectureTitle: data['title'] ?? 'No Title Available',
            lectureDep: data['dep'] ?? '',
            chapterId: purchase.chapId,
            lectureId: purchase.lecId,
            price: data['price'] ?? 0,
            stdWatches: purchase.stdWatches ?? 0,
            avaWatches: purchase.avaWatches ?? 0,
          );
        }
      }).catchError((error) {
        debugPrint(
            'Error fetching server metadata for lecture ${purchase.lecId}: $error');
      }));
    }

    try {
      // Resolve both network tasks at the same time
      await Future.wait(fetchTasks);

      // Filter out nulls in case a document was deleted or failed on the server
      purchasedVideosList =
          orderedWidgets.whereType<PurchasesWidgetData>().toList();

      emit(PlatformGetMyLecturesDataSuccessState());
    } catch (error) {
      debugPrint('Error building purchased widgets collection: $error');
    }
  }

/*
  Future<void> getPurchasedVideosList() async {
    UserModel um = Constants.userBox.get('user');

    final List<PurchasesWidgetData> result = [];

    um.purchasedVideos?.forEach((chapId, lectures) {
      lectures.forEach((lecId, videos) {
        VideoDetailsModel? recent;

        for (var video in recentVideosList) {
          if (video.lecId == lecId) {
            recent = video;
            break;
          }
        }

        if (recent != null) {
          int totalStdWatches = 0;
          int totalAvaWatches = 0;

          for (var video in videos) {
            totalStdWatches += video.stdWatches ?? 0;
            totalAvaWatches += video.avaWatches ?? 4;
          }

          if (totalStdWatches != totalAvaWatches) {
            result.add(
              PurchasesWidgetData(
                lectureImg: recent.thumbnail,
                lectureTitle: recent.title,
                lectureDep: recent.dep,
                chapterId: recent.chapId,
                lectureId: recent.lecId,
                price: recent.price,
                stdWatches: totalStdWatches,
                avaWatches: totalAvaWatches,
              ),
            );
          }
        }
      });
    });

    purchasedVideosList = result.take(2).toList();
  }
*/
  String phoneNum = '';
  String oldCode = '';
  void sendOtpMessage({
    required String mobile,
    required String code,
  }) async {
    bool isConnected = await Components.checkConnection();
    if (isConnected) {
      // بيانات الرسالة
      final url = Uri.parse('https://noti-fire.com/api/send/message');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'device_id': await getDeviceId(),
        "to": '+2$mobile',
        "message": Constants.otpMsg(code: code),
      });

      try {
        // إرسال الطلب
        final response = await http.post(url, headers: headers, body: body);

        // التحقق من الاستجابة
        if (response.statusCode == 200) {
          debugPrint('Message sent successfully: ${response.body}');
          phoneNum = mobile;
          oldCode = code;
          emit(PlatformSendOtpMsgSuccessState(
            phoneNum: mobile,
            code: code,
          ));
        } else {
          debugPrint('Failed to send message. Status: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
          emit(PlatformSendOtpMsgFailState(response.body));
        }
      } catch (e) {
        debugPrint('Error occurred: ${e.toString()}');
        debugPrint(e.toString());
        emit(PlatformSendOtpMsgFailState(e.toString()));
      }
    } else {
      emit(
        PlatformSendOtpMsgFailState(
          isAr ? 'لا يوجد اتصال بالانترنت' : 'No Internet Connection',
        ),
      );
    }
  }

  void sendOtp({required String mobile}) async {
    emit(PlatformSendOtpMsgLoadingState());
    bool isConnected = await Components.checkConnection();
    if (isConnected) {
      /// TODO: Check if the phone number already exists
      bool numExist = await checkPhoneExistance(phoneNum: mobile);
      if (!numExist) {
        String code = (Random().nextInt(900000) + 100000).toString();
        FirebaseFirestore.instance
            .collection('otp')
            .doc(code)
            .set(
              OtpModel(
                code: code,
                date: DateTime.now(),
                phoneNum: mobile,
              ).toJson(),
            )
            .then((onValue) {
          sendOtpMessage(mobile: mobile, code: code);
        }).catchError((onError) {
          debugPrint(onError.toString());
          emit(PlatformSendOtpMsgFailState(onError.toString()));
        });
      } else {
        emit(
          PlatformSendOtpMsgFailState(
            isAr ? "هذا الرقم مسجل من قبل" : "Phone Number Already Exists",
          ),
        );
      }
    } else {
      emit(
        PlatformSendOtpMsgFailState(
          isAr ? 'لا يوجد اتصال بالانترنت' : 'No Internet Connection',
        ),
      );
    }
  }

  Future<bool> checkPhoneExistance({required String phoneNum}) async {
    UserModel sm = Constants.userBox.get('user');
    QuerySnapshot<Map<String, dynamic>> get = await FirebaseFirestore.instance
        .collection('data')
        .doc('students')
        .collection(sm.grade!)
        .where('phoneNum', isEqualTo: phoneNum)
        .get();

    return get.docs.isNotEmpty;
  }

  void resendOtpMessage({
    required String mobile,
    required String code,
  }) async {
    bool isConnected = await Components.checkConnection();
    if (isConnected) {
      // بيانات الرسالة
      final url = Uri.parse('https://noti-fire.com/api/send/message');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'device_id': await getDeviceId(),
        "to": '+2$mobile',
        "message": Constants.otpMsg(code: code),
      });

      try {
        // إرسال الطلب
        final response = await http.post(url, headers: headers, body: body);

        // التحقق من الاستجابة
        if (response.statusCode == 200) {
          debugPrint('Message sent successfully: ${response.body}');
          phoneNum = mobile;
          oldCode = code;
          emit(PlatformReSendOtpMsgSuccessState(code));
        } else {
          debugPrint('Failed to send message. Status: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
          emit(PlatformReSendOtpMsgFailState(response.body));
        }
      } catch (e) {
        debugPrint('Error occurred: ${e.toString()}');
        debugPrint(e.toString());
        emit(PlatformReSendOtpMsgFailState(e.toString()));
      }
    } else {
      emit(
        PlatformReSendOtpMsgFailState(
          isAr ? 'لا يوجد اتصال بالانترنت' : 'No Internet Connection',
        ),
      );
    }
  }

  void resendOtp({required String mobile, required String oldCode}) async {
    emit(PlatformReSendOtpMsgLoadingState());
    bool isConnected = await Components.checkConnection();
    if (isConnected) {
      await FirebaseFirestore.instance.collection('otp').doc(oldCode).delete();
      String code = (Random().nextInt(900000) + 100000).toString();
      FirebaseFirestore.instance
          .collection('otp')
          .doc(code)
          .set(
            OtpModel(
              code: code,
              date: DateTime.now(),
              phoneNum: mobile,
            ).toJson(),
          )
          .then((onValue) {
        resendOtpMessage(mobile: mobile, code: code);
      }).catchError((onError) {
        debugPrint(onError.toString());
        emit(PlatformReSendOtpMsgFailState(onError.toString()));
      });
    } else {
      emit(
        PlatformReSendOtpMsgFailState(
          isAr ? 'لا يوجد اتصال بالانترنت' : 'No Internet Connection',
        ),
      );
    }
  }

  void checkOtpCode({required String code, required String mobile}) async {
    emit(PlatformCheckOtpCodeLoadingState());

    FirebaseFirestore.instance
        .collection('otp')
        .doc(code)
        .get()
        .then((onValue) async {
      if (onValue.exists) {
        // تحقق من تطابق رقم الهاتف
        if (onValue.data()!['phoneNum'] == mobile) {
          // تحقق من صلاحية الرمز
          DateTime expirationDate = (onValue.data()!['date'] as Timestamp)
              .toDate()
              .add(const Duration(minutes: 5));
          if (DateTime.now().isBefore(expirationDate)) {
            // إذا كان الرمز صالحًا
            await FirebaseFirestore.instance
                .collection('otp')
                .doc(code)
                .delete();

            emit(PlatformCheckOtpCodeSuccessState());
          } else {
            await FirebaseFirestore.instance
                .collection('otp')
                .doc(code)
                .delete();

            // إذا كانت صلاحية الرمز قد انتهت
            emit(PlatformCheckOtpCodeFailState(isAr
                ? 'رمز التحقق منتهي الصلاحية'
                : 'Verification code expired'));
          }
        } else {
          // إذا كان رقم الهاتف غير مطابق
          emit(PlatformCheckOtpCodeFailState(
              isAr ? 'رقم الهاتف غير مطابق' : 'Phone number does not match'));
        }
      } else {
        // إذا لم يتم العثور على الرمز في قاعدة البيانات
        emit(PlatformCheckOtpCodeFailState(
            isAr ? 'كود غير صحيح' : 'Invalid Code'));
      }
    }).catchError((onError) {
      debugPrint(onError.toString());
      emit(PlatformCheckOtpCodeFailState(onError.toString()));
    });
  }

  Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    return null;
  }

  File? stdImg;
  void setStdImage(File image) {
    stdImg = image;
    emit(PlatformImagePickedState()); // تحديث الحالة
  }

  Future<void> generateUniqueStdCode({required UserModel sm}) async {
    try {
      // Retrieve the current year
      String year = await getCurrentYear();

      final studentsCollection = FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(Components.getGrade(sm.grade!));

      // Generate a unique student code
      String stdCode = '${Components.getGradeNum(sm.grade!)}$year';
      String uniqueCode = await generateUniqueCode(studentsCollection, stdCode);

      // Generate a random password
      String password = (Random().nextInt(900000000) + 100000000).toString();

      // Save student model with new code and password
      sm.code = uniqueCode;
      sm.password = password;
      await sm.save();

      debugPrint('Generated StdCode: $uniqueCode');
    } catch (error) {
      debugPrint('Error generating unique std code: $error');
      emit(PlatformUploadStdImgFailState(error.toString()));
    }
  }

  Future<String> getCurrentYear() async {
    try {
      final yearDoc =
          await FirebaseFirestore.instance.collection('data').doc('year').get();

      return yearDoc.data()?['year'] ?? '25'; // Default year fallback
    } catch (error) {
      debugPrint('Error fetching year: $error');
      throw Exception('Failed to fetch year');
    }
  }

  Future<String> generateUniqueCode(
      CollectionReference studentsCollection, String baseCode) async {
    while (true) {
      // Generate a random index to append
      String stdIndex = (Random().nextInt(900000) + 100000).toString();
      String stdCode = '$baseCode$stdIndex';

      // Check if the code already exists
      var docSnapshot = await studentsCollection.doc(stdCode).get();
      if (!docSnapshot.exists) {
        return stdCode; // Return the unique code
      }
    }
  }

  Future<void> uploadStdImg() async {
    emit(PlatformUploadStdImgLoadingState());

    try {
      UserModel sm = Constants.userBox.get('user');

      if (sm.code?.isEmpty ?? true) {
        // Generate student code before uploading the image
        await generateUniqueStdCode(sm: sm);
      }
      if (stdImg != null) {
        // رفع الصورة إذا كانت موجودة
        Reference storageRef = FirebaseStorage.instance.ref().child(
            'user_images/_${sm.code}_${Uri.file(stdImg!.path).pathSegments.last}');

        TaskSnapshot snapshot = await storageRef.putFile(stdImg!);
        sm.img = await snapshot.ref.getDownloadURL();
      } else {
        // تعيين الصورة الافتراضية
        sm.img = Constants.img;
      }

      // حفظ البيانات المحلية
      await sm.save();

      // تسجيل الطالب
      await studentSignup(sm: sm);
      isShowDelAccount();
      emit(PlatformUploadStdImgSuccessState());
    } catch (error) {
      // التعامل مع الأخطاء
      debugPrint("Error uploading student image: $error");
      emit(PlatformUploadStdImgFailState(error.toString()));
    }
  }

  Future<void> studentSignup({required UserModel sm}) async {
    try {
      /*
      // Create a user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: '${sm.code}@gmail.com',
        password: sm.password!,
      );

      debugPrint('Firebase Auth User Created: ${userCredential.user?.uid}');
*/
      // Save the student data in Firestore
      await createStudent(sm: sm);
    } catch (error) {
      debugPrint('Error during student signup: $error');
      emit(PlatformUploadStdImgFailState(error.toString()));
    }
  }

  Future<void> createStudent({required UserModel sm}) async {
    try {
      String deviceId = await _getDeviceId();
      String deviceType = _getDeviceType();

      Map<String, dynamic> studentData = sm.toMap();
      studentData['devices'] = [
        {
          'type': deviceType,
          'id': deviceId,
        }
      ];

      // خزّن الـ pushToken عند الإنشاء (يتعامل مع APNs على iOS؛ قد يكون null
      // على iOS في أول تشغيل وسيُحدَّث لاحقًا عبر setLocalData/onTokenRefresh).
      if (!Platform.isWindows) {
        final String? token = await NotificationService.getToken();
        if (token != null && token.isNotEmpty) {
          studentData['pushToken'] = token;
        }
      }

      await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(sm.grade!)
          .doc(sm.code)
          .set(studentData);

      emit(PlatformUploadStdImgSuccessState());
    } catch (error) {
      debugPrint('Error during student signup: $error');
      emit(PlatformUploadStdImgFailState(error.toString()));
    }
  }

  List<GroupModel> groups = [];

  Future<void> getGroups({required String grade}) async {
    groups = [];
    emit(AdminGetGroupsLoadingState());

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(grade)
          .collection('Groups')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.isEmpty) continue;

        final grp = GroupModel.fromJson(data);

        final groupName = grp.name.trim().toLowerCase();

        if (groupName.startsWith('test') || groupName.startsWith('online')) {
          continue;
        }

        groups.add(grp);
      }

      emit(AdminGetGroupsSuccesState());
    } catch (e) {
      debugPrint('❌ getGroups error: $e');
      emit(AdminGetGroupsFailState(e.toString()));
    }
  }

  Future<String> getDeviceId() async {
    return await FirebaseFirestore.instance
        .collection('whatsapp')
        .doc('otp')
        .get()
        .then((value) => value.data()!['deviceId']);
  }

  bool isShowRegister = false;
  bool isShowGuest = false;

  Future<void> getIsShowRegister() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('data')
          .doc('isShowRegister')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        isShowRegister = data['isShowRegister'] ?? false;
        isShowGuest = data['isShowGuest'] ?? false;
      }

      emit(PlatfomrRefreshState());
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  String cashPhoneNum = '';

  bool isWalletShowOnlinePayment = false;
  bool isExamShowOnlinePayment = false;
  bool isLectureShowOnlinePayment = false;

  void getIsShowOnlinePayment() {
    FirebaseFirestore.instance
        .collection('data')
        .doc('isShowOnlinePayment')
        .get()
        .then((value) {
      isWalletShowOnlinePayment =
          value.data()!['isWalletShowOnlinePayment'] ?? false;
      isExamShowOnlinePayment =
          value.data()!['isExamShowOnlinePayment'] ?? false;
      isLectureShowOnlinePayment =
          value.data()!['isLectureShowOnlinePayment'] ?? false;
      emit(PlatfomrRefreshState());
    }).catchError((error) {
      debugPrint("Error fetching isShowOnlinePayment: $error");
      isWalletShowOnlinePayment = false;
      isExamShowOnlinePayment = false;
      isLectureShowOnlinePayment = false;
    });
  }

  void getCashPhoneNum() {
    FirebaseFirestore.instance
        .collection('phoneNums')
        .doc('cash')
        .get()
        .then((value) {
      cashPhoneNum = value.data()!['phone'] ?? '';
      emit(PlatfomrRefreshState());
    }).catchError((error) {
      debugPrint("Error fetching cash phone number: $error");
      cashPhoneNum = '';
    });
  }

  // ===========================================================================
  // Fawaterk online payment
  // ===========================================================================

  /// Re-reads the current balance from Firestore into the local user box.
  /// Call after a successful online wallet recharge (the backend credits the
  /// balance on the gateway callback; this pulls the fresh value).
  Future<void> refreshBalance() async {
    try {
      final UserModel um = Constants.userBox.get('user');
      final doc = await FirebaseFirestore.instance
          .collection('data')
          .doc('students')
          .collection(um.grade!)
          .doc(um.code!)
          .get();
      final bal = doc.data()?['balance'];
      if (bal is num) {
        um.balance = bal.toInt();
        await um.save();
      }
      emit(PlatfomrRefreshState());
    } catch (e) {
      debugPrint('refreshBalance error: $e');
    }
  }

  /// Fetches the list of available payment methods from Fawaterk.
  /// Returns `null` on any failure so the UI can show an error.
  Future<List<PaymentData>?> fetchPaymentMethods() async {
    const apiUrl =
        'https://kareempaymentbackend-production.up.railway.app/api/payments/methods';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final responseData = json.decode(response.body);
      final paymentMethods = PaymentModel.fromJson(responseData);
      if (paymentMethods.status != 'success') return null;
      return paymentMethods.paymentData ?? [];
    } catch (error) {
      debugPrint('fetchPaymentMethods error: $error');
      return null;
    }
  }

  /// Initialises a Fawaterk invoice for the chosen [paymentId].
  ///
  /// Returns a [PaymentInitResult] holding either a redirect url (Card/Visa) or
  /// a Fawry reference code, or `null` if the request failed.
  Future<PaymentInitResult?> sendPaymentRequest({
    required int paymentId,
    required bool redirectOption,
    required num amount,
    required String itemName,
    String? lecId,
    String? chapId,
    String? quizId,
  }) async {
    debugPrint('$paymentId $amount $itemName');
    const apiUrl =
        'https://kareempaymentbackend-production.up.railway.app/api/payments/send';
    UserModel um = Constants.userBox.get('user');

    final requestData = {
      'payment_method_id': paymentId,
      'lectureId': lecId,
      'chapterId': chapId,
      'quizId': quizId,
      'userId': um.code,
      'title': itemName,
      'price': '$amount',
      'grade': um.grade,
      'customer': {
        'first_name': um.ar_fname,
        'last_name': '${um.ar_sname} ${um.ar_thname}',
        'phone': um.phoneNum
      },
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      final responseData = json.decode(response.body);
      debugPrint(json.encode(responseData));

      final result = PaymentInitResult.fromJson(responseData);
      debugPrint('resultttt: ${responseData.toString()}');
      if (result.isSuccess) {
        resetLocalData(
          status: 'pending',
          lecId: lecId,
          chapId: chapId,
          quizId: quizId,
          itemName: itemName,
        );
        return result;
      }
      return null;
    } catch (error) {
      debugPrint('sendPaymentRequest error: $error');
      return null;
    }
  }

  void resetLocalData({
    required String status,
    String? lecId,
    String? chapId,
    String? quizId,
    required String itemName,
  }) async {
    UserModel um = Constants.userBox.get('user');

    final now = DateTime.now();

    if (chapId != null) {
      // 1. Ensure the parent map exists
      um.purchasedVideos ??= {};

      // 2. Safely fetch or initialize the chapter object
      final chapter =
          um.purchasedVideos![chapId] ??= UserPurchasedChapterModel();

      if (lecId != null) {
        // 3. Ensure the nested lectures map exists
        chapter.lectures ??= {};

        // 4. Safely fetch or initialize the lecture object inside it
        final lecture =
            chapter.lectures![lecId] ??= UserPurchasedLectureModel();

        // 5. Update the lecture fields
        lecture.status = status;
        lecture.purchaseDateTime = now;
      } else {
        // 6. Chapter-Only Update
        chapter.status = status;
        chapter.purchaseDateTime = now;
      }
    } else if (quizId != null) {
      // Ensure quizzes map exists
      um.stdQuizes ??= {};

      // Direct initialization replaces redundant lookups
      um.stdQuizes![quizId] = StdQuizModel(
        id: '',
        title: itemName,
        dateTime: now, // Replaced duplicate DateTime.now() with cached 'now'
        fullMark: 0,
        questionNums: 0,
        degree: 0,
        triesNum: 1,
        userAnsIdx: {},
        submitTime: null,
        status: status,
        purchaseDateTime: now,
      );
    } else {
      // Wallet Only Update
      um.walletBalanceStatus = status;
      um.lastwalletBalanceTransaction = now;
    }

    await um.save();
    emit(PlatfomrRefreshState());
  }

  static const int invoicesPageSize = 5;
  List<InvoiceModel> allInvoices = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastInvoiceDoc;
  bool hasMoreInvoices = true;
  bool isLoadingMoreInvoices = false;

  Query<Map<String, dynamic>> _invoicesQuery() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: Constants.userBox.get('user').code)
        .orderBy('createdAt', descending: true)
        .limit(invoicesPageSize);
  }

  /// First page (also used for pull-to-refresh). Resets the cursor.
  Future<void> getAllInvoices() async {
    emit(PlatfromGetAllInvoicesLoadingState());
    _lastInvoiceDoc = null;
    hasMoreInvoices = true;
    isLoadingMoreInvoices = false;
    try {
      final value = await _invoicesQuery().get();
      allInvoices =
          value.docs.map((doc) => InvoiceModel.fromJson(doc.data())).toList();
      _lastInvoiceDoc = value.docs.isNotEmpty ? value.docs.last : null;
      hasMoreInvoices = value.docs.length == invoicesPageSize;
      emit(PlatfromGetAllInvoicesSuccessState());
    } catch (error) {
      debugPrint('Error fetching invoices: $error');
      emit(PlatfromGetAllInvoicesFailState(error.toString()));
    }
  }

  /// Loads the next page when the user scrolls to the bottom.
  Future<void> getMoreInvoices() async {
    if (isLoadingMoreInvoices || !hasMoreInvoices || _lastInvoiceDoc == null) {
      return;
    }
    isLoadingMoreInvoices = true;
    emit(PlatfromGetMoreInvoicesLoadingState());
    try {
      final value =
          await _invoicesQuery().startAfterDocument(_lastInvoiceDoc!).get();
      allInvoices
          .addAll(value.docs.map((doc) => InvoiceModel.fromJson(doc.data())));
      if (value.docs.isNotEmpty) _lastInvoiceDoc = value.docs.last;
      hasMoreInvoices = value.docs.length == invoicesPageSize;
      isLoadingMoreInvoices = false;
      emit(PlatfromGetMoreInvoicesSuccessState());
    } catch (error) {
      debugPrint('Error fetching more invoices: $error');
      isLoadingMoreInvoices = false;
      emit(PlatfromGetMoreInvoicesFailState(error.toString()));
    }
  }
}
