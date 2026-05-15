import '../models/activity_model.dart';
import '../models/child_model.dart';
import '../models/facility_model.dart';
import '../models/vaccination_record.dart';
import '../models/worker_model.dart';

class SalamaData {
  SalamaData._();

  static const WorkerModel worker = WorkerModel(
    name: 'Achieng Manyiel',
    role: 'Community Health Worker (CHW)',
    workerId: 'CHW-1047',
    facility: 'Bentiu PHCC',
    county: 'Rubkona County',
    phone: '+211 92 123 4567',
    facilitiesCount: 4,
    active: true,
  );

  // ── Children (only those assigned to this worker) ──────────────────────
  static const List<ChildModel> children = [
    ChildModel(
      id: 'C-1047',
      name: 'Achol Nyakuoth',
      gender: 'Female',
      ageLabel: '6 weeks',
      bornDate: 'May 12, 2024',
      riskScore: 0.94,
      distanceKm: 2.1,
      lastSeen: 'Never contacted',
      currentLocation: 'Bentiu IDP Camp · Block C',
      parentName: 'Nyakong Chuol (mother)',
      parentPhone: '+211 92 110 4471',
      dueVaccines: ['BCG', 'OPV-0'],
      history: [],
      status: VisitStatus.toVisit,
    ),
    ChildModel(
      id: 'C-0823',
      name: 'Nyakim Deng',
      gender: 'Female',
      ageLabel: '14 weeks',
      bornDate: 'Feb 03, 2024',
      riskScore: 0.87,
      distanceKm: 3.4,
      lastSeen: 'Last seen 28d ago',
      currentLocation: 'Rubkona Town · near market',
      parentName: 'Adhel Deng (mother)',
      parentPhone: '+211 92 334 8820',
      dueVaccines: ['Penta-2', 'OPV-2'],
      history: [
        VaccinationRecord(
            vaccine: 'BCG',
            dose: 'Birth dose',
            date: 'Feb 05, 2024',
            status: DoseStatus.given,
            batch: 'BCG-2401'),
        VaccinationRecord(
            vaccine: 'OPV-0',
            dose: 'Birth dose',
            date: 'Feb 05, 2024',
            status: DoseStatus.given,
            batch: 'OPV-1180'),
        VaccinationRecord(
            vaccine: 'Penta-1',
            dose: '1st dose',
            date: 'Mar 18, 2024',
            status: DoseStatus.given,
            batch: 'PEN-3302'),
        VaccinationRecord(
            vaccine: 'OPV-1',
            dose: '1st dose',
            date: 'Mar 18, 2024',
            status: DoseStatus.given,
            batch: 'OPV-1212'),
        VaccinationRecord(
            vaccine: 'Penta-2',
            dose: '2nd dose',
            date: 'Due now',
            status: DoseStatus.due),
      ],
      status: VisitStatus.toVisit,
    ),
    ChildModel(
      id: 'C-2190',
      name: 'Gatluak Mabior',
      gender: 'Male',
      ageLabel: '9 months',
      bornDate: 'Aug 21, 2023',
      riskScore: 0.81,
      distanceKm: 1.8,
      lastSeen: 'Last seen 45d ago',
      currentLocation: 'Kaler Village',
      parentName: 'Mary Nyandeng (mother)',
      parentPhone: '+211 92 556 1093',
      dueVaccines: ['Measles-1', 'Rota-2'],
      history: [
        VaccinationRecord(
            vaccine: 'BCG',
            dose: 'Birth dose',
            date: 'Aug 23, 2023',
            status: DoseStatus.given,
            batch: 'BCG-2298'),
        VaccinationRecord(
            vaccine: 'Penta-1',
            dose: '1st dose',
            date: 'Oct 02, 2023',
            status: DoseStatus.given,
            batch: 'PEN-3110'),
        VaccinationRecord(
            vaccine: 'Penta-3',
            dose: '3rd dose',
            date: 'Dec 14, 2023',
            status: DoseStatus.given,
            batch: 'PEN-3271'),
        VaccinationRecord(
            vaccine: 'Rota-1',
            dose: '1st dose',
            date: 'Oct 02, 2023',
            status: DoseStatus.given,
            batch: 'ROT-0904'),
        VaccinationRecord(
            vaccine: 'Measles-1',
            dose: '9-month dose',
            date: 'Missed — overdue',
            status: DoseStatus.missed),
      ],
      status: VisitStatus.toVisit,
    ),
    ChildModel(
      id: 'C-0456',
      name: 'Ayen Lual',
      gender: 'Female',
      ageLabel: '6 weeks',
      bornDate: 'May 09, 2024',
      riskScore: 0.76,
      distanceKm: 4.1,
      lastSeen: 'Never contacted',
      currentLocation: 'Bentiu IDP Camp · Block A',
      parentName: null,
      parentPhone: null,
      dueVaccines: ['BCG'],
      history: [],
      status: VisitStatus.toVisit,
    ),
    ChildModel(
      id: 'C-1832',
      name: 'Malou Jok',
      gender: 'Male',
      ageLabel: '14 weeks',
      bornDate: 'Feb 14, 2024',
      riskScore: 0.71,
      distanceKm: 2.9,
      lastSeen: 'Last seen 21d ago',
      currentLocation: 'Nhialdiu Road · Sector 4',
      parentName: 'Tabitha Jok (mother)',
      parentPhone: '+211 92 778 2245',
      dueVaccines: ['Penta-2'],
      history: [
        VaccinationRecord(
            vaccine: 'BCG',
            dose: 'Birth dose',
            date: 'Feb 16, 2024',
            status: DoseStatus.given,
            batch: 'BCG-2405'),
        VaccinationRecord(
            vaccine: 'OPV-0',
            dose: 'Birth dose',
            date: 'Feb 16, 2024',
            status: DoseStatus.given,
            batch: 'OPV-1190'),
        VaccinationRecord(
            vaccine: 'Penta-1',
            dose: '1st dose',
            date: 'Mar 29, 2024',
            status: DoseStatus.given,
            batch: 'PEN-3340'),
      ],
      status: VisitStatus.visited,
    ),
    ChildModel(
      id: 'C-2044',
      name: 'Nyantap Riek',
      gender: 'Female',
      ageLabel: '10 months',
      bornDate: 'Jul 18, 2023',
      riskScore: 0.64,
      distanceKm: 5.2,
      lastSeen: 'Last seen 12d ago',
      currentLocation: 'Bentiu Town · Hai Salam',
      parentName: 'Rebecca Riek (mother)',
      parentPhone: '+211 92 901 5567',
      dueVaccines: ['Measles-1'],
      history: [
        VaccinationRecord(
            vaccine: 'BCG',
            dose: 'Birth dose',
            date: 'Jul 20, 2023',
            status: DoseStatus.given,
            batch: 'BCG-2270'),
        VaccinationRecord(
            vaccine: 'Penta-3',
            dose: '3rd dose',
            date: 'Nov 28, 2023',
            status: DoseStatus.given,
            batch: 'PEN-3260'),
        VaccinationRecord(
            vaccine: 'OPV-3',
            dose: '3rd dose',
            date: 'Nov 28, 2023',
            status: DoseStatus.given,
            batch: 'OPV-1205'),
        VaccinationRecord(
            vaccine: 'Measles-1',
            dose: '9-month dose',
            date: 'Due now',
            status: DoseStatus.due),
      ],
      status: VisitStatus.visited,
    ),
  ];

