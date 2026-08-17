import 'package:bound_mutation/src/bound_base.dart';
import 'package:riverpod/experimental/mutation.dart';

final class BoundAction<ResultT>
    extends BoundBase<ResultT, BoundAction<ResultT>> {
  BoundAction(this.cb, {Object? label})
    : super(Mutation<ResultT>(label: label));

  final Future<ResultT> Function(MutationTransaction transaction) cb;

  Future<ResultT> run(MutationTarget target) =>
      mutation.run(target, (transaction) => cb(transaction));

  @override
  String toString() => 'BoundAction<$ResultT> | $mutation';
}
