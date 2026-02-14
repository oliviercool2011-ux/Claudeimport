repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- Safe character wait - don't force anything
local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        return char
    end
    return Player.CharacterAdded:Wait()
end

-- Wait for character without forcing reset
task.spawn(function()
    waitForCharacter()
end)

if not getgenv then
    getgenv = function() return _G end
end

local ConfigFileName = "22s_DUELS_Config.json"

local Enabled = {
    SpeedBoost = false,
    AntiRagdoll = false,
    SpinBot = false,
    SpeedWhileStealing = false,
    AutoSteal = false,
    Unwalk = false,
    Optimizer = false,
    Galaxy = false,
    SpamBat = false,
    BatAimbot = false,
    AutoDisableSpeed = true,
    GalaxySkyBright = false,
    AutoWalkEnabled = false,
    AutoRightEnabled = false,
    ScriptUserESP = true
}

local Values = {
    BoostSpeed = 30,
    SpinSpeed = 30,
    StealingSpeedValue = 29,
    STEAL_RADIUS = 20,
    STEAL_DURATION = 1.3,
    DEFAULT_GRAVITY = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER = 35,
    HOP_COOLDOWN = 0.08
}

local KEYBINDS = {
    SPEED = Enum.KeyCode.V,
    SPIN = Enum.KeyCode.N,
    GALAXY = Enum.KeyCode.M,
    BATAIMBOT = Enum.KeyCode.X,
    NUKE = Enum.KeyCode.Q,
    AUTOLEFT = Enum.KeyCode.Z,
    AUTORIGHT = Enum.KeyCode.C
}

-- Load Config FIRST before anything else
local configLoaded = false
pcall(function()
    if readfile and isfile and isfile(ConfigFileName) then
        local data = HttpService:JSONDecode(readfile(ConfigFileName))
        if data then
            for k, v in pairs(data) do
                if Enabled[k] ~= nil then
                    Enabled[k] = v
                end
            end
            for k, v in pairs(data) do
                if Values[k] ~= nil then
                    Values[k] = v
                end
            end
            if data.KEY_SPEED then KEYBINDS.SPEED = Enum.KeyCode[data.KEY_SPEED] end
            if data.KEY_SPIN then KEYBINDS.SPIN = Enum.KeyCode[data.KEY_SPIN] end
            if data.KEY_GALAXY then KEYBINDS.GALAXY = Enum.KeyCode[data.KEY_GALAXY] end
            if data.KEY_BATAIMBOT then KEYBINDS.BATAIMBOT = Enum.KeyCode[data.KEY_BATAIMBOT] end
            if data.KEY_AUTOLEFT then KEYBINDS.AUTOLEFT = Enum.KeyCode[data.KEY_AUTOLEFT] end
            if data.KEY_AUTORIGHT then KEYBINDS.AUTORIGHT = Enum.KeyCode[data.KEY_AUTORIGHT] end
            configLoaded = true
        end
    end
end)

-- Save Config
local function SaveConfig()
    local data = {}
    for k, v in pairs(Enabled) do
        data[k] = v
    end
    for k, v in pairs(Values) do
        data[k] = v
    end
    data.KEY_SPEED = KEYBINDS.SPEED.Name
    data.KEY_SPIN = KEYBINDS.SPIN.Name
    data.KEY_GALAXY = KEYBINDS.GALAXY.Name
    data.KEY_BATAIMBOT = KEYBINDS.BATAIMBOT.Name
    data.KEY_AUTOLEFT = KEYBINDS.AUTOLEFT.Name
    data.KEY_AUTORIGHT = KEYBINDS.AUTORIGHT.Name
    
    local success = false
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(data))
            success = true
        end)
    end
    return success
end

local Connections = {}
local isStealing = false
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12
local spaceHeld = false
local AutoWalkEnabled = false
local AutoRightEnabled = false
local galaxyEnabled = false
local waitingForKeybind = nil

local SlapList = {
    {1, "Bat"}, {2, "Slap"}, {3, "Iron Slap"}, {4, "Gold Slap"},
    {5, "Diamond Slap"}, {6, "Emerald Slap"}, {7, "Ruby Slap"},
    {8, "Dark Matter Slap"}, {9, "Flame Slap"}, {10, "Nuclear Slap"},
    {11, "Galaxy Slap"}, {12, "Glitched Slap"}
}

