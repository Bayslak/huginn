package main

import "core:fmt"
import "core:sync"
import swin "core:sys/windows"
import "core:thread"
import rl "vendor:raylib"

HUGINN_LOGO := #load("../assets/huginn_logo.png")

APP_STATE :: enum {
	Loading,
	Searching,
}

WINDOW_SIZE :: rl.Vector2{1280, 720}

start_application :: proc() {
	rl.InitWindow(auto_cast WINDOW_SIZE[0], auto_cast WINDOW_SIZE[1], "HUGINN")
	icon := rl.LoadImageFromMemory(".png", raw_data(HUGINN_LOGO), i32(len(HUGINN_LOGO)))
	rl.SetWindowIcon(icon)
	rl.UnloadImage(icon)

	defer rl.CloseWindow()

	fonts_map := load_fonts()

	state := APP_STATE.Loading

	loading_done := false
	loading_worker_started := false
	files_indexed := 0
	total_files_indexed := 0

	files_maps: [dynamic]Indexed_Volume
	query: [dynamic]u8
	results: [dynamic]Search_Result

	loading_thread_data := Load_Context {
		files_maps    = &files_maps,
		loading_done  = &loading_done,
		files_indexed = &files_indexed,
		total_files_indexed = &total_files_indexed
	}

	scroll_offset := 0
	is_dragging := false

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
			wheel := rl.GetMouseWheelMove()
			if wheel != 0 {
				scroll_offset -= int(wheel) // going negative means we are growing the offset
			}

			if len(results) > 0 && len(results) > 30 {
				scroll_offset = draw_indicator(&results, scroll_offset, &is_dragging)
				max_scroll := max(0, len(results) - 30)
				scroll_offset = clamp(scroll_offset, 0, max_scroll)
			}

			draw_search_screen(&query, &results, files_maps, fonts_map)
			print_results(results, fonts_map[FONTS_AVAIABLE.Roboto], scroll_offset)
			draw_state_bar(fonts_map[FONTS_AVAIABLE.RobotoItalic], &total_files_indexed)
			draw_search_result_number(fonts_map[FONTS_AVAIABLE.Roboto], len(results))
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