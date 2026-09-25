package main

import rl "vendor:raylib"

FONTS_AVAIABLE :: enum {
	Roboto,
	RobotoItalic,
}

COLOR_BG :: rl.Color{245, 244, 240, 255} // dirty white
COLOR_TEXT :: rl.Color{44, 44, 42, 255} // almost black
COLOR_TEXT_DIM :: rl.Color{136, 135, 128, 255} // paths
COLOR_ACCENT :: rl.Color{55, 138, 221, 255} // light blue
COLOR_VOL_C :: rl.Color{24, 95, 165, 255} // blue
COLOR_VOL_D :: rl.Color{15, 110, 86, 255} // verde
COLOR_HOVER :: rl.Color{230, 229, 223, 255} // hover row
COLOR_INPUT_BG :: rl.Color{255, 255, 255, 255} // white

load_fonts :: proc() -> map[FONTS_AVAIABLE]rl.Font {

	fonts_map := make(map[FONTS_AVAIABLE]rl.Font)

	robotoFont := rl.LoadFontEx("./fonts/Roboto-VariableFont_wdth,wght.ttf", 60, nil, 0)
	robotoItalicFont := rl.LoadFontEx(
		"./fonts/Roboto-Italic-VariableFont_wdth,wght.ttf",
		60,
		nil,
		0,
	)

	fonts_map[FONTS_AVAIABLE.Roboto] = robotoFont
	fonts_map[FONTS_AVAIABLE.RobotoItalic] = robotoItalicFont

	return fonts_map
}
