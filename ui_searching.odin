package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

COL_NAME_X :: 20
COL_DIR_X :: 340
COL_PATH_X :: 400
COL_VOL_X :: 1240
RIGHT_PAD :: 60

volume_color :: proc(letter: string) -> rl.Color {
	switch letter {
	case "C:":
		return COLOR_VOL_C
	case "D:":
		return COLOR_VOL_D
	case:
		return COLOR_TEXT_DIM
	}
}

draw_search_screen :: proc(
	query: ^[dynamic]u8,
	results: ^[dynamic]Search_Result,
	files_maps: [dynamic]Indexed_Volume,
	fonts_map: map[FONTS_AVAIABLE]rl.Font,
) {
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

		filename_position := rl.Vector2{20, y}
		type_position := rl.Vector2{400, y}
		folder_position := rl.Vector2{440, y}

		folder, filename := split_path(r.path)

		folder_txt := truncate(font, folder, COL_VOL_X - COL_PATH_X - RIGHT_PAD, 18, 1)
		filename_txt := truncate(
			font,
			filename,
			WINDOW_SIZE[0] - (folder_position[0] + type_position[0] + filename_position[0]),
			20,
			1,
		)

		rl.DrawTextEx(
			font,
			strings.clone_to_cstring(filename_txt, context.temp_allocator),
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
			strings.clone_to_cstring(folder_txt, context.temp_allocator),
			folder_position,
			18,
			1,
			COLOR_TEXT_DIM,
		)

		vol_text := fmt.tprintf("%v", r.idx_v.letter)
		vol_cstr := strings.clone_to_cstring(vol_text, context.temp_allocator)
		rl.DrawTextEx(font, vol_cstr, {COL_VOL_X, y}, 18, 1, volume_color(r.idx_v.letter))

		y += 20
	}
}

split_path :: proc(path: string) -> (folder: string, filename: string) {
    volume_idx := strings.index(path, "\\")
	filename_idx := strings.last_index(path, "\\")

	if filename_idx < 0 {
		return "", path // no folders, it means that the path is the name of the file
	}

	folder = path[volume_idx:filename_idx]
	filename = path[filename_idx + 1:]

	return folder, filename
}

truncate :: proc(font: rl.Font, text: string, max_width: f32, size, spacing: f32) -> string {
	full := strings.clone_to_cstring(text, context.temp_allocator)
	if rl.MeasureTextEx(font, full, size, spacing).x <= max_width {
		return text
	}

	for end := len(text); end > 0; end -= 1 {
		candidate := fmt.tprintf("%s...", text[:end])
		cand_cstr := strings.clone_to_cstring(candidate, context.temp_allocator)
		if rl.MeasureTextEx(font, cand_cstr, size, spacing).x <= max_width {
			return candidate
		}
	}

	return "..."
}
