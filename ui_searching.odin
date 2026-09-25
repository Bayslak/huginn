package main

import "core:fmt"
import "core:strings"
import "core:sync"
import rl "vendor:raylib"

draw_search_screen :: proc(query: ^[dynamic]u8, results: ^[dynamic]Search_Result, files_maps: [dynamic]Indexed_Volume, fonts_map: map[FONTS_AVAIABLE]rl.Font) {
	for {
		c := rl.GetCharPressed()
		if c == 0 do break
		append(query, u8(c))
	}

	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		pop(query)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		clear(results)
		results^ = search(files_maps, string(query[:]))
	}

	query_cstr := strings.clone_to_cstring(string(query[:]), context.temp_allocator)
	rl.DrawTextEx(fonts_map[FONTS_AVAIABLE.Roboto], query_cstr, 20, 30, 1, COLOR_TEXT)
}

print_results :: proc(results: [dynamic]Search_Result, font: rl.Font) {
	y: f32 = 60
	max_visible := min(len(results), 30)

	for i in 0 ..< max_visible {
		r := results[i]

		row_rect := rl.Rectangle{20, y, 1240, 20} // x, y, width, height
		mouse := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse, row_rect) {
			rl.DrawRectangleRec(row_rect, COLOR_HOVER)
			if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
				open_file(r.path, r.is_dir)
			}
		}

		folder, filename := split_path(r.path)
		filename_position := rl.Vector2{20, y}
		type_position := rl.Vector2{400, y}
		folder_position := rl.Vector2{440, y}
		rl.DrawTextEx(
			font,
			strings.clone_to_cstring(filename, context.temp_allocator),
			filename_position,
			20,
			1,
			COLOR_TEXT,
		)

		if r.is_dir {
			rl.DrawTextEx(
				font,
				strings.clone_to_cstring("[dir]", context.temp_allocator),
				type_position,
				18,
				1,
				COLOR_TEXT,
			)
		}

		rl.DrawTextEx(
			font,
			strings.clone_to_cstring(folder, context.temp_allocator),
			folder_position,
			18,
			1,
			COLOR_TEXT_DIM,
		)
		y += 20
	}
}

split_path :: proc(path: string) -> (folder: string, filename: string) {
	filename_idx := strings.last_index(path, "\\")

	if filename_idx < 0 {
		return "", path // no folders, it means that the path is the name of the file
	}

	folder = path[:filename_idx]
	filename = path[filename_idx + 1:]

	return folder, filename
}
