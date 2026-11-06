extension type const CharacterId._(int _value) implements Object {
  const CharacterId.fromInt(int value) : this._(value);

  factory CharacterId.fromWire(int value) => CharacterId._(value);

  int get toWire => _value;
}
