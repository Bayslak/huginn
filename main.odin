package main

import "core:fmt"
import "core:os"
import "core:strings"
import swin "core:sys/windows"

main :: proc() {
	start_application()

	// ask for what its needed to be searched
	//buf := [2048]u8{}
	//fmt.println("What are you looking for?")
	//total_read, err := os.read(os.stdin, buf[:])

	//file_to_look_for := strings.trim_space(string(buf[:total_read]))
	//files_found := search(f_map, file_to_look_for)

	//for frn in files_found {
	//	path := build_path(f_map, frn, volume_to_use)
	//	fmt.printfln("Path: %v", path)
	//}
}