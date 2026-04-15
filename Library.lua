--[[
    JopLib - UI Library for Roblox
    Library.lua - Core: Window, Tabs, Groupboxes, TabBoxes, Watermark, KeybindFrame
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- GLOBALS: Toggles / Options tables (like Linoria)
-- ============================================================

if not getgenv then
    getfenv().getgenv = function() return getfenv() end
end

getgenv().Toggles = getgenv().Toggles or {}
getgenv().Options = getgenv().Options or {}

-- ============================================================
-- FONT CONFIG (single place to change)
-- ============================================================

local FontFamily = "rbxasset://fonts/families/Inter.json"
local Fonts = {
    Regular   = Font.new(FontFamily, Enum.FontWeight.Regular),
    SemiBold  = Font.new(FontFamily, Enum.FontWeight.SemiBold),
    Bold      = Font.new(FontFamily, Enum.FontWeight.Bold),
}

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

local function Tween(inst, props, duration, style, dir)
    duration = duration or 0.2
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    return TweenService:Create(inst, TweenInfo.new(duration, style, dir), props)
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- LIBRARY
-- ============================================================

local Library = {}
Library.__index = Library
Library.Toggled = true
Library.ToggleKeybind = nil
Library.AccentColor = Color3.fromRGB(96, 105, 255)
Library.FontRegular = Fonts.Regular
Library.FontSemiBold = Fonts.SemiBold
Library.FontBold = Fonts.Bold
Library.Unloaded = false

Library.Theme = {
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

Library.Elements = {}
Library.Flags = {}
Library.Connections = {}
Library._unloadCallbacks = {}
Library._openPopup = nil

-- ============================================================
-- POPUP MANAGEMENT (only one dropdown/colorpicker open at a time)
-- ============================================================

function Library:ClosePopups()
    if self._openPopup then
        local popup = self._openPopup
        self._openPopup = nil
        self._openPopupTrigger = nil
        if popup.Close then popup:Close() end
    end
end

function Library:_showClickCatcher()
    -- No-op: we use InputBegan listener instead
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================

local NotificationHolder = nil

function Library:Notify(text, duration)
    duration = duration or 3

    if not NotificationHolder then
        NotificationHolder = Create("ScreenGui", {
            Name = "JopLibNotifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = game:GetService("CoreGui"),
        })
        Create("Frame", {
            Name = "Holder",
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -310, 0, 0),
            BackgroundTransparency = 1,
            Parent = NotificationHolder,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
            Create("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
            }),
        })
    end

    local holder = NotificationHolder:FindFirstChild("Holder")

    local notif = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = holder,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", { Color = self.Theme.Border, Thickness = 1 }),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 0, 3),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -16, 1, -12),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = self.Theme.FontPrimary,
            FontFace = self.FontRegular,
            TextSize = 14,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }),
    })

    local textLabel = notif:FindFirstChild("Text")
    local textHeight = textLabel.TextBounds.Y + 16
    textHeight = math.max(textHeight, 30)

    Tween(notif, {Size = UDim2.new(1, 0, 0, textHeight)}, 0.25):Play()

    task.delay(duration, function()
        local t = Tween(notif, {Size = UDim2.new(1, 0, 0, 0)}, 0.25)
        t:Play()
        t.Completed:Wait()
        notif:Destroy()
    end)
end

-- ============================================================
-- WATERMARK
-- ============================================================

function Library:CreateWatermark()
    if self._watermarkGui then return end

    local gui = Create("ScreenGui", {
        Name = "JopLibWatermark",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })

    local frame = Create("Frame", {
        Name = "WatermarkFrame",
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = gui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", { Color = self.Theme.Border, Thickness = 1 }),
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(1, 16, 0, 3),
            Position = UDim2.new(0, -8, 0, 3),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = self.Theme.FontSecondary,
            FontFace = self.FontRegular,
            TextSize = 14,
        }),
    })

    MakeDraggable(frame)
    self._watermarkGui = gui
    self._watermarkFrame = frame
end

function Library:SetWatermark(text)
    if not self._watermarkGui then self:CreateWatermark() end
    local label = self._watermarkFrame:FindFirstChild("Text", true)
    if label then label.Text = text end
end

function Library:SetWatermarkVisibility(visible)
    if not self._watermarkGui then self:CreateWatermark() end
    self._watermarkFrame.Visible = visible
end

-- ============================================================
-- KEYBIND FRAME (auto-updating list of registered keybinds)
-- ============================================================

