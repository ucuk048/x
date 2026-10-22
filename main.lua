-- ==============================================================================
-- ANTIGRAVITY ENTERPRISE ULTIMATE GAME HUB (lua2.txt) - v5.0.0
-- IMPLEMENTASI LENGKAP 50+ FITUR (COMBAT, VISUALS, MOVEMENT, WORLD, EXPLOITS, UTILITIES)
-- 100% STANDALONE - TANPA DEPENDENSI GITHUB, TANPA ENKRIPSI VM LURAPH, BEBAS KUNCI
-- ==============================================================================

local HUB_NAME = "Antigravity Hub"
local HUB_VERSION = "5.0.0"
local CONFIG_FILE = "antigravity_hub_config.json"
local WAYPOINTS_FILE = "antigravity_waypoints.json"

-- 1. PEMBERSIHAN SESI LAMA (GLOBAL SINGLETON)
if type(_G.AntigravityHubInstance) == "table" and _G.AntigravityHubInstance.Cleanup then
    pcall(function() _G.AntigravityHubInstance.Cleanup() end)
end
_G.AntigravityHubInstance = {}

-- 2. RESOLUSI LAYANAN GAME ENGINE
local Services = {
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    TeleportService = game:GetService("TeleportService"),
    VirtualUser = game:GetService("VirtualUser"),
    ProximityPromptService = game:GetService("ProximityPromptService")
}

local LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or Services.CoreGui

local function getSafeUIParent()
    if gethui then return gethui() end
    local ok, _ = pcall(function() return Services.CoreGui.Name end)
    if ok then return Services.CoreGui end
    return PlayerGui
end

local function tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local anim = Services.TweenService:Create(object, tweenInfo, properties)
    anim:Play()
    return anim
end

-- 3. STATE MANAGEMENT (50+ FITUR CONFIG)
local HubState = {
    ActiveTab = "Combat",
    IsVisible = true,
    Config = {
        -- Combat
        AimbotEnabled = false,
        AimbotSmoothness = 0.2,
        AimbotPart = "Head",
        AimbotTeamCheck = true,
        FovEnabled = false,
        FovRadius = 130,
        HitboxExpander = false,
        HitboxSize = 12,
        TriggerBot = false,
        -- Visuals (ESP)
        EspEnabled = false,
        EspChams = true,
        EspBoxes = true,
        EspNames = true,
        EspDistance = true,
        EspHealth = true,
        EspTracers = false,
        EspTeamCheck = false,
        -- Movement & Physics
        WalkSpeed = 16,
        JumpPower = 50,
        Noclip = false,
        InfJump = false,
        Fly = false,
        FlySpeed = 50,
        ClickTP = false,
        SpinBot = false,
        SpinSpeed = 25,
        AutoBhop = false,
        -- Mine Antarctica Spesifik (Lengkap)
        AutoMine = false,
        MineRange = 35,
        AutoPickaxe = true,
        FastMine = false,
        FastMineHits = 3,
        OrePriority = true,
        AutoCollect = false,
        AutoSell = false,
        AutoGarden = false,
        AutoRunes = false,
        AutoUpgrade = false,
        AutoItems = false,
        AutoBomb = false,
        AutoClaimRewards = false,
        AntiFreeze = false,
        InfiniteJetpack = false,
        AntiRagdoll = true,
        NoFallDamage = true,
        CrystalEsp = false,
        -- World & Environment
        FullBright = false,
        NoFog = false,
        XRay = false,
        CameraFOV = 70,
        Gravity = 196.2,
        TimeOfDay = 14,
        -- Player & Utilities
        AntiAfk = true,
        AntiFling = false,
        InstantPrompt = true,
        AutoSave = true
    },
    EspObjects = {},
    Tracers = {},
    Waypoints = {},
    FlyBV = nil,
    FlyBG = nil,
    FovCircle = nil,
    SavedPos = nil
}

-- Load / Save JSON
local function loadConfig()
    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function()
            local decoded = Services.HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do HubState.Config[k] = v end
            end
        end)
    end
    if isfile and readfile and isfile(WAYPOINTS_FILE) then
        pcall(function()
            local wp = Services.HttpService:JSONDecode(readfile(WAYPOINTS_FILE))
            if type(wp) == "table" then HubState.Waypoints = wp end
        end)
    end
end

local function saveConfig()
    if writefile and HubState.Config.AutoSave then
        pcall(function()
            writefile(CONFIG_FILE, Services.HttpService:JSONEncode(HubState.Config))
            writefile(WAYPOINTS_FILE, Services.HttpService:JSONEncode(HubState.Waypoints))
        end)
    end
end

loadConfig()

