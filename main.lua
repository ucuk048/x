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
        -- Barrage UI & Preset States (1:1 Screenshot Exact)
        MiningModsEnabled = false,
        MiningPreset = "Blatant",
        MiningModsList = {
            ["Anti Ragdoll"] = true,
            ["Dig While Mining"] = true,
            ["Instant Break"] = true,
            ["Reach Mine"] = true,
            ["Fast Swing"] = true,
            ["Ore Aura"] = true,
            ["No Slowdown"] = true,
            ["Auto Equip Best Tool"] = true,
            ["Auto Repair"] = true
        },
        PlayerModsEnabled = false,
        PlayerPreset = "Blatant",
        PlayerModsList = {
            ["Speed"] = true,
            ["Fly"] = false,
            ["Noclip"] = false,
            ["Jump Boost"] = true,
            ["Infinite Jetpack"] = true,
            ["Anti Freeze"] = true,
            ["No Fall Damage"] = true,
            ["SpinBot"] = false,
            ["Click TP"] = false
        },
        TeleportCollectEnabled = false,
        AutoCollectPreset = "Everything",
        AutoMinePreset = "Blatant",
        AutoSellPreset = "Default",
        AutoGardenPreset = "Rarity > Luck",
        GardenAction = "Buy Space, Fill Best",
        AutoRunesPreset = "Default",
        RuneAction = "Collect & Activate",
        AutoPickaxePreset = "Best Available",
        AutoUpgradePreset = "Balance",
        AutoItemsPreset = "Utility",
        RewardsPreset = "Claim All",
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

-- 3. Auto Mine & Mining Mods (Fast Mine Multi-Hit & MiningMods) Loop
task.spawn(function()
    while true do
        local isFast = HubState.Config.FastMine or (HubState.Config.MiningModsEnabled and (HubState.Config.MiningModsList["Fast Swing"] or HubState.Config.MiningPreset == "Blatant"))
        local delay = isFast and 0.05 or 0.12
        task.wait(delay)
        if (HubState.Config.AutoMine or HubState.Config.MiningModsEnabled) and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
            local targetOre = getClosestOre()
            if targetOre then
                local hits = (HubState.Config.FastMine or HubState.Config.MiningModsEnabled) and (HubState.Config.FastMineHits or 6) or 1
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

-- 3.5. Player Mods Engine Loop (Speed, Jump, Freeze, Jetpack, Fall, Ragdoll)
task.spawn(function()
    while true do
        task.wait(0.3)
        if HubState.Config.PlayerModsEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if HubState.Config.PlayerPreset == "Blatant" then
                    hum.WalkSpeed = math.max(HubState.Config.WalkSpeed, 100)
                    hum.JumpPower = math.max(HubState.Config.JumpPower, 150)
                elseif HubState.Config.PlayerPreset == "Legit" then
                    hum.WalkSpeed = 32
                    hum.JumpPower = 70
                end
            end
            HubState.Config.AntiFreeze = true
            HubState.Config.InfiniteJetpack = true
            HubState.Config.NoFallDamage = true
            HubState.Config.AntiRagdoll = true
        end
    end
end)

-- 3.6. Teleport Collect Engine Loop
task.spawn(function()
    while true do
        task.wait(0.35)
        if HubState.Config.TeleportCollectEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("TouchTransmitter") and item.Parent and item.Parent:IsA("BasePart") then
                    local pname = item.Parent.Name:lower()
                    if pname:find("crystal") or pname:find("drop") or pname:find("shard") or pname:find("rune") or pname:find("meteor") or pname:find("coin") then
                        local dist = (item.Parent.Position - myRoot.Position).Magnitude
                        if dist > 4 and dist < 80 then
                            local oldCF = myRoot.CFrame
                            myRoot.CFrame = item.Parent.CFrame
                            firetouchinterest(myRoot, item.Parent, 0)
                            firetouchinterest(myRoot, item.Parent, 1)
                            task.wait(0.06)
                            myRoot.CFrame = oldCF
                            break
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

-- 6. Auto Garden (Tanaman, Bunga & Seeds dengan Prioritas Rarity > Luck Kristal)
local function getBestGardenSeed()
    if not LocalPlayer.Backpack then return nil end
    local seeds = {}
    local rarityScores = {
        mythic = 10000,
        godly = 8000,
        legendary = 5000,
        epic = 2000,
        rare = 1000,
        crystal = 800,
        luck = 600,
        fortune = 500,
        uncommon = 200,
        common = 100
    }
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        local iname = item.Name:lower()
        if iname:find("seed") or iname:find("benih") or iname:find("flower") or iname:find("plant") then
            local score = 100
            for rk, rv in pairs(rarityScores) do
                if iname:find(rk) then
                    score = score + rv
                    break
                end
            end
            -- Prioritas sekunder: Luck dari Kristal
            if iname:find("luck") or iname:find("fortune") or iname:find("kristal") or iname:find("crystal") or iname:find("hoki") then
                score = score + 450
            end
            table.insert(seeds, {item = item, score = score})
        end
    end
    table.sort(seeds, function(a, b) return a.score > b.score end)
    return seeds[1] and seeds[1].item or nil
end

task.spawn(function()
    while true do
        task.wait(1.8)
        if HubState.Config.AutoGarden and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local bestSeed = getBestGardenSeed()

            -- Panggil event garden dengan prioritas Rarity > Luck Kristal
            for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local n = rem.Name:lower()
                    if n:find("garden") or n:find("harvest") or n:find("plant") or n:find("flower") or n:find("seed") then
                        pcall(function()
                            if rem:IsA("RemoteEvent") then
                                if bestSeed and (n:find("plant") or n:find("seed")) then
                                    rem:FireServer(bestSeed)
                                    rem:FireServer("Plant", bestSeed)
                                else
                                    rem:FireServer()
                                end
                            else
                                if bestSeed and (n:find("plant") or n:find("seed")) then
                                    rem:InvokeServer(bestSeed)
                                else
                                    rem:InvokeServer()
                                end
                            end
                        end)
                    end
                end
            end

            -- Touch farm plots dengan prioritas petak langka/kristal
            local gardenFolder = workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Plants") or workspace:FindFirstChild("Crops")
            if gardenFolder then
                local plots = {}
                for _, plot in ipairs(gardenFolder:GetDescendants()) do
                    if plot:IsA("TouchTransmitter") and plot.Parent and plot.Parent:IsA("BasePart") then
                        local pname = plot.Parent.Name:lower()
                        local priority = 10
                        if pname:find("mythic") then priority = 1000
                        elseif pname:find("legendary") then priority = 500
                        elseif pname:find("crystal") or pname:find("luck") then priority = 300
                        end
                        table.insert(plots, {part = plot.Parent, p = priority})
                    end
                end
                table.sort(plots, function(a, b) return a.p > b.p end)
                for _, pData in ipairs(plots) do
                    pcall(function()
                        firetouchinterest(myRoot, pData.part, 0)
                        firetouchinterest(myRoot, pData.part, 1)
                    end)
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


-- 9. USER INTERFACE: BARRAGE HUB (EXACT 1:1 REPLICA)
-- ==============================================================================
local OldUI = getSafeUIParent():FindFirstChild("BarrageHubUI")
if OldUI then OldUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BarrageHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getSafeUIParent()

-- Mobile Floating Button
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 44, 0, 44)
FloatBtn.Position = UDim2.new(0, 15, 0.5, -22)
FloatBtn.BackgroundColor3 = Color3.fromRGB(28, 18, 24)
FloatBtn.Text = "B"
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 22
FloatBtn.TextColor3 = Color3.fromRGB(235, 50, 60)
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 1.5
FloatStroke.Color = Color3.fromRGB(225, 40, 50)
FloatStroke.Parent = FloatBtn

-- Main Frame Window (Barrage Charcoal/Crimson Theme)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 590, 0, 395)
MainFrame.Position = UDim2.new(0.5, -295, 0.5, -197)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(85, 24, 34)
MainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 38)
Topbar.BackgroundColor3 = Color3.fromRGB(26, 20, 24)
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

