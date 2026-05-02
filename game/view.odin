package karl2d_game

// import "core:log"
// import "core:fmt"
import "core:container/queue"

View :: struct {
	Open:    proc(),
	Close:   proc(),
	Control: proc(),
	Render:  proc(),
}

activeViews: queue.Queue(^View)

push_view :: push_view_back

push_view_front :: proc(view: ^View) {
	queue.push_front(&activeViews, view)
	view.Open()
}

push_view_back :: proc(view: ^View) {
	queue.push_back(&activeViews, view)
	view.Open()
}

pop_view :: proc(from := #caller_location) {
	// fmt.println("Pop called " , from, " #", activeViews.len)
	if activeViews.len == 0 do return
	queue.back_ptr(&activeViews)^.Close()
	queue.pop_back(&activeViews)
}

pop_all_views :: proc() {
	for queue.len(activeViews) > 0 {
		pop_view()
	}
}

set_view :: proc(view: ^View) {
	if queue.len(activeViews) > 0 {
		pop_all_views()
	}

	push_view_back(view)
}

is_view_open :: proc(view: ^View) -> bool {
	for i in 0 ..< activeViews.len {
		if queue.get(&activeViews, i) == view {
			return true
		}
	}
	return false

}

count_views :: proc() -> uint {
	return activeViews.len
}

control_views :: proc() {
	if activeViews.len == 0 do return

	// Front-to-back control: topmost view first, then views underneath it.
	i := int(activeViews.len) - 1
	for i > -1 {
		if activeViews.len == 0 do break

		// Views may pop/push during Control; clamp index to current bounds.
		if i >= int(activeViews.len) {
			i = int(activeViews.len) - 1
			continue
		}

		view := queue.get(&activeViews, i)
		if view.Control != nil {
			view.Control()
		}
		i -= 1
	}
}

render_views :: proc() {
	// Back-to-front render: background views first, topmost overlays last.
	for i := 0; i < int(activeViews.len); i += 1 {
		if queue.get(&activeViews, i).Render != nil {
			queue.get(&activeViews, i).Render()
		}
	}
}
