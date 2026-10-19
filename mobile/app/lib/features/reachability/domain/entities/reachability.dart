enum Reachability {
  online,
  offline;

  bool get isOnline => this == .online;
  bool get isOffline => this == .offline;
}
