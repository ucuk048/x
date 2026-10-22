-- ANTIGRAVITY ENTERPRISE ULTIMATE GAME HUB (lua2.txt) - v9.5.0 (Optimized Mining & Player Mods Suite: Dynamic Reach, Instant Break & Mobility Engine)
-- IMPLEMENTASI LENGKAP 50+ FITUR (COMBAT, VISUALS, MOVEMENT, WORLD, EXPLOITS, UTILITIES)
-- 100% STANDALONE - TANPA DEPENDENSI GITHUB, TANPA ENKRIPSI VM LURAPH, BEBAS KUNCI
-- ==============================================================================

local HUB_NAME = "Antigravity Hub"
local HUB_VERSION = "9.5.0"
local CONFIG_FILE = "antigravity_hub_config.json"
local WAYPOINTS_FILE = "antigravity_waypoints.json"

-- 0. FLIGHT-LOCK PROTOCOL (BARRAGE PATTERN FROM loader.txt)
local _flight = shared._barrageLoaderFlight or shared._agyLoaderFlight
if type(_flight) == "table" and _flight.Running and os.clock() - (_flight.StartedAt or 0) < 600 then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BARRAGE",
            Text = "BARRAGE sedang memuat. Mohon tunggu sebentar...",
            Duration = 4
        })
    end)
    return
end
_flight = { Running = true, Ready = false, StartedAt = os.clock() }
shared._barrageLoaderFlight = _flight
shared._agyLoaderFlight = _flight

-- 1. PEMBERSIHAN SESI LAMA (GLOBAL SINGLETON FROM payload.lua)
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
        EspRange = 1000,
        EspRarities = {
            ["Zenith"] = true,
            ["Cosmic"] = true,
            ["Transcendent"] = true,
            ["Celestial"] = true,
            ["Divine"] = true,
            ["Godly"] = true,
            ["Secret"] = true,
            ["Exotic"] = true,
            ["Mythic"] = true,
            ["Void"] = true,
            ["Legendary"] = true,
            ["Obsidian"] = true,
            ["Epic"] = true,
            ["Diamond"] = true,
            ["Emerald"] = true,
            ["Ruby"] = true,
            ["Sapphire"] = true,
            ["Rare"] = true,
            ["Gold"] = true,
            ["Silver"] = true,
            ["Uncommon"] = true,
            ["Copper"] = true,
            ["Iron"] = true,
            ["Common"] = true,
            ["Stone"] = true,
            ["Crystal"] = true,
            ["Boulder"] = true,
            ["Rock"] = true,
            ["Meteor"] = true,
            ["Ore"] = true
        },
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
        OrePriority = false,
        OrePriorityTier = "Semua Rarity",
        MineTargets = {
            ["Zenith"] = true,
            ["Transcendent"] = true,
            ["Celestial"] = true,
            ["Divine"] = true,
            ["Godly"] = true,
            ["Secret"] = true,
            ["Exotic"] = true,
            ["Mythic"] = true,
            ["Legendary"] = true,
            ["Epic"] = true,
            ["Rare"] = true,
            ["Uncommon"] = true,
            ["Common"] = true,
            ["Boulders"] = true,
            ["Meteors"] = true
        },
        -- Mine Antarctica Toko Gamepass Perks (100% Unlocked)
        Power8x = true,             -- 8X KEKUATAN (+8x Damage Kristal)
        InstantMine = true,          -- RANJAU INSTAN (1-Click Instant Break)
        CarryWeight4x = true,       -- X4 BERAT YANG DIBAWA (+4x Kapasitas Ransel)
        FastDig2x = true,           -- 2X PENGGALIAN CEPAT (+2x Kecepatan Gali)
        Luck2x = true,              -- 2X KEBERUNTUNGAN (+2x Luck Penggalian)
        Luck4x = true,              -- 4X KEBERUNTUNGAN (+4x Luck Penggalian)
        Crystal2x = true,           -- X2 KRISTAL (+2x Kristal yang Diangkat)
        Crystals2x = true,          -- Alias
        Coins2x = true,             -- 2X KOIN (+2x Koin saat Menjual)
        VIPPerks = true,            -- VIP (+25% Koin & 15% Luck)
        AutoCollect = false,
        CollectRange = 300,
        CollectTargets = {
            ["Semua Rarity (All)"] = true,
            ["Crystals"] = true,
            ["Ores"] = true,
            ["Boulders"] = true,
            ["Coins"] = true,
            ["Candy / Permen"] = true,
            ["Runes"] = true,
            ["Chests / Crates"] = true,
            ["Meteors"] = true,
            ["Shards"] = true
        },
        AutoSell = false,
        AutoGarden = false,
        AutoRunes = false,
        AutoUpgrade = false,
        AutoItems = false,
        AutoBomb = false,
        AutoClaimRewards = false,
        AntiFreeze = true,
        InfiniteJetpack = true,
        AntiRagdoll = true,
        NoFallDamage = true,
        CrystalEsp = false,
        -- Barrage UI & Preset States (1:1 Screenshot Exact)
        MiningModsEnabled = true,
        MiningPreset = "Blatant",
        MiningModsList = {
            ["8x Kekuatan"] = true,
            ["Ranjau Instan"] = true,
            ["x4 Berat Dibawa"] = true,
            ["2x Penggalian Cepat"] = true,
            ["2x Keberuntungan"] = true,
            ["4x Keberuntungan"] = true,
            ["x2 Kristal"] = true,
            ["Tidak Ada Kerusakan Jatuh"] = true,
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
        PlayerModsEnabled = true,
        PlayerPreset = "Blatant",
        PlayerModsList = {
            ["Speed"] = true,
            ["Jump Boost"] = true,
            ["Anti Ragdoll"] = true,
            ["Anti Freeze"] = true,
            ["No Fall Damage"] = true,
            ["Infinite Jetpack"] = true,
            ["Noclip"] = false,
            ["Fly"] = false,
            ["SpinBot"] = false,
            ["Click TP"] = false
        },
        TeleportCollectEnabled = false,
        AutoCollectPreset = "Everything",
        AutoMinePreset = "Blatant",
        AutoSellPreset = "Default",
        SellTarget = "Pedagang Base Camp",
        AutoGardenPreset = "Best",
        GardenAction = "Buy Space, Fill Best",
        GardenFeatures = {
            ["Auto Buy Garden Space"] = true,
            ["Auto Fill Best Crystals"] = true,
            ["Auto Harvest Mutated Crystals"] = true,
            ["Prioritize Rarity > Luck"] = true
        },
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
local function enforceMobility(hum)
    if not hum or not hum.Parent then return end
    pcall(function()
        local isPlayerModsOn = HubState.Config.PlayerModsEnabled
        local pList = HubState.Config.PlayerModsList or {}
        local mList = HubState.Config.MiningModsList or {}

        local s = 16
        if isPlayerModsOn and pList["Speed"] then
            s = HubState.Config.WalkSpeed or 32
        elseif HubState.Config.WalkSpeed and HubState.Config.WalkSpeed > 16 then
            s = HubState.Config.WalkSpeed
        end

        -- No Slowdown & Dig While Mining: Pertahankan mobilitas penuh saat menambang / cuaca es
        local isNoSlow = HubState.Config.MiningModsEnabled and (mList["No Slowdown"] or mList["Dig While Mining"])
        if isNoSlow then
            if hum.WalkSpeed < s then
                hum.WalkSpeed = s
            end
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        else
            if hum.WalkSpeed ~= s then
                hum.WalkSpeed = s
            end
        end

        local j = 50
        if isPlayerModsOn and pList["Jump Boost"] then
            j = HubState.Config.JumpPower or 70
        elseif HubState.Config.JumpPower and HubState.Config.JumpPower > 50 then
            j = HubState.Config.JumpPower
        end

        hum.UseJumpPower = true
        if hum.JumpPower ~= j then
            hum.JumpPower = j
        end
    end)
end

local function bindHumanoid(hum)
    if not hum then return end
    enforceMobility(hum)
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        local mList = HubState.Config.MiningModsList or {}
        local isNoSlow = HubState.Config.MiningModsEnabled and (mList["No Slowdown"] or mList["Dig While Mining"])
        local s = HubState.Config.WalkSpeed or 16
        if isNoSlow and hum.WalkSpeed < s then
            hum.WalkSpeed = s
        elseif not isNoSlow and s and s > 0 and hum.WalkSpeed ~= s then
            hum.WalkSpeed = s
        end
    end)
    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        local j = HubState.Config.JumpPower
        if j and j > 0 then
            hum.UseJumpPower = true
            if hum.JumpPower ~= j then
                hum.JumpPower = j
            end
        end
    end)
end

if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then bindHumanoid(hum) end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        bindHumanoid(hum)
    end
end)

Services.RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            enforceMobility(hum)
            -- Bypass pengurang kecepatan cuaca dingin Antartika & anti-speed bawaan game
            local isSpeedActive = (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList and HubState.Config.PlayerModsList["Speed"]) or (HubState.Config.WalkSpeed and HubState.Config.WalkSpeed > 16)
            if isSpeedActive and root and hum.MoveDirection.Magnitude > 0 then
                local desiredSpeed = HubState.Config.WalkSpeed or 32
                if desiredSpeed > 16 then
                    local boost = (desiredSpeed - 16)
                    root.CFrame = root.CFrame + (hum.MoveDirection * (boost * dt))
                end
            end
        end
    end
end)
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
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            if HubState.Config.InfJump then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            local desiredJump = HubState.Config.JumpPower or 50
            if desiredJump > 50 and root then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, desiredJump, root.AssemblyLinearVelocity.Z)
            end
        end
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
-- ==============================================================================
-- 8.5. ENGINE KHUSUS: MINE ANTARCTICA (MASTER SUITE)
-- ==============================================================================
-- 1. Deteksi Bijih & Kristal Terdekat (Spectrum Kelangkaan Lengkap: Zenith -> Common)
local ALL_RARITY_TIERS = {
    "zenith", "cosmic", "transcendent", "celestial", "divine", "godly", "secret",
    "exotic", "mythic", "void", "legendary", "obsidian", "epic", "diamond",
    "emerald", "ruby", "sapphire", "rare", "gold", "silver", "meteor",
    "uncommon", "copper", "iron", "common", "stone", "crystal", "kristal",
    "boulder", "rock", "ore"
}

local ORDERED_RARITY_KEYS = {
    "zenith", "cosmic", "transcendent", "celestial", "divine", "godly", "secret",
    "exotic", "mythic", "void", "legendary", "obsidian", "epic", "diamond",
    "emerald", "ruby", "sapphire", "rare", "gold", "silver", "meteor",
    "uncommon", "copper", "iron", "common", "stone", "crystal", "kristal",
    "boulder", "rock", "ore"
}

local RARITY_RANKS = {
    zenith = 100000,
    cosmic = 95000,
    transcendent = 60000,
    celestial = 40000,
    divine = 30000,
    godly = 25000,
    secret = 20000,
    exotic = 15000,
    mythic = 10000,
    void = 8000,
    legendary = 5000,
    obsidian = 4000,
    epic = 2500,
    diamond = 2000,
    emerald = 1800,
    ruby = 1600,
    sapphire = 1400,
    rare = 1200,
    gold = 1000,
    silver = 800,
    meteor = 700,
    uncommon = 500,
    copper = 400,
    iron = 300,
    crystal = 250,
    kristal = 250,
    common = 100,
    stone = 80,
    boulder = 50,
    rock = 50,
    ore = 20
}

local RARITY_COLORS = {
    zenith = Color3.fromRGB(244, 63, 94),          -- Rose Neon
    cosmic = Color3.fromRGB(244, 63, 94),          -- Rose Neon
    transcendent = Color3.fromRGB(168, 85, 247),    -- Purple
    celestial = Color3.fromRGB(56, 189, 248),       -- Sky Cyan
    divine = Color3.fromRGB(250, 204, 21),         -- Gold
    godly = Color3.fromRGB(239, 68, 68),           -- Crimson Red
    secret = Color3.fromRGB(192, 132, 252),        -- Violet
    exotic = Color3.fromRGB(20, 184, 166),         -- Teal
    mythic = Color3.fromRGB(147, 51, 234),         -- Deep Purple
    void = Color3.fromRGB(147, 51, 234),           -- Deep Purple
    legendary = Color3.fromRGB(245, 158, 11),      -- Amber Orange
    obsidian = Color3.fromRGB(245, 158, 11),       -- Amber Orange
    epic = Color3.fromRGB(99, 102, 241),           -- Indigo
    diamond = Color3.fromRGB(99, 102, 241),        -- Indigo
    emerald = Color3.fromRGB(99, 102, 241),        -- Indigo
    ruby = Color3.fromRGB(99, 102, 241),           -- Indigo
    sapphire = Color3.fromRGB(99, 102, 241),       -- Indigo
    rare = Color3.fromRGB(59, 130, 246),           -- Royal Blue
    gold = Color3.fromRGB(59, 130, 246),           -- Royal Blue
    silver = Color3.fromRGB(59, 130, 246),         -- Royal Blue
    uncommon = Color3.fromRGB(34, 197, 94),        -- Emerald Green
    copper = Color3.fromRGB(34, 197, 94),          -- Emerald Green
    iron = Color3.fromRGB(34, 197, 94),            -- Emerald Green
    common = Color3.fromRGB(148, 163, 184),        -- Slate
    stone = Color3.fromRGB(148, 163, 184),         -- Slate
    meteor = Color3.fromRGB(251, 146, 60),         -- Meteor Orange
    crystal = Color3.fromRGB(236, 72, 153),        -- Hot Pink
    kristal = Color3.fromRGB(236, 72, 153),        -- Hot Pink
    boulder = Color3.fromRGB(203, 213, 225),       -- Ice Silver
    rock = Color3.fromRGB(203, 213, 225),          -- Ice Silver
    ore = Color3.fromRGB(161, 161, 170)            -- Zinc
}

