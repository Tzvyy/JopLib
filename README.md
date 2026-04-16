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
-- Table API (supports sub-buttons)
local MyButton = Left:AddButton({
    Text = "Click Me",
    Func = function() print("Clicked!") end,
    DoubleClick = false,
})

-- Sub-button (appears stacked below)
MyButton:AddButton({
    Text = "Sub Button",
    Func = function() print("Sub clicked!") end,
    DoubleClick = true,  -- requires double-click to confirm
})
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
-- On a label
Left:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Box Color",
    Transparency = 0,  -- optional, 0 = opaque, 1 = fully transparent
})

-- Chained onto a toggle
Left:AddToggle("ShowBox", { Text = "Show Box" }):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255, 50, 50),
})

Options.BoxColor:OnChanged(function(color) print(color) end)
Options.BoxColor:SetValue(Color3.fromRGB(0, 255, 0))
Options.BoxColor:SetValue(Color3.fromRGB(0, 255, 0), 0.5)  -- with transparency
Options.BoxColor.Value         -- current Color3
Options.BoxColor.Transparency  -- current transparency (0-1)
```

**Color Picker Features:**
- Large saturation/value field with hue bar
- Editable HEX input (e.g. `#00baff`)
- Editable RGB input (e.g. `0, 186, 255`)
- Transparency slider with checkerboard preview
- Opacity reflects on the preview swatch
- **Right-click** the color swatch to:
  - **Copy color** — stores color + transparency internally
  - **Paste color** — applies a previously copied color
  - **Copy HEX** — copies hex to clipboard (e.g. `#ff0000`)
  - **Copy RGB** — copies RGB to clipboard (e.g. `255, 0, 0`)

### Label & Divider
```lua
Left:AddLabel("Some info text")
Left:AddLabel("Wrapping text here", true)  -- second arg enables word wrap
Left:AddDivider()

-- Label with color picker attached
Left:AddLabel("Accent Color"):AddColorPicker("AccentCol", {
    Default = Color3.fromRGB(96, 105, 255),
})
```

### DependencyBox
Shows/hides elements based on a toggle's state.
```lua
Left:AddToggle("ControlToggle", { Text = "Master Toggle" })

local dep = Left:AddDependencyBox()
dep:SetupDependencies({
    { Toggles.ControlToggle, true },  -- visible when ControlToggle is ON
})
dep:AddSlider("SubSlider", { Text = "Sub Slider", Min = 0, Max = 100, Default = 50 })
dep:AddLabel("Only visible when Master Toggle is ON")
```

### TabBox
```lua
local TabBox = Tab:AddRightTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("T1Toggle", { Text = "Toggle" })
local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddDropdown("T2Drop", { Text = "Drop", Values = {"A","B","C"}, Default = 1 })
```

## ThemeManager
```lua
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs.Settings, MenuGroupbox)  -- adds theme dropdown + color pickers + custom themes
ThemeManager:LoadAutoloadTheme()
ThemeManager:SetTheme("Default")  -- programmatic switch
```

Built-in themes: **Default**, **Dark**, **Light**

Custom themes can be saved/loaded/deleted via the UI. Delete requires a confirmation click. Use "Set as autoload" to auto-apply on startup.

## SaveManager
```lua
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()               -- prevent theme colors from leaking into configs
SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- ignore specific flags
SaveManager:BuildConfigSection(Tabs.Settings)   -- adds config UI
SaveManager:LoadAutoloadConfig()
```

Config UI provides: **Save**, **Load**, **Overwrite**, **Delete** (with confirmation), **Refresh**, and **Set as autoload**.

ShowWatermark and ShowKeybindFrame toggles are saved with configs (not ignored by `IgnoreThemeSettings`).

## Notifications
```lua
Library:Notify("Hello world!", 3)  -- text, duration in seconds
```

## Watermark
```lua
Library:SetWatermark("My Script | 60fps")
Library:SetWatermarkVisibility(true)
```

## Unload
```lua
Library:OnUnload(function()
    print("Cleanup here")
end)
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

## File Storage
All data is stored in the executor's workspace under `JopLib/`:
```
JopLib/
├── configs/              — saved user configurations
│   ├── autoload.txt      — name of config to auto-load
│   └── *.json            — individual config files
└── themes/               — custom theme storage
    ├── autoload.txt      — name of theme to auto-load
    └── *.json            — individual custom theme files
```

## Source Files
```
JopLib/
├── Library.lua        — Core window, tabs, groupboxes, layout
├── Elements.lua       — All UI elements (toggle, slider, dropdown, color picker, etc.)
├── ThemeManager.lua   — Theme system with built-in + custom themes
├── SaveManager.lua    — Config save/load system
├── Example.lua        — Demo script (loads from GitHub)
├── ExampleLocal.lua   — Demo script (loads from local files)
└── README.md          — This file
```
