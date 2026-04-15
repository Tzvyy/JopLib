--[[
    JopLib - Example Usage Script
    Shows all available UI elements and features
    
    Load from GitHub (replace with your actual URL):
    local repo = "https://raw.githubusercontent.com/YOUR_USER/JopLib/main/"
    
    Load locally (if using readfile):
    local repo = "JopLib/"
]]

-- ============================================================
-- LOADING (GitHub method)
-- ============================================================

local repo = "https://raw.githubusercontent.com/YOUR_USER/JopLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Elements = loadstring(game:HttpGet(repo .. "Elements.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

-- Initialize elements (MUST call before CreateWindow)
Elements:Setup(Library)

-- Connect managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- ============================================================
-- CREATE WINDOW
-- ============================================================

local Window = Library:CreateWindow({
    Title = "JopLib Example",
    Center = true,
    AutoShow = true,
    Width = 550,
    Height = 400,
})

-- ============================================================
-- TABS
-- ============================================================

local Tabs = {
    Combat   = Window:AddTab("Combat"),
    Visuals  = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings"),
}

-- ============================================================
-- COMBAT TAB
-- ============================================================

local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot")

AimbotGroup:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot",
    Default = false,
}):AddKeyPicker("AimbotKey", {
    Default = "None",
    Text = "Aimbot",
}):OnChanged(function(value)
    print("[Aimbot Key]", value)
end)

Toggles.AimbotEnabled:OnChanged(function(value)
    print("[Aimbot]", value)
end)

AimbotGroup:AddToggle("ShowFOV", {
    Text = "Show FOV Circle",
    Default = false,
})

AimbotGroup:AddSlider("AimFOV", {
    Text = "FOV Radius",
    Default = 250,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Suffix = " px",
}):OnChanged(function(value)
    print("[FOV]", value)
end)

AimbotGroup:AddSlider("AimSmooth", {
    Text = "Smoothing",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
}):OnChanged(function(value)
    print("[Smoothing]", value)
end)

AimbotGroup:AddDropdown("AimTarget", {
    Text = "Target Part",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Default = 1,
}):OnChanged(function(value)
    print("[Target Part]", value)
end)

AimbotGroup:AddLabel("Hold mouse to lock on")
AimbotGroup:AddLabel("Smoothing 1 = instant snap")

-- Silent Aim group
local SilentGroup = Tabs.Combat:AddRightGroupbox("Silent Aim")

SilentGroup:AddToggle("SilentAimEnabled", {
    Text = "Enable Silent Aim",
    Default = false,
}):AddKeyPicker("SilentAimKey", {
    Default = "None",
    Text = "Silent Aim",
})

SilentGroup:AddSlider("SilentFOV", {
    Text = "FOV Radius",
    Default = 250,
    Min = 30,
    Max = 800,
    Rounding = 0,
})

SilentGroup:AddDivider()

SilentGroup:AddToggle("InstantBullet", {
    Text = "Instant Bullet",
    Default = false,
}):AddKeyPicker("InstantBulletKey", {
    Default = "None",
    Text = "Instant Bullet",
})

SilentGroup:AddLabel("Teleports bullet to target")

-- ============================================================
-- VISUALS TAB
-- ============================================================

local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

ESPGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
}):OnChanged(function(value)
    print("[ESP]", value)
end)

ESPGroup:AddToggle("ESPBox", {
    Text = "Show Box",
    Default = true,
}):AddColorPicker("ESPBoxColor", {
    Default = Color3.fromRGB(255, 50, 50),
}):OnChanged(function(value)
    print("[ESP Box]", value)
end)

Options.ESPBoxColor:OnChanged(function(color)
    print("[Box Color]", color)
end)

ESPGroup:AddToggle("ESPNames", {
    Text = "Show Names",
    Default = true,
}):AddColorPicker("ESPNameColor", {
    Default = Color3.fromRGB(255, 255, 255),
})

ESPGroup:AddToggle("ESPHealth", {
    Text = "Show Health Bar",
    Default = true,
})

ESPGroup:AddSlider("ESPMaxDist", {
    Text = "Max Distance",
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
})

-- World visuals
local WorldGroup = Tabs.Visuals:AddRightGroupbox("World")

WorldGroup:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
})

WorldGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
})

WorldGroup:AddToggle("NoGrass", {
    Text = "No Grass",
    Default = false,
})

-- ============================================================
-- MOVEMENT TAB
-- ============================================================

