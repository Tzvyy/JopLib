--[[
    JopLib - UI Library for Roblox
    ThemeManager.lua - Theme system with built-in themes + custom theme support
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.Library = nil
ThemeManager.Folder = "JopLib"
ThemeManager.BuiltInThemes = {}

-- ============================================================
-- BUILT-IN THEMES
-- ============================================================

ThemeManager.BuiltInThemes["Default"] = {
    Background       = Color3.fromRGB(20, 20, 20),
    TitleBar         = Color3.fromRGB(25, 25, 25),
    TabBackground    = Color3.fromRGB(28, 28, 28),
    TabActive        = Color3.fromRGB(35, 35, 35),
    TabInactive      = Color3.fromRGB(28, 28, 28),
    GroupboxBg       = Color3.fromRGB(25, 25, 25),
    ElementBg        = Color3.fromRGB(35, 35, 35),
    ElementBorder    = Color3.fromRGB(50, 50, 50),
    FontPrimary      = Color3.fromRGB(220, 220, 220),
    FontSecondary    = Color3.fromRGB(160, 160, 160),
    Accent           = Color3.fromRGB(96, 105, 255),
    ToggleOn         = Color3.fromRGB(96, 105, 255),
    ToggleOff        = Color3.fromRGB(50, 50, 50),
    SliderFill       = Color3.fromRGB(96, 105, 255),
    Border           = Color3.fromRGB(45, 45, 45),
}

ThemeManager.BuiltInThemes["Light"] = {
    Background       = Color3.fromRGB(240, 240, 240),
    TitleBar         = Color3.fromRGB(230, 230, 230),
    TabBackground    = Color3.fromRGB(235, 235, 235),
    TabActive        = Color3.fromRGB(250, 250, 250),
    TabInactive      = Color3.fromRGB(235, 235, 235),
    GroupboxBg       = Color3.fromRGB(250, 250, 250),
    ElementBg        = Color3.fromRGB(235, 235, 235),
    ElementBorder    = Color3.fromRGB(200, 200, 200),
    FontPrimary      = Color3.fromRGB(30, 30, 30),
    FontSecondary    = Color3.fromRGB(100, 100, 100),
    Accent           = Color3.fromRGB(70, 80, 220),
    ToggleOn         = Color3.fromRGB(70, 80, 220),
    ToggleOff        = Color3.fromRGB(200, 200, 200),
    SliderFill       = Color3.fromRGB(70, 80, 220),
    Border           = Color3.fromRGB(190, 190, 190),
}

ThemeManager.BuiltInThemes["Dark"] = {
    Background       = Color3.fromRGB(15, 15, 15),
    TitleBar         = Color3.fromRGB(18, 18, 18),
    TabBackground    = Color3.fromRGB(20, 20, 20),
    TabActive        = Color3.fromRGB(30, 30, 30),
    TabInactive      = Color3.fromRGB(20, 20, 20),
    GroupboxBg       = Color3.fromRGB(18, 18, 18),
    ElementBg        = Color3.fromRGB(28, 28, 28),
    ElementBorder    = Color3.fromRGB(40, 40, 40),
    FontPrimary      = Color3.fromRGB(210, 210, 210),
    FontSecondary    = Color3.fromRGB(140, 140, 140),
    Accent           = Color3.fromRGB(96, 105, 255),
    ToggleOn         = Color3.fromRGB(96, 105, 255),
    ToggleOff        = Color3.fromRGB(40, 40, 40),
    SliderFill       = Color3.fromRGB(96, 105, 255),
    Border           = Color3.fromRGB(35, 35, 35),
}

-- ============================================================
-- METHODS
-- ============================================================

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
end

function ThemeManager:GetThemes()
    return {"Default", "Dark", "Light"}
end

function ThemeManager:SetTheme(name)
    local theme = self.BuiltInThemes[name]
    if not theme then return false end

    local lib = self.Library
    if not lib then return false end

    for key, color in pairs(theme) do
        lib.Theme[key] = color
    end
    lib.AccentColor = theme.Accent

    self:_applyThemeToGui()

    -- Update color picker previews
    local opts = getgenv().Options or {}
    for key, _ in pairs(theme) do
        local cpFlag = "ThemeColor_" .. key
        if opts[cpFlag] then
            pcall(function() opts[cpFlag]:SetValue(theme[key]) end)
        end
    end

    return true
end

function ThemeManager:_applyThemeToGui()
    local lib = self.Library
    if not lib or not lib.ScreenGui then return end

    local theme = lib.Theme
    local gui = lib.ScreenGui

    for _, desc in ipairs(gui:GetDescendants()) do
        local name = desc.Name

        if desc:IsA("Frame") then
            if name == "MainFrame" then
                desc.BackgroundColor3 = theme.Background
            elseif name == "TitleBar" or name == "BottomCover" then
                desc.BackgroundColor3 = theme.TitleBar
            elseif name == "AccentLine" or name == "AccentBar" then
                desc.BackgroundColor3 = theme.Accent
            elseif name == "TabBarContainer" then
                desc.BackgroundColor3 = theme.TabBackground
            elseif name:find("Groupbox_") or name == "Tabbox" then
                desc.BackgroundColor3 = theme.GroupboxBg
            elseif name == "Fill" then
                desc.BackgroundColor3 = theme.SliderFill
            end
        end

        if desc:IsA("UIStroke") then
            local parent = desc.Parent
            if parent then
                if parent.Name == "MainFrame" or (parent:IsA("Frame") and (parent.Name:find("Groupbox_") or parent.Name == "Tabbox")) then
                    desc.Color = theme.Border
                else
                    desc.Color = theme.ElementBorder
                end
            end
        end

        if desc:IsA("TextLabel") then
            if name == "TitleText" or name == "GroupTitle" then
                desc.TextColor3 = theme.FontPrimary
            elseif name == "Label" then
                desc.TextColor3 = theme.FontPrimary
            elseif name == "Value" or name == "Arrow" then
                desc.TextColor3 = theme.FontSecondary
            end
        end

        if desc:IsA("TextButton") then
            if name == "Btn" then
                desc.BackgroundColor3 = theme.ElementBg
                desc.TextColor3 = theme.FontPrimary
            end
        end

        if desc:IsA("ScrollingFrame") then
            if name == "LeftColumn" or name == "RightColumn" then
                desc.ScrollBarImageColor3 = theme.Accent
            end
        end
    end
end

function ThemeManager:ApplyToTab(tab)
    local lib = self.Library
    if not lib then return end

    local left = tab:AddLeftGroupbox("Theme")

    local themeNames = self:GetThemes()

    left:AddDropdown("ThemeSelector", {
        Values = themeNames,
        Default = "Default",
        Text = "Theme",
    })

    getgenv().Options.ThemeSelector:OnChanged(function()
        self:SetTheme(getgenv().Options.ThemeSelector.Value)
    end)

    -- Simplified color pickers (6 categories)
    local colorMap = {
        { label = "Background Color", keys = {"Background", "GroupboxBg"} },
        { label = "Main Color", keys = {"TitleBar", "TabBackground", "TabActive", "TabInactive", "ElementBg"} },
        { label = "Accent Color", keys = {"Accent", "ToggleOn", "SliderFill"} },
        { label = "Outline Color", keys = {"Border", "ElementBorder"} },
        { label = "Font Color", keys = {"FontPrimary"} },
        { label = "Subtext Font Color", keys = {"FontSecondary"} },
    }

    for i, entry in ipairs(colorMap) do
        local cpFlag = "ThemeColor_" .. i
        local firstKey = entry.keys[1]
        left:AddLabel(entry.label):AddColorPicker(cpFlag, {
            Default = lib.Theme[firstKey],
            Title = entry.label,
        })

        getgenv().Options[cpFlag]:OnChanged(function(color)
            for _, key in ipairs(entry.keys) do
                lib.Theme[key] = color
            end
            if entry.keys[1] == "Accent" then
                lib.AccentColor = color
            end
            self:_applyThemeToGui()
        end)
    end

    -- Save/Load theme
    left:AddButton({
        Text = "Save Theme",
        Func = function()
            local themeName = getgenv().Options.ThemeSelector and getgenv().Options.ThemeSelector.Value or "Default"
            local folder = self.Folder .. "/themes"
            pcall(function()
                if typeof(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end
                if typeof(writefile) == "function" then
                    writefile(folder .. "/current.txt", themeName)
                end
            end)
            if lib.Notify then lib:Notify("Theme saved: " .. themeName, 2) end
        end,
    })

    left:AddButton({
        Text = "Load Saved Theme",
        Func = function()
            local folder = self.Folder .. "/themes"
            local ok, content = pcall(function()
                return readfile(folder .. "/current.txt")
            end)
            if ok and content then
                self:SetTheme(content)
                if getgenv().Options.ThemeSelector then
                    getgenv().Options.ThemeSelector:SetValue(content)
                end
                if lib.Notify then lib:Notify("Theme loaded: " .. content, 2) end
            end
        end,
    })

    -- Auto-load theme on startup
    left:AddToggle("AutoLoadTheme", {
        Text = "Auto-load Theme",
        Default = false,
    })

    -- Watermark toggle
    left:AddToggle("ShowWatermark", {
        Text = "Show Watermark",
        Default = false,
    })

    getgenv().Toggles.ShowWatermark:OnChanged(function()
        lib:SetWatermarkVisibility(getgenv().Toggles.ShowWatermark.Value)
    end)

    -- Keybind frame toggle
    left:AddToggle("ShowKeybindFrame", {
        Text = "Show Keybind List",
        Default = false,
    })

    getgenv().Toggles.ShowKeybindFrame:OnChanged(function()
        if lib.KeybindFrame then
            lib.KeybindFrame.Visible = getgenv().Toggles.ShowKeybindFrame.Value
        end
    end)

    -- Keybind list filter
    left:AddDropdown("KeybindListFilter", {
        Values = {"Show All", "Active Only"},
        Default = 1,
        Text = "Keybind List Filter",
    })

    getgenv().Options.KeybindListFilter:OnChanged(function()
        lib._keybindFilterActive = (getgenv().Options.KeybindListFilter.Value == "Active Only")
    end)
end

function ThemeManager:ApplyToGroupbox(groupbox)
    local lib = self.Library
    if not lib then return end

    local themeNames = self:GetThemes()

    groupbox:AddDropdown("ThemeSelector", {
        Values = themeNames,
        Default = "Default",
        Text = "Theme",
    })

    getgenv().Options.ThemeSelector:OnChanged(function()
        self:SetTheme(getgenv().Options.ThemeSelector.Value)
    end)
end

function ThemeManager:LoadAutoloadTheme()
    if getgenv().Toggles.AutoLoadTheme and getgenv().Toggles.AutoLoadTheme.Value then
        local folder = self.Folder .. "/themes"
        local ok, content = pcall(function() return readfile(folder .. "/current.txt") end)
        if ok and content then
            self:SetTheme(content)
            if getgenv().Options.ThemeSelector then
                getgenv().Options.ThemeSelector:SetValue(content)
            end
        end
    end
end

return ThemeManager
