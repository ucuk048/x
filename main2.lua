-- ==============================================================================
-- ANTIGRAVITY COMPLETE ENTERPRISE GAME HUB & RUNTIME PAYLOAD
-- Fitur: Visuals/ESP, Movement Physics, World Utilities, Teleport, Config Persistence
-- ==============================================================================

local CoreHub = {
    Name = "Antigravity Hub",
    Version = "3.0.0",
    ConfigFile = "antigravity_hub_config.json",
    WaypointsFile = "antigravity_waypoints.json",
    State = {
        ActiveTab = "Visuals",
        Config = {},
        Waypoints = {},
        Connections = {},
        EspObjects = {},
        NoclipActive = false,
        FlyActive = false,
        InfJumpActive = false,
        FlySpeed = 50,
        IsVisible = true
    }
}

-- 1. RESOLUSI LAYANAN GAME ENGINE
local Services = {
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    TeleportService = game:GetService("TeleportService"),
    VirtualUser = game:GetService("VirtualUser")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") or Services.CoreGui

local function getSafeUIParent()
    if gethui then
        return gethui()
    end
    local success, _ = pcall(function() return Services.CoreGui.Name end)
    if success then
        return Services.CoreGui
    end
    return PlayerGui
end

-- 2. SISTEM PERSISTENSI KONFIGURASI
function CoreHub:LoadConfig()
    self.State.Config = {
        Theme = "DarkSlate",
        EspEnabled = false,
        EspBoxes = true,
        EspNames = true,
        EspDistance = true,
        EspChams = true,
        WalkSpeed = 16,
        JumpPower = 50,
        FullBright = false,
        AntiAfk = true,
        AutoSave = true
    }
    if isfile and readfile and isfile(self.ConfigFile) then
        pcall(function()
            local decoded = Services.HttpService:JSONDecode(readfile(self.ConfigFile))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    self.State.Config[k] = v
                end
            end
        end)
    end
end

function CoreHub:SaveConfig()
    if writefile and self.State.Config.AutoSave then
        pcall(function()
            writefile(self.ConfigFile, Services.HttpService:JSONEncode(self.State.Config))
        end)
    end
end

-- 3. ANIMATION TWEEN HELPER
local function tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local anim = Services.TweenService:Create(object, tweenInfo, properties)
    anim:Play()
    return anim
end

-- 4. PEMBERSIHAN INSTANCE LAMA (CLEANUP)
local OldUI = getSafeUIParent():FindFirstChild("AntigravityMainUI")
if OldUI then OldUI:Destroy() end

-- 5. PEMBUATAN ELEMEN GUI UTAMA
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntigravityMainUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getSafeUIParent()

-- Toggle Button Mengambang (Khusus Mobile / Touch)
local FloatToggle = Instance.new("TextButton")
FloatToggle.Name = "FloatToggle"
FloatToggle.Size = UDim2.new(0, 44, 0, 44)
FloatToggle.Position = UDim2.new(0, 15, 0.5, -22)
FloatToggle.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
FloatToggle.Text = "⚡"
FloatToggle.TextSize = 20
FloatToggle.TextColor3 = Color3.fromRGB(56, 189, 248)
FloatToggle.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatToggle

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 1.5
FloatStroke.Color = Color3.fromRGB(56, 189, 248)
FloatStroke.Parent = FloatToggle

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 410)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -205)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(51, 65, 85)
MainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "  ⚡ " .. CoreHub.Name .. "  <font color='#38bdf8'>v" .. CoreHub.Version .. "</font>  <font color='#64748b'>[Enterprise Suite]</font>"
TitleLabel.RichText = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local CloseButton = Instance.new("TextButton")
CloseButton.Text = "✕"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(148, 163, 184)
CloseButton.BackgroundTransparency = 1
CloseButton.Size = UDim2.new(0, 32, 0, 32)
CloseButton.Position = UDim2.new(1, -38, 0, 5)
CloseButton.Parent = Topbar

local function toggleUI()
    CoreHub.State.IsVisible = not CoreHub.State.IsVisible
    MainFrame.Visible = CoreHub.State.IsVisible
end

FloatToggle.MouseButton1Click:Connect(toggleUI)
CloseButton.MouseButton1Click:Connect(toggleUI)

