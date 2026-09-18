import 'package:bound_mutation/src/bound_transformer.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';

///Shared base of `BoundMutation` and `BoundAction`.
///
///Holds the underlying [Mutation], exposes its [MutationState] as a
///[ProviderListenable] and forwards [reset] to it. Subclasses only add the
///callback and the matching `run`/`cascade` signatures.
///
///[T] is the concrete subclass and is used for the transformer, `==` and
///`hashCode`.
abstract base class BoundBase<ResultT, T extends BoundBase<ResultT, T>>
    extends
        CustomProviderListenable<
          MutationState<ResultT>,
          MutationState<ResultT>
        > {
  BoundBase(this._mutation);

  final Mutation<ResultT> _mutation;

  ///The wrapped riverpod [Mutation] that owns the state.
  ///
  ///Only visible to subclasses, so the wrapper stays the single entry point
  ///and its callback cannot be replaced by an unrelated one at the call site.
  @protected
  Mutation<ResultT> get mutation => _mutation;

  ///The key this wrapper is scoped to, or `null` if it is unkeyed.
  ///
  ///This is the value that was passed to [call].
  Object? get key => _mutation.key;

  ///Returns a wrapper with the same callback whose state is scoped to [key].
  ///
  ///By default every run writes to the same state, so a `deleteUser` mutation
  ///cannot tell which user is currently being deleted. A key gives each value
  ///a state of its own.
  ///
  ///Watching and running have to use the same key, which is matched with `==`,
  ///so custom key objects should override `==`/`hashCode`. Use a record for a
  ///composite key, e.g. `deleteUser((userId, listId))`.
  ///
  ///Keyed wrappers are independent of the unkeyed one and of each other:
  ///`run`, [reset] and watching only ever affect the state of the key they
  ///were used with. Calling this twice with the same key returns two
  ///wrappers that compare equal and therefore resolve to the same state, so
  ///it is safe to call it inline in a build method.
  T call(Object? key);

  ///Resets the state back to `MutationIdle` for [target].
  ///
  ///Use this to clear a previous result or error, e.g. when a form is closed
  ///or an error message has been acknowledged. A pending run is not cancelled
  ///by this.
  ///
  ///Only the state of this wrapper's [key] is reset, not the one of the other
  ///keys of the same mutation.
  void reset(MutationTarget target) => _mutation.reset(target);

  ///The listenable the state is read from: the wrapped [Mutation] itself.
  @override
  ProviderListenable<MutationState<ResultT>> get source => _mutation;

  ///Creates the transformer that forwards the [Mutation]'s state unchanged.
  ///
  ///This is what makes watching this object equivalent to watching the
  ///wrapped [Mutation].
  @override
  ProviderTransformer2<MutationState<ResultT>, MutationState<ResultT>, T>
  createTransformer() => BoundTransformer<ResultT, T>();

  ///Two wrappers are equal if they are of the same type [T] and wrap the same
  ///[Mutation], which includes having the same [key].
  ///
  ///The callback is deliberately not part of the comparison, so equality
  ///matches the identity of the state riverpod tracks.
  @override
  bool operator ==(Object other) => other is T && other._mutation == _mutation;

  @override
  int get hashCode => _mutation.hashCode;
}
