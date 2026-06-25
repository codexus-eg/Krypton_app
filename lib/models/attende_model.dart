import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeModel {
  late bool isAttend;

  late DateTime date;

  String? groupName;

  DateTime? arrivalTime;

  bool? sent;

  String? hwDegree;
  String? examDegree;

  String? fullHWDegree;
  String? fullExamDegree;

  AttendeModel({
    required this.date,
    required this.isAttend,
    this.arrivalTime,
    this.hwDegree,
    this.examDegree,
    this.sent,
    this.groupName,
    this.fullHWDegree,
    this.fullExamDegree,
  });

  AttendeModel.fromJson(Map<String, dynamic> json) {
    isAttend = json['isAttend'] ?? false;
    hwDegree = json['hwDegree'];
    examDegree = json['degree'];

    if (json['date'] != null) {
      if (json['date'] is Timestamp) {
        date = (json['date'] as Timestamp).toDate();
      } else {
        date = json['date'];
      }
    }
    if (json['arrivalTime'] != null) {
      if (json['arrivalTime'] is Timestamp) {
        arrivalTime = (json['arrivalTime'] as Timestamp).toDate();
      } else {
        arrivalTime = json['arrivalTime'];
      }
    }
    groupName = json['groupName'];
    if (json['sent'] != null) {
      sent = json['sent'];
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'isAttend': isAttend,
      if (hwDegree != null) 'hwDegree': hwDegree,
      if (examDegree != null) 'degree': examDegree,
      if (arrivalTime != null) 'arrivalTime': arrivalTime!,
      if (sent != null) 'sent': sent,
      'date': date,
      if (groupName != null) 'groupName': groupName,
    };
  }

  /// ✅ copyWith method
  AttendeModel copyWith({
    bool? isAttend,
    DateTime? date,
    String? groupName,
    DateTime? arrivalTime,
    bool? sent,
    String? hwDegree,
    String? examDegree,
    String? fullHWDegree,
    String? fullExamDegree,
  }) {
    return AttendeModel(
      isAttend: isAttend ?? this.isAttend,
      date: date ?? this.date,
      groupName: groupName ?? this.groupName,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      sent: sent ?? this.sent,
      hwDegree: hwDegree ?? this.hwDegree,
      examDegree: examDegree ?? this.examDegree,
      fullHWDegree: fullHWDegree ?? this.fullHWDegree,
      fullExamDegree: fullExamDegree ?? this.fullExamDegree,
    );
  }
}
