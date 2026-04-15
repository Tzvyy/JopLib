--[[
    JopLib - UI Library for Roblox
    Elements.lua - Toggle, Slider, Button, Dropdown, TextInput, Label, Divider,
                   KeyPicker, ColorPicker, DependencyBox
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ============================================================
-- UTILITY
-- ============================================================

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Tween(inst, props, duration)
    duration = duration or 0.15
    return TweenService:Create(inst, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

-- ============================================================
-- SETUP: Inject methods into Groupbox
-- Called once to wire up Library reference
-- ============================================================

local Elements = {}

function Elements:Setup(Library)
    self.Library = Library

    local Groupbox = {}

    -- ============================================================
    -- TOGGLE
    -- ============================================================

    function Groupbox.AddToggle(self, flag, options)
        options = options or {}
        local lib = Elements.Library
        local order = self:_nextOrder()

        local default = options.Default or false
        local text = options.Text or flag
        local callback = options.Callback

        local toggleObj = {
            Value = default,
            Flag = flag,
            Type = "Toggle",
            _callbacks = {},
        }

        function toggleObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function toggleObj:SetValue(val)
            self.Value = val
            -- Update visual
            if self._checkmark then
                self._checkmark.Visible = val
            end
            if self._box then
                Tween(self._box, {BackgroundColor3 = val and lib.Theme.ToggleOn or lib.Theme.ToggleOff}, 0.15):Play()
            end
            -- Fire callbacks
            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, val)
            end
            if callback then
                task.spawn(callback, val)
            end
        end

        -- UI
        local container = Create("Frame", {
            Name = "Toggle_" .. flag,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        local box = Create("Frame", {
            Name = "Box",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = default and lib.Theme.ToggleOn or lib.Theme.ToggleOff,
            BorderSizePixel = 0,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        local checkmark = Create("TextLabel", {
            Name = "Checkmark",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✓",
            TextColor3 = Color3.new(1, 1, 1),
            FontFace = lib.FontBold,
            TextSize = 12,
            Visible = default,
            Parent = box,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 22, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        toggleObj._box = box
        toggleObj._checkmark = checkmark
        toggleObj._container = container

        -- Click handler
        local btn = Create("TextButton", {
            Name = "ClickArea",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = container,
        })

        btn.MouseButton1Click:Connect(function()
            toggleObj:SetValue(not toggleObj.Value)
        end)

        -- Register
        getgenv().Toggles[flag] = toggleObj
        lib.Flags[flag] = toggleObj

        -- Return toggle so :AddKeyPicker / :AddColorPicker can chain
        return toggleObj
    end

    -- ============================================================
    -- SLIDER
    -- ============================================================

    function Groupbox.AddSlider(self, flag, options)
        options = options or {}
        local lib = Elements.Library
        local order = self:_nextOrder()

        local min = options.Min or 0
        local max = options.Max or 100
        local default = options.Default or min
        local rounding = options.Rounding or 0
        local suffix = options.Suffix or ""
        local text = options.Text or flag
        local callback = options.Callback

        local function round(val)
            if rounding == 0 then
                return math.floor(val + 0.5)
            end
            local mult = 10 ^ rounding
            return math.floor(val * mult + 0.5) / mult
        end

        default = math.clamp(default, min, max)
        default = round(default)

        local sliderObj = {
            Value = default,
            Flag = flag,
            Type = "Slider",
            Min = min,
            Max = max,
            _callbacks = {},
        }

        function sliderObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function sliderObj:SetValue(val)
            val = math.clamp(val, min, max)
            val = round(val)
            self.Value = val

            -- Update visual
            local pct = (val - min) / (max - min)
            if self._fill then
                Tween(self._fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1):Play()
            end
            if self._valueLabel then
                self._valueLabel.Text = tostring(val) .. suffix
            end

            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, val)
            end
            if callback then
                task.spawn(callback, val)
            end
        end

        -- UI
        local container = Create("Frame", {
            Name = "Slider_" .. flag,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0.6, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        local valueLabel = Create("TextLabel", {
            Name = "Value",
            Size = UDim2.new(0.4, 0, 0, 16),
            Position = UDim2.new(0.6, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(default) .. suffix,
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = container,
        })

        local sliderBg = Create("Frame", {
            Name = "SliderBg",
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 20),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        local pct = (default - min) / (max - min)
        local fill = Create("Frame", {
            Name = "Fill",
            Size = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = lib.Theme.SliderFill,
            BorderSizePixel = 0,
            Parent = sliderBg,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        })

        sliderObj._fill = fill
        sliderObj._valueLabel = valueLabel

        -- Drag logic
        local dragging = false

        local inputBtn = Create("TextButton", {
            Name = "InputArea",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = sliderBg,
        })

        local function updateFromInput(inputX)
            local absPos = sliderBg.AbsolutePosition.X
            local absSize = sliderBg.AbsoluteSize.X
            local relX = math.clamp((inputX - absPos) / absSize, 0, 1)
            local val = min + (max - min) * relX
            sliderObj:SetValue(val)
        end

        inputBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input.Position.X)
            end
        end)

        inputBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local moveConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input.Position.X)
            end
        end)
        table.insert(lib.Connections, moveConn)

        -- Register
        getgenv().Options[flag] = sliderObj
        lib.Flags[flag] = sliderObj

        return sliderObj
    end

    -- ============================================================
    -- BUTTON
    -- ============================================================

    function Groupbox.AddButton(self, text, callback, options)
        options = options or {}
        local lib = Elements.Library
        local order = self:_nextOrder()

        local doubleConfirm = options.DoubleConfirm or false

        local container = Create("Frame", {
            Name = "Button_" .. text,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        local btn = Create("TextButton", {
            Name = "Btn",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontSemiBold,
            TextSize = 13,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        local confirming = false

        btn.MouseButton1Click:Connect(function()
            if doubleConfirm and not confirming then
                confirming = true
                btn.Text = "Click again to confirm"
                btn.TextColor3 = Color3.fromRGB(255, 200, 50)
                task.delay(3, function()
                    if confirming then
                        confirming = false
                        btn.Text = text
                        btn.TextColor3 = lib.Theme.FontPrimary
                    end
                end)
                return
            end
            confirming = false
            btn.Text = text
            btn.TextColor3 = lib.Theme.FontPrimary
            if callback then
                task.spawn(callback)
            end
        end)

        -- Hover effect
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = Color3.fromRGB(
                math.min(255, lib.Theme.ElementBg.R * 255 + 12) / 255,
                math.min(255, lib.Theme.ElementBg.G * 255 + 12) / 255,
                math.min(255, lib.Theme.ElementBg.B * 255 + 12) / 255
            )}, 0.1):Play()
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = lib.Theme.ElementBg}, 0.1):Play()
        end)

        return container
    end

    -- ============================================================
    -- DROPDOWN
    -- ============================================================

    function Groupbox.AddDropdown(self, flag, options)
        options = options or {}
        local lib = Elements.Library
        local order = self:_nextOrder()

        local values = options.Values or {}
        local text = options.Text or flag
        local multi = options.Multi or false
        local callback = options.Callback
        local default = options.Default

        -- Resolve default
        local currentValue
        if multi then
            currentValue = {}
            if type(default) == "table" then
                for _, v in ipairs(default) do currentValue[v] = true end
            end
        else
            if type(default) == "number" then
                currentValue = values[default] or values[1]
            elseif type(default) == "string" then
                currentValue = default
            else
                currentValue = values[1]
            end
        end

        local dropObj = {
            Value = currentValue,
            Flag = flag,
            Type = "Dropdown",
            Values = values,
            Multi = multi,
            _callbacks = {},
        }

        function dropObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        local function getDisplayText()
            if multi then
                local selected = {}
                for _, v in ipairs(values) do
                    if dropObj.Value[v] then
                        table.insert(selected, v)
                    end
                end
                if #selected == 0 then return "None" end
                return table.concat(selected, ", ")
            else
                return tostring(dropObj.Value or "None")
            end
        end

        function dropObj:SetValue(val)
            self.Value = val
            if self._displayLabel then
                self._displayLabel.Text = getDisplayText()
            end
            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, val)
            end
            if callback then
                task.spawn(callback, val)
            end
        end

        function dropObj:SetValues(newValues)
            values = newValues
            self.Values = newValues
            -- Rebuild dropdown items
            if self._rebuildItems then
                self:_rebuildItems()
            end
        end

        -- UI
        local container = Create("Frame", {
            Name = "Dropdown_" .. flag,
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            ClipsDescendants = false,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        local dropBtn = Create("TextButton", {
            Name = "DropBtn",
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = "",
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        local displayLabel = Create("TextLabel", {
            Name = "Display",
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Text = getDisplayText(),
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = dropBtn,
        })

        local arrow = Create("TextLabel", {
            Name = "Arrow",
            Size = UDim2.new(0, 16, 1, 0),
            Position = UDim2.new(1, -20, 0, 0),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 10,
            Parent = dropBtn,
        })

        dropObj._displayLabel = displayLabel

        -- Dropdown list (rendered above with high ZIndex)
        local open = false
        local maxVisible = 6
        local itemHeight = 22

        local dropList = Create("ScrollingFrame", {
            Name = "DropList",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 42),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 50,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = lib.Theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ClipsDescendants = true,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            }),
        })

        local function buildItems()
            -- Clear existing items
            for _, child in ipairs(dropList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            for i, val in ipairs(values) do
                local isSelected = multi and dropObj.Value[val] or (dropObj.Value == val)

                local item = Create("TextButton", {
                    Name = "Item_" .. val,
                    Size = UDim2.new(1, 0, 0, itemHeight),
                    BackgroundColor3 = isSelected and lib.Theme.Accent or lib.Theme.ElementBg,
                    BackgroundTransparency = isSelected and 0.7 or 0,
                    BorderSizePixel = 0,
                    Text = val,
                    TextColor3 = isSelected and lib.Theme.FontPrimary or lib.Theme.FontSecondary,
                    FontFace = lib.FontRegular,
                    TextSize = 12,
                    LayoutOrder = i,
                    ZIndex = 51,
                    Parent = dropList,
                })

                item.MouseButton1Click:Connect(function()
                    if multi then
                        dropObj.Value[val] = not dropObj.Value[val]
                        dropObj:SetValue(dropObj.Value)
                        -- Update item visual
                        local sel = dropObj.Value[val]
                        item.BackgroundTransparency = sel and 0.7 or 0
                        item.BackgroundColor3 = sel and lib.Theme.Accent or lib.Theme.ElementBg
                        item.TextColor3 = sel and lib.Theme.FontPrimary or lib.Theme.FontSecondary
                    else
                        dropObj:SetValue(val)
                        -- Close dropdown
                        open = false
                        Tween(dropList, {Size = UDim2.new(1, 0, 0, 0)}, 0.15):Play()
                        task.delay(0.15, function() dropList.Visible = false end)
                        arrow.Text = "▼"
                    end
                end)

                item.MouseEnter:Connect(function()
                    if not (multi and dropObj.Value[val]) and dropObj.Value ~= val then
                        Tween(item, {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}, 0.1):Play()
                    end
                end)
                item.MouseLeave:Connect(function()
                    local sel = multi and dropObj.Value[val] or (dropObj.Value == val)
                    Tween(item, {BackgroundColor3 = sel and lib.Theme.Accent or lib.Theme.ElementBg}, 0.1):Play()
                    item.BackgroundTransparency = sel and 0.7 or 0
                end)
            end
        end

        dropObj._rebuildItems = buildItems
        buildItems()

        -- Toggle dropdown
        dropBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                dropList.Visible = true
                local listHeight = math.min(#values, maxVisible) * itemHeight
                Tween(dropList, {Size = UDim2.new(1, 0, 0, listHeight)}, 0.15):Play()
                arrow.Text = "▲"
            else
                Tween(dropList, {Size = UDim2.new(1, 0, 0, 0)}, 0.15):Play()
                task.delay(0.15, function() dropList.Visible = false end)
                arrow.Text = "▼"
            end
        end)

        -- Register
        getgenv().Options[flag] = dropObj
        lib.Flags[flag] = dropObj

        return dropObj
    end

    -- ============================================================
    -- TEXT INPUT
    -- ============================================================

    function Groupbox.AddInput(self, flag, options)
        options = options or {}
        local lib = Elements.Library
        local order = self:_nextOrder()

        local text = options.Text or flag
        local default = options.Default or ""
        local placeholder = options.Placeholder or ""
        local numeric = options.Numeric or false
        local finished = options.Finished ~= false
        local callback = options.Callback

        local inputObj = {
            Value = default,
            Flag = flag,
            Type = "Input",
            _callbacks = {},
        }

        function inputObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function inputObj:SetValue(val)
            self.Value = val
            if self._textBox then
                self._textBox.Text = tostring(val)
            end
            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, val)
            end
            if callback then
                task.spawn(callback, val)
            end
        end

        -- UI
        local container = Create("Frame", {
            Name = "Input_" .. flag,
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        local textBox = Create("TextBox", {
            Name = "TextBox",
            Size = UDim2.new(1, 0, 0, 22),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = tostring(default),
            PlaceholderText = placeholder,
            PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            ClearTextOnFocus = false,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
            }),
        })

        inputObj._textBox = textBox

        local function processInput(txt)
            if numeric then
                local num = tonumber(txt)
                if num then
                    inputObj:SetValue(num)
                else
                    textBox.Text = tostring(inputObj.Value)
                end
            else
                inputObj:SetValue(txt)
            end
        end

        if finished then
            textBox.FocusLost:Connect(function(enterPressed)
                processInput(textBox.Text)
            end)
        else
            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                processInput(textBox.Text)
            end)
        end

        -- Register
        getgenv().Options[flag] = inputObj
        lib.Flags[flag] = inputObj

        return inputObj
    end

    -- ============================================================
    -- LABEL
    -- ============================================================

    function Groupbox.AddLabel(self, text)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local labelObj = {}

        local label = Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order,
            Parent = self._container,
        })

        labelObj._label = label
        labelObj._container = label

        function labelObj:SetText(newText)
            label.Text = newText
        end

        -- Allow chaining :AddColorPicker / :AddKeyPicker onto a label
        function labelObj:AddColorPicker(flag, options)
            return Groupbox._addColorPickerToContainer(self._container, flag, options, lib, order)
        end

        function labelObj:AddKeyPicker(flag, options)
            return Groupbox._addKeyPickerToContainer(self._container, flag, options, lib, order)
        end

        return labelObj
    end

    -- ============================================================
    -- DIVIDER
    -- ============================================================

    function Groupbox.AddDivider(self)
        local lib = Elements.Library
        local order = self:_nextOrder()

        Create("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 9),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        }, {
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = lib.Theme.Border,
                BorderSizePixel = 0,
            }),
        })
    end

    -- ============================================================
    -- KEYPICKER (Keybind)
    -- ============================================================

    -- Standalone method (can be called on toggle or label)
    function Groupbox._addKeyPickerToContainer(container, flag, options, lib, order)
        options = options or {}
        local default = options.Default or "None"
        local text = options.Text or flag
        local noUI = options.NoUI or false
        local mode = options.Mode or "Toggle"
        local syncToggle = options.SyncToggleState

        local kpObj = {
            Value = default,
            Flag = flag,
            Type = "KeyPicker",
            Mode = mode,
            _isActive = false,
            _callbacks = {},
        }

        function kpObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function kpObj:GetState()
            if self.Mode == "Always" then
                return true
            elseif self.Mode == "Hold" then
                return self._isActive
            else -- Toggle
                return self._isActive
            end
        end

        function kpObj:SetValue(key, newMode)
            if key then self.Value = key end
            if newMode then self.Mode = newMode end
            if self._keyLabel then
                self._keyLabel.Text = "[" .. self.Value .. "]"
            end
            if self._modeLabel then
                self._modeLabel.Text = self.Mode
            end
            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, self.Value)
            end
        end

        -- UI: small keybind button on the right side of the container
        local kpFrame = Create("Frame", {
            Name = "KeyPicker_" .. flag,
            Size = UDim2.new(0, 80, 0, 22),
            Position = UDim2.new(1, -80, 0, 0),
            BackgroundTransparency = 1,
            Parent = container,
        })

        local keyBtn = Create("TextButton", {
            Name = "KeyBtn",
            Size = UDim2.new(0, 48, 0, 18),
            Position = UDim2.new(1, -48, 0, 2),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = "[" .. default .. "]",
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 11,
            Parent = kpFrame,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        kpObj._keyLabel = keyBtn

        -- Mode selector (right-click to cycle)
        local listening = false

        keyBtn.MouseButton1Click:Connect(function()
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = lib.Theme.Accent
        end)

        keyBtn.MouseButton2Click:Connect(function()
            -- Cycle mode
            local modes = {"Hold", "Toggle", "Always"}
            local idx = table.find(modes, kpObj.Mode) or 1
            idx = idx % #modes + 1
            kpObj.Mode = modes[idx]
            kpObj:SetValue(nil, kpObj.Mode)
        end)

        local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
            if not listening then return end
            if processed then return end

            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                keyName = "MB3"
            end

            if keyName then
                if keyName == "Escape" or keyName == "Backspace" then
                    keyName = "None"
                end
                listening = false
                kpObj:SetValue(keyName)
                keyBtn.TextColor3 = lib.Theme.FontSecondary
            end
        end)
        table.insert(lib.Connections, inputConn)

        -- Handle Hold/Toggle/Always state
        local holdConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if listening then return end
            if kpObj.Value == "None" then return end

            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                keyName = "MB3"
            end

            if keyName == kpObj.Value then
                if kpObj.Mode == "Toggle" then
                    kpObj._isActive = not kpObj._isActive
                elseif kpObj.Mode == "Hold" then
                    kpObj._isActive = true
                end
                -- Sync with toggle if configured
                if syncToggle and getgenv().Toggles[syncToggle] then
                    getgenv().Toggles[syncToggle]:SetValue(kpObj:GetState())
                end
            end
        end)
        table.insert(lib.Connections, holdConn)

        local holdEndConn = UserInputService.InputEnded:Connect(function(input)
            if kpObj.Value == "None" then return end

            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                keyName = "MB3"
            end

            if keyName == kpObj.Value and kpObj.Mode == "Hold" then
                kpObj._isActive = false
                if syncToggle and getgenv().Toggles[syncToggle] then
                    getgenv().Toggles[syncToggle]:SetValue(false)
                end
            end
        end)
        table.insert(lib.Connections, holdEndConn)

        -- Register
        getgenv().Options[flag] = kpObj
        lib.Flags[flag] = kpObj

        return kpObj
    end

    function Groupbox.AddKeyPicker(self, flag, options)
        local lib = Elements.Library
        local order = self:_nextOrder()

        -- Create a container row for it
        local container = Create("Frame", {
            Name = "KeyPicker_" .. flag,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -80, 1, 0),
            BackgroundTransparency = 1,
            Text = options and options.Text or flag,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        return Groupbox._addKeyPickerToContainer(container, flag, options, lib, order)
    end

    -- Allow chaining AddKeyPicker on toggles
    local origToggle = Groupbox.AddToggle
    Groupbox.AddToggle = function(self, flag, options)
        local toggleObj = origToggle(self, flag, options)

        function toggleObj:AddKeyPicker(kpFlag, kpOptions)
            kpOptions = kpOptions or {}
            kpOptions.SyncToggleState = flag
            return Groupbox._addKeyPickerToContainer(toggleObj._container, kpFlag, kpOptions, Elements.Library, 0)
        end

        function toggleObj:AddColorPicker(cpFlag, cpOptions)
            return Groupbox._addColorPickerToContainer(toggleObj._container, cpFlag, cpOptions, Elements.Library, 0)
        end

        return toggleObj
    end

    -- ============================================================
    -- COLORPICKER
    -- ============================================================

    function Groupbox._addColorPickerToContainer(container, flag, options, lib, order)
        options = options or {}
        local default = options.Default or Color3.fromRGB(255, 255, 255)
        local callback = options.Callback
        local transparency = options.Transparency or nil

        local cpObj = {
            Value = default,
            Flag = flag,
            Type = "ColorPicker",
            Transparency = transparency or 0,
            _callbacks = {},
        }

        function cpObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function cpObj:SetValue(color, trans)
            if color then self.Value = color end
            if trans then self.Transparency = trans end
            if self._preview then
                self._preview.BackgroundColor3 = self.Value
            end
            for _, fn in ipairs(self._callbacks) do
                task.spawn(fn, self.Value)
            end
            if callback then
                task.spawn(callback, self.Value)
            end
        end

        -- Small color preview square on the right side
        local preview = Create("Frame", {
            Name = "ColorPreview_" .. flag,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(1, -20, 0, 2),
            BackgroundColor3 = default,
            BorderSizePixel = 0,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        cpObj._preview = preview

        -- Color picker popup on click
        local pickerOpen = false
        local pickerFrame = nil

        local previewBtn = Create("TextButton", {
            Name = "ClickArea",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = preview,
        })

        local function closePicker()
            if pickerFrame then
                pickerFrame:Destroy()
                pickerFrame = nil
            end
            pickerOpen = false
        end

        local function openPicker()
            if pickerOpen then closePicker() return end
            pickerOpen = true

            -- HSV picker popup
            local h, s, v = Color3.toHSV(cpObj.Value)

            pickerFrame = Create("Frame", {
                Name = "PickerPopup",
                Size = UDim2.new(0, 180, 0, 160),
                Position = UDim2.new(1, 4, 0, 0),
                BackgroundColor3 = lib.Theme.Background,
                BorderSizePixel = 0,
                ZIndex = 100,
                Parent = container,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Create("UIStroke", { Color = lib.Theme.Border, Thickness = 1 }),
            })

            -- Saturation/Value field
            local svField = Create("ImageLabel", {
                Name = "SVField",
                Size = UDim2.new(0, 140, 0, 100),
                Position = UDim2.new(0, 8, 0, 8),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 101,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                -- White gradient left to right
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    }),
                }),
            })

            -- Black overlay bottom to top
            Create("Frame", {
                Name = "BlackOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 102,
                Parent = svField,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                }),
            })

            -- SV cursor
            local svCursor = Create("Frame", {
                Name = "Cursor",
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(s, -4, 1 - v, -4),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 103,
                Parent = svField,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }),
            })

            -- Hue bar
            local hueBar = Create("Frame", {
                Name = "HueBar",
                Size = UDim2.new(0, 16, 0, 100),
                Position = UDim2.new(0, 156, 0, 8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 101,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                    }),
                }),
            })

            -- Hue cursor
            local hueCursor = Create("Frame", {
                Name = "HueCursor",
                Size = UDim2.new(1, 4, 0, 4),
                Position = UDim2.new(0, -2, h, -2),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 103,
                Parent = hueBar,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }),
            })

            -- Hex input
            local hexBox = Create("TextBox", {
                Name = "HexBox",
                Size = UDim2.new(1, -16, 0, 22),
                Position = UDim2.new(0, 8, 0, 114),
                BackgroundColor3 = lib.Theme.ElementBg,
                BorderSizePixel = 0,
                Text = "#" .. cpObj.Value:ToHex(),
                TextColor3 = lib.Theme.FontPrimary,
                FontFace = lib.FontRegular,
                TextSize = 11,
                ClearTextOnFocus = false,
                ZIndex = 101,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
                Create("UIPadding", { PaddingLeft = UDim.new(0, 4) }),
            })

            -- Close button
            local closeBtn = Create("TextButton", {
                Name = "CloseBtn",
                Size = UDim2.new(1, -16, 0, 18),
                Position = UDim2.new(0, 8, 0, 138),
                BackgroundColor3 = lib.Theme.ElementBg,
                BorderSizePixel = 0,
                Text = "Close",
                TextColor3 = lib.Theme.FontSecondary,
                FontFace = lib.FontRegular,
                TextSize = 11,
                ZIndex = 101,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            })
            closeBtn.MouseButton1Click:Connect(closePicker)

            local function updateColor()
                local newColor = Color3.fromHSV(h, s, v)
                cpObj:SetValue(newColor)
                svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position = UDim2.new(s, -4, 1 - v, -4)
                hueCursor.Position = UDim2.new(0, -2, h, -2)
                hexBox.Text = "#" .. newColor:ToHex()
            end

            -- SV field drag
            local svDragging = false
            local svBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 104,
                Parent = svField,
            })

            svBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    svDragging = true
                end
            end)
            svBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    svDragging = false
                end
            end)

            -- Hue bar drag
            local hueDragging = false
            local hueBtn = Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 104,
                Parent = hueBar,
            })

            hueBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = true
                end
            end)
            hueBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = false
                end
            end)

            local pickerMoveConn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

                if svDragging then
                    local relX = math.clamp((input.Position.X - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
                    local relY = math.clamp((input.Position.Y - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
                    s = relX
                    v = 1 - relY
                    updateColor()
                end

                if hueDragging then
                    local relY = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    h = relY
                    updateColor()
                end
            end)
            table.insert(lib.Connections, pickerMoveConn)

            -- Hex input
            hexBox.FocusLost:Connect(function()
                local hexText = hexBox.Text:gsub("#", "")
                local ok, color = pcall(function()
                    return Color3.fromHex("#" .. hexText)
                end)
                if ok and color then
                    h, s, v = Color3.toHSV(color)
                    updateColor()
                else
                    hexBox.Text = "#" .. cpObj.Value:ToHex()
                end
            end)
        end

        previewBtn.MouseButton1Click:Connect(openPicker)

        -- Register
        getgenv().Options[flag] = cpObj
        lib.Flags[flag] = cpObj

        return cpObj
    end

    function Groupbox.AddColorPicker(self, flag, options)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local container = Create("Frame", {
            Name = "ColorPicker_" .. flag,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Text = options and options.Text or flag,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        return Groupbox._addColorPickerToContainer(container, flag, options, lib, order)
    end

    -- ============================================================
    -- DEPENDENCY BOX
    -- ============================================================

    function Groupbox.AddDependencyBox(self)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local depBox = {
            _dependencies = {},
        }

        local container = Create("Frame", {
            Name = "DependencyBox",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
            ClipsDescendants = true,
            Parent = self._container,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            }),
        })

        depBox._container = container
        depBox._elementOrder = 0

        function depBox:_nextOrder()
            self._elementOrder = self._elementOrder + 1
            return self._elementOrder
        end

        function depBox:SetupDependencies(deps)
            self._dependencies = deps

            local function check()
                local visible = true
                for _, dep in ipairs(deps) do
                    local toggle = getgenv().Toggles[dep.Flag]
                    if toggle then
                        if dep.Inverted then
                            if toggle.Value then visible = false end
                        else
                            if not toggle.Value then visible = false end
                        end
                    end
                end
                container.Visible = visible
            end

            -- Hook into each dependency toggle
            for _, dep in ipairs(deps) do
                local toggle = getgenv().Toggles[dep.Flag]
                if toggle then
                    toggle:OnChanged(function()
                        check()
                    end)
                end
            end

            check()
        end

        -- Give DependencyBox all the same AddXxx methods
        depBox.AddToggle = Groupbox.AddToggle
        depBox.AddSlider = Groupbox.AddSlider
        depBox.AddButton = Groupbox.AddButton
        depBox.AddDropdown = Groupbox.AddDropdown
        depBox.AddInput = Groupbox.AddInput
        depBox.AddLabel = Groupbox.AddLabel
        depBox.AddDivider = Groupbox.AddDivider
        depBox.AddKeyPicker = Groupbox.AddKeyPicker
        depBox.AddColorPicker = Groupbox.AddColorPicker

        return depBox
    end

    -- ============================================================
    -- INJECT METHODS
    -- Apply all Groupbox methods to the actual Groupbox metatable
    -- ============================================================

    Library._GroupboxMethods = Groupbox
end

-- After Library:CreateWindow, we need to inject the methods
-- This function patches any Groupbox returned by Tab:AddLeftGroupbox / Tab:AddRightGroupbox
function Elements:InjectGroupboxMethods(groupbox)
    local lib = self.Library
    local methods = lib._GroupboxMethods
    if not methods then return end

    for k, v in pairs(methods) do
        if type(v) == "function" then
            groupbox[k] = v
        end
    end
end

return Elements
