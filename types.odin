package main

import swin "core:sys/windows"
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
	is_directory: bool,
}

Indexed_Volume :: struct {
	letter: string,
	files:  map[u64]WindowsFile,
}

Search_Result :: struct {
	frn:   u64,
	path:  string,
	is_dir: bool,
	idx_v: ^Indexed_Volume,
}

COLOR_BG :: rl.Color{245, 244, 240, 255} // dirty white
COLOR_TEXT :: rl.Color{44, 44, 42, 255} // almost black
COLOR_TEXT_DIM :: rl.Color{136, 135, 128, 255} // paths
COLOR_ACCENT :: rl.Color{55, 138, 221, 255} // light blue
COLOR_VOL_D :: rl.Color{15, 110, 86, 255} // green
COLOR_HOVER :: rl.Color{230, 229, 223, 255} // hover row 
