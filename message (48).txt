loadstring(game:HttpGet("https://pastefy.app/bthqN3E4/raw"))()

task.wait(0.1)
-- ============================================================
-- 22S DUELS - BLUE EDITION + FAST ESP
-- discord.gg/22s
-- ============================================================

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
    if spinBAV then spinBAV:Destroy() spinBAV = nil end
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

-- ================================================================
-- ================================================================
local AutoWalkEnabled = false
local AutoRightEnabled = false

RunService.Heartbeat:Connect(function()
    if Enabled.SpinBot and spinBAV then
        if Player:GetAttribute("Stealing") then
            spinBAV.AngularVelocity = Vector3.new(0, 0, 0)
        else
            spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
        end
    end
end)

-- Bat Aimbot (no radius limit, NO auto swing, purple line, smooth movement)
local aimbotTarget = nil

local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if Connections.batAimbot then return end
    
    Connections.batAimbot = RunService.Heartbeat:Connect(function(dt)
        if not Enabled.BatAimbot then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        -- Equip bat if not equipped (no swinging)
        local bat = findBat()
        if bat and bat.Parent ~= c then
            hum:EquipTool(bat)
        end
        
        -- Find target
        local target, dist, torso = findNearestEnemy(h)
        aimbotTarget = torso or target
        
        if target and torso then
            local dir = (torso.Position - h.Position)
            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            local flatDist = flatDir.Magnitude
            local spd = 55 -- Fixed aimbot speed
            
            if flatDist > 1.5 then
                local moveDir = flatDir.Unit
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * spd, h.AssemblyLinearVelocity.Y, moveDir.Z * spd)
            else
                local tv = target.AssemblyLinearVelocity
                h.AssemblyLinearVelocity = Vector3.new(tv.X, h.AssemblyLinearVelocity.Y, tv.Z)
            end
        end
    end)
end

local function stopBatAimbot()
    if Connections.batAimbot then
        Connections.batAimbot:Disconnect()
        Connections.batAimbot = nil
    end
    aimbotTarget = nil
end



-- Galaxy Mode
local galaxyVectorForce = nil
local galaxyAttachment = nil
local galaxyEnabled = false
local hopsEnabled = false
local lastHopTime = 0
local spaceHeld = false
local originalJumpPower = 50

-- Capture original jump power safely when character is ready
local function captureJumpPower()
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower > 0 then
            originalJumpPower = hum.JumpPower
        end
    end
end

-- Capture on current character
task.spawn(function()
    task.wait(1)
    captureJumpPower()
end)

-- Recapture when character respawns
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    captureJumpPower()
end)

local function setupGalaxyForce()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment then galaxyAttachment:Destroy() end
        galaxyAttachment = Instance.new("Attachment")
        galaxyAttachment.Parent = h
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0, 0, 0)
        galaxyVectorForce.Parent = h
    end)
end

local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = Player.Character
    if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            mass = mass + p:GetMass()
        end
    end
    local tg = Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)
    galaxyVectorForce.Force = Vector3.new(0, mass * (Values.DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function adjustGalaxyJump()
    pcall(function()
        local c = Player.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if not galaxyEnabled then
            hum.JumpPower = originalJumpPower
            return
        end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)) / Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower * ratio
    end)
end

local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if tick() - lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, Values.HOP_POWER, h.AssemblyLinearVelocity.Z)
        end
    end)
end

local function startGalaxy()
    galaxyEnabled = true
    hopsEnabled = true
    setupGalaxyForce()
    adjustGalaxyJump()
end

local function stopGalaxy()
    galaxyEnabled = false
    hopsEnabled = false
    if galaxyVectorForce then
        galaxyVectorForce:Destroy()
        galaxyVectorForce = nil
    end
    if galaxyAttachment then
        galaxyAttachment:Destroy()
        galaxyAttachment = nil
    end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then
        doMiniHop()
    end
    if galaxyEnabled then
        updateGalaxyForce()
    end
end)

local function getMovementDirection()
    local c = Player.Character
    if not c then return Vector3.zero end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum and hum.MoveDirection or Vector3.zero
end

