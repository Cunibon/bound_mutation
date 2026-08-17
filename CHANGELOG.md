## 2.1.0

- Adds `BoundAction<ResultT>` — a mutation without input
- `BoundMutation<ResultT, InputR>` keeps its required input; both share the same
  `ProviderListenable<MutationState<ResultT>>` integration

## 2.0.0

- migrate to `CustomProviderListenable`/`SyncProviderTransformer2`, replacing the
  `SyncProviderTransformerMixin`, `ProviderTransformer` and
  `ProviderTransformerContext` APIs deprecated in riverpod 3.4.0
- **Breaking:** requires riverpod `^3.4.0` (was `^3.0.0`)
- **Breaking:** requires Dart SDK `^3.12.0` (was `^3.8.0`), as mandated by
  riverpod 3.4.0

`BoundMutation` still implements `ProviderListenable<MutationState<ResultT>>`, so
`ref.watch`, `container.listen`, `run` and `reset` are unchanged.

## 1.0.3

- remove flutter dependency

## 1.0.2

- switch to riverpod from flutter_riverpod

## 1.0.1

- relax dependencies

## 1.0.0

- Inital release
  - Adds BoundMutation
  