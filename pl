-- Missspread its just for legit stuff like for example lets say your hitchance is 50 itll miss 50% of the time but if you want people to believe your actually shooting missspread makes it so it LOOKS like your missing because your missing next to them but not actually hitting them its crazy >~<

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Teams = game:GetService("Teams")

local guardsTeam = Teams:FindFirstChild("Guards")
local inmatesTeam = Teams:FindFirstChild("Inmates")
local criminalsTeam = Teams:FindFirstChild("Criminals")

local cfg = {
    enabled = true, -- toggle the whole script on/off
    teamcheck = true, -- dont shoot people on your team
    wallcheck = true, -- dont shoot through walls
    deathcheck = true, -- skip dead players
    ffcheck = true, -- skip players with forcefield
    hostilecheck = true, -- only shoot hostile inmates 💢 (guards only)
    trespasscheck = false, -- only shoot trespassing inmates 🔗 (guards only)
    vehiclecheck = true, -- dont shoot people sitting in cars
    criminalsnoinnmates = true, -- criminals wont shoot inmates
    inmatesnocriminals = true, -- inmates wont shoot criminals
    shieldbreaker = true, -- target shields to break them instead of being blocked
    shieldfrontangle = 0.3, -- (DONT CHANGE) how wide the shield covers (-1 to 1, lower = wider, 0.3 = ~70 degrees)
    shieldrandomhead = true, -- randomly hit head instead of shield sometimes (more legit)
    shieldheadchance = 30, -- percent chance to hit head instead of shield (0-100)
    taserbypasshostile = false, -- taser ignores hostile check
    taserbypasstrespass = false, -- taser ignores trespass check
    taseralwayshit = true, -- taser never misses
    ifplayerstill = false, -- always hit if player isnt moving
    stillthreshold = 0.5, -- how slow they gotta be to count as still
    hitchance = 40, -- percent chance to actually hit (0-100)
    hitchanceAutoOnly = false, -- only apply hitchance to automatic weapons (shotguns always hit)
    autoshoot = false, -- automatically shoot when target is found
    autoshootdelay = 0.12, -- delay between auto shots
    autoshootstartdelay = 0.2, -- delay before first shot when target acquired (reaction time)
    missspread = 5, -- how far off to shoot when missing (makes it look legit)
    shotgunnaturalspread = true, -- let shotgun bullets spread naturally instead of all hitting
    shotgungamehandled = false, -- aim at player but let game handle hitchance/spread
    prioritizeclosest = true, -- shoot whoever is closest to your cursor (false = random from fov)
    targetstickiness = false, -- enable/disable target stickiness
    targetstickinessduration = 0.6, -- how long to keep target (seconds)
    targetstickinessrandom = false, -- use random range instead of fixed value
    targetstickinessmin = 0.3, -- min time if random is on
    targetstickinessmax = 0.7, -- max time if random is on
    fov = 150, -- how big the aim circle is
    showfov = true, -- show the fov circle on screen
    showtargetline = false, -- draw a line to your target
    togglekey = Enum.KeyCode.RightShift, -- key to toggle silent aim
    aimpart = "Head", -- what body part to aim at
    randomparts = true, -- randomly pick body parts instead
    partslist = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "HumanoidRootPart"}, -- parts to pick from if random is on (can add more if wanted)
    esp = true,
    espteamcheck = true,
    espshowteam = false,
    esptargets = {guards = true, inmates = true, criminals = true},
    espmaxdist = 500,
    espshowdist = true,
    esptoggle = Enum.KeyCode.RightControl,
    espcolor = Color3.fromRGB(0, 170, 255),
    espguards = Color3.fromRGB(0, 170, 255),
    espinmates = Color3.fromRGB(255, 150, 50),
    espcriminals = Color3.fromRGB(255, 60, 60),
    espteam = Color3.fromRGB(60, 255, 60),
    espuseteamcolors = true,
    c4esp = true,
    c4esptoggle = Enum.KeyCode.B,
    c4espcolor = Color3.fromRGB(80, 255, 80),
    c4espmaxdist = 200,
    c4espshowdist = true,
}

