package main

import swin "core:sys/windows"

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
}