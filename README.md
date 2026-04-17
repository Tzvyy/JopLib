# JopLib — Roblox UI Library

A full-featured Roblox UI library inspired by Linoria. Uses native Roblox Instances (no Drawing API), parented to CoreGui. Modular architecture with instance-scoped state isolation for safe multi-script usage.

## Loading

```lua
local repo = "https://raw.githubusercontent.com/Tzvyy/JopLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Elements = loadstring(game:HttpGet(repo .. "Elements.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

Elements:Setup(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Instance-scoped proxy tables (safe with multiple scripts)
local Toggles = Library.Toggles
local Options = Library.Options
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
    Risky = false,            -- optional, shows red warning color
    Tooltip = "Hover text",   -- optional
    Callback = function(value) end,
})

Toggles.MyToggle:OnChanged(function(value) print(value) end)
Toggles.MyToggle:SetValue(true)
Toggles.MyToggle:SetText("New Label")  -- rename after creation
print(Toggles.MyToggle.Value)
```

### Slider
```lua
Left:AddSlider("MySlider", {
    Text = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 0,        -- 0 = integer, 1 = 0.1, 2 = 0.01
    Increment = 5,       -- optional, snaps to multiples (also accepts Step)
    Suffix = " studs/s", -- optional
    Compact = false,     -- optional, single-line mode
    HideMax = false,     -- optional, hides "/ max" text
    Tooltip = "...",     -- optional
})

Options.MySlider:OnChanged(function(value) print(value) end)
Options.MySlider:SetValue(50)
-- Click the value label to type a number directly
```

### Button
```lua
local MyButton = Left:AddButton({
    Text = "Click Me",
    Func = function() print("Clicked!") end,
    DoubleClick = false,  -- true = requires confirmation click
})

-- Sub-button (stacked below)
MyButton:AddButton({
    Text = "Sub Button",
    Func = function() print("Sub clicked!") end,
    DoubleClick = true,
})
```

### Dropdown
```lua
-- Single select
Left:AddDropdown("MyDrop", {
    Text = "Target",
    Values = { "Head", "Torso", "Nearest" },
    Default = 1,           -- index or string
    AllowNull = false,     -- optional, allows deselecting
    SearchThreshold = 6,   -- optional, search box appears when item count exceeds this
})

-- Multi select
Left:AddDropdown("Features", {
    Text = "Features",
    Values = { "Speed", "Fly", "Noclip" },
    Multi = true,
    Default = {},
})

-- Auto-refreshing dropdowns
Left:AddDropdown("Target", { Text = "Player", SpecialType = "Player" })
Left:AddDropdown("Team", { Text = "Team", SpecialType = "Team" })

Options.MyDrop:OnChanged(function(value) print(value) end)
Options.MyDrop:SetValue("Head")
Options.MyDrop:SetValues({ "New", "Values" })  -- replace all options
```

### Text Input
```lua
Left:AddInput("MyInput", {
    Text = "Player Name",
    Default = "",
    Placeholder = "Enter name...",
    Numeric = false,    -- true = numbers only
    Finished = true,    -- true = fires on focus lost, false = fires on every keystroke
})

Options.MyInput:OnChanged(function(value) print(value) end)
Options.MyInput:SetValue("new text")
```

### KeyPicker (Keybind)
```lua
-- Standalone
Left:AddKeyPicker("MyKey", {
    Default = "None",
    Text = "Feature Key",
    Mode = "Toggle",           -- "Hold", "Toggle", "Always"
    Modes = {"Hold", "Toggle", "Always"},  -- optional, restrict available modes
    NoUI = false,              -- optional, hides from keybind list
})

-- Chained onto a toggle (syncs toggle state with keybind)
Left:AddToggle("Speed", { Text = "Speed" }):AddKeyPicker("SpeedKey", {
    Default = "None",
    Text = "Speed",
    SyncToggleState = "Speed",  -- flag of toggle to sync with
})

-- Right-click the button to change mode
Options.SpeedKey:GetState()  -- true/false based on mode
Options.SpeedKey.Value       -- bound key name (e.g. "F", "Ctrl+X", "ScrollUp")
Options.SpeedKey.Mode        -- current mode string
```

**Keybind features:**
- Modifier combos: `Ctrl+X`, `Shift+F`, `Alt+G`
- Mouse buttons: `MB1`, `MB2`, `MB3`
- Scroll wheel: `ScrollUp`, `ScrollDown`
- Press Escape/Backspace to unbind

