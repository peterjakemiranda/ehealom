enum UserType {
  student,
  personnel,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.student:
        return 'Student';
      case UserType.personnel:
        return 'Personnel';
    }
  }
} 