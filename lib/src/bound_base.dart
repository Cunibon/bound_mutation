import 'package:bound_mutation/src/bound_transformer.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';

abstract base class BoundBase<ResultT, T extends BoundBase<ResultT, T>>
    extends
        CustomProviderListenable<
          MutationState<ResultT>,
          MutationState<ResultT>
        > {
  BoundBase(this._mutation);

  final Mutation<ResultT> _mutation;

  @protected
  Mutation<ResultT> get mutation => _mutation;

  void reset(MutationTarget target) => _mutation.reset(target);

  @override
  ProviderListenable<MutationState<ResultT>> get source => _mutation;

  @override
  ProviderTransformer2<MutationState<ResultT>, MutationState<ResultT>, T>
  createTransformer() => BoundTransformer<ResultT, T>();

  @override
  bool operator ==(Object other) => other is T && other._mutation == _mutation;

  @override
  int get hashCode => _mutation.hashCode;
}
