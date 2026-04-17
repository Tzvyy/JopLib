--[[
    JopLib - UI Library for Roblox
    SaveManager.lua - Config save/load system using writefile/readfile
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Library = nil
SaveManager.Folder = "JopLib/configs"
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
    self.IgnoreIndexes["KeybindListFilter"] = true
    self.IgnoreIndexes["CustomThemeName"] = true
    self.IgnoreIndexes["CustomThemeList"] = true
    self.IgnoreIndexes["GUILogs"] = true
    self.IgnoreIndexes["ShowWatermark"] = true
    self.IgnoreIndexes["ShowKeybindFrame"] = true
    -- Color picker flags are numbered 1-6 (matching ThemeManager:ApplyToTab)
    for i = 1, 6 do
        self.IgnoreIndexes["ThemeColor_" .. i] = true
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
    local flags = self.Library and self.Library.Flags or {}

    for flag, obj in pairs(flags) do
        if self.IgnoreIndexes[flag] then continue end
        local t = obj.Type

        if t == "Toggle" then
            data[flag] = { type = "Toggle", value = obj.Value }
        elseif t == "Slider" then
            data[flag] = { type = "Slider", value = obj.Value }
        elseif t == "Dropdown" then
            if obj.Multi then
                local selected = {}
                for k, v in pairs(obj.Value) do
                    if v then selected[#selected + 1] = k end
                end
                data[flag] = { type = "Dropdown", value = selected, multi = true }
            else
                data[flag] = { type = "Dropdown", value = obj.Value }
            end
        elseif t == "Input" then
            data[flag] = { type = "Input", value = obj.Value }
        elseif t == "KeyPicker" then
            data[flag] = { type = "KeyPicker", value = obj.Value, mode = obj.Mode }
        elseif t == "ColorPicker" then
            local c = obj.Value
            data[flag] = {
                type = "ColorPicker",
                value = { R = math.floor(c.R * 255), G = math.floor(c.G * 255), B = math.floor(c.B * 255) },
                transparency = obj.Transparency,
            }
        end
    end

    return data
end

function SaveManager:_deserialize(data)
    local flags = self.Library and self.Library.Flags or {}

    for flag, entry in pairs(data) do
        if self.IgnoreIndexes[flag] then continue end
        local obj = flags[flag]
        if not obj then continue end

        local t = entry.type
        if t == "Toggle" or t == "Slider" or t == "Input" then
            pcall(obj.SetValue, obj, entry.value)
        elseif t == "Dropdown" then
            if entry.multi then
                local val = {}
                for _, k in ipairs(entry.value) do val[k] = true end
                pcall(obj.SetValue, obj, val)
            else
                pcall(obj.SetValue, obj, entry.value)
            end
        elseif t == "KeyPicker" then
            pcall(obj.SetValue, obj, {entry.value, entry.mode})
        elseif t == "ColorPicker" then
            local c = entry.value
            if c then
                pcall(obj.SetValue, obj,
                    Color3.fromRGB(c.R or 255, c.G or 255, c.B or 255),
                    entry.transparency
                )
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
        Placeholder = "Enter config name...",
    })

    local configs = self:GetConfigs()
    right:AddDropdown("ConfigList", {
        Text = "Saved Configs",
        Values = configs,
        Default = configs[1],
    })

    lib.Flags.ConfigList:OnChanged(function()
        local val = lib.Flags.ConfigList.Value
        if val and lib.Flags.ConfigName then
            lib.Flags.ConfigName:SetValue(val)
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

    -- Row 1: Save config | Load config
    local row1 = makeButtonRow("SaveLoadRow", right)

    makeSideBySideBtn("Save config", 0, row1, function()
        local name = lib.Flags.ConfigName and lib.Flags.ConfigName.Value or ""
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
            if lib.Flags.ConfigList then
                lib.Flags.ConfigList:SetValues(newConfigs)
            end
        end
    end)

    makeSideBySideBtn("Load config", 1, row1, function()
        local name = lib.Flags.ConfigName and lib.Flags.ConfigName.Value or ""
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
        local name = lib.Flags.ConfigList and lib.Flags.ConfigList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a config first", 2) end
            return
        end
        local ok = self:Save(name)
        if ok and lib.Notify then lib:Notify("Config overwritten: " .. name, 2) end
    end)

    makeSideBySideBtn("Delete config", 1, row2, function()
        local name = lib.Flags.ConfigList and lib.Flags.ConfigList.Value or ""
        if name == "" then
            if lib.Notify then lib:Notify("Select a config first", 2) end
            return
        end
        self:Delete(name)
        if lib.Notify then lib:Notify("Config deleted: " .. name, 2) end
        local newConfigs = self:GetConfigs()
        if lib.Flags.ConfigList then
            lib.Flags.ConfigList:SetValues(newConfigs)
            if #newConfigs == 0 then
                lib.Flags.ConfigList:SetValue(nil)
            end
        end
    end, true)

    -- Row 3: Refresh list (full-width)
    right:AddButton({
        Text = "Refresh list",
        Func = function()
            local newConfigs = self:GetConfigs()
            if lib.Flags.ConfigList then
                lib.Flags.ConfigList:SetValues(newConfigs)
                if #newConfigs == 0 then
                    lib.Flags.ConfigList:SetValue(nil)
                end
            end
            if lib.Notify then lib:Notify("Found " .. #newConfigs .. " configs", 2) end
        end,
    })

    -- Set as autoload button + label (LinoriaLib style)
    right:AddButton({
        Text = "Set as autoload",
        Func = function()
            local name = lib.Flags.ConfigList and lib.Flags.ConfigList.Value or ""
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
