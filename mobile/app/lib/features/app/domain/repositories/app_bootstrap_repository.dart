abstract interface class AppBootstrapRepository {
  /// Starts process bootstrap. Later calls return the same future.
  Future<void> start();
}