local LogoBadge = Instance.new("Frame")
LogoBadge.Size = UDim2.new(0, 24, 0, 24)
LogoBadge.Position = UDim2.new(0, 10, 0.5, -12)
LogoBadge.BackgroundColor3 = Color3.fromRGB(65, 18, 26)
LogoBadge.BorderSizePixel = 0
LogoBadge.Parent = Topbar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 5)
LogoCorner.Parent = LogoBadge

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Thickness = 1
LogoStroke.Color = Color3.fromRGB(180, 40, 50)
LogoStroke.Parent = LogoBadge

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "B"
LogoText.Font = Enum.Font.GothamBold
LogoText.TextSize = 14
LogoText.TextColor3 = Color3.fromRGB(245, 245, 250)
LogoText.Parent = LogoBadge

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "BARRAGE"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.Size = UDim2.new(0, 120, 1, 0)
TitleLabel.Position = UDim2.new(0, 40, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

-- Topbar Metadata Pill (User, Date, Time, Version)
local MetaPill = Instance.new("Frame")
MetaPill.Size = UDim2.new(0, 240, 0, 22)
MetaPill.Position = UDim2.new(0.5, -120, 0.5, -11)
MetaPill.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
MetaPill.BorderSizePixel = 0
MetaPill.Parent = Topbar

local MetaCorner = Instance.new("UICorner")
MetaCorner.CornerRadius = UDim.new(1, 0)
MetaCorner.Parent = MetaPill

local MetaStroke = Instance.new("UIStroke")
MetaStroke.Thickness = 1
MetaStroke.Color = Color3.fromRGB(65, 22, 28)
MetaStroke.Parent = MetaPill

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(1, 0, 1, 0)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextSize = 10
MetaLabel.TextColor3 = Color3.fromRGB(180, 160, 165)
MetaLabel.Text = LocalPlayer.Name .. "  |  " .. os.date("%d/%m/%Y") .. "  |  1.0"
MetaLabel.Parent = MetaPill

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(160, 140, 145)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -16)
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
Sidebar.Size = UDim2.new(0, 140, 1, -38)
Sidebar.Position = UDim2.new(0, 0, 0, 38)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 12, 15)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, -52)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.ScrollBarThickness = 2
SidebarScroll.ScrollBarImageColor3 = Color3.fromRGB(85, 24, 34)
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SidebarScroll.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)
SidebarLayout.Parent = SidebarScroll

local SidebarPad = Instance.new("UIPadding")
SidebarPad.PaddingTop = UDim.new(0, 6)
SidebarPad.PaddingBottom = UDim.new(0, 6)
SidebarPad.PaddingLeft = UDim.new(0, 6)
SidebarPad.PaddingRight = UDim.new(0, 6)
SidebarPad.Parent = SidebarScroll

-- Profile Card (at bottom of sidebar)
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, 0, 0, 52)
ProfileCard.Position = UDim2.new(0, 0, 1, -52)
ProfileCard.BackgroundColor3 = Color3.fromRGB(18, 13, 17)
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = Sidebar

local ProfileTopStroke = Instance.new("Frame")
ProfileTopStroke.Size = UDim2.new(1, 0, 0, 1)
ProfileTopStroke.BackgroundColor3 = Color3.fromRGB(60, 20, 26)
ProfileTopStroke.BorderSizePixel = 0
ProfileTopStroke.Parent = ProfileCard

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 34, 0, 34)
AvatarImg.Position = UDim2.new(0, 8, 0.5, -17)
AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100"
AvatarImg.Parent = ProfileCard

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImg

local ProfileName = Instance.new("TextLabel")
ProfileName.Size = UDim2.new(1, -50, 0, 16)
ProfileName.Position = UDim2.new(0, 48, 0, 9)
ProfileName.BackgroundTransparency = 1
ProfileName.Font = Enum.Font.GothamBold
ProfileName.TextSize = 11
ProfileName.TextColor3 = Color3.fromRGB(240, 240, 245)
ProfileName.TextXAlignment = Enum.TextXAlignment.Left
ProfileName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
ProfileName.Parent = ProfileCard

local MemberPill = Instance.new("Frame")
MemberPill.Size = UDim2.new(0, 52, 0, 15)
MemberPill.Position = UDim2.new(0, 48, 0, 27)
MemberPill.BackgroundColor3 = Color3.fromRGB(18, 55, 25)
MemberPill.BorderSizePixel = 0
MemberPill.Parent = ProfileCard