local function isOnEnemyPlot()
    local character = Player.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local playerPos = hrp.Position
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    
    for _, plot in ipairs(plots:GetChildren()) do
        local isMyPlot = false
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local yourBase = sign:FindFirstChild("YourBase")
            if yourBase and yourBase:IsA("BillboardGui") then 
                isMyPlot = yourBase.Enabled == true 
            end
        end
        
        if not isMyPlot then
            local plotPart = plot:FindFirstChild("Plot") or plot:FindFirstChildWhichIsA("BasePart")
            if plotPart and plotPart:IsA("BasePart") then
                local plotPos, plotSize = plotPart.Position, plotPart.Size
                if math.abs(playerPos.X - plotPos.X) <= plotSize.X/2 + 5 and 
                   math.abs(playerPos.Z - plotPos.Z) <= plotSize.Z/2 + 5 then 
                    return true 
                end
            end
            
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    local base = podium:FindFirstChild("Base")
                    if base then
                        local spawn = base:FindFirstChild("Spawn")
                        if spawn and (spawn.Position - playerPos).Magnitude <= 25 then 
                            return true 
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Auto walk/right destination coordinates (forward declared for speed boost check)
local POSITION_2 = Vector3.new(-483.12, -4.95, 94.80)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)
local autoWalkPhase = 1
local autoRightPhase = 1

local function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        pcall(function()
            local c = Player.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then return end
            local md = getMovementDirection()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity = Vector3.new(md.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, md.Z * Values.BoostSpeed)
            end
        end)
    end)
end

local function stopSpeedBoost()
    if Connections.speed then
        Connections.speed:Disconnect()
        Connections.speed = nil
    end
end

-- ============================================
-- AUTO LEFT / AUTO RIGHT COORDINATE ESP
-- Small precise markers at exact positions
-- ============================================
local coordESPFolder = Instance.new("Folder", workspace)
coordESPFolder.Name = "22s_CoordESP"

local function createCoordMarker(position, labelText, color)
    -- Small dot at exact position
    local dot = Instance.new("Part", coordESPFolder)
    dot.Name = "CoordMarker_" .. labelText
    dot.Anchored = true
    dot.CanCollide = false
    dot.CastShadow = false
    dot.Material = Enum.Material.Neon
    dot.Color = color
    dot.Shape = Enum.PartType.Ball
    dot.Size = Vector3.new(1, 1, 1)
    dot.Position = position
    dot.Transparency = 0.2

    -- Small billboard label
    local bb = Instance.new("BillboardGui", dot)
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.MaxDistance = 300

    local text = Instance.new("TextLabel", bb)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = labelText
    text.TextColor3 = color
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextStrokeTransparency = 0
    text.Font = Enum.Font.GothamBold
    text.TextSize = 12
    text.TextScaled = false

    return dot
end

-- Create markers at exact coordinates
createCoordMarker(Vector3.new(-476.48, -6.28, 92.73), "L1", Color3.fromRGB(100, 150, 255))
createCoordMarker(Vector3.new(-483.12, -4.95, 94.80), "L END", Color3.fromRGB(60, 130, 255))
createCoordMarker(Vector3.new(-476.16, -6.52, 25.62), "R1", Color3.fromRGB(100, 220, 180))
createCoordMarker(Vector3.new(-483.04, -5.09, 23.14), "R END", Color3.fromRGB(50, 200, 150))

-- Auto Walk
local autoWalkConnection = nil
local POSITION_1 = Vector3.new(-476.48, -6.28, 92.73)

local autoRightConnection = nil
local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)

local function faceSouth()
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, 0, 0)
    local camera = workspace.CurrentCamera
    if camera then
        local camDistance = 12
        local camHeight = 5
        local charPos = h.Position
        camera.CFrame = CFrame.new(charPos.X, charPos.Y + camHeight, charPos.Z - camDistance) * CFrame.Angles(math.rad(-15), 0, 0)
    end
end

local function faceNorth()
    local c = Player.Character
    if not c then return end
    local h = c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position) * CFrame.Angles(0, math.rad(180), 0)
    local camera = workspace.CurrentCamera
    if camera then
        local camDistance = 12
        local charPos = h.Position
        camera.CFrame = CFrame.new(charPos.X, charPos.Y + 2, charPos.Z + camDistance) * CFrame.Angles(0, math.rad(180), 0)
    end
end

