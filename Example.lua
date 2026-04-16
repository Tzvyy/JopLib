-- JopLib Example Script
-- Matches Linoria-style API for testing all features

local repo = "https://raw.githubusercontent.com/Tzvyy/JopLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Elements = loadstring(game:HttpGet(repo .. "Elements.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

Elements:Setup(Library)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

local Window = Library:CreateWindow({
    Title = "JopLib Example",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
})

local Tabs = {
    Main = Window:AddTab("Main"),
    ["GUI Settings"] = Window:AddTab("GUI Settings"),
}

-- ============================================================
-- LEFT GROUPBOX
-- ============================================================

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox")

-- Toggle (with Tooltip)
LeftGroupBox:AddToggle("MyToggle", {
    Text = "This is a toggle",
    Default = true,
    Tooltip = "This is a tooltip for the toggle!",

    Callback = function(Value)
        print("[cb] MyToggle changed to:", Value)
    end,
})

Toggles.MyToggle:OnChanged(function()
    print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

Toggles.MyToggle:SetValue(false)

-- Button
local MyButton = LeftGroupBox:AddButton({
    Text = "Button",
    Func = function()
        print("You clicked a button!")
    end,
    DoubleClick = false,
})

MyButton:AddButton({
    Text = "Sub button",
    Func = function()
        print("You clicked a sub button!")
    end,
    DoubleClick = true,
})

-- Label
LeftGroupBox:AddLabel("This is a label")
LeftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)

-- Divider
LeftGroupBox:AddDivider()

-- Slider (with Tooltip)
LeftGroupBox:AddSlider("MySlider", {
    Text = "This is my slider!",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = "Drag to adjust the value",

    Callback = function(Value)
        print("[cb] MySlider was changed! New value:", Value)
    end,
})

Options.MySlider:OnChanged(function()
    print("MySlider was changed! New value:", Options.MySlider.Value)
end)

Options.MySlider:SetValue(3)

-- Input
LeftGroupBox:AddInput("MyTextbox", {
    Default = "My textbox!",
    Numeric = false,
    Finished = false,
    Text = "This is a textbox",
    Placeholder = "Placeholder text",

    Callback = function(Value)
        print("[cb] Text updated. New text:", Value)
    end,
})

Options.MyTextbox:OnChanged(function()
    print("Text updated. New text:", Options.MyTextbox.Value)
end)

-- Dropdown
LeftGroupBox:AddDropdown("MyDropdown", {
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,
    Multi = false,
    Text = "A dropdown",

    Callback = function(Value)
        print("[cb] Dropdown got changed. New value:", Value)
    end,
})

Options.MyDropdown:OnChanged(function()
    print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

-- Multi dropdown
LeftGroupBox:AddDropdown("MyMultiDropdown", {
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,
    Multi = true,
    Text = "A multi dropdown",

    Callback = function(Value)
        print("[cb] Multi dropdown got changed:", Value)
    end,
})

Options.MyMultiDropdown:OnChanged(function()
    print("Multi dropdown got changed:")
    for key, value in next, Options.MyMultiDropdown.Value do
        print(key, value)
    end
end)

Options.MyMultiDropdown:SetValue({
    This = true,
    is = true,
})

-- Multiple ColorPickers on a Label
LeftGroupBox:AddLabel("Colors"):AddColorPicker("ColorPicker", {
    Default = Color3.new(0, 1, 0),
    Title = "Some color",

    Callback = function(Value)
        print("[cb] Color changed!", Value)
    end,
}):AddColorPicker("ColorPickerAlt", {
    Default = Color3.new(1, 0.5, 0),
    Title = "Secondary color",
})

Options.ColorPicker:OnChanged(function()
    print("Color changed!", Options.ColorPicker.Value)
end)

Options.ColorPickerAlt:OnChanged(function()
    print("Alt color changed!", Options.ColorPickerAlt.Value)
end)

-- KeyPicker on a Label (with restricted Modes)
LeftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
    Default = "MB2",
    SyncToggleState = false,
    Mode = "Toggle",
    Modes = {"Hold", "Toggle"},
    Text = "Auto lockpick safes",
    NoUI = false,

    Callback = function(Value)
        print("[cb] Keybind clicked!", Value)
    end,

    ChangedCallback = function(New)
        print("[cb] Keybind changed!", New)
    end,
})

Options.KeyPicker:OnClick(function()
    print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
    print("Keybind changed!", Options.KeyPicker.Value)
end)

task.spawn(function()
    while true do
        wait(1)
        if Library.Unloaded then break end
        if Options and Options.KeyPicker and Options.KeyPicker.GetState then
            local state = Options.KeyPicker:GetState()
            if state then
                Library:Log("KeyPicker is being held down")
            end
        end
    end
end)

Options.KeyPicker:SetValue({ "MB2", "Toggle" })