-- 4. FOV DRAWING CIRCLE
pcall(function()
    if Drawing and Drawing.new then
        local circle = Drawing.new("Circle")
        circle.Radius = HubState.Config.FovRadius
        circle.Thickness = 1.5
        circle.Color = Color3.fromRGB(56, 189, 248)
        circle.Transparency = 0.7
        circle.Filled = false
        circle.Visible = HubState.Config.FovEnabled
        HubState.FovCircle = circle

        Services.RunService.RenderStepped:Connect(function()
            if HubState.FovCircle then
                HubState.FovCircle.Visible = HubState.Config.FovEnabled
                HubState.FovCircle.Radius = HubState.Config.FovRadius
                HubState.FovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            end
        end)
    end
end)

-- 5. COMBAT ENGINE: AIMBOT, TRIGGERBOT, HITBOX EXPANDER
local function getClosestTarget()
    local closest, maxDist = nil, HubState.Config.FovRadius
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + 36)

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not HubState.Config.AimbotTeamCheck or (player.Team ~= LocalPlayer.Team or player.Team == nil) then
                local char = player.Character
                local part = char:FindFirstChild(HubState.Config.AimbotPart) or char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")

                if part and hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < maxDist then
                            maxDist = dist
                            closest = part
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Aimbot Loop
Services.RunService.RenderStepped:Connect(function()
    if HubState.Config.AimbotEnabled and Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPart = getClosestTarget()
        if targetPart then
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPart.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, math.clamp(1 - HubState.Config.AimbotSmoothness, 0.05, 1))
        end
    end
end)

-- TriggerBot Loop
Services.RunService.RenderStepped:Connect(function()
    if HubState.Config.TriggerBot and Mouse.Target then
        local model = Mouse.Target:FindFirstAncestorOfClass("Model")
        local player = model and Services.Players:GetPlayerFromCharacter(model)
        if player and player ~= LocalPlayer then
            if not HubState.Config.AimbotTeamCheck or (player.Team ~= LocalPlayer.Team or player.Team == nil) then
                mouse1click()
            end
        end
    end
end)

-- Hitbox Expander Loop
local function updateHitboxes()
    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if HubState.Config.HitboxExpander then
                    local s = HubState.Config.HitboxSize
                    root.Size = Vector3.new(s, s, s)
                    root.Transparency = 0.7
                    root.CanCollide = false
                else
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
    end
end
Services.RunService.Heartbeat:Connect(updateHitboxes)

-- 6. VISUALS ENGINE: CHAMS, BOX, TAGS, DISTANCE, HEALTH & TRACERS
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        if not root or not hum then return end

        -- Chams
        local highlight = char:FindFirstChild("AgyHighlight") or Instance.new("Highlight")
        highlight.Name = "AgyHighlight"
        highlight.Adornee = char
        highlight.FillColor = (player.Team and player.Team.TeamColor and player.Team.TeamColor.Color) or Color3.fromRGB(239, 68, 68)
        highlight.FillTransparency = HubState.Config.EspChams and 0.5 or 1
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = HubState.Config.EspEnabled
        highlight.Parent = char

        -- Billboard Tag
        local tag = root:FindFirstChild("AgyBillboard") or Instance.new("BillboardGui")
        tag.Name = "AgyBillboard"
        tag.Adornee = root
        tag.Size = UDim2.new(0, 140, 0, 42)
        tag.StudsOffset = Vector3.new(0, 3, 0)
        tag.AlwaysOnTop = true
        tag.Enabled = HubState.Config.EspEnabled
        tag.Parent = root

        local label = tag:FindFirstChild("Label") or Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.2
        label.Parent = tag

        -- Drawing Tracers (jika didukung)
        local tracer = nil
        pcall(function()
            if Drawing and Drawing.new then
                tracer = Drawing.new("Line")
                tracer.Thickness = 1.5
                tracer.Color = Color3.fromRGB(239, 68, 68)
                tracer.Transparency = 0.6
                tracer.Visible = false
            end
        end)

        HubState.EspObjects[player] = { Highlight = highlight, Tag = tag, Label = label, Root = root, Hum = hum, Tracer = tracer }
    end

    if player.Character then setupChar(player.Character) end
    player.CharacterAdded:Connect(setupChar)
end

for _, p in ipairs(Services.Players:GetPlayers()) do applyESP(p) end
Services.Players.PlayerAdded:Connect(applyESP)
Services.Players.PlayerRemoving:Connect(function(p)
    if HubState.EspObjects[p] and HubState.EspObjects[p].Tracer then
        pcall(function() HubState.EspObjects[p].Tracer:Remove() end)
    end
    HubState.EspObjects[p] = nil
end)

