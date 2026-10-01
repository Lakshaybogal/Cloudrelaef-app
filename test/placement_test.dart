import 'package:cloudrelaef/services/placement.dart';
import 'package:flutter_test/flutter_test.dart';

Candidate c(
  int id, {
  int? total = 100,
  int used = 0,
  bool active = true,
  String provider = 'x',
}) => Candidate(
  accountId: id,
  provider: provider,
  active: active,
  total: total,
  used: used,
);

void main() {
  final engine = PlacementEngine(MostFreeSpace());

  test('picks the account with the most free space', () {
    expect(engine.place([c(1, used: 50), c(2, used: 10)], 5).accountId, 2);
  });

  test('ties go to the lowest account id', () {
    expect(engine.place([c(3), c(2), c(5)], 1).accountId, 2);
  });

  test('skips inactive accounts', () {
    expect(engine.place([c(1, active: false), c(2, used: 90)], 5).accountId, 2);
  });

  test('skips accounts that cannot fit the file', () {
    expect(engine.place([c(1, used: 98), c(2, used: 50)], 10).accountId, 2);
  });

  test('unlimited accounts always fit and win', () {
    expect(
      engine.place([c(1), c(2, total: null, used: 999)], 1 << 40).accountId,
      2,
    );
  });

  test('safety margin is respected', () {
    final e = PlacementEngine(MostFreeSpace(), safetyMarginBytes: 20);
    expect(e.place([c(1, used: 85), c(2, used: 70)], 10).accountId, 2);
    expect(
      () => e.place([c(1, used: 85)], 10),
      throwsA(isA<NoCapacityError>()),
    );
  });

  test('no accounts -> NoCapacityError', () {
    expect(() => engine.place([], 1), throwsA(isA<NoCapacityError>()));
  });

  test('over-used account has zero free, not negative', () {
    expect(c(1, used: 150).free, 0);
  });

  test('strategy registry', () {
    expect(strategyByName('most_free_space'), isA<MostFreeSpace>());
    expect(() => strategyByName('nope'), throwsArgumentError);
  });
}
