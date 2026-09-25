package main

import "core:fmt"
import "core:strings"
import "core:sync"
import swin "core:sys/windows"
import "core:thread"
import rl "vendor:raylib"

bg: [3]u8 = {90, 95, 100}

APP_STATE :: enum {
	Loading,
	Searching,
}

Load_Context :: struct {
	files_maps: ^[dynamic]Indexed_Volume,
	loading_done: ^bool,
}

start_application :: proc() {
	rl.InitWindow(720, 600, "HUGINN")
	defer rl.CloseWindow()

	state := APP_STATE.Loading

	loading_done := false
	loading_worker_started := false

	files_maps: [dynamic]Indexed_Volume
	query: [dynamic]u8
	results: [dynamic]Search_Result

	loading_thread_data := Load_Context {
		files_maps = &files_maps,
		loading_done = &loading_done,
	}

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground({bg.r, bg.g, bg.b, 255})

		switch state {
		case .Loading:
			if !loading_worker_started {
				thread.create_and_start_with_poly_data(&loading_thread_data, load_all_files_thread)
				loading_worker_started = true
			}

			loading_screen_animation()
			if sync.atomic_load(&loading_done) {
				state = APP_STATE.Searching
			}
		case .Searching:
			for {
				c := rl.GetCharPressed()
				if c == 0 do break
				append(&query, u8(c))
			}

			if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
				pop(&query)
			}

			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				clear(&results)
				results = search(files_maps, string(query[:]))
			}

			query_cstr := strings.clone_to_cstring(string(query[:]), context.temp_allocator)
			rl.DrawText(query_cstr, 20, 20, 20, rl.WHITE)

			print_results(results)
		}
	}
}

print_results :: proc(results: [dynamic]Search_Result) {
	y: i32 = 60
	max_visible := min(len(results), 30)

	for i in 0 ..< max_visible {
		r := results[i]
		path_cstr := strings.clone_to_cstring(r.path, context.temp_allocator)
		rl.DrawText(path_cstr, 20, y, 18, rl.WHITE)
		y += 20
	}
}

load_all_files_thread :: proc(data: ^Load_Context) {
	volumes_list := list_volumes()
	for volume in volumes_list {
		path: swin.wstring
		path = swin.utf8_to_wstring(fmt.tprintf("\\\\.\\%v", volume))

		handle, h_ok := open_volume(path)
		if !h_ok {
			fmt.eprintfln("It was impossible to load files on volume %v", volume)
			continue
		}

		fv_map, fv_ok := get_all_files_of_volume(handle)
		if !fv_ok {
			fmt.eprintfln("It was impossible to get files on volume %v", volume)
			continue
		}

		idx_v := Indexed_Volume {
			letter = strings.clone(volume),
			files  = fv_map,
		}

		append(data.files_maps, idx_v)
		close_volume(handle)
	}

	sync.atomic_store(data.loading_done, true)
}

loading_screen_animation :: proc() {
	dots := int(rl.GetTime() * 2) % 4 // 0,1,2,3 that cycles
	text := fmt.tprintf("Caricamento%s", strings.repeat(".", dots, context.temp_allocator))
	text_cstr := strings.clone_to_cstring(text, context.temp_allocator)
	rl.DrawText(text_cstr, 20, 20, 20, rl.WHITE)
}