local function startAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() end
    autoWalkPhase = 1
    
    autoWalkConnection = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        if autoWalkPhase == 1 then
            local targetPos = Vector3.new(POSITION_1.X, h.Position.Y, POSITION_1.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                autoWalkPhase = 2
                -- Immediately start moving to coord 2 this same frame
                local dir = (POSITION_2 - h.Position)
                local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
                hum:Move(moveDir, false)
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
                return
            end
            local dir = (POSITION_1 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
            
        elseif autoWalkPhase == 2 then
            local targetPos = Vector3.new(POSITION_2.X, h.Position.Y, POSITION_2.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoWalkEnabled = false
                Enabled.AutoWalkEnabled = false

                if _G.setAutoLeftVisual then _G.setAutoLeftVisual(false) end
                if VisualSetters and VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false, true) end
                if autoWalkConnection then autoWalkConnection:Disconnect() autoWalkConnection = nil end
                faceSouth()
                return
            end
            local dir = (POSITION_2 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
        end
    end)
end

local function stopAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() autoWalkConnection = nil end
    autoWalkPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
    end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase = 1
    
    autoRightConnection = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        if autoRightPhase == 1 then
            local targetPos = Vector3.new(POSITION_R1.X, h.Position.Y, POSITION_R1.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                autoRightPhase = 2
                local dir = (POSITION_R2 - h.Position)
                local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
                hum:Move(moveDir, false)
                h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
                return
            end
            local dir = (POSITION_R1 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
            
        elseif autoRightPhase == 2 then
            local targetPos = Vector3.new(POSITION_R2.X, h.Position.Y, POSITION_R2.Z)
            local dist = (targetPos - h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoRightEnabled = false
                Enabled.AutoRightEnabled = false

                if _G.setAutoRightVisual then _G.setAutoRightVisual(false) end
                if VisualSetters and VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false, true) end
                if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection = nil end
                faceNorth()
                return
            end
            local dir = (POSITION_R2 - h.Position)
            local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
            hum:Move(moveDir, false)
            h.AssemblyLinearVelocity = Vector3.new(moveDir.X * Values.BoostSpeed, h.AssemblyLinearVelocity.Y, moveDir.Z * Values.BoostSpeed)
        end
    end)
end

local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection = nil end
    autoRightPhase = 1
    local c = Player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
    end
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = Player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics or humState == Enum.HumanoidStateType.Ragdoll or humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if Player.Character then
                        local PlayerModule = Player.PlayerScripts:FindFirstChild("PlayerModule")
                        if PlayerModule then
                            local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                            Controls:Enable()
                        end
                    end
                end)
                if root then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if Connections.antiRagdoll then
        Connections.antiRagdoll:Disconnect()
        Connections.antiRagdoll = nil
    end
end

local function startSpeedWhileStealing()
    if Connections.speedWhileStealing then return end
    Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
        local c = Player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local md = getMovementDirection()
        if md.Magnitude > 0.1 then
            h.AssemblyLinearVelocity = Vector3.new(md.X * Values.StealingSpeedValue, h.AssemblyLinearVelocity.Y, md.Z * Values.StealingSpeedValue)
        end
    end)
end

local function stopSpeedWhileStealing()
    if Connections.speedWhileStealing then
        Connections.speedWhileStealing:Disconnect()
        Connections.speedWhileStealing = nil
    end
end

-- Auto Steal
local ProgressBarFill, ProgressLabel, ProgressPercentLabel, RadiusInput
local stealStartTime = nil
local progressConnection = nil
local StealData = {}

-- Discord text for progress bar
local DISCORD_TEXT = "discord.gg/22s"

local function getDiscordProgress(percent)
    local totalChars = #DISCORD_TEXT
    -- Speed up the text reveal - complete by 70% progress so it's visible longer
    local adjustedPercent = math.min(percent * 1.5, 100)
    local charsToShow = math.floor((adjustedPercent / 100) * totalChars)
    return string.sub(DISCORD_TEXT, 1, charsToShow)
end

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist < nd and dist <= Values.STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

local function ResetProgressBar()
    if ProgressLabel then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect() return end
        local prog = math.clamp((tick() - stealStartTime) / Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressPercentLabel then 
            local percent = math.floor(prog * 100)
            ProgressPercentLabel.Text = getDiscordProgress(percent)
        end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Values.STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p, _, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if Connections.autoSteal then
        Connections.autoSteal:Disconnect()
        Connections.autoSteal = nil
    end
    isStealing = false
    ResetProgressBar()
end

-- Unwalk
local savedAnimations = {}

local function startUnwalk()
    local c = Player.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then
        savedAnimations.Animate = anim:Clone()
        anim:Destroy()
    end
end

local function stopUnwalk()
    local c = Player.Character
    if c and savedAnimations.Animate then
        savedAnimations.Animate:Clone().Parent = c
        savedAnimations.Animate = nil
    end
end

-- Optimizer
local originalTransparency = {}
local xrayEnabled = false

local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.FogEnd = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
end

local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE = false end
    if xrayEnabled then
        for part, value in pairs(originalTransparency) do
            if part then part.LocalTransparencyModifier = value end
        end
        originalTransparency = {}
        xrayEnabled = false
    end
end

-- Galaxy Sky Bright
local originalSkybox = nil
local galaxySkyBright = nil
local galaxySkyBrightConn = nil
local galaxyPlanets = {}
local galaxyBloom = nil
local galaxyCC = nil

local function enableGalaxySkyBright()
    if galaxySkyBright then return end
    
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    
    galaxySkyBright = Instance.new("Sky")
    galaxySkyBright.SkyboxBk = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxDn = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxFt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxLf = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxRt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxUp = "rbxassetid://1534951537"
    galaxySkyBright.StarCount = 10000
    galaxySkyBright.CelestialBodiesShown = false
    galaxySkyBright.Parent = Lighting
    
    galaxyBloom = Instance.new("BloomEffect")
    galaxyBloom.Intensity = 1.5
    galaxyBloom.Size = 40
    galaxyBloom.Threshold = 0.8
    galaxyBloom.Parent = Lighting
    
    galaxyCC = Instance.new("ColorCorrectionEffect")
    galaxyCC.Saturation = 0.8
    galaxyCC.Contrast = 0.3
    galaxyCC.TintColor = Color3.fromRGB(200, 150, 255)
    galaxyCC.Parent = Lighting
    
    Lighting.Ambient = Color3.fromRGB(120, 60, 180)
    Lighting.Brightness = 3
    Lighting.ClockTime = 0
    
    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800 + i * 200, 800 + i * 200, 800 + i * 200)
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(140 + i * 20, 60 + i * 10, 200 + i * 15)
        p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i * 2) * (3000 + i * 500), 1500 + i * 300, math.sin(i * 2) * (3000 + i * 500))
        p.Parent = workspace
        table.insert(galaxyPlanets, p)
    end
    
    galaxySkyBrightConn = RunService.Heartbeat:Connect(function()
        if not Enabled.GalaxySkyBright then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(120 + math.sin(t) * 60, 50 + math.sin(t * 0.8) * 40, 180 + math.sin(t * 1.2) * 50)
        if galaxyBloom then
            galaxyBloom.Intensity = 1.2 + math.sin(t * 2) * 0.4
        end
    end)