local ADMIN_KEY = "78a772b6-9e1c-4827-ab8b-04a07838f298"
local REMOTE_EVENT_ID = "352aad58-c786-4998-886b-3e4fa390721e"
local BALLOON_REMOTE = ReplicatedStorage:FindFirstChild(REMOTE_EVENT_ID, true)

local function INSTANT_NUKE(target)
    if not BALLOON_REMOTE or not target then return end
    for _, p in ipairs({"balloon", "ragdoll", "jumpscare", "morph", "tiny", "rocket", "inverse", "jail"}) do
        BALLOON_REMOTE:FireServer(ADMIN_KEY, target, p)
    end
end

local function getNearestPlayer()
    local c = Player.Character
    if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local pos = h.Position
    local nearest = nil
    local dist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local oh = p.Character:FindFirstChild("HumanoidRootPart")
            if oh then
                local d = (pos - oh.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function findBat()
    local c = Player.Character
    if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then
            return ch
        end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then
                return ch
            end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function startSpamBat()
    if Connections.spamBat then return end
    Connections.spamBat = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c = Player.Character
        if not c then return end
        local bat = findBat()
        if not bat then return end
        if bat.Parent ~= c then
            bat.Parent = c
        end
        local now = tick()
        if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now
        pcall(function() bat:Activate() end)
    end)
end

local function stopSpamBat()
    if Connections.spamBat then
        Connections.spamBat:Disconnect()
        Connections.spamBat = nil
    end
end

local spinBAV = nil

local function startSpinBot()
    local c = Player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if spinBAV then spinBAV:Destroy() spinBAV = nil end
    for _, v in pairs(hrp:GetChildren()) do
        if v.Name == "SpinBAV" then v:Destroy() end
    end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "SpinBAV"
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    spinBAV.Parent = hrp
end

local function stopSpinBot()
    if spinBAV then
        spinBAV:Destroy()
        spinBAV = nil
    end
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v.Name == "SpinBAV" then v:Destroy() end
            end
        end
    end
end

local function startSpeedBoost()
    if Connections.speedBoost then return end
    Connections.speedBoost = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            h.WalkSpeed = Values.BoostSpeed
        end
    end)
end

local function stopSpeedBoost()
    if Connections.speedBoost then
        Connections.speedBoost:Disconnect()
        Connections.speedBoost = nil
    end
    local c = Player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16 end
    end
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end

local function stopAntiRagdoll()
    if Connections.antiRagdoll then
        Connections.antiRagdoll:Disconnect()
        Connections.antiRagdoll = nil
    end
    local c = Player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
    end
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local c = Player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local pos = hrp.Position
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character then
                local otherHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if otherHrp and (pos - otherHrp.Position).Magnitude <= Values.STEAL_RADIUS then
                    isStealing = true
                    task.delay(Values.STEAL_DURATION, function() isStealing = false end)
                    break
                end
            end
        end
    end)
end

local function stopAutoSteal()
    if Connections.autoSteal then
        Connections.autoSteal:Disconnect()
        Connections.autoSteal = nil
    end
    isStealing = false
end

local function startSpeedWhileStealing()
    if Connections.speedStealing then return end
    Connections.speedStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not isStealing then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            h.WalkSpeed = Values.StealingSpeedValue
        end
    end)
end

local function stopSpeedWhileStealing()
    if Connections.speedStealing then
        Connections.speedStealing:Disconnect()
        Connections.speedStealing = nil
    end
end

local galaxyForce = nil

local function setupGalaxyForce()
    local c = Player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if galaxyForce then galaxyForce:Destroy() galaxyForce = nil end
    for _, v in pairs(hrp:GetChildren()) do
        if v.Name == "GalaxyForce" then v:Destroy() end
    end
    
    galaxyForce = Instance.new("BodyVelocity")
    galaxyForce.Name = "GalaxyForce"
    galaxyForce.MaxForce = Vector3.new(0, 0, 0)
    galaxyForce.Velocity = Vector3.new(0, 0, 0)
    galaxyForce.Parent = hrp
end

