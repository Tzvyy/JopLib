--[[
    JopLib - UI Library for Roblox
    Library.lua - Core: Window, Tabs, Groupboxes, Layout, Dragging, Minimize, Module List
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

-- Theming tables (populated by ThemeManager)
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

-- Element registries
Library.Elements = {}
Library.Flags = {}
Library.Connections = {}
Library.Modules = {}
Library.ModuleListGui = nil
Library.ModuleListEnabled = false
Library.ModuleListMode = 1

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
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = holder,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
        Create("UIStroke", { Color = self.Theme.Border, Thickness = 1 }),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -16, 1, -10),
            Position = UDim2.new(0, 8, 0, 5),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = self.Theme.FontPrimary,
            FontFace = self.FontRegular,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }),
    })

    -- Calculate needed height
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
-- MODULE LIST WIDGET
-- ============================================================

function Library:AddModule(info)
    table.insert(self.Modules, {
        Name = info.Name or "Module",
        Toggle = info.Toggle,
        Keybind = info.Keybind or nil,
    })
end

function Library:CreateModuleListGui()
    if self.ModuleListGui then
        self.ModuleListGui:Destroy()
    end

    local gui = Create("ScreenGui", {
        Name = "JopLibModuleList",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })
    self.ModuleListGui = gui

    local frame = Create("Frame", {
        Name = "ModuleListFrame",
        Size = UDim2.new(0, 180, 0, 30),
        Position = UDim2.new(0, 10, 0, 300),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = gui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Create("UIStroke", { Color = Color3.fromRGB(50, 50, 50), Thickness = 1 }),
        Create("Frame", {
            Name = "AccentBar",
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -8, 0, 20),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundTransparency = 1,
            Text = "Keybinds",
            TextColor3 = Color3.fromRGB(200, 200, 200),
            TextSize = 13,
            FontFace = self.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    MakeDraggable(frame)

    local listFrame = Create("Frame", {
        Name = "List",
        Size = UDim2.new(1, -8, 1, -28),
        Position = UDim2.new(0, 4, 0, 26),
        BackgroundTransparency = 1,
        Parent = frame,
    }, {
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 1),
        }),
    })

    self._moduleListFrame = frame
    self._moduleListEntries = {}

    for i, def in ipairs(self.Modules) do
        local entry = Create("Frame", {
            Name = "Entry_" .. def.Name,
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            LayoutOrder = i,
            Parent = listFrame,
        })

        local label = Create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0.5, -2, 1, 0),
            Position = UDim2.new(0, 2, 0, 0),
            BackgroundTransparency = 1,
            Text = def.Name,
            TextColor3 = Color3.fromRGB(140, 140, 140),
            TextSize = 12,
            FontFace = self.FontRegular,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = entry,
        })

        local kbLabel = Create("TextLabel", {
            Name = "Keybind",
            Size = UDim2.new(0.5, -2, 1, 0),
            Position = UDim2.new(0.5, 2, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = 11,
            FontFace = self.FontRegular,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = entry,
        })

        self._moduleListEntries[i] = {
            frame = entry,
            label = label,
            keybindLabel = kbLabel,
            def = def,
        }
    end

    return gui
end

function Library:UpdateModuleList()
    if not self.ModuleListEnabled or not self.ModuleListGui or not self.ModuleListGui.Parent then return end

    local toggles = getgenv().Toggles
    local opts = getgenv().Options
    if not toggles or not opts then return end

    local accent = self.Theme.Accent
    local bar = self._moduleListFrame and self._moduleListFrame:FindFirstChild("AccentBar")
    if bar then bar.BackgroundColor3 = accent end

    local visibleCount = 0

    for _, entry in ipairs(self._moduleListEntries or {}) do
        local def = entry.def
        local toggle = toggles[def.Toggle]
        local isEnabled = toggle and toggle.Value or false

        local kbText = "[None]"
        local modeText = ""
        if def.Keybind and opts[def.Keybind] then
            local kp = opts[def.Keybind]
            pcall(function()
                kbText = "[" .. (kp.Value or "None") .. "]"
                modeText = "(" .. (kp.Mode or "Toggle") .. ")"
            end)
        end

        if self.ModuleListMode == 2 and not isEnabled then
            entry.frame.Visible = false
        else
            entry.frame.Visible = true
            visibleCount = visibleCount + 1

            if isEnabled then
                entry.label.TextColor3 = accent
                entry.label.FontFace = self.FontBold
            else
                entry.label.TextColor3 = Color3.fromRGB(140, 140, 140)
                entry.label.FontFace = self.FontRegular
            end

            if modeText ~= "" then
                entry.keybindLabel.Text = modeText .. " " .. kbText
            else
                entry.keybindLabel.Text = kbText
            end
        end
    end

    local totalHeight = 28 + (visibleCount * 17)
    self._moduleListFrame.Size = UDim2.new(0, 180, 0, math.max(30, totalHeight))
end

-- ============================================================
-- WINDOW
-- ============================================================

function Library:CreateWindow(options)
    options = options or {}
    local title = options.Title or "JopLib"
    local center = options.Center ~= false
    local autoShow = options.AutoShow ~= false
    local windowWidth = options.Width or 550
    local windowHeight = options.Height or 400

    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "JopLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })
    self.ScreenGui = screenGui

    -- Main Window Frame
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
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        Parent = mainFrame,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })

    -- Bottom cover for title bar corner (so only top corners are rounded)
    Create("Frame", {
        Name = "BottomCover",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    -- Accent line under title bar
    Create("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = titleBar,
    })

    MakeDraggable(mainFrame, titleBar)

    -- Title text
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

    -- Minimize button
    local minimizeBtn = Create("TextButton", {
        Name = "MinimizeBtn",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Text = "-",
        TextColor3 = self.Theme.FontPrimary,
        FontFace = self.FontBold,
        TextSize = 16,
        Parent = titleBar,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
    })

    -- Tab Bar Container (below title bar)
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
            Padding = UDim.new(0, 4),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })

    -- Content Container (below tab bar, holds tab pages)
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

    -- Minimize logic
    local minimized = false
    local fullSize = mainFrame.Size

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(mainFrame, {Size = UDim2.new(0, windowWidth, 0, 34)}, 0.2):Play()
            minimizeBtn.Text = "+"
        else
            Tween(mainFrame, {Size = fullSize}, 0.2):Play()
            minimizeBtn.Text = "-"
        end
    end)

    -- Toggle visibility keybind
    local toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if Library.Unloaded then return end

        local keybind = Library.ToggleKeybind
        if keybind then
            -- If ToggleKeybind is an Options KeyPicker object
            if type(keybind) == "table" and keybind.Value then
                local keyName = keybind.Value
                if keyName == input.KeyCode.Name or keyName == input.UserInputType.Name then
                    Library:ToggleGui()
                end
            end
        else
            -- Default: RightControl
            if input.KeyCode == Enum.KeyCode.RightControl then
                Library:ToggleGui()
            end
        end
    end)
    table.insert(Library.Connections, toggleConn)

    -- Module list heartbeat
    local mlConn = RunService.Heartbeat:Connect(function()
        if Library.ModuleListEnabled then
            Library:UpdateModuleList()
        end
    end)
    table.insert(Library.Connections, mlConn)

    -- ============================================================
    -- TAB
    -- ============================================================

    function Window:AddTab(tabName)
        Window._tabOrder = Window._tabOrder + 1
        local order = Window._tabOrder

        -- Tab button
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

        -- Tab content page (two columns)
        local tabPage = Create("Frame", {
            Name = "TabPage_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = contentContainer,
        })

        -- Left column
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
            Parent = tabPage,
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
            }),
        })

        -- Right column
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
        -- GROUPBOX
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
            })

            -- Groupbox title
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

            -- Element container inside groupbox
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

            -- Returns a properly ordered container frame for elements
            function Groupbox:_nextOrder()
                self._elementOrder = self._elementOrder + 1
                return self._elementOrder
            end

            -- Inject element methods from _GroupboxMethods
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

        -- Tab switching
        tabBtn.MouseButton1Click:Connect(function()
            Window:SwitchTab(Tab)
        end)

        Window.Tabs[tabName] = Tab

        -- Activate first tab automatically
        if Window.ActiveTab == nil then
            Window:SwitchTab(Tab)
        end

        return Tab
    end

    function Window:SwitchTab(tab)
        -- Deactivate all tabs
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

        -- Activate selected tab
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
-- UNLOAD
-- ============================================================

function Library:Unload()
    self.Unloaded = true

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

    if self.ModuleListGui then
        self.ModuleListGui:Destroy()
        self.ModuleListGui = nil
    end

    if NotificationHolder then
        NotificationHolder:Destroy()
        NotificationHolder = nil
    end
end

-- ============================================================
-- APPLY THEME (called by ThemeManager)
-- ============================================================

function Library:UpdateThemeColors()
    self.AccentColor = self.Theme.Accent
    -- Theme updates propagate via element :UpdateColors() methods
    -- Each element stores references and updates them
end

return Library
