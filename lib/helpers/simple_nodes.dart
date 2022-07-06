import 'package:listenable_tree/listenable_tree.dart';

class SimpleNode extends ListenableNode {
  /// A [SimpleNode] that can be used with the [TreeView].
  ///
  /// To use your own custom data with [TreeView], extend the [ListenableNode]
  /// like this:
  /// ```dart
  ///   class YourCustomNode extends ListenableNode {
  ///   ...
  ///   }
  /// ```
  SimpleNode([String? key]) : super(key: key);
}

class SimpleIndexedNode extends ListenableIndexedNode {
  /// A [SimpleIndexedNode] that can be used with the [IndexedTreeView].
  ///
  /// To use your own custom data with [IndexedTreeView], extend the [ListenableIndexedNode]
  /// like this:
  /// ```dart
  ///   class YourCustomIndexedNode extends ListenableIndexedNode {
  ///   ...
  ///   }
  /// ```
  SimpleIndexedNode([String? key]) : super(key: key);
}
