class StudentsModel {
  final String StdId;
  final String Name;
  final String Group;
  final String groupid;

  final Map<String, bool> Attendance;

  StudentsModel({
    required this.StdId,
    required this.Name,
    required this.Group,
    required this.Attendance,
    required this.groupid,
  });

  factory StudentsModel.fromJson(Map<String, dynamic> json) {
    return StudentsModel(
      StdId: json['code'],
      Name: json['ar_fname'] + " " + json['ar_sname'],
      Group: json['groupName'],
      groupid: json['groupId'],
      Attendance: Map<String, bool>.from(json['attendance']),
    );
  }
  // factory StudentsModel.fromJson(Map<String, dynamic> json) {
  //   return StudentsModel(
  //     StdId: json['StdId'] ?? '',
  //     Name: json['Name'] ?? '',
  //     Group: json['Group'] ?? '',
  //     Attendance: json['Attendance'] != null
  //         ? Map<String, bool>.from(json['Attendance'])
  //         : {},
  //   );
  // }
  Map<String, dynamic> toMap() {
    return {
      'StdId': StdId,
      'Name': Name,
    };
  }
}
