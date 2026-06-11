local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RollEgg = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RollEgg")

-- Stop the test at any time by executing: _G.TestHatch = false
_G.TestHatch = true

print("🥚 [Standalone Test] Testing Egg Slots 1, 2, and 3...")

task.spawn(function()
    while _G.TestHatch do
        task.wait(1.0)
        
        -- Loop through the 3 available display slots/pedestals in the shop
        for slotIndex = 1, 3 do
            pcall(function()
                RollEgg:FireServer(slotIndex)
                print("Fired RollEgg for Slot: " .. slotIndex)
            end)
            task.wait(0.2)
        end
    end
end)