  // ── Facilities across the region ───────────────────────────────────────
  static const List<FacilityModel> facilities = [
    FacilityModel(
      name: 'Bentiu PHCC',
      county: 'Bentiu, Rubkona County',
      children: 128,
      cdiScore: 0.72,
      risk: FacilityRisk.danger,
      hazard: 'Seasonal flooding',
      daysToWindow: 18,
      hazardTimeframe: 'Expected to last 3–4 weeks',
      hazardDetail:
          'Seasonal river flooding is forecast to cut off road access and '
          'damage the cold chain. Prioritise vaccinating high-risk children '
          'before water levels peak.',
      highPriority: 25,
      dueSoon: 63,
      recentlyVisited: 40,
      assigned: true,
    ),
    FacilityModel(
      name: 'Kaled Clinic',
      county: 'Kaled, Rubkona County',
      children: 64,
      cdiScore: 0.81,
      risk: FacilityRisk.danger,
      hazard: 'Flash flooding',
      daysToWindow: 12,
      hazardTimeframe: 'Routes impassable for ~2 weeks',
      hazardDetail:
          'Heavy upstream rainfall is expected to trigger flash floods. '
          'Outreach routes may be impassable for up to two weeks.',
      highPriority: 18,
      dueSoon: 30,
      recentlyVisited: 16,
      assigned: true,
    ),
    FacilityModel(
      name: 'Rubkona Health Unit',
      county: 'Rubkona, Rubkona County',
      children: 86,
      cdiScore: 0.58,
      risk: FacilityRisk.warning,
      hazard: 'Heavy rainfall',
      daysToWindow: 26,
      hazardTimeframe: 'Disruption window of 1–2 weeks',
      hazardDetail:
          'Above-average rainfall may slow outreach and increase disease '
          'spread. Plan indoor vaccination sessions where possible.',
      highPriority: 14,
      dueSoon: 44,
      recentlyVisited: 28,
      assigned: true,
    ),
    FacilityModel(
      name: 'Mayendit Clinic',
      county: 'Mayendit, Rubkona County',
      children: 71,
      cdiScore: 0.55,
      risk: FacilityRisk.warning,
      hazard: 'Heatwave',
      daysToWindow: 29,
      hazardTimeframe: 'Heat spell of about 10 days',
      hazardDetail:
          'A prolonged heatwave threatens vaccine potency. Verify cold-chain '
          'capacity and schedule visits in the early morning.',
      highPriority: 11,
      dueSoon: 38,
      recentlyVisited: 22,
      assigned: true,
    ),
    FacilityModel(
      name: 'Guit PHCU',
      county: 'Guit, Guit County',
      children: 58,
      cdiScore: 0.88,
      risk: FacilityRisk.danger,
      hazard: 'Severe flooding',
      daysToWindow: 9,
      hazardTimeframe: 'Imminent — peaks within 2 weeks',
      hazardDetail:
          'Severe flooding is imminent. Coordinate with the county team for '
          'an emergency immunization push.',
      highPriority: 22,
      dueSoon: 26,
      recentlyVisited: 10,
      assigned: false,
    ),
    FacilityModel(
      name: 'Leer Outreach Post',
      county: 'Leer, Leer County',
      children: 52,
      cdiScore: 0.49,
      risk: FacilityRisk.warning,
      hazard: 'Drought',
      daysToWindow: 34,
      hazardTimeframe: 'Prolonged — several months',
      hazardDetail:
          'Dry conditions are driving families to migrate, raising the risk '
          'of missed doses. Track mobile households closely.',
      highPriority: 9,
      dueSoon: 27,
      recentlyVisited: 16,
      assigned: false,
    ),
    FacilityModel(
      name: 'Nhialdiu PHCU',
      county: 'Nhialdiu, Rubkona County',
      children: 40,
      cdiScore: 0.21,
      risk: FacilityRisk.ok,
      hazard: 'No active hazard',
      daysToWindow: 0,
      hazardTimeframe: 'No disruption forecast',
      hazardDetail:
          'Climate conditions are stable. Maintain routine immunization and '
          'standard reporting.',
      highPriority: 3,
      dueSoon: 15,
      recentlyVisited: 22,
      assigned: false,
    ),
    FacilityModel(
      name: 'Koch Health Centre',
      county: 'Koch, Koch County',
      children: 38,
      cdiScore: 0.18,
      risk: FacilityRisk.ok,
      hazard: 'No active hazard',
      daysToWindow: 0,
      hazardTimeframe: 'No disruption forecast',
      hazardDetail:
          'No disruption expected in the forecast window. Continue normal '
          'operations.',
      highPriority: 2,
      dueSoon: 12,
      recentlyVisited: 24,
      assigned: false,
    ),
  ];

