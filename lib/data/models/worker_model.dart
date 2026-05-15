class WorkerModel {
  final String name;
  final String role;
  final String workerId;
  final String facility;
  final String county;
  final String phone;
  final int facilitiesCount;
  final bool active;

  const WorkerModel({
    required this.name,
    required this.role,
    required this.workerId,
    required this.facility,
    required this.county,
    required this.phone,
    this.facilitiesCount = 0,
    this.active = true,
  });
}
