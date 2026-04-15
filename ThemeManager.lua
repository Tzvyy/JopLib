--[[
    JopLib - UI Library for Roblox
    ThemeManager.lua - Theme system with built-in themes + custom theme support
]]

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

ThemeManager.BuiltInThemes["Mocha"] = {
    Background       = Color3.fromRGB(30, 30, 46),
    TitleBar         = Color3.fromRGB(24, 24, 37),
    TabBackground    = Color3.fromRGB(27, 27, 40),
    TabActive        = Color3.fromRGB(45, 45, 60),
    TabInactive      = Color3.fromRGB(27, 27, 40),
    GroupboxBg       = Color3.fromRGB(24, 24, 37),
    ElementBg        = Color3.fromRGB(49, 50, 68),
    ElementBorder    = Color3.fromRGB(69, 71, 90),
    FontPrimary      = Color3.fromRGB(205, 214, 244),
    FontSecondary    = Color3.fromRGB(147, 153, 178),
    Accent           = Color3.fromRGB(137, 180, 250),
    ToggleOn         = Color3.fromRGB(137, 180, 250),
    ToggleOff        = Color3.fromRGB(49, 50, 68),
    SliderFill       = Color3.fromRGB(137, 180, 250),
    Border           = Color3.fromRGB(69, 71, 90),
}

ThemeManager.BuiltInThemes["Dracula"] = {
    Background       = Color3.fromRGB(40, 42, 54),
    TitleBar         = Color3.fromRGB(33, 34, 44),
    TabBackground    = Color3.fromRGB(36, 38, 48),
    TabActive        = Color3.fromRGB(55, 57, 70),
    TabInactive      = Color3.fromRGB(36, 38, 48),
    GroupboxBg       = Color3.fromRGB(33, 34, 44),
    ElementBg        = Color3.fromRGB(68, 71, 90),
    ElementBorder    = Color3.fromRGB(98, 114, 164),
    FontPrimary      = Color3.fromRGB(248, 248, 242),
    FontSecondary    = Color3.fromRGB(188, 188, 178),
    Accent           = Color3.fromRGB(189, 147, 249),
    ToggleOn         = Color3.fromRGB(189, 147, 249),
    ToggleOff        = Color3.fromRGB(68, 71, 90),
    SliderFill       = Color3.fromRGB(189, 147, 249),
    Border           = Color3.fromRGB(98, 114, 164),
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
    local names = {}
    for name in pairs(self.BuiltInThemes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
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

    -- The UI won't live-update existing elements' colors automatically
    -- (that requires storing references to every Instance property and tweening them)
    -- For now, theme changes take full effect on next window creation
    -- or we can walk the GUI tree and update known properties:

    self:_applyThemeToGui()
    return true
end

function ThemeManager:_applyThemeToGui()
    local lib = self.Library
    if not lib or not lib.ScreenGui then return end

    local theme = lib.Theme
    local gui = lib.ScreenGui

    -- Walk entire GUI tree and update colors by name conventions
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
            elseif name:find("Groupbox_") then
                desc.BackgroundColor3 = theme.GroupboxBg
            elseif name == "SliderBg" or name == "Box" then
                -- handled individually
            elseif name == "Fill" then
                desc.BackgroundColor3 = theme.SliderFill
            elseif name == "Divider" then
                -- skip
            end
        end

        if desc:IsA("UIStroke") then
            local parent = desc.Parent
            if parent then
                if parent.Name == "MainFrame" or parent:IsA("Frame") and parent.Name:find("Groupbox_") then
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
            if name:find("Tab_") then
                -- Tab buttons handled separately
            elseif name == "Btn" then
                desc.BackgroundColor3 = theme.ElementBg
                desc.TextColor3 = theme.FontPrimary
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
        Text = "Theme",
        Values = themeNames,
        Default = "Default",
        Callback = function(val)
            self:SetTheme(val)
        end,
    })

    -- Save/Load theme
    if typeof(writefile) == "function" then
        left:AddButton("Save Theme", function()
            local themeName = getgenv().Options.ThemeSelector and getgenv().Options.ThemeSelector.Value or "Default"
            local folder = self.Folder .. "/themes"
            pcall(function()
                if not isfolder(folder) then makefolder(folder) end
                writefile(folder .. "/current.txt", themeName)
            end)
            if lib.Notify then lib:Notify("Theme saved: " .. themeName, 2) end
        end)

        left:AddButton("Load Saved Theme", function()
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
        end)
    end
end

return ThemeManager
