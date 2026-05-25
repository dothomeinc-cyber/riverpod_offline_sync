import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueExtension<T> on AsyncValue<T> {
  T? get valueOrNull {
    return maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
  }

  bool get isLoading => this is AsyncLoading<T>;

  bool get hasError => this is AsyncError<T>;

  Object? get errorValue {
    return maybeWhen(
      error: (error, stack) => error,
      orElse: () => null,
    );
  }

  T get requireData {
    return maybeWhen(
      data: (value) => value,
      orElse: () => throw StateError('No data available'),
    );
  }
}