getgenv().cfg = cfg

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.IgnoreWater = true
wallParams.RespectCanCollide = false
wallParams.CollisionGroup = "ClientBullet"

local currentGun = nil
local rng = Random.new()
local lastShotTime = 0
local lastShotResult = false
local shotCooldown = 0.15
local currentTarget = nil
local targetSwitchTime = 0
local currentStickiness = 0

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Radius = cfg.fov
fovCircle.Transparency = 0.8
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Thickness = 1
fovCircle.Visible = cfg.showfov and cfg.enabled

local targetLine = Drawing.new("Line")
targetLine.Color = Color3.fromRGB(0, 255, 0)
targetLine.Thickness = 1
targetLine.Transparency = 0.5
targetLine.Visible = false

local visuals = {container = nil}
local espCache = {}

local function makeVisuals()
    local container
    if gethui then
        local screen = Instance.new("ScreenGui")
        screen.Name = "SilentAimESP"
        screen.ResetOnSpawn = false
        screen.Parent = gethui()
        container = screen
    elseif syn and syn.protect_gui then
        local screen = Instance.new("ScreenGui")
        screen.Name = "SilentAimESP"
        screen.ResetOnSpawn = false
        syn.protect_gui(screen)
        screen.Parent = CoreGui
        container = screen
    else
        local screen = Instance.new("ScreenGui")
        screen.Name = "SilentAimESP"
        screen.ResetOnSpawn = false
        screen.Parent = CoreGui
        container = screen
    end
    visuals.container = container
end

local function makeEsp(player)
    if espCache[player] then return espCache[player] end
    
    local esp = Instance.new("BillboardGui")
    esp.Name = "ESP_" .. player.Name
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 20, 0, 20)
    esp.StudsOffset = Vector3.new(0, 3, 0)
    esp.LightInfluence = 0
    
    local diamond = Instance.new("Frame")
    diamond.Name = "Diamond"
    diamond.BackgroundColor3 = cfg.espcolor
    diamond.BorderSizePixel = 0
    diamond.Size = UDim2.new(0, 10, 0, 10)
    diamond.Position = UDim2.new(0.5, -5, 0.5, -5)
    diamond.Rotation = 45
    diamond.Parent = esp
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = diamond
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistanceLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(0, 60, 0, 16)
    distLabel.Position = UDim2.new(0.5, -30, 1, 2)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Text = ""
    distLabel.Parent = esp
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 100, 0, 14)
    nameLabel.Position = UDim2.new(0.5, -50, 0, -16)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.Parent = esp
    
    espCache[player] = esp
    return esp
end

local function removeEsp(player)
    local e = espCache[player]
    if e then e:Destroy() espCache[player] = nil end
end