  static List<FacilityModel> get assignedFacilities =>
      facilities.where((f) => f.assigned).toList();

  // ── Recent activity ────────────────────────────────────────────────────
  static const List<ActivityModel> recentActivity = [
    ActivityModel(
      type: ActivityType.vaccination,
      title: 'Vaccination recorded',
      subtitle: 'BCG + OPV-0 for Achol Nyakuoth',
      time: '2h ago',
    ),
    ActivityModel(
      type: ActivityType.visit,
      title: 'Visit completed',
      subtitle: 'Outreach session at Bentiu PHCC',
      time: '4h ago',
    ),
    ActivityModel(
      type: ActivityType.alert,
      title: 'Risk alert raised',
      subtitle: 'Flood risk rising at Kaled Clinic',
      time: 'Yesterday',
    ),
    ActivityModel(
      type: ActivityType.sync,
      title: 'Data synced',
      subtitle: '14 records uploaded to server',
      time: 'Yesterday',
    ),
    ActivityModel(
      type: ActivityType.registration,
      title: 'New child registered',
      subtitle: 'Ayen Lual added to your register',
      time: '2d ago',
    ),
  ];

  // ── Sync status ────────────────────────────────────────────────────────
  static const String lastSync = 'Today, 6:30 AM';
  static const int pendingRecords = 12;
}