local function getObjectRarity(obj)
    if not obj then return 100, "Common", RARITY_COLORS.common end
    local name = obj.Name:lower()

    -- 1. Periksa Attributes
    local attrRarity = obj:GetAttribute("Rarity") or obj:GetAttribute("Tier") or obj:GetAttribute("Kelangkaan") or obj:GetAttribute("Type")
    if attrRarity and type(attrRarity) == "string" then
        local an = attrRarity:lower()
        for _, rk in ipairs(ORDERED_RARITY_KEYS) do
            if an:find(rk) then
                local label = rk:sub(1,1):upper() .. rk:sub(2)
                return RARITY_RANKS[rk] or 100, label, RARITY_COLORS[rk] or RARITY_COLORS.common
            end
        end
    end

    -- 2. Periksa Child Values (StringValue / NumberValue)
    local valObj = obj:FindFirstChild("Rarity") or obj:FindFirstChild("Tier") or obj:FindFirstChild("Kelangkaan")
    if valObj and valObj:IsA("ValueBase") and type(valObj.Value) == "string" then
        local vn = valObj.Value:lower()
        for _, rk in ipairs(ORDERED_RARITY_KEYS) do
            if vn:find(rk) then
                local label = rk:sub(1,1):upper() .. rk:sub(2)
                return RARITY_RANKS[rk] or 100, label, RARITY_COLORS[rk] or RARITY_COLORS.common
            end
        end
    end

    -- 3. Periksa ProximityPrompt Text
    for _, p in ipairs(obj:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            local pText = (p.ObjectText .. " " .. p.ActionText):lower()
            for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                if pText:find(rk) then
                    local label = rk:sub(1,1):upper() .. rk:sub(2)
                    return RARITY_RANKS[rk] or 100, label, RARITY_COLORS[rk] or RARITY_COLORS.common
                end
            end
        end
    end

    -- 4. Periksa Nama Model / Part
    for _, rk in ipairs(ORDERED_RARITY_KEYS) do
        if name:find(rk) then
            local label = rk:sub(1,1):upper() .. rk:sub(2)
            return RARITY_RANKS[rk] or 100, label, RARITY_COLORS[rk] or RARITY_COLORS.common
        end
    end

    -- Fallback Keyword Cerdas
    if name:find("crystal") or name:find("kristal") then
        return 250, "Crystal", RARITY_COLORS.crystal
    elseif name:find("meteor") then
        return 700, "Meteor", RARITY_COLORS.meteor
    elseif name:find("boulder") or name:find("batu") or name:find("rock") then
        return 50, "Boulder", RARITY_COLORS.boulder
    end

    return 100, "Common", RARITY_COLORS.common
end

local function getClosestOre(customRange)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local maxDist = customRange or HubState.Config.MineRange or 35

    local candidates = {}
    local seen = {}

    local function checkCandidate(obj)
        if not obj or seen[obj] then return end
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
        local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or (obj:FindFirstChildWhichIsA("BasePart") and obj:FindFirstChildWhichIsA("BasePart").Position)) or (obj:IsA("BasePart") and obj.Position)
        if not pos then return end
        local dist = (pos - myRoot.Position).Magnitude
        if dist > maxDist then return end

        seen[obj] = true
        local rScore, rLabel, _ = getObjectRarity(obj)

        -- Prioritas Cerdas:
        -- 1. Tambahkan bonus skor jika OrePriority aktif
        -- 2. Batuan Common/Rare/Epic TETAP VALID dan TIDAK PERNAH DIBUANG!
        -- 3. Jarak terdekat menjadi penentu utama agar objek tepat di depan pemain selalu ditambang
        local priorityBonus = (HubState.Config.OrePriority and (rScore or 100) or 0) * 15
        local score = (1000 - dist * 10) + priorityBonus

        table.insert(candidates, {obj = obj, dist = dist, score = score})
    end

    local searchFolders = {
        workspace:FindFirstChild("Ores"),
        workspace:FindFirstChild("Boulders"),
        workspace:FindFirstChild("Crystals"),
        workspace:FindFirstChild("Nodes"),
        workspace:FindFirstChild("Map"),
        workspace:FindFirstChild("Debris"),
        workspace:FindFirstChild("Terrain"),
        workspace:FindFirstChild("Chunks"),
        workspace:FindFirstChild("Mines"),
        workspace:FindFirstChild("Mining"),
        workspace:FindFirstChild("Deposits"),
        workspace:FindFirstChild("Rocks"),
        workspace:FindFirstChild("Spawns"),
        workspace:FindFirstChild("Caves"),
        workspace:FindFirstChild("Cave"),
        workspace:FindFirstChild("Zones"),
        workspace:FindFirstChild("Zone"),
        workspace:FindFirstChild("Ice"),
        workspace:FindFirstChild("Glacier")
    }

    for _, folder in ipairs(searchFolders) do
        if folder then
            local children = folder:GetChildren()
            for _, obj in ipairs(children) do
                local name = obj.Name:lower()
                if name:find("ore") or name:find("boulder") or name:find("crystal") or name:find("kristal") or name:find("rock") or name:find("deposit") or name:find("meteor") or name:find("node") then
                    checkCandidate(obj)
                elseif obj:FindFirstChildOfClass("ProximityPrompt") then
                    checkCandidate(obj)
                end
                for _, sub in ipairs(obj:GetChildren()) do
                    local sname = sub.Name:lower()
                    if sname:find("ore") or sname:find("boulder") or sname:find("crystal") or sname:find("kristal") or sname:find("rock") then
                        checkCandidate(sub)
                    end
                end
            end
        end
    end

    -- Pindai juga objek langsung di workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        local name = obj.Name:lower()
        if name:find("ore") or name:find("boulder") or name:find("crystal") or name:find("kristal") or name:find("rock") or name:find("deposit") or name:find("meteor") or name:find("node") then
            checkCandidate(obj)
        end
    end

    -- Pindai ProximityPrompt aksi tambang di sekitar pemain
    pcall(function()
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local pText = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()
                if pText:find("mine") or pText:find("gali") or pText:find("break") or pText:find("boulder") or pText:find("crystal") or pText:find("ore") or pText:find("hancur") or pText:find("rock") or pText:find("deposit") or pText:find("hit") or pText:find("strike") then
                    local pParent = prompt.Parent
                    if pParent and pParent:IsA("BasePart") then
                        local pObj = pParent.Parent and pParent.Parent:IsA("Model") and pParent.Parent or pParent
                        checkCandidate(pObj)
                    end
                end
            end
        end
    end)

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1].obj
end

-- 2. Auto Equip Best Pickaxe Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if HubState.Config.AutoPickaxe and LocalPlayer.Character then
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if hum and backpack then
                    local bestTool = nil
                    local highestTier = 0
                    local pickaxeKeywords = {
                        ["zenith"] = 1000, ["transcendent"] = 800, ["celestial"] = 600, ["divine"] = 500,
                        ["godly"] = 400, ["secret"] = 350, ["exotic"] = 300, ["mythic"] = 250,
                        ["legendary"] = 200, ["epic"] = 150, ["rare"] = 100, ["uncommon"] = 50,
                        ["diamond"] = 80, ["crystal"] = 60, ["gold"] = 40, ["iron"] = 20,
                        ["pickaxe"] = 10, ["beliung"] = 10, ["axe"] = 5
                    }
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            local tname = tool.Name:lower()
                            for kw, tier in pairs(pickaxeKeywords) do
                                if tname:find(kw) and tier > highestTier then
                                    highestTier = tier
                                    bestTool = tool
                                end
                            end
                        end
                    end
                    if bestTool and not LocalPlayer.Character:FindFirstChild(bestTool.Name) then
                        hum:EquipTool(bestTool)
                    end
                end
            end)
        end
    end
end)

-- ==============================================================================
-- 3. GLOBAL GAMEPASS HOOK & MINING MODS ENGINE (LEVEL ULTIMATE DEWA)
-- ==============================================================================

-- 3.0. MarketplaceService & __namecall Remote Interceptor
local oldNamecall = nil
local rawFireServer = Instance.new("RemoteEvent").FireServer
local rawInvokeServer = Instance.new("RemoteFunction").InvokeServer

pcall(function()
    local MPS = game:GetService("MarketplaceService")
    if hookmetamethod then
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() then
                -- 1. Gamepass Check Interception (Client Spoofing)
                if method == "UserOwnsGamePassAsync" or method == "PlayerOwnsAsset" then
                    return true
                end

                -- 2. Mining Remote Hit Multiplier Interception
                if (method == "FireServer" or method == "InvokeServer") and HubState.Config.MiningModsEnabled then
                    local sName = (typeof(self) == "Instance" and self.Name or ""):lower()
                    local isMiningRemote = sName:find("mine") or sName:find("hit") or sName:find("damage") or sName:find("boulder") 
                        or sName:find("swing") or sName:find("dig") or sName:find("break") or sName:find("ore") or sName:find("strike")
                        or sName:find("attack") or sName:find("smash")

                    if isMiningRemote then
                        local pList = HubState.Config.MiningModsList or {}
                        local mult = 1
                        if HubState.Config.InstantMine or pList["Ranjau Instan"] or pList["Instant Break"] then
                            mult = 16
                        elseif HubState.Config.Power8x or pList["8x Kekuatan"] then
                            mult = 8
                        elseif HubState.Config.FastMineHits and HubState.Config.FastMineHits > 1 then
                            mult = HubState.Config.FastMineHits
                        end

                        if mult > 1 then
                            local args = {...}
                            if method == "FireServer" and self:IsA("RemoteEvent") then
                                for i = 2, mult do
                                    pcall(rawFireServer, self, table.unpack(args))
                                end
                            end
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end
    if hookfunction and MPS.UserOwnsGamePassAsync then
        hookfunction(MPS.UserOwnsGamePassAsync, function(self, ...)
            return true
        end)
    end
end)

-- 3.0.1. ProximityPrompt Engine: Instant Hold, Extended Reach & Auto-Trigger
local function processMiningPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if not HubState.Config.MiningModsEnabled then return end
    local pText = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()
    local isMining = pText:find("mine") or pText:find("gali") or pText:find("break") or pText:find("boulder") 
        or pText:find("crystal") or pText:find("ore") or pText:find("hancur") or pText:find("rock") 
        or pText:find("deposit") or pText:find("hit") or pText:find("strike")

    if isMining then
        local pList = HubState.Config.MiningModsList or {}
        local isInstant = HubState.Config.InstantMine or HubState.Config.InstantPrompt or pList["Ranjau Instan"] or pList["Instant Break"]
        if isInstant then
            prompt.HoldDuration = 0
        end
        if pList["Reach Mine"] or HubState.Config.MineRange then
            local reach = HubState.Config.MineRange or 50
            prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, reach)
            prompt.RequiresLineOfSight = false
        end
    end
end

pcall(function()
    Services.ProximityPromptService.PromptShown:Connect(function(prompt)
        processMiningPrompt(prompt)
    end)
    Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LocalPlayer and HubState.Config.MiningModsEnabled then
            processMiningPrompt(prompt)
            local pText = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()
            local isMining = pText:find("mine") or pText:find("gali") or pText:find("break") or pText:find("boulder") 
                or pText:find("crystal") or pText:find("ore") or pText:find("hancur") or pText:find("rock") or pText:find("deposit")
            if isMining and fireproximityprompt then
                fireproximityprompt(prompt, 0)
            end
        end
    end)
    workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("ProximityPrompt") then
            processMiningPrompt(desc)
        end
    end)
end)

-- Background Prompt & Range Sweeper (1.0s Interval)
task.spawn(function()
    while true do
        task.wait(1.0)
        if HubState.Config.MiningModsEnabled then
            pcall(function()
                for _, prompt in ipairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        processMiningPrompt(prompt)
                    end
                end
            end)
        end
    end
end)

-- 3.0.2. Remote Event Cache System (Zero-Lag Enterprise Scanner)
local cachedMiningRemotes = {}
local cachedCollectRemotes = {}
local cachedGardenRemotes = {}
local cachedSellRemotes = {}
local cachedRuneRemotes = {}
local cachedUpgradeRemotes = {}
local cachedRewardRemotes = {}
local cachedBombRemotes = {}
local cachedItemRemotes = {}
local lastRemoteScan = 0

local function scanAndCacheRemotes()
    local now = os.clock()
    if now - lastRemoteScan < 15 and (#cachedMiningRemotes > 0 or #cachedCollectRemotes > 0) then return end
    lastRemoteScan = now

    table.clear(cachedMiningRemotes)
    table.clear(cachedCollectRemotes)
    table.clear(cachedGardenRemotes)
    table.clear(cachedSellRemotes)
    table.clear(cachedRuneRemotes)
    table.clear(cachedUpgradeRemotes)
    table.clear(cachedRewardRemotes)
    table.clear(cachedBombRemotes)
    table.clear(cachedItemRemotes)

    local function checkRemote(rem)
        if not rem or not (rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction")) then return end
        local n = rem.Name:lower()
        if n:find("mine") or n:find("hit") or n:find("damage") or n:find("boulder") or n:find("swing") or n:find("dig") or n:find("break") or n:find("strike") or n:find("attack") then
            table.insert(cachedMiningRemotes, rem)
        end
        if n:find("collect") or n:find("pickup") or n:find("claim") or n:find("take") or n:find("grab") then
            table.insert(cachedCollectRemotes, rem)
        end
        if n:find("garden") or n:find("kebun") or n:find("plant") or n:find("harvest") or n:find("plot") or n:find("space") then
            table.insert(cachedGardenRemotes, rem)
        end
        if n:find("sell") or n:find("vendor") or n:find("shop") or n:find("merchant") then
            table.insert(cachedSellRemotes, rem)
        end
        if n:find("rune") or n:find("altar") or n:find("infuse") or n:find("craftrune") or n:find("activaterune") then
            table.insert(cachedRuneRemotes, rem)
        end
        if n:find("upgrade") or n:find("buy") or n:find("purchase") or n:find("pickaxe") or n:find("bag") or n:find("capacity") then
            table.insert(cachedUpgradeRemotes, rem)
        end
        if n:find("reward") or n:find("gift") or n:find("daily") or n:find("quest") or n:find("playtime") or n:find("prize") then
            table.insert(cachedRewardRemotes, rem)
        end
        if n:find("bomb") or n:find("dynamite") or n:find("explode") or n:find("blast") or n:find("throw") then
            table.insert(cachedBombRemotes, rem)
        end
        if n:find("buyitem") or n:find("openchest") or n:find("openbox") or n:find("radar") or n:find("useitem") then
            table.insert(cachedItemRemotes, rem)
        end
    end

    pcall(function()
        for _, rem in ipairs(Services.ReplicatedStorage:GetDescendants()) do
            checkRemote(rem)
        end
    end)
end
scanAndCacheRemotes()

-- 3.0.3. Multi-Vector Mining Hit Execution (Prompt + TouchInterest + Remotes + ClickDetector)
local function fireMiningHit(targetOre, hits)
    if not targetOre then return end
    hits = math.clamp(hits or 1, 1, 32)
    
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))

    -- Vektor 1: Picu ProximityPrompt instan jika ada
    pcall(function()
        for _, p in ipairs(targetOre:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                p.HoldDuration = 0
                if fireproximityprompt then fireproximityprompt(p, 0) end
            end
        end
        if targetOre.Parent then
            for _, p in ipairs(targetOre.Parent:GetChildren()) do
                if p:IsA("ProximityPrompt") then
                    p.HoldDuration = 0
                    if fireproximityprompt then fireproximityprompt(p, 0) end
                end
            end
        end
    end)

    -- Vektor 2: Picu ClickDetector jika ada
    pcall(function()
        for _, cd in ipairs(targetOre:GetDescendants()) do
            if cd:IsA("ClickDetector") and fireclickdetector then
                fireclickdetector(cd, 0)
            end
        end
    end)

    -- Vektor 3: Picu TouchInterest Fisika Pickaxe (Physical Swing Hits)
    if handle and firetouchinterest then
        local targetParts = {}
        if targetOre:IsA("BasePart") then
            table.insert(targetParts, targetOre)
        else
            for _, bp in ipairs(targetOre:GetDescendants()) do
                if bp:IsA("BasePart") and bp.CanTouch ~= false then
                    table.insert(targetParts, bp)
                end
            end
        end
        for _, tp in ipairs(targetParts) do
            for i = 1, math.min(hits, 8) do
                pcall(function()
                    firetouchinterest(handle, tp, 0)
                    firetouchinterest(handle, tp, 1)
                end)
            end
        end
    end

    -- Vektor 4: Picu Cached Mining Remotes dengan Parameter Lengkap
    scanAndCacheRemotes()
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hitPos = targetOre:IsA("BasePart") and targetOre.Position or (targetOre.PrimaryPart and targetOre.PrimaryPart.Position or (myRoot and myRoot.Position or Vector3.new()))

    for _, rem in ipairs(cachedMiningRemotes) do
        if rem:IsA("RemoteEvent") then
            for i = 1, hits do
                pcall(function() rem:FireServer(targetOre, hitPos, tool) end)
                pcall(function() rem:FireServer(targetOre, hitPos) end)
                pcall(function() rem:FireServer(targetOre) end)
            end
        elseif rem:IsA("RemoteFunction") then
            pcall(function() rem:InvokeServer(targetOre, hitPos, tool) end)
        end
    end
end

-- 3.0.4. Universal Tool Hooking (Attributes, IntValues, Manual Swings & Reach)
local function hookTool(tool)
    if not tool or not tool:IsA("Tool") then return end

    local pList = HubState.Config.MiningModsList or {}
    local isPower = HubState.Config.Power8x or (HubState.Config.MiningModsEnabled and pList["8x Kekuatan"])
    local isInst = HubState.Config.InstantMine or (HubState.Config.MiningModsEnabled and (pList["Ranjau Instan"] or pList["Instant Break"]))
    local isFast = HubState.Config.FastDig2x or (HubState.Config.MiningModsEnabled and (pList["2x Penggalian Cepat"] or pList["Fast Swing"]))

    pcall(function()
        -- 1. Modifikasi Attributes
        if isPower then
            local dmg = tool:GetAttribute("Damage") or tool:GetAttribute("Power") or 10
            tool:SetAttribute("Damage", dmg * 8)
            tool:SetAttribute("Power", dmg * 8)
            tool:SetAttribute("MiningPower", 8)
        end
        if isInst then
            tool:SetAttribute("Damage", 999999)
            tool:SetAttribute("Power", 999999)
            tool:SetAttribute("InstantBreak", true)
        end
        if isFast then
            tool:SetAttribute("Cooldown", 0.01)
            tool:SetAttribute("Delay", 0.01)
            tool:SetAttribute("AttackSpeed", 3)
            tool:SetAttribute("SwingSpeed", 3)
        end

        -- 2. Modifikasi Value Objects di dalam Tool
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("ValueBase") then
                local cn = child.Name:lower()
                if (cn:find("dmg") or cn:find("damage") or cn:find("power") or cn:find("strength") or cn:find("hit")) and type(child.Value) == "number" then
                    local orig = child:GetAttribute("Orig")
                    if not orig then
                        orig = child.Value
                        child:SetAttribute("Orig", orig)
                    end
                    child.Value = isInst and 999999 or (isPower and (orig * 8) or orig)
                elseif (cn:find("cooldown") or cn:find("delay") or cn:find("rate")) and type(child.Value) == "number" then
                    child.Value = isFast and 0.01 or child.Value
                end
            end
        end
    end)

    if not tool:GetAttribute("AGY_SwingHooked") then
        tool:SetAttribute("AGY_SwingHooked", true)
        tool.Activated:Connect(function()
            if not HubState.Config.MiningModsEnabled then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local reach = HubState.Config.MineRange or 35
            local targetOre = getClosestOre(reach)
            if targetOre then
                local powerMult = 1
                if HubState.Config.InstantMine or (HubState.Config.MiningModsList and (HubState.Config.MiningModsList["Ranjau Instan"] or HubState.Config.MiningModsList["Instant Break"])) then
                    powerMult = 16
                elseif HubState.Config.Power8x or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["8x Kekuatan"]) then
                    powerMult = 8
                elseif HubState.Config.FastMineHits and HubState.Config.FastMineHits > 1 then
                    powerMult = HubState.Config.FastMineHits
                end
                fireMiningHit(targetOre, powerMult)
            end
        end)
    end
