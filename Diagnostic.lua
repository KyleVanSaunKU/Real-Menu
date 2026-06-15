local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local bookEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

local function teleportAndPickup(targetSeries)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then 
        warn("Could not find character to teleport!")
        return 
    end

    -- 1. Save your current position so we can return you here later
    local originalCFrame = rootPart.CFrame
    local count = 0

    for _, child in ipairs(Workspace:GetDescendants()) do
        if child.Name == "Book" then
            local titleAttr = child:GetAttribute("title")
            
            if titleAttr then
                local seriesName = string.gsub(titleAttr, "%s*EP%d+$", "")
                
                if seriesName == targetSeries then
                    -- 2. Teleport your character directly to the book
                    -- We add + Vector3.new(0, 3, 0) so you hover slightly above it and don't get stuck in the floor/shelf
                    rootPart.CFrame = child.CFrame + Vector3.new(0, 3, 0)
                    
                    -- 3. CRITICAL: Wait a fraction of a second for the server to update your new position
                    task.wait(0.2)
                    
                    -- 4. Fire the pickup remote now that the server thinks we are standing on it
                    bookEvent:FireServer(child, "pickup")
                    count += 1
                    
                    -- 5. Add a small cooldown so the game's anti-cheat doesn't kick you for teleporting too fast
                    task.wait(0.2)
                end
            end
        end
    end
    
    -- 6. Teleport back to where you started
    task.wait(0.1)
    rootPart.CFrame = originalCFrame
    
    print("Successfully teleported to and picked up " .. count .. " books from: " .. targetSeries)
end

-- Example Usage:
teleportAndPickup("Money Heist")
