import 'package:bound_mutation/src/bound_base.dart';
import 'package:riverpod/experimental/mutation.dart';

///A riverpod [Mutation] bound to a callback that takes an input of type
///[InputR].
///
///The input is not captured when the mutation is created but passed on every
///[run], so a single instance can be reused for every value, e.g. one
///`deleteUser` mutation for all user ids. If the callback needs no input, use
///`BoundAction` instead.
///
///Watching this object (`ref.watch`) yields the [MutationState] of the
///underlying [Mutation], so the idle/pending/success/error states can be used
///in the UI without holding on to the [Mutation] itself.
final class BoundMutation<ResultT, InputR>
    extends BoundBase<ResultT, BoundMutation<ResultT, InputR>> {
  ///Creates a [BoundMutation] from [_cb].
  ///
  ///[label] is forwarded to the underlying [Mutation] and only used for
  ///debugging output.
  BoundMutation(this._cb, {Object? label})
    : super(Mutation<ResultT>(label: label));

  ///The bound callback.
  ///
  ///Kept private on purpose: calling it directly would bypass the mutation
  ///lifecycle without that being obvious at the call site. Use [run] to
  ///execute it as this mutation, or [cascade] to reuse it inside another
  ///mutation's transaction.
  final Future<ResultT> Function(MutationTransaction transaction, InputR input)
  _cb;

  ///Executes the bound callback as this mutation, with [input].
  ///
  ///[target] is the [MutationTarget] the mutation state is scoped to, e.g. a
  ///`Ref`, a `WidgetRef` or a `ProviderContainer`.
  ///
  ///This drives the full lifecycle: the state moves to pending, then to
  ///success with the returned value or to error if the callback throws.
  ///Errors are still rethrown to the caller.
  ///
  ///Note that all runs share the same state, no matter which [input] they were
  ///given, so a second run overwrites the state of the first one.
  Future<ResultT> run(MutationTarget target, InputR input) =>
      mutation.run(target, (transaction) => _cb(transaction, input));

  ///Executes the bound callback with [input] inside an already running [tsx],
  ///without going through this mutation.
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
  Future<ResultT> cascade(MutationTransaction tsx, InputR input) =>
      _cb(tsx, input);

  @override
  String toString() => 'BoundMutation<$ResultT,$InputR> | $mutation';
}
