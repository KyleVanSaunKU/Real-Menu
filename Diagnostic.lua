local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RollEgg = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RollEgg")

-- Change this to test different egg names from the shop (e.g., "RareEgg", "SeperatedEgg", etc.)
local testEggName = "RareEgg"

-- Set to true to start, set to false in your executor console to stop
_G.TestHatch = true

print("🥚 [Standalone Test] Firing RollEgg for: " .. testEggName)

task.spawn(function()
    while _G.TestHatch do
        task.wait(0.5)
        
        pcall(function()
            -- Simulator remotes usually take the egg name and an amount (e.g., 1)
            RollEgg:FireServer(testEggName, 1)
            print("Successfully fired RollEgg for " .. testEggName)
        end)
        
        pcall(function()
            -- Fallback in case it's an InvokeServer (RemoteFunction) or takes no arguments
            RollEgg:InvokeServer(testEggName)
        end)
    end
end)