-- Dragging Topbar
local isDragging, dragStart, startPos = false, nil, nil
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
Topbar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)
Services.UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -42)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 27, 45)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = Sidebar

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 8)
SidebarPad.PaddingLeft = UDim.new(0, 8)
SidebarPad.PaddingRight = UDim.new(0, 8)
SidebarPad.Parent = Sidebar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -148, 1, -50)
ContentContainer.Position = UDim2.new(0, 144, 0, 46)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Tab Builder
local Tabs = {}
local TabButtons = {}

local function createTab(tabName, isDefault)
    local TabPage = Instance.new("ScrollingFrame")
    TabPage.Name = tabName .. "Page"
    TabPage.Size = UDim2.new(1, 0, 1, 0)
    TabPage.BackgroundTransparency = 1
    TabPage.ScrollBarThickness = 3
    TabPage.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
    TabPage.Visible = isDefault or false
    TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabPage.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.Parent = TabPage

    local PagePad = Instance.new("UIPadding")
    PagePad.PaddingTop = UDim.new(0, 4)
    PagePad.PaddingBottom = UDim.new(0, 12)
    PagePad.PaddingRight = UDim.new(0, 6)
    PagePad.Parent = TabPage

    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = tabName .. "Btn"
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.Text = "  " .. tabName
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 12
    TabBtn.TextColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
    TabBtn.BackgroundColor3 = isDefault and Color3.fromRGB(30, 41, 59) or Color3.fromRGB(20, 27, 45)
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        for name, page in pairs(Tabs) do
            page.Visible = (name == tabName)
        end
        for _, btn in pairs(TabButtons) do
            tween(btn, { BackgroundColor3 = Color3.fromRGB(20, 27, 45), TextColor3 = Color3.fromRGB(148, 163, 184) }, 0.2)
        end
        tween(TabBtn, { BackgroundColor3 = Color3.fromRGB(30, 41, 59), TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
        CoreHub.State.ActiveTab = tabName
    end)

    Tabs[tabName] = TabPage
    TabButtons[tabName] = TabBtn
    return TabPage
end

-- Component Builders
local function addSection(parent, title)
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size = UDim2.new(1, 0, 0, 20)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Text = title:upper()
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.TextSize = 10
    SectionLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Parent = parent
end

local function addToggle(parent, title, configKey, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(241, 245, 249)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 36, 0, 18)
    Switch.Position = UDim2.new(1, -46, 0.5, -9)
    Switch.BackgroundColor3 = defaultVal and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(71, 85, 105)
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local isEnabled = defaultVal
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = Frame

    Btn.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        CoreHub.State.Config[configKey] = isEnabled
        CoreHub:SaveConfig()

        if isEnabled then
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(56, 189, 248) }, 0.2)
            tween(Knob, { Position = UDim2.new(1, -16, 0.5, -7) }, 0.2)
        else
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(71, 85, 105) }, 0.2)
            tween(Knob, { Position = UDim2.new(0, 2, 0.5, -7) }, 0.2)
        end
        if callback then callback(isEnabled) end
    end)
end

local function addButton(parent, title, btnText, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(241, 245, 249)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, 85, 0, 24)
    ActionBtn.Position = UDim2.new(1, -95, 0.5, -12)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
    ActionBtn.Text = btnText or "Terapkan"
    ActionBtn.Font = Enum.Font.GothamMedium
    ActionBtn.TextSize = 11
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ActionBtn

    ActionBtn.MouseButton1Click:Connect(function()
        tween(ActionBtn, { BackgroundColor3 = Color3.fromRGB(56, 189, 248) }, 0.1)
        task.wait(0.12)
        tween(ActionBtn, { BackgroundColor3 = Color3.fromRGB(14, 165, 233) }, 0.2)
        if callback then callback() end
    end)
end

