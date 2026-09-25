package main

import "core:fmt"
import "core:strings"
import "core:sync"
import unicode "core:unicode/utf16"
import swin "core:sys/windows"

Load_Context :: struct {
	files_maps:    ^[dynamic]Indexed_Volume,
	loading_done:  ^bool,
	files_indexed: ^int,
}

get_all_files_of_volume :: proc(handle: swin.HANDLE, files_indexed: ^int) -> (map[u64]WindowsFile, bool) {
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
				is_directory			  = (rec.FileAttributes & swin.FILE_ATTRIBUTE_DIRECTORY) != 0,
			}

			sync.atomic_store(files_indexed, files_found)
		}
	}

	fmt.printfln("%v files found.", files_found)
	fmt.printfln("%v map dimension.", len(f_map))

	return f_map, true
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

	append(&path_files, fmt.tprintf("%v", volume))

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