end

local function disableGalaxySkyBright()
    if galaxySkyBrightConn then galaxySkyBrightConn:Disconnect() galaxySkyBrightConn = nil end
    if galaxySkyBright then galaxySkyBright:Destroy() galaxySkyBright = nil end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if galaxyBloom then galaxyBloom:Destroy() galaxyBloom = nil end
    if galaxyCC then galaxyCC:Destroy() galaxyCC = nil end
    for _, obj in ipairs(galaxyPlanets) do
        if obj then obj:Destroy() end
    end
    galaxyPlanets = {}
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
end

-- ============================================
-- GUI - CLEAN NO BOXES - MORE BLACK
-- ============================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local guiScale = isMobile and 0.4 or 1

local C = {
    bg = Color3.fromRGB(2, 2, 4),
    purple = Color3.fromRGB(60, 130, 255),
    purpleLight = Color3.fromRGB(100, 170, 255),
    purpleDark = Color3.fromRGB(30, 80, 200),
    purpleGlow = Color3.fromRGB(80, 150, 255),
    accent = Color3.fromRGB(60, 130, 255),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(100, 170, 255),
    success = Color3.fromRGB(34, 197, 94),
    danger = Color3.fromRGB(239, 68, 68),
    border = Color3.fromRGB(30, 60, 120)
}

local sg = Instance.new("ScreenGui")
sg.Name = "22S_BLUE"
sg.ResetOnSpawn = false
sg.Parent = Player.PlayerGui

local function playSound(id, vol, spd)
    pcall(function()
        local s = Instance.new("Sound", SoundService)
        s.SoundId = id
        s.Volume = vol or 0.3
        s.PlaybackSpeed = spd or 1
        s:Play()
        game:GetService("Debris"):AddItem(s, 1)
    end)
end

-- Progress Bar
local progressBar = Instance.new("Frame", sg)
progressBar.Size = UDim2.new(0, 420 * guiScale, 0, 56 * guiScale)
progressBar.Position = UDim2.new(0.5, -210 * guiScale, 1, -168 * guiScale)
progressBar.BackgroundColor3 = Color3.fromRGB(2, 2, 4)
progressBar.BorderSizePixel = 0
progressBar.ClipsDescendants = true
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 14 * guiScale)

local pStroke = Instance.new("UIStroke", progressBar)
pStroke.Thickness = 2
local pGrad = Instance.new("UIGradient", pStroke)
pGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 170, 255)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})

task.spawn(function()
    local r = 0
    while progressBar.Parent do
        r = (r + 3) % 360
        pGrad.Rotation = r
        task.wait(0.02)
    end
end)

