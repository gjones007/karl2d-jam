package karl2d_game

import hm "core:/container/handle_map"

Inventory_Handle :: distinct hm.Handle32

@(private = "file")
inventoryEntities: hm.Dynamic_Handle_Map(InventoryData, Inventory_Handle)

InventoryData :: struct {
	handle: Inventory_Handle,
	items:  [dynamic]ItemPrefab,
}

flush_all_inventories :: proc() {
	hm.clear(&inventoryEntities)
}

add_inventory :: proc() -> Inventory_Handle {
	handle := hm.add(&inventoryEntities, InventoryData{})
	debugf("INVENTORY: Created inventory with handle %v", handle)
	return handle
}

add_inventory_item :: proc(
	inventory: Inventory_Handle,
	itemPrefab: ItemPrefab,
	quantity: int = 1,
) -> int {
	inventory := hm.get(&inventoryEntities, inventory)
	added := 0

	for i in 0 ..< len(inventory.items) {
		if inventory.items[i] == .NONE {
			tracef(
				"INVENTORY: Adding item %v to inventory %v at index %d",
				itemPrefab,
				inventory.handle,
				i,
			)
			inventory.items[i] = itemPrefab
			added += 1

			if added == quantity {
				return quantity
			}
		}
	}

	return added
}

remove_inventory_item :: proc(
	inventory: Inventory_Handle,
	itemPrefab: ItemPrefab,
	quantity: int,
) -> int {
	inventory := hm.get(&inventoryEntities, inventory)
	removed := 0

	for i in 0 ..< len(inventory.items) {
		if inventory.items[i] == itemPrefab {
			tracef(
				"INVENTORY: Removing item %v from inventory %v at index %d",
				itemPrefab,
				inventory.handle,
				i,
			)
			inventory.items[i] = .NONE
			removed += 1

			if removed == quantity {
				return quantity
			}
		}
	}

	return removed
}