local function addSlider(parent, title, minVal, maxVal, currentVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(241, 245, 249)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.25, 0, 0, 20)
    ValLabel.Position = UDim2.new(0.75, -10, 0, 4)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(math.floor(currentVal))
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 12
    ValLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -20, 0, 6)
    SliderBar.Position = UDim2.new(0, 10, 0, 32)
    SliderBar.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
    SliderBar.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    local pct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
    FillBar.Size = UDim2.new(pct, 0, 1, 0)
    FillBar.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local isDraggingSlider = false
    local function updateSlider(inputX)
        local rel = math.clamp((inputX - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local value = math.floor(minVal + (maxVal - minVal) * rel)
        FillBar.Size = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            updateSlider(input.Position.X)
        end
    end)
    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
end

-- ==============================================================================
-- 6. FITUR: VISUALS / ESP ENGINE (HIGHLIGHT & BILLBOARD)
-- ==============================================================================
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not root or not hum then return end

        -- 1. Highlight / Chams
        local highlight = char:FindFirstChild("AgyHighlight") or Instance.new("Highlight")
        highlight.Name = "AgyHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(239, 68, 68) -- Red
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = CoreHub.State.Config.EspEnabled
        highlight.Parent = char

        -- 2. Name & Distance Billboard
        local tag = root:FindFirstChild("AgyNameTag") or Instance.new("BillboardGui")
        tag.Name = "AgyNameTag"
        tag.Adornee = root
        tag.Size = UDim2.new(0, 120, 0, 36)
        tag.StudsOffset = Vector3.new(0, 2.5, 0)
        tag.AlwaysOnTop = true
        tag.Enabled = CoreHub.State.Config.EspEnabled
        tag.Parent = root

        local tagLabel = tag:FindFirstChild("Label") or Instance.new("TextLabel")
        tagLabel.Name = "Label"
        tagLabel.Size = UDim2.new(1, 0, 1, 0)
        tagLabel.BackgroundTransparency = 1
        tagLabel.Font = Enum.Font.GothamBold
        tagLabel.TextSize = 11
        tagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        tagLabel.TextStrokeTransparency = 0.3
        tagLabel.Parent = tag

        CoreHub.State.EspObjects[player] = { Highlight = highlight, Tag = tag, Label = tagLabel, Root = root, Hum = hum }
    end

    if player.Character then setupChar(player.Character) end
    player.CharacterAdded:Connect(setupChar)
end

for _, p in ipairs(Services.Players:GetPlayers()) do
    applyESP(p)
end
Services.Players.PlayerAdded:Connect(applyESP)

-- Update ESP Labels (Distance & Health)
Services.RunService.RenderStepped:Connect(function()
    if not CoreHub.State.Config.EspEnabled then return end
    local myRoot = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for player, data in pairs(CoreHub.State.EspObjects) do
        if data.Root and data.Root.Parent and data.Label then
            local dist = math.floor((myRoot.Position - data.Root.Position).Magnitude)
            local hp = data.Hum and math.floor(data.Hum.Health) or 0
            data.Label.Text = string.format("%s\n[%d HP | %dm]", player.Name, hp, dist)
        end
    end
end)

-- ==============================================================================
-- 7. FITUR: MOVEMENT ENGINE (NOCLIP, FLY, INFINITE JUMP)
-- ==============================================================================
-- Noclip via Stepped
Services.RunService.Stepped:Connect(function()
    if CoreHub.State.NoclipActive and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
Services.UserInputService.JumpRequest:Connect(function()
    if CoreHub.State.InfJumpActive and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Fly Engine (BodyVelocity & BodyGyro)
local flyBV, flyBG = nil, nil
local function setFly(enabled)
    CoreHub.State.FlyActive = enabled
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if enabled then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = root

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.CFrame = root.CFrame
        flyBG.Parent = root
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end

Services.RunService.RenderStepped:Connect(function()
    if CoreHub.State.FlyActive and flyBV and flyBG and Camera then
        local moveDir = Vector3.new(0, 0, 0)
        local uis = Services.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        flyBV.Velocity = moveDir * CoreHub.State.FlySpeed
        flyBG.CFrame = Camera.CFrame
    end
end)

-- ==============================================================================
-- 8. FITUR: WORLD UTILITIES (FULLBRIGHT, ANTI-AFK, SERVER REJOIN)
-- ==============================================================================
-- Fullbright
local function setFullBright(enabled)
    if enabled then
        Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Services.Lighting.Brightness = 2
        Services.Lighting.ClockTime = 14
        Services.Lighting.FogEnd = 1e5
    else
        Services.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Services.Lighting.Brightness = 1
        Services.Lighting.FogEnd = 1000
    end
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if CoreHub.State.Config.AntiAfk then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==============================================================================
-- 9. PEMASANGAN TABS & KONTROL UI
-- ==============================================================================
CoreHub:LoadConfig()

-- Tab 1: Visuals (ESP)
local VisualsPage = createTab("Visuals", true)
addSection(VisualsPage, "Pengaturan Wallhack & ESP")
addToggle(VisualsPage, "Aktifkan Seluruh ESP", "EspEnabled", CoreHub.State.Config.EspEnabled, function(val)
    for _, data in pairs(CoreHub.State.EspObjects) do
        if data.Highlight then data.Highlight.Enabled = val end
        if data.Tag then data.Tag.Enabled = val end
    end
end)
addToggle(VisualsPage, "Chams (Highlight Merah)", "EspChams", CoreHub.State.Config.EspChams, function(val)
    for _, data in pairs(CoreHub.State.EspObjects) do
        if data.Highlight then data.Highlight.FillTransparency = val and 0.5 or 1 end
    end
end)

-- Tab 2: Movement (Pergerakan)
local MovePage = createTab("Movement", false)
addSection(MovePage, "Modifikasi Kecepatan & Fisika")
addSlider(MovePage, "Kecepatan Karakter (WalkSpeed)", 16, 200, CoreHub.State.Config.WalkSpeed, function(val)
    CoreHub.State.Config.WalkSpeed = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)
addSlider(MovePage, "Kekuatan Lompatan (JumpPower)", 50, 300, CoreHub.State.Config.JumpPower, function(val)
    CoreHub.State.Config.JumpPower = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)
addToggle(MovePage, "Menembus Dinding (Noclip)", "Noclip", false, function(val)
    CoreHub.State.NoclipActive = val
end)
addToggle(MovePage, "Lompatan Tanpa Batas (Infinite Jump)", "InfJump", false, function(val)
    CoreHub.State.InfJumpActive = val
end)
addToggle(MovePage, "Mode Terbang Bebas (Fly)", "Fly", false, function(val)
    setFly(val)
end)

-- Tab 3: World & Utilitas
local WorldPage = createTab("World & Tools", false)
addSection(WorldPage, "Lingkungan & Server")
addToggle(WorldPage, "Penerangan Penuh (FullBright)", "FullBright", CoreHub.State.Config.FullBright, function(val)
    setFullBright(val)
end)
addToggle(WorldPage, "Anti-AFK (Cegah Disconnect 20 Menit)", "AntiAfk", CoreHub.State.Config.AntiAfk, function(val)
    CoreHub.State.Config.AntiAfk = val
end)
addButton(WorldPage, "Gabung Ulang Server Ini (Rejoin)", "Rejoin", function()
    Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- Tab 4: Teleport (Koordinat)
local TeleportPage = createTab("Teleport", false)
addSection(TeleportPage, "Pengelola Titik Koordinat")
local savedPos = nil
addButton(TeleportPage, "Simpan Posisi Karakter Saat Ini", "Simpan", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        savedPos = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end)
addButton(TeleportPage, "Teleport ke Titik Tersimpan", "Teleport", function()
    if savedPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = savedPos
    end
end)

-- Tab 5: Pengaturan
local SettingsPage = createTab("Pengaturan", false)
addSection(SettingsPage, "Sistem & Lisensi")
addButton(SettingsPage, "Simpan Konfigurasi ke File", "Simpan", function()
    CoreHub:SaveConfig()
end)
addButton(SettingsPage, "Hapus Cache Lisensi Lokal", "Reset Kunci", function()
    if delfile and isfile and isfile("antigravity_license_key.txt") then
        delfile("antigravity_license_key.txt")
    end
end)

-- ==============================================================================
-- 10. OVERLAY DIAGNOSTIK & SINYAL HANDSHAKE KE INDUK
-- ==============================================================================
local Overlay = Instance.new("TextLabel")
Overlay.Size = UDim2.new(0, 150, 0, 22)
Overlay.Position = UDim2.new(0, 65, 0, 15)
Overlay.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
Overlay.BackgroundTransparency = 0.3
Overlay.TextColor3 = Color3.fromRGB(56, 189, 248)
Overlay.Font = Enum.Font.GothamMedium
Overlay.TextSize = 11
Overlay.Parent = ScreenGui

local OverCorner = Instance.new("UICorner")
OverCorner.CornerRadius = UDim.new(0, 6)
OverCorner.Parent = Overlay

local frames = {}
Services.RunService.RenderStepped:Connect(function(dt)
    table.insert(frames, dt)
    if #frames > 20 then table.remove(frames, 1) end
    local sum = 0
    for _, f in ipairs(frames) do sum = sum + f end
    local fps = math.floor(#frames / sum)
    Overlay.Text = string.format(" ⚡ FPS: %d | %s", fps, CoreHub.State.ActiveTab)
end)

-- Kunci pintasan keyboard (RightShift untuk buka/tutup)
Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        toggleUI()
    end
end)

shared._agyGameLoaded = true
shared._agyGameReady = true
print("[ANTIGRAVITY] Enterprise Suite Payload v" .. CoreHub.Version .. " siap beroperasi.")

return CoreHub