for i = 1, 12 do
    local ball = Instance.new("Frame", progressBar)
    ball.Size = UDim2.new(0, math.random(2, 3), 0, math.random(2, 3))
    ball.Position = UDim2.new(math.random(3, 97) / 100, 0, math.random(15, 85) / 100, 0)
    ball.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    ball.BackgroundTransparency = math.random(20, 50) / 100
    ball.BorderSizePixel = 0
    ball.ZIndex = 1
    Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        local startX = ball.Position.X.Scale
        local startY = ball.Position.Y.Scale
        local phase = math.random() * math.pi * 2
        while ball.Parent do
            local t = tick() + phase
            local newX = startX + math.sin(t * (0.5 + i * 0.1)) * 0.03
            local newY = startY + math.cos(t * (0.4 + i * 0.08)) * 0.05
            ball.Position = UDim2.new(math.clamp(newX, 0.02, 0.98), 0, math.clamp(newY, 0.1, 0.9), 0)
            ball.BackgroundTransparency = 0.3 + math.sin(t * 2) * 0.2
            task.wait(0.03)
        end
    end)
end

ProgressLabel = Instance.new("TextLabel", progressBar)
ProgressLabel.Size = UDim2.new(0.35, 0, 0.5, 0)
ProgressLabel.Position = UDim2.new(0, 10 * guiScale, 0, 0)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Text = "READY"
ProgressLabel.TextColor3 = C.text
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 14 * guiScale
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.ZIndex = 3

ProgressPercentLabel = Instance.new("TextLabel", progressBar)
ProgressPercentLabel.Size = UDim2.new(1, 0, 0.5, 0)
ProgressPercentLabel.BackgroundTransparency = 1
ProgressPercentLabel.Text = ""
ProgressPercentLabel.TextColor3 = C.purpleLight
ProgressPercentLabel.Font = Enum.Font.GothamBlack
ProgressPercentLabel.TextSize = 18 * guiScale
ProgressPercentLabel.TextXAlignment = Enum.TextXAlignment.Center
ProgressPercentLabel.ZIndex = 3

RadiusInput = Instance.new("TextBox", progressBar)
RadiusInput.Size = UDim2.new(0, 40 * guiScale, 0, 22 * guiScale)
RadiusInput.Position = UDim2.new(1, -50 * guiScale, 0, 2 * guiScale)
RadiusInput.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
RadiusInput.Text = tostring(Values.STEAL_RADIUS)
RadiusInput.TextColor3 = C.purpleLight
RadiusInput.Font = Enum.Font.GothamBold
RadiusInput.TextSize = 12 * guiScale
RadiusInput.ZIndex = 3
Instance.new("UICorner", RadiusInput).CornerRadius = UDim.new(0, 6 * guiScale)

RadiusInput.FocusLost:Connect(function()
    local n = tonumber(RadiusInput.Text)
    if n then
        Values.STEAL_RADIUS = math.clamp(math.floor(n), 5, 100)
        RadiusInput.Text = tostring(Values.STEAL_RADIUS)
    end
end)

local pTrack = Instance.new("Frame", progressBar)
pTrack.Size = UDim2.new(0.94, 0, 0, 8 * guiScale)
pTrack.Position = UDim2.new(0.03, 0, 1, -15 * guiScale)
pTrack.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
pTrack.ZIndex = 2
Instance.new("UICorner", pTrack).CornerRadius = UDim.new(1, 0)

ProgressBarFill = Instance.new("Frame", pTrack)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = C.purple
ProgressBarFill.ZIndex = 2
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(1, 0)

-- Main Window
local main = Instance.new("Frame", sg)
main.Name = "Main"
main.Size = UDim2.new(0, 560 * guiScale, 0, 740 * guiScale)
main.Position = isMobile and UDim2.new(0.5, -280 * guiScale, 0.5, -370 * guiScale) or UDim2.new(1, -580, 0, 20)
main.BackgroundColor3 = Color3.fromRGB(2, 2, 4)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 18 * guiScale)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", mainStroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 170, 255)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 130, 255)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 170, 255))
})

task.spawn(function()
    local r = 0
    while main.Parent do
        r = (r + 3) % 360
        strokeGrad.Rotation = r
        task.wait(0.02)
    end
end)

for i = 1, 60 do
    local ball = Instance.new("Frame", main)
    ball.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    ball.Position = UDim2.new(math.random(2, 98) / 100, 0, math.random(2, 98) / 100, 0)
    ball.BackgroundColor3 = Color3.fromRGB(100, 170, 255)
    ball.BackgroundTransparency = math.random(10, 40) / 100
    ball.BorderSizePixel = 0
    ball.ZIndex = 2
    Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        local startX = ball.Position.X.Scale
        local startY = ball.Position.Y.Scale
        local phase = math.random() * math.pi * 2
        local speedMult = 0.3 + math.random() * 0.4
        while ball.Parent do
            local t = tick() + phase
            local newX = startX + math.sin(t * speedMult) * 0.02
            local newY = startY + math.cos(t * speedMult * 0.8) * 0.015
            ball.Position = UDim2.new(math.clamp(newX, 0.01, 0.99), 0, math.clamp(newY, 0.01, 0.99), 0)
            ball.BackgroundTransparency = 0.2 + math.sin(t * 1.5 + phase) * 0.25
            task.wait(0.03)
        end
    end)
