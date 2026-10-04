package main

import "core:fmt"
import "core:strings"
import "core:sync"
import rl "vendor:raylib"

COL_NAME_X :: 20
COL_DIR_X :: 400
COL_PATH_X :: 460
COL_VOL_X :: 1200
COL_INDICATOR_X :: 1260
RIGHT_PAD :: 40

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

	if rl.IsKeyPressed(.BACKSPACE) || rl.IsKeyPressedRepeat(.BACKSPACE) {
		if len(query) > 0 do pop(query)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		clear(results)
		results^ = search(files_maps, string(query[:]))
	}

	box := rl.Rectangle{20, 10, WINDOW_SIZE[0] - 40, 44}
	rl.DrawRectangleRec(box, COLOR_INPUT_BG)
	rl.DrawRectangleLinesEx(box, 1.5, COLOR_ACCENT)

	query_cstr := strings.clone_to_cstring(string(query[:]), context.temp_allocator)
	rl.DrawTextEx(
		fonts_map[FONTS_AVAIABLE.Roboto],
		query_cstr,
		{
			box.x + 14,
			box.height - rl.MeasureTextEx(fonts_map[FONTS_AVAIABLE.Roboto], query_cstr, 30, 1).y,
		},
		30,
		1,
		COLOR_TEXT,
	)

	draw_blinking_pointer(fonts_map[FONTS_AVAIABLE.Roboto], query_cstr, box)
}

draw_blinking_pointer :: proc(font: rl.Font, query: cstring, box: rl.Rectangle) {
	if int(rl.GetTime() * 2) % 2 == 0 {
		qw := rl.MeasureTextEx(font, query, 30, 1)
		cursor_x := box.x + 14 + qw.x
		rl.DrawRectangle(i32(cursor_x), i32(box.y + 12), 2, 20, COLOR_TEXT)
	}
}

draw_indicator :: proc(results: ^[dynamic]Search_Result, current_indicator_offset: int, is_dragging: ^bool) -> int {

	if len(results) == 0 do return 0
	
	track_top: f32 = 80
	track_height: f32 = (f32)(WINDOW_SIZE[1] - 80 - 20)
	
	indicator_height: f32 = max(20, track_height * (f32(30) / f32(len(results))))

	max_scroll := max(1, len(results) - 30)

	progress_now := f32(current_indicator_offset) / f32(max_scroll)
	progress_now = clamp(progress_now, 0, 1)
	indicator_y := track_top + progress_now * (track_height - indicator_height)
	indicator_rect := rl.Rectangle {
		f32(COL_INDICATOR_X + 5),
		indicator_y,
		10,
		indicator_height
	}

	mouse := rl.GetMousePosition()

	if rl.IsMouseButtonPressed(.LEFT) {
		if rl.CheckCollisionPointRec(mouse, indicator_rect) {
			is_dragging^ = true
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		is_dragging^ = false
	}

	progress: f32

	if is_dragging^ {
		progress = (mouse.y - track_top) / track_height
		progress = clamp(progress, 0, 1)
		new_scroll := int(progress * f32(max_scroll))
		
		indicator_y := track_top + progress * (track_height - indicator_height)
		rl.DrawRectangle(COL_INDICATOR_X + 5, i32(indicator_y), 10, i32(indicator_height), COLOR_TEXT)

		return new_scroll
	} else {
		progress = f32(current_indicator_offset) / f32(max_scroll)
		progress = clamp(progress, 0, 1)
		
		indicator_y := track_top + progress * (track_height - indicator_height)
		rl.DrawRectangle(COL_INDICATOR_X + 5, i32(indicator_y), 10, i32(indicator_height), COLOR_TEXT)
	}

	return current_indicator_offset
}

print_results :: proc(results: [dynamic]Search_Result, font: rl.Font, scroll_offset: int) {
	y: f32 = 90
	results_len := len(results)

	max_visible := min(results_len, 30)
	
	max_offset := max(0, len(results) - max_visible)
	scroll_offset_to_use := clamp(scroll_offset, 0, max_offset)
	
	rl.DrawTextEx(font, "Name", {COL_NAME_X, 60}, 18, 1, COLOR_TEXT)
	rl.DrawTextEx(font, "IsDir", {COL_DIR_X, 60}, 18, 1, COLOR_TEXT)
	rl.DrawTextEx(font, "Path", {COL_PATH_X, 60}, 18, 1, COLOR_TEXT)
	rl.DrawTextEx(font, "Volume", {COL_VOL_X, 60}, 18, 1, COLOR_TEXT)
	rl.DrawLineEx({COL_NAME_X, 78}, {WINDOW_SIZE[0] - COL_NAME_X, 78}, 1, COLOR_TEXT)

	start := scroll_offset_to_use
	end := min(start + max_visible, len(results))

	for i in start ..< end {
		r := results[i]

		row_rect := rl.Rectangle{20, y, COL_VOL_X, 20}
		mouse := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse, row_rect) {
			rl.DrawRectangleRec(row_rect, COLOR_HOVER)
			if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
				open_file(r.path, r.is_dir)
			}
		}

		filename_position := rl.Vector2{COL_NAME_X, y}
		type_position := rl.Vector2{COL_DIR_X, y}
		folder_position := rl.Vector2{COL_PATH_X, y}

		folder, filename := split_path(r.path)

		folder_txt := truncate(font, folder, COL_VOL_X - COL_PATH_X - RIGHT_PAD, 18, 1)
		filename_txt := truncate(font, filename, COL_DIR_X - COL_NAME_X - RIGHT_PAD, 20, 1)

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

draw_state_bar :: proc(font: rl.Font, total_files_indexed: ^int) {
	rl.DrawTextEx(
		font,
		strings.clone_to_cstring(
			fmt.tprintf(
				"%d indexed files. Click a row to open the explorer...",
				sync.atomic_load(total_files_indexed),
			),
			context.temp_allocator,
		),
		{COL_NAME_X, WINDOW_SIZE[1] - 20},
		16,
		1,
		COLOR_TEXT_DIM,
	)
}

draw_search_result_number :: proc(font: rl.Font, files_found: int) {
	rl.DrawTextEx(
		font,
		strings.clone_to_cstring(
			fmt.tprintf("%d files found", files_found),
			context.temp_allocator,
		),
		{COL_VOL_X - RIGHT_PAD * 3, WINDOW_SIZE[1] - 20},
		16,
		1,
		COLOR_TEXT,
	)
}