-- ============================================================
-- LEFT GROUPBOX #2 (long content for scroll testing)
-- ============================================================

local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel("Oh no...\nThis label spans multiple lines!\n\nWe're gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true)

-- Risky Toggle
LeftGroupBox2:AddToggle("RiskyToggle", {
    Text = "Risky feature (may cause detection)",
    Default = false,
    Risky = true,
    Tooltip = "This feature may be detected by anti-cheat",
})

-- Player Dropdown (auto-refreshes on join/leave)
LeftGroupBox2:AddDropdown("TargetPlayer", {
    Text = "Target Player",
    SpecialType = "Player",
})

-- Team Dropdown (auto-refreshes on team changes)
LeftGroupBox2:AddDropdown("TargetTeam", {
    Text = "Target Team",
    SpecialType = "Team",
})

-- Toggle with KeyPicker AND multiple ColorPickers
LeftGroupBox2:AddToggle("AddonToggle", {
    Text = "Addons toggle",
    Default = false,
}):AddKeyPicker("AddonKP", {
    Default = "None",
    Mode = "Toggle",
    Text = "Addon Key",
}):AddColorPicker("AddonCP1", {
    Default = Color3.new(1, 0, 0),
    Title = "Primary",
}):AddColorPicker("AddonCP2", {
    Default = Color3.new(0, 0, 1),
    Title = "Secondary",
})

-- ============================================================
-- RIGHT TABBOX
-- ============================================================

local TabBox = Tabs.Main:AddRightTabbox()

local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })
Tab1:AddSlider("Tab1Slider", { Text = "Tab1 Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })
Tab2:AddDropdown("Tab2Drop", { Text = "Tab2 Dropdown", Values = {"Option A", "Option B", "Option C"}, Default = 1 })

-- ============================================================
-- DEPENDENCY BOX
-- ============================================================

local RightGroupbox = Tabs.Main:AddRightGroupbox("Groupbox #3")
RightGroupbox:AddToggle("ControlToggle", { Text = "Dependency box toggle" })

local Depbox = RightGroupbox:AddDependencyBox()
Depbox:AddToggle("DepboxToggle", { Text = "Sub-dependency box toggle" })

local SubDepbox = Depbox:AddDependencyBox()
SubDepbox:AddSlider("DepboxSlider", { Text = "Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })
SubDepbox:AddDropdown("DepboxDropdown", { Text = "Dropdown", Default = 1, Values = {"a", "b", "c"} })

Depbox:SetupDependencies({
    { Toggles.ControlToggle, true },
})

SubDepbox:SetupDependencies({
    { Toggles.DepboxToggle, true },
})

-- ============================================================
-- WATERMARK (hidden by default, toggle in GUI Settings)
-- ============================================================

-- SetWindowTitle example
Window:SetTitle("JopLib Example | v2.0")

Library:SetWatermarkVisibility(false)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter += 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    Library:SetWatermark(("JopLib demo | %s fps | %s ms"):format(
        math.floor(FPS),
        math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    ))
end)

-- ============================================================
-- KEYBIND FRAME (hidden by default, toggle in GUI Settings)
-- ============================================================

Library.KeybindFrame.Visible = false

-- ============================================================
-- UNLOAD HANDLER
-- ============================================================

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print("Unloaded!")
    Library.Unloaded = true
end)

-- ============================================================
-- UI SETTINGS TAB
-- ============================================================

local MenuGroup = Tabs["GUI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddButton({
    Text = "Unload",
    Func = function() Library:Unload() end,
})

MenuGroup:AddLabel(""):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI = true,
    Text = "Menu keybind",
})

Library.ToggleKeybind = Options.MenuKeybind

-- Show Watermark toggle (unique flag per script instance to avoid collisions)
local ShowWatermarkToggle = MenuGroup:AddToggle("ShowWatermark_" .. tostring(math.random(10000, 99999)), {
    Text = "Show Watermark",
    Default = false,
})
ShowWatermarkToggle:OnChanged(function(val)
    Library:SetWatermarkVisibility(val)
end)

-- Show Keybinds toggle (unique flag per script instance to avoid collisions)
local ShowKeybindsToggle = MenuGroup:AddToggle("ShowKeybinds_" .. tostring(math.random(10000, 99999)), {
    Text = "Show Keybinds",
    Default = false,
})
ShowKeybindsToggle:OnChanged(function(val)
    if Library._keybindFrame then Library._keybindFrame.Visible = val end
end)

-- ============================================================
-- THEME + CONFIG (addons)
-- ============================================================

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

SaveManager:BuildConfigSection(Tabs["GUI Settings"])
ThemeManager:ApplyToTab(Tabs["GUI Settings"], MenuGroup)

SaveManager:LoadAutoloadConfig()
ThemeManager:LoadAutoloadTheme()