function Library:CreateKeybindFrame()
    if self._keybindGui then return end

    local gui = Create("ScreenGui", {
        Name = "JopLibKeybinds",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })

    local frame = Create("Frame", {
        Name = "KeybindFrame",
        Size = UDim2.new(0, 220, 0, 30),
        Position = UDim2.new(0, 10, 0, 300),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = gui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", { Color = self.Theme.Border, Thickness = 1 }),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 0, 3),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -8, 0, 24),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Text = "Keybinds",
            TextColor3 = self.Theme.FontSecondary,
            TextSize = 14,
            FontFace = self.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    local listFrame = Create("Frame", {
        Name = "List",
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 5, 0, 30),
        BackgroundTransparency = 1,
        Parent = frame,
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        }),
    })

    MakeDraggable(frame)
    self._keybindGui = gui
    self._keybindFrame = frame
    self._keybindList = listFrame
    self.KeybindFrame = frame
end

function Library:UpdateKeybindFrame()
    if not self._keybindGui or not self._keybindFrame.Visible then return end

    local listFrame = self._keybindList
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local count = 0
    local showAll = not (self._keybindFilterActive)
    local opts = getgenv().Options or {}
    for flag, opt in pairs(opts) do
        if opt.Type == "KeyPicker" and not opt.NoUI and opt.Value and opt.Value ~= "None" then
            if not showAll and not opt._isActive then continue end
            count = count + 1
            local modeStr = opt.Mode or "Toggle"
            local isActive = opt._isActive or (modeStr == "Always")
            local textColor = isActive and self.Theme.Accent or self.Theme.FontSecondary

            local entryHeight = 18
            local mainSize = 13
            local modeSize = 12
            local fontFace = self.FontRegular

            local entry = Create("Frame", {
                Size = UDim2.new(1, 0, 0, entryHeight),
                BackgroundTransparency = 1,
                LayoutOrder = count,
                Parent = listFrame,
            })

            Create("TextLabel", {
                Size = UDim2.new(0.65, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = (opt.Text or flag) .. " [" .. opt.Value .. "]",
                TextColor3 = textColor,
                FontFace = fontFace,
                TextSize = mainSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = entry,
            })

            Create("TextLabel", {
                Size = UDim2.new(0.35, 0, 1, 0),
                Position = UDim2.new(0.65, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = "(" .. modeStr .. ")",
                TextColor3 = textColor,
                FontFace = fontFace,
                TextSize = modeSize,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = entry,
            })
        end
    end

    local totalHeight = 34 + (count * 20)
    self._keybindFrame.Size = UDim2.new(0, 220, 0, math.max(30, totalHeight))
end

-- ============================================================
-- WINDOW
-- ============================================================

function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "JopLib"
    local center = options.Center ~= false
    local autoShow = options.AutoShow ~= false
    local windowWidth = options.Width or 700
    local windowHeight = options.Height or 500
    local tabPadding = options.TabPadding or 8

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    local screenGui = Create("ScreenGui", {
        Name = "JopLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })
    self.ScreenGui = screenGui

    -- Popup holder (renders dropdowns/colorpickers above everything)
    local popupHolder = Create("Frame", {
        Name = "PopupHolder",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = screenGui,
    })
    self._popupHolder = popupHolder

    -- Close popups on click outside (deferred by 1 frame to avoid stealing the triggering click)
    local outsideClickConn = UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not Library._openPopup then return end

        local mousePos = input.Position

        -- Check if click is on the trigger button (let the button's own handler deal with toggle)
        if Library._openPopupTrigger then
            local tp = Library._openPopupTrigger.AbsolutePosition
            local ts = Library._openPopupTrigger.AbsoluteSize
            if mousePos.X >= tp.X and mousePos.X <= tp.X + ts.X
                and mousePos.Y >= tp.Y and mousePos.Y <= tp.Y + ts.Y then
                return
            end
        end

        -- Check if click is inside the popup holder's children
        local isInsidePopup = false
        for _, child in ipairs(popupHolder:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                local pos = child.AbsolutePosition
                local size = child.AbsoluteSize
                if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X
                    and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                    isInsidePopup = true
                    break
                end
            end
        end

        if not isInsidePopup then
            task.defer(function()
                Library:ClosePopups()
            end)
        end
    end)
    table.insert(self.Connections, outsideClickConn)

    local windowPos
    if center then
        windowPos = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2)
    else
        windowPos = UDim2.new(0, 100, 0, 100)
    end

    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, windowWidth, 0, windowHeight),
        Position = windowPos,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", { Color = self.Theme.Border, Thickness = 1 }),
    })
    self.MainFrame = mainFrame

    if not autoShow then
        mainFrame.Visible = false
    end

    -- Title Bar
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })

    Create("Frame", {
        Name = "BottomCover",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    Create("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    MakeDraggable(mainFrame, titleBar)

    Create("TextLabel", {
        Name = "TitleText",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.FontPrimary,
        FontFace = self.FontBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    -- Tab Bar
    local tabBarContainer = Create("Frame", {
        Name = "TabBarContainer",
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundColor3 = self.Theme.TabBackground,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })

    local tabBarScroll = Create("ScrollingFrame", {
        Name = "TabBarScroll",
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        CanvasSize = UDim2.new(0, 0, 1, 0),
        Parent = tabBarContainer,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, tabPadding),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    -- Content Container
    local contentContainer = Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -12, 1, -70),
        Position = UDim2.new(0, 6, 0, 64),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = mainFrame,
    })

    -- Window object
    local Window = {}
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window._tabBarScroll = tabBarScroll
    Window._contentContainer = contentContainer
    Window._tabOrder = 0

    -- Toggle visibility keybind
    local toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if Library.Unloaded then return end

        local keybind = Library.ToggleKeybind
        if keybind then
            if type(keybind) == "table" and keybind.Value then
                local keyName = keybind.Value
                local match = false
                pcall(function()
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        match = keyName == input.KeyCode.Name
                    else
                        match = keyName == input.UserInputType.Name
                    end
                end)
                if match then Library:ToggleGui() end
            end
        else
            if input.KeyCode == Enum.KeyCode.RightControl then
                Library:ToggleGui()
            end
        end
    end)
    table.insert(Library.Connections, toggleConn)

    -- Keybind frame heartbeat
    self:CreateKeybindFrame()
    local kbConn = RunService.Heartbeat:Connect(function()
        if not Library.Unloaded then
            Library:UpdateKeybindFrame()
        end
    end)
    table.insert(Library.Connections, kbConn)

    -- ============================================================
    -- TAB
    -- ============================================================

    function Window:AddTab(tabName)
        Window._tabOrder = Window._tabOrder + 1
        local order = Window._tabOrder

        local tabBtn = Create("TextButton", {
            Name = "Tab_" .. tabName,
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme.TabInactive,
            BorderSizePixel = 0,
            Text = "",
            LayoutOrder = order,
            Parent = tabBarScroll,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Create("UIPadding", {
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            }),
            Create("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tabName,
                TextColor3 = Library.Theme.FontSecondary,
                FontFace = Library.FontSemiBold,
                TextSize = 13,
            }),
        })

        local tabPage = Create("Frame", {
            Name = "TabPage_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = contentContainer,
        })

        local leftColumn = Create("ScrollingFrame", {
            Name = "LeftColumn",
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ClipsDescendants = true,
            Parent = tabPage,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            }),
        })

        local rightColumn = Create("ScrollingFrame", {
            Name = "RightColumn",
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0.5, 4, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ClipsDescendants = true,
            Parent = tabPage,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            }),
        })

        local Tab = {}
        Tab.Name = tabName
        Tab._page = tabPage
        Tab._leftColumn = leftColumn
        Tab._rightColumn = rightColumn
        Tab._groupOrder = 0

        -- ============================================================
        -- GROUPBOX FACTORY
        -- ============================================================

        local function CreateGroupbox(name, parent)
            Tab._groupOrder = Tab._groupOrder + 1

            local groupbox = Create("Frame", {
                Name = "Groupbox_" .. name,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Theme.GroupboxBg,
                BorderSizePixel = 0,
                LayoutOrder = Tab._groupOrder,
                Parent = parent,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1 }),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                }),
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                }),
            })

            Create("TextLabel", {
                Name = "GroupTitle",
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Library.Theme.FontPrimary,
                FontFace = Library.FontBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 0,
                Parent = groupbox,
            })

            local elementContainer = Create("Frame", {
                Name = "Elements",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = groupbox,
            }, {
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                }),
            })

            local Groupbox = {}
            Groupbox.Name = name
            Groupbox._container = elementContainer
            Groupbox._elementOrder = 0

            function Groupbox:_nextOrder()
                self._elementOrder = self._elementOrder + 1
                return self._elementOrder
            end

            if Library._GroupboxMethods then
                for k, v in pairs(Library._GroupboxMethods) do
                    if type(v) == "function" then
                        Groupbox[k] = v
                    end
                end
            end

            return Groupbox
        end

        function Tab:AddLeftGroupbox(name)
            return CreateGroupbox(name, leftColumn)
        end

        function Tab:AddRightGroupbox(name)
            return CreateGroupbox(name, rightColumn)
        end

        -- ============================================================
        -- TABBOX (mini tab container inside a column)
        -- ============================================================

        local function CreateTabbox(parent)
            Tab._groupOrder = Tab._groupOrder + 1

            local tabboxFrame = Create("Frame", {
                Name = "Tabbox",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Theme.GroupboxBg,
                BorderSizePixel = 0,
                LayoutOrder = Tab._groupOrder,
                Parent = parent,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1 }),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                }),
                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                }),
            })

            local tabRow = Create("Frame", {
                Name = "TabRow",
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                LayoutOrder = 0,
                Parent = tabboxFrame,
            }, {
                Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 4),
                }),
            })

            local contentHolder = Create("Frame", {
                Name = "ContentHolder",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = tabboxFrame,
            })

            local TabBox = {}
            TabBox._tabRow = tabRow
            TabBox._contentHolder = contentHolder
            TabBox._tabs = {}
            TabBox._activeTab = nil
            TabBox._tabOrder = 0

            function TabBox:AddTab(name)
                TabBox._tabOrder = TabBox._tabOrder + 1
                local tOrder = TabBox._tabOrder

                local tbBtn = Create("TextButton", {
                    Name = "TBTab_" .. name,
                    Size = UDim2.new(0, 0, 0, 20),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = Library.Theme.TabInactive,
                    BorderSizePixel = 0,
                    Text = name,
                    TextColor3 = Library.Theme.FontSecondary,
                    FontFace = Library.FontSemiBold,
                    TextSize = 12,
                    LayoutOrder = tOrder,
                    Parent = tabRow,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                    Create("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                    }),
                })

                local tbContent = Create("Frame", {
                    Name = "TBContent_" .. name,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible = false,
                    Parent = contentHolder,
                }, {
                    Create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 4),
                    }),
                })

                local tbTab = {}
                tbTab.Name = name
                tbTab._btn = tbBtn
                tbTab._content = tbContent
                tbTab._container = tbContent
                tbTab._elementOrder = 0

                function tbTab:_nextOrder()
                    self._elementOrder = self._elementOrder + 1
                    return self._elementOrder
                end

                if Library._GroupboxMethods then
                    for k, v in pairs(Library._GroupboxMethods) do
                        if type(v) == "function" then
                            tbTab[k] = v
                        end
                    end
                end

                tbBtn.MouseButton1Click:Connect(function()
                    for _, t in ipairs(TabBox._tabs) do
                        t._content.Visible = false
                        t._btn.BackgroundColor3 = Library.Theme.TabInactive
                        t._btn.TextColor3 = Library.Theme.FontSecondary
                    end
                    tbContent.Visible = true
                    tbBtn.BackgroundColor3 = Library.Theme.TabActive
                    tbBtn.TextColor3 = Library.Theme.FontPrimary
                    TabBox._activeTab = tbTab
                end)

                table.insert(TabBox._tabs, tbTab)

                if #TabBox._tabs == 1 then
                    tbContent.Visible = true
                    tbBtn.BackgroundColor3 = Library.Theme.TabActive
                    tbBtn.TextColor3 = Library.Theme.FontPrimary
                    TabBox._activeTab = tbTab
                end

                return tbTab
            end

            return TabBox
        end

        function Tab:AddLeftTabbox()
            return CreateTabbox(leftColumn)
        end

        function Tab:AddRightTabbox()
            return CreateTabbox(rightColumn)
        end

        -- Tab switching
        tabBtn.MouseButton1Click:Connect(function()
            Library:ClosePopups()
            Window:SwitchTab(Tab)
        end)

        Window.Tabs[tabName] = Tab

        if Window.ActiveTab == nil then
            Window:SwitchTab(Tab)
        end

        return Tab
    end

    function Window:SwitchTab(tab)
        for _, t in pairs(Window.Tabs) do
            t._page.Visible = false
            local btn = tabBarScroll:FindFirstChild("Tab_" .. t.Name)
            if btn then
                btn.BackgroundColor3 = Library.Theme.TabInactive
                local label = btn:FindFirstChild("Label")
                if label then
                    label.TextColor3 = Library.Theme.FontSecondary
                end
            end
        end

        tab._page.Visible = true
        local btn = tabBarScroll:FindFirstChild("Tab_" .. tab.Name)
        if btn then
            btn.BackgroundColor3 = Library.Theme.TabActive
            local label = btn:FindFirstChild("Label")
            if label then
                label.TextColor3 = Library.Theme.FontPrimary
            end
        end

        Window.ActiveTab = tab
    end

    self.Window = Window
    return Window
end

-- ============================================================
-- TOGGLE GUI VISIBILITY
-- ============================================================

function Library:ToggleGui()
    self.Toggled = not self.Toggled
    if self.MainFrame then
        self.MainFrame.Visible = self.Toggled
    end
end

-- ============================================================
-- ON UNLOAD CALLBACK
-- ============================================================

function Library:OnUnload(fn)
    table.insert(self._unloadCallbacks, fn)
end

-- ============================================================
-- UNLOAD
-- ============================================================

function Library:Unload()
    self.Unloaded = true

    for _, fn in ipairs(self._unloadCallbacks) do
        pcall(fn)
    end

    for _, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.Connections = {}

    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    if self._watermarkGui then
        self._watermarkGui:Destroy()
        self._watermarkGui = nil
    end

    if self._keybindGui then
        self._keybindGui:Destroy()
        self._keybindGui = nil
    end

    if NotificationHolder then
        NotificationHolder:Destroy()
        NotificationHolder = nil
    end
end

return Library
