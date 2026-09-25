class WorkerModel {
  final String id;
  final String name;
  final String role;
  final String workerId;
  final String facility;
  final String county;
  final String phone;
  final int facilitiesCount;
  final bool active;

  /// Support contacts for this worker's programme, served with the profile so
  /// the app never shows a placeholder address.
  final String? supportEmail;
  final String? supportPhone;

  const WorkerModel({
    this.id = '',
    required this.name,
    required this.role,
    required this.workerId,
    required this.facility,
    required this.county,
    required this.phone,
    this.facilitiesCount = 0,
    this.active = true,
    this.supportEmail,
    this.supportPhone,
  });

  /// "Unity State • Bentiu PHCC" for the app header — built from whichever of
  /// the two the server actually gave us.
  String get postingLabel =>
      [county, facility].where((e) => e.isNotEmpty).join(' • ');

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'CHW',
      workerId: json['workerId'] as String? ?? '',
      facility: json['facility'] as String? ?? '',
      county: json['county'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      facilitiesCount: (json['facilitiesCount'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      supportEmail: json['supportEmail'] as String?,
      supportPhone: json['supportPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'workerId': workerId,
        'facility': facility,
        'county': county,
        'phone': phone,
        'facilitiesCount': facilitiesCount,
        'active': active,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
      };
}
