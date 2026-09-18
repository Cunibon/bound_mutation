# bound_mutation

A wrapper around [riverpod](https://pub.dev/packages/riverpod)'s `Mutation` that binds an input parameter to the mutation callback. Instead of capturing input at construction time, you pass it when calling `run`.

## Features

- `BoundMutation<ResultT, InputR>` — mutation with an input parameter passed to `run`
- `BoundAction<ResultT>` — mutation without input
- Keys — `deleteUser(id)` gives every id its own idle/pending/success/error state
- Full `ProviderListenable<MutationState<ResultT>>` integration — listen to idle/pending/success/error states
- Thin wrapper: delegates directly to `Mutation.run` and `Mutation.reset`

## Usage

A complete, runnable example lives in [`example/main.dart`](example/main.dart)
(`dart run example/main.dart`) — it covers `run`, error states, `reset`,
`cascade` and keys without needing Flutter.

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

### `BoundAction<ResultT>` — mutation without input

```dart
final refreshFeed = BoundAction<void>((transaction) async {
  final repo = transaction.get(feedRepositoryProvider);
  await repo.refresh();
});

await refreshFeed.run(ref);
```

### `cascade` — reusing a mutation inside another one

Call `cascade` from within another mutation's callback to reuse its logic in the
same transaction. The cascaded mutation is not run, so its state stays as it is —
only the outer mutation reports pending/success/error:

```dart
final refreshEverything = BoundAction<void>((transaction) async {
  await refreshFeed.cascade(transaction);
  await createUser.cascade(transaction, 42);
});
```

### Keys — one state per value

By default every run writes to the same state, so a single `deleteUser` mutation
cannot tell which user is currently being deleted. Calling the mutation with a
key returns an instance with a state of its own, exactly like riverpod's
`Mutation.call`:

```dart
final deleteUser = BoundMutation<void, int>((transaction, userId) async {
  await transaction.get(userRepositoryProvider).delete(userId);
});

// In a list, each row watches and runs its own key:
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(deleteUser(user.id));

  return ElevatedButton(
    onPressed: state.isPending
        ? null
        : () => deleteUser(user.id).run(ref, user.id),
    child: state.isPending ? const CircularProgressIndicator() : const Text('Delete'),
  );
}
```

The key is not derived from the input — watching and running have to pass the
same key explicitly. Keys are matched with `==`, so custom key objects should
override `==`/`hashCode`; use a record for a composite key
(`deleteUser((user.id, listId))`).

Keyed instances are independent of the unkeyed one and of each other: `run`,
`reset` and watching only ever affect the state of the key they were used with.
Two instances created from the same key compare equal, so calling `deleteUser(id)`
inline in a build method is safe.

`BoundAction` works the same way:

```dart
final state = ref.watch(syncDevice(device.id));
await syncDevice(device.id).run(ref);
```

## API

| Method | Description |
|--------|-------------|
| `BoundMutation(cb, {label})` | Creates a mutation with a callback `(transaction, input) -> Future<ResultT>` |
| `BoundMutation.run(target, input)` | Executes the mutation, returning `Future<ResultT>` |
| `BoundMutation.cascade(tsx, input)` | Runs the callback inside an existing transaction, leaving this mutation's state untouched |
| `BoundAction(cb, {label})` | Creates a mutation without input, callback `(transaction) -> Future<ResultT>` |
| `BoundAction.run(target)` | Executes the mutation, returning `Future<ResultT>` |
| `BoundAction.cascade(tsx)` | Runs the callback inside an existing transaction, leaving this mutation's state untouched |
| `bound(key)` (`call`) | Returns an instance with the same callback whose state is scoped to `key` |
| `key` | The key this instance is scoped to, or `null` if it is unkeyed |
| `reset(target)` | Resets the mutation state back to `MutationIdle` (of this key only) |
| `source` | Returns the underlying `Mutation<ResultT>` |
| `==` / `hashCode` | Delegates to the internal `Mutation` |

`BoundMutation` and `BoundAction` implement `ProviderListenable<MutationState<ResultT>>`, so they can be watched via `ref.watch()` or `container.listen()`.