local function shouldShowEsp(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return false end
    
    local distance = (hrp.Position - myHrp.Position).Magnitude
    if distance > cfg.espmaxdist then return false end
    
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    
    if theirTeam == myTeam then
        if not cfg.espshowteam then return false end
        return true
    end
    
    if cfg.espteamcheck then
        local imCrimOrInmate = (myTeam == criminalsTeam or myTeam == inmatesTeam)
        local theyCrimOrInmate = (theirTeam == criminalsTeam or theirTeam == inmatesTeam)
        if imCrimOrInmate and theyCrimOrInmate then return false end
    end
    
    if theirTeam == guardsTeam then return cfg.esptargets.guards
    elseif theirTeam == inmatesTeam then return cfg.esptargets.inmates
    elseif theirTeam == criminalsTeam then return cfg.esptargets.criminals end
    
    return false
end

local function updateEsp()
    if not cfg.esp or not visuals.container then
        for _, e in pairs(espCache) do e.Parent = nil end
        return
    end
    
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for _, player in ipairs(Players:GetPlayers()) do
        local show = shouldShowEsp(player)
        
        if show then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            
            if hrp and head then
                local esp = makeEsp(player)
                esp.Adornee = head
                esp.Parent = visuals.container
                
                local d = esp:FindFirstChild("Diamond")
                if d and cfg.espuseteamcolors then
                    local t = player.Team
                    if t == LocalPlayer.Team then d.BackgroundColor3 = cfg.espteam
                    elseif t == guardsTeam then d.BackgroundColor3 = cfg.espguards
                    elseif t == inmatesTeam then d.BackgroundColor3 = cfg.espinmates
                    elseif t == criminalsTeam then d.BackgroundColor3 = cfg.espcriminals
                    else d.BackgroundColor3 = cfg.espcolor end
                end
                
                if cfg.espshowdist and myHrp then
                    local label = esp:FindFirstChild("DistanceLabel")
                    if label then
                        label.Text = math.floor((hrp.Position - myHrp.Position).Magnitude) .. "m"
                        label.Visible = true
                    end
                end
            end
        else
            local e = espCache[player]
            if e then e.Parent = nil end
        end
    end
end

local c4espCache = {}

local function makeC4Esp(c4Part)
    if c4espCache[c4Part] then return c4espCache[c4Part] end
    
    local esp = Instance.new("BillboardGui")
    esp.Name = "C4ESP_" .. tostring(c4Part)
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 24, 0, 24)
    esp.StudsOffset = Vector3.new(0, 1, 0)
    esp.LightInfluence = 0
    
    local icon = Instance.new("Frame")
    icon.Name = "Icon"
    icon.BackgroundColor3 = cfg.c4espcolor
    icon.BorderSizePixel = 0
    icon.Size = UDim2.new(0, 14, 0, 14)
    icon.Position = UDim2.new(0.5, -7, 0.5, -7)
    icon.Rotation = 45
    icon.Parent = esp
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = icon
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 60, 0, 14)
    label.Position = UDim2.new(0.5, -30, 1, 2)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text = "C4"
    label.Parent = esp
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(0, 60, 0, 12)
    distLabel.Position = UDim2.new(0.5, -30, 1, 16)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 10
    distLabel.TextColor3 = cfg.c4espcolor
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Text = ""
    distLabel.Parent = esp
    
    c4espCache[c4Part] = esp
    return esp
end

local trackedC4s = {}

local function isC4Part(part)
    if not part or not part:IsA("BasePart") then return false end
    local name = part.Name:lower()
    local parentName = part.Parent and part.Parent.Name:lower() or ""
    return name == "explosive" or name == "c4" or name == "clientc4" or 
        parentName:find("c4") or name:find("c4")
end

local function onDescendantAdded(desc)
    if isC4Part(desc) then
        trackedC4s[desc] = true
    end
end

local function onDescendantRemoving(desc)
    trackedC4s[desc] = nil
    if c4espCache[desc] then
        c4espCache[desc]:Destroy()
        c4espCache[desc] = nil
    end
end

for _, desc in ipairs(workspace:GetDescendants()) do
    if isC4Part(desc) then trackedC4s[desc] = true end
end
workspace.DescendantAdded:Connect(onDescendantAdded)
workspace.DescendantRemoving:Connect(onDescendantRemoving)

local function updateC4Esp()
    if not cfg.c4esp or not visuals.container then
        for _, e in pairs(c4espCache) do e.Parent = nil end
        return
    end
    
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for part in pairs(trackedC4s) do
        if part and part:IsDescendantOf(workspace) then
            local dist = 0
            if myHrp then
                dist = (part.Position - myHrp.Position).Magnitude
            end
            
            if dist <= cfg.c4espmaxdist then
                local esp = makeC4Esp(part)
                esp.Adornee = part
                esp.Parent = visuals.container
                
                if cfg.c4espshowdist and myHrp then
                    local distLabel = esp:FindFirstChild("DistLabel")
                    if distLabel then
                        distLabel.Text = math.floor(dist) .. "m"
                    end
                end
            else
                local e = c4espCache[part]
                if e then e.Parent = nil end
            end
        else
            trackedC4s[part] = nil
            if c4espCache[part] then
                c4espCache[part]:Destroy()
                c4espCache[part] = nil
            end
        end
    end
end

makeVisuals()


