extends Node
## Generic object pool. Nodes are recycled instead of freed to keep the
## frame time flat on mobile (no allocation spikes, no GC-like churn).

var _factories: Dictionary = {}
var _free_lists: Dictionary = {}

func register(pool_name: String, factory: Callable) -> void:
	_factories[pool_name] = factory
	if not _free_lists.has(pool_name):
		_free_lists[pool_name] = []

func acquire(pool_name: String) -> Node:
	var free_list: Array = _free_lists.get(pool_name, [])
	while free_list.size() > 0:
		var node: Node = free_list.pop_back()
		if is_instance_valid(node):
			return node
	var made: Node = _factories[pool_name].call()
	made.set_meta("pool_name", pool_name)
	return made

func release(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var pool_name: String = node.get_meta("pool_name", "")
	if pool_name == "":
		node.queue_free()
		return
	if node.get_parent():
		node.get_parent().remove_child(node)
	_free_lists[pool_name].append(node)

func clear_all() -> void:
	for key in _free_lists.keys():
		for node in _free_lists[key]:
			if is_instance_valid(node):
				node.queue_free()
		_free_lists[key] = []