end

local toolsHookedInitialized = false
local function initToolHooks()
    if toolsHookedInitialized then return end
    toolsHookedInitialized = true

    local function onBackpack(bp)
        if not bp then return end
        for _, t in ipairs(bp:GetChildren()) do hookTool(t) end
        bp.ChildAdded:Connect(hookTool)
    end

    local function onCharacter(char)
        if not char then return end
        for _, t in ipairs(char:GetChildren()) do hookTool(t) end
        char.ChildAdded:Connect(hookTool)
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then onBackpack(bp) end
    LocalPlayer.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then onBackpack(child) end
    end)

    if LocalPlayer.Character then onCharacter(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        onCharacter(char)
    end)
end
initToolHooks()

-- 3.0.5. Hyperspeed Auto-Swing on Mouse/Touch Hold
local isHoldingClick = false
pcall(function()
    Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and (HubState.Config.MiningModsList["Fast Swing"] or HubState.Config.MiningModsList["2x Penggalian Cepat"]) then
                isHoldingClick = true
                task.spawn(function()
                    while isHoldingClick do
                        local char = LocalPlayer.Character
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate()
                        end
                        task.wait(0.08)
                    end
                end)
            end
        end
    end)
    Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isHoldingClick = false
        end
    end)
end)

-- 3.0.6. Emulasi Folder Gamepasses & Sinkronisasi Atribut Toko
local function ensureGamepassFolder()
    local passFolder = LocalPlayer:FindFirstChild("Gamepasses") or LocalPlayer:FindFirstChild("Passes") or LocalPlayer:FindFirstChild("Perks")
    if not passFolder then
        passFolder = Instance.new("Folder")
        passFolder.Name = "Gamepasses"
        pcall(function() passFolder.Parent = LocalPlayer end)
    end
    local passStatus = {
        ["8x Strength"] = HubState.Config.Power8x or false,
        ["8x Power"] = HubState.Config.Power8x or false,
        ["8x Kekuatan"] = HubState.Config.Power8x or false,
        ["Instant Mine"] = HubState.Config.InstantMine or false,
        ["Instant Break"] = HubState.Config.InstantMine or false,
        ["Ranjau Instan"] = HubState.Config.InstantMine or false,
        ["No Fall Damage"] = HubState.Config.NoFallDamage or false,
        ["Tidak Ada Kerusakan Jatuh"] = HubState.Config.NoFallDamage or false,
        ["4x Weight"] = HubState.Config.CarryWeight4x or false,
        ["4x Capacity"] = HubState.Config.CarryWeight4x or false,
        ["x4 Berat Dibawa"] = HubState.Config.CarryWeight4x or false,
        ["2x Fast Dig"] = HubState.Config.FastDig2x or false,
        ["2x Penggalian Cepat"] = HubState.Config.FastDig2x or false,
        ["2x Luck"] = HubState.Config.Luck2x or false,
        ["2x Keberuntungan"] = HubState.Config.Luck2x or false,
        ["4x Luck"] = HubState.Config.Luck4x or false,
        ["4x Keberuntungan"] = HubState.Config.Luck4x or false,
        ["2x Crystals"] = HubState.Config.Crystal2x or HubState.Config.Crystals2x or false,
        ["x2 Kristal"] = HubState.Config.Crystal2x or HubState.Config.Crystals2x or false,
        ["2x Coins"] = HubState.Config.Coins2x or false,
        ["2x Koin"] = HubState.Config.Coins2x or false,
        ["VIP"] = HubState.Config.VIPPerks or false,
        ["VIP Perks"] = HubState.Config.VIPPerks or false
    }
    for pn, isActive in pairs(passStatus) do
        local val = passFolder:FindFirstChild(pn)
        if not val then
            val = Instance.new("BoolValue")
            val.Name = pn
            val.Value = isActive
            pcall(function() val.Parent = passFolder end)
        else
            val.Value = isActive
        end
    end
end

-- Spoof In-Game Shop GUI: Tampilkan Semua Gamepass Sebagai DIMILIKI
local function spoofShopGamepassUI()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end

    pcall(function()
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("GuiObject") then
                local gn = gui.Name:lower()
                local isPassElement = gn:find("pass") or gn:find("gamepass") or gn:find("toko") or gn:find("shop") or gn:find("perk")
                if isPassElement then
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                            local txt = child.Text:lower()
                            if txt:find("r%$") or txt:find("robux") or txt:find("beli") or txt:find("buy") or txt:find("purchase") or txt:find("harga") or txt:find("price") then
                                child.Text = "DIMILIKI"
                                child.TextColor3 = Color3.fromRGB(46, 204, 113)
                                if child:IsA("TextButton") then
                                    child.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function syncGamepassPerks()
    if not LocalPlayer then return end
    local char = LocalPlayer.Character

    -- 1. Gamepass Folder
    ensureGamepassFolder()

    -- 2. x4 Berat yang Dibawa (Rock-Solid Stabel 4x Kapasitas Ransel pada Semua Folder Data)
    local is4xBag = HubState.Config.CarryWeight4x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["x4 Berat Dibawa"])
    pcall(function()
        local capAttrs = {
            "MaxCapacity", "BackpackCapacity", "BagSize", "WeightLimit", "MaxWeight",
            "Capacity", "BagCapacity", "MaxBag", "InventoryCapacity", "Storage", "MaxStorage"
        }
        for _, a in ipairs(capAttrs) do
            local cur = LocalPlayer:GetAttribute(a)
            if cur and type(cur) == "number" then
                local orig = LocalPlayer:GetAttribute(a .. "_Orig")
                if not orig then
                    orig = cur
                    LocalPlayer:SetAttribute(a .. "_Orig", orig)
                end
                LocalPlayer:SetAttribute(a, is4xBag and (orig * 4) or orig)
            end
            if char then
                local ccur = char:GetAttribute(a)
                if ccur and type(ccur) == "number" then
                    local corig = char:GetAttribute(a .. "_Orig")
                    if not corig then
                        corig = ccur
                        char:SetAttribute(a .. "_Orig", corig)
                    end
                    char:SetAttribute(a, is4xBag and (corig * 4) or corig)
                end
            end
        end

        local searchFolders = {
            LocalPlayer:FindFirstChild("leaderstats"),
            LocalPlayer:FindFirstChild("Data"),
            LocalPlayer:FindFirstChild("Stats"),
            LocalPlayer:FindFirstChild("Values"),
            LocalPlayer:FindFirstChild("PlayerData"),
            LocalPlayer:FindFirstChild("Profile"),
            LocalPlayer:FindFirstChild("Inventory")
        }
        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    local cn = child.Name:lower()
                    if (cn:find("cap") or cn:find("bag") or cn:find("maxweight") or cn:find("storage") or cn:find("weight")) and child:IsA("ValueBase") and type(child.Value) == "number" then
                        local lorig = child:GetAttribute("Orig")
                        if not lorig then
                            lorig = child.Value
                            child:SetAttribute("Orig", lorig)
                        end
                        child.Value = is4xBag and (lorig * 4) or lorig
                    end
                end
            end
        end

        LocalPlayer:SetAttribute("CarryWeight4x", is4xBag)
        LocalPlayer:SetAttribute("4xWeight", is4xBag)
        LocalPlayer:SetAttribute("x4Weight", is4xBag)
        LocalPlayer:SetAttribute("Has4xWeight", is4xBag)
        LocalPlayer:SetAttribute("Owns4xWeight", is4xBag)
        LocalPlayer:SetAttribute("Pass_4xWeight", is4xBag)
        LocalPlayer:SetAttribute("BagMultiplier", is4xBag and 4 or 1)
        LocalPlayer:SetAttribute("WeightMultiplier", is4xBag and 4 or 1)
        if char then
            char:SetAttribute("BagMultiplier", is4xBag and 4 or 1)
            char:SetAttribute("WeightMultiplier", is4xBag and 4 or 1)
        end
    end)

    -- 3. 2x & 4x Keberuntungan (Dua Gamepass Terpisah: 2x Luck & 4x Luck)
    local is2xLuck = HubState.Config.Luck2x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["2x Keberuntungan"])
    local is4xLuck = HubState.Config.Luck4x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["4x Keberuntungan"])
    local isVIP = HubState.Config.VIPPerks

    local luckMult = 1
    if is2xLuck then luckMult = luckMult * 2 end
    if is4xLuck then luckMult = luckMult * 4 end
    if isVIP then luckMult = luckMult * 1.25 end

    pcall(function()
        LocalPlayer:SetAttribute("2xLuck", is2xLuck)
        LocalPlayer:SetAttribute("Has2xLuck", is2xLuck)
        LocalPlayer:SetAttribute("Owns2xLuck", is2xLuck)
        LocalPlayer:SetAttribute("Pass_2xLuck", is2xLuck)

        LocalPlayer:SetAttribute("4xLuck", is4xLuck)
        LocalPlayer:SetAttribute("Has4xLuck", is4xLuck)
        LocalPlayer:SetAttribute("Owns4xLuck", is4xLuck)
        LocalPlayer:SetAttribute("Pass_4xLuck", is4xLuck)

        LocalPlayer:SetAttribute("LuckMultiplier", luckMult)
        LocalPlayer:SetAttribute("Luck", luckMult)
        LocalPlayer:SetAttribute("DigLuck", luckMult)
        LocalPlayer:SetAttribute("MiningLuck", luckMult)
        LocalPlayer:SetAttribute("CrystalLuck", luckMult)
        if char then
            char:SetAttribute("Luck", luckMult)
            char:SetAttribute("LuckMultiplier", luckMult)
            char:SetAttribute("2xLuck", is2xLuck)
            char:SetAttribute("4xLuck", is4xLuck)
        end

        local searchFolders = {
            LocalPlayer:FindFirstChild("leaderstats"),
            LocalPlayer:FindFirstChild("Data"),
            LocalPlayer:FindFirstChild("Stats")
        }
        for _, folder in ipairs(searchFolders) do
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child.Name:lower():find("luck") and child:IsA("ValueBase") and type(child.Value) == "number" then
                        child.Value = luckMult
                    end
                end
            end
        end
    end)

    -- 4. x2 Kristal
    local is2xCrystal = HubState.Config.Crystal2x or HubState.Config.Crystals2x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["x2 Kristal"])
    pcall(function()
        LocalPlayer:SetAttribute("CrystalMultiplier", is2xCrystal and 2 or 1)
        LocalPlayer:SetAttribute("DoubleCrystals", is2xCrystal)
        LocalPlayer:SetAttribute("x2Crystal", is2xCrystal)
        LocalPlayer:SetAttribute("Has2xCrystal", is2xCrystal)
        LocalPlayer:SetAttribute("Owns2xCrystal", is2xCrystal)
        if char then
            char:SetAttribute("CrystalMultiplier", is2xCrystal and 2 or 1)
            char:SetAttribute("DoubleCrystals", is2xCrystal)
        end
    end)

    -- 5. 2x Koin
    local is2xCoins = HubState.Config.Coins2x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["2x Koin"])
    pcall(function()
        LocalPlayer:SetAttribute("CoinMultiplier", is2xCoins and 2 or 1)
        LocalPlayer:SetAttribute("SellMultiplier", is2xCoins and 2 or 1)
        LocalPlayer:SetAttribute("DoubleCoins", is2xCoins)
        LocalPlayer:SetAttribute("2xCoins", is2xCoins)
        LocalPlayer:SetAttribute("Has2xCoins", is2xCoins)
        LocalPlayer:SetAttribute("Owns2xCoins", is2xCoins)
    end)

    -- 6. 8x Kekuatan & Ranjau Instan pada Pickaxe
    local is8xPower = HubState.Config.Power8x or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["8x Kekuatan"])
    local isInstMine = HubState.Config.InstantMine or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["Ranjau Instan"])
    local isFastDig = HubState.Config.FastDig2x or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["2x Penggalian Cepat"])

    pcall(function()
        LocalPlayer:SetAttribute("StrengthMultiplier", is8xPower and 8 or 1)
        LocalPlayer:SetAttribute("Power8x", is8xPower)
        LocalPlayer:SetAttribute("Has8xPower", is8xPower)
        LocalPlayer:SetAttribute("Owns8xPower", is8xPower)
        LocalPlayer:SetAttribute("InstantMine", isInstMine)
        LocalPlayer:SetAttribute("InstantBreak", isInstMine)
        LocalPlayer:SetAttribute("FastDig2x", isFastDig)
        LocalPlayer:SetAttribute("DigSpeedMultiplier", isFastDig and 2 or 1)
    end)

    -- 7. Visual UI Toko Spoofing
    spoofShopGamepassUI()
end
HubState.SyncGamepasses = syncGamepassPerks
syncGamepassPerks()

task.spawn(function()
    while true do
        task.wait(2.0)
        syncGamepassPerks()
    end
end)

-- 3.0.7. Fast Dig 2x Animation Speed Doubler (Stutter-Free Event Hook)
local function hookAnimationSpeed(hum)
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        if HubState.Config.MiningModsEnabled and (HubState.Config.FastDig2x or (HubState.Config.MiningModsList and (HubState.Config.MiningModsList["2x Penggalian Cepat"] or HubState.Config.MiningModsList["Fast Swing"]))) then
            local aname = track.Name:lower()
            if aname:find("mine") or aname:find("swing") or aname:find("dig") or aname:find("attack") or aname:find("pickaxe") or aname:find("tool") then
                pcall(function() track:AdjustSpeed(2.5) end)
            end
        end
    end)
end
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hookAnimationSpeed(hum) end
end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then hookAnimationSpeed(hum) end
end)

-- 3.0.8. Auto Equip Best Tool & Auto Repair Engine
local function autoEquipBestTool()
    if not HubState.Config.MiningModsEnabled then return end
    if not (HubState.Config.AutoPickaxe or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["Auto Equip Best Tool"])) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local curTool = char:FindFirstChildOfClass("Tool")
    if not curTool then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            local bestTool = nil
            local highestScore = -1
            local pickKeywords = {
                ["zenith"] = 1000, ["transcendent"] = 800, ["celestial"] = 600, ["divine"] = 500,
                ["godly"] = 400, ["secret"] = 350, ["exotic"] = 300, ["mythic"] = 250,
                ["legendary"] = 200, ["epic"] = 150, ["rare"] = 100, ["uncommon"] = 50,
                ["diamond"] = 80, ["crystal"] = 60, ["gold"] = 40, ["iron"] = 20,
                ["pickaxe"] = 15, ["beliung"] = 15, ["axe"] = 10, ["drill"] = 12, ["hammer"] = 10
            }
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") then
                    local tname = tool.Name:lower()
                    local score = 10
                    for kw, val in pairs(pickKeywords) do
                        if tname:find(kw) and val > score then score = val end
                    end
                    local pwr = tool:GetAttribute("Power") or tool:GetAttribute("Damage") or (tool:FindFirstChild("Power") and tool.Power.Value) or (tool:FindFirstChild("Damage") and tool.Damage.Value) or 0
                    score = score + (type(pwr) == "number" and pwr or 0) * 10
                    if score > highestScore then
                        highestScore = score
                        bestTool = tool
                    end
                end
            end
            if bestTool then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(bestTool) end
            end
        end
    end
end

