import 'package:flutter/material.dart';
import 'package:listenable_tree/helpers/exceptions.dart';

import 'base/i_node.dart';
import 'base/i_node_actions.dart';

class Node<T> extends INode<T> implements INodeActions<T> {
  /// These are the children of the node.
  @override
  final Map<String, Node<T>> children;

  /// This is the uniqueKey of the [Node]
  @override
  final String key;

  /// The data contained in the node
  @override
  final T? data;

  /// This is the parent [Node]. Only the root node has a null [parent]
  @override
  Node<T>? parent;

  /// The simple Node that use a [Map] to store the [children].
  ///
  /// Default constructor that takes an optional [key] and a parent.
  /// Make sure that the provided [key] is unique to among the siblings of the node.
  /// If a [key] is not provided, then a [UniqueKey] will automatically be
  /// assigned to the [Node].
  @mustCallSuper
  Node({String? key, this.data, this.parent, Map<String, Node<T>>? children})
      : children = children ?? <String, Node<T>>{},
        key = key ?? UniqueKey().toString();

  /// Alternate factory constructor that should be used for the [root] nodes.
  factory Node.root() => Node(key: INode.rootKey);

  // factory Node.fromIterables(Iterable<T> iterable, {Node<T>? parent}) =>
  //     (parent ?? Node<T>.root())..addAll(iterable.map((e) => Node<T>(data: e)));

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  @override
  Node<T> get root => super.root as Node<T>;

  /// This returns the [children] as an iterable list.
  @override
  List<Node<T>> get childrenAsList => children.values.toList(growable: false);

  /// Add a [value] node to the [children]
  @override
  void add(Node<T> value) {
    if (children.containsKey(value.key)) throw DuplicateKeyException(value.key);
    value.parent = this;
    children[value.key] = value;
  }

  /// Add a collection of [Iterable] nodes to [children]
  @override
  void addAll(Iterable<Node<T>> iterable) {
    for (final node in iterable) {
      if (children.containsKey(node.key)) throw DuplicateKeyException(node.key);
      node.parent = this;
      children[node.key] = node;
    }
  }

  /// Clear all the child nodes from [children]. The [children] will be empty
  /// after this operation.
  @override
  void clear() {
    children.clear();
  }

  /// Remove a child [value] node from the [children]
  @override
  void remove(Node<T> value) {
    children.remove(value.key);
  }

  /// Delete [this] node
  @override
  void delete() {
    if (isRoot) throw ActionNotAllowedException.deleteRoot(this);
    (parent as Node).remove(this);
  }

  /// Remove all the [Iterable] nodes from the [children]
  @override
  void removeAll(Iterable<Node<T>> iterable) {
    for (final node in iterable) {
      children.remove(node.key);
    }
  }

  /// Remove all the child nodes from the [children] that match the criterion in
  /// the provided [test]
  @override
  void removeWhere(bool Function(Node<T> element) test) {
    children.removeWhere((key, value) => test(value));
  }

  /// Overloaded operator for [elementAt]
  @override
  Node<T> operator [](String path) => elementAt(path);

  /// * Utility method to get a child node at the [path].
  /// Get any item at [path] from the [root]
  /// The keys of the items to be traversed should be provided in the [path]
  ///
  /// For example in a TreeView like this
  ///
  /// ```dart
  /// Node get mockNode1 => Node.root()
  ///   ..addAll([
  ///     Node(key: "0A")..add(Node(key: "0A1A")),
  ///     Node(key: "0B"),
  ///     Node(key: "0C")
  ///       ..addAll([
  ///         Node(key: "0C1A"),
  ///         Node(key: "0C1B"),
  ///         Node(key: "0C1C")
  ///           ..addAll([
  ///             Node(key: "0C1C2A")
  ///               ..addAll([
  ///                 Node(key: "0C1C2A3A"),
  ///                 Node(key: "0C1C2A3B"),
  ///                 Node(key: "0C1C2A3C"),
  ///               ]),
  ///           ]),
  ///       ]),
  ///   ]);
  ///```
  ///
  /// In order to access the Node with key "0C1C", the path would be
  ///   0C.0C1C
  ///
  /// Note: The root node [rootKey] does not need to be in the path
  @override
  Node<T> elementAt(String path) {
    Node<T> currentNode = this;
    for (final nodeKey in path.splitToNodes) {
      if (nodeKey == currentNode.key) {
        continue;
      } else {
        final nextNode = currentNode.children[nodeKey];
        if (nextNode == null) {
          throw NodeNotFoundException(parentKey: path, key: nodeKey);
        }
        currentNode = nextNode;
      }
    }
    return currentNode;
  }

  @override
  String toString() => 'Node{children: $children, key: $key, parent: $parent}';
}
