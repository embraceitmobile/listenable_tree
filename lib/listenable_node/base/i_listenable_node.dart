import 'package:flutter/foundation.dart';
import 'package:listenable_tree/node/base/i_node.dart';

/// The base class for implementing a Listenable Node. It allows for the listener
/// to observe any changes in the Node.
///
/// The [IListenableNode] also implements the [ValueListenable], so it can be
/// used with a [ValueListenableBuilder] for updating the UI whenever the node
/// is mutated.
abstract class IListenableNode extends INode
    implements NodeUpdateNotifier, ValueListenable<INode> {}

/// This class provides more granular over which updates to listen to.
abstract class NodeUpdateNotifier {
  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is added to the current node.
  /// It returns a stream of [NodeAddEvent]
  Stream<NodeAddEvent> get addedNodes;

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is inserted in the current node.
  /// It returns a stream of [insertedNodes]
  Stream<NodeInsertEvent> get insertedNodes;

  /// Listen to this [Stream] to get updates on when a Node or a collection of
  /// Nodes is removed from the current node.
  /// It returns a stream of [NodeRemoveEvent]
  Stream<NodeRemoveEvent> get removedNodes;

  void dispose();
}

mixin NodeEvent {}

class NodeAddEvent with NodeEvent {
  final List items;

  const NodeAddEvent(this.items);

  @override
  String toString() {
    return 'NodeAddEvent{items: $items}';
  }
}

class NodeRemoveEvent with NodeEvent {
  final List items;

  const NodeRemoveEvent(this.items);

  @override
  String toString() {
    return 'NodeRemoveEvent{keys: $items}';
  }
}

class NodeInsertEvent with NodeEvent {
  final List items;
  final int index;

  const NodeInsertEvent(this.items, this.index);

  @override
  String toString() {
    return 'NodeInsertEvent{items: $items, index: $index}';
  }
}
