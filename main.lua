-- ==============================================================================
-- ANTIGRAVITY ALL-IN-ONE DIRECT RUNNER (lua2.txt)
-- Menggabungkan seluruh mekanisme loader.txt (Flight-Lock & Safe Boundary),
-- struktur katalog lua.txt (Game Profiles & Auto-Detect),
-- serta fitur penuh payload.lua (ESP, Movement, Fly, Teleport, Anti-AFK, FPS, JSON Config)
-- TANPA SISTEM VERIFIKASI / KEY-FREE (Langsung Eksekusi)
-- ==============================================================================

local HUB_NAME = "Antigravity Hub"
local HUB_VERSION = "3.2.0"
local CONFIG_FILE = "antigravity_hub_config.json"

-- ==============================================================================
-- 1. MEKANISME DARI LOADER.TXT: FLIGHT LOCK & CONCURRENCY GUARD
-- Mencegah eksekusi ganda jika skrip sedang dalam proses memuat di memori
-- ==============================================================================
local _flight = shared._agyLoaderFlight
if type(_flight) == "table" and _flight.Running and os.clock() - (_flight.StartedAt or 0) < 600 then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = HUB_NAME,
            Text = HUB_NAME .. " sedang berjalan di memori. Mohon tunggu.",
            Duration = 5
        })
    end)
    return
end

_flight = { Running = true, Ready = false, StartedAt = os.clock() }
shared._agyLoaderFlight = _flight

-- Global Cleanup (seperti pada lua.txt)
if type(_G.AntigravityHubLoader) == "table" and _G.AntigravityHubLoader.Cleanup then
    pcall(function()
        _G.AntigravityHubLoader.Cleanup()
    end)
end
_G.AntigravityHubLoader = {}

-- Safe Execution Boundary (pcall seperti loader.txt)
local _ok, _err = pcall(function(...)

-- ==============================================================================
-- 2. RESOLUSI LAYANAN GAME ENGINE
-- ==============================================================================
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

local function tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local anim = Services.TweenService:Create(object, tweenInfo, properties)
    anim:Play()
    return anim
end

-- ==============================================================================
-- 3. STRUKTUR KATALOG GAME DARI LUA.TXT
-- ==============================================================================
local CATALOG = {
    {
        Key = "universal",
        Name = "Universal Game Suite",
        Places = { 0 },
        Universe = 0,
        Tone = Color3.fromRGB(56, 189, 248),
        Listed = true,
    },
    {
        Key = "rivals",
        Name = "RIVALS",
        Places = { 17625359962, 71874690745115, 117398147513099, 129604661913557, 133215910299950, 18126510175 },
        Universe = 6035872082,
        Tone = Color3.fromRGB(90, 169, 255),
        Listed = true,
    },
    {
        Key = "mm2",
        Name = "Murder Mystery 2",
        Places = { 142823291 },
        Universe = 66654135,
        Tone = Color3.fromRGB(214, 68, 88),
        Listed = true,
    },
    {
        Key = "bloxfruits",
        Name = "Blox Fruits",
        Places = { 2753915549, 4442272183, 7449423635 },
        Universe = 1000000000,
        Tone = Color3.fromRGB(236, 176, 72),
        Listed = true,
    }
}

local function matchPlace(placeId, universeId)
    for _, entry in ipairs(CATALOG) do
        if entry.Universe and entry.Universe == universeId then
            return entry
        end
        for _, id in ipairs(entry.Places) do
            if id == placeId then
                return entry
            end
        end
    end
    return CATALOG[1] -- Fallback ke Universal
end

-- ==============================================================================
-- 4. SISTEM PERSISTENSI KONFIGURASI DARI PAYLOAD.LUA (JSON AUTO-SAVE / LOAD)
-- ==============================================================================
local CoreState = {
    Config = {
        EspEnabled = false,
        EspChams = true,
        WalkSpeed = 16,
        JumpPower = 50,
        FullBright = false,
        AntiAfk = true,
        PerformanceOverlay = true,
        AutoSave = true
    },
    EspObjects = {},
    NoclipActive = false,
    FlyActive = false,
    InfJumpActive = false,
    FlySpeed = 50,
    IsVisible = true,
    SavedPos = nil
}

local function loadConfig()
    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function()
            local decoded = Services.HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    CoreState.Config[k] = v
                end
            end
        end)
    end
end

local function saveConfig()
    if writefile and CoreState.Config.AutoSave then
        pcall(function()
            writefile(CONFIG_FILE, Services.HttpService:JSONEncode(CoreState.Config))
        end)
    end