local function adjustGalaxyJump()
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        local gravityPercent = Values.GalaxyGravityPercent / 100
        h.JumpPower = Values.HOP_POWER / gravityPercent
    end
end

local lastHopTime = 0

local function startGalaxy()
    galaxyEnabled = true
    setupGalaxyForce()
    adjustGalaxyJump()
    
    local c = Player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            local gravityPercent = Values.GalaxyGravityPercent / 100
            workspace.Gravity = Values.DEFAULT_GRAVITY * gravityPercent
        end
    end
    
    if Connections.galaxyHop then return end
    Connections.galaxyHop = RunService.Heartbeat:Connect(function()
        if not Enabled.Galaxy then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not h or not hrp then return end
        
        if spaceHeld and h:GetState() ~= Enum.HumanoidStateType.Freefall then
            local now = tick()
            if now - lastHopTime >= Values.HOP_COOLDOWN then
                lastHopTime = now
                if galaxyForce then
                    galaxyForce.MaxForce = Vector3.new(0, math.huge, 0)
                    galaxyForce.Velocity = Vector3.new(0, Values.HOP_POWER, 0)
                    task.delay(0.1, function()
                        if galaxyForce then
                            galaxyForce.MaxForce = Vector3.new(0, 0, 0)
                            galaxyForce.Velocity = Vector3.new(0, 0, 0)
                        end
                    end)
                end
            end
        end
    end)
end

local function stopGalaxy()
    galaxyEnabled = false
    workspace.Gravity = Values.DEFAULT_GRAVITY
    
    if galaxyForce then
        galaxyForce:Destroy()
        galaxyForce = nil
    end
    
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v.Name == "GalaxyForce" then v:Destroy() end
            end
        end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = 50 end
    end
    
    if Connections.galaxyHop then
        Connections.galaxyHop:Disconnect()
        Connections.galaxyHop = nil
    end
end

local function startUnwalk()
    if Connections.unwalk then return end
    Connections.unwalk = RunService.Heartbeat:Connect(function()
        if not Enabled.Unwalk then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            for _, v in pairs(h:GetPlayingAnimationTracks()) do
                if v.Name:lower():find("walk") or v.Name:lower():find("run") then
                    v:Stop()
                end
            end
        end
    end)
end

local function stopUnwalk()
    if Connections.unwalk then
        Connections.unwalk:Disconnect()
        Connections.unwalk = nil
    end
end

local optimizerEnabled = false

local function enableOptimizer()
    optimizerEnabled = true
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency < 1 then
            v.Material = Enum.Material.SmoothPlastic
            if v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0.5
            end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") 
            or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
end

local function disableOptimizer()
    optimizerEnabled = false
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0
        end
    end
    
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") 
            or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = true
        end
    end
end

local originalSky = nil

local function enableGalaxySkyBright()
    if originalSky == nil then
        originalSky = Lighting:FindFirstChildOfClass("Sky")
    end
    
    if originalSky then
        originalSky.Parent = nil
    end
    
    local newSky = Instance.new("Sky")
    newSky.Name = "GalaxySky"
    newSky.SkyboxBk = "rbxassetid://159454299"
    newSky.SkyboxDn = "rbxassetid://159454296"
    newSky.SkyboxFt = "rbxassetid://159454293"
    newSky.SkyboxLf = "rbxassetid://159454286"
    newSky.SkyboxRt = "rbxassetid://159454300"
    newSky.SkyboxUp = "rbxassetid://159454288"
    newSky.Parent = Lighting
    
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end

local function disableGalaxySkyBright()
    local galaxySky = Lighting:FindFirstChild("GalaxySky")
    if galaxySky then
        galaxySky:Destroy()
    end
    
    if originalSky then
        originalSky.Parent = Lighting
    end
    
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    Lighting.Brightness = 1
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    Connections.batAimbot = RunService.Heartbeat:Connect(function()
        if not Enabled.BatAimbot then return end
        local nearest = getNearestPlayer()
        if not nearest or not nearest.Character then return end
        local targetHrp = nearest.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end
        
        local c = Player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local lookVector = (targetHrp.Position - hrp.Position).Unit
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + lookVector)
    end)
end

