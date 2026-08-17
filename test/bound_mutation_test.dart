import 'package:bound_mutation/bound_mutation.dart';
import 'package:test/test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('BoundMutation', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('construction', () {
      test('can be created with callback and label', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
          label: 'my-label',
        );
        expect(bm, isNotNull);
        expect(bm.toString(), contains('my-label'));
      });

      test('can be created without label', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm, isNotNull);
      });

      test('can be created with void ResultT', () {
        final bm = BoundMutation<void, String>((transaction, input) async {});
        expect(bm, isNotNull);
      });

      test('can be created with different type parameters', () {
        final bm = BoundMutation<double, int>(
          (transaction, input) async => input.toDouble(),
        );
        expect(bm, isNotNull);
      });
    });

    group('toString', () {
      test('returns formatted string with type parameters', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm.toString(), contains('BoundMutation<int,String>'));
      });

      test('returns different string for different type params', () {
        final bm = BoundMutation<double, int>(
          (transaction, input) async => input.toDouble(),
        );
        expect(bm.toString(), contains('BoundMutation<double,int>'));
      });
    });

    group('equality', () {
      test('same instance is equal to itself', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm, equals(bm));
      });

      test('different instances are not equal', () {
        final bm1 = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final bm2 = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm1, isNot(equals(bm2)));
      });

      test('different type params are not equal', () {
        final bm1 = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final bm2 = BoundMutation<double, String>(
          (transaction, input) async => input.length.toDouble(),
        );
        expect(bm1, isNot(equals(bm2)));
      });

      test('hashCode is consistent with equality', () {
        final bm1 = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final bm2 = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm1.hashCode, equals(bm1.hashCode));
        expect(bm1.hashCode, isNot(equals(bm2.hashCode)));
      });
    });

    group('source', () {
      test('returns internal Mutation as ProviderListenable', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(bm.source, isNotNull);
        expect(bm.source, isA<ProviderListenable<MutationState<int>>>());
      });

      test('source is same object across multiple accesses', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(identical(bm.source, bm.source), isTrue);
      });
    });

    group('run', () {
      test('executes callback and returns result', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final result = await bm.run(container, 'hello');
        expect(result, 5);
      });

      test('returns result with different types', () async {
        final bm = BoundMutation<String, int>(
          (transaction, input) async => input.toString(),
        );
        final result = await bm.run(container, 42);
        expect(result, '42');
      });

      test('can receive ProviderContainer as MutationTarget', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final result = await bm.run(container, 'test');
        expect(result, 4);
      });

      test('callback receives transaction and input', () async {
        String? capturedInput;
        MutationTransaction? capturedTransaction;

        final bm = BoundMutation<int, String>((transaction, input) async {
          capturedTransaction = transaction;
          capturedInput = input;
          return input.length;
        });

        await bm.run(container, 'test');

        expect(capturedInput, 'test');
        expect(capturedTransaction, isNotNull);
      });

      test('mutation state transitions through pending to success', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        final subscription = container.listen<MutationState<int>>(bm, (
          prev,
          next,
        ) {
          states.add(next);
        }, fireImmediately: true);

        final result = await bm.run(container, 'hello');

        expect(result, 5);
        expect(states.length, greaterThanOrEqualTo(3));
        expect(states.first.isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states.last.isSuccess, isTrue);
        expect((states.last as MutationSuccess<int>).value, 5);

        subscription.close();
      });

      test('handles errors and transitions to error state', () async {
        final exception = Exception('test error');
        final bm = BoundMutation<int, String>((transaction, input) async {
          throw exception;
        });
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await expectLater(
          bm.run(container, 'hello'),
          throwsA(equals(exception)),
        );

        expect(states.first.isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states.last.hasError, isTrue);
        expect((states.last as MutationError<int>).error, equals(exception));
      });

      test('can run multiple times with different inputs', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );

        final result1 = await bm.run(container, 'hi');
        final result2 = await bm.run(container, 'hello');

        expect(result1, 2);
        expect(result2, 5);
      });

      test('can run multiple times accumulating results', () async {
        var counter = 0;
        final bm = BoundMutation<int, void>((transaction, input) async {
          counter++;
          return counter;
        });

        expect(await bm.run(container, null), 1);
        expect(await bm.run(container, null), 2);
        expect(await bm.run(container, null), 3);
      });

      test('void mutation runs and completes', () async {
        var called = false;
        final bm = BoundMutation<void, String>((transaction, input) async {
          called = true;
        });

        await bm.run(container, 'test');
        expect(called, isTrue);
      });
    });

    group('reset', () {
      test('resets mutation state back to idle after successful run', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await bm.run(container, 'hello');

        // Clear states tracked during run
        states.clear();

        bm.reset(container);

        expect(states.length, 1);
        expect(states.single.isIdle, isTrue);
      });

      test('resets mutation state back to idle after error', () async {
        final bm = BoundMutation<int, String>((transaction, input) async {
          throw Exception('error');
        });
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        try {
          await bm.run(container, 'hello');
        } catch (_) {}

        states.clear();

        bm.reset(container);

        expect(states.single.isIdle, isTrue);
      });

      test('reset on idle mutation stays idle', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        // First state is Idle from fireImmediately
        expect(states.single.isIdle, isTrue);
        states.clear();

        bm.reset(container);

        // Reset on idle triggers no additional state changes
        expect(states, isEmpty);
      });

      test('can run again after reset', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );

        await bm.run(container, 'first');
        bm.reset(container);
        final result = await bm.run(container, 'second');

        expect(result, 6);
      });
    });

    group('ProviderListenable integration', () {
      test('can be listened to via ProviderContainer', () {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        final subscription = container.listen<MutationState<int>>(bm, (
          prev,
          next,
        ) {
          states.add(next);
        }, fireImmediately: true);

        expect(states.length, 1);
        expect(states.first.isIdle, isTrue);

        subscription.close();
      });

      test('listener receives all state transitions', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await bm.run(container, 'x');
        bm.reset(container);

        // Idle → Pending → Success → Idle (reset)
        expect(states.length, 4);
        expect(states[0].isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states[2].isSuccess, isTrue);
        expect(states[3].isIdle, isTrue);
      });

      test('multiple listeners receive same state changes', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states1 = <MutationState<int>>[];
        final states2 = <MutationState<int>>[];

        container.listen<MutationState<int>>(bm, (prev, next) {
          states1.add(next);
        }, fireImmediately: true);
        container.listen<MutationState<int>>(bm, (prev, next) {
          states2.add(next);
        }, fireImmediately: true);

        await bm.run(container, 'test');

        expect(states1.length, states2.length);
        for (var i = 0; i < states1.length; i++) {
          expect(states1[i], equals(states2[i]));
        }
      });

      test('removing listener stops receiving updates', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        final states = <MutationState<int>>[];

        final subscription = container.listen<MutationState<int>>(bm, (
          prev,
          next,
        ) {
          states.add(next);
        }, fireImmediately: true);

        subscription.close();
        states.clear();

        await bm.run(container, 'test');

        expect(states, isEmpty);
      });
    });

    group('edge cases', () {
      test('callback that returns Future with delay', () async {
        final bm = BoundMutation<int, String>((transaction, input) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return input.length;
        });

        final result = await bm.run(container, 'delayed');
        expect(result, 7);
      });

      test('callback receives empty string', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );

        final result = await bm.run(container, '');
        expect(result, 0);
      });

      test('callback throws immediately (sync error)', () async {
        final bm = BoundMutation<int, String>(
          (transaction, input) => throw FormatException('bad input'),
        );

        await expectLater(
          bm.run(container, 'test'),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });

  group('BoundAction', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('construction', () {
      test('can be created with callback and label', () {
        final ba = BoundAction<int>((transaction) async => 42,
            label: 'my-label');
        expect(ba, isNotNull);
        expect(ba.toString(), contains('my-label'));
      });

      test('can be created without label', () {
        final ba = BoundAction<int>((transaction) async => 42);
        expect(ba, isNotNull);
      });

      test('can be created with void ResultT', () {
        final ba = BoundAction<void>((transaction) async {});
        expect(ba, isNotNull);
      });
    });

    group('toString', () {
      test('returns formatted string with type parameter', () {
        final ba = BoundAction<int>((transaction) async => 42);
        expect(ba.toString(), contains('BoundAction<int>'));
      });
    });

    group('equality', () {
      test('same instance is equal to itself', () {
        final ba = BoundAction<int>((transaction) async => 42);
        expect(ba, equals(ba));
      });

      test('different instances are not equal', () {
        final ba1 = BoundAction<int>((transaction) async => 42);
        final ba2 = BoundAction<int>((transaction) async => 42);
        expect(ba1, isNot(equals(ba2)));
      });

      test('is not equal to a BoundMutation', () {
        final ba = BoundAction<int>((transaction) async => 42);
        final bm = BoundMutation<int, String>(
          (transaction, input) async => input.length,
        );
        expect(ba, isNot(equals(bm)));
        expect(bm, isNot(equals(ba)));
      });

      test('hashCode is consistent with equality', () {
        final ba1 = BoundAction<int>((transaction) async => 42);
        final ba2 = BoundAction<int>((transaction) async => 42);
        expect(ba1.hashCode, equals(ba1.hashCode));
        expect(ba1.hashCode, isNot(equals(ba2.hashCode)));
      });
    });

    group('source', () {
      test('returns internal Mutation as ProviderListenable', () {
        final ba = BoundAction<int>((transaction) async => 42);
        expect(ba.source, isNotNull);
        expect(ba.source, isA<ProviderListenable<MutationState<int>>>());
      });
    });

    group('run', () {
      test('executes callback and returns result', () async {
        final ba = BoundAction<int>((transaction) async => 42);
        final result = await ba.run(container);
        expect(result, 42);
      });

      test('callback receives transaction', () async {
        MutationTransaction? capturedTransaction;

        final ba = BoundAction<int>((transaction) async {
          capturedTransaction = transaction;
          return 42;
        });

        await ba.run(container);

        expect(capturedTransaction, isNotNull);
      });

      test('mutation state transitions through pending to success', () async {
        final ba = BoundAction<int>((transaction) async => 42);
        final states = <MutationState<int>>[];

        final subscription = container.listen<MutationState<int>>(ba, (
          prev,
          next,
        ) {
          states.add(next);
        }, fireImmediately: true);

        final result = await ba.run(container);

        expect(result, 42);
        expect(states.length, greaterThanOrEqualTo(3));
        expect(states.first.isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states.last.isSuccess, isTrue);
        expect((states.last as MutationSuccess<int>).value, 42);

        subscription.close();
      });

      test('handles errors and transitions to error state', () async {
        final exception = Exception('test error');
        final ba = BoundAction<int>((transaction) async {
          throw exception;
        });
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(ba, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await expectLater(ba.run(container), throwsA(equals(exception)));

        expect(states.first.isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states.last.hasError, isTrue);
        expect((states.last as MutationError<int>).error, equals(exception));
      });

      test('can run multiple times accumulating results', () async {
        var counter = 0;
        final ba = BoundAction<int>((transaction) async {
          counter++;
          return counter;
        });

        expect(await ba.run(container), 1);
        expect(await ba.run(container), 2);
        expect(await ba.run(container), 3);
      });
    });

    group('reset', () {
      test('resets mutation state back to idle after successful run', () async {
        final ba = BoundAction<int>((transaction) async => 42);
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(ba, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await ba.run(container);

        states.clear();

        ba.reset(container);

        expect(states.length, 1);
        expect(states.single.isIdle, isTrue);
      });

      test('can run again after reset', () async {
        var counter = 0;
        final ba = BoundAction<int>((transaction) async {
          counter++;
          return counter;
        });

        expect(await ba.run(container), 1);
        ba.reset(container);
        expect(await ba.run(container), 2);
      });
    });

    group('ProviderListenable integration', () {
      test('can be listened to via ProviderContainer', () {
        final ba = BoundAction<int>((transaction) async => 42);
        final states = <MutationState<int>>[];

        final subscription = container.listen<MutationState<int>>(ba, (
          prev,
          next,
        ) {
          states.add(next);
        }, fireImmediately: true);

        expect(states.length, 1);
        expect(states.first.isIdle, isTrue);

        subscription.close();
      });

      test('listener receives all state transitions', () async {
        final ba = BoundAction<int>((transaction) async => 42);
        final states = <MutationState<int>>[];

        container.listen<MutationState<int>>(ba, (prev, next) {
          states.add(next);
        }, fireImmediately: true);

        await ba.run(container);
        ba.reset(container);

        expect(states.length, 4);
        expect(states[0].isIdle, isTrue);
        expect(states[1].isPending, isTrue);
        expect(states[2].isSuccess, isTrue);
        expect(states[3].isIdle, isTrue);
      });
    });
  });
}
