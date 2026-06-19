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
  });

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
      };
}
