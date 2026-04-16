--[[
    JopLib - UI Library for Roblox
    ThemeManager.lua - Theme system with built-in themes + custom theme support
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.Library = nil
ThemeManager.Folder = "JopLib"
ThemeManager.BuiltInThemes = {}
ThemeManager._currentThemeName = "Default"

-- ============================================================
-- BUILT-IN THEMES
-- ============================================================

ThemeManager.BuiltInThemes["Default"] = {
    Background       = Color3.fromRGB(35, 35, 40),
    TitleBar         = Color3.fromRGB(40, 40, 46),
    TabBackground    = Color3.fromRGB(38, 38, 44),
    TabActive        = Color3.fromRGB(50, 50, 58),
    TabInactive      = Color3.fromRGB(38, 38, 44),
    GroupboxBg       = Color3.fromRGB(38, 38, 44),
    ElementBg        = Color3.fromRGB(48, 48, 56),
    ElementBorder    = Color3.fromRGB(60, 60, 68),
    FontPrimary      = Color3.fromRGB(220, 220, 225),
    FontSecondary    = Color3.fromRGB(150, 150, 160),
    Accent           = Color3.fromRGB(96, 105, 255),
    ToggleOn         = Color3.fromRGB(96, 105, 255),
    ToggleOff        = Color3.fromRGB(55, 55, 62),
    SliderFill       = Color3.fromRGB(96, 105, 255),
    Border           = Color3.fromRGB(55, 55, 62),
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
    Accent           = Color3.fromRGB(220, 220, 220),
    ToggleOn         = Color3.fromRGB(220, 220, 220),
    ToggleOff        = Color3.fromRGB(40, 40, 40),
    SliderFill       = Color3.fromRGB(220, 220, 220),
    Border           = Color3.fromRGB(35, 35, 35),
}

ThemeManager.BuiltInThemes["Jester"] = {
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
    Accent           = Color3.fromRGB(170, 50, 220),
    ToggleOn         = Color3.fromRGB(170, 50, 220),
    ToggleOff        = Color3.fromRGB(50, 50, 50),
    SliderFill       = Color3.fromRGB(170, 50, 220),
    Border           = Color3.fromRGB(45, 45, 45),
}

ThemeManager.BuiltInThemes["Mint"] = {
    Background       = Color3.fromRGB(18, 24, 22),
    TitleBar         = Color3.fromRGB(22, 30, 27),
    TabBackground    = Color3.fromRGB(24, 32, 29),
    TabActive        = Color3.fromRGB(32, 42, 38),
    TabInactive      = Color3.fromRGB(24, 32, 29),
    GroupboxBg       = Color3.fromRGB(22, 30, 27),
    ElementBg        = Color3.fromRGB(32, 42, 38),
    ElementBorder    = Color3.fromRGB(44, 58, 52),
    FontPrimary      = Color3.fromRGB(210, 230, 220),
    FontSecondary    = Color3.fromRGB(140, 170, 155),
    Accent           = Color3.fromRGB(60, 210, 150),
    ToggleOn         = Color3.fromRGB(60, 210, 150),
    ToggleOff        = Color3.fromRGB(44, 58, 52),
    SliderFill       = Color3.fromRGB(60, 210, 150),
    Border           = Color3.fromRGB(38, 50, 45),
}

ThemeManager.BuiltInThemes["Tokyo Night"] = {
    Background       = Color3.fromRGB(26, 27, 38),
    TitleBar         = Color3.fromRGB(30, 31, 44),
    TabBackground    = Color3.fromRGB(32, 33, 48),
    TabActive        = Color3.fromRGB(42, 43, 60),
    TabInactive      = Color3.fromRGB(32, 33, 48),
    GroupboxBg       = Color3.fromRGB(30, 31, 44),
    ElementBg        = Color3.fromRGB(42, 43, 60),
    ElementBorder    = Color3.fromRGB(56, 58, 78),
    FontPrimary      = Color3.fromRGB(192, 202, 245),
    FontSecondary    = Color3.fromRGB(130, 140, 175),
    Accent           = Color3.fromRGB(122, 162, 247),
    ToggleOn         = Color3.fromRGB(122, 162, 247),
    ToggleOff        = Color3.fromRGB(56, 58, 78),
    SliderFill       = Color3.fromRGB(122, 162, 247),
    Border           = Color3.fromRGB(48, 50, 68),
}

ThemeManager.BuiltInThemes["Rose"] = {
    Background       = Color3.fromRGB(25, 18, 22),
    TitleBar         = Color3.fromRGB(30, 22, 26),
    TabBackground    = Color3.fromRGB(32, 24, 28),
    TabActive        = Color3.fromRGB(42, 32, 36),
    TabInactive      = Color3.fromRGB(32, 24, 28),
    GroupboxBg       = Color3.fromRGB(30, 22, 26),
    ElementBg        = Color3.fromRGB(42, 32, 36),
    ElementBorder    = Color3.fromRGB(62, 45, 52),
    FontPrimary      = Color3.fromRGB(235, 210, 220),
    FontSecondary    = Color3.fromRGB(170, 140, 155),
    Accent           = Color3.fromRGB(235, 80, 120),
    ToggleOn         = Color3.fromRGB(235, 80, 120),
    ToggleOff        = Color3.fromRGB(55, 40, 46),
    SliderFill       = Color3.fromRGB(235, 80, 120),
    Border           = Color3.fromRGB(50, 38, 44),
}

ThemeManager.BuiltInThemes["Ocean"] = {
    Background       = Color3.fromRGB(16, 22, 30),
    TitleBar         = Color3.fromRGB(20, 28, 38),
    TabBackground    = Color3.fromRGB(22, 30, 40),
    TabActive        = Color3.fromRGB(30, 40, 54),
    TabInactive      = Color3.fromRGB(22, 30, 40),
    GroupboxBg       = Color3.fromRGB(20, 28, 38),
    ElementBg        = Color3.fromRGB(30, 40, 54),
    ElementBorder    = Color3.fromRGB(42, 56, 74),
    FontPrimary      = Color3.fromRGB(200, 220, 240),
    FontSecondary    = Color3.fromRGB(130, 155, 180),
    Accent           = Color3.fromRGB(50, 150, 255),
    ToggleOn         = Color3.fromRGB(50, 150, 255),
    ToggleOff        = Color3.fromRGB(42, 56, 74),
    SliderFill       = Color3.fromRGB(50, 150, 255),
    Border           = Color3.fromRGB(36, 48, 64),
}

ThemeManager.BuiltInThemes["Dracula"] = {
    Background       = Color3.fromRGB(40, 42, 54),
    TitleBar         = Color3.fromRGB(44, 47, 60),
    TabBackground    = Color3.fromRGB(47, 50, 65),
    TabActive        = Color3.fromRGB(56, 58, 75),
    TabInactive      = Color3.fromRGB(47, 50, 65),
    GroupboxBg       = Color3.fromRGB(44, 47, 60),
    ElementBg        = Color3.fromRGB(56, 58, 75),
    ElementBorder    = Color3.fromRGB(68, 71, 90),
    FontPrimary      = Color3.fromRGB(248, 248, 242),
    FontSecondary    = Color3.fromRGB(180, 180, 175),
    Accent           = Color3.fromRGB(189, 147, 249),
    ToggleOn         = Color3.fromRGB(189, 147, 249),
    ToggleOff        = Color3.fromRGB(68, 71, 90),
    SliderFill       = Color3.fromRGB(189, 147, 249),
    Border           = Color3.fromRGB(60, 63, 80),
}

ThemeManager.BuiltInThemes["Nord"] = {
    Background       = Color3.fromRGB(46, 52, 64),
    TitleBar         = Color3.fromRGB(50, 56, 70),
    TabBackground    = Color3.fromRGB(54, 60, 74),
    TabActive        = Color3.fromRGB(62, 68, 82),
    TabInactive      = Color3.fromRGB(54, 60, 74),
    GroupboxBg       = Color3.fromRGB(50, 56, 70),
    ElementBg        = Color3.fromRGB(62, 68, 82),
    ElementBorder    = Color3.fromRGB(76, 86, 106),
    FontPrimary      = Color3.fromRGB(229, 233, 240),
    FontSecondary    = Color3.fromRGB(170, 176, 190),
    Accent           = Color3.fromRGB(136, 192, 208),
    ToggleOn         = Color3.fromRGB(136, 192, 208),
    ToggleOff        = Color3.fromRGB(76, 86, 106),
    SliderFill       = Color3.fromRGB(136, 192, 208),
    Border           = Color3.fromRGB(67, 76, 94),
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

    self._currentThemeName = name

    for key, color in pairs(theme) do
        lib.Theme[key] = color
    end
    lib.AccentColor = theme.Accent

    lib:UpdateColorsUsingRegistry()

    -- Update color picker previews to match theme
    self:_syncColorPickers()

    -- Deferred re-apply to catch any tweens from config autoload that may override colors
    task.delay(0.2, function()
        lib:UpdateColorsUsingRegistry()
    end)

    return true
end

function ThemeManager:_getBaseFolder()
    return "JopLib"
end

function ThemeManager:_getThemesFolder()
    return self:_getBaseFolder() .. "/themes"
end

function ThemeManager:_getAutoloadPath()
    return self:_getThemesFolder() .. "/autoload.txt"
end

function ThemeManager:_getDefaultThemePath()
    return self:_getThemesFolder() .. "/default.txt"
end

function ThemeManager:_ensureFolders()
    pcall(function()
        if typeof(isfolder) == "function" then
            local base = self:_getBaseFolder()
            if not isfolder(base) then makefolder(base) end
            local themes = self:_getThemesFolder()
            if not isfolder(themes) then makefolder(themes) end
        end
    end)
    return self:_getThemesFolder()
end

function ThemeManager:_syncColorPickers()
    local lib = self.Library
    if not lib then return end
    local opts = getgenv().Options or {}
    local colorMap = {
        { keys = {"Background", "TitleBar", "GroupboxBg"} },
        { keys = {"TabBackground", "TabActive", "TabInactive", "ElementBg"} },
        { keys = {"Accent", "ToggleOn", "SliderFill"} },
        { keys = {"Border", "ElementBorder"} },
        { keys = {"FontPrimary"} },
        { keys = {"FontSecondary"} },
    }
    for i, entry in ipairs(colorMap) do
        local cpFlag = "ThemeColor_" .. i
        local firstKey = entry.keys[1]
        if opts[cpFlag] and lib.Theme[firstKey] then
            pcall(function() opts[cpFlag]:SetValue(lib.Theme[firstKey]) end)
        end
    end
end

function ThemeManager:_listCustomThemes()
    local folder = self:_getThemesFolder()
    local themes = {}
    pcall(function()
        if typeof(listfiles) == "function" then
            for _, path in ipairs(listfiles(folder)) do
                local name = path:match("([^/\\]+)%.json$")
                if name and name ~= "autoload_theme" and name ~= "autoload_config" then
                    table.insert(themes, name)
                end
            end
        end
    end)
    table.sort(themes)
    return themes
end

function ThemeManager:SaveCustomTheme(name)
    if not name or name == "" then return false end
    local lib = self.Library
    if not lib then return false end
    local folder = self:_ensureFolders()
    local data = {}
    for key, color in pairs(lib.Theme) do
        data[key] = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
    end
    pcall(function()
        writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return true
end

function ThemeManager:LoadCustomTheme(name)
    if not name or name == "" then return false end
    local lib = self.Library
    if not lib then return false end
    local folder = self:_getThemesFolder()
    local ok, content = pcall(function()
        return readfile(folder .. "/" .. name .. ".json")
    end)
    if not ok or not content then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or not data then return false end
    for key, rgb in pairs(data) do
        if type(rgb) == "table" and #rgb == 3 then
            lib.Theme[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
        end
    end
    if lib.Theme.Accent then lib.AccentColor = lib.Theme.Accent end
    self._currentThemeName = name
    lib:UpdateColorsUsingRegistry()
    self:_syncColorPickers()
    return true
end

function ThemeManager:ApplyToTab(tab, menuGroupbox)
    local lib = self.Library
    if not lib then return end

    -- ── RIGHT: Theme (selector + colors + custom themes) ──
    local right = tab:AddRightGroupbox("Theme")

    local themeNames = self:GetThemes()

    right:AddDropdown("ThemeSelector", {
        Values = themeNames,
        Default = "Default",
        Text = "Theme",
    })

    getgenv().Options.ThemeSelector:OnChanged(function(val)
        ThemeManager:SetTheme(val)
    end)

    -- Color pickers
    local colorMap = {
        { label = "Background Color", keys = {"Background", "TitleBar", "GroupboxBg"} },
        { label = "Main Color", keys = {"TabBackground", "TabActive", "TabInactive", "ElementBg"} },
        { label = "Accent Color", keys = {"Accent", "ToggleOn", "SliderFill"} },
        { label = "Outline Color", keys = {"Border", "ElementBorder"} },
        { label = "Font Color", keys = {"FontPrimary"} },
        { label = "Subtext Font Color", keys = {"FontSecondary"} },
    }

    for i, entry in ipairs(colorMap) do
        local cpFlag = "ThemeColor_" .. i
        local firstKey = entry.keys[1]
        right:AddLabel(entry.label):AddColorPicker(cpFlag, {
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
            lib:UpdateColorsUsingRegistry()
        end)
    end

    -- Custom themes
    right:AddInput("CustomThemeName", {
        Default = "",
        Numeric = false,
        Finished = false,
        Text = "Custom Theme Name",
        Placeholder = "Enter theme name...",
    })

    right:AddDropdown("CustomThemeList", {
        Values = ThemeManager:_listCustomThemes(),
        Default = 1,
        Text = "Custom Themes",
    })

    getgenv().Options.CustomThemeList:OnChanged(function(val)
        -- Just update the name input to match selection; user clicks "Load theme" to apply
        if not val or val == "" then return end
        if getgenv().Options.CustomThemeName then
            getgenv().Options.CustomThemeName:SetValue(val)
        end
    end)

    -- Helper to create side-by-side button rows
    local Create = function(cls, props, children)
        local inst = Instance.new(cls)
        for k, v in pairs(props or {}) do
            if k ~= "Parent" then inst[k] = v end
        end
        if children then
            for _, c in ipairs(children) do c.Parent = inst end
        end
        if props.Parent then inst.Parent = props.Parent end
        return inst
    end

    local function makeButtonRow(rowName, parent)
        local order = parent:_nextOrder()
        return Create("Frame", {
            Name = rowName,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = parent._container,
        }, {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            }),
        })
    end

    local function makeSideBySideBtn(btnText, layoutOrder, parent, onClick, doubleClick)
        local btn = Create("TextButton", {
            Name = "Btn",
            Size = UDim2.new(0.5, -2, 1, 0),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = btnText,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontSemiBold,
            TextSize = 13,
            LayoutOrder = layoutOrder,
            Parent = parent,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })
        lib:AddToRegistry(btn, { BackgroundColor3 = "ElementBg", TextColor3 = "FontPrimary" })
        local btnStroke = btn:FindFirstChildOfClass("UIStroke")
        if btnStroke then lib:AddToRegistry(btnStroke, { Color = "ElementBorder" }) end
        if doubleClick then
            local confirming = false
            btn.MouseButton1Click:Connect(function()
                if not confirming then
                    confirming = true
                    btn.Text = "Are you sure?"
                    btn.TextColor3 = lib.Theme.Accent
                    task.delay(3, function()
                        if confirming then
                            confirming = false
                            btn.Text = btnText
                            btn.TextColor3 = lib.Theme.FontPrimary
                        end
                    end)
                    return
                end
                confirming = false
                btn.Text = btnText
                btn.TextColor3 = lib.Theme.FontPrimary
                onClick()
            end)
        else
            btn.MouseButton1Click:Connect(onClick)
        end
        return btn
    end

    -- Row 1: Save theme | Load theme
    local row1 = makeButtonRow("SaveLoadRow", right)

    makeSideBySideBtn("Save theme", 0, row1, function()
        local name = getgenv().Options.CustomThemeName and getgenv().Options.CustomThemeName.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Enter a theme name first", 2) end
            return
        end
        -- Check if theme already exists
        local existing = ThemeManager:_listCustomThemes()
        for _, n in ipairs(existing) do
            if n == name then
                if lib.Notify then lib:Notify("Theme already exists, use Overwrite", 2) end
                return
            end
        end
        if ThemeManager:SaveCustomTheme(name) then
            if lib.Notify then lib:Notify("Theme saved: " .. name, 2) end
            local newList = ThemeManager:_listCustomThemes()
            if getgenv().Options.CustomThemeList then
                getgenv().Options.CustomThemeList:SetValues(newList)
            end
        end
    end)

    makeSideBySideBtn("Load theme", 1, row1, function()
        local name = getgenv().Options.CustomThemeList and getgenv().Options.CustomThemeList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a custom theme first", 2) end
            return
        end
        if ThemeManager:LoadCustomTheme(name) then
            if lib.Notify then lib:Notify("Theme loaded: " .. name, 2) end
            local autoToggle = getgenv().Toggles.AutoLoadTheme
            if autoToggle then
                autoToggle:SetValueText(name)
                if autoToggle.Value then
                    ThemeManager:_saveAutoloadSilent(name)
                end
            end
        end
    end)

    -- Row 2: Overwrite theme | Delete theme
    local row2 = makeButtonRow("OverwriteDeleteRow", right)

    makeSideBySideBtn("Overwrite theme", 0, row2, function()
        local name = getgenv().Options.CustomThemeList and getgenv().Options.CustomThemeList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a custom theme first", 2) end
            return
        end
        if ThemeManager:SaveCustomTheme(name) then
            if lib.Notify then lib:Notify("Theme overwritten: " .. name, 2) end
        end
    end)

    makeSideBySideBtn("Delete theme", 1, row2, function()
        local name = getgenv().Options.CustomThemeList and getgenv().Options.CustomThemeList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a custom theme first", 2) end
            return
        end
        pcall(function()
            if typeof(delfile) == "function" then
                delfile(ThemeManager:_getThemesFolder() .. "/" .. name .. ".json")
            end
        end)
        if lib.Notify then lib:Notify("Theme deleted: " .. name, 2) end
        local newList = ThemeManager:_listCustomThemes()
        if getgenv().Options.CustomThemeList then
            getgenv().Options.CustomThemeList:SetValues(newList)
            if #newList == 0 then
                getgenv().Options.CustomThemeList:SetValue(nil)
            end
        end
    end, true)

    -- Row 3: Refresh list (full-width)
    right:AddButton({
        Text = "Refresh list",
        Func = function()
            local newList = ThemeManager:_listCustomThemes()
            if getgenv().Options.CustomThemeList then
                getgenv().Options.CustomThemeList:SetValues(newList)
                if #newList == 0 then
                    getgenv().Options.CustomThemeList:SetValue(nil)
                end
            end
            if lib.Notify then lib:Notify("Custom themes refreshed", 2) end
        end,
    })

    -- Set as autoload button + label
    right:AddButton({
        Text = "Set as autoload",
        Func = function()
            local themeName = ThemeManager._currentThemeName or "Default"
            ThemeManager:_saveAutoloadSilent(themeName)
            if lib.Notify then lib:Notify(string.format("Set %q to auto load", themeName)) end
            if ThemeManager.AutoloadLabel then
                ThemeManager.AutoloadLabel:SetText("Current autoload theme: " .. themeName)
            end
        end,
    })

    local currentAutoTheme = "none"
    pcall(function()
        if typeof(isfile) == "function" and isfile(ThemeManager:_getAutoloadPath()) then
            local content = readfile(ThemeManager:_getAutoloadPath())
            content = content:match("^%s*(.-)%s*$") or ""
            if content ~= "" then
                currentAutoTheme = content
            end
        end
    end)
    ThemeManager.AutoloadLabel = right:AddLabel("Current autoload theme: " .. currentAutoTheme, true)

    -- ── Menu toggles (added to existing Menu groupbox if provided) ──
    local menu = menuGroupbox or tab:AddLeftGroupbox("Menu")

    menu:AddToggle("ShowWatermark", {
        Text = "Show Watermark",
        Default = false,
    })

    getgenv().Toggles.ShowWatermark:OnChanged(function()
        lib:SetWatermarkVisibility(getgenv().Toggles.ShowWatermark.Value)
    end)

    menu:AddToggle("ShowKeybindFrame", {
        Text = "Show Keybind List",
        Default = false,
    })

    getgenv().Toggles.ShowKeybindFrame:OnChanged(function()
        if lib.KeybindFrame then
            lib.KeybindFrame.Visible = getgenv().Toggles.ShowKeybindFrame.Value
        end
    end)

    menu:AddDropdown("KeybindListFilter", {
        Values = {"Show All", "Active Only"},
        Default = 1,
        Text = "Keybind List Filter",
    })

    getgenv().Options.KeybindListFilter:OnChanged(function()
        lib._keybindFilterActive = (getgenv().Options.KeybindListFilter.Value == "Active Only")
    end)

    menu:AddDivider()
    menu:AddLabel("Debug")

    menu:AddToggle("GUILogs", {
        Text = "GUI Logs",
        Default = false,
    })

    getgenv().Toggles.GUILogs:OnChanged(function()
        lib.DebugLogs = getgenv().Toggles.GUILogs.Value
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

    getgenv().Options.ThemeSelector:OnChanged(function(val)
        ThemeManager:SetTheme(val)
    end)
end

function ThemeManager:_saveAutoloadSilent(themeName)
    self:_ensureFolders()
    local path = self:_getAutoloadPath()
    pcall(function()
        writefile(path, themeName)
    end)
end

function ThemeManager:SaveCurrentTheme()
    local themeName = self._currentThemeName or "Default"
    self:_saveAutoloadSilent(themeName)
    local lib = self.Library
    if lib and lib.Notify then
        lib:Notify("Auto-load saved: " .. themeName, 2)
    end
end

function ThemeManager:SaveDefault(theme)
    local path = self:_getDefaultThemePath()
    pcall(function()
        writefile(path, theme)
    end)
end

function ThemeManager:GetCustomTheme(name)
    if not name or name == "" then return nil end
    local folder = self:_getThemesFolder()
    local ok, content = pcall(function()
        return readfile(folder .. "/" .. name .. ".json")
    end)
    if not ok or not content then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or not data then return nil end
    return data
end

function ThemeManager:LoadDefault()
    local theme = "Default"
    local path = self:_getDefaultThemePath()
    local ok, content = pcall(function() return readfile(path) end)
    if ok and content then
        content = content:match("^%s*(.-)%s*$") or ""
        if content ~= "" then
            -- Check built-in themes first, then custom themes
            if self.BuiltInThemes[content] then
                theme = content
            else
                local customData = self:GetCustomTheme(content)
                if customData then
                    theme = content
                end
            end
        end
    end
    self:SetTheme(theme)
    return theme
end

function ThemeManager:LoadAutoloadTheme()
    task.defer(function()
        self:_ensureFolders()
        local path = self:_getAutoloadPath()
        local ok, content = pcall(function() return readfile(path) end)
        if not ok or not content then return end
        content = content:match("^%s*(.-)%s*$") or ""
        if content == "" then return end

        local lib = self.Library
        if lib and lib.Notify then
            lib:Notify("Auto-loading theme: " .. content, 2)
        end

        -- Set guard BEFORE any theme operations to prevent
        -- OnChanged callbacks from re-saving during load
        self._loadingAutoTheme = true

        -- Try built-in theme first
        if self.BuiltInThemes[content] then
            self:SetTheme(content)
            if getgenv().Options.ThemeSelector then
                getgenv().Options.ThemeSelector:SetValue(content)
            end
        else
            -- Try custom theme
            self:LoadCustomTheme(content)
        end

        -- Update the autoload label
        if ThemeManager.AutoloadLabel then
            ThemeManager.AutoloadLabel:SetText("Current autoload theme: " .. content)
        end

        self._loadingAutoTheme = false
    end)
end

return ThemeManager