local function autoRepairTools()
    if not HubState.Config.MiningModsEnabled then return end
    if not (HubState.Config.MiningModsList and HubState.Config.MiningModsList["Auto Repair"]) then return end
    pcall(function()
        local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }
        for _, cont in ipairs(containers) do
            if cont then
                for _, t in ipairs(cont:GetChildren()) do
                    if t:IsA("Tool") then
                        for _, a in ipairs({"Durability", "Health", "Condition", "MaxDurability", "MaxHealth"}) do
                            local maxVal = t:GetAttribute("Max" .. a) or 100
                            if t:GetAttribute(a) then t:SetAttribute(a, maxVal) end
                            local valObj = t:FindFirstChild(a)
                            if valObj and valObj:IsA("ValueBase") then valObj.Value = maxVal end
                        end
                    end
                end
            end
        end
    end)
end

-- 3.0.9. Ore Aura Engine (Active Auto-Mining in Radius)
task.spawn(function()
    while true do
        task.wait(0.2)
        if HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["Ore Aura"] then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local reach = HubState.Config.MineRange or 35
                local targetOre = getClosestOre(reach)
                if targetOre then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if not tool then
                        autoEquipBestTool()
                        tool = char:FindFirstChildOfClass("Tool")
                    end
                    if tool then tool:Activate() end

                    local powerMult = 1
                    if HubState.Config.InstantMine or (HubState.Config.MiningModsList and (HubState.Config.MiningModsList["Ranjau Instan"] or HubState.Config.MiningModsList["Instant Break"])) then
                        powerMult = 16
                    elseif HubState.Config.Power8x or (HubState.Config.MiningModsList and HubState.Config.MiningModsList["8x Kekuatan"]) then
                        powerMult = 8
                    elseif HubState.Config.FastMineHits and HubState.Config.FastMineHits > 1 then
                        powerMult = HubState.Config.FastMineHits
                    end

                    fireMiningHit(targetOre, powerMult)
                end
            end
        end
    end
end)

-- 3.1. Auto Mine & Instant Mine One-Click Controller
local function performInstantMineNow()
    local reach = HubState.Config.MineRange or 50
    local targetOre = getClosestOre(reach)
    if targetOre and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool then
            autoEquipBestTool()
            tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        end
        if tool then tool:Activate() end
        local powerMult = 24 -- Massive burst for 1-click destroy
        fireMiningHit(targetOre, powerMult)
        return true
    end
    return false
end
HubState.InstantMineClosest = performInstantMineNow

task.spawn(function()
    while true do
        local isFast = HubState.Config.FastMine or (HubState.Config.MiningModsEnabled and (HubState.Config.MiningModsList and (HubState.Config.MiningModsList["Fast Swing"] or HubState.Config.MiningPreset == "Blatant")))
        local delay = isFast and 0.05 or 0.10
        if HubState.Config.FastDig2x or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and HubState.Config.MiningModsList["2x Penggalian Cepat"]) then
            delay = delay * 0.5
        end
        task.wait(delay)
        if HubState.Config.AutoMine and LocalPlayer.Character then
            autoEquipBestTool()
            autoRepairTools()
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
            local reach = HubState.Config.MineRange or 35
            local targetOre = getClosestOre(reach)
            if targetOre then
                pcall(function()
                    if LocalPlayer:FindFirstChild("PlayerGui") then
                        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                            if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                                local gn = gui.Name:lower()
                                if gn:find("mine") or gn:find("gali") or gn:find("dig") or gn:find("swing") or gn:find("attack") then
                                    if gui.Visible and firesignal then firesignal(gui.Activated) end
                                end
                            end
                        end
                    end
                end)

                local powerMult = (HubState.Config.Power8x or HubState.Config.InstantMine or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList and (HubState.Config.MiningModsList["8x Kekuatan"] or HubState.Config.MiningModsList["Ranjau Instan"]))) and 16 or 2
                fireMiningHit(targetOre, powerMult)
            end
        end
    end
end)

-- 3.5. Player Mods Engine Loop (Speed, Jump, Freeze, Jetpack, Fall, Ragdoll)
task.spawn(function()
    while true do
        task.wait(0.2)
        local isPlayerModsOn = HubState.Config.PlayerModsEnabled
        local pList = HubState.Config.PlayerModsList or {}
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                if isPlayerModsOn and pList["Speed"] then
                    local s = HubState.Config.WalkSpeed or 32
                    if hum.WalkSpeed ~= s then hum.WalkSpeed = s end
                elseif not isPlayerModsOn or not pList["Speed"] then
                    if hum.WalkSpeed > 16 and not HubState.Config.Fly then
                        hum.WalkSpeed = 16
                    end
                end

                if isPlayerModsOn and pList["Jump Boost"] then
                    local j = HubState.Config.JumpPower or 70
                    if hum.JumpPower ~= j then hum.JumpPower = j end
                elseif not isPlayerModsOn or not pList["Jump Boost"] then
                    if hum.JumpPower > 50 then
                        hum.JumpPower = 50
                    end
                end
            end

            if isPlayerModsOn then
                if pList["Anti Freeze"] then HubState.Config.AntiFreeze = true end
                if pList["Infinite Jetpack"] then HubState.Config.InfiniteJetpack = true end
                if pList["No Fall Damage"] then HubState.Config.NoFallDamage = true end
                if pList["Anti Ragdoll"] then HubState.Config.AntiRagdoll = true end
                if pList["Noclip"] then HubState.Config.Noclip = true end
                if pList["Fly"] then HubState.Config.Fly = true end
            end
        end
    end
end)

-- 3.6. Teleport Collect Engine Loop (Semua Rarity & Safe Drop Check)
task.spawn(function()
    while true do
        task.wait(0.6)
        if HubState.Config.TeleportCollectEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local maxRange = (HubState.Config.CollectRange or 300) * 1.5
            local searchDirs = {
                workspace:FindFirstChild("Drops"),
                workspace:FindFirstChild("Debris"),
                workspace:FindFirstChild("SpawnedItems"),
                workspace:FindFirstChild("Collectibles"),
                workspace:FindFirstChild("Pickups"),
                workspace:FindFirstChild("Items"),
                workspace:FindFirstChild("Candy"),
                workspace:FindFirstChild("Permen"),
                workspace:FindFirstChild("Runes"),
                workspace:FindFirstChild("Coins"),
                workspace:FindFirstChild("Gems"),
                workspace:FindFirstChild("Shards"),
                workspace
            }

            local dropKeywords = {"crystal", "kristal", "drop", "shard", "rune", "meteor", "coin", "candy", "permen", "gem", "loot", "present"}
            for _, folder in ipairs(searchDirs) do
                if folder then
                    local items = (folder == workspace) and folder:GetChildren() or folder:GetDescendants()
                    for _, item in ipairs(items) do
                        local iname = item.Name:lower()
                        local isDrop = false
                        if folder ~= workspace and (folder.Name:lower():find("drop") or folder.Name:lower():find("debris") or folder.Name:lower():find("spawn") or folder.Name:lower():find("collect") or folder.Name:lower():find("pickup") or folder.Name:lower():find("item")) then
                            isDrop = true
                        else
                            for _, kw in ipairs(dropKeywords) do
                                if iname:find(kw) then isDrop = true break end
                            end
                            if not isDrop then
                                for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                                    if iname:find(rk) then isDrop = true break end
                                end
                            end
                        end

                        if isDrop and isRealLootDrop(item) then
                            local part = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")))
                            if part then
                                local dist = (part.Position - myRoot.Position).Magnitude
                                if dist <= maxRange and dist > 8 then
                                    local oldCF = myRoot.CFrame
                                    myRoot.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                                    task.wait(0.08)
                                    pcall(function()
                                        firetouchinterest(myRoot, part, 0)
                                        firetouchinterest(myRoot, part, 1)
                                        if HubState.Config.Crystal2x or HubState.Config.Crystals2x then
                                            firetouchinterest(myRoot, part, 0)
                                            firetouchinterest(myRoot, part, 1)
                                        end
                                    end)
                                    local prompt = item:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt and fireproximityprompt then fireproximityprompt(prompt, 0) end
                                    task.wait(0.05)
                                    myRoot.CFrame = oldCF
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Auto Collect (Full-Spectrum Semua Rarity: Zenith hingga Common, Drops, Permen, Runes, Coins & Chests)
-- Validator Drop Nyata: Memisahkan Loot Lepas dari Gunung / Bijih Tambang
local function isRealLootDrop(item)
    if not item or not item.Parent then return false end

    local iname = item.Name:lower()
    local parentName = item.Parent.Name:lower()

    -- 1. PENGECUALIAN MUTLAK: Model gunung atau chunk terrain besar
    if iname:find("mountain") or iname:find("gunung") or iname:find("chunk") then
        return false
    end

    -- 2. Cek ProximityPrompt: Jika aksi bertuliskan "Mine", "Gali", "Break", "Hancurkan", maka ini adalah BATU GUNUNG, BUKAN DROP!
    local prompt = item:FindFirstChildOfClass("ProximityPrompt") or (item:IsA("BasePart") and item:FindFirstChildOfClass("ProximityPrompt")) or (item:IsA("Model") and item:FindFirstChildWhichIsA("ProximityPrompt", true))
    if prompt then
        local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
        if pText:find("mine") or pText:find("gali") or pText:find("break") or pText:find("hancur") then
            return false
        end
    end

    -- 3. Objek di dalam folder Drop/Loot resmi game (Pasti drop nyata)
    if parentName:find("drop") or parentName:find("debris") or parentName:find("spawn") or parentName:find("collect") or parentName:find("loot") or parentName:find("pickup") or parentName:find("item") then
        return true
    end

    -- 4. Jika parent-nya adalah folder batuan/gunung tidak bergerak (Map, Terrain, Chunks), jangan diambil sebagai drop
    if parentName:find("map") or parentName:find("terrain") then
        return false
    end

    -- 5. Part kecil di tanah hasil tambang yang jatuh (unanchored atau ukuran kecil <= 7 studs)
    if item:IsA("BasePart") then
        if not item.Anchored or (item.Size.X <= 7 and item.Size.Y <= 7 and item.Size.Z <= 7) then
            return true
        end
    elseif item:IsA("Model") then
        local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if pp and (not pp.Anchored or (pp.Size.X <= 7 and pp.Size.Y <= 7 and pp.Size.Z <= 7)) then
            return true
        end
    end

    return false
end

local function performAutoCollectNow()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local maxRange = HubState.Config.CollectRange or 300

    local searchDirs = {
        workspace:FindFirstChild("Drops"),
        workspace:FindFirstChild("Debris"),
        workspace:FindFirstChild("SpawnedItems"),
        workspace:FindFirstChild("Collectibles"),
        workspace:FindFirstChild("Pickups"),
        workspace:FindFirstChild("Items"),
        workspace:FindFirstChild("Candy"),
        workspace:FindFirstChild("Permen"),
        workspace:FindFirstChild("Runes"),
        workspace:FindFirstChild("Coins"),
        workspace:FindFirstChild("Gems"),
        workspace:FindFirstChild("Shards"),
        workspace
    }
    local dropKeywords = {"crystal", "kristal", "drop", "shard", "rune", "meteor", "coin", "candy", "permen", "gem", "loot", "present"}

    for _, folder in ipairs(searchDirs) do
        if folder then
            local items = (folder == workspace) and folder:GetChildren() or folder:GetDescendants()
            for _, item in ipairs(items) do
                local iname = item.Name:lower()
                local isDrop = false
                if folder ~= workspace and (folder.Name:lower():find("drop") or folder.Name:lower():find("debris") or folder.Name:lower():find("spawn") or folder.Name:lower():find("collect") or folder.Name:lower():find("pickup") or folder.Name:lower():find("item")) then
                    isDrop = true
                else
                    for _, kw in ipairs(dropKeywords) do
                        if iname:find(kw) then isDrop = true break end
                    end
                    if not isDrop then
                        for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                            if iname:find(rk) then isDrop = true break end
                        end
                    end
                end

                if isDrop and isRealLootDrop(item) then
                    local part = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart"))) or (item:IsA("Tool") and item:FindFirstChild("Handle"))
                    if part then
                        local dist = (part.Position - myRoot.Position).Magnitude
                        if dist <= maxRange then
                            pcall(function()
                                firetouchinterest(myRoot, part, 0)
                                firetouchinterest(myRoot, part, 1)
                                if HubState.Config.Crystal2x or HubState.Config.Crystals2x then
                                    firetouchinterest(myRoot, part, 0)
                                    firetouchinterest(myRoot, part, 1)
                                end
                            end)
                            local prompt = item:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and fireproximityprompt then
                                local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
                                if not (pText:find("mine") or pText:find("gali") or pText:find("break")) then
                                    prompt.HoldDuration = 0
                                    fireproximityprompt(prompt, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    scanAndCacheRemotes()
    for _, rem in ipairs(cachedCollectRemotes) do
        if rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer() end)
        end
    end
end
HubState.CollectEverythingNow = performAutoCollectNow

task.spawn(function()
    while true do
        task.wait(0.18)
        if HubState.Config.AutoCollect and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local maxRange = HubState.Config.CollectRange or 300

            local searchDirs = {
                workspace:FindFirstChild("Drops"),
                workspace:FindFirstChild("Debris"),
                workspace:FindFirstChild("SpawnedItems"),
                workspace:FindFirstChild("Collectibles"),
                workspace:FindFirstChild("Pickups"),
                workspace:FindFirstChild("Items"),
                workspace:FindFirstChild("Candy"),
                workspace:FindFirstChild("Permen"),
                workspace:FindFirstChild("Runes"),
                workspace:FindFirstChild("Coins"),
                workspace:FindFirstChild("Gems"),
                workspace:FindFirstChild("Shards"),
                workspace
            }

            local dropKeywords = {"crystal", "kristal", "drop", "shard", "rune", "meteor", "coin", "candy", "permen", "gem", "loot", "present"}

            for _, folder in ipairs(searchDirs) do
                if folder then
                    local items = (folder == workspace) and folder:GetChildren() or folder:GetDescendants()
                    for _, item in ipairs(items) do
                        local iname = item.Name:lower()
                        local isDrop = false

                        local tg = HubState.Config.CollectTargets
                        if tg then
                            if tg["Semua Rarity (All)"] or tg["All Rarities"] then
                                isDrop = true
                            end
                            if tg["Crystals"] and (iname:find("crystal") or iname:find("kristal") or iname:find("gem")) then isDrop = true end
                            if tg["Coins"] and iname:find("coin") then isDrop = true end
                            if tg["Candy / Permen"] and (iname:find("candy") or iname:find("permen")) then isDrop = true end
                            if tg["Runes"] and iname:find("rune") then isDrop = true end
                            if tg["Meteors"] and iname:find("meteor") then isDrop = true end
                            if tg["Shards"] and iname:find("shard") then isDrop = true end
                            if tg["Chests / Crates"] and (iname:find("chest") or iname:find("crate") or iname:find("box")) then isDrop = true end
                            if tg["Ores"] and iname:find("ore") then isDrop = true end
                            if tg["Boulders"] and iname:find("boulder") then isDrop = true end
                        end

                        if not isDrop then
                            local preset = HubState.Config.AutoCollectPreset or "Everything"
                            if preset == "Crystals Only" then
                                if iname:find("crystal") or iname:find("gem") or iname:find("shard") then isDrop = true end
                                for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                                    if iname:find(rk) then isDrop = true break end
                                end
                            elseif preset == "Coins Only" then
                                if iname:find("coin") or iname:find("permen") or iname:find("candy") then isDrop = true end
                            elseif preset == "Runes Only" then
                                if iname:find("rune") then isDrop = true end
                            else
                                if folder ~= workspace and (folder.Name:lower():find("drop") or folder.Name:lower():find("debris") or folder.Name:lower():find("spawn") or folder.Name:lower():find("collect") or folder.Name:lower():find("pickup") or folder.Name:lower():find("item")) then
                                    isDrop = true
                                else
                                    for _, kw in ipairs(dropKeywords) do
                                        if iname:find(kw) then isDrop = true break end
                                    end
                                    if not isDrop then
                                        for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                                            if iname:find(rk) then isDrop = true break end
                                        end
                                    end
                                end
                            end
                        end

                        if isDrop and isRealLootDrop(item) then
                            local part = item:IsA("BasePart") and item or (item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart"))) or (item:IsA("Tool") and item:FindFirstChild("Handle"))
                            if part then
                                local dist = (part.Position - myRoot.Position).Magnitude
                                if dist <= maxRange then
                                    pcall(function()
                                        firetouchinterest(myRoot, part, 0)
                                        firetouchinterest(myRoot, part, 1)
                                        if HubState.Config.Crystal2x or HubState.Config.Crystals2x then
                                            firetouchinterest(myRoot, part, 0)
                                            firetouchinterest(myRoot, part, 1)
                                        end
                                    end)
                                    local prompt = item:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt and fireproximityprompt then
                                        local pText = (prompt.ActionText .. " " .. prompt.ObjectText):lower()
                                        if not (pText:find("mine") or pText:find("gali") or pText:find("break")) then
                                            prompt.HoldDuration = 0
                                            fireproximityprompt(prompt, 0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            scanAndCacheRemotes()
            for _, rem in ipairs(cachedCollectRemotes) do
                if rem:IsA("RemoteEvent") then
                    pcall(function() rem:FireServer() end)
                end
            end
        end
    end
end)

-- 5. Auto Sell (Jual Hasil Tambang)
local function performAutoSellNow()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Cari Toko / Merchant di Base Camp
    local merchantObj = nil
    local searchMerchantNames = {"merchant", "toko", "shop", "seller", "vendor", "sell", "pedagang", "pangkalan", "basecamp"}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local oname = obj.Name:lower()
            for _, sm in ipairs(searchMerchantNames) do
                if oname:find(sm) then
                    merchantObj = obj
                    break
                end
            end
        end
        if merchantObj then break end
    end

    if merchantObj and (HubState.Config.SellTarget == "Teleport Jual & Balik" or HubState.Config.AutoSellPreset == "Teleport Jual & Balik") then
        local savedPos = myRoot.CFrame
        local targetPos = merchantObj:IsA("Model") and (merchantObj.PrimaryPart and merchantObj.PrimaryPart.CFrame or merchantObj:GetPivot()) or merchantObj.CFrame
        myRoot.CFrame = targetPos + Vector3.new(0, 3, 0)
        task.wait(0.2)

        for _, p in ipairs(merchantObj:GetDescendants()) do
            if p:IsA("ProximityPrompt") and fireproximityprompt then
                p.HoldDuration = 0
                fireproximityprompt(p, 0)
            end
        end
        scanAndCacheRemotes()
        for _, rem in ipairs(cachedSellRemotes) do
            if rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer() end)
            end
        end
        task.wait(0.15)
        myRoot.CFrame = savedPos
    else
        scanAndCacheRemotes()
        for _, rem in ipairs(cachedSellRemotes) do
            if rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer() end)
            end
        end
    end
end
HubState.SellAllItemsNow = performAutoSellNow

local function isBagFull()
    local cap = LocalPlayer:GetAttribute("MaxCapacity") or LocalPlayer:GetAttribute("Capacity") or LocalPlayer:GetAttribute("MaxWeight")
    local cur = LocalPlayer:GetAttribute("CurrentWeight") or LocalPlayer:GetAttribute("Weight") or LocalPlayer:GetAttribute("BagWeight")
    local ls = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Data")
    if ls then
        local bagVal = ls:FindFirstChild("Bag") or ls:FindFirstChild("Weight") or ls:FindFirstChild("Current")
        local maxVal = ls:FindFirstChild("MaxBag") or ls:FindFirstChild("Capacity") or ls:FindFirstChild("MaxWeight")
        if bagVal and maxVal and type(bagVal.Value) == "number" and type(maxVal.Value) == "number" then
            return bagVal.Value >= maxVal.Value
        end
    end
    if cap and cur and type(cap) == "number" and type(cur) == "number" then
        return cur >= cap
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(2.5)
        if HubState.Config.AutoSell or (HubState.Config.AutoSellPreset == "Auto Bag Full" and isBagFull()) then
            performAutoSellNow()
        end
    end
end)

