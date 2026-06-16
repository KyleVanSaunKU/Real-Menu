-- 1. CLEANUP: Prevent executor loop stacking (No more rejoining needed when tweaking)
if _G.AutoMusket then
    _G.AutoMusket:Disconnect()
    _G.AutoMusket = nil
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local STAB_RANGE = 15
local SHOOT_RANGE = 250
local SHOOT_COOLDOWN = 0.5 
local STAB_COOLDOWN = 0.5

local lastShoot = 0
local lastStab = 0
local isReloading = false

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
        
        if hum and hum.Health > 0 and head then
            local dist = (head.Position - rootPos).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestHead = head
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then checkTarget(p.Character) end
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            checkTarget(obj)
        end
    end

    return closestHead, shortestDist
end

-- 2. GLOBAL BIND: Store the connection so we can kill it on re-execution
_G.AutoMusket = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local musket = char:FindFirstChild("Musket")
    if not musket then return end 

    local remote = musket:FindFirstChild("RemoteEvent")
    local ammo = musket:FindFirstChild("Ammo")
    if not remote or not ammo then return end

    local now = os.clock()
    local targetHead, distance = getClosestTarget()

    -- Reset reload lock once the server updates the ammo value
    if ammo.Value > 0 then
        isReloading = false
    end

    -- PRIORITY 1: Melee
    if targetHead and distance <= STAB_RANGE then
        if now - lastStab > STAB_COOLDOWN then
            remote:FireServer(nil, "Stab")
            lastStab = now
        end

    -- PRIORITY 2: Shoot
    elseif targetHead and distance <= SHOOT_RANGE then
        if ammo.Value >= 1 then
            if now - lastShoot > SHOOT_COOLDOWN then
                local origin = Camera.CFrame.Position
                local direction = (targetHead.Position - origin).Unit * SHOOT_RANGE
                
                -- STATE SPOOFING: We must tell the server we are aiming first
                remote:FireServer(nil, "Aim")
                
                -- Fire the actual bullet
                remote:FireServer(Ray.new(origin, direction), "Shoot")
                
                -- Reset state so the server doesn't bug out
                remote:FireServer(nil, "Unaim")
                
                lastShoot = now
            end
        elseif not isReloading then
            remote:FireServer(nil, "Reload")
            isReloading = true -- Lock it so we don't spam the remote and reset the timer
        end
        
    -- PRIORITY 3: Idle Reload
    else
        if ammo.Value <= 0 and not isReloading then
            remote:FireServer(nil, "Reload")
            isReloading = true
        end
    end
end)
