enum EmergencyType {
  fire,
  accident,
  medical,
  flood,
  crime,
  other,
  none,
}

class EmergencyResult {
  final EmergencyType type;
  final String description;
  final List<String> suggestedDepartments;

  EmergencyResult({
    required this.type,
    required this.description,
    required this.suggestedDepartments,
  });
}
