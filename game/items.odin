package karl2d_game

import k2 "../../karl2d"
import hm "core:/container/handle_map"

Item_Handle :: distinct hm.Handle32
itemEntities: hm.Dynamic_Handle_Map(ItemData, Item_Handle)

ItemData :: struct {
	handle: Item_Handle,
	x, y:   f32,
	prefab: ItemPrefab,
}

add_item_from_prefabs :: proc(x, y: f32, prefab: ItemPrefab) -> Maybe(Item_Handle) {
	handle: Maybe(Item_Handle)
	#partial switch prefab {
	case .SWORD_GOLD:
		handle = add_item(x, y, .SWORD_GOLD)
	case .WORN_PICKAXE:
		handle = add_item(x, y, .WORN_PICKAXE)
	case:
		warnf("Item: Attempted to spawn unknown item prefab %v", prefab)
		return nil
	}
	return handle
}

add_item :: proc(x, y: f32, prefab: ItemPrefab) -> Maybe(Item_Handle) {
	item := hm.add(&itemEntities, ItemData{x = x, y = y, prefab = prefab})
	item_entity := hm.get(&itemEntities, item)
	debugf(
		"Item: Added item (handle: %v, x: %v, y: %v, prefab: %v)",
		item,
		item_entity.x,
		item_entity.y,
		item_entity.prefab,
	)
	return item
}

remove_item :: proc(handle: Item_Handle) -> bool {
	if ok, err := hm.remove(&itemEntities, handle); err != nil {
		debugf("Item: Removed item (handle: %v)", handle)
		return true
	} else {
		warnf("Item: Failed to remove item (handle: %v): %v", handle, err)
		return false
	}
}

get_item_at_location :: proc(x, y: f32) -> Maybe(Item_Handle) {
	it := hm.iterator_make(&itemEntities)
	for item, item_handle in hm.iterate(&it) {
		if _, does := k2.rect_overlap({x, y, 16, 16}, {item.x, item.y, 16, 16}); does {
			return item_handle
		}
	}
	return nil
}

flush_all_items :: proc() {
	hm.clear(&itemEntities)
}
