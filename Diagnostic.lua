local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local STAB_RANGE = 15
local SHOOT_RANGE = 250
local SHOOT_COOLDOWN = 0.5
local RELOAD_WAIT = 1.5
local LOOP_DELAY = 0.1

-- Calculates the shortest distance to a valid enemy head
local function getClosestTarget()
    local closestHead = nil
    local shortestDistance = math.huge
    local character = LocalPlayer.Character

    -- Prevent execution if your character isn't fully loaded
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil, nil
    end

    local rootPos = character.HumanoidRootPart.Position

    -- Iterate through all players to find the closest valid target
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyHumanoid = player.Character:FindFirstChild("Humanoid")
            local enemyHead = player.Character:FindFirstChild("Head")

            -- Ensure the target is alive and has a Head part
            if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHead then
                local distance = (enemyHead.Position - rootPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestHead = enemyHead
                end
            end
        end
    end

    return closestHead, shortestDistance
end

-- Main Automation Loop
task.spawn(function()
    while task.wait(LOOP_DELAY) do
        local character = LocalPlayer.Character
        if not character then continue end

        -- Only run the logic if the Musket is currently equipped
        local musket = character:FindFirstChild("Musket")
        if not musket then continue end 

        local remote = musket:FindFirstChild("RemoteEvent")
        local ammo = musket:FindFirstChild("Ammo")
        if not remote then continue end

        -- 1. Auto Reload Logic
        if ammo and ammo.Value <= 0 then
            remote:FireServer(nil, "Reload")
            task.wait(RELOAD_WAIT) -- Wait for the server to register the reload
            continue
        end

        -- 2. Target Acquisition
        local targetHead, distance = getClosestTarget()
        if not targetHead then continue end

        -- 3. Action Execution (Stab vs. Shoot)
        if distance <= STAB_RANGE then
            -- Engage in melee if within stabbing distance
            remote:FireServer(nil, "Stab")
            task.wait(0.25)
            
        elseif distance <= SHOOT_RANGE then
            -- Shoot if ammo is available
            if ammo and ammo.Value > 0 then
                local origin = Camera.CFrame.Position
                
                -- Calculate the exact vector intersection to the target's head
                local direction = (targetHead.Position - origin).Unit * SHOOT_RANGE

                -- Spoof the raycast arguments to the server
                remote:FireServer(Ray.new(origin, direction), "Shoot")
                
                -- Cooldown to prevent the server from flagging remote spam
                task.wait(SHOOT_COOLDOWN) 
            end
        end
    end
end)
