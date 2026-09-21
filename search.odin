package main

import "core:strings"

search :: proc(f_map: map[u64]WindowsFile, query: string) -> [dynamic]u64 {
    query_lower := strings.to_lower(query)
	result_partial_search: [dynamic]u64
	for frn, file in f_map {
		if strings.contains(file.FileNameLower, query_lower) {
			append(&result_partial_search, frn)
		}
	}

	return result_partial_search
}