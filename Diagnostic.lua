local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Configuration: Target specific physical egg models found in the world
-- Options spotted from your scan: "RareEgg", "SeperatedEgg"
local TARGET_EGG_NAME = "RareEgg"

_G.AutoHatch = true

print("🥚 [Auto-Hatch] Started scanning for: " .. TARGET_EGG_NAME)

local function triggerInteraction(obj)
    -- Method 1: Fire ProximityPrompt (hold 'E' mechanism)
    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
    if prompt and fireproximityprompt then
        pcall(function() 
            fireproximityprompt(prompt) 
        end)
        return
    end

    -- Method 2: Fire ClickDetector (click mechanism)
    local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
    if clickDetector and fireclickdetector then
        pcall(function() 
            fireclickdetector(clickDetector) 
        end)
        return
    end

    -- Method 3: Fallback Brute-Force Touch interest (simulates character stepping on/touching the pad)
    local touchInterest = obj:FindFirstChild("TouchTransmitter") or obj:FindFirstChild("TouchInterest")
    if touchInterest and firetouchinterest then
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                firetouchinterest(obj, char.HumanoidRootPart, 0)
                task.wait(0.05)
                firetouchinterest(obj, char.HumanoidRootPart, 1)
            end
        end)
    end
end

-- Main processing loop running on Heartbeat for maximum speed and responsiveness
RunService.Heartbeat:Connect(function()
    if not _G.AutoHatch then return end

    -- Deep recursive search using GetDescendants to locate objects even inside nested folders/maps
    for _, descendant in ipairs(workspace:GetDescendants()) do
        -- Match target egg names or partial terms
        if descendant.Name == TARGET_EGG_NAME and descendant:IsA("BasePart") or descendant:IsA("Model") then
            
            -- Make sure we are only hitting physical world items, not UI components
            if descendant:IsDescendantOf(game.Players.LocalPlayer.Character) then continue end
            
            triggerInteraction(descendant)
        end
    end
end)