local MemberCorner = Instance.new("UICorner")
MemberCorner.CornerRadius = UDim.new(0, 4)
MemberCorner.Parent = MemberPill

local MemberLabel = Instance.new("TextLabel")
MemberLabel.Size = UDim2.new(1, 0, 1, 0)
MemberLabel.BackgroundTransparency = 1
MemberLabel.Font = Enum.Font.GothamBold
MemberLabel.TextSize = 9
MemberLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
MemberLabel.Text = "MEMBER"
MemberLabel.Parent = MemberPill

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -145, 1, -44)
ContentContainer.Position = UDim2.new(0, 143, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Tab System Storage
local Tabs = {}
local TabButtons = {}

local function addCategoryHeader(categoryName)
    local CatLabel = Instance.new("TextLabel")
    CatLabel.Size = UDim2.new(1, 0, 0, 22)
    CatLabel.BackgroundTransparency = 1
    CatLabel.Text = categoryName:upper()
    CatLabel.Font = Enum.Font.GothamBold
    CatLabel.TextSize = 9
    CatLabel.TextColor3 = Color3.fromRGB(150, 120, 126)
    CatLabel.TextXAlignment = Enum.TextXAlignment.Left
    CatLabel.Parent = SidebarScroll
end

local function createTab(tabName, isDefault, iconSymbol)
    local TabPage = Instance.new("ScrollingFrame")
    TabPage.Name = tabName .. "Page"
    TabPage.Size = UDim2.new(1, 0, 1, 0)
    TabPage.BackgroundTransparency = 1
    TabPage.ScrollBarThickness = 3
    TabPage.ScrollBarImageColor3 = Color3.fromRGB(225, 40, 50)
    TabPage.Visible = isDefault or false
    TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabPage.Parent = ContentContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.Parent = TabPage

    local PagePad = Instance.new("UIPadding")
    PagePad.PaddingTop = UDim.new(0, 6)
    PagePad.PaddingBottom = UDim.new(0, 16)
    PagePad.PaddingRight = UDim.new(0, 8)
    PagePad.Parent = TabPage

    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = tabName .. "Btn"
    TabBtn.Size = UDim2.new(1, 0, 0, 26)
    TabBtn.Text = "  " .. (iconSymbol or "•") .. " " .. tabName
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 11
    TabBtn.TextColor3 = isDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 140, 145)
    TabBtn.BackgroundColor3 = isDefault and Color3.fromRGB(65, 20, 28) or Color3.fromRGB(16, 12, 15)
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = SidebarScroll

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 5)
    Corner.Parent = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        for name, page in pairs(Tabs) do page.Visible = (name == tabName) end
        for _, btn in pairs(TabButtons) do
            tween(btn, { BackgroundColor3 = Color3.fromRGB(16, 12, 15), TextColor3 = Color3.fromRGB(160, 140, 145) }, 0.2)
        end
        tween(TabBtn, { BackgroundColor3 = Color3.fromRGB(65, 20, 28), TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
        HubState.ActiveTab = tabName
    end)

    Tabs[tabName] = TabPage
    TabButtons[tabName] = TabBtn
    return TabPage
end

-- ==============================================================================
-- BARRAGE CARD & CONTROL BUILDERS
-- ==============================================================================

local function createCard(parent, title, initialStatus)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -6, 0, 0)
    Card.AutomaticSize = Enum.AutomaticSize.Y
    Card.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
    Card.BorderSizePixel = 0
    Card.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Card

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(75, 24, 34)
    Stroke.Parent = Card

    local CardPad = Instance.new("UIPadding")
    CardPad.PaddingTop = UDim.new(0, 10)
    CardPad.PaddingBottom = UDim.new(0, 12)
    CardPad.PaddingLeft = UDim.new(0, 12)
    CardPad.PaddingRight = UDim.new(0, 12)
    CardPad.Parent = Card

    local CardLayout = Instance.new("UIListLayout")
    CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CardLayout.Padding = UDim.new(0, 8)
    CardLayout.Parent = Card

    -- Card Header
    local HeaderRow = Instance.new("Frame")
    HeaderRow.Size = UDim2.new(1, 0, 0, 20)
    HeaderRow.BackgroundTransparency = 1
    HeaderRow.Parent = Card

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title:upper()
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 11
    TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = HeaderRow

    local ArrowLabel = Instance.new("TextLabel")
    ArrowLabel.Size = UDim2.new(0, 20, 1, 0)
    ArrowLabel.Position = UDim2.new(1, -20, 0, 0)
    ArrowLabel.BackgroundTransparency = 1
    ArrowLabel.Text = "v"
    ArrowLabel.Font = Enum.Font.GothamBold
    ArrowLabel.TextSize = 11
    ArrowLabel.TextColor3 = Color3.fromRGB(160, 140, 145)
    ArrowLabel.Parent = HeaderRow

    -- Status Row
    local StatusRow = Instance.new("Frame")
    StatusRow.Size = UDim2.new(1, 0, 0, 28)
    StatusRow.BackgroundTransparency = 1
    StatusRow.Parent = Card

    local StatusTitle = Instance.new("TextLabel")
    StatusTitle.Size = UDim2.new(1, 0, 0, 12)
    StatusTitle.BackgroundTransparency = 1
    StatusTitle.Text = "Status"
    StatusTitle.Font = Enum.Font.GothamMedium
    StatusTitle.TextSize = 10
    StatusTitle.TextColor3 = Color3.fromRGB(150, 130, 135)
    StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
    StatusTitle.Parent = StatusRow

    local StatusVal = Instance.new("TextLabel")
    StatusVal.Size = UDim2.new(1, 0, 0, 14)
    StatusVal.Position = UDim2.new(0, 0, 0, 13)
    StatusVal.BackgroundTransparency = 1
    StatusVal.Text = initialStatus or "[IDLE]"
    StatusVal.Font = Enum.Font.GothamMedium
    StatusVal.TextSize = 11
    StatusVal.TextColor3 = Color3.fromRGB(200, 180, 185)
    StatusVal.TextXAlignment = Enum.TextXAlignment.Left
    StatusVal.Parent = StatusRow

    return Card, StatusVal