local function stopBatAimbot()
    if Connections.batAimbot then
        Connections.batAimbot:Disconnect()
        Connections.batAimbot = nil
    end
end

local function startAutoWalk()
    if Connections.autoWalk then return end
    Connections.autoWalk = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h:Move(Vector3.new(-1, 0, 0), false)
        end
    end)
end

local function stopAutoWalk()
    if Connections.autoWalk then
        Connections.autoWalk:Disconnect()
        Connections.autoWalk = nil
    end
end

local function startAutoRight()
    if Connections.autoRight then return end
    Connections.autoRight = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h:Move(Vector3.new(1, 0, 0), false)
        end
    end)
end

local function stopAutoRight()
    if Connections.autoRight then
        Connections.autoRight:Disconnect()
        Connections.autoRight = nil
    end
end

-- GUI Creation
local guiScale = 1
local C = {
    bg = Color3.fromRGB(20, 20, 25),
    bgLight = Color3.fromRGB(30, 30, 35),
    accent = Color3.fromRGB(100, 150, 255),
    purple = Color3.fromRGB(130, 80, 200),
    success = Color3.fromRGB(50, 200, 100),
    danger = Color3.fromRGB(255, 80, 80),
    text = Color3.fromRGB(240, 240, 240),
    textDim = Color3.fromRGB(150, 150, 160)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DuelsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = game:GetService("CoreGui")
end

local main = Instance.new("Frame", ScreenGui)
main.Name = "MainFrame"
main.Size = UDim2.new(0, 660 * guiScale, 0, 670 * guiScale)
main.Position = UDim2.new(0.5, -330 * guiScale, 0.5, -335 * guiScale)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.ZIndex = 1
main.Active = true
main.Draggable = true

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 16 * guiScale)

local shadow = Instance.new("ImageLabel", main)
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 40 * guiScale, 1, 40 * guiScale)
shadow.Position = UDim2.new(0, -20 * guiScale, 0, -20 * guiScale)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554236805"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(23, 23, 277, 277)
shadow.ZIndex = 0

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 60 * guiScale)
header.BackgroundColor3 = C.bgLight
header.BorderSizePixel = 0
header.ZIndex = 2

local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 16 * guiScale)

local headerCover = Instance.new("Frame", header)
headerCover.Size = UDim2.new(1, 0, 0, 30 * guiScale)
headerCover.Position = UDim2.new(0, 0, 1, -30 * guiScale)
headerCover.BackgroundColor3 = C.bgLight
headerCover.BorderSizePixel = 0
headerCover.ZIndex = 2

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -20 * guiScale, 1, 0)
title.Position = UDim2.new(0, 20 * guiScale, 0, 0)
title.BackgroundTransparency = 1
title.Text = "22's DUELS SCRIPT"
title.TextColor3 = C.text
title.Font = Enum.Font.GothamBold
title.TextSize = 24 * guiScale
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3

local divider = Instance.new("Frame", main)
divider.Size = UDim2.new(0, 2 * guiScale, 1, -80 * guiScale)
divider.Position = UDim2.new(0.5, -1 * guiScale, 0, 70 * guiScale)
divider.BackgroundColor3 = C.bgLight
divider.BorderSizePixel = 0
divider.ZIndex = 2

local leftSide = Instance.new("Frame", main)
leftSide.Size = UDim2.new(0.5, -10 * guiScale, 1, -80 * guiScale)
leftSide.Position = UDim2.new(0, 5 * guiScale, 0, 70 * guiScale)
leftSide.BackgroundTransparency = 1
leftSide.ZIndex = 2

local rightSide = Instance.new("Frame", main)
rightSide.Size = UDim2.new(0.5, -10 * guiScale, 1, -80 * guiScale)
rightSide.Position = UDim2.new(0.5, 5 * guiScale, 0, 70 * guiScale)
rightSide.BackgroundTransparency = 1
rightSide.ZIndex = 2

local VisualSetters = {}
local SliderSetters = {}
local KeyButtons = {}

