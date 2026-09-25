package main

import "core:fmt"
import "core:strings"
import "core:sync"
import swin "core:sys/windows"
import "core:thread"
import rl "vendor:raylib"

APP_STATE :: enum {
	Loading,
	Searching,
}

WINDOW_SIZE :: rl.Vector2{1280, 720}

start_application :: proc() {
	rl.InitWindow(auto_cast WINDOW_SIZE[0], auto_cast WINDOW_SIZE[1], "HUGINN")
	defer rl.CloseWindow()

	fonts_map := load_fonts()

	state := APP_STATE.Loading

	loading_done := false
	loading_worker_started := false
	files_indexed := 0

	files_maps: [dynamic]Indexed_Volume
	query: [dynamic]u8
	results: [dynamic]Search_Result

	loading_thread_data := Load_Context {
		files_maps    = &files_maps,
		loading_done  = &loading_done,
		files_indexed = &files_indexed,
	}

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(COLOR_BG)

		switch state {
		case .Loading:
			if !loading_worker_started {
				thread.create_and_start_with_poly_data(&loading_thread_data, load_all_files_thread)
				loading_worker_started = true
			}

			draw_loading_screen(fonts_map[FONTS_AVAIABLE.Roboto], &files_indexed)
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
			rl.DrawTextEx(fonts_map[FONTS_AVAIABLE.Roboto], query_cstr, 20, 30, 1, COLOR_TEXT)

			print_results(results, fonts_map[FONTS_AVAIABLE.Roboto])
		}
	}
}

open_file :: proc(path: string, is_dir: bool) {
	if is_dir {
		swin.ShellExecuteW(
			nil,
			swin.utf8_to_wstring("open"),
			swin.utf8_to_wstring(path),
			nil,
			nil,
			swin.SW_NORMAL,
		)
	} else {
		args := fmt.tprintf("/select,%v", path)
		swin.ShellExecuteW(
			nil,
			swin.utf8_to_wstring("open"),
			swin.utf8_to_wstring("explorer.exe"),
			swin.utf8_to_wstring(args),
			nil,
			swin.SW_SHOWNORMAL,
		)
	}
}

