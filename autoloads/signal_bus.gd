class_name SignalBus extends BaseSignalBus

signal entity_selected(target: Node2D, popup_position: Vector2)
signal selection_cleared
signal product_produced(product: ProductData)
signal build_requested(slot: Slot, building_data: BuildingData)
signal demolish_requested(building: Building)
