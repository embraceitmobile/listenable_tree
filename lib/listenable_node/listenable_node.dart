import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:listenable_tree/helpers/event_stream_controller.dart';
import 'package:listenable_tree/helpers/exceptions.dart';
import 'package:listenable_tree/node/base/i_node.dart';
import 'package:listenable_tree/node/node.dart';

import 'base/i_listenable_node.dart';

class ListenableNode<T> extends Node<T>
    with ChangeNotifier
    implements IListenableNode<T> {
  /// A listenable implementation the [Node].
  /// The mutations to the [Node] can be listened to using the [ValueListenable]
  /// interface or the [addedNodes] and [removedNodes] streams.
  ///
  /// The [ListenableNode] can also be used with a [ValueListenableBuilder]
  /// for updating the UI whenever the [Node] is mutated.
  ///
  /// Default constructor that takes an optional [key] and a parent.
  /// Make sure that the provided [key] is unique to among the siblings of the node.
  /// If a [key] is not provided, then a [UniqueKey] will automatically be
  /// assigned to the [Node].
  ListenableNode({String? key, Node<T>? parent})
      : super(key: key, parent: parent);

  /// Alternate factory constructor for [ListenableNode] that should be used for
  /// the [root] nodes.
  factory ListenableNode.root() => ListenableNode(key: INode.rootKey);

  /// This is the parent [ListenableNode]. Only the root node has a null [parent]
  @override
  ListenableNode<T>? parent;

  /// Getter to get the [value] of the [ValueListenable]. It returns the [root]
  @override
  T get value => this as T;

  /// Getter to get the [root] node.
  /// If the current node is not a [root], then the getter will traverse up the
  /// path to get the [root].
  @override
  ListenableNode<T> get root => super.root as ListenableNode<T>;

  /// This returns the [children] as an iterable list.
  @override
  List<ListenableNode<T>> get childrenAsList =>
      List<ListenableNode<T>>.from(super.childrenAsList);

  final EventStreamController<NodeAddEvent<T>> _addedNodes =
      EventStreamController();

  final EventStreamController<NodeRemoveEvent<T>> _removedNodes =
      EventStreamController();

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is added to the current node.
  ///
  /// The stream should only be listened to on the [root] node.
  /// [ActionNotAllowedException] if a non-root tries to listen the [addedNodes]
  @override
  Stream<NodeAddEvent<T>> get addedNodes {
    if (!isRoot) throw ActionNotAllowedException.listener(this);
    return _addedNodes.stream;
  }

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is removed from the current node.
  ///
  /// The stream should only be listened to on the [root] node.
  /// [ActionNotAllowedException] if a non-root tries to listen the [removedNodes]
  @override
  Stream<NodeRemoveEvent<T>> get removedNodes {
    if (!isRoot) throw ActionNotAllowedException.listener(this);
    return _removedNodes.stream;
  }

  /// The insertNodes stream is not allowed for the ListenableNode.
  /// The index based operations like 'insert' are not implemented in ListenableNode
  @override
  Stream<NodeInsertEvent<T>> get insertedNodes =>
      throw ActionNotAllowedException(
          this,
          "The insertNodes stream is not allowed"
          "for the ListenableNode. The index based operations like 'insert' are "
          "not implemented in ListenableNode");

  /// Add a [value] node to the [children]
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  @override
  void add(Node<T> value) {
    super.add(value);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List<T>.from([value])));
  }

  /// Add a collection of [Iterable] nodes to [this] node
  ///
  /// The [ValueListenable] and [addedNodes] listeners will also be notified
  /// on this operation
  @override
  void addAll(Iterable<Node<T>> iterable) {
    super.addAll(iterable);
    _notifyListeners();
    _notifyNodesAdded(NodeAddEvent(List<T>.from(iterable)));
  }

  /// Remove a child [value] node from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  @override
  void remove(Node<T> value) {
    super.remove(value);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List<T>.from([value])));
  }

  /// Delete [this] node
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  @override
  void delete() {
    final nodeToRemove = this;
    super.delete();
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List<T>.from([nodeToRemove])));
  }

  /// Remove all the [Iterable] nodes from the [children]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  @override
  void removeAll(Iterable<Node<T>> iterable) {
    super.removeAll(iterable);
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List<T>.from(iterable)));
  }

  /// Remove all the child nodes from the [children] that match the criterion in
  /// the provided [test]
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  @override
  void removeWhere(bool Function(Node<T> element) test) {
    final allChildren = childrenAsList.toSet();
    super.removeWhere(test);
    _notifyListeners();
    final remainingChildren = childrenAsList.toSet();
    allChildren.removeAll(remainingChildren);

    if (allChildren.isNotEmpty) {
      _notifyNodesRemoved(NodeRemoveEvent(List<T>.from(allChildren)));
    }
  }

  /// Clear all the child nodes from [children]. The [children] will be empty
  /// after this operation.
  ///
  /// The [ValueListenable] and [removedNodes] listeners will also be notified
  /// on this operation
  @override
  void clear() {
    final clearedNodes = childrenAsList;
    super.clear();
    _notifyListeners();
    _notifyNodesRemoved(NodeRemoveEvent(List<T>.from(clearedNodes)));
  }

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
  ListenableNode<T> elementAt(String path) =>
      super.elementAt(path) as ListenableNode<T>;

  /// Overloaded operator for [elementAt]
  @override
  ListenableNode<T> operator [](String path) => elementAt(path);

  /// Disposer to clear the listeners and [StreamSubscription]s
  @override
  void dispose() {
    _addedNodes.close();
    _removedNodes.close();
    super.dispose();
  }

  void _notifyListeners() {
    notifyListeners();
    if (!isRoot) parent!._notifyListeners();
  }

  void _notifyNodesAdded(NodeAddEvent<T> event) {
    if (isRoot) {
      _addedNodes.emit(event);
    } else {
      root._notifyNodesAdded(event);
    }
  }

  void _notifyNodesRemoved(NodeRemoveEvent<T> event) {
    if (isRoot) {
      _removedNodes.emit(event);
    } else {
      root._notifyNodesRemoved(event);
    }
  }
}