end

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 70 * guiScale)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.ZIndex = 0

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, 0, 0, 32 * guiScale)
titleLabel.Position = UDim2.new(0, 0, 0, 10 * guiScale)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "22S DUELS"
titleLabel.TextColor3 = C.text
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 28 * guiScale
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 5

local subtitleLabel = Instance.new("TextLabel", header)
subtitleLabel.Size = UDim2.new(1, 0, 0, 24 * guiScale)
subtitleLabel.Position = UDim2.new(0, 0, 0, 40 * guiScale)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "discord.gg/22s"
subtitleLabel.TextColor3 = C.purpleLight
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.TextSize = 16 * guiScale
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.ZIndex = 5

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 36 * guiScale, 0, 36 * guiScale)
closeBtn.Position = UDim2.new(1, -46 * guiScale, 0.5, -18 * guiScale)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = C.textDim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24 * guiScale
closeBtn.ZIndex = 5

closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = C.danger end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = C.textDim end)

local leftSide = Instance.new("Frame", main)
leftSide.Size = UDim2.new(0.48, 0, 0, 650 * guiScale)
leftSide.Position = UDim2.new(0.01, 0, 0, 75 * guiScale)
leftSide.BackgroundTransparency = 1
leftSide.BorderSizePixel = 0
leftSide.ClipsDescendants = true
leftSide.ZIndex = 2

local rightSide = Instance.new("Frame", main)
rightSide.Size = UDim2.new(0.48, 0, 0, 650 * guiScale)
rightSide.Position = UDim2.new(0.51, 0, 0, 75 * guiScale)
rightSide.BackgroundTransparency = 1
rightSide.BorderSizePixel = 0
rightSide.ClipsDescendants = true
rightSide.ZIndex = 2

VisualSetters = {}
local SliderSetters = {}
local KeyButtons = {}
local waitingForKeybind = nil

-- CLEAN TOGGLE WITH KEYBIND - No box, just text, key button and switch - SPACED OUT
local function createToggleWithKey(parent, yPos, labelText, keybindKey, enabledKey, callback, specialColor)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10 * guiScale, 0, 48 * guiScale)
    row.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.ZIndex = 3
    
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0, 36 * guiScale, 0, 28 * guiScale)
    keyBtn.Position = UDim2.new(0, 3 * guiScale, 0.5, -14 * guiScale)
    keyBtn.BackgroundColor3 = C.purple
    keyBtn.Text = KEYBINDS[keybindKey].Name
    keyBtn.TextColor3 = Color3.new(1, 1, 1)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11 * guiScale
    keyBtn.ZIndex = 4
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 8 * guiScale)
    
    KeyButtons[keybindKey] = keyBtn
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 45 * guiScale, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local onColor = specialColor or C.purple
    local defaultOn = Enabled[enabledKey]
    
    local toggleBg = Instance.new("Frame", row)
    toggleBg.Size = UDim2.new(0, 50 * guiScale, 0, 26 * guiScale)
    toggleBg.Position = UDim2.new(1, -58 * guiScale, 0.5, -13 * guiScale)
    toggleBg.BackgroundColor3 = defaultOn and onColor or Color3.fromRGB(25, 20, 35)
    toggleBg.ZIndex = 4
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local toggleCircle = Instance.new("Frame", toggleBg)
    toggleCircle.Size = UDim2.new(0, 20 * guiScale, 0, 20 * guiScale)
    toggleCircle.Position = defaultOn and UDim2.new(1, -23 * guiScale, 0.5, -10 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -10 * guiScale)
    toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    toggleCircle.ZIndex = 5
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    
    local clickBtn = Instance.new("TextButton", row)
    clickBtn.Size = UDim2.new(0.6, 0, 1, 0)
    clickBtn.Position = UDim2.new(0.4, 0, 0, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 6
    
    local isOn = defaultOn
    
    local function setVisual(state, skipCallback)
        isOn = state
        TweenService:Create(toggleBg, TweenInfo.new(0.3), {BackgroundColor3 = isOn and onColor or Color3.fromRGB(25, 20, 35)}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -23 * guiScale, 0.5, -10 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -10 * guiScale)}):Play()
        if not skipCallback then
            callback(isOn)
        end
    end
    
    VisualSetters[enabledKey] = setVisual
    
    clickBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Enabled[enabledKey] = isOn
        setVisual(isOn)
        playSound("rbxassetid://6895079813", 0.4, 1)
    end)
    
    keyBtn.MouseButton1Click:Connect(function()
        waitingForKeybind = keybindKey
        keyBtn.Text = "..."
        playSound("rbxassetid://6895079813", 0.3, 1.5)
    end)
    
    return row, enabledKey, function() return isOn end, setVisual, keyBtn
