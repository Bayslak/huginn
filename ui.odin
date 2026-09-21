package main

import rl "vendor:raylib"

bg: [3]u8 = {90, 95, 100}

start_ui :: proc() {
    rl.InitWindow(720, 600, "HUGINN")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground({bg.r, bg.g, bg.b, 255})

		rl.DrawText("Huginn pronto.", 20, 20, 20, rl.WHITE)

		rl.EndDrawing()
	}
}