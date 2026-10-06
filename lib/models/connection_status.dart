/// What the last check of the SwarVed server found.
enum ConnectionStatus {
  unknown,
  checking,
  connected,
  badToken,
  unreachable,
  unexpected,
}