-- 6. Auto Garden / Crystal Farm (Mine Antarctica Spesifik: Best, Rarity, Luck, Mutation, Value, Weight)
local function getPlayerGardenPlot()
    local char = LocalPlayer.Character
    local searchGardenDirs = {
        workspace:FindFirstChild("CrystalGarden"),
        workspace:FindFirstChild("Crystal Garden"),
        workspace:FindFirstChild("CrystalFarm"),
        workspace:FindFirstChild("Crystal Farm"),
        workspace:FindFirstChild("CrystalPlots"),
        workspace:FindFirstChild("Crystal Plots"),
        workspace:FindFirstChild("CrystalBeds"),
        workspace:FindFirstChild("Garden"),
        workspace:FindFirstChild("Gardens"),
        workspace:FindFirstChild("Farms"),
        workspace:FindFirstChild("Plots"),
        workspace:FindFirstChild("Kebun"),
        workspace:FindFirstChild("BaseCamp"),
        workspace:FindFirstChild("Pangkalan"),
        workspace
    }

    local myPlot = nil
    for _, folder in ipairs(searchGardenDirs) do
        if folder then
            local children = (folder == workspace) and folder:GetChildren() or folder:GetDescendants()
            for _, obj in ipairs(children) do
                local oname = obj.Name:lower()
                if oname:find("garden") or oname:find("kebun") or oname:find("plot") or oname:find("farm") or oname:find("bed") then
                    -- Periksa apakah ini plot milik LocalPlayer
                    local ownerVal = obj:FindFirstChild("Owner") or obj:FindFirstChild("Player") or obj:FindFirstChild("UserId")
                    if ownerVal and (tostring(ownerVal.Value) == LocalPlayer.Name or tostring(ownerVal.Value) == tostring(LocalPlayer.UserId)) then
                        return obj
                    end
                    local attrOwner = obj:GetAttribute("Owner") or obj:GetAttribute("UserId")
                    if attrOwner and (tostring(attrOwner) == LocalPlayer.Name or tostring(attrOwner) == tostring(LocalPlayer.UserId)) then
                        return obj
                    end
                    if oname:find(LocalPlayer.Name:lower()) then
                        return obj
                    end
                    if not myPlot and (obj:FindFirstChildOfClass("TouchTransmitter") or obj:FindFirstChildOfClass("ProximityPrompt")) then
                        myPlot = obj
                    end
                end
            end
        end
    end
    return myPlot
end

local function buyGardenSpace()
    scanAndCacheRemotes()
    for _, rem in ipairs(cachedGardenRemotes) do
        pcall(function()
            if rem:IsA("RemoteEvent") then rem:FireServer("BuySpace") else rem:InvokeServer("BuySpace") end
        end)
    end
    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local gn = gui.Name:lower()
                    if (gn:find("garden") or gn:find("kebun")) and (gn:find("buy") or gn:find("slot") or gn:find("space") or gn:find("expand")) then
                        if firesignal then firesignal(gui.Activated) end
                    end
                end
            end
        end
    end)
end
HubState.BuyGardenSpace = buyGardenSpace

local function getBestGardenCrystal(sortMode)
    sortMode = sortMode or HubState.Config.AutoGardenPreset or "Best"
    local crystals = {}
    local containers = {LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}

    local rarityScores = {
        zenith = 100000,
        transcendent = 60000,
        celestial = 40000,
        divine = 30000,
        godly = 25000,
        secret = 20000,
        exotic = 15000,
        mythic = 10000,
        legendary = 5000,
        epic = 2500,
        rare = 1200,
        uncommon = 500,
        common = 100
    }

    local mutationKeywords = {
        "aurora", "blood moon", "blood", "frozen", "radiant", "gilded",
        "void", "cosmic", "shadow", "mutation", "mutated", "shiny", "spectral",
        "corrupted", "rainbow", "electric", "nebula", "abyssal"
    }

    local ignoredKeywords = {
        "pickaxe", "beliung", "axe", "radar", "bomb", "dynamite", "dinamit",
        "potion", "jetpack", "backpack", "ransel", "compass", "lamp"
    }

    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                local iname = item.Name:lower()

                -- Pastikan bukan utility tools/pickaxe
                local isIgnored = false
                for _, ign in ipairs(ignoredKeywords) do
                    if iname:find(ign) then
                        isIgnored = true
                        break
                    end
                end

                if not isIgnored then
                    local isCrystal = false
                    local rarityScore = 0

                    -- Cek atribut dan ValueBase untuk tier Rarity sesungguhnya
                    pcall(function()
                        local attrRarity = item:GetAttribute("Rarity") or item:GetAttribute("Tier") or item:GetAttribute("Kelangkaan")
                        if attrRarity and type(attrRarity) == "string" then
                            local an = attrRarity:lower()
                            for rk, rv in pairs(rarityScores) do
                                if an:find(rk) then
                                    isCrystal = true
                                    if rv > rarityScore then rarityScore = rv end
                                end
                            end
                        end
                        local valRarity = item:FindFirstChild("Rarity") or item:FindFirstChild("Tier")
                        if valRarity and valRarity:IsA("ValueBase") and type(valRarity.Value) == "string" then
                            local vn = valRarity.Value:lower()
                            for rk, rv in pairs(rarityScores) do
                                if vn:find(rk) then
                                    isCrystal = true
                                    if rv > rarityScore then rarityScore = rv end
                                end
                            end
                        end
                    end)

                    for rk, rv in pairs(rarityScores) do
                        if iname:find(rk) then
                            isCrystal = true
                            if rv > rarityScore then
                                rarityScore = rv
                            end
                        end
                    end

                    if iname:find("crystal") or iname:find("kristal") or iname:find("shard") or iname:find("gem")
                       or iname:find("ore") or iname:find("emerald") or iname:find("ruby") or iname:find("sapphire")
                       or iname:find("diamond") or iname:find("berlian") or iname:find("obsidian")
                       or iname:find("topaz") or iname:find("amethyst") then
                        isCrystal = true
                        rarityScore = rarityScore + 200
                    end

                    if isCrystal then
                        local luckBonus = 0
                        if iname:find("luck") or iname:find("fortune") or iname:find("hoki") or iname:find("keberuntungan") then
                            luckBonus = 800
                        end
                        pcall(function()
                            local luckVal = item:GetAttribute("Luck") or item:GetAttribute("LuckMultiplier")
                                          or (item:FindFirstChild("Luck") and item.Luck.Value)
                                          or (item:FindFirstChild("Multiplier") and item.Multiplier.Value)
                            if type(luckVal) == "number" then
                                luckBonus = luckBonus + math.floor(luckVal * 100)
                            end
                        end)

                        local mutationBonus = 0
                        for _, mut in ipairs(mutationKeywords) do
                            if iname:find(mut) then
                                mutationBonus = mutationBonus + 25000
                                break
                            end
                        end
                        pcall(function()
                            if item:GetAttribute("Mutation") or item:GetAttribute("IsMutated") or item:FindFirstChild("Mutation") then
                                mutationBonus = mutationBonus + 25000
                            end
                        end)

                        local valueScore = 100
                        pcall(function()
                            local val = item:GetAttribute("Value") or item:GetAttribute("Price") or (item:FindFirstChild("Value") and item.Value.Value)
                            if type(val) == "number" then valueScore = val end
                        end)

                        local weightScore = 10
                        pcall(function()
                            local w = item:GetAttribute("Weight") or item:GetAttribute("Berat") or (item:FindFirstChild("Weight") and item.Weight.Value)
                            if type(w) == "number" then weightScore = w end
                        end)

                        -- Hitung skor berdasarkan mode sortir Mine Antarctica (Barrage Hub Specification)
                        local finalScore = 0
                        if sortMode == "Rarity" then
                            finalScore = rarityScore * 10 + luckBonus
                        elseif sortMode == "Luck" then
                            finalScore = luckBonus * 100 + rarityScore
                        elseif sortMode == "Mutation" then
                            finalScore = mutationBonus * 10 + rarityScore + luckBonus
                        elseif sortMode == "Value" then
                            finalScore = valueScore + (rarityScore * 2)
                        elseif sortMode == "Weight" then
                            finalScore = weightScore * 100 + rarityScore
                        else -- "Best" (Default: Rarity > Mutation > Luck > Value)
                            finalScore = rarityScore + mutationBonus + luckBonus + (valueScore / 100)
                        end

                        table.insert(crystals, {item = item, score = finalScore, name = item.Name})
                    end
                end
            end
        end
    end

    table.sort(crystals, function(a, b) return a.score > b.score end)
    return crystals[1] and crystals[1].item or nil
end
local getBestGardenSeed = getBestGardenCrystal

local function performAutoGarden(action)
    action = action or "all"
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = LocalPlayer.Character.HumanoidRootPart
    local bestCrystal = getBestGardenCrystal(HubState.Config.AutoGardenPreset)
    local plot = getPlayerGardenPlot()

    -- Pola Teleport CFrame: Kebun berada di Base Camp (Pangkalan), simpan koordinat gunung
    local savedPos = nil
    if plot then
        local plotPos = plot:IsA("Model") and (plot.PrimaryPart and plot.PrimaryPart.Position or plot:GetPivot().Position) or plot.Position
        if (plotPos - myRoot.Position).Magnitude > 60 then
            savedPos = myRoot.CFrame
            myRoot.CFrame = CFrame.new(plotPos + Vector3.new(0, 3.5, 0))
            task.wait(0.25) -- Replikasi posisi karakter di kebun kepada server
        end
    end

    -- 1. Beli Ruang Kebun jika tindakan mengizinkan (Mine Antarctica Garden Space Expansion)
    if action == "all" or action == "buyspace" or HubState.Config.GardenAction == "Buy Space, Fill Best" or HubState.Config.GardenAction == "Buy Garden Space Only" then
        buyGardenSpace()
        if action == "buyspace" or HubState.Config.GardenAction == "Buy Garden Space Only" then
            if savedPos then myRoot.CFrame = savedPos end
            return
        end
    end

    -- Auto equip kristal terbaik saat aksi penanaman
    if (action == "all" or action == "plant") and bestCrystal and bestCrystal:IsA("Tool") and bestCrystal.Parent == LocalPlayer.Backpack then
        pcall(function()
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(bestCrystal) end
        end)
    end

    -- 2. Pemicu ProximityPrompt & ClickDetector pada Petak Kebun
    if plot then
        for _, p in ipairs(plot:GetDescendants()) do
            if p:IsA("ProximityPrompt") and fireproximityprompt then
                p.HoldDuration = 0
                fireproximityprompt(p, 0)
            end
            if p:IsA("ClickDetector") and fireclickdetector then
                fireclickdetector(p)
            end
            if p:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(myRoot, p, 0)
                    firetouchinterest(myRoot, p, 1)
                    if bestCrystal and bestCrystal:FindFirstChild("Handle") then
                        firetouchinterest(bestCrystal.Handle, p, 0)
                        firetouchinterest(bestCrystal.Handle, p, 1)
                    end
                end)
            end
        end
    end

    -- 3. Panggil RemoteEvent Garden Secara Terarah & Aman (Anti-Ratelimit)
    scanAndCacheRemotes()
    for _, rem in ipairs(cachedGardenRemotes) do
        pcall(function()
            if rem:IsA("RemoteEvent") then
                if (action == "all" or action == "plant") and bestCrystal then
                    rem:FireServer("Plant", bestCrystal)
                end
                if (action == "all" or action == "harvest") then
                    rem:FireServer("Harvest")
                end
            elseif rem:IsA("RemoteFunction") then
                if (action == "all" or action == "plant") and bestCrystal then
                    rem:InvokeServer("Plant", bestCrystal)
                end
                if (action == "all" or action == "harvest") then
                    rem:InvokeServer("Harvest")
                end
            end
        end)
    end

    -- 4. Pemicu Tombol Garden GUI di PlayerGui
    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local gn = gui.Name:lower()
                    if gn:find("garden") or gn:find("kebun") or gn:find("harvest") or gn:find("panen") or gn:find("plant") or gn:find("tanam") or gn:find("deposit") then
                        if firesignal then firesignal(gui.Activated) end
                    end
                end
            end
        end
    end)

    task.wait(0.2)
    -- Kembalikan karakter ke posisi gunung tempat menambang sebelumnya
    if savedPos and myRoot and myRoot.Parent then
        myRoot.CFrame = savedPos
    end
end
HubState.PerformGarden = performAutoGarden

task.spawn(function()
    while true do
        task.wait(1.8)
        if HubState.Config.AutoGarden then
            performAutoGarden("all")
        end
    end
end)

-- 7. Auto Runes & Rune Altar (Zero-Lag Cached Scanner)
task.spawn(function()
    while true do
        task.wait(3)
        if HubState.Config.AutoRunes then
            scanAndCacheRemotes()
            for _, rem in ipairs(cachedRuneRemotes) do
                pcall(function()
                    if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                end)
            end
        end
    end
end)