local function createToggle(parent, yPos, labelText, enabledKey, callback, customColor)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10 * guiScale, 0, 40 * guiScale)
    frame.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 3
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -60 * guiScale, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    
    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0, 50 * guiScale, 0, 24 * guiScale)
    toggle.Position = UDim2.new(1, -50 * guiScale, 0.5, -12 * guiScale)
    toggle.BackgroundColor3 = C.bgLight
    toggle.Text = ""
    toggle.ZIndex = 3
    
    local toggleCorner = Instance.new("UICorner", toggle)
    toggleCorner.CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame", toggle)
    indicator.Size = UDim2.new(0, 18 * guiScale, 0, 18 * guiScale)
    indicator.Position = UDim2.new(0, 3 * guiScale, 0.5, -9 * guiScale)
    indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    indicator.ZIndex = 4
    
    local indicatorCorner = Instance.new("UICorner", indicator)
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    
    local state = Enabled[enabledKey] or false
    
    local function updateVisual(newState, instant)
        state = newState
        local targetColor = newState and (customColor or C.accent) or C.bgLight
        local targetPos = newState and UDim2.new(1, -21 * guiScale, 0.5, -9 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -9 * guiScale)
        local targetIndColor = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        
        if instant then
            toggle.BackgroundColor3 = targetColor
            indicator.Position = targetPos
            indicator.BackgroundColor3 = targetIndColor
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = targetIndColor}):Play()
        end
    end
    
    updateVisual(state, true)
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        updateVisual(state, false)
        callback(state)
    end)
    
    VisualSetters[enabledKey] = updateVisual
    
    return frame
end

local function createToggleWithKey(parent, yPos, labelText, keybindKey, enabledKey, callback, customColor)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10 * guiScale, 0, 40 * guiScale)
    frame.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 3
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -110 * guiScale, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    
    local keyBtn = Instance.new("TextButton", frame)
    keyBtn.Size = UDim2.new(0, 45 * guiScale, 0, 24 * guiScale)
    keyBtn.Position = UDim2.new(1, -100 * guiScale, 0.5, -12 * guiScale)
    keyBtn.BackgroundColor3 = C.bgLight
    keyBtn.Text = KEYBINDS[keybindKey].Name
    keyBtn.TextColor3 = C.text
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11 * guiScale
    keyBtn.ZIndex = 3
    
    local keyCorner = Instance.new("UICorner", keyBtn)
    keyCorner.CornerRadius = UDim.new(0, 6 * guiScale)
    
    KeyButtons[keybindKey] = keyBtn
    
    keyBtn.MouseButton1Click:Connect(function()
        keyBtn.Text = "..."
        waitingForKeybind = keybindKey
    end)
    
    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0, 50 * guiScale, 0, 24 * guiScale)
    toggle.Position = UDim2.new(1, -50 * guiScale, 0.5, -12 * guiScale)
    toggle.BackgroundColor3 = C.bgLight
    toggle.Text = ""
    toggle.ZIndex = 3
    
    local toggleCorner = Instance.new("UICorner", toggle)
    toggleCorner.CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame", toggle)
    indicator.Size = UDim2.new(0, 18 * guiScale, 0, 18 * guiScale)
    indicator.Position = UDim2.new(0, 3 * guiScale, 0.5, -9 * guiScale)
    indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    indicator.ZIndex = 4
    
    local indicatorCorner = Instance.new("UICorner", indicator)
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    
    local state = Enabled[enabledKey] or false
    
    local function updateVisual(newState, instant)
        state = newState
        local targetColor = newState and (customColor or C.accent) or C.bgLight
        local targetPos = newState and UDim2.new(1, -21 * guiScale, 0.5, -9 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -9 * guiScale)
        local targetIndColor = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        
        if instant then
            toggle.BackgroundColor3 = targetColor
            indicator.Position = targetPos
            indicator.BackgroundColor3 = targetIndColor
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = targetPos, BackgroundColor3 = targetIndColor}):Play()
        end
    end
    
    updateVisual(state, true)
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        updateVisual(state, false)
        callback(state)
    end)
    
    VisualSetters[enabledKey] = updateVisual
    
    return frame
end

