package main

import "core:fmt"
import "core:strings"
import swin "core:sys/windows"

FSCTL_ENUM_USN_DATA :: 0x000900b3

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

    mft := MFT_ENUM_DATA {
        StartFileReferenceNumber = 0,
        LowUsn = 0,
        HighUsn = max(i64)
    }

    buff: [64 * 1024]u8 //64KB
    n_b_produced: u32

    res := swin.DeviceIoControl(handle, FSCTL_ENUM_USN_DATA, &mft, size_of(mft), &buff[0], len(buff), &n_b_produced, nil)

    if !res {
        r_error := swin.GetLastError()
        fmt.eprintfln("It was impossible to index files. Error: %d", r_error)
    }

    fmt.printfln("Bytes produced: %d", n_b_produced)
	fmt.printfln("End")
}

MFT_ENUM_DATA :: struct {
    StartFileReferenceNumber: swin.DWORDLONG,
    LowUsn: i64,
    HighUsn: i64,
}
