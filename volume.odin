package main

import "core:fmt"
import "core:os"
import "core:strings"
import swin "core:sys/windows"

list_volumes :: proc() -> [dynamic]string {
	volumes_list: [dynamic]string

	for volume, index in POSSIBLE_VOLUMES {
		t_path := swin.utf8_to_wstring(fmt.tprintf("\\\\.\\%v:", volume))
		v_handle := swin.CreateFileW(
			t_path,
			swin.GENERIC_READ,
			swin.FILE_SHARE_WRITE | swin.FILE_SHARE_READ | swin.FILE_SHARE_DELETE,
			nil,
			swin.OPEN_EXISTING,
			swin.FILE_ATTRIBUTE_NORMAL,
			nil,
		)

		if v_handle == swin.INVALID_HANDLE_VALUE {
			o_error := swin.GetLastError()
			continue
		}

		append(&volumes_list, fmt.tprintf("%v:", volume))

		close_handle := swin.CloseHandle(v_handle)

		if !close_handle {
			c_error := swin.GetLastError()
			fmt.eprintf("It was impossible to close the handle. Error: %d", c_error)
		}
	}

	fmt.println("Volumes avaiable: ")
	for volume in volumes_list {
		fmt.println(volume)
	}

	return volumes_list
}

select_volume_path :: proc(volumes_list: ^[dynamic]string) -> (swin.wstring, string, bool) {
	fmt.println("Please, choose a volume to search into.")

	v_buf := [2048]u8{}
	v_total_read, v_err := os.read(os.stdin, v_buf[:])

	volume_to_use := strings.trim_space(string(v_buf[:v_total_read]))
	volume_exist := false

	for volume in volumes_list {
		if strings.contains(strings.to_lower(volume), strings.to_lower(volume_to_use)) {
			volume_exist = true
		}
	}

	if !volume_exist {
		fmt.eprintfln("The volume you selected is not present. %v", volume_to_use)
		return nil, "", false
	}

	path: swin.wstring
	path = swin.utf8_to_wstring(fmt.tprintf("\\\\.\\%v:", volume_to_use))
	return path, strings.clone(volume_to_use), true
}

open_volume :: proc(path: swin.wstring) -> (swin.HANDLE, bool) {
	handle := swin.CreateFileW(
		path,
		swin.GENERIC_READ,
		swin.FILE_SHARE_WRITE | swin.FILE_SHARE_READ | swin.FILE_SHARE_DELETE,
		nil,
		swin.OPEN_EXISTING,
		swin.FILE_ATTRIBUTE_NORMAL,
		nil,
	)

	fmt.printfln("handle = %v", handle)

	if handle == swin.INVALID_HANDLE_VALUE {
		o_error := swin.GetLastError()
		fmt.printfln("Error: %d", o_error)
		return nil, false
	}

	return handle, true
}