end

loadConfig()

-- ==============================================================================
-- 5. PEMBUATAN INTERFACE MANDIRI (PURE STANDALONE GUI)
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntigravityDirectUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getSafeUIParent()

-- Floating Button (Mobile Friendly)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 44, 0, 44)
FloatBtn.Position = UDim2.new(0, 15, 0.5, -22)
FloatBtn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
FloatBtn.Text = "⚡"
FloatBtn.TextSize = 20
FloatBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 1.5
FloatStroke.Color = Color3.fromRGB(56, 189, 248)
FloatStroke.Parent = FloatBtn

-- Main Card Frame
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
TitleLabel.Text = "  ⚡ " .. HUB_NAME .. "  <font color='#38bdf8'>v" .. HUB_VERSION .. "</font>  <font color='#4ade80'>[Direct / No Key]</font>"
TitleLabel.RichText = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.Parent = Topbar

local function toggleUI()
    CoreState.IsVisible = not CoreState.IsVisible
    MainFrame.Visible = CoreState.IsVisible
end

FloatBtn.MouseButton1Click:Connect(toggleUI)
CloseBtn.MouseButton1Click:Connect(toggleUI)

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

-- Tab System
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
    end)

    Tabs[tabName] = TabPage
    TabButtons[tabName] = TabBtn
    return TabPage
end

-- Component Builders
local function addSection(parent, title)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = title:upper()
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.TextColor3 = Color3.fromRGB(56, 189, 248)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
end

local function addToggle(parent, title, defaultVal, callback)
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
        if isEnabled then
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(56, 189, 248) }, 0.2)
            tween(Knob, { Position = UDim2.new(1, -16, 0.5, -7) }, 0.2)
        else
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(71, 85, 105) }, 0.2)
            tween(Knob, { Position = UDim2.new(0, 2, 0.5, -7) }, 0.2)
        end
        if callback then callback(isEnabled) end
        saveConfig()
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
        saveConfig()
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
-- 6. FITUR DARI PAYLOAD: VISUALS (ESP & CHAMS HIGHLIGHT)
-- ==============================================================================
local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupChar(char)
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not root or not hum then return end

        local highlight = char:FindFirstChild("AgyHighlight") or Instance.new("Highlight")
        highlight.Name = "AgyHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(239, 68, 68)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = CoreState.Config.EspEnabled
        highlight.Parent = char

        local tag = root:FindFirstChild("AgyNameTag") or Instance.new("BillboardGui")
        tag.Name = "AgyNameTag"
        tag.Adornee = root
        tag.Size = UDim2.new(0, 120, 0, 36)
        tag.StudsOffset = Vector3.new(0, 2.5, 0)
        tag.AlwaysOnTop = true
        tag.Enabled = CoreState.Config.EspEnabled
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

        CoreState.EspObjects[player] = { Highlight = highlight, Tag = tag, Label = tagLabel, Root = root, Hum = hum }
    end
    if player.Character then setupChar(player.Character) end
    player.CharacterAdded:Connect(setupChar)
end

for _, p in ipairs(Services.Players:GetPlayers()) do applyESP(p) end
Services.Players.PlayerAdded:Connect(applyESP)

Services.RunService.RenderStepped:Connect(function()
    if not CoreState.Config.EspEnabled then return end
    local myRoot = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for player, data in pairs(CoreState.EspObjects) do
        if data.Root and data.Root.Parent and data.Label then
            local dist = math.floor((myRoot.Position - data.Root.Position).Magnitude)
            local hp = data.Hum and math.floor(data.Hum.Health) or 0
            data.Label.Text = string.format("%s\n[%d HP | %dm]", player.Name, hp, dist)
        end
    end
end)

-- ==============================================================================
-- 7. FITUR DARI PAYLOAD: MOVEMENT (SPEED, JUMP, NOCLIP, FLY)
-- ==============================================================================
Services.RunService.Stepped:Connect(function()
    if CoreState.NoclipActive and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if CoreState.InfJumpActive and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local flyBV, flyBG = nil, nil
local function setFly(enabled)
    CoreState.FlyActive = enabled
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
    if CoreState.FlyActive and flyBV and flyBG and Camera then
        local moveDir = Vector3.new(0, 0, 0)
        local uis = Services.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        flyBV.Velocity = moveDir * CoreState.FlySpeed
        flyBG.CFrame = Camera.CFrame
    end
end)

