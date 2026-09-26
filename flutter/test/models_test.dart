import 'package:boji/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses user and membership', () {
    final user = AppUser.fromJson({
      'id': 1,
      'phone': '+8613800138000',
      'display_name': '测试用户',
      'onboarded': true,
      'membership': {
        'active': true,
        'status': 'active',
        'expires_at': '2027-09-26T00:00:00Z',
      },
    });

    expect(user.id, 1);
    expect(user.onboarded, isTrue);
    expect(user.membership.active, isTrue);
    expect(user.membership.expiresAt, isNotNull);
  });

  test('parses legacy plan arrays', () {
    final preview = PlanPreview.fromJson({
      'summary': '居家增肌计划',
      'plans': [
        {
          'name': '上肢推',
          'note': '控制动作节奏',
          'exercises': [
            ['哑铃卧推', 4, '8–12', 'weight'],
            ['俯卧撑', 3, '10–15', 'bodyweight'],
          ],
        },
      ],
    });

    expect(preview.days, hasLength(1));
    expect(preview.days.first.exercises, hasLength(2));
    expect(preview.days.first.exercises.first.name, '哑铃卧推');
  });

  test('serializes onboarding payload', () {
    const payload = OnboardingPayload(
      gender: 'male',
      age: 25,
      heightCm: 175,
      weightKg: 70,
      experience: 'beginner',
      environment: 'home',
      equipment: ['bodyweight', 'dumbbell'],
      daysPerWeek: 3,
      sessionMinutes: 45,
      goal: 'muscle_gain',
      limitations: '',
    );

    expect(payload.toJson()['height_cm'], 175);
    expect(payload.toJson()['days_per_week'], 3);
    expect(payload.toJson()['equipment'], ['bodyweight', 'dumbbell']);
  });
}

