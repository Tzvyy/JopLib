--[[
    JopLib - UI Library for Roblox
    Elements.lua - Toggle, Slider, Button, Dropdown, TextInput, Label, Divider,
                   KeyPicker, ColorPicker, DependencyBox
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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
            if self._box then
                Tween(self._box, {BackgroundColor3 = val and lib.Theme.ToggleOn or lib.Theme.ToggleOff}, 0.15):Play()
            end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, val) end
            if callback then task.spawn(callback, val) end
        end

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

        local hasValue = options.ValueText and options.ValueText ~= ""
        local labelWidth = hasValue and UDim2.new(1, -120, 1, 0) or UDim2.new(1, -24, 1, 0)

        Create("TextLabel", {
            Name = "Label",
            Size = labelWidth,
            Position = UDim2.new(0, 22, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        local valueLabel = nil
        if hasValue then
            valueLabel = Create("TextLabel", {
                Name = "ValueLabel",
                Size = UDim2.new(0, 90, 1, 0),
                Position = UDim2.new(1, -95, 0, 0),
                BackgroundTransparency = 1,
                Text = options.ValueText,
                TextColor3 = lib.Theme.FontSecondary,
                FontFace = lib.FontRegular,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = container,
            })
        end

        toggleObj._box = box
        toggleObj._valueLabel = valueLabel
        toggleObj._container = container

        function toggleObj:SetValueText(txt)
            if self._valueLabel then
                self._valueLabel.Text = txt or ""
            end
        end

        local btn = Create("TextButton", {
            Name = "ClickArea",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundTransparency = 1,
            Text = "",
            Parent = container,
        })

        local labelBtn = Create("TextButton", {
            Name = "LabelClick",
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 22, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = container,
        })

        btn.MouseButton1Click:Connect(function()
            toggleObj:SetValue(not toggleObj.Value)
        end)
        labelBtn.MouseButton1Click:Connect(function()
            toggleObj:SetValue(not toggleObj.Value)
        end)

        getgenv().Toggles[flag] = toggleObj
        lib.Flags[flag] = toggleObj

        function toggleObj:_layoutAccessories()
            local rightOffset = 2
            -- KeyPicker is rightmost
            if self._kpFlag then
                local kpFrame = self._container:FindFirstChild("KeyPicker_" .. self._kpFlag)
                if kpFrame then
                    kpFrame.Position = UDim2.new(1, -(rightOffset + 55), 0, 0)
                    rightOffset = rightOffset + 55 + 4
                end
            end
            -- ColorPicker is to the left of keybind
            if self._cpFlag then
                local cpPreview = self._container:FindFirstChild("ColorPreview_" .. self._cpFlag)
                if cpPreview then
                    cpPreview.Position = UDim2.new(1, -(rightOffset + 18), 0, 2)
                    rightOffset = rightOffset + 18 + 4
                end
            end
        end

        function toggleObj:AddKeyPicker(kpFlag, kpOptions)
            kpOptions = kpOptions or {}
            kpOptions.SyncToggleState = flag
            local kp = Groupbox._addKeyPickerToContainer(toggleObj._container, kpFlag, kpOptions, lib)
            toggleObj._kpFlag = kpFlag
            toggleObj:_layoutAccessories()
            return kp
        end

        function toggleObj:AddColorPicker(cpFlag, cpOptions)
            local cp = Groupbox._addColorPickerToContainer(toggleObj._container, cpFlag, cpOptions, lib)
            toggleObj._cpFlag = cpFlag
            toggleObj:_layoutAccessories()
            return cp
        end

        return toggleObj
    end

    -- ============================================================
    -- SLIDER (with click-to-type on the value)
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
        local compact = options.Compact or false
        local hideMax = options.HideMax or false
        local callback = options.Callback

        local function round(val)
            if rounding == 0 then return math.floor(val + 0.5) end
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
            local pct = (val - min) / (max - min)
            if self._fill then Tween(self._fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.1):Play() end
            if self._valueLabel then
                if compact or hideMax then
                    self._valueLabel.Text = tostring(val) .. suffix
                else
                    self._valueLabel.Text = tostring(val) .. " / " .. tostring(max) .. suffix
                end
            end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, val) end
            if callback then task.spawn(callback, val) end
        end

        local containerHeight = compact and 22 or 36
        local container = Create("Frame", {
            Name = "Slider_" .. flag,
            Size = UDim2.new(1, 0, 0, containerHeight),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        if not compact then
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
        end

        local valText
        if compact or hideMax then
            valText = tostring(default) .. suffix
        else
            valText = tostring(default) .. " / " .. tostring(max) .. suffix
        end

        local valueBg = Create("Frame", {
            Name = "ValueBg",
            Size = UDim2.new(0, 0, 0, 16),
            AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Parent = container,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            }),
        })

        local valueLabel = Create("TextButton", {
            Name = "Value",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = valText,
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            Parent = valueBg,
        })

        local sliderY = compact and 0 or 20
        local sliderBg = Create("Frame", {
            Name = "SliderBg",
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, sliderY),
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

        -- Click on value to type a number (only edit the value, keep /max suffix visible)
        valueLabel.MouseButton1Click:Connect(function()
            local suffixText = ""
            if not compact and not hideMax then
                suffixText = " / " .. tostring(max) .. suffix
            elseif suffix ~= "" then
                suffixText = suffix
            end

            -- Hide the value label, show an inline editor
            valueLabel.Visible = false

            local editHolder = Create("Frame", {
                Name = "EditHolder",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Parent = valueBg,
            })

            local inputBox = Create("TextBox", {
                Name = "NumInput",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = tostring(sliderObj.Value),
                TextColor3 = lib.Theme.FontPrimary,
                FontFace = lib.FontRegular,
                TextSize = 12,
                ClearTextOnFocus = false,
                LayoutOrder = 0,
                Parent = editHolder,
            })

            local suffixLabel = Create("TextLabel", {
                Name = "Suffix",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = suffixText,
                TextColor3 = lib.Theme.FontSecondary,
                FontFace = lib.FontRegular,
                TextSize = 12,
                LayoutOrder = 1,
                Parent = editHolder,
            })

            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = editHolder,
            })

            inputBox:CaptureFocus()

            -- Only allow numeric input
            inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                local cleaned = inputBox.Text:gsub("[^%d%.%-]", "")
                if cleaned ~= inputBox.Text then
                    inputBox.Text = cleaned
                end
            end)

            inputBox.FocusLost:Connect(function()
                local num = tonumber(inputBox.Text)
                if num then sliderObj:SetValue(num) end
                editHolder:Destroy()
                valueLabel.Visible = true
            end)
        end)

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
            sliderObj:SetValue(min + (max - min) * relX)
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

        getgenv().Options[flag] = sliderObj
        lib.Flags[flag] = sliderObj
        return sliderObj
    end

    -- ============================================================
    -- BUTTON (table API, sub-buttons, double-click confirm)
    -- ============================================================

    function Groupbox.AddButton(self, info)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local text = info.Text or "Button"
        local func = info.Func
        local doubleClick = info.DoubleClick or false

        local container = Create("Frame", {
            Name = "Button_" .. text,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            }),
        })

        local function makeBtn(btnText, btnFunc, isDouble, layoutOrder)
            local btn = Create("TextButton", {
                Name = "Btn",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = lib.Theme.ElementBg,
                BorderSizePixel = 0,
                Text = btnText,
                TextColor3 = lib.Theme.FontPrimary,
                FontFace = lib.FontSemiBold,
                TextSize = 13,
                LayoutOrder = layoutOrder,
                Parent = container,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
            })

            local confirming = false
            btn.MouseButton1Click:Connect(function()
                if isDouble and not confirming then
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
                if btnFunc then task.spawn(btnFunc) end
            end)

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

            return btn
        end

        makeBtn(text, func, doubleClick, 0)

        local buttonObj = {}
        buttonObj._container = container
        buttonObj._btnCount = 1

        function buttonObj:AddButton(subInfo)
            self._btnCount = self._btnCount + 1
            makeBtn(subInfo.Text or "Sub Button", subInfo.Func, subInfo.DoubleClick or false, self._btnCount)
            return self
        end

        return buttonObj
    end

    -- ============================================================
    -- DROPDOWN (close others, render in popupHolder)
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

        if options.SpecialType == "Player" then
            values = {}
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game:GetService("Players").LocalPlayer then
                    table.insert(values, p.Name)
                end
            end
        end

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
                    if dropObj.Value[v] then table.insert(selected, v) end
                end
                if #selected == 0 then return "None" end
                return table.concat(selected, ", ")
            else
                return tostring(dropObj.Value or "None")
            end
        end

        function dropObj:SetValue(val)
            if multi and type(val) == "table" then
                self.Value = val
            elseif not multi then
                self.Value = val
            end
            if self._displayLabel then self._displayLabel.Text = getDisplayText() end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, self.Value) end
            if callback then task.spawn(callback, self.Value) end
        end

        function dropObj:SetValues(newValues)
            values = newValues
            self.Values = newValues
            if self._rebuildItems then self:_rebuildItems() end
        end

        local container = Create("Frame", {
            Name = "Dropdown_" .. flag,
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
            Text = "\226\150\188",
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 10,
            Parent = dropBtn,
        })

        dropObj._displayLabel = displayLabel

        local open = false
        local maxVisible = 6
        local itemHeight = 22
        local dropList = nil
        local dropTrackConn = nil

        local function closeDrop()
            open = false
            arrow.Text = "\226\150\188"
            if dropTrackConn then dropTrackConn:Disconnect() dropTrackConn = nil end
            if dropList then dropList:Destroy() dropList = nil end
        end

        local popupObj = { Close = closeDrop }

        local function buildItems()
            if dropList then dropList:Destroy() dropList = nil end

            local absPos = dropBtn.AbsolutePosition
            local absSize = dropBtn.AbsoluteSize
            local listHeight = math.min(#values, maxVisible) * itemHeight

            dropList = Create("ScrollingFrame", {
                Name = "DropList_" .. flag,
                Size = UDim2.new(0, absSize.X, 0, listHeight),
                Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2),
                BackgroundColor3 = lib.Theme.ElementBg,
                BorderSizePixel = 0,
                ZIndex = 100,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = lib.Theme.Accent,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ClipsDescendants = true,
                Parent = lib._popupHolder,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
            })

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
                    ZIndex = 101,
                    Parent = dropList,
                })

                item.MouseButton1Click:Connect(function()
                    if multi then
                        dropObj.Value[val] = not dropObj.Value[val]
                        dropObj:SetValue(dropObj.Value)
                        local sel = dropObj.Value[val]
                        item.BackgroundTransparency = sel and 0.7 or 0
                        item.BackgroundColor3 = sel and lib.Theme.Accent or lib.Theme.ElementBg
                        item.TextColor3 = sel and lib.Theme.FontPrimary or lib.Theme.FontSecondary
                    else
                        dropObj:SetValue(val)
                        -- Update all items highlight without closing
                        if dropList then
                            for _, child in ipairs(dropList:GetChildren()) do
                                if child:IsA("TextButton") then
                                    local isSel = (child.Name == "Item_" .. val)
                                    child.BackgroundColor3 = isSel and lib.Theme.Accent or lib.Theme.ElementBg
                                    child.BackgroundTransparency = isSel and 0.7 or 0
                                    child.TextColor3 = isSel and lib.Theme.FontPrimary or lib.Theme.FontSecondary
                                end
                            end
                        end
                    end
                end)

                item.MouseEnter:Connect(function()
                    if not (multi and dropObj.Value[val]) and dropObj.Value ~= val then
                        Tween(item, {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}, 0.1):Play()
                    end
                end)
                item.MouseLeave:Connect(function()
                    local sel = multi and dropObj.Value[val] or (dropObj.Value == val)
                    item.BackgroundColor3 = sel and lib.Theme.Accent or lib.Theme.ElementBg
                    item.BackgroundTransparency = sel and 0.7 or 0
                end)
            end
        end

        dropObj._rebuildItems = function()
            if open then buildItems() end
        end

        dropBtn.MouseButton1Click:Connect(function()
            if open then
                closeDrop()
                lib._openPopup = nil
                lib._openPopupTrigger = nil
            else
                lib:ClosePopups()
                open = true
                arrow.Text = "\226\150\178"
                buildItems()
                lib._openPopup = popupObj
                lib._openPopupTrigger = dropBtn
                lib:_showClickCatcher()

                -- Track dropdown position while scrolling
                dropTrackConn = RunService.Heartbeat:Connect(function()
                    if not dropList or not dropList.Parent then
                        if dropTrackConn then dropTrackConn:Disconnect() dropTrackConn = nil end
                        return
                    end
                    local ap = dropBtn.AbsolutePosition
                    local as = dropBtn.AbsoluteSize
                    dropList.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
                    dropList.Size = UDim2.new(0, as.X, 0, dropList.Size.Y.Offset)
                end)
                table.insert(lib.Connections, dropTrackConn)
            end
        end)

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
            if self._textBox then self._textBox.Text = tostring(val) end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, val) end
            if callback then task.spawn(callback, val) end
        end

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
            Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
        })

        inputObj._textBox = textBox

        local function processInput(txt)
            if numeric then
                local num = tonumber(txt)
                if num then inputObj:SetValue(num) else textBox.Text = tostring(inputObj.Value) end
            else
                inputObj:SetValue(txt)
            end
        end

        if finished then
            textBox.FocusLost:Connect(function() processInput(textBox.Text) end)
        else
            textBox:GetPropertyChangedSignal("Text"):Connect(function() processInput(textBox.Text) end)
        end

        getgenv().Options[flag] = inputObj
        lib.Flags[flag] = inputObj
        return inputObj
    end

    -- ============================================================
    -- LABEL (supports wrapping)
    -- ============================================================

    function Groupbox.AddLabel(self, text, doesWrap)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local labelInst = Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = doesWrap or false,
            LayoutOrder = order,
            Parent = self._container,
        })

        if not doesWrap then
            labelInst.Size = UDim2.new(1, 0, 0, 18)
            labelInst.AutomaticSize = Enum.AutomaticSize.None
        end

        local labelObj = {}
        labelObj._label = labelInst
        labelObj._container = labelInst

        function labelObj:SetText(newText) labelInst.Text = newText end

        function labelObj:AddColorPicker(cpFlag, cpOptions)
            return Groupbox._addColorPickerToContainer(labelInst, cpFlag, cpOptions, lib)
        end

        function labelObj:AddKeyPicker(kpFlag, kpOptions)
            return Groupbox._addKeyPickerToContainer(labelInst, kpFlag, kpOptions, lib)
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
    -- KEYPICKER (right-click context menu for mode selection)
    -- ============================================================

    function Groupbox._addKeyPickerToContainer(container, flag, options, lib)
        options = options or {}
        local default = options.Default or "None"
        local text = options.Text or flag
        local noUI = options.NoUI or false
        local mode = options.Mode or "Toggle"
        local syncToggle = options.SyncToggleState
        local cbCallback = options.Callback
        local changedCb = options.ChangedCallback

        local kpObj = {
            Value = default,
            Flag = flag,
            Type = "KeyPicker",
            Mode = mode,
            Text = text,
            NoUI = noUI,
            _isActive = false,
            _callbacks = {},
            _clickCallbacks = {},
        }

        function kpObj:OnChanged(fn)
            table.insert(self._callbacks, fn)
            return self
        end

        function kpObj:OnClick(fn)
            table.insert(self._clickCallbacks, fn)
            return self
        end

        function kpObj:GetState()
            if self.Mode == "Always" then return true end
            return self._isActive
        end

        function kpObj:SetValue(data)
            if type(data) == "table" then
                if data[1] then self.Value = data[1] end
                if data[2] then self.Mode = data[2] end
            elseif type(data) == "string" then
                self.Value = data
            end
            if self._keyLabel then self._keyLabel.Text = self.Value end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, self.Value) end
            if changedCb then task.spawn(changedCb, self.Value) end
        end

        local kpFrame = Create("Frame", {
            Name = "KeyPicker_" .. flag,
            Size = UDim2.new(0, 55, 0, 22),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 1,
            Parent = container,
        })

        local keyBtn = Create("TextButton", {
            Name = "KeyBtn",
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 2),
            BackgroundColor3 = lib.Theme.ElementBg,
            BorderSizePixel = 0,
            Text = default,
            TextColor3 = lib.Theme.FontSecondary,
            FontFace = lib.FontRegular,
            TextSize = 11,
            Parent = kpFrame,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
        })

        kpObj._keyLabel = keyBtn

        local listening = false

        keyBtn.MouseButton1Click:Connect(function()
            listening = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = lib.Theme.Accent
        end)

        -- Right-click: show mode context menu
        keyBtn.MouseButton2Click:Connect(function()
            lib:ClosePopups()

            local absPos = keyBtn.AbsolutePosition
            local absSize = keyBtn.AbsoluteSize

            local modeMenu = Create("Frame", {
                Name = "ModeMenu",
                Size = UDim2.new(0, 80, 0, 66),
                Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2),
                BackgroundColor3 = lib.Theme.ElementBg,
                BorderSizePixel = 0,
                ZIndex = 100,
                Parent = lib._popupHolder,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIStroke", { Color = lib.Theme.ElementBorder, Thickness = 1 }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            })

            local function closeMenu()
                modeMenu:Destroy()
            end

            local modes = {"Hold", "Toggle", "Always"}
            for i, m in ipairs(modes) do
                local mBtn = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = kpObj.Mode == m and lib.Theme.Accent or lib.Theme.ElementBg,
                    BackgroundTransparency = kpObj.Mode == m and 0.7 or 0,
                    BorderSizePixel = 0,
                    Text = m,
                    TextColor3 = lib.Theme.FontPrimary,
                    FontFace = lib.FontRegular,
                    TextSize = 12,
                    LayoutOrder = i,
                    ZIndex = 101,
                    Parent = modeMenu,
                })
                mBtn.MouseButton1Click:Connect(function()
                    kpObj.Mode = m
                    kpObj._isActive = false
                    closeMenu()
                    lib._openPopup = nil
                end)
            end

            lib._openPopup = { Close = closeMenu }
            lib._openPopupTrigger = keyBtn
            lib:_showClickCatcher()
        end)

        -- Key listening
        local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
            if not listening then return end
            if processed then return end
            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MB3"
            end
            if keyName then
                if keyName == "Escape" or keyName == "Backspace" then keyName = "None" end
                listening = false
                kpObj:SetValue({keyName, kpObj.Mode})
                keyBtn.TextColor3 = lib.Theme.FontSecondary
            end
        end)
        table.insert(lib.Connections, inputConn)

        -- Hold/Toggle/Always state
        local holdConn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed or listening then return end
            if kpObj.Value == "None" then return end
            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MB3"
            end
            if keyName == kpObj.Value then
                if kpObj.Mode == "Toggle" then
                    kpObj._isActive = not kpObj._isActive
                    for _, fn in ipairs(kpObj._clickCallbacks) do task.spawn(fn, kpObj._isActive) end
                    if cbCallback then task.spawn(cbCallback, kpObj._isActive) end
                elseif kpObj.Mode == "Hold" then
                    kpObj._isActive = true
                    if cbCallback then task.spawn(cbCallback, true) end
                end
                if syncToggle and getgenv().Toggles[syncToggle] then
                    getgenv().Toggles[syncToggle]:SetValue(kpObj:GetState())
                end
            end
        end)
        table.insert(lib.Connections, holdConn)

        local holdEndConn = UserInputService.InputEnded:Connect(function(input)
            if kpObj.Value == "None" then return end
            local keyName
            if input.UserInputType == Enum.UserInputType.Keyboard then keyName = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MB1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MB2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MB3"
            end
            if keyName == kpObj.Value and kpObj.Mode == "Hold" then
                kpObj._isActive = false
                if cbCallback then task.spawn(cbCallback, false) end
                if syncToggle and getgenv().Toggles[syncToggle] then
                    getgenv().Toggles[syncToggle]:SetValue(false)
                end
            end
        end)
        table.insert(lib.Connections, holdEndConn)

        getgenv().Options[flag] = kpObj
        lib.Flags[flag] = kpObj
        return kpObj
    end

    function Groupbox.AddKeyPicker(self, flag, options)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local container = Create("Frame", {
            Name = "KeyPicker_" .. flag,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = self._container,
        })

        Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Text = options and options.Text or flag,
            TextColor3 = lib.Theme.FontPrimary,
            FontFace = lib.FontRegular,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
        })

        return Groupbox._addKeyPickerToContainer(container, flag, options, lib)
    end

    -- ============================================================
    -- COLORPICKER (render in popupHolder, close others)
    -- ============================================================

    function Groupbox._addColorPickerToContainer(container, flag, options, lib)
        options = options or {}
        local default = options.Default or Color3.fromRGB(255, 255, 255)
        local callback = options.Callback
        local title = options.Title or flag
        local transparency = options.Transparency

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
            if trans ~= nil then self.Transparency = trans end
            if self._preview then self._preview.BackgroundColor3 = self.Value end
            for _, fn in ipairs(self._callbacks) do task.spawn(fn, self.Value) end
            if callback then task.spawn(callback, self.Value) end
        end

        function cpObj:SetValueRGB(color)
            self:SetValue(color)
        end

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

        local pickerFrame = nil
        local pickerTrackConn = nil

        local function closePicker()
            if pickerTrackConn then pickerTrackConn:Disconnect() pickerTrackConn = nil end
            if pickerFrame then pickerFrame:Destroy() pickerFrame = nil end
        end

        local popupObj = { Close = closePicker }

        local previewBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = preview,
        })

        previewBtn.MouseButton1Click:Connect(function()
            if pickerFrame then
                closePicker()
                lib._openPopup = nil
                lib._openPopupTrigger = nil
                return
            end

            lib:ClosePopups()

            local h, s, v = Color3.toHSV(cpObj.Value)
            local absPos = preview.AbsolutePosition

            local pickerW = 200
            local pickerH = 180
            pickerFrame = Create("Frame", {
                Name = "PickerPopup_" .. flag,
                Size = UDim2.new(0, pickerW, 0, pickerH),
                Position = UDim2.new(0, absPos.X, 0, absPos.Y + 22),
                BackgroundColor3 = lib.Theme.Background,
                BorderSizePixel = 0,
                ZIndex = 100,
                Parent = lib._popupHolder,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Create("UIStroke", { Color = lib.Theme.Border, Thickness = 1 }),
            })

            lib:_showClickCatcher()

            -- Keep picker attached to the preview box while scrolling
            pickerTrackConn = RunService.Heartbeat:Connect(function()
                if not pickerFrame or not pickerFrame.Parent then
                    if pickerTrackConn then pickerTrackConn:Disconnect() pickerTrackConn = nil end
                    return
                end
                local ap = preview.AbsolutePosition
                pickerFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + 22)
            end)
            table.insert(lib.Connections, pickerTrackConn)

            Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -8, 0, 18),
                Position = UDim2.new(0, 4, 0, 2),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = lib.Theme.FontPrimary,
                FontFace = lib.FontBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 101,
                Parent = pickerFrame,
            })

            -- SV Field: background = pure hue color
            -- White gradient left-to-right (saturation)
            -- Black gradient top-to-bottom (value, inverted)
            local svField = Create("Frame", {
                Name = "SVField",
                Size = UDim2.new(0, 148, 0, 100),
                Position = UDim2.new(0, 8, 0, 22),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 101,
                ClipsDescendants = true,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            })

            -- White overlay (left = white, right = transparent)
            Create("Frame", {
                Name = "WhiteOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 102,
                Parent = svField,
            }, {
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

            -- Black overlay (bottom = black, top = transparent)
            Create("Frame", {
                Name = "BlackOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 103,
                Parent = svField,
            }, {
                Create("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    }),
                }),
            })

            local svCursor = Create("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(s, -4, 1-v, -4),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                ZIndex = 104,
                Parent = svField,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                Create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }),
            })

            local hueBar = Create("Frame", {
                Name = "HueBar",
                Size = UDim2.new(0, 16, 0, 100),
                Position = UDim2.new(0, 164, 0, 22),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                ZIndex = 101,
                Parent = pickerFrame,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,1,1)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,1,1)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
                    }),
                }),
            })

            local hueCursor = Create("Frame", {
                Size = UDim2.new(1, 4, 0, 4),
                Position = UDim2.new(0, -2, h, -2),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0,
                ZIndex = 103,
                Parent = hueBar,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
                Create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }),
            })

            local hexBox = Create("TextBox", {
                Size = UDim2.new(1, -16, 0, 22),
                Position = UDim2.new(0, 8, 0, 128),
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

            local closeBtn = Create("TextButton", {
                Size = UDim2.new(1, -16, 0, 18),
                Position = UDim2.new(0, 8, 0, 154),
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
            closeBtn.MouseButton1Click:Connect(function()
                closePicker()
                lib._openPopup = nil
            end)

            local function updateColor()
                local newColor = Color3.fromHSV(h, s, v)
                cpObj:SetValue(newColor)
                svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position = UDim2.new(s, -4, 1-v, -4)
                hueCursor.Position = UDim2.new(0, -2, h, -2)
                hexBox.Text = "#" .. newColor:ToHex()
            end

            local svDragging, hueDragging = false, false

            local svBtn = Create("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 104, Parent = svField,
            })
            svBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true end
            end)
            svBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
            end)

            local hueBtn = Create("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 104, Parent = hueBar,
            })
            hueBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true end
            end)
            hueBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
            end)

            local pickerMoveConn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if svDragging then
                    s = math.clamp((input.Position.X - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
                    updateColor()
                end
                if hueDragging then
                    h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                    updateColor()
                end
            end)
            table.insert(lib.Connections, pickerMoveConn)

            hexBox.FocusLost:Connect(function()
                local hexText = hexBox.Text:gsub("#", "")
                local ok, color = pcall(function() return Color3.fromHex("#" .. hexText) end)
                if ok and color then
                    h, s, v = Color3.toHSV(color)
                    updateColor()
                else
                    hexBox.Text = "#" .. cpObj.Value:ToHex()
                end
            end)

            lib._openPopup = popupObj
            lib._openPopupTrigger = previewBtn
        end)

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

        return Groupbox._addColorPickerToContainer(container, flag, options, lib)
    end

    -- ============================================================
    -- DEPENDENCY BOX (Linoria format: { ToggleObj, true/false })
    -- ============================================================

    function Groupbox.AddDependencyBox(self)
        local lib = Elements.Library
        local order = self:_nextOrder()

        local depBox = { _dependencies = {} }

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
                    local toggle = dep[1]
                    local wantState = dep[2]
                    if toggle then
                        if wantState then
                            if not toggle.Value then visible = false end
                        else
                            if toggle.Value then visible = false end
                        end
                    end
                end
                container.Visible = visible
            end

            for _, dep in ipairs(deps) do
                local toggle = dep[1]
                if toggle and toggle.OnChanged then
                    toggle:OnChanged(function() check() end)
                end
            end

            check()
        end

        depBox.AddToggle = Groupbox.AddToggle
        depBox.AddSlider = Groupbox.AddSlider
        depBox.AddButton = Groupbox.AddButton
        depBox.AddDropdown = Groupbox.AddDropdown
        depBox.AddInput = Groupbox.AddInput
        depBox.AddLabel = Groupbox.AddLabel
        depBox.AddDivider = Groupbox.AddDivider
        depBox.AddKeyPicker = Groupbox.AddKeyPicker
        depBox.AddColorPicker = Groupbox.AddColorPicker
        depBox.AddDependencyBox = Groupbox.AddDependencyBox

        return depBox
    end

    Library._GroupboxMethods = Groupbox
end

return Elements
