import 'package:bound_mutation/src/bound_base.dart';
import 'package:riverpod/experimental/mutation.dart';

final class BoundMutation<ResultT, InputR>
    extends BoundBase<ResultT, BoundMutation<ResultT, InputR>> {
  BoundMutation(this.cb, {Object? label})
    : super(Mutation<ResultT>(label: label));

  final Future<ResultT> Function(MutationTransaction transaction, InputR input)
  cb;

  Future<ResultT> run(MutationTarget target, InputR input) =>
      mutation.run(target, (transaction) => cb(transaction, input));

  @override
  String toString() => 'BoundMutation<$ResultT,$InputR> | $mutation';
}
