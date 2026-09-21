package main

import "core:fmt"
import "core:strings"
import swin "core:sys/windows"
import rl "vendor:raylib"

bg: [3]u8 = {90, 95, 100}

APP_STATE :: enum {
	Loading,
	Searching,
}

start_application :: proc() {
	rl.InitWindow(720, 600, "HUGINN")
	defer rl.CloseWindow()

	state := APP_STATE.Loading
	is_loading := false

	files_maps: [dynamic]Indexed_Volume
    query: [dynamic]u8
    results: [dynamic]Search_Result

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground({bg.r, bg.g, bg.b, 255})

		switch state {
		case .Loading:
			rl.DrawText("Caricamento volumi...", 20, 20, 20, rl.WHITE)

			if is_loading {
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
                    
					append(&files_maps, idx_v)
                    close_volume(handle)
				}

                state = APP_STATE.Searching
			}

			is_loading = true
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
    y : i32 = 60
    max_visible := min(len(results), 30)

    for i in 0..<max_visible {
        r := results[i]
        path_cstr := strings.clone_to_cstring(r.path, context.temp_allocator)
        rl.DrawText(path_cstr, 20, y, 18, rl.WHITE)
        y += 20 
    }
}