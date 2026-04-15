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
    return self.BaseFolder .. "/autoload_config.txt"
end

function SaveManager:SetAutoload(name)
    if typeof(writefile) ~= "function" then return end
    local path = self:_getAutoloadPath()
    pcall(function() writefile(path, name) end)
end

function SaveManager:GetAutoload()
    if typeof(readfile) ~= "function" then return nil end
    local path = self:_getAutoloadPath()
    local ok, content = pcall(readfile, path)
    if ok and content then
        content = content:match("^%s*(.-)%s*$") or ""
        if content ~= "" then return content end
    end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoload()
    if name then
        self:Load(name)
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

    right:AddButton({
        Text = "Save Config",
        Func = function()
            local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
            if name == "" then
                if lib.Notify then lib:Notify("Enter a config name first!", 2) end
                return
            end
            local ok = self:Save(name)
            if ok then
                if lib.Notify then lib:Notify("Config saved: " .. name, 2) end
                -- Refresh list
                local newConfigs = self:GetConfigs()
                if getgenv().Options.ConfigList then
                    getgenv().Options.ConfigList:SetValues(newConfigs)
                end
            end
        end,
    })

    right:AddButton({
        Text = "Load Config",
        Func = function()
            local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
            if name == "" then
                if lib.Notify then lib:Notify("Enter a config name first!", 2) end
                return
            end
            local ok = self:Load(name)
            if ok and lib.Notify then lib:Notify("Config loaded: " .. name, 2) end
            if not ok and lib.Notify then lib:Notify("Config not found: " .. name, 2) end
        end,
    })

    right:AddButton({
        Text = "Delete Config",
        Func = function()
            local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
            if name == "" then return end
            self:Delete(name)
            if lib.Notify then lib:Notify("Config deleted: " .. name, 2) end
            local newConfigs = self:GetConfigs()
            if getgenv().Options.ConfigList then
                getgenv().Options.ConfigList:SetValues(newConfigs)
            end
        end,
        DoubleClick = true,
    })

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

    right:AddToggle("AutoloadEnabled", {
        Text = "Auto-load Config",
        Default = self:GetAutoload() ~= nil,
    })

    getgenv().Toggles.AutoloadEnabled:OnChanged(function()
        local val = getgenv().Toggles.AutoloadEnabled.Value
        if val then
            local name = getgenv().Options.ConfigName and getgenv().Options.ConfigName.Value or ""
            if name ~= "" then
                self:SetAutoload(name)
                if lib.Notify then lib:Notify("Autoload set: " .. name, 2) end
            end
        else
            pcall(function()
                if typeof(delfile) == "function" then
                    delfile(self:_getAutoloadPath())
                end
            end)
        end
    end)
end

return SaveManager