-- ==============================================================================
-- 8. FITUR DARI PAYLOAD: WORLD UTILITIES
-- ==============================================================================
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

LocalPlayer.Idled:Connect(function()
    if CoreState.Config.AntiAfk then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==============================================================================
-- 9. PENYUSUNAN TABS & KONTROL UI
-- ==============================================================================
-- Tab 1: Game Catalog (Struktur lua.txt)
local ScriptsPage = createTab("Game Catalog", true)
addSection(ScriptsPage, "Profil Game Aktif & Terdeteksi")

local detectedEntry = matchPlace(game.PlaceId, game.GameId)
local DetectNotice = Instance.new("Frame")
DetectNotice.Size = UDim2.new(1, 0, 0, 40)
DetectNotice.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
DetectNotice.Parent = ScriptsPage

local DetectCorner = Instance.new("UICorner")
DetectCorner.CornerRadius = UDim.new(0, 6)
DetectCorner.Parent = DetectNotice

local DetectLabel = Instance.new("TextLabel")
DetectLabel.Size = UDim2.new(1, -20, 1, 0)
DetectLabel.Position = UDim2.new(0, 10, 0, 0)
DetectLabel.BackgroundTransparency = 1
DetectLabel.RichText = true
DetectLabel.Font = Enum.Font.GothamMedium
DetectLabel.TextSize = 12
DetectLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
DetectLabel.TextXAlignment = Enum.TextXAlignment.Left
DetectLabel.Text = string.format("🎮 Game Terdeteksi: <font color='#38bdf8'><b>%s</b></font> (PlaceID: %d)", detectedEntry.Name, game.PlaceId)
DetectLabel.Parent = DetectNotice

addSection(ScriptsPage, "Pilih Profil Lain")
for _, entry in ipairs(CATALOG) do
    if entry.Listed then
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, 0, 0, 46)
        Card.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
        Card.Parent = ScriptsPage

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 6)
        CardCorner.Parent = Card

        local CardTitle = Instance.new("TextLabel")
        CardTitle.Size = UDim2.new(0.65, 0, 1, 0)
        CardTitle.Position = UDim2.new(0, 12, 0, 0)
        CardTitle.BackgroundTransparency = 1
        CardTitle.RichText = true
        CardTitle.Font = Enum.Font.GothamMedium
        CardTitle.TextSize = 12
        CardTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
        CardTitle.TextXAlignment = Enum.TextXAlignment.Left
        CardTitle.Text = string.format("<b>%s</b>  <font color='#94a3b8'>ID: %s</font>", entry.Name, tostring(entry.Places[1] or 0))
        CardTitle.Parent = Card

        local RunBtn = Instance.new("TextButton")
        RunBtn.Size = UDim2.new(0, 75, 0, 24)
        RunBtn.Position = UDim2.new(1, -85, 0.5, -12)
        RunBtn.BackgroundColor3 = entry.Tone or Color3.fromRGB(56, 189, 248)
        RunBtn.Text = "Aktifkan"
        RunBtn.Font = Enum.Font.GothamBold
        RunBtn.TextSize = 11
        RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RunBtn.Parent = Card

        local RunCorner = Instance.new("UICorner")
        RunCorner.CornerRadius = UDim.new(0, 6)
        RunCorner.Parent = RunBtn

        RunBtn.MouseButton1Click:Connect(function()
            pcall(function()
                Services.StarterGui:SetCore("SendNotification", {
                    Title = HUB_NAME,
                    Text = "Profil " .. entry.Name .. " diterapkan!",
                    Duration = 3
                })
            end)
        end)
    end
end

-- Tab 2: Visuals
local VisualsPage = createTab("Visuals", false)
addSection(VisualsPage, "Wallhack & ESP")
addToggle(VisualsPage, "Aktifkan Seluruh ESP", CoreState.Config.EspEnabled, function(val)
    CoreState.Config.EspEnabled = val
    for _, data in pairs(CoreState.EspObjects) do
        if data.Highlight then data.Highlight.Enabled = val end
        if data.Tag then data.Tag.Enabled = val end
    end
end)
addToggle(VisualsPage, "Chams Siluet Merah", CoreState.Config.EspChams, function(val)
    CoreState.Config.EspChams = val
    for _, data in pairs(CoreState.EspObjects) do
        if data.Highlight then data.Highlight.FillTransparency = val and 0.5 or 1 end
    end
end)

