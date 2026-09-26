class Membership {
  const Membership({
    required this.active,
    required this.status,
    this.expiresAt,
  });

  final bool active;
  final String status;
  final DateTime? expiresAt;

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      active: json['active'] == true,
      status: json['status'] as String? ?? 'none',
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse(json['expires_at'].toString()),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.onboarded,
    required this.membership,
    this.displayName,
  });

  final int id;
  final String phone;
  final String? displayName;
  final bool onboarded;
  final Membership membership;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      displayName: json['display_name'] as String?,
      onboarded: json['onboarded'] == true,
      membership: Membership.fromJson(
        Map<String, dynamic>.from(json['membership'] as Map? ?? const {}),
      ),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}

class OnboardingPayload {
  const OnboardingPayload({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.experience,
    required this.environment,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.goal,
    this.limitations,
  });

  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String experience;
  final String environment;
  final List<String> equipment;
  final int daysPerWeek;
  final int sessionMinutes;
  final String goal;
  final String? limitations;

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'experience': experience,
        'environment': environment,
        'equipment': equipment,
        'days_per_week': daysPerWeek,
        'session_minutes': sessionMinutes,
        'goal': goal,
        'limitations': limitations,
      };
}

class PlanExercise {
  const PlanExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.type = 'weight',
  });

  final String name;
  final int sets;
  final String reps;
  final String type;

  factory PlanExercise.fromList(List<dynamic> value) {
    return PlanExercise(
      name: value.isNotEmpty ? value[0].toString() : '',
      sets: value.length > 1 ? (num.tryParse(value[1].toString())?.toInt() ?? 3) : 3,
      reps: value.length > 2 ? value[2].toString() : '8–12',
      type: value.length > 3 ? value[3].toString() : 'weight',
    );
  }
}

class PlanDay {
  const PlanDay({
    required this.name,
    required this.note,
    required this.exercises,
  });

  final String name;
  final String note;
  final List<PlanExercise> exercises;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final exercises = (json['exercises'] as List? ?? const [])
        .whereType<List>()
        .map(PlanExercise.fromList)
        .toList();
    return PlanDay(
      name: json['name'] as String? ?? '训练日',
      note: json['note'] as String? ?? '',
      exercises: exercises,
    );
  }
}

class PlanPreview {
  const PlanPreview({required this.summary, required this.days});

  final String summary;
  final List<PlanDay> days;

  factory PlanPreview.fromJson(Map<String, dynamic> json) {
    final plans = (json['plans'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => PlanDay.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return PlanPreview(
      summary: json['summary'] as String? ?? '',
      days: plans,
    );
  }
}
