import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';

final class BoundMutation<ResultT, InputR>
    with
        SyncProviderTransformerMixin<
          MutationState<ResultT>,
          MutationState<ResultT>
        >
    implements ProviderListenable<MutationState<ResultT>> {
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
  ProviderTransformer<MutationState<ResultT>, MutationState<ResultT>> transform(
    ProviderTransformerContext<MutationState<ResultT>, MutationState<ResultT>>
    context,
  ) {
    return ProviderTransformer(
      initState: (self) => context.sourceState.requireValue,
      listener: (self, prev, next) {
        self.state = next;
      },
    );
  }

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