-- Tab 3: Movement
local MovePage = createTab("Movement", false)
addSection(MovePage, "Kecepatan & Pergerakan Karakter")
addSlider(MovePage, "Kecepatan (WalkSpeed)", 16, 200, CoreState.Config.WalkSpeed, function(val)
    CoreState.Config.WalkSpeed = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)
addSlider(MovePage, "Lompatan (JumpPower)", 50, 300, CoreState.Config.JumpPower, function(val)
    CoreState.Config.JumpPower = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)
addToggle(MovePage, "Menembus Dinding (Noclip)", false, function(val)
    CoreState.NoclipActive = val
end)
addToggle(MovePage, "Lompatan Bebas (Infinite Jump)", false, function(val)
    CoreState.InfJumpActive = val
end)
addToggle(MovePage, "Mode Terbang (Fly WASD)", false, function(val)
    setFly(val)
end)

-- Tab 4: World & Tools
local WorldPage = createTab("World & Tools", false)
addSection(WorldPage, "Lingkungan & Server")
addToggle(WorldPage, "Penerangan Penuh (FullBright)", CoreState.Config.FullBright, function(val)
    CoreState.Config.FullBright = val
    setFullBright(val)
end)
addToggle(WorldPage, "Anti-AFK (Bypass Idle 20 Menit)", CoreState.Config.AntiAfk, function(val)
    CoreState.Config.AntiAfk = val
end)
addButton(WorldPage, "Gabung Ulang (Rejoin Server)", "Rejoin", function()
    Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

-- Tab 5: Teleport
local TeleportPage = createTab("Teleport", false)
addSection(TeleportPage, "Pengelola Koordinat Posisi")
addButton(TeleportPage, "Simpan Posisi Karakter Saat Ini", "Simpan Pos", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        CoreState.SavedPos = LocalPlayer.Character.HumanoidRootPart.CFrame
        pcall(function()
            Services.StarterGui:SetCore("SendNotification", {
                Title = HUB_NAME,
                Text = "Koordinat tersimpan!",
                Duration = 3
            })
        end)
    end
end)
addButton(TeleportPage, "Teleport ke Posisi Tersimpan", "Teleport", function()
    if CoreState.SavedPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CoreState.SavedPos
    end
end)

-- Tab 6: Menu & Konfigurasi
local MenuPage = createTab("Pengaturan", false)
addSection(MenuPage, "Konfigurasi & Siklus Hidup")
addToggle(MenuPage, "Simpan Konfigurasi Otomatis", CoreState.Config.AutoSave, function(val)
    CoreState.Config.AutoSave = val
end)
addButton(MenuPage, "Simpan Pengaturan Sekarang", "Simpan File", function()
    saveConfig()
end)
addButton(MenuPage, "Tutup & Hapus Menu GUI", "Hancurkan", function()
    ScreenGui:Destroy()
    _G.AntigravityHubLoader = nil
end)

-- ==============================================================================
-- 10. OVERLAY DIAGNOSTIK KINERJA REAL-TIME (DARI PAYLOAD.LUA)
-- ==============================================================================
local Overlay = Instance.new("TextLabel")
Overlay.Size = UDim2.new(0, 165, 0, 22)
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
    local ping = math.floor(LocalPlayer and LocalPlayer:GetNetworkPing() * 1000 or 30)
    Overlay.Text = string.format(" ⚡ FPS: %d | Ping: %dms", fps, ping)
end)

-- Shortcut Keyboard (RightShift)
Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        toggleUI()
    end
end)

-- Registrasi Global & Sinyal Ready
_G.AntigravityHubLoader = {
    Window = ScreenGui,
    Cleanup = function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end
}

pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = HUB_NAME,
        Text = "Modul terpasang & aktif tanpa kunci!",
        Duration = 5
    })
end)

shared._agyGameLoaded = true
shared._agyGameReady = true
print("[ANTIGRAVITY] All-in-One Direct Suite v" .. HUB_VERSION .. " berjalan aktif.")

end) -- Akhir pcall safe execution boundary

-- ==============================================================================
-- 11. SINKRONISASI STATUS FLIGHT LOCK (DARI LOADER.TXT)
-- ==============================================================================
local _ready = (shared._agyGameLoaded == true and shared._agyGameReady == true)
if shared._agyLoaderFlight == _flight then
    _flight.Running = false
    _flight.Ready = _ready
    if not _ready then
        shared._agyLoaderFlight = nil
    end
end

if not _ok then
    error(_err, 0)
end
