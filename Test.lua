local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Create a visual indicator to show which slime is currently targeted
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
TargetHighlight.FillTransparency = 0.5

-- Function to locate the closest slime based on your specific folder hierarchy
local function getClosestSlime()
    -- Safely navigate the workspace path
    local SpawnPoints = workspace:FindFirstChild("SpawnPoints")
    if not SpawnPoints then return nil end

    local SlimeResp = SpawnPoints:FindFirstChild("SlimeResp")
    if not SlimeResp then return nil end

    local closestSlime = nil
    local shortestDistance = math.huge
    local character = LocalPlayer.Character
    local playerPos = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position

    -- If the player hasn't loaded properly, abort the search for this frame
    if not playerPos then return nil end

    -- Loop through SlimeResp -> Resp objects -> Objects with "Slime" in the name
    for _, respObj in ipairs(SlimeResp:GetChildren()) do
        if respObj.Name == "Resp" then
            for _, obj in ipairs(respObj:GetChildren()) do
                if string.match(obj.Name, "Slime") then
                    
                    -- Look for a physical part of the slime to lock the camera onto
                    local targetPart = obj:FindFirstChild("HumanoidRootPart") 
                        or obj:FindFirstChild("PrimaryPart") 
                        or obj:FindFirstChildWhichIsA("BasePart")
                    
                    if targetPart then
                        local distance = (playerPos - targetPart.Position).Magnitude
                        
                        -- Update the target if this slime is closer than the previous ones
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestSlime = targetPart
                        end
                    end
                end
            end
        end
    end

    return closestSlime
end

-- Bind the aimbot to RenderStepped so it updates exactly when the camera renders
local aimbotConnection
aimbotConnection = RunService.RenderStepped:Connect(function()
    local target = getClosestSlime()
    
    if target then
        -- Snap the camera's CFrame to look at the targeted slime's position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        
        -- Move the red highlight to the active target model
        if target.Parent and target.Parent ~= TargetHighlight.Parent then
            TargetHighlight.Parent = target.Parent
        end
    else
        -- Hide the highlight if no slimes are currently spawned/found
        TargetHighlight.Parent = nil
    end
end)

-- Execute this in your executor to kill the aimbot loop cleanly if needed
getgenv().stopSlimeAimbot = function() 
    if aimbotConnection then aimbotConnection:Disconnect() end
    if TargetHighlight then TargetHighlight:Destroy() end
end