end

local function addPresetDropdown(parent, title, options, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local LabelRow = Instance.new("Frame")
    LabelRow.Size = UDim2.new(1, 0, 0, 16)
    LabelRow.BackgroundTransparency = 1
    LabelRow.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.8, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = LabelRow

    local InfoIcon = Instance.new("TextLabel")
    InfoIcon.Size = UDim2.new(0, 16, 1, 0)
    InfoIcon.Position = UDim2.new(1, -16, 0, 0)
    InfoIcon.BackgroundTransparency = 1
    InfoIcon.Text = "ⓘ"
    InfoIcon.Font = Enum.Font.Gotham
    InfoIcon.TextSize = 11
    InfoIcon.TextColor3 = Color3.fromRGB(140, 120, 125)
    InfoIcon.Parent = LabelRow

    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(1, 0, 0, 28)
    DropBtn.Position = UDim2.new(0, 0, 0, 18)
    DropBtn.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
    DropBtn.Text = "  " .. tostring(defaultVal)
    DropBtn.Font = Enum.Font.GothamMedium
    DropBtn.TextSize = 11
    DropBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
    DropBtn.TextXAlignment = Enum.TextXAlignment.Left
    DropBtn.Parent = Frame

    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 5)
    DropCorner.Parent = DropBtn

    local DropStroke = Instance.new("UIStroke")
    DropStroke.Thickness = 1
    DropStroke.Color = Color3.fromRGB(60, 24, 30)
    DropStroke.Parent = DropBtn

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -22, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 10
    Arrow.TextColor3 = Color3.fromRGB(160, 140, 145)
    Arrow.Parent = DropBtn

    local currentIdx = 1
    for i, opt in ipairs(options) do
        if opt == defaultVal then currentIdx = i break end
    end

    DropBtn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx + 1
        if currentIdx > #options then currentIdx = 1 end
        local choice = options[currentIdx]
        DropBtn.Text = "  " .. choice
        if callback then callback(choice) end
        saveConfig()
    end)
end

local function addToggle(parent, title, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 32)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(230, 230, 235)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local InfoIcon = Instance.new("TextLabel")
    InfoIcon.Size = UDim2.new(0, 16, 1, 0)
    InfoIcon.Position = UDim2.new(0.65, 4, 0, 0)
    InfoIcon.BackgroundTransparency = 1
    InfoIcon.Text = "ⓘ"
    InfoIcon.Font = Enum.Font.Gotham
    InfoIcon.TextSize = 11
    InfoIcon.TextColor3 = Color3.fromRGB(140, 120, 125)
    InfoIcon.Parent = Frame

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 38, 0, 20)
    Switch.Position = UDim2.new(1, -42, 0.5, -10)
    Switch.BackgroundColor3 = defaultVal and Color3.fromRGB(225, 40, 50) or Color3.fromRGB(50, 42, 46)
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
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
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(225, 40, 50) }, 0.2)
            tween(Knob, { Position = UDim2.new(1, -18, 0.5, -8) }, 0.2)
        else
            tween(Switch, { BackgroundColor3 = Color3.fromRGB(50, 42, 46) }, 0.2)
            tween(Knob, { Position = UDim2.new(0, 2, 0.5, -8) }, 0.2)
        end
        if callback then callback(isEnabled) end
        saveConfig()
    end)
end

local function addMultiSelectDropdown(parent, title, options, selectedDict, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local LabelRow = Instance.new("Frame")
    LabelRow.Size = UDim2.new(1, 0, 0, 16)
    LabelRow.BackgroundTransparency = 1
    LabelRow.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.8, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = LabelRow

    local InfoIcon = Instance.new("TextLabel")
    InfoIcon.Size = UDim2.new(0, 16, 1, 0)
    InfoIcon.Position = UDim2.new(1, -16, 0, 0)
    InfoIcon.BackgroundTransparency = 1
    InfoIcon.Text = "ⓘ"
    InfoIcon.Font = Enum.Font.Gotham
    InfoIcon.TextSize = 11
    InfoIcon.TextColor3 = Color3.fromRGB(140, 120, 125)
    InfoIcon.Parent = LabelRow

    local DropBtn = Instance.new("TextButton")
    DropBtn.Size = UDim2.new(1, 0, 0, 28)
    DropBtn.Position = UDim2.new(0, 0, 0, 18)
    DropBtn.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
    DropBtn.Font = Enum.Font.GothamMedium
    DropBtn.TextSize = 10
    DropBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
    DropBtn.TextXAlignment = Enum.TextXAlignment.Left
    DropBtn.Parent = Frame

    local function getSummary()
        local active = {}
        for _, opt in ipairs(options) do
            if selectedDict[opt] then
                table.insert(active, opt)
            end
        end
        if #active == 0 then return "  (None)" end
        local txt = table.concat(active, ", ")
        if #txt > 36 then
            return "  " .. txt:sub(1, 33) .. "..."
        end
        return "  " .. txt
    end

    DropBtn.Text = getSummary()

    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 5)
    DropCorner.Parent = DropBtn

    local DropStroke = Instance.new("UIStroke")
    DropStroke.Thickness = 1
    DropStroke.Color = Color3.fromRGB(60, 24, 30)
    DropStroke.Parent = DropBtn

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -22, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 10
    Arrow.TextColor3 = Color3.fromRGB(160, 140, 145)
    Arrow.Parent = DropBtn

    local cycleIdx = 1
    DropBtn.MouseButton1Click:Connect(function()
        local opt = options[cycleIdx]
        selectedDict[opt] = not selectedDict[opt]
        cycleIdx = cycleIdx + 1
        if cycleIdx > #options then cycleIdx = 1 end
        DropBtn.Text = getSummary()
        if callback then callback(selectedDict) end
        saveConfig()
    end)
end

