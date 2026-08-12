import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final class BoundMutation<ResultT, InputR>
    extends
        CustomProviderListenable<
          MutationState<ResultT>,
          MutationState<ResultT>
        > {
  BoundMutation(this.cb, {Object? label})
    : _mutation = Mutation<ResultT>(label: label);

  final Mutation<ResultT> _mutation;

  final Future<ResultT> Function(MutationTransaction transaction, InputR input)
  cb;

  Future<ResultT> run(MutationTarget target, InputR input) =>
      _mutation.run(target, (transaction) => cb(transaction, input));

  void reset(MutationTarget target) => _mutation.reset(target);

  @override
  ProviderListenable<MutationState<ResultT>> get source => _mutation;

  @override
  ProviderTransformer2<
    MutationState<ResultT>,
    MutationState<ResultT>,
    BoundMutation<ResultT, InputR>
  >
  createTransformer() => _BoundMutationTransformer<ResultT, InputR>();

  @override
  bool operator ==(Object other) {
    if (other is BoundMutation<ResultT, InputR>) {
      return other._mutation == _mutation;
    }
    return false;
  }

  @override
  int get hashCode => _mutation.hashCode;

  @override
  String toString() =>
      'BoundMutation<$ResultT,$InputR> | ${_mutation.toString()}';
}

final class _BoundMutationTransformer<ResultT, InputR>
    extends
        SyncProviderTransformer2<
          MutationState<ResultT>,
          MutationState<ResultT>,
          BoundMutation<ResultT, InputR>
        > {
  @override
  MutationState<ResultT> initState() => sourceState.requireValue;

  @override
  void onEvent(
    AsyncResult<MutationState<ResultT>> prev,
    AsyncResult<MutationState<ResultT>> next,
  ) {
    state = next;
  }
}
