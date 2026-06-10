# bound_mutation

A wrapper around [riverpod](https://pub.dev/packages/riverpod)'s `Mutation` that binds an input parameter to the mutation callback. Instead of capturing input at construction time, you pass it when calling `run`.

## Features

- Pre-bound mutation callbacks with an `InputR` type parameter
- Full `ProviderListenable<MutationState<ResultT>>` integration — listen to idle/pending/success/error states
- Thin wrapper: delegates directly to `Mutation.run` and `Mutation.reset`

## Usage

```dart
import 'package:bound_mutation/bound_mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a bound mutation: ResultT = String, InputR = int
final createUser = BoundMutation<String, int>(
  (transaction, userId) async {
    // transaction gives access to providers
    final repo = transaction.get(userRepositoryProvider);
    return repo.fetchUserName(userId);
  },
);

// Inside a provider or widget with a Ref:
Future<void> loadUser(WidgetRef ref) async {
  // Watch mutation state
  final state = ref.watch(createUser);

  if (state.isIdle) {
    final name = await createUser.run(ref, 42);
    print('User: $name');
  } else if (state.isPending) {
    print('Loading...');
  } else if (state.isSuccess) {
    print('Success: ${(state as MutationSuccess<String>).value}');
  } else if (state.hasError) {
    final err = state as MutationError<String>;
    print('Error: ${err.error}');
  }
}

// Reset mutation state (back to idle):
createUser.reset(ref);
```

### With `ProviderContainer` (e.g. in tests)

```dart
final container = ProviderContainer();
final result = await createUser.run(container, 42);
createUser.reset(container);
container.dispose();
```

## API

| Method | Description |
|--------|-------------|
| `BoundMutation(cb, {label})` | Creates a mutation with a callback `(transaction, input) -> Future<ResultT>` |
| `run(target, input)` | Executes the mutation, returning `Future<ResultT>` |
| `reset(target)` | Resets the mutation state back to `MutationIdle` |
| `source` | Returns the underlying `Mutation<ResultT>` |
| `==` / `hashCode` | Delegates to the internal `Mutation` |

`BoundMutation` implements `ProviderListenable<MutationState<ResultT>>`, so it can be watched via `ref.watch()` or `container.listen()`.