local function addSlider(parent, title, minVal, maxVal, currentVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 44)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 0, 16)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.3, 0, 0, 16)
    ValLabel.Position = UDim2.new(0.7, 0, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(math.floor(currentVal))
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 11
    ValLabel.TextColor3 = Color3.fromRGB(225, 40, 50)
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, 0, 0, 5)
    SliderBar.Position = UDim2.new(0, 0, 0, 26)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 34, 40)
    SliderBar.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    local pct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
    FillBar.Size = UDim2.new(pct, 0, 1, 0)
    FillBar.BackgroundColor3 = Color3.fromRGB(225, 40, 50)
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local isDragging = false
    local function update(inputX)
        local rel = math.clamp((inputX - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * rel)
        FillBar.Size = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(val)
        if callback then callback(val) end
        saveConfig()
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            update(input.Position.X)
        end
    end)
    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
end

local function addButton(parent, title, btnText, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 32)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(230, 230, 235)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, 90, 0, 24)
    ActionBtn.Position = UDim2.new(1, -95, 0.5, -12)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(65, 20, 28)
    ActionBtn.Text = btnText or "Action"
    ActionBtn.Font = Enum.Font.GothamMedium
    ActionBtn.TextSize = 11
    ActionBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
    ActionBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = ActionBtn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Thickness = 1
    BtnStroke.Color = Color3.fromRGB(180, 40, 50)
    BtnStroke.Parent = ActionBtn

    ActionBtn.MouseButton1Click:Connect(function()
        tween(ActionBtn, { BackgroundColor3 = Color3.fromRGB(225, 40, 50) }, 0.1)
        task.wait(0.12)
        tween(ActionBtn, { BackgroundColor3 = Color3.fromRGB(65, 20, 28) }, 0.2)
        if callback then callback() end
    end)
end

-- ==============================================================================
-- 10. SETUP TAB & KATEGORI SIDEBAR SESUAI BARRAGE HUB (1:1 SCREENSHOT)
-- ==============================================================================

-- KATEGORI 1: MINING
addCategoryHeader("Mining")
local AutoMinePage    = createTab("Auto Mine", true, "⛏")
local AutoSellPage    = createTab("Auto Sell", false, "💰")
local AutoCollectPage = createTab("Auto Collect", false, "✋")

-- KATEGORI 2: MOVEMENT
addCategoryHeader("Movement")
local MovementPage    = createTab("Movement", false, "🏃")

-- KATEGORI 3: GARDEN
addCategoryHeader("Garden")
local AutoGardenPage  = createTab("Auto Garden", false, "🌸")
local AutoRunesPage   = createTab("Auto Runes", false, "💎")

-- KATEGORI 4: TOKO
addCategoryHeader("Toko")
local AutoPickaxePage = createTab("Auto Pickaxe", false, "🛠")
local AutoUpgradePage = createTab("Auto Upgrade", false, "⬆")
local AutoItemsPage   = createTab("Auto Items", false, "📦")

-- KATEGORI 5: REWARDS
addCategoryHeader("Rewards")
local RewardsPage     = createTab("Rewards", false, "🎁")

-- KATEGORI 6: MODS
addCategoryHeader("Mods")
local PlayerModsPage  = createTab("Player Mods", false, "🧍")
local MiningModsPage  = createTab("Mining Mods", false, "⚡")

-- KATEGORI 7: UNIVERSAL
addCategoryHeader("Universal")
local VisualsPage     = createTab("Visuals & ESP", false, "👁")
local CombatPage      = createTab("Combat", false, "🎯")
local TeleportPage    = createTab("Teleport", false, "📍")
local SettingsPage    = createTab("Pengaturan", false, "⚙")

-- ==============================================================================
-- POPULASI KARTU DAN KONTROL DI SETIAP TAB
-- ==============================================================================

