# JopLib — Roblox UI Library

A full-featured Roblox UI library inspired by Linoria. Uses native Roblox Instances (no Drawing API for UI), parented to CoreGui.

## Loading

### From GitHub
```lua
local repo = "https://raw.githubusercontent.com/Tzvyy/JopLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Elements = loadstring(game:HttpGet(repo .. "Elements.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

Elements:Setup(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
```

### Local (readfile)
```lua
local Library = loadstring(readfile("JopLib/Library.lua"))()
local Elements = loadstring(readfile("JopLib/Elements.lua"))()
local ThemeManager = loadstring(readfile("JopLib/ThemeManager.lua"))()
local SaveManager = loadstring(readfile("JopLib/SaveManager.lua"))()

Elements:Setup(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
```

## Quick Start

```lua
local Window = Library:CreateWindow({ Title = "My Script", Center = true, AutoShow = true })
local Tab = Window:AddTab("Main")
local Left = Tab:AddLeftGroupbox("Features")
local Right = Tab:AddRightGroupbox("Settings")
```

## Elements API

### Toggle
```lua
Left:AddToggle("MyToggle", {
    Text = "Enable Feature",
    Default = false,
    Callback = function(value) end,  -- optional instant callback
})

Toggles.MyToggle:OnChanged(function(value) print(value) end)
Toggles.MyToggle:SetValue(true)
print(Toggles.MyToggle.Value)
```

### Slider
```lua
Left:AddSlider("MySlider", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,    -- 0 = integer, 1 = 0.1, 2 = 0.01
    Suffix = " studs/s",
})

Options.MySlider:OnChanged(function(value) print(value) end)
Options.MySlider:SetValue(50)
```

### Button
```lua
Left:AddButton("Click Me", function()
    print("Clicked!")
end)

-- With double-click confirm:
Left:AddButton("Dangerous Action", function()
    print("Confirmed!")
end, { DoubleConfirm = true })
```

### Dropdown
```lua
-- Single select
Left:AddDropdown("MyDrop", {
    Text = "Target",
    Values = { "Head", "Torso", "Nearest" },
    Default = 1,  -- index or string
})

-- Multi select
Left:AddDropdown("Features", {
    Text = "Features",
    Values = { "Speed", "Fly", "Noclip" },
    Multi = true,
    Default = {},
})

Options.MyDrop:OnChanged(function(value) print(value) end)
Options.MyDrop:SetValue("Head")
Options.MyDrop:SetValues({ "New", "Values" })  -- replace options
```

### Text Input
```lua
Left:AddInput("MyInput", {
    Text = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
    Numeric = false,
    Finished = true,  -- fires on focus lost only
})

Options.MyInput:OnChanged(function(value) print(value) end)
```

### KeyPicker (Keybind)
```lua
-- Standalone
Left:AddKeyPicker("MyKey", {
    Default = "None",
    Text = "Feature Key",
    Mode = "Toggle",  -- "Hold", "Toggle", "Always"
})

-- Chained onto a toggle
Left:AddToggle("Speed", { Text = "Speed" }):AddKeyPicker("SpeedKey", {
    Default = "None",
    Text = "Speed",
})

-- Right-click the keybind button to cycle mode
Options.SpeedKey:GetState()  -- returns true/false based on mode
Options.SpeedKey.Value       -- the bound key name
Options.SpeedKey.Mode        -- current mode
```

### ColorPicker
```lua
-- Standalone
Left:AddColorPicker("MyColor", {
    Text = "Box Color",
    Default = Color3.fromRGB(255, 0, 0),
})

-- Chained onto a toggle
Left:AddToggle("ShowBox", { Text = "Show Box" }):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255, 50, 50),
})

Options.BoxColor:OnChanged(function(color) print(color) end)
Options.BoxColor:SetValue(Color3.fromRGB(0, 255, 0))
```

### Label & Divider
```lua
Left:AddLabel("Some info text")
Left:AddDivider()

-- Label with color picker attached
Left:AddLabel("Accent Color"):AddColorPicker("AccentCol", {
    Default = Color3.fromRGB(96, 105, 255),
})
```

### DependencyBox
Shows/hides elements based on a toggle's state.
```lua
local dep = Left:AddDependencyBox()
dep:SetupDependencies({
    { Flag = "Speed", Inverted = false },
})
dep:AddSlider("BurstTime", { Text = "Burst", Min = 0.1, Max = 1.0, Default = 0.3 })
dep:AddLabel("Only visible when Speed is ON")
```

## Module List
A draggable overlay showing active modules + keybinds.
```lua
Library:AddModule({ Name = "Speed", Toggle = "SpeedEnabled", Keybind = "SpeedKey" })
Library:AddModule({ Name = "ESP", Toggle = "ESPEnabled" })

Library.ModuleListEnabled = true
Library:CreateModuleListGui()
-- Library.ModuleListMode = 1  (1 = all, 2 = enabled only)
```

## ThemeManager
```lua
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyScript")
ThemeManager:ApplyToTab(Tabs.Settings)  -- adds theme dropdown + save/load
ThemeManager:SetTheme("Mocha")          -- programmatic switch
```

Built-in themes: **Default**, **Light**, **Mocha**, **Dracula**

## SaveManager
```lua
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.Settings)  -- adds config UI
SaveManager:LoadAutoloadConfig()
```

## Notifications
```lua
Library:Notify("Hello world!", 3)  -- text, duration in seconds
```

## Unload
```lua
Library:Unload()  -- destroys GUI, disconnects all events
```

## Globals
- `Toggles` — table of all toggle objects, keyed by flag
- `Options` — table of all option objects (sliders, dropdowns, inputs, keypickers, colorpickers), keyed by flag

## Font
Uses **Inter** font family via `FontFace`. Change in `Library.lua`:
```lua
local FontFamily = "rbxasset://fonts/families/Inter.json"
```

## File Structure
```
JopLib/
├── Library.lua       — Core window, tabs, groupboxes, layout
├── Elements.lua      — All UI elements
├── ThemeManager.lua  — Theme system
├── SaveManager.lua   — Config save/load
├── Example.lua       — Demo script
└── README.md         — This file
```