end

-- CLEAN TOGGLE - No box, just text and switch - SPACED OUT
local function createToggle(parent, yPos, labelText, enabledKey, callback, specialColor)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10 * guiScale, 0, 48 * guiScale)
    row.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.ZIndex = 3
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10 * guiScale, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local onColor = specialColor or C.purple
    local defaultOn = Enabled[enabledKey]
    
    local toggleBg = Instance.new("Frame", row)
    toggleBg.Size = UDim2.new(0, 50 * guiScale, 0, 26 * guiScale)
    toggleBg.Position = UDim2.new(1, -58 * guiScale, 0.5, -13 * guiScale)
    toggleBg.BackgroundColor3 = defaultOn and onColor or Color3.fromRGB(25, 20, 35)
    toggleBg.ZIndex = 4
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local toggleCircle = Instance.new("Frame", toggleBg)
    toggleCircle.Size = UDim2.new(0, 20 * guiScale, 0, 20 * guiScale)
    toggleCircle.Position = defaultOn and UDim2.new(1, -23 * guiScale, 0.5, -10 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -10 * guiScale)
    toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    toggleCircle.ZIndex = 5
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    
    local clickBtn = Instance.new("TextButton", row)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 6
    
    local isOn = defaultOn
    
    local function setVisual(state, skipCallback)
        isOn = state
        TweenService:Create(toggleBg, TweenInfo.new(0.3), {BackgroundColor3 = isOn and onColor or Color3.fromRGB(25, 20, 35)}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -23 * guiScale, 0.5, -10 * guiScale) or UDim2.new(0, 3 * guiScale, 0.5, -10 * guiScale)}):Play()
        if not skipCallback then
            callback(isOn)
        end
    end
    
    VisualSetters[enabledKey] = setVisual
    
    clickBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Enabled[enabledKey] = isOn
        setVisual(isOn)
        playSound("rbxassetid://6895079813", 0.4, 1)
    end)
    
    return row, enabledKey, function() return isOn end, setVisual
end

-- CLEAN SLIDER - No box - SPACED OUT
local function createSlider(parent, yPos, labelText, minVal, maxVal, valueKey, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10 * guiScale, 0, 56 * guiScale)
    container.Position = UDim2.new(0, 5 * guiScale, 0, yPos * guiScale)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ZIndex = 3
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, 0, 0, 20 * guiScale)
    label.Position = UDim2.new(0, 10 * guiScale, 0, 4 * guiScale)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = C.textDim
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12 * guiScale
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    
    local defaultVal = Values[valueKey]
    
    local valueInput = Instance.new("TextBox", container)
    valueInput.Size = UDim2.new(0, 50 * guiScale, 0, 22 * guiScale)
    valueInput.Position = UDim2.new(1, -58 * guiScale, 0, 2 * guiScale)
    valueInput.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    valueInput.Text = tostring(defaultVal)
    valueInput.TextColor3 = C.purpleLight
    valueInput.Font = Enum.Font.GothamBold
    valueInput.TextSize = 12 * guiScale
    valueInput.ClearTextOnFocus = false
    valueInput.ZIndex = 4
    Instance.new("UICorner", valueInput).CornerRadius = UDim.new(0, 6 * guiScale)
    
    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(0.92, 0, 0, 10 * guiScale)
    sliderBg.Position = UDim2.new(0.04, 0, 0, 32 * guiScale)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    sliderBg.ZIndex = 4
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderFill.BackgroundColor3 = C.purple
    sliderFill.ZIndex = 5
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local thumb = Instance.new("Frame", sliderBg)
    thumb.Size = UDim2.new(0, 16 * guiScale, 0, 16 * guiScale)
    thumb.Position = UDim2.new(pct, -8 * guiScale, 0.5, -8 * guiScale)
    thumb.BackgroundColor3 = Color3.new(1, 1, 1)
    thumb.ZIndex = 6
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    
    local sliderBtn = Instance.new("TextButton", sliderBg)
    sliderBtn.Size = UDim2.new(1, 0, 3, 0)
    sliderBtn.Position = UDim2.new(0, 0, -1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 7
    
    local dragging = false
    
    local function updateSlider(rel, skipCallback)
        rel = math.clamp(rel, 0, 1)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -8 * guiScale, 0.5, -8 * guiScale)
        local val = math.floor(minVal + (maxVal - minVal) * rel)
        valueInput.Text = tostring(val)
        Values[valueKey] = val
        if not skipCallback then
            callback(val)
        end
    end
    
    local function setSliderValue(val)
        val = math.clamp(val, minVal, maxVal)
        local rel = (val - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -8 * guiScale, 0.5, -8 * guiScale)
        valueInput.Text = tostring(val)
        Values[valueKey] = val
    end
    
    SliderSetters[valueKey] = setSliderValue
    
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X)
        end
    end)
    
    valueInput.FocusLost:Connect(function()
        local n = tonumber(valueInput.Text)
        if n then
            n = math.clamp(math.floor(n), minVal, maxVal)
            valueInput.Text = tostring(n)
            local r = (n - minVal) / (maxVal - minVal)
            sliderFill.Size = UDim2.new(r, 0, 1, 0)
            thumb.Position = UDim2.new(r, -8 * guiScale, 0.5, -8 * guiScale)
            Values[valueKey] = n
            callback(n)
        end
    end)
    
    return container, setSliderValue
