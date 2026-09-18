import 'package:bound_mutation/src/bound_base.dart';
import 'package:riverpod/experimental/mutation.dart';

///A riverpod [Mutation] bound to a callback that takes no input.
///
///Use this for side effects that need no arguments, e.g. refreshing a feed or
///signing the current user out. If the callback needs an argument, use
///`BoundMutation` instead.
///
///Watching this object (`ref.watch`) yields the [MutationState] of the
///underlying [Mutation], so the idle/pending/success/error states can be used
///in the UI without holding on to the [Mutation] itself.
///
///All runs share one state. Use [call] to get a state per key instead, e.g.
///one per row of a list that each refresh themselves.
final class BoundAction<ResultT>
    extends BoundBase<ResultT, BoundAction<ResultT>> {
  ///Creates a [BoundAction] from [_cb].
  ///
  ///[label] is forwarded to the underlying [Mutation] and only used for
  ///debugging output.
  BoundAction(this._cb, {Object? label})
    : super(Mutation<ResultT>(label: label));

  ///Creates a [BoundAction] that reuses [_cb] with an already keyed
  ///[Mutation]. See [call].
  BoundAction._(this._cb, Mutation<ResultT> mutation) : super(mutation);

  ///The bound callback.
  ///
  ///Kept private on purpose: calling it directly would bypass the mutation
  ///lifecycle without that being obvious at the call site. Use [run] to
  ///execute it as this mutation, or [cascade] to reuse it inside another
  ///mutation's transaction.
  final Future<ResultT> Function(MutationTransaction transaction) _cb;

  ///Returns a [BoundAction] with the same callback whose state is scoped to
  ///[key].
  ///
  ///Without a key all runs share one state, so the same action triggered from
  ///two places cannot be told apart. A key gives each of them a state of its
  ///own:
  ///
  ///```dart
  ///final state = ref.watch(syncDevice(device.id));
  ///...
  ///await syncDevice(device.id).run(ref);
  ///```
  ///
  ///Watching and running have to pass the same key, which is matched with
  ///`==`, so custom key objects should override `==`/`hashCode`. Use a record
  ///for a composite key, e.g. `syncDevice((device.id, userId))`.
  ///
  ///Keyed instances are independent of the unkeyed one and of each other:
  ///[run], [reset] and watching only ever affect the state of the key they
  ///were used with. Calling this twice with the same key returns two
  ///instances that compare equal and therefore resolve to the same state, so
  ///it is safe to call it inline in a build method.
  @override
  BoundAction<ResultT> call(Object? key) =>
      BoundAction._(_cb, mutation.call<ResultT>(key));

  ///Executes the bound callback as this mutation.
  ///
  ///[target] is the [MutationTarget] the mutation state is scoped to, e.g. a
  ///`Ref`, a `WidgetRef` or a `ProviderContainer`.
  ///
  ///This drives the full lifecycle: the state moves to pending, then to
  ///success with the returned value or to error if the callback throws.
  ///Errors are still rethrown to the caller.
  Future<ResultT> run(MutationTarget target) =>
      mutation.run(target, (transaction) => _cb(transaction));

  ///Executes the bound callback inside an already running [tsx], without
  ///going through this mutation.
  ///
  ///Use this to reuse the logic of one mutation inside another instead of
  ///duplicating it: the outer mutation calls [cascade] from within its own
  ///callback, so everything runs in a single transaction.
  ///
  ///Because this mutation is never run, its state does not change at all: no
  ///pending/success/error transitions are emitted and anything watching this
  ///object sees nothing. Only the mutation that started [tsx] reports
  ///progress, and a thrown error propagates to it rather than being recorded
  ///here. Keys are therefore irrelevant here.
  Future<ResultT> cascade(MutationTransaction tsx) => _cb(tsx);

  @override
  String toString() => 'BoundAction<$ResultT> | $mutation';
}
