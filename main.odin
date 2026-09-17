package main

import "core:fmt"
import "core:strings"
import swin "core:sys/windows"

main :: proc() {
	fmt.println("Helloooo")

	path: swin.wstring
	path = swin.utf8_to_wstring("\\\\.\\C:")

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
		return
	}

	defer {
		close_handle := swin.CloseHandle(handle)

		if !close_handle {
			c_error := swin.GetLastError()
			fmt.eprintf("It was impossible to close the handle. Error: %d", c_error)
		}
	}

	fmt.printfln("End")
}
