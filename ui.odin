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
	files_maps:   ^[dynamic]Indexed_Volume,
	loading_done: ^bool,
	files_indexed: ^int,
}

FONTS_AVAIABLE :: enum {
	Roboto,
	RobotoItalic,
}

WINDOW_SIZE :: rl.Vector2 { 1280, 720 }

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
		files_maps   = &files_maps,
		loading_done = &loading_done,
		files_indexed = &files_indexed,
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
			rl.DrawTextEx(fonts_map[FONTS_AVAIABLE.Roboto], query_cstr, 20, 30, 1, rl.WHITE)

			print_results(results, fonts_map[FONTS_AVAIABLE.Roboto])
		}
	}
}

print_results :: proc(results: [dynamic]Search_Result, font: rl.Font) {
	y: f32 = 60
	max_visible := min(len(results), 30)

	for i in 0 ..< max_visible {
		r := results[i]
		path_cstr := strings.clone_to_cstring(r.path, context.temp_allocator)
		position := rl.Vector2 { 20, y }
		rl.DrawTextEx(font, path_cstr, position, 18, 1, rl.WHITE)
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

		fv_map, fv_ok := get_all_files_of_volume(handle, data.files_indexed)
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

draw_loading_screen :: proc(font: rl.Font, files_indexed: ^int) {
	big_title_size := rl.MeasureTextEx(font, "HUGINN", 40, 1)
	rl.DrawTextEx(font, "HUGINN", rl.Vector2 { WINDOW_SIZE[0] / 2 - big_title_size[0] / 2, 30 }, 40, 1, rl.WHITE)

	indexing_files_text := strings.clone_to_cstring(fmt.tprintf("we are indexing your files"), context.temp_allocator)
	sub_title_size := rl.MeasureTextEx(font, indexing_files_text, 20, 1)
	rl.DrawTextEx(font, indexing_files_text, rl.Vector2 { WINDOW_SIZE[0] / 2 - sub_title_size[0] / 2, 80 }, 20, 1, rl.WHITE)

	loading_screen_animation(font)

	indexed_files_text := strings.clone_to_cstring(fmt.tprintf("%v", sync.atomic_load(files_indexed)), context.temp_allocator)
	indexed_files_text_size := rl.MeasureTextEx(font, indexed_files_text, 20, 1)
	rl.DrawTextEx(font, indexed_files_text, rl.Vector2 { WINDOW_SIZE[0] / 2 - indexed_files_text_size[0] / 2, 140 }, 20, 1, rl.WHITE)
}

loading_screen_animation :: proc(font: rl.Font) {
	dots := int(rl.GetTime() * 2) % 4 // 0,1,2,3 that cycles
	text := fmt.tprintf("%s", strings.repeat(".", dots, context.temp_allocator))
	text_cstr := strings.clone_to_cstring(text, context.temp_allocator)

	text_size := rl.MeasureTextEx(font, text_cstr, 40, 2)
	rl.DrawTextEx(font, text_cstr, rl.Vector2 { WINDOW_SIZE[0] / 2 - text_size[0] / 2, 100 }, 40, 2, rl.WHITE)
}

load_fonts :: proc() -> map[FONTS_AVAIABLE]rl.Font {

	fonts_map := make(map[FONTS_AVAIABLE]rl.Font)

	robotoFont := rl.LoadFontEx("./fonts/Roboto-VariableFont_wdth,wght.ttf", 60, nil, 0)
	robotoItalicFont := rl.LoadFontEx("./fonts/Roboto-Italic-VariableFont_wdth,wght.ttf", 60, nil, 0)

	fonts_map[FONTS_AVAIABLE.Roboto] = robotoFont
	fonts_map[FONTS_AVAIABLE.RobotoItalic] = robotoItalicFont 

	return fonts_map
}