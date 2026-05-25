class RetryStrategy {
  final int maxRetries;
  final Duration initialDelay;
  final bool shouldRetryOnTimeout;
  final bool shouldRetryOnServerError;
  final bool shouldRetryOnNetworkError;
  final List<int> retryableStatusCodes;

  const RetryStrategy({
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 2),
    this.shouldRetryOnTimeout = true,
    this.shouldRetryOnServerError = true,
    this.shouldRetryOnNetworkError = true,
    this.retryableStatusCodes = const [
      408,
      429,
      500,
      502,
      503,
      504
    ],
  });

  bool shouldRetry(
      int retryCount, Object? error, int? statusCode) {
    if (retryCount >= maxRetries) return false;

    if (error != null) {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('timeout') &&
          !shouldRetryOnTimeout) {
        return false;
      }
      if (errorStr.contains('network') &&
          !shouldRetryOnNetworkError) {
        return false;
      }
      if (errorStr.contains('socket') &&
          !shouldRetryOnNetworkError) {
        return false;
      }
    }

    if (statusCode != null) {
      if (statusCode >= 500 && shouldRetryOnServerError) {
        return true;
      }
      if (retryableStatusCodes.contains(statusCode)) {
        return true;
      }
      if (statusCode >= 400 && statusCode < 500) {
        return false;
      }
    }

    return true;
  }

  Duration getDelay(int retryCount) {
    final multiplier = [1, 2, 4, 8, 16, 32, 60];
    final index = retryCount < multiplier.length
        ? retryCount
        : multiplier.length - 1;
    return Duration(
        seconds:
            multiplier[index] * initialDelay.inSeconds);
  }

  factory RetryStrategy.aggressive() => const RetryStrategy(
        maxRetries: 10,
        initialDelay: Duration(seconds: 1),
      );

  factory RetryStrategy.conservative() =>
      const RetryStrategy(
        maxRetries: 3,
        initialDelay: Duration(seconds: 5),
      );

  factory RetryStrategy.noRetry() => const RetryStrategy(
        maxRetries: 0,
      );
}
