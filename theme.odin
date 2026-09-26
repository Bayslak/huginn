package main

import rl "vendor:raylib"

FONTS_AVAIABLE :: enum {
	Roboto,
	RobotoItalic,
}

COLOR_BG :: rl.Color{22, 26, 34, 255} // dark deep blue
COLOR_SURFACE :: rl.Color{30, 35, 45, 255} // surface slightly lighter
COLOR_TEXT :: rl.Color{232, 234, 237, 255} // warm white
COLOR_TEXT_DIM :: rl.Color{138, 145, 158, 255} // grey-blue
COLOR_ACCENT :: rl.Color{56, 138, 221, 255} // strong blue
COLOR_VOL_C :: rl.Color{96, 165, 250, 255} // light blue
COLOR_VOL_D :: rl.Color{250, 204, 21, 255} // yellow-amber
COLOR_HOVER :: rl.Color{38, 44, 56, 255} // slightly ligther than bg
COLOR_INPUT_BG :: rl.Color{30, 35, 45, 255} // search bar

load_fonts :: proc() -> map[FONTS_AVAIABLE]rl.Font {

	fonts_map := make(map[FONTS_AVAIABLE]rl.Font)

	robotoFont := rl.LoadFontEx("./fonts/Roboto-VariableFont_wdth,wght.ttf", 40, nil, 0)
	rl.SetTextureFilter(robotoFont.texture, rl.TextureFilter.BILINEAR)
	robotoItalicFont := rl.LoadFontEx(
		"./fonts/Roboto-Italic-VariableFont_wdth,wght.ttf",
		40,
		nil,
		0,
	)
	rl.SetTextureFilter(robotoItalicFont.texture, rl.TextureFilter.BILINEAR)


	fonts_map[FONTS_AVAIABLE.Roboto] = robotoFont
	fonts_map[FONTS_AVAIABLE.RobotoItalic] = robotoItalicFont

	return fonts_map
}