local partMap = {
    ["Torso"] = {"Torso", "UpperTorso", "LowerTorso"},
    ["LeftArm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["RightArm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["LeftLeg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["RightLeg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function getPart(char, name)
    if not char then return nil end
    local p = char:FindFirstChild(name)
    if p then return p end
    
    local maps = partMap[name]
    if maps then
        for _, n in ipairs(maps) do
            local part = char:FindFirstChild(n)
            if part then return part end
        end
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function getTargetPart(char)
    if not char then return nil end
    
    if cfg.shieldbreaker then
        local shield = char:FindFirstChild("RiotShieldPart")
        if shield and shield:IsA("BasePart") then
            local hp = shield:GetAttribute("Health")
            if hp and hp > 0 then
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local theirHrp = char:FindFirstChild("HumanoidRootPart")
                
                if myHrp and theirHrp then
                    local toMe = (myHrp.Position - theirHrp.Position).Unit
                    local theirLook = theirHrp.CFrame.LookVector
                    local dot = toMe:Dot(theirLook)
                    
                    if dot > cfg.shieldfrontangle then
                        if cfg.shieldrandomhead and rng:NextInteger(1, 100) <= cfg.shieldheadchance then
                            return getPart(char, "Head")
                        end
                        return shield
                    end
                end
            end
        end
    end
    
    local partName
    if cfg.randomparts then
        local list = cfg.partslist
        partName = (list and #list > 0) and list[rng:NextInteger(1, #list)] or "Head"
    else
        partName = cfg.aimpart
    end
    return getPart(char, partName)
end

local function isDead(player)
    if not player or not player.Character then return true end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return not humanoid or humanoid.Health <= 0
end

local function isStanding(player)
    if not player or not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local vel = hrp.AssemblyLinearVelocity
    return Vector2.new(vel.X, vel.Z).Magnitude <= cfg.stillthreshold
end

local function hasForceField(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function isInVehicle(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return humanoid.SeatPart ~= nil
end

local function wallBetween(startPos, endPos, targetChar)
    local myChar = LocalPlayer.Character
    if not myChar then return true end
    
    local filter = {myChar}
    if targetChar then table.insert(filter, targetChar) end
    wallParams.FilterDescendantsInstances = filter
    
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local unit = direction.Unit
    
    local currentStart = startPos
    local remaining = distance
    
    for _ = 1, 10 do
        local result = workspace:Raycast(currentStart, unit * remaining, wallParams)
        if not result then return false end
        
        local hit = result.Instance
        if hit.Transparency < 0.8 and hit.CanCollide then return true end
        
        local hitDist = (result.Position - currentStart).Magnitude
        remaining = remaining - hitDist - 0.01
        if remaining <= 0 then return false end
        
        currentStart = result.Position + unit * 0.01
    end
    return false
end

local function quickCheck(player)
    if not player or player == LocalPlayer or not player.Character then return false end
    if not getTargetPart(player.Character) then return false end
    if cfg.deathcheck and isDead(player) then return false end
    if cfg.ffcheck and hasForceField(player) then return false end
    if cfg.vehiclecheck and isInVehicle(player) then return false end
    if cfg.teamcheck and player.Team == LocalPlayer.Team then return false end
    if cfg.criminalsnoinnmates then
        if LocalPlayer.Team == criminalsTeam and player.Team == inmatesTeam then return false end
    end
    if cfg.inmatesnocriminals then
        if LocalPlayer.Team == inmatesTeam and player.Team == criminalsTeam then return false end
    end
    
    if cfg.hostilecheck or cfg.trespasscheck then
        local isTaser = currentGun and currentGun:GetAttribute("Projectile") == "Taser"
        local bypassHostile = cfg.taserbypasshostile and isTaser
        local bypassTrespass = cfg.taserbypasstrespass and isTaser
        local targetChar = player.Character
        
        if LocalPlayer.Team == guardsTeam and player.Team == inmatesTeam then
            local hostile = targetChar:GetAttribute("Hostile")
            local trespass = targetChar:GetAttribute("Trespassing")
            
            if cfg.hostilecheck and cfg.trespasscheck then
                if not bypassHostile and not bypassTrespass then
                    if not hostile and not trespass then return false end
                end
            elseif cfg.hostilecheck and not bypassHostile then
                if not hostile then return false end
            elseif cfg.trespasscheck and not bypassTrespass then
                if not trespass then return false end
            end
        end
    end
    return true
end

local function fullCheck(player)
    if not quickCheck(player) then return false end
    
    if cfg.wallcheck then
        local myChar = LocalPlayer.Character
        local myHead = myChar and myChar:FindFirstChild("Head")
        local targetPart = getTargetPart(player.Character)
        if myHead and targetPart then
            if wallBetween(myHead.Position, targetPart.Position, player.Character) then
                return false
            end
        end
    end
    return true
end

local function rollHit()
    local now = os.clock()
    if now - lastShotTime > shotCooldown then
        lastShotTime = now
        local chance = cfg.hitchance
        if chance >= 100 then
            lastShotResult = true
        elseif chance <= 0 then
            lastShotResult = false
        else
            lastShotResult = rng:NextInteger(1, 100) <= chance
        end
    end
    return lastShotResult
end

local function getMissPos(targetPos)
    local spread = cfg.missspread
    local angle = rng:NextNumber() * math.pi * 2
    local d = rng:NextNumber() * spread
    local yOffset = (rng:NextNumber() - 0.5) * spread
    return targetPos + Vector3.new(math.cos(angle) * d, yOffset, math.sin(angle) * d)
end

local function getClosest(fovRadius)
    fovRadius = fovRadius or cfg.fov
    local camera = workspace.CurrentCamera
    if not camera then return nil, nil end
    
    local lastInput = UserInputService:GetLastInputType()
    local locked = (lastInput == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
    
    local aimPos
    if locked then
        local viewportSize = camera.ViewportSize
        aimPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        aimPos = UserInputService:GetMouseLocation()
    end
    
    local now = os.clock()
    
    if cfg.targetstickiness and currentTarget and (now - targetSwitchTime) < currentStickiness then
        if fullCheck(currentTarget) then
            local part = getTargetPart(currentTarget.Character)
            if part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPos).Magnitude
                    if dist < fovRadius then
                        return currentTarget, part.Position
                    end
                end
            end
        end
    end
    
    local candidates = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if quickCheck(player) then
            local part = getTargetPart(player.Character)
            if part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPos).Magnitude
                    if dist < fovRadius then
                        candidates[#candidates + 1] = {player = player, dist = dist, part = part}
                    end
                end
            end
        end
    end
    
    if cfg.prioritizeclosest then
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
    else
        for i = #candidates, 2, -1 do
            local j = rng:NextInteger(1, i)
            candidates[i], candidates[j] = candidates[j], candidates[i]
        end
    end
    
    for _, candidate in ipairs(candidates) do
        if fullCheck(candidate.player) then
            if candidate.player ~= currentTarget then
                currentTarget = candidate.player
                targetSwitchTime = now
                if cfg.targetstickinessrandom then
                    currentStickiness = rng:NextNumber(cfg.targetstickinessmin, cfg.targetstickinessmax)
                else
                    currentStickiness = cfg.targetstickinessduration
                end
            end
            return candidate.player, candidate.part.Position
        end
    end
    
    currentTarget = nil
    return nil, nil
end
local ShootEvent = ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("ShootEvent")
local Debris = game:GetService("Debris")
local lastAutoShoot = 0

local function createBulletTrail(startPos, endPos, isTaser)
    local distance = (endPos - startPos).Magnitude
    local trail = Instance.new("Part")
    trail.Name = "BulletTrail"
    trail.Anchored = true
    trail.CanCollide = false
    trail.CanQuery = false
    trail.CanTouch = false
    trail.Material = Enum.Material.Neon
    trail.Size = Vector3.new(0.1, 0.1, distance)
    trail.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    trail.Transparency = 0.5
    
    if isTaser then
        trail.BrickColor = BrickColor.new("Cyan")
        trail.Size = Vector3.new(0.2, 0.2, distance)
        local light = Instance.new("SurfaceLight")
        light.Color = Color3.fromRGB(0, 234, 255)
        light.Range = 7
        light.Brightness = 5
        light.Face = Enum.NormalId.Bottom
        light.Parent = trail
    else
        trail.BrickColor = BrickColor.Yellow()
    end
    
    trail.Parent = workspace
    Debris:AddItem(trail, isTaser and 0.8 or 0.1)
end

local cachedBulletsLabel = nil
local targetAcquiredTime = 0
local lastAutoTarget = nil

local function autoShoot()
    if not cfg.autoshoot or not cfg.enabled or not currentGun then return end
    
    local now = os.clock()
    local fireRate = currentGun:GetAttribute("FireRate") or cfg.autoshootdelay
    if now - lastAutoShoot < fireRate then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return end
    
    local muzzle = currentGun:FindFirstChild("Muzzle")
    local startPos = muzzle and muzzle.Position or myHead.Position
    
    local target, targetPos = getClosest(cfg.fov)
    if not target or not fullCheck(target) then 
        lastAutoTarget = nil
        return 
    end
    
    if target ~= lastAutoTarget then
        targetAcquiredTime = now
        lastAutoTarget = target
    end
    
    if now - targetAcquiredTime < cfg.autoshootstartdelay then return end
    
    local targetPart = getTargetPart(target.Character)
    if not targetPart then return end
    
    local ammo = currentGun:GetAttribute("Local_CurrentAmmo") or currentGun:GetAttribute("CurrentAmmo") or 0
    if ammo <= 0 then return end
    
    lastAutoShoot = now
    
    local isTaser = currentGun:GetAttribute("Projectile") == "Taser"
    local isShotgun = currentGun:GetAttribute("IsShotgun")
    local shouldHit = false
    
    if cfg.taseralwayshit and isTaser then
        shouldHit = true
    elseif cfg.ifplayerstill and isStanding(target) then
        shouldHit = true
    elseif cfg.hitchanceAutoOnly and isShotgun then
        shouldHit = true
    else
        shouldHit = rollHit()
    end
    
    local projectileCount = currentGun:GetAttribute("ProjectileCount") or 1
    local shots = {}
    
    for i = 1, projectileCount do
        local finalPos
        if shouldHit then
            finalPos = targetPart.Position
        else
            if cfg.missspread > 0 then
                finalPos = getMissPos(targetPart.Position)
            else
                return
            end
        end
        shots[i] = {myHead.Position, finalPos, shouldHit and targetPart or nil}
        createBulletTrail(startPos, finalPos, isTaser)
    end
    
    ShootEvent:FireServer(shots)
    
    local newAmmo = ammo - 1
    currentGun:SetAttribute("Local_CurrentAmmo", newAmmo)
    
    if not cachedBulletsLabel then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local home = playerGui:FindFirstChild("Home")
            if home then
                local hud = home:FindFirstChild("hud")
                if hud then
                    local br = hud:FindFirstChild("BottomRightFrame")
                    if br then
                        local gf = br:FindFirstChild("GunFrame")
                        if gf then
                            cachedBulletsLabel = gf:FindFirstChild("BulletsLabel")
                        end
                    end
                end
            end
        end
    end
    
    if cachedBulletsLabel then
        cachedBulletsLabel.Text = newAmmo .. "/" .. (currentGun:GetAttribute("MaxAmmo") or 30)
    end
    
    local handle = currentGun:FindFirstChild("Handle")
    if handle then
        local shootSound = handle:FindFirstChild("ShootSound")
        if shootSound then
            local sound = shootSound:Clone()
            sound.Parent = handle
            sound:Play()
            Debris:AddItem(sound, 2)
        end
    end
end

local function getGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
            return tool
        end
    end
    return nil
end

local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

local lastGun = nil

RunService.Heartbeat:Connect(function()
    currentGun = getGun()
    if currentGun ~= lastGun then
        lastAutoShoot = 0
        lastGun = currentGun
    end
    autoShoot()
end)

RunService.PreRender:Connect(function()
    local aimPos = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    
    if camera then
        local lastInput = UserInputService:GetLastInputType()
        local locked = (lastInput == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
        if locked then
            local viewportSize = camera.ViewportSize
            aimPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        end
    end
    
    fovCircle.Position = aimPos
    fovCircle.Radius = cfg.fov
    fovCircle.Visible = cfg.showfov and cfg.enabled
    
    if cfg.showtargetline and cfg.enabled then
        local target, targetPos = getClosest()
        if target and targetPos and camera then
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
            if onScreen then
                targetLine.From = aimPos
                targetLine.To = Vector2.new(screenPos.X, screenPos.Y)
                targetLine.Visible = true
            else
                targetLine.Visible = false
            end
        else
            targetLine.Visible = false
        end
    else
        targetLine.Visible = false
    end
    
    updateEsp()
    updateC4Esp()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == cfg.togglekey then
        cfg.enabled = not cfg.enabled
        notify("Silent Aim", "Enabled: " .. tostring(cfg.enabled), 3)
    elseif input.KeyCode == cfg.esptoggle then
        cfg.esp = not cfg.esp
        notify("ESP", "Enabled: " .. tostring(cfg.esp), 3)
    elseif input.KeyCode == cfg.c4esptoggle then
        cfg.c4esp = not cfg.c4esp
        notify("C4 ESP", "Enabled: " .. tostring(cfg.c4esp), 3)
    end
end)

Players.PlayerRemoving:Connect(removeEsp)

local function clearEsp()
    for player, e in pairs(espCache) do
        if e then e:Destroy() end
        espCache[player] = nil
    end
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    clearEsp()
end)

local function noUpvals(fn)
    return function(...) return fn(...) end
end

local origCastRay
local hooked = false

local function setupHook()
    local castRayFunc = filtergc("function", {Name = "castRay"}, true)
    if not castRayFunc then return false end
    
    origCastRay = hookfunction(castRayFunc, noUpvals(function(startPos, targetPos, ...)
        if not cfg.enabled then return origCastRay(startPos, targetPos, ...) end
        
        local closest, closestPos = getClosest(cfg.fov)
        
        if closest and closest.Character then
            local isTaser = currentGun and currentGun:GetAttribute("Projectile") == "Taser"
            local isShotgun = currentGun and currentGun:GetAttribute("IsShotgun")
            local shouldHit = false
            
            if cfg.hitchanceAutoOnly and isShotgun then
                return origCastRay(startPos, targetPos, ...)
            end
            
            if cfg.shotgungamehandled and isShotgun then
                local targetPart = getTargetPart(closest.Character)
                if targetPart then
                    return origCastRay(startPos, targetPart.Position, ...)
                end
                return origCastRay(startPos, targetPos, ...)
            end
            
            if cfg.taseralwayshit and isTaser then
                shouldHit = true
            elseif cfg.ifplayerstill and isStanding(closest) then
                shouldHit = true
            else
                shouldHit = rollHit()
            end
            
            if shouldHit then
                local targetPart = getTargetPart(closest.Character)
                if targetPart then
                    if cfg.shotgunnaturalspread and isShotgun then
                        return origCastRay(startPos, targetPart.Position, ...)
                    end
                    return targetPart, targetPart.Position
                end
            else
                if cfg.missspread > 0 then
                    local targetPart = getTargetPart(closest.Character)
                    if targetPart then
                        local missPos = getMissPos(targetPart.Position)
                        return origCastRay(startPos, missPos, ...)
                    end
                end
                return origCastRay(startPos, targetPos, ...)
            end
        end
        
        return origCastRay(startPos, targetPos, ...)
    end))
    return true
end

if not setupHook() then
    task.spawn(function()
        while not hooked do
            task.wait(0.5)
            if setupHook() then
                hooked = true
            end
        end
    end)
else
    hooked = true
end

notify("Silent Aim + ESP", "Loaded! RShift = Aim, RCtrl = ESP", 5)
