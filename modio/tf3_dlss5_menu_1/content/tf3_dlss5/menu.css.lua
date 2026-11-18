-- The D5 button matches the other buttons of the mod button area (a 32 x 32 toggle with a 24 x 24
-- icon, margins 1, 1, 2, 1); the settings row next to it uses the same height. Only this mod's own
-- classes are selected.
local ssu = require("::/gui/main/stylesheetutil.lua")

function data()
	local result = {}
	local add = ssu.makeAdder(result)
	add("ToggleButton!tf3dlss5-toggle", {
		size = { 32, 32 }, minSize = { 32, 32 }, maxSize = { 32, 32 },
		padding = { 4, 4, 4, 4 }, margin = { 1, 1, 2, 1 }, gravity = { 0.5, 0.5 },
	})
	add("ToggleButton!tf3dlss5-toggle ImageView!tf3dlss5-icon", {
		size = { 24, 24 }, minSize = { 24, 24 }, maxSize = { 24, 24 }, gravity = { 0.5, 0.5 },
	})
	add("Button!tf3dlss5-btn", {
		minSize = { 32, 32 }, maxSize = { 400, 32 },
		padding = { 4, 8, 4, 8 }, margin = { 1, 1, 2, 1 }, gravity = { 0.5, 0.5 },
	})
	add("TextView!tf3dlss5-value", {
		minSize = { 28, 32 }, maxSize = { 60, 32 },
		padding = { 4, 2, 4, 2 }, margin = { 1, 1, 2, 1 }, gravity = { 0.5, 0.5 },
	})
	add("TextView!tf3dlss5-hint", {
		minSize = { 28, 32 }, maxSize = { 900, 32 },
		padding = { 4, 6, 4, 6 }, margin = { 1, 1, 2, 1 }, gravity = { 0.5, 0.5 },
	})
	return result
end
