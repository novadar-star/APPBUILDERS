import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapfood/domain/models.dart';

class PreferencesStore {
  static const _equipmentKey = 'equipment';
  static const _budgetKey = 'budget';

  /// Loads persisted preferences. Returns defaults ({riceCooker}, budget 30)
  /// if nothing has been saved yet.
  Future<Preferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final equipmentList = prefs.getStringList(_equipmentKey);
    final budget = prefs.getInt(_budgetKey) ?? 30;

    Set<Equipment> equipment;
    if (equipmentList == null || equipmentList.isEmpty) {
      equipment = {Equipment.riceCooker};
    } else {
      equipment = equipmentList.map(_equipmentFromString).toSet();
    }

    return Preferences(equipment: equipment, extraBudgetPesos: budget);
  }

  /// Persists the given preferences.
  Future<void> save(Preferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await Future.wait([
      sp.setStringList(
        _equipmentKey,
        prefs.equipment.map(_equipmentToString).toList(),
      ),
      sp.setInt(_budgetKey, prefs.extraBudgetPesos),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Helpers — keep codec logic here, not in models.dart
// ---------------------------------------------------------------------------
String _equipmentToString(Equipment e) {
  switch (e) {
    case Equipment.riceCooker:
      return 'riceCooker';
    case Equipment.kettle:
      return 'kettle';
    case Equipment.microwave:
      return 'microwave';
    case Equipment.stove:
      return 'stove';
  }
}

Equipment _equipmentFromString(String value) {
  switch (value) {
    case 'riceCooker':
      return Equipment.riceCooker;
    case 'kettle':
      return Equipment.kettle;
    case 'microwave':
      return Equipment.microwave;
    case 'stove':
      return Equipment.stove;
    default:
      throw ArgumentError('Unknown equipment string: $value');
  }
}
