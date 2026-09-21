package main

import "core:strings"

search :: proc(indexed_volumes: [dynamic]Indexed_Volume, query: string) -> [dynamic]Search_Result {
    query_lower := strings.to_lower(query)
	results: [dynamic]Search_Result
	for &idx_v in indexed_volumes {
        for frn, file in idx_v.files {
            if strings.contains(file.FileNameLower, query_lower) {
                f_path := build_path(idx_v.files, frn, idx_v.letter)
                append(&results, Search_Result { frn = frn, path = strings.clone(f_path), idx_v = &idx_v})
            }
        }
	}

	return results
}