Services.RunService.RenderStepped:Connect(function()
    if not HubState.Config.EspEnabled then
        for _, d in pairs(HubState.EspObjects) do
            if d.Tracer then d.Tracer.Visible = false end
        end
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for player, data in pairs(HubState.EspObjects) do
        if data.Root and data.Root.Parent and data.Label and data.Hum then
            local isTeammate = HubState.Config.EspTeamCheck and (player.Team == LocalPlayer.Team and player.Team ~= nil)
            if isTeammate then
                data.Tag.Enabled = false
                data.Highlight.Enabled = false
                if data.Tracer then data.Tracer.Visible = false end
            else
                data.Tag.Enabled = true
                data.Highlight.Enabled = true

                local dist = math.floor((myRoot.Position - data.Root.Position).Magnitude)
                local hp = math.floor(data.Hum.Health)
                local maxHp = math.floor(data.Hum.MaxHealth or 100)
                local hpColor = hp > 50 and "#4ade80" or (hp > 25 and "#facc15" or "#ef4444")

                data.Label.Text = string.format("%s\n<font color='%s'>[%d/%d HP]</font> • <font color='#38bdf8'>%dm</font>",
                    player.DisplayName or player.Name, hpColor, hp, maxHp, dist
                )
                data.Label.RichText = true

                -- Update Tracer Line
                if data.Tracer and HubState.Config.EspTracers then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(data.Root.Position)
                    if onScreen then
                        data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        data.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                        data.Tracer.Visible = true
                    else
                        data.Tracer.Visible = false
                    end
                elseif data.Tracer then
                    data.Tracer.Visible = false
                end
            end
        end
    end
end)

