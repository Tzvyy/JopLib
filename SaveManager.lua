--[[
    JopLib - UI Library for Roblox
    SaveManager.lua - Config save/load system using writefile/readfile
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Library = nil
SaveManager.Folder = "JopLib/settings"
SaveManager.BaseFolder = "JopLib"
SaveManager.IgnoreIndexes = {}
SaveManager.IgnoreTheme = false

-- ============================================================
-- METHODS
-- ============================================================

function SaveManager:SetLibrary(lib)
    self.Library = lib
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
end

function SaveManager:SetIgnoreIndexes(indexes)
    for _, idx in ipairs(indexes) do
        self.IgnoreIndexes[idx] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    self.IgnoreTheme = true
    self.IgnoreIndexes["ThemeSelector"] = true
    self.IgnoreIndexes["AutoLoadTheme"] = true
    self.IgnoreIndexes["ShowWatermark"] = true
    self.IgnoreIndexes["ShowKeybindFrame"] = true
    for key, _ in pairs(self.Library and self.Library.Theme or {}) do
        self.IgnoreIndexes["ThemeColor_" .. key] = true
    end
end

function SaveManager:_ensureFolder()
    if typeof(isfolder) ~= "function" then return false end
    -- Create parent folders recursively
    local parts = self.Folder:split("/")
    local path = ""
    for _, part in ipairs(parts) do
        path = path == "" and part or (path .. "/" .. part)
        if not isfolder(path) then
            makefolder(path)
        end
    end
    return true
end

function SaveManager:_ensureBaseFolder()
    if typeof(isfolder) ~= "function" then return false end
    if not isfolder("JopLib") then makefolder("JopLib") end
    return true
end

-- ============================================================
-- SERIALIZE / DESERIALIZE
-- ============================================================

function SaveManager:_serialize()
    local data = {}

    local toggles = getgenv().Toggles or {}
    local options = getgenv().Options or {}

    for flag, toggle in pairs(toggles) do
        if self.IgnoreIndexes[flag] then continue end
        if toggle.Type == "Toggle" then
            data[flag] = { type = "Toggle", value = toggle.Value }
        end
    end

    for flag, option in pairs(options) do
        if self.IgnoreIndexes[flag] then continue end

        if option.Type == "Slider" then
            data[flag] = { type = "Slider", value = option.Value }

        elseif option.Type == "Dropdown" then
            if option.Multi then
                local selected = {}
                for k, v in pairs(option.Value) do
                    if v then table.insert(selected, k) end
                end
                data[flag] = { type = "Dropdown", value = selected, multi = true }
            else
                data[flag] = { type = "Dropdown", value = option.Value }
            end

        elseif option.Type == "Input" then
            data[flag] = { type = "Input", value = option.Value }

        elseif option.Type == "KeyPicker" then
            data[flag] = { type = "KeyPicker", value = option.Value, mode = option.Mode }

        elseif option.Type == "ColorPicker" then
            local c = option.Value
            data[flag] = {
                type = "ColorPicker",
                value = { R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255) },
                transparency = option.Transparency,
            }
        end
    end

    return data
end

function SaveManager:_deserialize(data)
    local toggles = getgenv().Toggles or {}
    local options = getgenv().Options or {}

    for flag, entry in pairs(data) do
        if self.IgnoreIndexes[flag] then continue end

        if entry.type == "Toggle" and toggles[flag] then
            pcall(function() toggles[flag]:SetValue(entry.value) end)

        elseif entry.type == "Slider" and options[flag] then
            pcall(function() options[flag]:SetValue(entry.value) end)

        elseif entry.type == "Dropdown" and options[flag] then
            if entry.multi then
                local val = {}
                for _, k in ipairs(entry.value) do val[k] = true end
                pcall(function() options[flag]:SetValue(val) end)
            else
                pcall(function() options[flag]:SetValue(entry.value) end)
            end

        elseif entry.type == "Input" and options[flag] then
            pcall(function() options[flag]:SetValue(entry.value) end)

        elseif entry.type == "KeyPicker" and options[flag] then
            pcall(function() options[flag]:SetValue({entry.value, entry.mode}) end)

        elseif entry.type == "ColorPicker" and options[flag] then
            local c = entry.value
            if c then
                pcall(function()
                    options[flag]:SetValue(
                        Color3.fromRGB(c.R or 255, c.G or 255, c.B or 255),
                        entry.transparency
                    )
                end)
            end
        end
    end
end

-- ============================================================
-- FILE OPERATIONS
-- ============================================================

function SaveManager:Save(name)
    if not self:_ensureFolder() then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    local data = self:_serialize()
    local json = HttpService:JSONEncode(data)
    writefile(path, json)
    return true
end

function SaveManager:Load(name)
    if typeof(readfile) ~= "function" then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    local ok, content = pcall(readfile, path)
    if not ok or not content then return false end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not ok2 or not data then return false end
    self:_deserialize(data)
    return true
end

function SaveManager:Delete(name)
    if typeof(delfile) ~= "function" then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    pcall(delfile, path)
    return true
end

function SaveManager:GetConfigs()
    if typeof(listfiles) ~= "function" then return {} end
    self:_ensureFolder()
    local ok, files = pcall(listfiles, self.Folder)
    if not ok then return {} end
    local configs = {}
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            table.insert(configs, name)
        end
    end
    return configs
end

function SaveManager:_getAutoloadPath()
    return self.Folder .. "/autoload.txt"
end

function SaveManager:LoadAutoloadConfig()
    if isfile(self:_getAutoloadPath()) then
        local name = readfile(self:_getAutoloadPath())
        name = name:match("^%s*(.-)%s*$") or ""

        if name ~= "" then
            local success, err = self:Load(name)
            if not success then
                return self.Library:Notify("Failed to load autoload config: " .. tostring(err))
            end
            self.Library:Notify(string.format("Auto loaded config %q", name))
        end
    end
end

-- ============================================================
-- BUILD CONFIG UI SECTION
-- ============================================================

function SaveManager:BuildConfigSection(tab)
    local lib = self.Library
    if not lib then return end

    local right = tab:AddLeftGroupbox("Config")

    right:AddInput("ConfigName", {
        Text = "Config Name",
        Default = "",
        Placeholder = "my_config",
    })

    local configs = self:GetConfigs()
    right:AddDropdown("ConfigList", {
        Text = "Saved Configs",
        Values = configs,
        Default = configs[1],
    })

    getgenv().Options.ConfigList:OnChanged(function()
        local val = getgenv().Options.ConfigList.Value
        if val and getgenv().Options.ConfigName then
            getgenv().Options.ConfigName:SetValue(val)
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

    -- Row 1: Save config | Load config
    local row1 = makeButtonRow("SaveLoadRow", right)

    makeSideBySideBtn("Save config", 0, row1, function()
        local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Enter a config name first!", 2) end
            return
        end
        -- Check if config already exists
        local existing = self:GetConfigs()
        for _, n in ipairs(existing) do
            if n == name then
                if lib.Notify then lib:Notify("Config already exists, use Overwrite", 2) end
                return
            end
        end
        local ok = self:Save(name)
        if ok then
            if lib.Notify then lib:Notify("Config saved: " .. name, 2) end
            local newConfigs = self:GetConfigs()
            if getgenv().Options.ConfigList then
                getgenv().Options.ConfigList:SetValues(newConfigs)
            end
        end
    end)

    makeSideBySideBtn("Load config", 1, row1, function()
        local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Enter a config name first!", 2) end
            return
        end
        local ok = self:Load(name)
        if ok and lib.Notify then lib:Notify("Config loaded: " .. name, 2) end
        if not ok and lib.Notify then lib:Notify("Config not found: " .. name, 2) end
    end)

    -- Row 2: Overwrite config | Delete config
    local row2 = makeButtonRow("OverwriteDeleteRow", right)

    makeSideBySideBtn("Overwrite config", 0, row2, function()
        local name = getgenv().Options.ConfigList and getgenv().Options.ConfigList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a config first", 2) end
            return
        end
        local ok = self:Save(name)
        if ok and lib.Notify then lib:Notify("Config overwritten: " .. name, 2) end
    end)

    makeSideBySideBtn("Delete config", 1, row2, function()
        local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
        if name == "" then return end
        self:Delete(name)
        if lib.Notify then lib:Notify("Config deleted: " .. name, 2) end
        local newConfigs = self:GetConfigs()
        if getgenv().Options.ConfigList then
            getgenv().Options.ConfigList:SetValues(newConfigs)
        end
    end)

    -- Row 3: Refresh list (full-width)
    right:AddButton({
        Text = "Refresh list",
        Func = function()
            local newConfigs = self:GetConfigs()
            if getgenv().Options.ConfigList then
                getgenv().Options.ConfigList:SetValues(newConfigs)
            end
            if lib.Notify then lib:Notify("Found " .. #newConfigs .. " configs", 2) end
        end,
    })

    right:AddDivider()

    -- Set as autoload button + label (LinoriaLib style)
    right:AddButton({
        Text = "Set as autoload",
        Func = function()
            local name = getgenv().Options.ConfigList and getgenv().Options.ConfigList.Value or ""
            if name == "" then
                if lib.Notify then lib:Notify("Select a config first", 2) end
                return
            end
            writefile(self:_getAutoloadPath(), name)
            if lib.Notify then lib:Notify(string.format("Set %q to auto load", name)) end
            -- Update label
            if SaveManager.AutoloadLabel then
                SaveManager.AutoloadLabel:SetText("Current autoload config: " .. name)
            end
        end,
    })

    -- Show current autoload status
    local autoloadName = "none"
    if isfile(self:_getAutoloadPath()) then
        local ok, content = pcall(function() return readfile(self:_getAutoloadPath()) end)
        if ok and content then
            content = content:match("^%s*(.-)%s*$") or ""
            if content ~= "" then
                autoloadName = content
            end
        end
    end
    SaveManager.AutoloadLabel = right:AddLabel("Current autoload config: " .. autoloadName, true)
end

return SaveManager