-- 8. Auto Upgrade (Pickaxes, Capacity, Warmth)
task.spawn(function()
    while true do
        task.wait(5)
        if HubState.Config.AutoUpgrade then
            scanAndCacheRemotes()
            for _, rem in ipairs(cachedUpgradeRemotes) do
                pcall(function()
                    if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                end)
            end
        end
    end
end)

-- 9. Auto Items (Auto Gunakan Radar, Beli Bom, Buka Chests)
task.spawn(function()
    while true do
        task.wait(3.5)
        if HubState.Config.AutoItems and LocalPlayer.Character then
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                -- 1. Auto Aktifkan Radar di Hotbar (Slot 2-5: Radar Batu Besar, Radar Kristal 99x, Radar Meteor)
                local containers = {LocalPlayer.Character, backpack}
                for _, cont in ipairs(containers) do
                    if cont then
                        for _, tool in ipairs(cont:GetChildren()) do
                            if tool:IsA("Tool") and tool.Name:lower():find("radar") then
                                if cont == backpack and hum then
                                    hum:EquipTool(tool)
                                    task.wait(0.1)
                                end
                                tool:Activate()
                                for _, rem in ipairs(tool:GetDescendants()) do
                                    if rem:IsA("RemoteEvent") then rem:FireServer() end
                                end
                            end
                        end
                    end
                end
            end)

            -- 2. Beli perlengkapan utility & buka chest via cached item remotes
            scanAndCacheRemotes()
            for _, rem in ipairs(cachedItemRemotes) do
                pcall(function()
                    if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                end)
            end
        end
    end
end)

-- 10. Auto Claim Rewards & Daily Gifts
task.spawn(function()
    while true do
        task.wait(6)
        if HubState.Config.AutoClaimRewards then
            scanAndCacheRemotes()
            for _, rem in ipairs(cachedRewardRemotes) do
                pcall(function()
                    if rem:IsA("RemoteEvent") then rem:FireServer() else rem:InvokeServer() end
                end)
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
                scanAndCacheRemotes()
                local targetPos = ore:IsA("Model") and ore:GetPivot().Position or ore.Position
                for _, rem in ipairs(cachedBombRemotes) do
                    if rem:IsA("RemoteEvent") then
                        pcall(function() rem:FireServer(targetPos) end)
                    end
                end
            end
        end
    end
end)

-- 12. Player Mods: Infinite Jetpack & Anti-Freeze (Warmth Lock)
Services.RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character then return end
    if HubState.Config.InfiniteJetpack or (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList["Infinite Jetpack"]) then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("fuel") or v.Name:lower():find("jetpack")) then
                v.Value = 100
            end
        end
    end
    if HubState.Config.AntiFreeze or (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList["Anti Freeze"]) then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("warmth") or v.Name:lower():find("temp") or v.Name:lower():find("cold")) then
                v.Value = 100
            end
        end
        pcall(function()
            LocalPlayer:SetAttribute("Warmth", 100)
            LocalPlayer:SetAttribute("Temperature", 100)
            LocalPlayer:SetAttribute("Freeze", 0)
        end)
    end
end)

-- 13. Player Mods: Anti-Ragdoll & No Fall Damage (Deep Enforcer)
local function hookAntiRagdoll(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 3)
    if not hum then return end
    hum.StateChanged:Connect(function(oldState, newState)
        if HubState.Config.AntiRagdoll or (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList["Anti Ragdoll"]) or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList["Anti Ragdoll"]) then
            if newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.PlatformStanding then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)
end

if LocalPlayer.Character then hookAntiRagdoll(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookAntiRagdoll)

Services.RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local isAntiRagdoll = HubState.Config.AntiRagdoll or (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList["Anti Ragdoll"]) or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList["Anti Ragdoll"])
            if isAntiRagdoll then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
                if hum.PlatformStand then hum.PlatformStand = false end
                if hum.Sit then hum.Sit = false end

                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("Script") or child:IsA("LocalScript") then
                        local cn = child.Name:lower()
                        if cn:find("ragdoll") or cn:find("fall") or cn:find("knockback") or cn:find("trip") or cn:find("stun") or cn:find("slip") then
                            pcall(function() child.Disabled = true end)
                        end
                    end
                end
            end

            -- No Fall Damage (Klem Kecepatan Jatuh Sebelum Menyentuh Tanah)
            local isNoFall = HubState.Config.NoFallDamage or (HubState.Config.PlayerModsEnabled and HubState.Config.PlayerModsList["No Fall Damage"]) or (HubState.Config.MiningModsEnabled and HubState.Config.MiningModsList["Tidak Ada Kerusakan Jatuh"])
            if isNoFall and root then
                local vel = root.AssemblyLinearVelocity
                if vel.Y < -30 then
                    root.AssemblyLinearVelocity = Vector3.new(vel.X, -30, vel.Z)
                end
                if root.Velocity.Y < -30 then
                    root.Velocity = Vector3.new(root.Velocity.X, -30, root.Velocity.Z)
                end
            end
        end
    end
end)

-- 14. Crystal & Boulder ESP (Live Background Loop + Billboard Text)
local crystalEspHighlights = {}
local crystalEspBillboards = {}

local function clearCrystalESP()
    for _, h in pairs(crystalEspHighlights) do
        if h and h.Parent then pcall(function() h:Destroy() end) end
    end
    for _, b in pairs(crystalEspBillboards) do
        if b and b.Parent then pcall(function() b:Destroy() end) end
    end
    crystalEspHighlights = {}
    crystalEspBillboards = {}
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if HubState.Config.CrystalEsp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local validObjs = {}
            local maxEspRange = HubState.Config.EspRange or 1000

            local searchList = {
                workspace:FindFirstChild("Ores"),
                workspace:FindFirstChild("Boulders"),
                workspace:FindFirstChild("Crystals"),
                workspace:FindFirstChild("Nodes"),
                workspace:FindFirstChild("Drops"),
                workspace:FindFirstChild("Spawned"),
                workspace:FindFirstChild("SpawnedOres"),
                workspace:FindFirstChild("Map"),
                workspace:FindFirstChild("Debris"),
                workspace:FindFirstChild("Terrain"),
                workspace
            }

            local seen = {}
            for _, folder in ipairs(searchList) do
                if folder then
                    local children = (folder == workspace) and folder:GetChildren() or folder:GetDescendants()
                    for _, obj in ipairs(children) do
                        if not seen[obj] then
                            local isModel = obj:IsA("Model")
                            local isPart = obj:IsA("BasePart")
                            if isModel or isPart then
                                local name = obj.Name:lower()
                                local isMatch = false

                                if folder ~= workspace and (folder.Name == "Ores" or folder.Name == "Boulders" or folder.Name == "Crystals" or folder.Name == "Nodes" or folder.Name == "Drops") then
                                    isMatch = true
                                elseif name:find("crystal") or name:find("kristal") or name:find("boulder") or name:find("ore") or name:find("meteor") or name:find("rock") or name:find("deposit") or name:find("node") or name:find("stone") or name:find("shard") then
                                    isMatch = true
                                elseif obj:FindFirstChildOfClass("ProximityPrompt") or (isModel and obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then
                                    isMatch = true
                                else
                                    for _, rk in ipairs(ORDERED_RARITY_KEYS) do
                                        if name:find(rk) then
                                            isMatch = true
                                            break
                                        end
                                    end
                                end

                                if isMatch then
                                    local part = isPart and obj or (isModel and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                                    if part then
                                        local dist = (part.Position - myRoot.Position).Magnitude
                                        if dist < maxEspRange then
                                            seen[obj] = true
                                            local rScore, rLabel, rColor = getObjectRarity(obj)

                                            local allowed = true
                                            if HubState.Config.EspRarities and HubState.Config.EspRarities[rLabel] == false then
                                                allowed = false
                                            end

                                            if allowed then
                                                table.insert(validObjs, {obj = obj, part = part, name = obj.Name, dist = math.floor(dist), label = rLabel, color = rColor, score = rScore})
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- KUNCI UTAMA: Urutkan berdasarkan JARAK TERDEKAT (dist)!
            -- Menjamin SEMUA kelangkaan (Common, Uncommon, Rare, Epic, Legendary, Mythic, Exotic, Godly, Zenith)
            -- 100% muncul di layar pemain tanpa diskriminasi Rarity!
            table.sort(validObjs, function(a, b)
                return a.dist < b.dist
            end)

            local currentSet = {}
            local maxRenderCount = math.min(#validObjs, 120)

            for i = 1, maxRenderCount do
                local data = validObjs[i]
                currentSet[data.obj] = true

                -- 1. Highlight (Chams) - Dibatasi 25 kristal terdekat agar patuh batas internal 31 Highlight Roblox
                if i <= 25 then
                    if not crystalEspHighlights[data.obj] or not crystalEspHighlights[data.obj].Parent then
                        local h = Instance.new("Highlight")
                        h.Name = "AGY_CrystalESP"
                        h.FillColor = data.color
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.FillTransparency = 0.35
                        h.OutlineTransparency = 0
                        h.Adornee = data.obj
                        pcall(function() h.Parent = data.obj end)
                        crystalEspHighlights[data.obj] = h
                    else
                        crystalEspHighlights[data.obj].FillColor = data.color
                    end
                else
                    if crystalEspHighlights[data.obj] then
                        pcall(function() crystalEspHighlights[data.obj]:Destroy() end)
                        crystalEspHighlights[data.obj] = nil
                    end
                end

                -- 2. BillboardGui (3D Text Tag dengan Badge Tier & Jarak) - Ditampilkan untuk seluruh 120 objek!
                if not crystalEspBillboards[data.obj] or not crystalEspBillboards[data.obj].Parent then
                    local bg = Instance.new("BillboardGui")
                    bg.Name = "AGY_CrystalBB"
                    bg.Adornee = data.part
                    bg.Size = UDim2.new(0, 150, 0, 36)
                    bg.StudsOffset = Vector3.new(0, 3.2, 0)
                    bg.AlwaysOnTop = true

                    local lbl = Instance.new("TextLabel")
                    lbl.Name = "Tag"
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = string.format("[%s] %s\n%dm", data.label, data.name, data.dist)
                    lbl.TextColor3 = data.color
                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    lbl.TextStrokeTransparency = 0.2
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 11
                    lbl.Parent = bg

                    pcall(function() bg.Parent = data.part end)
                    crystalEspBillboards[data.obj] = bg
                else
                    local tag = crystalEspBillboards[data.obj]:FindFirstChild("Tag")
                    if tag then
                        tag.Text = string.format("[%s] %s\n%dm", data.label, data.name, data.dist)
                        tag.TextColor3 = data.color
                    end
                end
            end

            -- Bersihkan entri lama di luar jangkauan
            for obj, h in pairs(crystalEspHighlights) do
                if not currentSet[obj] then
                    if h and h.Parent then pcall(function() h:Destroy() end) end
                    crystalEspHighlights[obj] = nil
                end
            end
            for obj, b in pairs(crystalEspBillboards) do
                if not currentSet[obj] then
                    if b and b.Parent then pcall(function() b:Destroy() end) end
                    crystalEspBillboards[obj] = nil
                end
            end
        else
            if next(crystalEspHighlights) ~= nil or next(crystalEspBillboards) ~= nil then
                clearCrystalESP()
            end
        end
    end
end)

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
    StatusVal.TextColor3 = (initialStatus and initialStatus:find("%[ACTIVE%]")) and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    StatusVal.TextXAlignment = Enum.TextXAlignment.Left
    StatusVal.Parent = StatusRow

    return Card, StatusVal
end

local function addPresetDropdown(parent, title, options, defaultVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local FrameLayout = Instance.new("UIListLayout")
    FrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FrameLayout.Padding = UDim.new(0, 3)
    FrameLayout.Parent = Frame

    local LabelRow = Instance.new("Frame")
    LabelRow.Size = UDim2.new(1, 0, 0, 16)
    LabelRow.BackgroundTransparency = 1
    LabelRow.LayoutOrder = 1
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
    DropBtn.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
    DropBtn.Text = "  " .. tostring(defaultVal)
    DropBtn.Font = Enum.Font.GothamMedium
    DropBtn.TextSize = 11
    DropBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
    DropBtn.TextXAlignment = Enum.TextXAlignment.Left
    DropBtn.LayoutOrder = 2
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

    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
    OptionsContainer.AutomaticSize = Enum.AutomaticSize.Y
    OptionsContainer.BackgroundColor3 = Color3.fromRGB(28, 20, 24)
    OptionsContainer.Visible = false
    OptionsContainer.LayoutOrder = 3
    OptionsContainer.Parent = Frame

    local OptCorner = Instance.new("UICorner")
    OptCorner.CornerRadius = UDim.new(0, 5)
    OptCorner.Parent = OptionsContainer

    local OptStroke = Instance.new("UIStroke")
    OptStroke.Thickness = 1
    OptStroke.Color = Color3.fromRGB(75, 24, 34)
    OptStroke.Parent = OptionsContainer

    local OptLayout = Instance.new("UIListLayout")
    OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OptLayout.Padding = UDim.new(0, 2)
    OptLayout.Parent = OptionsContainer

    local OptPad = Instance.new("UIPadding")
    OptPad.PaddingTop = UDim.new(0, 4)
    OptPad.PaddingBottom = UDim.new(0, 4)
    OptPad.PaddingLeft = UDim.new(0, 4)
    OptPad.PaddingRight = UDim.new(0, 4)
    OptPad.Parent = OptionsContainer

    local isOpen = false
    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 24)
        OptBtn.BackgroundColor3 = (opt == defaultVal) and Color3.fromRGB(65, 20, 28) or Color3.fromRGB(34, 25, 30)
        OptBtn.Text = "  " .. tostring(opt)
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextSize = 11
        OptBtn.TextColor3 = (opt == defaultVal) and Color3.fromRGB(225, 40, 50) or Color3.fromRGB(230, 230, 235)
        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
        OptBtn.Parent = OptionsContainer

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = OptBtn

        OptBtn.MouseButton1Click:Connect(function()
            DropBtn.Text = "  " .. tostring(opt)
            isOpen = false
            OptionsContainer.Visible = false
            Arrow.Text = "v"
            for _, ch in ipairs(OptionsContainer:GetChildren()) do
                if ch:IsA("TextButton") then
                    local isSelected = (ch.Text == "  " .. tostring(opt))
                    ch.BackgroundColor3 = isSelected and Color3.fromRGB(65, 20, 28) or Color3.fromRGB(34, 25, 30)
                    ch.TextColor3 = isSelected and Color3.fromRGB(225, 40, 50) or Color3.fromRGB(230, 230, 235)
                end
            end
            if callback then callback(opt) end
            saveConfig()
        end)
    end

    DropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        OptionsContainer.Visible = isOpen
        Arrow.Text = isOpen and "^" or "v"
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
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local FrameLayout = Instance.new("UIListLayout")
    FrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FrameLayout.Padding = UDim.new(0, 3)
    FrameLayout.Parent = Frame

    local LabelRow = Instance.new("Frame")
    LabelRow.Size = UDim2.new(1, 0, 0, 16)
    LabelRow.BackgroundTransparency = 1
    LabelRow.LayoutOrder = 1
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
    DropBtn.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
    DropBtn.Font = Enum.Font.GothamMedium
    DropBtn.TextSize = 10
    DropBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
    DropBtn.TextXAlignment = Enum.TextXAlignment.Left
    DropBtn.LayoutOrder = 2
    DropBtn.Parent = Frame

    local function getSummary()
        local active = {}
        for _, opt in ipairs(options) do
            if selectedDict[opt] then
                table.insert(active, opt)
            end
        end
        if #active == 0 then return "  (None Selected)" end
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

    local OptionsContainer = Instance.new("Frame")
    OptionsContainer.Size = UDim2.new(1, 0, 0, 0)
    OptionsContainer.AutomaticSize = Enum.AutomaticSize.Y
    OptionsContainer.BackgroundColor3 = Color3.fromRGB(28, 20, 24)
    OptionsContainer.Visible = false
    OptionsContainer.LayoutOrder = 3
    OptionsContainer.Parent = Frame

    local OptCorner = Instance.new("UICorner")
    OptCorner.CornerRadius = UDim.new(0, 5)
    OptCorner.Parent = OptionsContainer

    local OptStroke = Instance.new("UIStroke")
    OptStroke.Thickness = 1
    OptStroke.Color = Color3.fromRGB(75, 24, 34)
    OptStroke.Parent = OptionsContainer

    local OptLayout = Instance.new("UIListLayout")
    OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OptLayout.Padding = UDim.new(0, 2)
    OptLayout.Parent = OptionsContainer

    local OptPad = Instance.new("UIPadding")
    OptPad.PaddingTop = UDim.new(0, 4)
    OptPad.PaddingBottom = UDim.new(0, 4)
    OptPad.PaddingLeft = UDim.new(0, 6)
    OptPad.PaddingRight = UDim.new(0, 6)
    OptPad.Parent = OptionsContainer

    local isOpen = false
    for _, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 24)
        OptBtn.BackgroundColor3 = Color3.fromRGB(34, 25, 30)
        local isChecked = (selectedDict[opt] == true)
        OptBtn.Text = (isChecked and "[✓]  " or "[  ]  ") .. tostring(opt)
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.TextSize = 11
        OptBtn.TextColor3 = isChecked and Color3.fromRGB(225, 40, 50) or Color3.fromRGB(180, 180, 185)
        OptBtn.TextXAlignment = Enum.TextXAlignment.Left
        OptBtn.Parent = OptionsContainer

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = OptBtn

        OptBtn.MouseButton1Click:Connect(function()
            selectedDict[opt] = not selectedDict[opt]
            local checked = (selectedDict[opt] == true)
            OptBtn.Text = (checked and "[✓]  " or "[  ]  ") .. tostring(opt)
            OptBtn.TextColor3 = checked and Color3.fromRGB(225, 40, 50) or Color3.fromRGB(180, 180, 185)
            DropBtn.Text = getSummary()
            if callback then callback(selectedDict) end
            saveConfig()
        end)
    end

    DropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        OptionsContainer.Visible = isOpen
        Arrow.Text = isOpen and "^" or "v"
    end)