-- 7. MOVEMENT ENGINE: NOCLIP, FLY, SPEED, JUMP, BHOP, CLICK TP, SPINBOT
Services.RunService.Stepped:Connect(function()
    if HubState.Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if HubState.Config.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Auto Bhop
Services.RunService.RenderStepped:Connect(function()
    if HubState.Config.AutoBhop and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air and Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function setFly(enabled)
    HubState.Config.Fly = enabled
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if enabled then
        HubState.FlyBV = Instance.new("BodyVelocity")
        HubState.FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        HubState.FlyBV.Velocity = Vector3.new(0, 0, 0)
        HubState.FlyBV.Parent = root

        HubState.FlyBG = Instance.new("BodyGyro")
        HubState.FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        HubState.FlyBG.CFrame = root.CFrame
        HubState.FlyBG.Parent = root
    else
        if HubState.FlyBV then HubState.FlyBV:Destroy(); HubState.FlyBV = nil end
        if HubState.FlyBG then HubState.FlyBG:Destroy(); HubState.FlyBG = nil end
    end
end

Services.RunService.RenderStepped:Connect(function()
    if HubState.Config.Fly and HubState.FlyBV and HubState.FlyBG and Camera then
        local moveDir = Vector3.new(0, 0, 0)
        local uis = Services.UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        HubState.FlyBV.Velocity = moveDir * HubState.Config.FlySpeed
        HubState.FlyBG.CFrame = Camera.CFrame
    end
end)

-- Click TP (Ctrl + Click)
Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and HubState.Config.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hitPos = Mouse.Hit
        if hitPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(hitPos.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- SpinBot
Services.RunService.RenderStepped:Connect(function()
    if HubState.Config.SpinBot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(HubState.Config.SpinSpeed), 0)
    end
end)

-- 8. WORLD & ENVIRONMENT ENGINE
local originalAmbient = Services.Lighting.Ambient
local originalBrightness = Services.Lighting.Brightness
local originalFog = Services.Lighting.FogEnd

local function setFullBright(val)
    HubState.Config.FullBright = val
    if val then
        Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Services.Lighting.Brightness = 2
        Services.Lighting.ClockTime = 14
        Services.Lighting.FogEnd = 1e6
    else
        Services.Lighting.Ambient = originalAmbient
        Services.Lighting.Brightness = originalBrightness
        Services.Lighting.FogEnd = originalFog
    end
end

local function setXRay(val)
    HubState.Config.XRay = val
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Parent:FindFirstChildOfClass("Humanoid") then
            part.Transparency = val and 0.65 or 0
        end
    end
end

-- Fast Proximity Prompt
Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if HubState.Config.InstantPrompt then
        prompt.HoldDuration = 0
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if HubState.Config.AntiAfk then
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Anti-Fling
Services.RunService.Heartbeat:Connect(function()
    if HubState.Config.AntiFling and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        if root.RotVelocity.Magnitude > 50 or root.Velocity.Magnitude > 150 then
            root.RotVelocity = Vector3.new()
            root.Velocity = Vector3.new()
        end
    end
end)

-- ==============================================================================
-- 8.5. ENGINE KHUSUS: MINE ANTARCTICA (MASTER SUITE)
-- ==============================================================================
-- 1. Deteksi Bijih & Kristal Terdekat (dengan filter Prioritas Rarity)
local function getClosestOre()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, minDist = nil, HubState.Config.MineRange or 35

    local folders = {
        workspace:FindFirstChild("Ores"),
        workspace:FindFirstChild("Boulders"),
        workspace:FindFirstChild("Crystals"),
        workspace:FindFirstChild("Nodes"),
        workspace
    }
    
    local priorityList = {"mythic", "legendary", "epic", "diamond", "crystal", "gold", "boulder", "ore"}

    for _, priorityName in ipairs(priorityList) do
        for _, folder in ipairs(folders) do
            if folder then
                for _, obj in ipairs(folder:GetChildren()) do
                    local name = obj.Name:lower()
                    if name:find(priorityName) and (obj:IsA("Model") or obj:IsA("BasePart")) then
                        local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or (obj:FindFirstChildWhichIsA("BasePart") and obj:FindFirstChildWhichIsA("BasePart").Position)) or (obj:IsA("BasePart") and obj.Position)
                        if pos then
                            local d = (pos - myRoot.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                closest = obj
                                if HubState.Config.OrePriority then
                                    return closest -- Prioritaskan batu langka terlebih dahulu
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- 2. Auto Equip Best Pickaxe Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if HubState.Config.AutoPickaxe and LocalPlayer.Character then
            local char = LocalPlayer.Character
            if not char:FindFirstChildOfClass("Tool") and LocalPlayer.Backpack then
                local bestTool = nil
                for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and (tool.Name:lower():find("pick") or tool.Name:lower():find("axe") or tool.Name:lower():find("drill") or tool.Name:lower():find("hammer")) then
                        bestTool = tool
                        break
                    end
                end
                if not bestTool then
                    bestTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                end
                if bestTool then
                    bestTool.Parent = char
                end
            end
        end
    end
end)

-- 3. Auto Mine & Mining Mods (Fast Mine Multi-Hit) Loop
task.spawn(function()
    while true do
        local delay = HubState.Config.FastMine and 0.05 or 0.12
        task.wait(delay)
        if HubState.Config.AutoMine and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
            local targetOre = getClosestOre()
            if targetOre then
                local hits = HubState.Config.FastMine and (HubState.Config.FastMineHits or 3) or 1
                for i = 1, hits do
                    for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                        if rem:IsA("RemoteEvent") then
                            local rname = rem.Name:lower()
                            if rname:find("mine") or rname:find("hit") or rname:find("damage") or rname:find("boulder") or rname:find("swing") then
                                pcall(function() rem:FireServer(targetOre) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Auto Collect (Drops, Kristal, & Shards)
task.spawn(function()
    while true do
        task.wait(0.25)
        if HubState.Config.AutoCollect and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("TouchTransmitter") and item.Parent then
                    local pname = item.Parent.Name:lower()
                    if pname:find("crystal") or pname:find("drop") or pname:find("shard") or pname:find("rune") or pname:find("meteor") or pname:find("coin") then
                        pcall(function()
                            firetouchinterest(myRoot, item.Parent, 0)
                            firetouchinterest(myRoot, item.Parent, 1)
                        end)
                    end
                end
            end
        end
    end
end)

-- 5. Auto Sell (Jual Hasil Tambang)
task.spawn(function()
    while true do
        task.wait(3)
        if HubState.Config.AutoSell then
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") then
                    local rname = rem.Name:lower()
                    if rname:find("sell") or rname:find("vendor") or rname:find("shop") or rname:find("merchant") then
                        pcall(function() rem:FireServer() end)
                    end
                end
            end
        end
    end
end)

-- 6. Auto Garden (Tanaman, Bunga & Seeds)
task.spawn(function()
    while true do
        task.wait(2)
        if HubState.Config.AutoGarden and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            -- Panggil event garden
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("garden") or n:find("harvest") or n:find("plant") or n:find("flower") or n:find("seed") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                        end)
                    end
                end
            end
            -- Touch farm plots
            local gardenFolder = workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Plants")
            if gardenFolder then
                for _, plot in ipairs(gardenFolder:GetDescendants()) do
                    if plot:IsA("TouchTransmitter") and plot.Parent then
                        pcall(function()
                            firetouchinterest(myRoot, plot.Parent, 0)
                            firetouchinterest(myRoot, plot.Parent, 1)
                        end)
                    end
                end
            end
        end
    end
end)

-- 7. Auto Runes & Rune Altar
task.spawn(function()
    while true do
        task.wait(3)
        if HubState.Config.AutoRunes then
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("rune") or n:find("altar") or n:find("infuse") or n:find("craftrune") or n:find("activaterune") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- 8. Auto Upgrade (Pickaxes, Capacity, Warmth)
task.spawn(function()
    while true do
        task.wait(5)
        if HubState.Config.AutoUpgrade then
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("upgrade") or n:find("buyupgrade") or n:find("purchaseweight") or n:find("capacity") or n:find("buypickaxe") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- 9. Auto Items (Beli Bom, Radar, Buka Chests)
task.spawn(function()
    while true do
        task.wait(4)
        if HubState.Config.AutoItems then
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("chest") or n:find("openchest") or n:find("crate") or n:find("buybomb") or n:find("buyradar") or n:find("box") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- 10. Auto Claim Rewards & Daily Gifts
task.spawn(function()
    while true do
        task.wait(6)
        if HubState.Config.AutoClaimRewards then
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("reward") or n:find("claim") or n:find("daily") or n:find("gift") or n:find("spin") or n:find("freegift") or n:find("quest") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- 11. Auto Bomb Thrower
task.spawn(function()
    while true do
        task.wait(3.5)
        if HubState.Config.AutoBomb and LocalPlayer.Character then
            local ore = getClosestOre()
            if ore then
                for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                    if rem:IsA("RemoteEvent") and (rem.Name:lower():find("bomb") or rem.Name:lower():find("dynamite") or rem.Name:lower():find("throw")) then
                        pcall(function() rem:FireServer(ore:IsA("Model") and ore:GetPivot().Position or ore.Position) end)
                    end
                end
            end
        end
    end
end)

-- 12. Player Mods: Infinite Jetpack & Anti-Freeze (Warmth Lock)
Services.RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character then return end
    if HubState.Config.InfiniteJetpack then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("fuel") or v.Name:lower():find("jetpack")) then
                v.Value = 100
            end
        end
    end
    if HubState.Config.AntiFreeze then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("warmth") or v.Name:lower():find("temp") or v.Name:lower():find("cold")) then
                v.Value = 100
            end
        end
    end
end)

-- 13. Player Mods: Anti-Ragdoll & No Fall Damage
Services.RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if HubState.Config.AntiRagdoll then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end
            if HubState.Config.NoFallDamage and hum.FloorMaterial ~= Enum.Material.Air and char:FindFirstChild("HumanoidRootPart") then
                local vel = char.HumanoidRootPart.Velocity
                char.HumanoidRootPart.Velocity = Vector3.new(vel.X, math.clamp(vel.Y, -40, 40), vel.Z)
            end
        end
    end
end)

-- 14. Crystal & Boulder ESP
local crystalEspHighlights = {}
local function updateCrystalESP(enabled)
    if not enabled then
        for _, h in pairs(crystalEspHighlights) do
            if h and h.Parent then h:Destroy() end
        end
        crystalEspHighlights = {}
        return
    end

    local folders = { workspace:FindFirstChild("Ores"), workspace:FindFirstChild("Boulders"), workspace:FindFirstChild("Crystals"), workspace }
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                local name = obj.Name:lower()
                if (name:find("boulder") or name:find("crystal") or name:find("ore") or name:find("meteor")) and not crystalEspHighlights[obj] then
                    local h = Instance.new("Highlight")
                    h.Name = "AgyCrystalESP"
                    h.Adornee = obj
                    h.FillColor = name:find("meteor") and Color3.fromRGB(249, 115, 22) or Color3.fromRGB(56, 189, 248)
                    h.FillTransparency = 0.4
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.Parent = obj
                    crystalEspHighlights[obj] = h
                end
            end
        end
    end
end

-- 9. USER INTERFACE (PURE ROBLOX GUI)
local OldUI = getSafeUIParent():FindFirstChild("AntigravityMainUI")
if OldUI then OldUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntigravityMainUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getSafeUIParent()

-- Mobile Floating Button
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

-- Main Frame Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 640, 0, 430)
MainFrame.Position = UDim2.new(0.5, -320, 0.5, -215)
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
TitleLabel.Text = "  ⚡ " .. HUB_NAME .. "  <font color='#38bdf8'>v" .. HUB_VERSION .. "</font>  <font color='#4ade80'>[Ultimate Suite: 50+ Features]</font>"
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
    HubState.IsVisible = not HubState.IsVisible
    MainFrame.Visible = HubState.IsVisible
end

FloatBtn.MouseButton1Click:Connect(toggleUI)
CloseBtn.MouseButton1Click:Connect(toggleUI)

-- Dragging Logic
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
Sidebar.Size = UDim2.new(0, 135, 1, -42)
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
SidebarPad.PaddingLeft = UDim.new(0, 6)
SidebarPad.PaddingRight = UDim.new(0, 6)
SidebarPad.Parent = Sidebar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -145, 1, -50)
ContentContainer.Position = UDim2.new(0, 140, 0, 46)
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
    PagePad.PaddingBottom = UDim.new(0, 14)
    PagePad.PaddingRight = UDim.new(0, 6)
    PagePad.Parent = TabPage

    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = tabName .. "Btn"
    TabBtn.Size = UDim2.new(1, 0, 0, 30)
    TabBtn.Text = "  " .. tabName
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 11
    TabBtn.TextColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
    TabBtn.BackgroundColor3 = isDefault and Color3.fromRGB(30, 41, 59) or Color3.fromRGB(20, 27, 45)
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = Sidebar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        for name, page in pairs(Tabs) do page.Visible = (name == tabName) end
        for _, btn in pairs(TabButtons) do
            tween(btn, { BackgroundColor3 = Color3.fromRGB(20, 27, 45), TextColor3 = Color3.fromRGB(148, 163, 184) }, 0.2)
        end
        tween(TabBtn, { BackgroundColor3 = Color3.fromRGB(30, 41, 59), TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
        HubState.ActiveTab = tabName
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

local function addToggle(parent, title, configKey, callback)
    local defaultVal = HubState.Config[configKey]
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
        HubState.Config[configKey] = isEnabled
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
    ActionBtn.Text = btnText or "Eksekusi"
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

local function addSlider(parent, title, minVal, maxVal, configKey, callback)
    local currentVal = HubState.Config[configKey] or minVal
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
        HubState.Config[configKey] = value
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
-- 10. TAB 1: MINE ANTARCTICA (MASTER AUTOMATION)
-- ==============================================================================
local AntPage = createTab("Antarctica", true)

addSection(AntPage, "Mining Mods (Penambangan)")
addToggle(AntPage, "Auto Mine (Tebang Batu & Kristal)", "AutoMine")
addToggle(AntPage, "Auto Pickaxe (Peralatan Terbaik Otomatis)", "AutoPickaxe")
addToggle(AntPage, "Fast Mine (Multi-Hit Kecepatan Tinggi)", "FastMine")
addSlider(AntPage, "Jumlah Pukulan Multi-Hit", 2, 8, "FastMineHits")
addToggle(AntPage, "Prioritas Kristal Langka (Mythic/Legendary)", "OrePriority")
addSlider(AntPage, "Jarak Deteksi Tambang (Studs)", 10, 80, "MineRange")

addSection(AntPage, "Otomasi Loot & Hasil Tambang")
addToggle(AntPage, "Auto Collect (Sedot Kristal & Drop)", "AutoCollect")
addToggle(AntPage, "Auto Sell (Jual Otomatis ke Merchant)", "AutoSell")
addToggle(AntPage, "Auto Upgrade (Pickaxe & Kapasitas Tas)", "AutoUpgrade")
addToggle(AntPage, "Auto Items (Beli Bom/Radar & Buka Peti)", "AutoItems")
addToggle(AntPage, "Auto Bomb (Lempar Dinamit ke Batu Besar)", "AutoBomb")

addSection(AntPage, "Garden, Runes & Hadiah")
addToggle(AntPage, "Auto Garden (Panen & Tanam Bunga)", "AutoGarden")
addToggle(AntPage, "Auto Runes (Koleksi & Aktivasi Rune Altar)", "AutoRunes")
addToggle(AntPage, "Auto Claim Reward (Klaim Hadiah Harian & Gift)", "AutoClaimRewards")

addSection(AntPage, "Player Mods (Ketahanan Tubuh)")
addToggle(AntPage, "Anti-Freeze (Tubuh Selalu Hangat / No Cold)", "AntiFreeze")
addToggle(AntPage, "Bahan Bakar Jetpack Tak Terbatas", "InfiniteJetpack")
addToggle(AntPage, "Anti-Ragdoll (Cegah Terpeleset di Es)", "AntiRagdoll")
addToggle(AntPage, "No Fall Damage (Kebal Jatuh ke Jurang Es)", "NoFallDamage")

addSection(AntPage, "Visuals Tambang (ESP)")
addToggle(AntPage, "Crystal & Boulder ESP (Sorot Cyan/Oranye)", "CrystalEsp", function(val)
    updateCrystalESP(val)
end)

addSection(AntPage, "Teleportasi Zona Tambang")
addButton(AntPage, "Teleport ke Spawn / Base Camp", "Base Camp", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local spawnLoc = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawns")
        if spawnLoc then
            LocalPlayer.Character.HumanoidRootPart.CFrame = spawnLoc:IsA("Model") and spawnLoc:GetPivot() or spawnLoc.CFrame + Vector3.new(0, 4, 0)
        end
    end
end)
addButton(AntPage, "Teleport ke Toko / Merchant Penjualan", "Merchant", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if name:find("merchant") or name:find("vendor") or name:find("shop") or name:find("sell") then
                local pos = obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
                if pos then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = pos + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end
end)
addButton(AntPage, "Teleport ke Area Garden", "Garden", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local g = workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farms")
        if g then
            LocalPlayer.Character.HumanoidRootPart.CFrame = (g:IsA("Model") and g:GetPivot() or g.CFrame) + Vector3.new(0, 3, 0)
        end
    end
end)
addButton(AntPage, "Teleport ke Rune Altar", "Rune Altar", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, obj in ipairs(workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if name:find("altar") or name:find("rune") then
                local pos = obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
                if pos then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = pos + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end
end)

-- 11. TAB 2: COMBAT & SENJATA
-- ==============================================================================
local CombatPage = createTab("Combat", false)
addSection(CombatPage, "Aimbot & Penguncian Target")
addToggle(CombatPage, "Kamera Aimbot (Tahan Klik Kanan)", "AimbotEnabled")
addToggle(CombatPage, "Tampilkan Lingkaran Radius FOV", "FovEnabled")
addSlider(CombatPage, "Radius FOV Lingkaran", 50, 400, "FovRadius")
addSlider(CombatPage, "Kelenturan Gerak (Smoothness %)", 0, 95, "AimbotSmoothness", function(val)
    HubState.Config.AimbotSmoothness = val / 100
end)
addToggle(CombatPage, "Pemeriksaan Tim (Ignore Teammate)", "AimbotTeamCheck")
addButton(CombatPage, "Target Part Saat Ini: " .. HubState.Config.AimbotPart, "Ganti Part", function()
    HubState.Config.AimbotPart = (HubState.Config.AimbotPart == "Head" and "HumanoidRootPart" or "Head")
    saveConfig()
end)

addSection(CombatPage, "Triggerbot & Hitbox Mod")
addToggle(CombatPage, "TriggerBot (Tembak Otomatis saat Bidik)", "TriggerBot")
addToggle(CombatPage, "Hitbox Expander (Perbesar Badan Musuh)", "HitboxExpander")
addSlider(CombatPage, "Ukuran Skala Hitbox Musuh", 4, 30, "HitboxSize")

-- ==============================================================================
-- 11. TAB 2: VISUALS (ESP & WALLHACK)
-- ==============================================================================
local VisualsPage = createTab("Visuals", false)
addSection(VisualsPage, "Pengaturan Wallhack Pemain")
addToggle(VisualsPage, "Aktifkan Master ESP", "EspEnabled", function(val)
    for _, d in pairs(HubState.EspObjects) do
        if d.Highlight then d.Highlight.Enabled = val end
        if d.Tag then d.Tag.Enabled = val end
    end
end)
addToggle(VisualsPage, "Chams Siluet Tubuh Musuh", "EspChams", function(val)
    for _, d in pairs(HubState.EspObjects) do
        if d.Highlight then d.Highlight.FillTransparency = val and 0.5 or 1 end
    end
end)
addToggle(VisualsPage, "Garis Penunjuk Bawah (Tracers)", "EspTracers")
addToggle(VisualsPage, "Sembunyikan Teman Satu Tim", "EspTeamCheck")

-- ==============================================================================
-- 12. TAB 3: MOVEMENT & FISIKA
-- ==============================================================================
local MovePage = createTab("Movement", false)
addSection(MovePage, "Kecepatan & Pergerakan")
addSlider(MovePage, "Kecepatan Jalan (WalkSpeed)", 16, 300, "WalkSpeed", function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)
addSlider(MovePage, "Kekuatan Lompatan (JumpPower)", 50, 400, "JumpPower", function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)
addToggle(MovePage, "Tembus Dinding (Noclip)", "Noclip")
addToggle(MovePage, "Lompatan Udara Bebas (InfJump)", "InfJump")
addToggle(MovePage, "Auto Bunny Hop (Tahan Spasi)", "AutoBhop")
addToggle(MovePage, "Mode Terbang Bebas (Fly 3D WASD)", "Fly", function(val) setFly(val) end)
addSlider(MovePage, "Kecepatan Terbang (FlySpeed)", 20, 250, "FlySpeed")
addToggle(MovePage, "Teleportasi Klik Mouse (Ctrl + Klik)", "ClickTP")
addToggle(MovePage, "SpinBot (Putar Tubuh Cepat)", "SpinBot")
addSlider(MovePage, "Kecepatan Putaran SpinBot", 5, 80, "SpinSpeed")

-- ==============================================================================
-- 13. TAB 4: WORLD & ENVIRONMENT
-- ==============================================================================
local WorldPage = createTab("World", false)
addSection(WorldPage, "Modifikasi Lingkungan & Kamera")
addToggle(WorldPage, "Penerangan Siang Penuh (FullBright)", "FullBright", function(val) setFullBright(val) end)
addToggle(WorldPage, "Tembus Pandang Dinding Gedung (X-Ray)", "XRay", function(val) setXRay(val) end)
addSlider(WorldPage, "Sudut Pandang Kamera (Field of View)", 70, 120, "CameraFOV", function(val)
    Camera.FieldOfView = val
end)
addSlider(WorldPage, "Waktu Siang/Malam (TimeOfDay)", 0, 24, "TimeOfDay", function(val)
    Services.Lighting.ClockTime = val
end)
addSlider(WorldPage, "Gravitasi Dunia Game", 0, 350, "Gravity", function(val)
    workspace.Gravity = val
end)
addButton(WorldPage, "Pulihkan Gravitasi Standar (196.2)", "Normal", function()
    workspace.Gravity = 196.2
    HubState.Config.Gravity = 196.2
end)

-- ==============================================================================
-- 14. TAB 5: TELEPORT & WAYPOINTS
-- ==============================================================================
local TeleportPage = createTab("Teleport", false)
addSection(TeleportPage, "Pengelola Titik Koordinat")
addButton(TeleportPage, "Simpan Titik Posisi Saat Ini", "Simpan", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        HubState.SavedPos = LocalPlayer.Character.HumanoidRootPart.CFrame
        pcall(function()
            Services.StarterGui:SetCore("SendNotification", { Title = HUB_NAME, Text = "Koordinat posisi berhasil disimpan!", Duration = 3 })
        end)
    end
end)
addButton(TeleportPage, "Teleport ke Titik Tersimpan", "Teleport", function()
    if HubState.SavedPos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = HubState.SavedPos
    end
end)

addSection(TeleportPage, "Teleportasi Pemain Lain")
addButton(TeleportPage, "Teleport ke Pemain Acak (Random Player)", "Teleport", function()
    local list = Services.Players:GetPlayers()
    for _, p in ipairs(list) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
end)

-- ==============================================================================
-- 15. TAB 6: UTILITAS & PROTEKSI
-- ==============================================================================
local UtilPage = createTab("Utilitas", false)
addSection(UtilPage, "Proteksi Pemain & Eksploit")
addToggle(UtilPage, "Anti-AFK (Bypass Kick Idle 20 Menit)", "AntiAfk")
addToggle(UtilPage, "Anti-Fling (Stabilkan Kecepatan Putar)", "AntiFling")
addToggle(UtilPage, "Instan Tombol Interaksi (HoldDuration 0s)", "InstantPrompt")
addButton(UtilPage, "Gabung Ulang Server Ini (Rejoin)", "Rejoin", function()
    Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
addButton(UtilPage, "Salin JobID / Server ID", "Salin", function()
    if setclipboard then
        setclipboard(tostring(game.JobId))
        pcall(function() Services.StarterGui:SetCore("SendNotification", { Title = HUB_NAME, Text = "JobID disalin ke clipboard!", Duration = 3 }) end)
    end
end)

-- ==============================================================================
-- 16. TAB 7: PENGATURAN
-- ==============================================================================
local SettingsPage = createTab("Pengaturan", false)
addSection(SettingsPage, "Konfigurasi Sistem")
addToggle(SettingsPage, "Otomatis Simpan Pengaturan", "AutoSave")
addButton(SettingsPage, "Simpan Konfigurasi ke File Sekarang", "Simpan File", function() saveConfig() end)
addButton(SettingsPage, "Tutup & Hapus Menu GUI", "Hancurkan", function()
    ScreenGui:Destroy()
    _G.AntigravityHubInstance = nil
end)

-- ==============================================================================
-- 17. OVERLAY TELEMETRI (FPS & PING)
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
    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 or 30)
    Overlay.Text = string.format(" ⚡ FPS: %d | Ping: %dms", fps, ping)
end)

-- Shortcut Keyboard (RightShift)
Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        toggleUI()
    end
end)

_G.AntigravityHubInstance = {
    Window = ScreenGui,
    Cleanup = function()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
        if HubState.FovCircle and HubState.FovCircle.Remove then HubState.FovCircle:Remove() end
    end
}

pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = HUB_NAME,
        Text = "Ultimate Suite v" .. HUB_VERSION .. " (50+ Fitur) aktif!",
        Duration = 5
    })
end)

print("[ANTIGRAVITY] Ultimate Suite v" .. HUB_VERSION .. " berjalan penuh tanpa dependensi eksternal.")
