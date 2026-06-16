local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- Speed Configuration (Set insanely low since you can bypass animation states)
local STAB_RANGE = 15
local SHOOT_RANGE = 250
local SHOOT_COOLDOWN = 0.05 
local STAB_COOLDOWN = 0.05
local RELOAD_COOLDOWN = 0.1 

-- Timers to prevent completely crashing your game/server
local lastShoot = 0
local lastStab = 0
local lastReload = 0

-- Scans both Players and Workspace for the nearest head
local function getClosestTarget()
    local closestHead = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local rootPos = char.HumanoidRootPart.Position

    local function checkTarget(model)
        if model == char then return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local head = model:FindFirstChild("Head")
        
        -- Target must be alive and have a head part
        if hum and hum.Health > 0 and head then
            local dist = (head.Position - rootPos).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestHead = head
            end
        end
    end

    -- 1. Check actual Players
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then checkTarget(p.Character) end
    end

    -- 2. Check Workspace for NPCs/Bots
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            checkTarget(obj)
        end
    end

    return closestHead, shortestDist
end

-- Replaced the while loop with Heartbeat for maximum smooth execution
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local musket = char:FindFirstChild("Musket")
    if not musket then return end 

    local remote = musket:FindFirstChild("RemoteEvent")
    local ammo = musket:FindFirstChild("Ammo")
    if not remote then return end

    local now = os.clock()
    local targetHead, distance = getClosestTarget()

    -- PRIORITY 1: Melee
    -- The decompiled script allows stabbing even if ammo is 0
    if targetHead and distance <= STAB_RANGE then
        if now - lastStab > STAB_COOLDOWN then
            remote:FireServer(nil, "Stab")
            lastStab = now
        end

    -- PRIORITY 2: Shoot
    elseif targetHead and distance <= SHOOT_RANGE then
        if ammo and ammo.Value >= 1 then
            if now - lastShoot > SHOOT_COOLDOWN then
                local origin = Camera.CFrame.Position
                local direction = (targetHead.Position - origin).Unit * SHOOT_RANGE
                
                remote:FireServer(Ray.new(origin, direction), "Shoot")
                lastShoot = now
            end
        -- If looking at a target but empty, spam reload
        elseif ammo and ammo.Value <= 0 then
            if now - lastReload > RELOAD_COOLDOWN then
                remote:FireServer(nil, "Reload")
                lastReload = now
            end
        end
        
    -- PRIORITY 3: Idle Reload
    else
        -- Automatically top off ammo when no targets are nearby
        if ammo and ammo.Value <= 0 then
            if now - lastReload > RELOAD_COOLDOWN then
                remote:FireServer(nil, "Reload")
                lastReload = now
            end
        end
    end
end)
