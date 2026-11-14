import 'package:flutter_test/flutter_test.dart';
import 'package:midweek_meeting_sc9/main.dart';

void main() {
  test('default schedule preserves S-140-CV printed part numbers', () {
    final schedule = MeetingSchedule();
    expect(schedule.parts.map((part) => part.number).toList(),
        [1, 2, 3, 5, 6, 7, 8, 9, 10]);
    expect(schedule.introduction, '1');
    expect(schedule.conclusion, '3');
  });

  test('schedule survives JSON round trip', () {
    final original = MeetingSchedule(
      congregation: 'Pananglitan nga Kongregasyon',
      bibleReading: 'Isaias 1-2',
      chairman: 'Juan',
    );
    original.parts[3].student = 'Pedro';
    original.parts[3].assistant = 'Maria';
    final restored = MeetingSchedule.fromJson(original.toJson());
    expect(restored.congregation, original.congregation);
    expect(restored.bibleReading, original.bibleReading);
    expect(restored.parts[3].student, 'Pedro');
    expect(restored.parts[3].assistant, 'Maria');
    expect(restored.id, original.id);
  });
}
