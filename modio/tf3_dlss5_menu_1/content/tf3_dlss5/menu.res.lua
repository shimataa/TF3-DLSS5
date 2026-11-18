-- Registers the TF3-DLSS5 menu as a plugin of the mod button area (top left of the screen).
function data()
	return {
		type = "react-plugin ::MainModButtonAreaExtension",
		data = {
			filePath = "tf3_dlss5_menu_1::/tf3_dlss5/menu.script@Tf3Dlss5Menu",
			order = 71,
		},
	}
end
