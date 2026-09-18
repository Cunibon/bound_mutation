import 'package:bound_mutation/bound_mutation.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart';

///A tiny in-memory store, standing in for a repository or an API client.
class TodoRepository {
  final _todos = <String>[];

  List<String> get todos => List.unmodifiable(_todos);

  Future<String> add(String title) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (title.isEmpty) throw ArgumentError('title must not be empty');
    _todos.add(title);
    return title;
  }

  Future<void> remove(String title) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _todos.remove(title);
  }

  Future<void> clear() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _todos.clear();
  }
}

final todoRepositoryProvider = Provider((ref) => TodoRepository());

///A `BoundMutation` takes its input on every `run`, so this single instance
///covers every title instead of one mutation per todo.
final addTodo = BoundMutation<String, String>((transaction, title) async {
  final repository = transaction.get(todoRepositoryProvider);
  return repository.add(title);
}, label: 'addTodo');

///A `BoundAction` is the same thing for a callback that needs no input.
final clearTodos = BoundAction<void>((transaction) async {
  final repository = transaction.get(todoRepositoryProvider);
  await repository.clear();
}, label: 'clearTodos');

///`cascade` reuses the callbacks of the two mutations above inside this one's
///transaction, so their logic is not duplicated. Since they are not run, their
///own state stays untouched — only `resetTodos` reports pending/success/error.
final resetTodos = BoundAction<void>((transaction) async {
  await clearTodos.cascade(transaction);
  await addTodo.cascade(transaction, 'Buy milk');
}, label: 'resetTodos');

///Keys give one mutation a state per value. Without one, removing two todos
///at once would share a single pending/success/error state.
final removeTodo = BoundMutation<void, String>((transaction, title) async {
  final repository = transaction.get(todoRepositoryProvider);
  await repository.remove(title);
}, label: 'removeTodo');

Future<void> main() async {
  final container = ProviderContainer();

  //Watching a BoundMutation yields the MutationState of the wrapped Mutation.
  container.listen<MutationState<String>>(addTodo, (previous, next) {
    print('addTodo    -> ${describe(next)}');
  }, fireImmediately: true);

  container.listen<MutationState<void>>(resetTodos, (previous, next) {
    print('resetTodos -> ${describe(next)}');
  }, fireImmediately: true);

  print('\n--- run: idle -> pending -> success ---');
  final title = await addTodo.run(container, 'Walk the dog');
  print(
    'returned "$title", todos: ${container.read(todoRepositoryProvider).todos}',
  );

  print('\n--- a failing run: the error is recorded and rethrown ---');
  try {
    await addTodo.run(container, '');
  } on ArgumentError catch (error) {
    print('caught ${error.message}');
  }

  print('\n--- reset: back to idle ---');
  addTodo.reset(container);

  print('\n--- cascade: both callbacks run in one transaction ---');
  await resetTodos.run(container);
  print('todos: ${container.read(todoRepositoryProvider).todos}');
  //addTodo ran as part of resetTodos, but only via cascade, so it is still idle.
  print('addTodo is still ${describe(container.read(addTodo))}');

  print('\n--- keys: one state per todo ---');
  //Both keys are watched, but only the one that is run reports progress.
  for (final title in ['Buy milk', 'Walk the dog']) {
    container.listen<MutationState<void>>(removeTodo(title), (previous, next) {
      print('removeTodo($title) -> ${describe(next)}');
    }, fireImmediately: true);
  }
  //The key is passed explicitly, next to the input: they are not the same
  //thing, even when they happen to hold the same value.
  await removeTodo('Buy milk').run(container, 'Buy milk');
  print('todos: ${container.read(todoRepositoryProvider).todos}');
  //The unkeyed mutation has a state of its own and stays idle as well.
  print('removeTodo (unkeyed) is ${describe(container.read(removeTodo))}');

  container.dispose();
}

String describe(MutationState<Object?> state) => switch (state) {
  MutationIdle() => 'idle',
  MutationPending() => 'pending',
  MutationError(:final error) => 'error($error)',
  MutationSuccess(:final value) => 'success($value)',
};
