abstract class Tags {
  const Tags._();

  const factory Tags(String tag) = _SingleItemTags;
  const factory Tags.fromList(List<String> items) = _ListTags;

  static Tags combine2(Tags? tags1, Tags? tags2) {
    if (tags1 == null) {
      return tags2 ?? empty;
    }
    return tags2 == null ? tags1 : _ListTags([...tags1.items, ...tags2.items]);
  }

  static const empty = _ListTags([]);

  List<String> get items;

  @override
  String toString({String separator = "."}) => items.join(separator);

  Tags operator +(String? other) => other == null ? this : _ListTags([...items, other]);
}

/// A single tag. Just to be able to instantiate const objects.
class _SingleItemTags extends Tags {
  final String item;

  const _SingleItemTags(this.item) : super._();

  @override
  List<String> get items => List.unmodifiable([item]);
}

class _ListTags extends Tags {
  @override
  final List<String> items;

  const _ListTags(this.items) : super._();
}