local function createSlider(parent, yPos, labelText, minVal, maxVal, valueKey, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10 * guiScale, 0, 50 * guiScale)
    frame.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 3
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -60 * guiScale, 0, 20 * guiScale)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    
    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0, 50 * guiScale, 0, 20 * guiScale)
    valueLabel.Position = UDim2.new(1, -50 * guiScale, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(Values[valueKey] or minVal)
    valueLabel.TextColor3 = C.accent
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13 * guiScale
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 3
    
    local sliderBg = Instance.new("Frame", frame)
    sliderBg.Size = UDim2.new(1, 0, 0, 6 * guiScale)
    sliderBg.Position = UDim2.new(0, 0, 0, 30 * guiScale)
    sliderBg.BackgroundColor3 = C.bgLight
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 3
    
    local sliderBgCorner = Instance.new("UICorner", sliderBg)
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.accent
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 4
    
    local sliderFillCorner = Instance.new("UICorner", sliderFill)
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    
    local sliderButton = Instance.new("TextButton", sliderBg)
    sliderButton.Size = UDim2.new(1, 0, 1, 10 * guiScale)
    sliderButton.Position = UDim2.new(0, 0, 0, -5 * guiScale)
    sliderButton.BackgroundTransparency = 1
    sliderButton.Text = ""
    sliderButton.ZIndex = 5
    
    local currentValue = Values[valueKey] or minVal
    
    local function setValue(val)
        val = math.clamp(val, minVal, maxVal)
        currentValue = math.floor(val)
        Values[valueKey] = currentValue
        valueLabel.Text = tostring(currentValue)
        
        local percent = (currentValue - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        
        callback(currentValue)
    end
    
    setValue(currentValue)
    
    local dragging = false
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = sliderBg.AbsolutePosition.X
            local sliderSize = sliderBg.AbsoluteSize.X
            local percent = math.clamp((mousePos.X - sliderPos) / sliderSize, 0, 1)
            local newValue = minVal + (maxVal - minVal) * percent
            setValue(newValue)
        end
    end)
    
    SliderSetters[valueKey] = setValue
    
    return frame
end

-- Left side toggles
createToggleWithKey(leftSide, 0, "Speed Boost", "SPEED", "SpeedBoost", function(s)
    Enabled.SpeedBoost = s
    if s then startSpeedBoost() else stopSpeedBoost() end
end)
_G.setSpeedVisual = VisualSetters.SpeedBoost

createSlider(leftSide, 52, "Speed Value", 16, 100, "BoostSpeed", function(v) Values.BoostSpeed = v end)

createToggle(leftSide, 112, "Auto Disable Speed", "AutoDisableSpeed", function(s)
    Enabled.AutoDisableSpeed = s
end)

createToggle(leftSide, 164, "Anti-Ragdoll", "AntiRagdoll", function(s)
    Enabled.AntiRagdoll = s
    if s then startAntiRagdoll() else stopAntiRagdoll() end
end)

createToggleWithKey(leftSide, 216, "Spin Bot", "SPIN", "SpinBot", function(s)
    Enabled.SpinBot = s
    if s then startSpinBot() else stopSpinBot() end
end, Color3.fromRGB(255, 150, 50))
_G.setSpinVisual = VisualSetters.SpinBot

createSlider(leftSide, 268, "Spin Speed", 10, 100, "SpinSpeed", function(v)
    Values.SpinSpeed = v
    if spinBAV then spinBAV.AngularVelocity = Vector3.new(0, v, 0) end
end)

createToggle(leftSide, 328, "Auto Steal", "AutoSteal", function(s)
    Enabled.AutoSteal = s
    if s then startAutoSteal() else stopAutoSteal() end
end)

createToggle(leftSide, 380, "Spam Bat", "SpamBat", function(s)
    Enabled.SpamBat = s
    if s then startSpamBat() else stopSpamBat() end
end)

createToggleWithKey(leftSide, 432, "Bat Aimbot", "BATAIMBOT", "BatAimbot", function(s)
    Enabled.BatAimbot = s
    if s then startBatAimbot() else stopBatAimbot() end
end, C.danger)

createToggle(leftSide, 484, "Galaxy Sky Bright", "GalaxySkyBright", function(s)
    Enabled.GalaxySkyBright = s
    if s then enableGalaxySkyBright() else disableGalaxySkyBright() end
end, Color3.fromRGB(180, 80, 255))

-- Right side toggles
createToggleWithKey(rightSide, 0, "Galaxy Mode", "GALAXY", "Galaxy", function(s)
    Enabled.Galaxy = s
    if s then startGalaxy() else stopGalaxy() end
end, Color3.fromRGB(60, 130, 255))
_G.setGalaxyVisual = VisualSetters.Galaxy

createSlider(rightSide, 52, "Gravity %", 25, 130, "GalaxyGravityPercent", function(v)
    Values.GalaxyGravityPercent = v
    if galaxyEnabled then adjustGalaxyJump() end
end)

createSlider(rightSide, 112, "Hop Power", 10, 80, "HOP_POWER", function(v) Values.HOP_POWER = v end)

createToggle(rightSide, 172, "Speed While Stealing", "SpeedWhileStealing", function(s)
    Enabled.SpeedWhileStealing = s
    if s then startSpeedWhileStealing() else stopSpeedWhileStealing() end
end)

createSlider(rightSide, 224, "Steal Speed", 10, 35, "StealingSpeedValue", function(v) Values.StealingSpeedValue = v end)

createToggle(rightSide, 284, "Unwalk", "Unwalk", function(s)
    Enabled.Unwalk = s
    if s then startUnwalk() else stopUnwalk() end
end)

createToggle(rightSide, 336, "Optimizer + XRay", "Optimizer", function(s)
    Enabled.Optimizer = s
    if s then enableOptimizer() else disableOptimizer() end
end)

createToggleWithKey(rightSide, 388, "Auto Left", "AUTOLEFT", "AutoWalkEnabled", function(s)
    AutoWalkEnabled = s
    Enabled.AutoWalkEnabled = s
    if s then startAutoWalk() else stopAutoWalk() end
end, Color3.fromRGB(100, 150, 255))
_G.setAutoLeftVisual = VisualSetters.AutoWalkEnabled

createToggleWithKey(rightSide, 440, "Auto Right", "AUTORIGHT", "AutoRightEnabled", function(s)
    AutoRightEnabled = s
    Enabled.AutoRightEnabled = s
    if s then startAutoRight() else stopAutoRight() end
end, Color3.fromRGB(100, 220, 180))
_G.setAutoRightVisual = VisualSetters.AutoRightEnabled

-- Save Button
local SaveBtn = Instance.new("TextButton", rightSide)
SaveBtn.Size = UDim2.new(1, -10 * guiScale, 0, 50 * guiScale)
SaveBtn.Position = UDim2.new(0, 5 * guiScale, 0, 503 * guiScale)
SaveBtn.BackgroundColor3 = C.purple
SaveBtn.Text = "SAVE CONFIG"
SaveBtn.TextColor3 = Color3.new(1, 1, 1)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 15 * guiScale
SaveBtn.ZIndex = 3
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 12 * guiScale)