end

-- Left side toggles - SPACED OUT LIKE BEFORE
createToggleWithKey(leftSide, 0, "Speed Boost", "SPEED", "SpeedBoost", function(s)
    Enabled.SpeedBoost = s
    if s then startSpeedBoost() else stopSpeedBoost() end
end)
_G.setSpeedVisual = VisualSetters.SpeedBoost

createSlider(leftSide, 52, "Boost Speed", 1, 70, "BoostSpeed", function(v) Values.BoostSpeed = v end)

createToggle(leftSide, 112, "Anti Ragdoll", "AntiRagdoll", function(s)
    Enabled.AntiRagdoll = s
    if s then startAntiRagdoll() else stopAntiRagdoll() end
end)

createToggleWithKey(leftSide, 216, "Spin Bot", "SPIN", "SpinBot", function(s)
    Enabled.SpinBot = s
    if s then startSpinBot() else stopSpinBot() end
end)

createSlider(leftSide, 268, "Spin Speed", 5, 50, "SpinSpeed", function(v) Values.SpinSpeed = v end)

createToggle(leftSide, 328, "Spam Bat", "SpamBat", function(s)
    Enabled.SpamBat = s
    if s then startSpamBat() else stopSpamBat() end
end)

createToggle(leftSide, 380, "Auto Steal", "AutoSteal", function(s)
    Enabled.AutoSteal = s
    if s then startAutoSteal() else stopAutoSteal() end
end)

createToggleWithKey(leftSide, 432, "Bat Aimbot", "BATAIMBOT", "BatAimbot", function(s)
    Enabled.BatAimbot = s
    if s then startBatAimbot() else stopBatAimbot() end
end, C.danger)

createToggle(leftSide, 484, "Galaxy Sky Bright", "GalaxySkyBright", function(s)
    Enabled.GalaxySkyBright = s
    if s then enableGalaxySkyBright() else disableGalaxySkyBright() end
end, Color3.fromRGB(180, 80, 255))

-- Right side toggles - SPACED OUT LIKE BEFORE
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
infoLabel.Position = UDim2.new(0, 0, 0, 600 * guiScale)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "V=Speed | N=Spin | M=Galaxy | X=Aimbot\nZ=AutoLeft | C=AutoRight | Q=Nuke | U=GUI"
infoLabel.TextColor3 = C.textDim
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 9 * guiScale
infoLabel.ZIndex = 3

local guiVisible = true

-- Apply loaded config (delayed to prevent character reset)
task.spawn(function()
    task.wait(3) -- Wait longer to ensure character is fully loaded and physics settled
    
    -- Make sure character exists
    local c = Player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then
        c = Player.CharacterAdded:Wait()
        task.wait(1)
    end
    
    -- Update keybind buttons
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
    
    -- Start features that don't affect physics first
    if Enabled.AntiRagdoll then startAntiRagdoll() end
    if Enabled.AutoSteal then startAutoSteal() end
    if Enabled.Optimizer then enableOptimizer() end
    if Enabled.GalaxySkyBright then enableGalaxySkyBright() end
    
    task.wait(0.5)
    
    -- Then start physics features
    if Enabled.SpeedBoost then startSpeedBoost() end
    if Enabled.SpinBot then startSpinBot() end
    if Enabled.SpamBat then startSpamBat() end
    if Enabled.BatAimbot then startBatAimbot() end
    if Enabled.Galaxy then startGalaxy() end
    if Enabled.SpeedWhileStealing then startSpeedWhileStealing() end
    if Enabled.Unwalk then startUnwalk() end
    if Enabled.AutoWalkEnabled then AutoWalkEnabled = true startAutoWalk() end
    if Enabled.AutoRightEnabled then AutoRightEnabled = true startAutoRight() end
    
    if configLoaded then
        -- Config loaded silently
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Handle keybind changes
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