### ColorPicker
```lua
-- On a label
Left:AddLabel("Box Color"):AddColorPicker("BoxColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Box Color",
    Transparency = 0,  -- optional, 0 = opaque, 1 = fully transparent
})

-- Chained onto a toggle (multiple pickers supported)
Left:AddToggle("ShowBox", { Text = "Show" }):AddColorPicker("BoxCol", {
    Default = Color3.fromRGB(255, 50, 50),
}):AddColorPicker("BoxCol2", {
    Default = Color3.fromRGB(50, 50, 255),
})

Options.BoxColor:OnChanged(function(color) print(color) end)
Options.BoxColor:SetValue(Color3.fromRGB(0, 255, 0))
Options.BoxColor:SetValue(Color3.fromRGB(0, 255, 0), 0.5)  -- with transparency
```

**Color picker features:**
- SV field + hue bar + transparency slider with checkerboard
- Editable HEX and RGB inputs
- Right-click: copy/paste color, copy HEX, copy RGB to clipboard

### Label, Divider & Blank
```lua
Left:AddLabel("Some info text")
Left:AddLabel("Wrapping text here", true)  -- enables word wrap
Left:AddDivider()
Left:AddBlank(8)  -- spacer (height in pixels, default 8)

-- Labels support dynamic text
local myLabel = Left:AddLabel("Initial text")
myLabel:SetText("Updated text")
```

### DependencyBox
Shows/hides elements based on toggle state.
```lua
Left:AddToggle("Master", { Text = "Master Toggle" })

local dep = Left:AddDependencyBox()
dep:SetupDependencies({
    { Toggles.Master, true },  -- visible when Master is ON
})
dep:AddSlider("Sub", { Text = "Sub Slider", Min = 0, Max = 100, Default = 50 })
```

### TabBox
```lua
local TabBox = Tab:AddRightTabbox()
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("T1", { Text = "Toggle" })
local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddDropdown("T2", { Text = "Drop", Values = {"A","B","C"}, Default = 1 })
```

### Groupbox
```lua
local Left = Tab:AddLeftGroupbox("Features")
local Right = Tab:AddRightGroupbox("Settings")

Left:SetTitle("New Title")  -- rename groupbox header at runtime
```

## Window API

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Center = true,
    AutoShow = true,
    Width = 550,      -- optional, default 550
    Height = 600,     -- optional, default 600
    TabPadding = 8,
})

-- Tab icons (optional second argument)
local Tab = Window:AddTab("Combat", { Icon = "rbxassetid://7733960981" })

Window:SetTitle("New Title")
Window:Resize(700, 500)       -- width, height
Window:SwitchTab(Tab)
```

## ThemeManager

```lua
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs.Settings, MenuGroupbox)
ThemeManager:LoadAutoloadTheme()
ThemeManager:SetTheme("Default")  -- programmatic switch
```

**Built-in themes:** Default, Dark, Light, Dracula, Jester, Mint, Nord, Ocean, Rose, Tokyo Night

Custom themes: save/load/delete/overwrite via the UI. Set as autoload to auto-apply on startup.
- **Set as autoload** uses the most recent selection from either the built-in or custom theme dropdown.

## SaveManager

```lua
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
```

**Config version migration:**
```lua
SaveManager:SetConfigVersion(2)
SaveManager:AddMigration(1, function(data)
    -- Rename a flag from old to new
    if data["OldFlag"] then
        data["NewFlag"] = data["OldFlag"]
        data["OldFlag"] = nil
    end
    return data
end)
```

Config UI: Save, Load, Overwrite, Delete (with confirmation), Refresh, Set as autoload.
- **Load** uses the config selected in the dropdown (not the name textbox).
- **Set as autoload** sets the currently selected dropdown item as the autoload config.

## Notifications

```lua
Library:Notify("Hello world!", 3)  -- text, duration (seconds)
```

Notifications stack from the bottom-right with accent bar, max 5 visible at once.

## Watermark

```lua
Library:SetWatermark("My Script | 60fps | 20ms")
Library:SetWatermarkVisibility(true)
```

## Unload

```lua
Library:OnUnload(function()
    print("Cleanup here")
end)
Library:Unload()  -- destroys GUI, disconnects all events, cleans up globals
```

## Instance-Scoped State

Each `Library` instance maintains its own `Flags` table. The global `Toggles`/`Options` tables are still populated for compatibility, but `Library.Toggles` and `Library.Options` are proxy tables that only return flags belonging to that instance. This prevents collisions when multiple scripts use JopLib simultaneously.

## Font

Uses **Inter** font family. Change globally in `Library.lua`:
```lua
local FontFamily = "rbxasset://fonts/families/Inter.json"
```

## File Storage

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
├── Library.lua        — Core: window, tabs, groupboxes, notifications, watermark
├── Elements.lua       — UI elements: toggle, slider, dropdown, color picker, etc.
├── ThemeManager.lua   — Theme system with 10 built-in + custom themes
├── SaveManager.lua    — Config save/load with version migration
├── Example.lua        — Demo script showcasing all features
└── README.md          — This file
```
