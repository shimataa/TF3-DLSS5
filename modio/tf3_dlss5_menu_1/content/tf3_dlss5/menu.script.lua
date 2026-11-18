--- TF3-DLSS5: a D5 button in the mod button area (top left, next to the Layers button) that
-- opens a row of settings for the TF3-DLSS5 Windows add-on: upscaler on/off, DLSS 5 on/off, sharpness
-- and the info box. The add-on itself ships in this mod's "Windows add-on" folder; mods can't install
-- it, so the player copies it next to TransportFever3.exe once (the "Install add-on" button opens
-- that folder).
--
-- This mod is Lua only. It can't call the add-on (a Vulkan layer that runs inside the game's
-- process), so each change is printed as one line to the game log (crash_dump/stdout.txt):
--
--     [tf3_dlss5] set dlss5=0
--
-- The add-on follows the log, applies the change within a second, saves it in its tf3_dlss.cfg and
-- shows its info box for a few seconds as a confirmation. Without the add-on (or on a console) the
-- lines go nowhere and nothing happens.
--
-- Values shown: read from TF3-DLSS/tf3_dlss.cfg when the game lets Lua read files, otherwise the
-- add-on's defaults, then whatever was last chosen here.
--
-- A recipe error would drop the whole game UI, so everything runs in pcall and failures are logged.
-- The button structure follows the Transit Overlay mod (MIT, Axel Ferb), which proved it in TF3.
-- @module tf3_dlss5.menu
local react = require("::/gui/main/react.lua")
local builtin = require("::/gui/main/builtin.lua")

local MOD_REVISION = 1 -- keep equal to "revision" in mod.json
local ICON = "tf3_dlss5_menu_1::/tf3_dlss5/icon.tga"
local TAG = "[tf3_dlss5] "
local ADDON_SUBDIR = "Windows add-on"
local TOOLTIP = "TF3-DLSS5: DLSS / DLSS 5 settings"
	.. "\nNeeds the TF3-DLSS5 Windows add-on, copied once next to TransportFever3.exe. Without it these buttons do nothing."
	.. "\nEach change shows the add-on's info box for a few seconds when it has been applied."

local function log(msg)
	local p = debugPrint or print
	pcall(p, TAG .. tostring(msg))
end

-- The settings, shared by every render of the recipe for the whole session.
local settings = { enabled = 1, dlss5 = 1, sharpness = 0.3, overlay = 0 }
local loaded = false -- tf3_dlss.cfg read (or tried)
local addon = nil -- true: the add-on's tf3_dlss.cfg was found; false: not found; nil: Lua can't read files
local saidHello = false

-- Reads the add-on's current settings when the game's Lua allows reading files. Silent otherwise.
local function load_settings()
	if loaded then return end
	loaded = true
	local ok, err = pcall(function()
		if type(io) ~= "table" or type(io.open) ~= "function" then return end
		addon = false
		for _, path in ipairs({ "TF3-DLSS/tf3_dlss.cfg", "./TF3-DLSS/tf3_dlss.cfg" }) do
			local f = io.open(path, "r")
			if f then
				for line in f:lines() do
					local k, v = line:match("^%s*([%w_]+)%s*=%s*([^#%s]+)")
					local n = tonumber(v)
					if k and n and settings[k] ~= nil then settings[k] = n end
				end
				f:close()
				addon = true
				log("settings read from " .. path)
				return
			end
		end
	end)
	if not ok then log("could not read the settings: " .. tostring(err)) end
	if addon == false then log("add-on not found next to the game (TF3-DLSS/tf3_dlss.cfg)") end
end

-- This mod's folder on disk, or nil: from this script's own path, else from the mod hub.
local function mod_root()
	local found
	pcall(function()
		local src = string.gsub(string.gsub(debug.getinfo(1, "S").source, "^@", ""), "\\", "/")
		found = string.match(src, "^(%a:/.-)/content/tf3_dlss5/menu%.script%.lua$")
			or string.match(src, "^(/.-)/content/tf3_dlss5/menu%.script%.lua$")
	end)
	if found then return found end
	pcall(function()
		local modId = api.type.mod.ModId.new()
		modId.name = "tf3_dlss5_menu_1"
		local source = app.getUserProfile():getModRep():getModSource(modId)
		local backend = api.modhub.getBackendIdForSource(source)
		local p = api.modhub.getModInstallInfo(backend, api.modhub.getModHubModIdForModId(modId)).installPath
		if type(p) == "string" and p ~= "" then found = string.gsub(string.gsub(p, "\\", "/"), "/+$", "") end
	end)
	return found
end

