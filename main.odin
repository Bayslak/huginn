package main

import "core:fmt"
import "core:os"
import "core:strings"
import swin "core:sys/windows"
import unicode "core:unicode/utf16"
import rl "vendor:raylib"

FSCTL_ENUM_USN_DATA :: 0x000900b3
POSSIBLE_VOLUMES :: enum {
	A,
	B,
	C,
	D,
	E,
	F,
	G,
	H,
	I,
	L,
	M,
	N,
	O,
	P,
	Q,
	R,
	S,
	T,
	U,
	V,
	Z,
}

bg : [3]u8 = { 90, 95, 100 }

main :: proc() {
	//fmt.printfln("size = %d", size_of(USN_RECORD_V2))

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
		fmt.eprintln("The volume you selected is not present.")
		return
	}

	path: swin.wstring
	path = swin.utf8_to_wstring(fmt.tprintf("\\\\.\\%v:", volume_to_use))

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
		LowUsn                   = 0,
		HighUsn                  = max(i64),
	}

	buff: [64 * 1024]u8 //64KB
	n_b_produced: u32
	current_start_file_reference_number: swin.DWORDLONG
	current_low_usn: i64
	more_to_read := true
	files_found := 0

	f_map := make(map[u64]WindowsFile) // add allocator

	for more_to_read {
		mft.StartFileReferenceNumber = current_start_file_reference_number

		res := swin.DeviceIoControl(
			handle,
			FSCTL_ENUM_USN_DATA,
			&mft,
			size_of(mft),
			&buff[0],
			len(buff),
			&n_b_produced,
			nil,
		)

		if !res {
			r_error := swin.GetLastError()
			//fmt.eprintfln("It was impossible to index files. Error: %d", r_error)
			more_to_read = false
			continue
		}

		next_start := (^u64)(&buff[0])^
		//fmt.printfln("StartFileReferenceNumber: %v", next_start)
		current_start_file_reference_number = next_start

		//fmt.printfln("Bytes produced: %d", n_b_produced)

		offset: u32 = 8

		for offset < n_b_produced {
			rec := (^USN_RECORD_V2)(&buff[offset])
			//fmt.printfln("Record length: %d", rec.RecordLength)
			//fmt.printfln("File name length: %d", rec.FileNameLength)

			// name position is 8 + FileNameOffset
			// I have to take the bytes from 8 + FileNameOffset to FileNameLenght / 2 as []u16
			sliced_buffer := ([^]u16)(&buff[(offset) + u32(rec.FileNameOffset)])
			sliced_name := sliced_buffer[:rec.FileNameLength / 2]

			name_buff: [512]u8
			n_b := unicode.decode_to_utf8(name_buff[:], sliced_name)
			name := string(name_buff[:n_b])

			//fmt.printfln("Name found: %v", name)

			offset += rec.RecordLength

			files_found += 1

			f_map[rec.FileReferenceNumber] = WindowsFile {
				ParentFileReferenceNumber = rec.ParentFileReferenceNumber,
				FileName                  = strings.clone(name),
				FileNameLower             = strings.clone(strings.to_lower(name)),
			}
		}
	}

	fmt.printfln("%v files found.", files_found)
	fmt.printfln("%v map dimension.", len(f_map))

	//for frn, file in f_map {
	//	fmt.printfln("Testing frn %v (%v)", frn, file.FileName)
	//	path := build_path(f_map, frn, "C:")
	//	fmt.printfln("Path: %v", path)
	//	break
	//}

	// ask for what its needed to be searched
	buf := [2048]u8{}
	fmt.println("What are you looking for?")
	total_read, err := os.read(os.stdin, buf[:])

	file_to_look_for := strings.trim_space(string(buf[:total_read]))
	query_lower := strings.to_lower(file_to_look_for)

	result_partial_search: [dynamic]u64
	for frn, file in f_map {
		if strings.contains(file.FileNameLower, query_lower) {
			append(&result_partial_search, frn)
		}
	}

	for frn in result_partial_search {
		path := build_path(f_map, frn, volume_to_use)
		fmt.printfln("Path: %v", path)
	}

	// raylib
	rl.InitWindow(720, 600, "HUGINN")
	defer rl.CloseWindow()

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground({ bg.r, bg.g, bg.b, 255 })
		
		rl.DrawText("Huginn pronto.", 20, 20, 20, rl.WHITE)

		rl.EndDrawing()
	}
}

MFT_ENUM_DATA :: struct {
	StartFileReferenceNumber: swin.DWORDLONG,
	LowUsn:                   i64,
	HighUsn:                  i64,
}

USN_RECORD_V2 :: struct #packed {
	RecordLength:              swin.DWORD,
	MajorVersion:              swin.WORD,
	MinorVersion:              swin.WORD,
	FileReferenceNumber:       swin.DWORDLONG,
	ParentFileReferenceNumber: swin.DWORDLONG,
	Usn:                       i64,
	TimeStamp:                 swin.LARGE_INTEGER,
	Reason:                    swin.DWORD,
	SourceInfo:                swin.DWORD,
	SecurityId:                swin.DWORD,
	FileAttributes:            swin.DWORD,
	FileNameLength:            swin.WORD,
	FileNameOffset:            swin.WORD,
}

WindowsFile :: struct {
	FileName:                  string,
	FileNameLower:             string,
	ParentFileReferenceNumber: u64,
}

build_path :: proc(files: map[u64]WindowsFile, frn: u64, volume: string) -> string {
	p_builder: strings.Builder
	strings.builder_init(&p_builder)

	file, ok := files[frn]

	if !ok {
		fmt.eprintfln("There are no files with the file reference number: %v", frn)
		return "NOT_EXISTING"
	}

	path_files: [dynamic]string

	append(&path_files, file.FileName)

	keep_looking := true
	pfrn := file.ParentFileReferenceNumber

	for keep_looking {
		pfile, pf_ok := files[pfrn]

		if !pf_ok {
			keep_looking = false
			continue
		}

		if pfile.ParentFileReferenceNumber == pfrn {
			keep_looking = false
			continue
		}

		append(&path_files, pfile.FileName)
		pfrn = pfile.ParentFileReferenceNumber
	}

	append(&path_files, fmt.tprintf("%v:", volume))

	first := true
	#reverse for pf, n in path_files {
		if !first {
			strings.write_string(&p_builder, "\\")
		}

		strings.write_string(&p_builder, pf)
		if first {first = false}
	}

	return strings.to_string(p_builder)
}
