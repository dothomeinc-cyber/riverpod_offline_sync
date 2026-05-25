class BackoffCalculator {
  static Duration calculateNextRetry(int retryCount) {
    final seconds = [1, 2, 4, 8, 16, 32, 60];
    final index = retryCount < seconds.length
        ? retryCount
        : seconds.length - 1;
    return Duration(seconds: seconds[index]);
  }

  static bool shouldRetry(int retryCount, int maxRetries) {
    return retryCount < maxRetries;
  }

  static int getRetryDelaySeconds(int retryCount) {
    final seconds = [1, 2, 4, 8, 16, 32, 60];
    final index = retryCount < seconds.length
        ? retryCount
        : seconds.length - 1;
    return seconds[index];
  }
}
