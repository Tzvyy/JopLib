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

    self._currentThemeName = name

    for key, color in pairs(theme) do
        lib.Theme[key] = color
    end
    lib.AccentColor = theme.Accent

    self:_applyThemeToGui()

    -- Update color picker previews to match theme
    self:_syncColorPickers()

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
            elseif name == "TitleBar" then
                desc.BackgroundColor3 = theme.Background
            elseif name == "BottomCover" then
                desc.BackgroundColor3 = theme.Background
            elseif name == "AccentLine" or name == "AccentBar" then
                desc.BackgroundColor3 = theme.Accent
            elseif name == "TabBarContainer" then
                desc.BackgroundColor3 = theme.TabBackground
            elseif name:find("Groupbox_") or name == "Tabbox" then
                desc.BackgroundColor3 = theme.GroupboxBg
            elseif name == "Fill" then
                desc.BackgroundColor3 = theme.SliderFill
            elseif name == "Box" and desc.Parent and desc.Parent.Name:find("^Toggle_") then
                local flag = desc.Parent.Name:sub(8)
                local tog = getgenv().Toggles and getgenv().Toggles[flag]
                if tog then
                    desc.BackgroundColor3 = tog.Value and theme.ToggleOn or theme.ToggleOff
                end
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
            elseif name:find("^Tab_") then
                -- Main tabs (Tab_Main, Tab_UI Settings, etc.)
                local isActive = desc.BackgroundColor3 ~= theme.TabInactive
                desc.BackgroundColor3 = theme.TabActive
            elseif name:find("^TBTab_") then
                -- Tabbox sub-tabs
                desc.BackgroundColor3 = theme.TabActive
            elseif name == "DropBtn" then
                desc.BackgroundColor3 = theme.ElementBg
            elseif name == "KeyBtn" then
                desc.BackgroundColor3 = theme.ElementBg
            end
        end

        if desc:IsA("ScrollingFrame") then
            if name == "LeftColumn" or name == "RightColumn" then
                desc.ScrollBarImageColor3 = theme.Accent
            end
        end
    end
end

function ThemeManager:_getBaseFolder()
    return "JopLib"
end

function ThemeManager:_getThemesFolder()
    return self:_getBaseFolder() .. "/themes"
end

function ThemeManager:_getAutoloadPath()
    return self:_getThemesFolder() .. "/autoload_theme.txt"
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
    self:_applyThemeToGui()
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
        -- Skip saving if we're in the middle of loading autoload theme
        if ThemeManager._loadingAutoTheme then return end
        local autoToggle = getgenv().Toggles.AutoLoadTheme
        if autoToggle then
            -- Always update the display text
            autoToggle:SetValueText(val)
            if autoToggle.Value then
                -- Save the new theme as autoload
                ThemeManager:_saveAutoloadSilent(val)
            end
        end
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
            ThemeManager:_applyThemeToGui()
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

    local function makeSideBySideBtn(btnText, layoutOrder, parent, onClick)
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
        btn.MouseButton1Click:Connect(onClick)
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
        end
    end)

    -- Row 3: Refresh list (full-width)
    right:AddButton({
        Text = "Refresh list",
        Func = function()
            local newList = ThemeManager:_listCustomThemes()
            if getgenv().Options.CustomThemeList then
                getgenv().Options.CustomThemeList:SetValues(newList)
            end
            if lib.Notify then lib:Notify("Custom themes refreshed", 2) end
        end,
    })

    right:AddDivider()

    -- Auto-load theme toggle
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

    right:AddToggle("AutoLoadTheme", {
        Text = "Auto-load Theme",
        Default = false,
    })

    -- Show the saved theme name next to the toggle
    if currentAutoTheme ~= "none" and getgenv().Toggles.AutoLoadTheme then
        getgenv().Toggles.AutoLoadTheme:SetValueText(currentAutoTheme)
    end

    getgenv().Toggles.AutoLoadTheme:OnChanged(function()
        -- Skip if we're in the middle of loading autoload theme
        if ThemeManager._loadingAutoTheme then return end

        if getgenv().Toggles.AutoLoadTheme.Value then
            -- Enabling auto-load: save current theme
            local themeName = ThemeManager._currentThemeName or "Default"
            ThemeManager:_saveAutoloadSilent(themeName)
            getgenv().Toggles.AutoLoadTheme:SetValueText(themeName)
            if lib.Notify then lib:Notify(string.format("Auto-load theme set to %q", themeName)) end
        else
            -- Disabling auto-load: delete the autoload file
            pcall(function()
                if typeof(delfile) == "function" then
                    delfile(ThemeManager:_getAutoloadPath())
                end
            end)
            getgenv().Toggles.AutoLoadTheme:SetValueText("")
            if lib.Notify then lib:Notify("Auto-load theme disabled") end
        end
    end)

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

        -- Enable the toggle (guard prevents OnChanged from re-saving)
        if getgenv().Toggles.AutoLoadTheme then
            getgenv().Toggles.AutoLoadTheme:SetValue(true)
            getgenv().Toggles.AutoLoadTheme:SetValueText(content)
        end

        self._loadingAutoTheme = false
    end)
end

return ThemeManager