-- Opens the "Windows add-on" folder of this mod in the file explorer. Logs its path either way.
local function open_addon_folder()
	local root = mod_root()
	if not root then
		log("install: this mod's folder was not found; it is in the game's mods folder, " .. ADDON_SUBDIR)
		return
	end
	local folder = root .. "/" .. ADDON_SUBDIR
	if string.match(folder, "^%a:/") then folder = string.gsub(folder, "/", "\\") end
	local opened = pcall(function() api.modhub.openPath(folder) end)
	log("install: " .. (opened and "opened " or "please open ") .. folder)
end

local INSTALL_TIP = "Install the Windows add-on (once):"
	.. "\n1. Click here: the add-on's folder opens. Copy everything in it (Ctrl+A, Ctrl+C)."
	.. "\n2. In Steam: right-click Transport Fever 3 > Manage > Browse local files."
	.. "\n3. Paste (Ctrl+V) next to TransportFever3.exe, then restart the game."
	.. "\nUninstall: delete version.dll and the TF3-DLSS folder there. Windows only."

local function send(key, value)
	local text = type(value) == "number" and value % 1 ~= 0 and string.format("%.2f", value) or tostring(value)
	log("set " .. key .. "=" .. text)
end

local function onoff(v) return v == 1 and "ON" or "OFF" end

local stub = {}

stub.Tf3Dlss5Menu = react.RegisterRecipe("Tf3Dlss5Menu", function()
	-- hooks first, the same on every render
	local open = react.useState(false)
	local rev = react.useState(0) -- bumped after each change, so the row shows the new values

	local ok, node = pcall(function()
		load_settings()
		if not saidHello then
			saidHello = true
			log("hello mod:" .. MOD_REVISION)
		end

		local function change(key, value)
			if settings[key] == value then return end -- at a limit already: nothing to send
			settings[key] = value
			send(key, value)
			rev:set(rev:old() + 1)
		end

		local function textButton(label, tooltip, onClick)
			return builtin.Button{
				meta = { tooltip = tooltip, class = "tf3dlss5-btn" },
				content = builtin.TextView{ meta = { class = "tf3dlss5-text" }, text = label },
				onClick = function()
					local done, e = pcall(onClick)
					if not done then log("button failed: " .. tostring(e)) end
				end,
			}
		end

		local children = {
			builtin.ToggleButton{
				meta = { tooltip = TOOLTIP, class = "tf3dlss5-toggle", id = "tf3dlss5.menu" },
				content = builtin.ImageView{
					meta = { class = "tf3dlss5-icon" },
					path = ICON,
					scaling = builtin.type.ImageViewScaling.AutoFit,
				},
				value = open:old() and 1 or 0,
				onValueChange = function() open:set(not open:old()) end,
			},
		}

		if open:old() then
			local s = settings
			children[#children + 1] = textButton("Upscaler " .. onoff(s.enabled),
				"DLSS / FSR 3.1 on or off (off = the game's own FSR 1, to compare)",
				function() change("enabled", s.enabled == 1 and 0 or 1) end)
			children[#children + 1] = textButton("DLSS 5 " .. onoff(s.dlss5),
				"DLSS 5 neural rendering after DLSS (NVIDIA RTX; needs the DLSS 5 files in the add-on's dlss5 folder)."
					.. "\nIf the game was started with DLSS 5 off, turning it on needs a restart.",
				function() change("dlss5", s.dlss5 == 1 and 0 or 1) end)
			children[#children + 1] = textButton("Sharp -", "Less sharpening after DLSS",
				function() change("sharpness", math.max(0, math.floor(s.sharpness * 10 - 0.5) / 10)) end)
			children[#children + 1] = builtin.TextView{
				meta = { class = "tf3dlss5-value", tooltip = "Sharpening after DLSS, 0 to 1" },
				text = string.format("%.1f", s.sharpness),
			}
			children[#children + 1] = textButton("+", "More sharpening after DLSS",
				function() change("sharpness", math.min(1, math.floor(s.sharpness * 10 + 1.5) / 10)) end)
			children[#children + 1] = textButton("Info " .. onoff(s.overlay),
				"The add-on's info box: upscaler, sizes, DLSS 5 state, frame rate",
				function() change("overlay", s.overlay == 1 and 0 or 1) end)
			if addon ~= true then
				children[#children + 1] = textButton(addon == false and "Install add-on" or "Add-on files",
					INSTALL_TIP, open_addon_folder)
			end
		end

		return builtin.BoxLayout{ children = children }
	end)
	if ok and node then return node end
	log("menu failed: " .. tostring(node))
	return builtin.BoxLayout{}
end)

-- The engine loads *.script.lua resources by calling data().
function data()
	return stub
end

return stub
