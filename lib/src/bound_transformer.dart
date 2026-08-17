import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final class BoundTransformer<
  ResultT,
  T extends CustomProviderListenable<
    MutationState<ResultT>,
    MutationState<ResultT>
  >
>
    extends
        SyncProviderTransformer2<
          MutationState<ResultT>,
          MutationState<ResultT>,
          T
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
