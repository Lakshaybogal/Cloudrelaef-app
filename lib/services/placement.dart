/// Picks which connected account a new file goes to.
library;

/// A snapshot of an account a file could be placed on.
class Candidate {
  const Candidate({
    required this.accountId,
    required this.provider,
    required this.active,
    required this.total,
    required this.used,
  });
  final int accountId;
  final String provider;
  final bool active;

  /// null = unlimited or unknown.
  final int? total;
  final int used;

  /// Free bytes; unlimited accounts count as infinite.
  int get free => total == null ? _unlimited : (total! - used).clamp(0, total!);

  static const _unlimited = 1 << 62;
}

class NoCapacityError implements Exception {
  NoCapacityError(this.fileSize);
  final int fileSize;

  @override
  String toString() => 'No account has $fileSize bytes free';
}

abstract class PlacementStrategy {
  String get name;

  /// Picks one of [candidates] (all already eligible), or null.
  Candidate? choose(List<Candidate> candidates, int fileSize);
}

/// Sends the file to the account with the most free space.
/// Ties go to the lowest account id.
class MostFreeSpace implements PlacementStrategy {
  @override
  String get name => 'most_free_space';

  @override
  Candidate? choose(List<Candidate> candidates, int fileSize) {
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]
      ..sort((a, b) {
        final byFree = b.free.compareTo(a.free);
        return byFree != 0 ? byFree : a.accountId.compareTo(b.accountId);
      });
    return sorted.first;
  }
}

final Map<String, PlacementStrategy Function()> placementStrategies = {
  'most_free_space': MostFreeSpace.new,
};

PlacementStrategy strategyByName(String name) {
  final make = placementStrategies[name];
  if (make == null) throw ArgumentError.value(name, 'name', 'Unknown strategy');
  return make();
}

class PlacementEngine {
  PlacementEngine(this.strategy, {this.safetyMarginBytes = 0});
  final PlacementStrategy strategy;
  final int safetyMarginBytes;

  /// Keeps accounts that are active and fit `size + margin`, then lets the
  /// strategy pick. Throws [NoCapacityError] when none fit.
  Candidate place(List<Candidate> candidates, int fileSize) {
    final eligible = candidates
        .where((c) => c.active && c.free >= fileSize + safetyMarginBytes)
        .toList();
    final chosen = strategy.choose(eligible, fileSize);
    if (chosen == null) throw NoCapacityError(fileSize);
    return chosen;
  }
}
