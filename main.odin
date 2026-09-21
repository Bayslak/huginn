package main

import "core:fmt"
import "core:os"
import "core:strings"
import swin "core:sys/windows"

main :: proc() {
	//fmt.printfln("size = %d", size_of(USN_RECORD_V2))

	volumes_list := list_volumes()
	path, volume_to_use, v_ok := select_volume_path(&volumes_list)
	if !v_ok {
		// we already print error in the procedure
		return
	}

	handle, h_ok := open_volume(path)
	if !h_ok {
		// we already print error in the procedure
		return
	}

	defer {
		close_handle := swin.CloseHandle(handle)

		if !close_handle {
			c_error := swin.GetLastError()
			fmt.eprintf("It was impossible to close the handle. Error: %d", c_error)
		}
	}

	f_map, map_ok := get_all_files_of_volume(handle)
	if !map_ok {
		// we already print error in the procedure
		return
	}

	// ask for what its needed to be searched
	buf := [2048]u8{}
	fmt.println("What are you looking for?")
	total_read, err := os.read(os.stdin, buf[:])

	file_to_look_for := strings.trim_space(string(buf[:total_read]))
	query_lower := strings.to_lower(file_to_look_for)

	files_found := search(f_map, query_lower)

	for frn in files_found {
		path := build_path(f_map, frn, volume_to_use)
		fmt.printfln("Path: %v", path)
	}

	start_ui()
}