-- 1. TAB: AUTO MINE
local CardMine, StatusMine = createCard(AutoMinePage, "Auto Mine", "[IDLE]")
addPresetDropdown(CardMine, "Preset", {"Blatant", "Legit", "Priority"}, HubState.Config.AutoMinePreset, function(v)
    HubState.Config.AutoMinePreset = v
    if v == "Blatant" then
        HubState.Config.MineRange = 50
        HubState.Config.FastMineHits = 6
    elseif v == "Legit" then
        HubState.Config.MineRange = 25
        HubState.Config.FastMineHits = 2
    end
end)
addToggle(CardMine, "Enable Auto Mine", HubState.Config.AutoMine, function(enabled)
    HubState.Config.AutoMine = enabled
    StatusMine.Text = enabled and "[ACTIVE] Mining Ore Terdekat" or "[IDLE]"
    StatusMine.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addPresetDropdown(CardMine, "Ore Priority", {"Mythic & Legendary", "Diamond+", "Semua Ore"}, "Mythic & Legendary", function(v)
    HubState.Config.OrePriority = (v ~= "Semua Ore")
end)
addSlider(CardMine, "Mine Range (Studs)", 10, 80, HubState.Config.MineRange, function(val)
    HubState.Config.MineRange = val
end)
addSlider(CardMine, "Fast Hit Multiplier", 1, 8, HubState.Config.FastMineHits, function(val)
    HubState.Config.FastMineHits = val
end)

-- 2. TAB: AUTO SELL
local CardSell, StatusSell = createCard(AutoSellPage, "Auto Sell", "[IDLE]")
addPresetDropdown(CardSell, "Preset", {"Default", "Auto Bag Full"}, HubState.Config.AutoSellPreset, function(v)
    HubState.Config.AutoSellPreset = v
end)
addToggle(CardSell, "Enable Auto Sell", HubState.Config.AutoSell, function(enabled)
    HubState.Config.AutoSell = enabled
    StatusSell.Text = enabled and "[ACTIVE] Remote Merchant Berjalan" or "[IDLE]"
    StatusSell.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addPresetDropdown(CardSell, "Sell Target", {"Pedagang Base Camp", "Pedagang Terdekat", "Teleport Jual & Balik"}, "Pedagang Base Camp", function(v) end)

-- 3. TAB: AUTO COLLECT (1:1 SESUAI SCREENSHOT)
local CardCol, StatusCol = createCard(AutoCollectPage, "Auto Collect", "[WAITING] Awaiting Drops In 25 Studs")
addPresetDropdown(CardCol, "Preset", {"Everything", "Crystals Only", "Coins Only", "Runes Only"}, HubState.Config.AutoCollectPreset, function(v)
    HubState.Config.AutoCollectPreset = v
end)
addToggle(CardCol, "Enable Auto Collect", HubState.Config.AutoCollect, function(enabled)
    HubState.Config.AutoCollect = enabled
    StatusCol.Text = enabled and "[WAITING] Awaiting Drops In 25 Studs" or "[IDLE]"
    StatusCol.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)

local CardTPCol, StatusTPCol = createCard(AutoCollectPage, "Teleport Collect", "[IDLE]")
addPresetDropdown(CardTPCol, "Preset", {"Everything", "Rare Drops Only"}, "Everything", function(v) end)
addToggle(CardTPCol, "Enable Teleport Collect", HubState.Config.TeleportCollectEnabled, function(enabled)
    HubState.Config.TeleportCollectEnabled = enabled
    StatusTPCol.Text = enabled and "[ACTIVE] Teleporting to Drops" or "[IDLE]"
    StatusTPCol.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)

-- 4. TAB: MOVEMENT
local CardMove, StatusMove = createCard(MovementPage, "Movement", "[ACTIVE] Physics Engine Loaded")
addPresetDropdown(CardMove, "Preset", {"Blatant", "Legit", "Custom"}, "Blatant", function(v)
    if v == "Blatant" then
        HubState.Config.WalkSpeed = 100
        HubState.Config.JumpPower = 150
    elseif v == "Legit" then
        HubState.Config.WalkSpeed = 32
        HubState.Config.JumpPower = 70
    end
end)
addToggle(CardMove, "Enable Movement Mods", true, function(enabled)
    StatusMove.Text = enabled and "[ACTIVE] Physics Engine Loaded" or "[IDLE]"
end)
local moveDict = { ["Speed"] = true, ["Jump"] = true, ["Fly"] = false, ["Noclip"] = false, ["InfJump"] = false, ["SpinBot"] = false, ["ClickTP"] = false }
addMultiSelectDropdown(CardMove, "Movement Features", {"Speed", "Jump", "Fly", "Noclip", "InfJump", "SpinBot", "ClickTP"}, moveDict, function(res)
    HubState.Config.Fly = res["Fly"]
    HubState.Config.Noclip = res["Noclip"]
    HubState.Config.InfJump = res["InfJump"]
    HubState.Config.SpinBot = res["SpinBot"]
    HubState.Config.ClickTP = res["ClickTP"]
end)
addSlider(CardMove, "WalkSpeed", 16, 300, HubState.Config.WalkSpeed, function(val)
    HubState.Config.WalkSpeed = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
    end
end)
addSlider(CardMove, "JumpPower", 50, 400, HubState.Config.JumpPower, function(val)
    HubState.Config.JumpPower = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
    end
end)

-- 5. TAB: AUTO GARDEN (1:1 SESUAI SCREENSHOT)
local CardGarden, StatusGarden = createCard(AutoGardenPage, "Auto Garden", "[IDLE]")
addPresetDropdown(CardGarden, "Preset", {"Rarity > Luck", "Keberuntungan", "Cepat", "Default"}, HubState.Config.AutoGardenPreset or "Rarity > Luck", function(v)
    HubState.Config.AutoGardenPreset = v
    if HubState.Config.AutoGarden then
        StatusGarden.Text = "[ACTIVE] Farming Garden (" .. v .. ")"
    end
end)
addToggle(CardGarden, "Enable Auto Garden", HubState.Config.AutoGarden, function(enabled)
    HubState.Config.AutoGarden = enabled
    local currentPreset = HubState.Config.AutoGardenPreset or "Rarity > Luck"
    StatusGarden.Text = enabled and ("[ACTIVE] Farming Garden (" .. currentPreset .. ")") or "[IDLE]"
    StatusGarden.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addPresetDropdown(CardGarden, "Garden Actions", {"Buy Space, Fill Best", "Harvest Only", "Plant Only", "Full Auto"}, HubState.Config.GardenAction, function(v)
    HubState.Config.GardenAction = v
end)

-- 6. TAB: AUTO RUNES
local CardRunes, StatusRunes = createCard(AutoRunesPage, "Auto Runes", "[IDLE]")
addPresetDropdown(CardRunes, "Preset", {"Default", "Fast Activate"}, HubState.Config.AutoRunesPreset, function(v)
    HubState.Config.AutoRunesPreset = v
end)
addToggle(CardRunes, "Enable Auto Runes", HubState.Config.AutoRunes, function(enabled)
    HubState.Config.AutoRunes = enabled
    StatusRunes.Text = enabled and "[ACTIVE] Altar Rune Otomatis" or "[IDLE]"
    StatusRunes.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addPresetDropdown(CardRunes, "Rune Actions", {"Collect & Activate", "Collect Only", "Activate Altar Only"}, HubState.Config.RuneAction, function(v)
    HubState.Config.RuneAction = v
end)

-- 7. TAB: AUTO PICKAXE
local CardPickaxe, StatusPickaxe = createCard(AutoPickaxePage, "Auto Pickaxe", "[ACTIVE] Auto Equip Best Tool")
addPresetDropdown(CardPickaxe, "Preset", {"Best Available", "Next Tier"}, HubState.Config.AutoPickaxePreset, function(v)
    HubState.Config.AutoPickaxePreset = v
end)
addToggle(CardPickaxe, "Enable Auto Pickaxe", HubState.Config.AutoPickaxe, function(enabled)
    HubState.Config.AutoPickaxe = enabled
    StatusPickaxe.Text = enabled and "[ACTIVE] Best Pickaxe Dipantau" or "[IDLE]"
    StatusPickaxe.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local pickDict = { ["Auto Equip Best Tool"] = true, ["Auto Buy Next Tier"] = true, ["Auto Repair Tool"] = true }
addMultiSelectDropdown(CardPickaxe, "Pickaxe Actions", {"Auto Equip Best Tool", "Auto Buy Next Tier", "Auto Repair Tool"}, pickDict, function(r) end)

-- 8. TAB: AUTO UPGRADE
local CardUpgrade, StatusUpgrade = createCard(AutoUpgradePage, "Auto Upgrade", "[IDLE]")
addPresetDropdown(CardUpgrade, "Preset", {"Balance", "Capacity First", "Strength First"}, HubState.Config.AutoUpgradePreset, function(v)
    HubState.Config.AutoUpgradePreset = v
end)
addToggle(CardUpgrade, "Enable Auto Upgrade", HubState.Config.AutoUpgrade, function(enabled)
    HubState.Config.AutoUpgrade = enabled
    StatusUpgrade.Text = enabled and "[ACTIVE] Upgrade Berkala Berjalan" or "[IDLE]"
    StatusUpgrade.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local upgDict = { ["Carry Capacity"] = true, ["Mining Power"] = true, ["Warmth Insulation"] = true }
addMultiSelectDropdown(CardUpgrade, "Upgrade Actions", {"Carry Capacity", "Mining Power", "Warmth Insulation"}, upgDict, function(r) end)

-- 9. TAB: AUTO ITEMS
local CardItems, StatusItems = createCard(AutoItemsPage, "Auto Items", "[IDLE]")
addPresetDropdown(CardItems, "Preset", {"Utility", "Explosives", "All"}, HubState.Config.AutoItemsPreset, function(v)
    HubState.Config.AutoItemsPreset = v
end)
addToggle(CardItems, "Enable Auto Items", HubState.Config.AutoItems, function(enabled)
    HubState.Config.AutoItems = enabled
    StatusItems.Text = enabled and "[ACTIVE] Radar & Peti Dipantau" or "[IDLE]"
    StatusItems.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local itemDict = { ["Radar Batu Besar"] = true, ["Radar Kristal 99x"] = true, ["Dinamit Bom"] = true, ["Buka Peti Kuali"] = true }
addMultiSelectDropdown(CardItems, "Item Actions", {"Radar Batu Besar", "Radar Kristal 99x", "Dinamit Bom", "Buka Peti Kuali"}, itemDict, function(r) end)

-- 10. TAB: REWARDS
local CardRewards, StatusRewards = createCard(RewardsPage, "Rewards", "[IDLE]")
addPresetDropdown(CardRewards, "Preset", {"Claim All", "Playtime Only"}, HubState.Config.RewardsPreset, function(v)
    HubState.Config.RewardsPreset = v
end)
addToggle(CardRewards, "Enable Auto Claim Rewards", HubState.Config.AutoClaimRewards, function(enabled)
    HubState.Config.AutoClaimRewards = enabled
    StatusRewards.Text = enabled and "[ACTIVE] Hadiah Diklaim Otomatis" or "[IDLE]"
    StatusRewards.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local rewDict = { ["Daily Gift Claim"] = true, ["Playtime Rewards"] = true, ["Completed Quests"] = true }
addMultiSelectDropdown(CardRewards, "Reward Actions", {"Daily Gift Claim", "Playtime Rewards", "Completed Quests"}, rewDict, function(r) end)

-- 11. TAB: PLAYER MODS (1:1 SESUAI SCREENSHOT)
local CardPlayerMods, StatusPlayerMods = createCard(PlayerModsPage, "Player Mods", "[IDLE]")
addPresetDropdown(CardPlayerMods, "Preset", {"Blatant", "Legit", "Custom"}, HubState.Config.PlayerPreset, function(v)
    HubState.Config.PlayerPreset = v
    if v == "Blatant" then
        HubState.Config.WalkSpeed = 100
        HubState.Config.JumpPower = 150
        HubState.Config.AntiFreeze = true
        HubState.Config.InfiniteJetpack = true
        HubState.Config.NoFallDamage = true
        HubState.Config.AntiRagdoll = true
    elseif v == "Legit" then
        HubState.Config.WalkSpeed = 32
        HubState.Config.JumpPower = 70
        HubState.Config.AntiFreeze = true
        HubState.Config.NoFallDamage = true
    end
end)
addToggle(CardPlayerMods, "Enable Player Mods", HubState.Config.PlayerModsEnabled, function(enabled)
    HubState.Config.PlayerModsEnabled = enabled
    StatusPlayerMods.Text = enabled and "[ACTIVE] 7 Mods | Blatant" or "[IDLE]"
    StatusPlayerMods.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardPlayerMods, "Player Mods", {
    "Speed", "Fly", "Noclip", "Jump Boost", "Infinite Jetpack", "Anti Freeze", "No Fall Damage", "SpinBot", "Click TP"
}, HubState.Config.PlayerModsList, function(res)
    HubState.Config.InfiniteJetpack = res["Infinite Jetpack"]
    HubState.Config.AntiFreeze = res["Anti Freeze"]
    HubState.Config.NoFallDamage = res["No Fall Damage"]
end)
addSlider(CardPlayerMods, "Custom Speed", 16, 300, HubState.Config.WalkSpeed, function(v) HubState.Config.WalkSpeed = v end)
addSlider(CardPlayerMods, "Custom Jump", 50, 400, HubState.Config.JumpPower, function(v) HubState.Config.JumpPower = v end)

-- 12. TAB: MINING MODS (1:1 SESUAI SCREENSHOT)
local CardMiningMods, StatusMiningMods = createCard(MiningModsPage, "Mining Mods", "[ACTIVE] 9 Mods | Swing 0.09s")
addPresetDropdown(CardMiningMods, "Preset", {"Blatant", "Legit", "Custom"}, HubState.Config.MiningPreset, function(v)
    HubState.Config.MiningPreset = v
    if v == "Blatant" then
        HubState.Config.FastMineHits = 6
        HubState.Config.MineRange = 50
    elseif v == "Legit" then
        HubState.Config.FastMineHits = 2
        HubState.Config.MineRange = 25
    end
end)
addToggle(CardMiningMods, "Enable Mining Mods", HubState.Config.MiningModsEnabled or true, function(enabled)
    HubState.Config.MiningModsEnabled = enabled
    StatusMiningMods.Text = enabled and "[ACTIVE] 9 Mods | Swing 0.09s" or "[IDLE]"
    StatusMiningMods.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardMiningMods, "Mining Mods", {
    "Anti Ragdoll", "Dig While Mining", "Instant Break", "Reach Mine", "Fast Swing", "Ore Aura", "No Slowdown", "Auto Equip Best Tool", "Auto Repair"
}, HubState.Config.MiningModsList, function(res)
    HubState.Config.AntiRagdoll = res["Anti Ragdoll"]
end)
addSlider(CardMiningMods, "Fast Swing Hit Multiplier", 1, 8, HubState.Config.FastMineHits, function(v) HubState.Config.FastMineHits = v end)
addSlider(CardMiningMods, "Reach Mine (Studs)", 10, 80, HubState.Config.MineRange, function(v) HubState.Config.MineRange = v end)

-- 13. TAB: VISUALS (ESP & WALLHACK)
local CardESP, StatusESP = createCard(VisualsPage, "Visuals & ESP", "[IDLE]")
addToggle(CardESP, "Enable Player ESP", HubState.Config.EspEnabled, function(v)
    HubState.Config.EspEnabled = v
    StatusESP.Text = v and "[ACTIVE] ESP Rendered" or "[IDLE]"
    StatusESP.TextColor3 = v and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local espDict = { ["Chams"] = true, ["Boxes"] = true, ["Names"] = true, ["Health"] = true, ["Distance"] = true, ["Tracers"] = false, ["Crystal ESP"] = true }
addMultiSelectDropdown(CardESP, "ESP Elements", {"Chams", "Boxes", "Names", "Health", "Distance", "Tracers", "Crystal ESP"}, espDict, function(res)
    HubState.Config.EspChams = res["Chams"]
    HubState.Config.EspBoxes = res["Boxes"]
    HubState.Config.EspNames = res["Names"]
    HubState.Config.EspHealth = res["Health"]
    HubState.Config.EspDistance = res["Distance"]
    HubState.Config.EspTracers = res["Tracers"]
    HubState.Config.CrystalEsp = res["Crystal ESP"]
end)
addToggle(CardESP, "FullBright (Terang Penuh)", HubState.Config.FullBright, function(v) HubState.Config.FullBright = v end)
addToggle(CardESP, "X-Ray Mode (Tembus Pandang)", HubState.Config.XRay, function(v)
    HubState.Config.XRay = v
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Parent:FindFirstChildOfClass("Humanoid") then
            part.Transparency = v and 0.5 or 0
        end
    end
end)

-- 14. TAB: COMBAT
local CardCombat, StatusCombat = createCard(CombatPage, "Combat & Aimbot", "[IDLE]")
addToggle(CardCombat, "Enable Aimbot", HubState.Config.AimbotEnabled, function(v)
    HubState.Config.AimbotEnabled = v
    StatusCombat.Text = v and "[ACTIVE] Aimbot Armed" or "[IDLE]"
    StatusCombat.TextColor3 = v and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local combatDict = { ["FOV Circle"] = false, ["Hitbox Expander"] = false, ["TriggerBot"] = false }
addMultiSelectDropdown(CardCombat, "Combat Features", {"FOV Circle", "Hitbox Expander", "TriggerBot"}, combatDict, function(res)
    HubState.Config.FovEnabled = res["FOV Circle"]
    HubState.Config.HitboxExpander = res["Hitbox Expander"]
    HubState.Config.TriggerBot = res["TriggerBot"]
end)
addSlider(CardCombat, "FOV Radius", 30, 300, HubState.Config.FovRadius, function(v) HubState.Config.FovRadius = v end)

-- 15. TAB: TELEPORT
local CardTP, _ = createCard(TeleportPage, "Antarctica Waypoints", "[READY]")
addButton(CardTP, "Pangkalan / Base Camp", "Teleport", function()
    local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("BaseCamp")
    if spawn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    end
end)
addButton(CardTP, "Pedagang / Toko Vendor", "Teleport", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(120, 15, -45)
    end
end)
addButton(CardTP, "Area Kebun / Garden", "Teleport", function()
    local g = workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Farms")
    if g and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = g:GetPivot() + Vector3.new(0, 5, 0)
    end
end)
addButton(CardTP, "Altar Rune Kuno", "Teleport", function()
    local r = workspace:FindFirstChild("RuneAltar") or workspace:FindFirstChild("Altar")
    if r and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = r:GetPivot() + Vector3.new(0, 5, 0)
    end
end)
addButton(CardTP, "Puncak Gunung (31.000m)", "Teleport", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 31050, 0)
    end
end)

-- 16. TAB: PENGATURAN
local CardSet, _ = createCard(SettingsPage, "Hub Configuration", "[SAVED]")
addToggle(CardSet, "Auto Save Pengaturan", HubState.Config.AutoSave, function(v) HubState.Config.AutoSave = v end)
addButton(CardSet, "Simpan Konfigurasi Sekarang", "Simpan", function() saveConfig() end)
addButton(CardSet, "Tutup / Unload Menu Hub", "Hapus", function()
    ScreenGui:Destroy()
    _G.AntigravityHubInstance = nil
end)

-- ==============================================================================
-- 17. OVERLAY TELEMETRI (FPS & PING)
-- ==============================================================================
local Overlay = Instance.new("TextLabel")
Overlay.Size = UDim2.new(0, 160, 0, 22)
Overlay.Position = UDim2.new(0, 65, 0, 15)
Overlay.BackgroundColor3 = Color3.fromRGB(20, 15, 18)
Overlay.BackgroundTransparency = 0.3
Overlay.TextColor3 = Color3.fromRGB(225, 40, 50)
Overlay.Font = Enum.Font.GothamMedium
Overlay.TextSize = 10
Overlay.Parent = ScreenGui

local OverCorner = Instance.new("UICorner")
OverCorner.CornerRadius = UDim.new(0, 5)
OverCorner.Parent = Overlay

local frames = {}
Services.RunService.RenderStepped:Connect(function(dt)
    table.insert(frames, dt)
    if #frames > 20 then table.remove(frames, 1) end
    local sum = 0
    for _, f in ipairs(frames) do sum = sum + f end
    local fps = math.floor(#frames / sum)
    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 or 30)
    Overlay.Text = string.format(" BARRAGE | FPS: %d | %dms", fps, ping)
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
        Title = "BARRAGE",
        Text = "Barrage Hub v1.0 [Mine Antarctica Suite] berhasil dimuat!",
        Duration = 5
    })
end)

print("[BARRAGE] Barrage Hub v1.0 loaded successfully (Standalone).")
