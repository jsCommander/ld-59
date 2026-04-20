class_name Groups extends RefCounted


# --- Untyped ---

static func get_all(tree: SceneTree, group: String) -> Array[Node]:
	return tree.get_nodes_in_group(group)


static func get_first(tree: SceneTree, group: String) -> Node:
	var nodes: Array[Node] = tree.get_nodes_in_group(group)
	if nodes.is_empty():
		return null
	return nodes[0]


static func get_all_filtered(tree: SceneTree, group: String, filter: Callable) -> Array:
	var result: Array = []
	for node: Node in tree.get_nodes_in_group(group):
		if filter.call(node):
			result.append(node)
	return result


static func get_first_filtered(tree: SceneTree, group: String, filter: Callable) -> Node:
	for node: Node in tree.get_nodes_in_group(group):
		if filter.call(node):
			return node
	return null


# --- Typed ---

static func get_all_of_type(tree: SceneTree, group: String, type: Variant) -> Array:
	var result: Array = []
	for node: Node in tree.get_nodes_in_group(group):
		if is_instance_of(node, type):
			result.append(node)
	return result


static func get_first_of_type(tree: SceneTree, group: String, type: Variant) -> Node:
	for node: Node in tree.get_nodes_in_group(group):
		if is_instance_of(node, type):
			return node
	return null


static func get_all_of_type_filtered(tree: SceneTree, group: String, type: Variant, filter: Callable) -> Array:
	var result: Array = []
	for node: Node in tree.get_nodes_in_group(group):
		if is_instance_of(node, type) and filter.call(node):
			result.append(node)
	return result


static func get_first_of_type_filtered(tree: SceneTree, group: String, type: Variant, filter: Callable) -> Node:
	for node: Node in tree.get_nodes_in_group(group):
		if is_instance_of(node, type) and filter.call(node):
			return node
	return null
