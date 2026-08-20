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
final class BoundAction<ResultT>
    extends BoundBase<ResultT, BoundAction<ResultT>> {
  ///Creates a [BoundAction] from [_cb].
  ///
  ///[label] is forwarded to the underlying [Mutation] and only used for
  ///debugging output.
  BoundAction(this._cb, {Object? label})
    : super(Mutation<ResultT>(label: label));

  ///The bound callback.
  ///
  ///Kept private on purpose: calling it directly would bypass the mutation
  ///lifecycle without that being obvious at the call site. Use [run] to
  ///execute it as this mutation, or [cascade] to reuse it inside another
  ///mutation's transaction.
  final Future<ResultT> Function(MutationTransaction transaction) _cb;

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
  ///here.
  Future<ResultT> cascade(MutationTransaction tsx) => _cb(tsx);

  @override
  String toString() => 'BoundAction<$ResultT> | $mutation';
}