SaveBtn.MouseButton1Click:Connect(function()
    local success = SaveConfig()
    if success then
        SaveBtn.Text = "SAVED!"
        SaveBtn.BackgroundColor3 = C.success
    else
        SaveBtn.Text = "FAILED"
        SaveBtn.BackgroundColor3 = C.danger
    end
    task.delay(1.5, function()
        SaveBtn.Text = "SAVE CONFIG"
        SaveBtn.BackgroundColor3 = C.purple
    end)
end)

local infoLabel = Instance.new("TextLabel", leftSide)
infoLabel.Size = UDim2.new(1, 0, 0, 40 * guiScale)
infoLabel.Position = UDim2.new(0, 0, 0, 540 * guiScale)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "V=Speed | N=Spin | M=Galaxy | X=Aimbot\nZ=AutoLeft | C=AutoRight | Q=Nuke | U=GUI"
infoLabel.TextColor3 = C.textDim
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 9 * guiScale
infoLabel.ZIndex = 3

local guiVisible = true

-- Apply loaded config (delayed to prevent character reset)
task.spawn(function()
    task.wait(3)
    
    local c = Player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then
        c = Player.CharacterAdded:Wait()
        task.wait(1)
    end
    
    for key, btn in pairs(KeyButtons) do
        if btn and KEYBINDS[key] then
            btn.Text = KEYBINDS[key].Name
        end
    end
    
    for key, setter in pairs(VisualSetters) do
        if Enabled[key] then
            setter(true, true)
        end
    end
    
    for key, setter in pairs(SliderSetters) do
        if Values[key] then
            setter(Values[key])
        end
    end
    
    if Enabled.AntiRagdoll then startAntiRagdoll() end
    if Enabled.AutoSteal then startAutoSteal() end
    if Enabled.Optimizer then enableOptimizer() end
    if Enabled.GalaxySkyBright then enableGalaxySkyBright() end
    
    task.wait(0.5)
    
    if Enabled.SpeedBoost then startSpeedBoost() end
    if Enabled.SpinBot then startSpinBot() end
    if Enabled.SpamBat then startSpamBat() end
    if Enabled.BatAimbot then startBatAimbot() end
    if Enabled.Galaxy then startGalaxy() end
    if Enabled.SpeedWhileStealing then startSpeedWhileStealing() end
    if Enabled.Unwalk then startUnwalk() end
    if Enabled.AutoWalkEnabled then AutoWalkEnabled = true startAutoWalk() end
    if Enabled.AutoRightEnabled then AutoRightEnabled = true startAutoRight() end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if waitingForKeybind and input.KeyCode ~= Enum.KeyCode.Unknown then
        local k = input.KeyCode
        KEYBINDS[waitingForKeybind] = k
        if KeyButtons[waitingForKeybind] then
            KeyButtons[waitingForKeybind].Text = k.Name
        end
        waitingForKeybind = nil
        return
    end
    
    if input.KeyCode == Enum.KeyCode.U then
        guiVisible = not guiVisible
        main.Visible = guiVisible
        return
    end
    
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = true
        return
    end
    
    if input.KeyCode == KEYBINDS.SPEED then
        Enabled.SpeedBoost = not Enabled.SpeedBoost
        if VisualSetters.SpeedBoost then VisualSetters.SpeedBoost(Enabled.SpeedBoost) end
        if Enabled.SpeedBoost then startSpeedBoost() else stopSpeedBoost() end
    end
    
    if input.KeyCode == KEYBINDS.SPIN then
        Enabled.SpinBot = not Enabled.SpinBot
        if VisualSetters.SpinBot then VisualSetters.SpinBot(Enabled.SpinBot) end
        if Enabled.SpinBot then startSpinBot() else stopSpinBot() end
    end
    
    if input.KeyCode == KEYBINDS.GALAXY then
        Enabled.Galaxy = not Enabled.Galaxy
        if VisualSetters.Galaxy then VisualSetters.Galaxy(Enabled.Galaxy) end
        if Enabled.Galaxy then startGalaxy() else stopGalaxy() end
    end
    
    if input.KeyCode == KEYBINDS.BATAIMBOT then
        Enabled.BatAimbot = not Enabled.BatAimbot
        if VisualSetters.BatAimbot then VisualSetters.BatAimbot(Enabled.BatAimbot) end
        if Enabled.BatAimbot then startBatAimbot() else stopBatAimbot() end
    end
    
    if input.KeyCode == KEYBINDS.NUKE then
        local n = getNearestPlayer()
        if n then INSTANT_NUKE(n) end
    end
    
    if input.KeyCode == KEYBINDS.AUTOLEFT then
        AutoWalkEnabled = not AutoWalkEnabled
        Enabled.AutoWalkEnabled = AutoWalkEnabled
        if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(AutoWalkEnabled) end
        if AutoWalkEnabled then startAutoWalk() else stopAutoWalk() end
    end
    
    if input.KeyCode == KEYBINDS.AUTORIGHT then
        AutoRightEnabled = not AutoRightEnabled
        Enabled.AutoRightEnabled = AutoRightEnabled
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end
        if AutoRightEnabled then startAutoRight() else stopAutoRight() end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        spaceHeld = false
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot then stopSpinBot() task.wait(0.1) startSpinBot() end
    if Enabled.Galaxy then setupGalaxyForce() adjustGalaxyJump() end
    if Enabled.SpamBat then stopSpamBat() task.wait(0.1) startSpamBat() end
    if Enabled.BatAimbot then stopBatAimbot() task.wait(0.1) startBatAimbot() end
    if Enabled.Unwalk then startUnwalk() end
end)