local SpeedGroup = Tabs.Movement:AddLeftGroupbox("Speed")

SpeedGroup:AddToggle("SpeedEnabled", {
    Text = "Enable Speed",
    Default = false,
}):AddKeyPicker("SpeedKey", {
    Default = "None",
    Text = "Speed",
})

SpeedGroup:AddDropdown("SpeedMethod", {
    Text = "Method",
    Values = { "CFrame Burst", "CFrame Smooth" },
    Default = 1,
}):OnChanged(function(value)
    print("[Speed Method]", value)
end)

SpeedGroup:AddSlider("SpeedValue", {
    Text = "Speed",
    Default = 28,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Suffix = " studs/s",
})

SpeedGroup:AddDivider()
SpeedGroup:AddLabel("Burst = move/pause cycles")
SpeedGroup:AddLabel("Smooth = constant, keep low")

-- Spider
local SpiderGroup = Tabs.Movement:AddLeftGroupbox("Spiderman")

SpiderGroup:AddToggle("SpiderEnabled", {
    Text = "Enable Spiderman",
    Default = false,
}):AddKeyPicker("SpiderKey", {
    Default = "None",
    Text = "Spiderman",
})

SpiderGroup:AddSlider("SpiderSpeed", {
    Text = "Climb Speed",
    Default = 24,
    Min = 10,
    Max = 60,
    Rounding = 0,
    Suffix = " studs/s",
})

-- Third Person
local TPGroup = Tabs.Movement:AddRightGroupbox("Third Person")

TPGroup:AddToggle("ThirdPerson", {
    Text = "Enable Third Person",
    Default = false,
}):AddKeyPicker("ThirdPersonKey", {
    Default = "None",
    Text = "Third Person",
})

TPGroup:AddSlider("TPCamDist", {
    Text = "Camera Distance",
    Default = 10,
    Min = 2,
    Max = 30,
    Rounding = 0,
    Suffix = " studs",
})

-- Text Input example
local MiscGroup = Tabs.Movement:AddRightGroupbox("Misc")

MiscGroup:AddInput("PlayerName", {
    Text = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
}):OnChanged(function(value)
    print("[Player Name]", value)
end)

-- Multi-select dropdown example
MiscGroup:AddDropdown("Features", {
    Text = "Features",
    Values = { "Speed", "Fly", "Noclip", "Teleport" },
    Multi = true,
    Default = {},
}):OnChanged(function(value)
    print("[Features]", value)
end)

-- Dependency Box example
local depBox = MiscGroup:AddDependencyBox()
depBox:SetupDependencies({
    { Flag = "SpeedEnabled" },
})
depBox:AddSlider("BurstOn", {
    Text = "Burst Duration",
    Default = 0.3,
    Min = 0.1,
    Max = 1.0,
    Rounding = 2,
    Suffix = "s",
})
depBox:AddLabel("Only visible when Speed is enabled")

-- ============================================================
-- SETTINGS TAB
-- ============================================================

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

MenuGroup:AddButton("Unload Script", function()
    Library:Unload()
    print("[Script] Unloaded.")
end, { DoubleConfirm = true })

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    Text = "Menu Toggle",
})

Library.ToggleKeybind = Options.MenuKeybind

-- Theme & Config
ThemeManager:SetFolder("JopLib")
SaveManager:SetFolder("JopLib/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Auto-load config
SaveManager:LoadAutoloadConfig()

-- ============================================================
-- MODULE LIST (optional)
-- ============================================================

Library:AddModule({ Name = "Speed",         Toggle = "SpeedEnabled",   Keybind = "SpeedKey" })
Library:AddModule({ Name = "Spiderman",     Toggle = "SpiderEnabled",  Keybind = "SpiderKey" })
Library:AddModule({ Name = "Third Person",  Toggle = "ThirdPerson",    Keybind = "ThirdPersonKey" })
Library:AddModule({ Name = "Aimbot",        Toggle = "AimbotEnabled",  Keybind = "AimbotKey" })
Library:AddModule({ Name = "Silent Aim",    Toggle = "SilentAimEnabled", Keybind = "SilentAimKey" })
Library:AddModule({ Name = "ESP",           Toggle = "ESPEnabled" })
Library:AddModule({ Name = "Fullbright",    Toggle = "Fullbright" })

-- To show the module list:
-- Library.ModuleListEnabled = true
-- Library:CreateModuleListGui()

Library:Notify("JopLib Example loaded!", 3)
print("[JopLib] Example script loaded successfully!")