end

local function addSlider(parent, title, minVal, maxVal, currentVal, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = title
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.35, 0, 0, 18)
    ValLabel.Position = UDim2.new(0.65, 0, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(math.floor(currentVal))
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 12
    ValLabel.TextColor3 = Color3.fromRGB(225, 40, 50)
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local SliderTrack = Instance.new("Frame")
    SliderTrack.Size = UDim2.new(1, 0, 0, 26)
    SliderTrack.Position = UDim2.new(0, 0, 0, 20)
    SliderTrack.BackgroundTransparency = 1
    SliderTrack.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, 0, 0, 8)
    SliderBar.Position = UDim2.new(0, 0, 0.5, -4)
    SliderBar.BackgroundColor3 = Color3.fromRGB(45, 34, 40)
    SliderBar.Parent = SliderTrack

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

    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            update(input.Position.X)
        end
    end)
    Services.UserInputService.InputEnded:Connect(function(input)
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
addMultiSelectDropdown(CardMine, "Mine Targets", {
    "Zenith", "Transcendent", "Celestial", "Divine", "Godly", "Secret", "Exotic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common", "Boulders", "Meteors"
}, HubState.Config.MineTargets, function(res)
    HubState.Config.MineTargets = res
end)
addPresetDropdown(CardMine, "Ore Priority", {"Zenith & Exotic+", "Mythic+", "Legendary+", "Rare+", "Semua Rarity"}, HubState.Config.OrePriorityTier or "Zenith & Exotic+", function(v)
    HubState.Config.OrePriorityTier = v
    HubState.Config.OrePriority = (v ~= "Semua Rarity")
end)
addButton(CardMine, "Instant Mine Closest", "Mine Now", function()
    if HubState.InstantMineClosest then
        HubState.InstantMineClosest()
    end
    StatusMine.Text = "[INSTANT] Mined Closest Ore!"
    StatusMine.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        StatusMine.Text = HubState.Config.AutoMine and "[ACTIVE] Mining Ore Terdekat" or "[IDLE]"
        StatusMine.TextColor3 = HubState.Config.AutoMine and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
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
addPresetDropdown(CardSell, "Sell Target", {"Pedagang Base Camp", "Pedagang Terdekat", "Teleport Jual & Balik"}, HubState.Config.SellTarget or "Pedagang Base Camp", function(v)
    HubState.Config.SellTarget = v
end)
addButton(CardSell, "Sell All Items Now", "Sell Now", function()
    if HubState.SellAllItemsNow then
        HubState.SellAllItemsNow()
    end
    StatusSell.Text = "[INSTANT] Sold All Items!"
    StatusSell.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        StatusSell.Text = HubState.Config.AutoSell and "[ACTIVE] Remote Merchant Berjalan" or "[IDLE]"
        StatusSell.TextColor3 = HubState.Config.AutoSell and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)

-- 3. TAB: AUTO COLLECT (1:1 SESUAI SCREENSHOT)
local CardCol, StatusCol = createCard(AutoCollectPage, "Auto Collect", string.format("[IDLE] Range %d Studs", HubState.Config.CollectRange or 300))
addPresetDropdown(CardCol, "Preset", {"Everything (Semua Drop & Rarity)", "Crystals Only", "Coins Only", "Runes Only"}, HubState.Config.AutoCollectPreset or "Everything (Semua Drop & Rarity)", function(v)
    HubState.Config.AutoCollectPreset = v
    if HubState.Config.AutoCollect then
        StatusCol.Text = string.format("[ACTIVE] %s | Range %d Studs", v, HubState.Config.CollectRange or 300)
    end
end)
addButton(CardCol, "Pilih Semua Target (Select All)", "Select All", function()
    for k in pairs(HubState.Config.CollectTargets) do
        HubState.Config.CollectTargets[k] = true
    end
end)
addToggle(CardCol, "Enable Auto Collect", HubState.Config.AutoCollect, function(enabled)
    HubState.Config.AutoCollect = enabled
    local curRange = HubState.Config.CollectRange or 300
    StatusCol.Text = enabled and string.format("[ACTIVE] Collecting within %d Studs", curRange) or string.format("[IDLE] Range %d Studs", curRange)
    StatusCol.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardCol, "Collect Targets", {
    "Semua Rarity (All)", "Crystals", "Ores", "Boulders", "Coins", "Candy / Permen", "Runes", "Chests / Crates", "Meteors", "Shards"
}, HubState.Config.CollectTargets, function(res)
    HubState.Config.CollectTargets = res
end)
addButton(CardCol, "Collect All Drops Now", "Collect Now", function()
    if HubState.CollectEverythingNow then
        HubState.CollectEverythingNow()
    end
    StatusCol.Text = "[INSTANT] All Drops Collected!"
    StatusCol.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        local curRange = HubState.Config.CollectRange or 300
        StatusCol.Text = HubState.Config.AutoCollect and string.format("[ACTIVE] Collecting within %d Studs", curRange) or string.format("[IDLE] Range %d Studs", curRange)
        StatusCol.TextColor3 = HubState.Config.AutoCollect and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)
addSlider(CardCol, "Collect Range (Studs)", 50, 1500, HubState.Config.CollectRange or 300, function(val)
    HubState.Config.CollectRange = val
    if HubState.Config.AutoCollect then
        StatusCol.Text = string.format("[ACTIVE] Collecting within %d Studs", val)
    else
        StatusCol.Text = string.format("[IDLE] Range %d Studs", val)
    end
end)
addButton(CardCol, "Preset Range: 300 Studs", "300", function()
    HubState.Config.CollectRange = 300
    if HubState.Config.AutoCollect then StatusCol.Text = "[ACTIVE] Range 300 Studs" else StatusCol.Text = "[IDLE] Range 300 Studs" end
end)
addButton(CardCol, "Preset Range: 600 Studs", "600", function()
    HubState.Config.CollectRange = 600
    if HubState.Config.AutoCollect then StatusCol.Text = "[ACTIVE] Range 600 Studs" else StatusCol.Text = "[IDLE] Range 600 Studs" end
end)
addButton(CardCol, "Preset Range: 1500 Studs (Max)", "1500", function()
    HubState.Config.CollectRange = 1500
    if HubState.Config.AutoCollect then StatusCol.Text = "[ACTIVE] Range 1500 Studs" else StatusCol.Text = "[IDLE] Range 1500 Studs" end
end)

local CardTPCol, StatusTPCol = createCard(AutoCollectPage, "Teleport Collect", "[IDLE]")
addPresetDropdown(CardTPCol, "Preset", {"Everything", "Rare Drops Only"}, "Everything", function(v) end)
addToggle(CardTPCol, "Enable Teleport Collect", HubState.Config.TeleportCollectEnabled, function(enabled)
    HubState.Config.TeleportCollectEnabled = enabled
    StatusTPCol.Text = enabled and "[ACTIVE] Teleporting to Drops" or "[IDLE]"
    StatusTPCol.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addSlider(CardTPCol, "Max TP Range (Studs)", 100, 1500, math.floor((HubState.Config.CollectRange or 300) * 1.5), function(val)
    HubState.Config.CollectRange = math.floor(val / 1.5)
end)

-- 4. TAB: MOVEMENT
local CardMove, StatusMove = createCard(MovementPage, "Movement", "[ACTIVE] Physics Engine Loaded")
addPresetDropdown(CardMove, "Preset", {"Blatant", "Legit", "Custom"}, "Blatant", function(v)
    if v == "Blatant" then
        HubState.Config.WalkSpeed = 100
        HubState.Config.JumpPower = 150
        HubState.Config.Noclip = true
    elseif v == "Legit" then
        HubState.Config.WalkSpeed = 32
        HubState.Config.JumpPower = 70
        HubState.Config.Noclip = false
    end
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.WalkSpeed = HubState.Config.WalkSpeed
            hum.JumpPower = HubState.Config.JumpPower
        end
    end
end)
addToggle(CardMove, "Enable Movement Mods", true, function(enabled)
    HubState.Config.PlayerModsEnabled = enabled
    StatusMove.Text = enabled and "[ACTIVE] Movement Enforced" or "[IDLE]"
end)
addMultiSelectDropdown(CardMove, "Movement Features", {"Speed", "Jump", "Fly", "Noclip", "InfJump", "AutoBhop", "Click TP"}, {
    ["Speed"] = true, ["Jump"] = true, ["Fly"] = false, ["Noclip"] = false, ["InfJump"] = false, ["AutoBhop"] = false, ["Click TP"] = false
}, function(res)
    HubState.Config.Noclip = res["Noclip"]
    HubState.Config.InfJump = res["InfJump"]
    HubState.Config.AutoBhop = res["AutoBhop"]
    HubState.Config.ClickTP = res["Click TP"]
end)
addSlider(CardMove, "WalkSpeed", 16, 300, HubState.Config.WalkSpeed, function(val)
    HubState.Config.WalkSpeed = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end)
addButton(CardMove, "Quick Speed: 16 (Normal)", "16", function()
    HubState.Config.WalkSpeed = 16
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
addButton(CardMove, "Quick Speed: 32 (Fast)", "32", function()
    HubState.Config.WalkSpeed = 32
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 32 end
    end
end)
addButton(CardMove, "Quick Speed: 60 (Sprint)", "60", function()
    HubState.Config.WalkSpeed = 60
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 60 end
    end
end)
addButton(CardMove, "Quick Speed: 100 (Extreme)", "100", function()
    HubState.Config.WalkSpeed = 100
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 100 end
    end
end)
addSlider(CardMove, "JumpPower", 50, 400, HubState.Config.JumpPower, function(val)
    HubState.Config.JumpPower = val
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end
end)

-- 5. TAB: AUTO GARDEN (MINE ANTARCTICA CRYSTAL FARM - 1:1 BARRAGE HUB SPEC)
local CardGarden, StatusGarden = createCard(AutoGardenPage, "Auto Garden", "[IDLE]")
addPresetDropdown(CardGarden, "Preset", {"Best", "Rarity", "Luck", "Mutation", "Value", "Weight"}, HubState.Config.AutoGardenPreset or "Best", function(v)
    HubState.Config.AutoGardenPreset = v
    if HubState.Config.AutoGarden then
        StatusGarden.Text = "[ACTIVE] Farming Kristal (" .. v .. ")"
    end
end)
addToggle(CardGarden, "Enable Auto Garden", HubState.Config.AutoGarden, function(enabled)
    HubState.Config.AutoGarden = enabled
    local currentPreset = HubState.Config.AutoGardenPreset or "Best"
    StatusGarden.Text = enabled and ("[ACTIVE] Farming Kristal (" .. currentPreset .. ")") or "[IDLE]"
    StatusGarden.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addButton(CardGarden, "Auto Garden Now", "Garden Now", function()
    if HubState.PerformGarden then
        HubState.PerformGarden("all")
    end
    StatusGarden.Text = "[INSTANT] Auto Garden Executed!"
    StatusGarden.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        local currentPreset = HubState.Config.AutoGardenPreset or "Best"
        StatusGarden.Text = HubState.Config.AutoGarden and ("[ACTIVE] Farming Kristal (" .. currentPreset .. ")") or "[IDLE]"
        StatusGarden.TextColor3 = HubState.Config.AutoGarden and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)
addButton(CardGarden, "Buy Garden Space", "Buy Space", function()
    if HubState.BuyGardenSpace then
        HubState.BuyGardenSpace()
    end
    StatusGarden.Text = "[INSTANT] Buy Space Triggered!"
    StatusGarden.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        local currentPreset = HubState.Config.AutoGardenPreset or "Best"
        StatusGarden.Text = HubState.Config.AutoGarden and ("[ACTIVE] Farming Kristal (" .. currentPreset .. ")") or "[IDLE]"
        StatusGarden.TextColor3 = HubState.Config.AutoGarden and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)
addButton(CardGarden, "Harvest All Crystals", "Harvest Now", function()
    if HubState.PerformGarden then
        HubState.PerformGarden("harvest")
    end
    StatusGarden.Text = "[INSTANT] Harvest All Executed!"
    StatusGarden.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        local currentPreset = HubState.Config.AutoGardenPreset or "Best"
        StatusGarden.Text = HubState.Config.AutoGarden and ("[ACTIVE] Farming Kristal (" .. currentPreset .. ")") or "[IDLE]"
        StatusGarden.TextColor3 = HubState.Config.AutoGarden and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)
addButton(CardGarden, "Plant Best Crystal", "Plant Now", function()
    if HubState.PerformGarden then
        HubState.PerformGarden("plant")
    end
    StatusGarden.Text = "[INSTANT] Plant Best Crystal Executed!"
    StatusGarden.TextColor3 = Color3.fromRGB(74, 222, 128)
    task.delay(1.5, function()
        local currentPreset = HubState.Config.AutoGardenPreset or "Best"
        StatusGarden.Text = HubState.Config.AutoGarden and ("[ACTIVE] Farming Kristal (" .. currentPreset .. ")") or "[IDLE]"
        StatusGarden.TextColor3 = HubState.Config.AutoGarden and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    end)
end)
addPresetDropdown(CardGarden, "Garden Actions", {"Buy Space, Fill Best", "Fill Garden Only", "Buy Garden Space Only", "Harvest / Clear Garden"}, HubState.Config.GardenAction, function(v)
    HubState.Config.GardenAction = v
end)
local gardenDict = {
    ["Auto Buy Garden Space"] = true,
    ["Auto Fill Best Crystals"] = true,
    ["Auto Harvest Mutated Crystals"] = true,
    ["Prioritize Rarity > Luck"] = true
}
addMultiSelectDropdown(CardGarden, "Garden Features", {
    "Auto Buy Garden Space", "Auto Fill Best Crystals", "Auto Harvest Mutated Crystals", "Prioritize Rarity > Luck"
}, gardenDict, function(r)
    HubState.Config.GardenFeatures = r
end)

-- 6. TAB: AUTO RUNES
local CardRunes, StatusRunes = createCard(AutoRunesPage, "Auto Runes", "[IDLE]")
addPresetDropdown(CardRunes, "Preset", {"Default", "Fast Activate"}, HubState.Config.AutoRunesPreset, function(v)
    HubState.Config.AutoRunesPreset = v
end)
addToggle(CardRunes, "Enable Auto Runes", HubState.Config.AutoRunes, function(enabled)
    HubState.Config.AutoRunes = enabled
    StatusRunes.Text = enabled and "[ACTIVE] Auto Craft & Infuse Runes" or "[IDLE]"
    StatusRunes.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addPresetDropdown(CardRunes, "Rune Actions", {"Collect & Activate", "Collect Only", "Activate Only"}, HubState.Config.RuneAction, function(v)
    HubState.Config.RuneAction = v
end)

-- 7. TAB: AUTO PICKAXE
local CardPickaxe, StatusPickaxe = createCard(AutoPickaxePage, "Auto Pickaxe", "[ACTIVE] Auto Equip Highest Tier")
addPresetDropdown(CardPickaxe, "Preset", {"Best Available", "Next Tier"}, HubState.Config.AutoPickaxePreset, function(v)
    HubState.Config.AutoPickaxePreset = v
end)
addToggle(CardPickaxe, "Enable Auto Pickaxe", HubState.Config.AutoPickaxe, function(enabled)
    HubState.Config.AutoPickaxe = enabled
    StatusPickaxe.Text = enabled and "[ACTIVE] Auto Equip Highest Tier" or "[IDLE]"
    StatusPickaxe.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardPickaxe, "Pickaxe Actions", {"Auto Equip Best Tool", "Auto Buy Better Pickaxe", "Auto Repair"}, {
    ["Auto Equip Best Tool"] = true, ["Auto Buy Better Pickaxe"] = false, ["Auto Repair"] = true
}, function(r) end)

-- 8. TAB: AUTO UPGRADE
local CardUpgrade, StatusUpgrade = createCard(AutoUpgradePage, "Auto Upgrade", "[IDLE]")
addPresetDropdown(CardUpgrade, "Preset", {"Balance", "Capacity First", "Strength First"}, HubState.Config.AutoUpgradePreset, function(v)
    HubState.Config.AutoUpgradePreset = v
end)
addToggle(CardUpgrade, "Enable Auto Upgrade", HubState.Config.AutoUpgrade, function(enabled)
    HubState.Config.AutoUpgrade = enabled
    StatusUpgrade.Text = enabled and "[ACTIVE] Upgrading Pickaxes & Bag" or "[IDLE]"
    StatusUpgrade.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardUpgrade, "Upgrade Actions", {"Carry Capacity", "Mining Power", "Warmth & Freeze Shield"}, {
    ["Carry Capacity"] = true, ["Mining Power"] = true, ["Warmth & Freeze Shield"] = true
}, function(r) end)

-- 9. TAB: AUTO ITEMS
local CardItems, StatusItems = createCard(AutoItemsPage, "Auto Items", "[IDLE]")
addPresetDropdown(CardItems, "Preset", {"Utility", "Explosives", "All"}, HubState.Config.AutoItemsPreset, function(v)
    HubState.Config.AutoItemsPreset = v
end)
addToggle(CardItems, "Enable Auto Items", HubState.Config.AutoItems, function(enabled)
    HubState.Config.AutoItems = enabled
    StatusItems.Text = enabled and "[ACTIVE] Radar, Bombs & Chests Active" or "[IDLE]"
    StatusItems.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardItems, "Item Actions", {"Radar Batu Besar", "Radar Kristal 99x", "Radar Meteor", "Auto Gunakan Radar", "Beli Bom Dinamit", "Buka Chest & Crate"}, {
    ["Radar Batu Besar"] = true, ["Radar Kristal 99x"] = true, ["Radar Meteor"] = true, ["Auto Gunakan Radar"] = true, ["Beli Bom Dinamit"] = false, ["Buka Chest & Crate"] = true
}, function(r) end)
addButton(CardItems, "Ping Radar Tools Now", "Ping Now", function()
    pcall(function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local containers = {LocalPlayer.Character, backpack}
        for _, cont in ipairs(containers) do
            if cont then
                for _, tool in ipairs(cont:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:lower():find("radar") then
                        tool:Activate()
                    end
                end
            end
        end
    end)
    StatusItems.Text = "[INSTANT] Radar Activated!"
    StatusItems.TextColor3 = Color3.fromRGB(74, 222, 128)
end)

-- 10. TAB: REWARDS
local CardRewards, StatusRewards = createCard(RewardsPage, "Rewards", "[IDLE]")
addPresetDropdown(CardRewards, "Preset", {"Claim All", "Playtime Only"}, HubState.Config.RewardsPreset, function(v)
    HubState.Config.RewardsPreset = v
end)
addToggle(CardRewards, "Enable Auto Claim Rewards", HubState.Config.AutoClaimRewards, function(enabled)
    HubState.Config.AutoClaimRewards = enabled
    StatusRewards.Text = enabled and "[ACTIVE] Claiming Daily & Free Gifts" or "[IDLE]"
    StatusRewards.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
addMultiSelectDropdown(CardRewards, "Reward Actions", {"Daily Gift Claim", "Playtime Rewards", "Wheel Spin", "Quests"}, {
    ["Daily Gift Claim"] = true, ["Playtime Rewards"] = true, ["Wheel Spin"] = true, ["Quests"] = true
}, function(r) end)

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
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.WalkSpeed = HubState.Config.WalkSpeed
            hum.JumpPower = HubState.Config.JumpPower
        end
    end
end)
addToggle(CardPlayerMods, "Enable Player Mods", HubState.Config.PlayerModsEnabled, function(enabled)
    HubState.Config.PlayerModsEnabled = enabled
    StatusPlayerMods.Text = enabled and "[ACTIVE] 7 Mods | Blatant" or "[IDLE]"
    StatusPlayerMods.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    if not enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end
end)
addToggle(CardPlayerMods, "Enable Anti-Ragdoll", HubState.Config.AntiRagdoll, function(enabled)
    HubState.Config.AntiRagdoll = enabled
    HubState.Config.PlayerModsList["Anti Ragdoll"] = enabled
end)
addMultiSelectDropdown(CardPlayerMods, "Player Mods", {
    "Speed", "Jump Boost", "Anti Ragdoll", "Anti Freeze", "No Fall Damage", "Infinite Jetpack", "Noclip", "Fly", "SpinBot", "Click TP"
}, HubState.Config.PlayerModsList, function(res)
    HubState.Config.PlayerModsList = res
    HubState.Config.AntiRagdoll = res["Anti Ragdoll"]
    HubState.Config.AntiFreeze = res["Anti Freeze"]
    HubState.Config.NoFallDamage = res["No Fall Damage"]
    HubState.Config.InfiniteJetpack = res["Infinite Jetpack"]
    HubState.Config.Noclip = res["Noclip"]
    HubState.Config.Fly = res["Fly"]
    HubState.Config.SpinBot = res["SpinBot"]
    HubState.Config.ClickTP = res["Click TP"]
end)
addSlider(CardPlayerMods, "Custom Speed", 16, 300, HubState.Config.WalkSpeed, function(v)
    HubState.Config.WalkSpeed = v
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
addButton(CardPlayerMods, "Quick Speed: 16 (Normal)", "16", function()
    HubState.Config.WalkSpeed = 16
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
addButton(CardPlayerMods, "Quick Speed: 32 (Fast)", "32", function()
    HubState.Config.WalkSpeed = 32
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 32 end
    end
end)
addButton(CardPlayerMods, "Quick Speed: 60 (Sprint)", "60", function()
    HubState.Config.WalkSpeed = 60
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 60 end
    end
end)
addButton(CardPlayerMods, "Quick Speed: 100 (Extreme)", "100", function()
    HubState.Config.WalkSpeed = 100
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 100 end
    end
end)
addSlider(CardPlayerMods, "Custom Jump", 50, 400, HubState.Config.JumpPower, function(v)
    HubState.Config.JumpPower = v
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
end)
addButton(CardPlayerMods, "Quick Jump: 50 (Normal)", "50", function()
    HubState.Config.JumpPower = 50
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
end)
addButton(CardPlayerMods, "Quick Jump: 100 (High)", "100", function()
    HubState.Config.JumpPower = 100
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 100 end
    end
end)
addButton(CardPlayerMods, "Quick Jump: 150 (Super)", "150", function()
    HubState.Config.JumpPower = 150
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 150 end
    end
end)

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
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardMiningMods, "Enable Mining Mods", HubState.Config.MiningModsEnabled, function(enabled)
    HubState.Config.MiningModsEnabled = enabled
    StatusMiningMods.Text = enabled and "[ACTIVE] 9 Mods | Swing 0.09s" or "[IDLE]"
    StatusMiningMods.TextColor3 = enabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardMiningMods, "Enable Anti-Ragdoll", HubState.Config.AntiRagdoll, function(enabled)
    HubState.Config.AntiRagdoll = enabled
    HubState.Config.MiningModsList["Anti Ragdoll"] = enabled
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addMultiSelectDropdown(CardMiningMods, "Mining Mods", {
    "8x Kekuatan", "Ranjau Instan", "x4 Berat Dibawa", "2x Penggalian Cepat", "2x Keberuntungan", "4x Keberuntungan", "x2 Kristal", "Tidak Ada Kerusakan Jatuh",
    "Anti Ragdoll", "Dig While Mining", "Instant Break", "Reach Mine", "Fast Swing", "Ore Aura", "No Slowdown", "Auto Equip Best Tool", "Auto Repair"
}, HubState.Config.MiningModsList, function(res)
    HubState.Config.MiningModsList = res
    HubState.Config.Power8x = res["8x Kekuatan"]
    HubState.Config.InstantMine = res["Ranjau Instan"]
    HubState.Config.CarryWeight4x = res["x4 Berat Dibawa"]
    HubState.Config.FastDig2x = res["2x Penggalian Cepat"]
    HubState.Config.Luck2x = res["2x Keberuntungan"]
    HubState.Config.Luck4x = res["4x Keberuntungan"]
    HubState.Config.Crystal2x = res["x2 Kristal"]
    HubState.Config.Crystals2x = res["x2 Kristal"]
    HubState.Config.NoFallDamage = res["Tidak Ada Kerusakan Jatuh"]
    HubState.Config.AntiRagdoll = res["Anti Ragdoll"]
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addSlider(CardMiningMods, "Fast Swing Hit Multiplier", 1, 8, HubState.Config.FastMineHits, function(v) HubState.Config.FastMineHits = v end)
addSlider(CardMiningMods, "Reach Mine (Studs)", 10, 80, HubState.Config.MineRange, function(v) HubState.Config.MineRange = v end)
addButton(CardMiningMods, "Hancurkan Tambang Terdekat (1-Click)", "Mine Now", function()
    if HubState.InstantMineClosest then
        local success = HubState.InstantMineClosest()
        if StatusMiningMods then
            StatusMiningMods.Text = success and "[INSTANT] Mined Closest Ore!" or "[FAILED] No Ore In Range"
            StatusMiningMods.TextColor3 = success and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(239, 68, 68)
            task.delay(1.5, function()
                if StatusMiningMods then
                    StatusMiningMods.Text = HubState.Config.MiningModsEnabled and "[ACTIVE] 17 Mods Active" or "[IDLE]"
                    StatusMiningMods.TextColor3 = HubState.Config.MiningModsEnabled and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
                end
            end)
        end
    end
end)
addButton(CardMiningMods, "Pilih Semua Mining Mods (Select All)", "Select All", function()
    for k in pairs(HubState.Config.MiningModsList) do
        HubState.Config.MiningModsList[k] = true
    end
    HubState.Config.MiningModsEnabled = true
    HubState.Config.Power8x = true
    HubState.Config.InstantMine = true
    HubState.Config.CarryWeight4x = true
    HubState.Config.FastDig2x = true
    HubState.Config.Luck2x = true
    HubState.Config.Luck4x = true
    HubState.Config.Crystal2x = true
    HubState.Config.Crystals2x = true
    HubState.Config.NoFallDamage = true
    HubState.Config.AntiRagdoll = true
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
    if StatusMiningMods then
        StatusMiningMods.Text = "[ACTIVE] All 17 Mining Mods Active"
        StatusMiningMods.TextColor3 = Color3.fromRGB(74, 222, 128)
    end
end)

-- KARTU GAMEPASS TOKO MINE ANTARCTICA (100% UNLOCKED)
local CardTokoPass, StatusTokoPass = createCard(MiningModsPage, "Toko Gamepasses (Unlocked)", "[ACTIVE] 9 Passes Active")
addToggle(CardTokoPass, "8x Kekuatan (Damage Kristal 8x)", HubState.Config.Power8x, function(v)
    HubState.Config.Power8x = v
    HubState.Config.MiningModsList["8x Kekuatan"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "Ranjau Instan (1-Click Instant Break)", HubState.Config.InstantMine, function(v)
    HubState.Config.InstantMine = v
    HubState.Config.MiningModsList["Ranjau Instan"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "Tidak Ada Kerusakan Akibat Jatuh", HubState.Config.NoFallDamage, function(v)
    HubState.Config.NoFallDamage = v
    HubState.Config.MiningModsList["Tidak Ada Kerusakan Jatuh"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "x4 Berat yang Dibawa (4x Ransel)", HubState.Config.CarryWeight4x, function(v)
    HubState.Config.CarryWeight4x = v
    HubState.Config.MiningModsList["x4 Berat Dibawa"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "2x Penggalian Cepat (Fast Dig 2x)", HubState.Config.FastDig2x, function(v)
    HubState.Config.FastDig2x = v
    HubState.Config.MiningModsList["2x Penggalian Cepat"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "2x Keberuntungan (2x Luck Gali)", HubState.Config.Luck2x, function(v)
    HubState.Config.Luck2x = v
    HubState.Config.MiningModsList["2x Keberuntungan"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "4x Keberuntungan (4x Luck Gali)", HubState.Config.Luck4x, function(v)
    HubState.Config.Luck4x = v
    HubState.Config.MiningModsList["4x Keberuntungan"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "x2 Kristal (2x Kristal Diangkat)", HubState.Config.Crystal2x, function(v)
    HubState.Config.Crystal2x = v
    HubState.Config.Crystals2x = v
    HubState.Config.MiningModsList["x2 Kristal"] = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)
addToggle(CardTokoPass, "2x Koin (2x Koin saat Menjual)", HubState.Config.Coins2x, function(v)
    HubState.Config.Coins2x = v
    if HubState.SyncGamepasses then HubState.SyncGamepasses() end
end)

-- 13. TAB: VISUALS (ESP & WALLHACK)
local CardESP, StatusESP = createCard(VisualsPage, "Visuals & ESP", "[IDLE]")
addToggle(CardESP, "Enable Player ESP", HubState.Config.EspEnabled, function(v)
    HubState.Config.EspEnabled = v
    StatusESP.Text = v and "[ACTIVE] ESP Rendered" or "[IDLE]"
    StatusESP.TextColor3 = v and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(200, 180, 185)
end)
local espDict = { ["Chams"] = true, ["Boxes"] = true, ["Names"] = true, ["Health"] = true, ["Distance"] = true, ["Tracers"] = false, ["Crystal ESP"] = true }
addToggle(CardESP, "Enable Crystal & Boulder ESP", HubState.Config.CrystalEsp, function(v)
    HubState.Config.CrystalEsp = v
end)
addMultiSelectDropdown(CardESP, "ESP Elements", {"Chams", "Boxes", "Names", "Health", "Distance", "Tracers", "Crystal ESP"}, espDict, function(res)
    HubState.Config.EspChams = res["Chams"]
    HubState.Config.EspBoxes = res["Boxes"]
    HubState.Config.EspNames = res["Names"]
    HubState.Config.EspHealth = res["Health"]
    HubState.Config.EspDistance = res["Distance"]
    HubState.Config.EspTracers = res["Tracers"]
    HubState.Config.CrystalEsp = res["Crystal ESP"]
end)
addSlider(CardESP, "Crystal ESP Range (Studs)", 100, 1500, HubState.Config.EspRange or 1000, function(v)
    HubState.Config.EspRange = v
end)
addMultiSelectDropdown(CardESP, "Filter Kelangkaan (Semua Rarity)", {
    "Zenith", "Cosmic", "Transcendent", "Celestial", "Divine", "Godly", "Secret", "Exotic", "Mythic", "Void", "Legendary", "Obsidian", "Epic", "Diamond", "Emerald", "Ruby", "Sapphire", "Rare", "Gold", "Silver", "Uncommon", "Copper", "Iron", "Common", "Stone", "Crystal", "Boulder", "Meteor"
}, HubState.Config.EspRarities, function(res)
    HubState.Config.EspRarities = res
end)
addButton(CardESP, "Tampilkan Semua Rarity (All On)", "Semua Rarity", function()
    for k in pairs(HubState.Config.EspRarities) do
        HubState.Config.EspRarities[k] = true
    end
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

-- Handshake kesiapan game untuk flight-lock loader (Barrage loader.txt & payload.lua protocol)
shared._barrageGameLoaded = true
shared._barrageGameReady = true
if _flight then
    _flight.Running = false
    _flight.Ready = true
end

pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = "BARRAGE",
        Text = "Barrage Hub v1.0 [Mine Antarctica Suite] berhasil dimuat!",
        Duration = 5
    })
end)

print("[BARRAGE] Barrage Hub v1.0 loaded successfully (Standalone).")
