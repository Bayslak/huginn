package main

import "core:fmt"
import "core:strings"
import "core:sync"
import rl "vendor:raylib"

draw_loading_screen :: proc(font: rl.Font, files_indexed: ^int) {
	big_title_size := rl.MeasureTextEx(font, "HUGINN", 40, 1)
	rl.DrawTextEx(
		font,
		"HUGINN",
		rl.Vector2{WINDOW_SIZE[0] / 2 - big_title_size[0] / 2, 30},
		40,
		1,
		COLOR_TEXT,
	)

	indexing_files_text := strings.clone_to_cstring(
		fmt.tprintf("we are indexing your files"),
		context.temp_allocator,
	)
	sub_title_size := rl.MeasureTextEx(font, indexing_files_text, 20, 1)
	rl.DrawTextEx(
		font,
		indexing_files_text,
		rl.Vector2{WINDOW_SIZE[0] / 2 - sub_title_size[0] / 2, 80},
		20,
		1,
		COLOR_TEXT_DIM,
	)

	loading_screen_animation(font)

	indexed_files_text := strings.clone_to_cstring(
		fmt.tprintf("%v", sync.atomic_load(files_indexed)),
		context.temp_allocator,
	)
	indexed_files_text_size := rl.MeasureTextEx(font, indexed_files_text, 20, 1)
	rl.DrawTextEx(
		font,
		indexed_files_text,
		rl.Vector2{WINDOW_SIZE[0] / 2 - indexed_files_text_size[0] / 2, 140},
		20,
		1,
		COLOR_TEXT_DIM,
	)
}

loading_screen_animation :: proc(font: rl.Font) {
	dots := int(rl.GetTime() * 2) % 4 // 0,1,2,3 that cycles
	text := fmt.tprintf("%s", strings.repeat(".", dots, context.temp_allocator))
	text_cstr := strings.clone_to_cstring(text, context.temp_allocator)

	text_size := rl.MeasureTextEx(font, text_cstr, 40, 2)
	rl.DrawTextEx(
		font,
		text_cstr,
		rl.Vector2{WINDOW_SIZE[0] / 2 - text_size[0] / 2, 100},
		40,
		2,
		COLOR_TEXT_DIM,
	)
}