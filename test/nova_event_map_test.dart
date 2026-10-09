import 'package:flutter_test/flutter_test.dart';
import 'package:snapfood/shared/nova/nova_event_map.dart';
import 'package:snapfood/shared/nova/nova_state.dart';

void main() {
  group('novaStateForEvent', () {
    test('every AppEvent resolves to a NovaState without throwing', () {
      for (final event in AppEvent.values) {
        expect(
          () => novaStateForEvent(event),
          returnsNormally,
          reason: 'Event $event threw',
        );
      }
    });

    test('maps loading events to thinking', () {
      expect(novaStateForEvent(AppEvent.loading), NovaState.thinking);
      expect(novaStateForEvent(AppEvent.photoTaken), NovaState.thinking);
    });

    test('maps success events to happy', () {
      expect(novaStateForEvent(AppEvent.recognitionSuccess), NovaState.happy);
      expect(novaStateForEvent(AppEvent.recipeLoaded), NovaState.happy);
      expect(novaStateForEvent(AppEvent.selectionConfirmed), NovaState.happy);
    });

    test('maps error events to error', () {
      expect(novaStateForEvent(AppEvent.recognitionFailed), NovaState.error);
      expect(novaStateForEvent(AppEvent.noNetwork), NovaState.error);
      expect(novaStateForEvent(AppEvent.permissionDenied), NovaState.error);
    });

    test('maps celebration events to celebrating', () {
      expect(novaStateForEvent(AppEvent.recipeSaved), NovaState.celebrating);
      expect(novaStateForEvent(AppEvent.onboardingDone), NovaState.celebrating);
    });

    test('maps launch/scan events to idle', () {
      expect(novaStateForEvent(AppEvent.appLaunch), NovaState.idle);
      expect(novaStateForEvent(AppEvent.scanStarted), NovaState.idle);
    });

    test('kNovaEventMap covers every AppEvent', () {
      for (final event in AppEvent.values) {
        expect(
          kNovaEventMap.containsKey(event),
          isTrue,
          reason: 'AppEvent.$event is not in kNovaEventMap',
        );
      }
    });
  });
}
