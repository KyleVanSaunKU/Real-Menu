local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RollEgg = Remotes:WaitForChild("RollEgg")

-- Check your actual balance
local leaderstats = player:FindFirstChild("leaderstats")
local cashObj = leaderstats and leaderstats:FindFirstChild("Cash")
print("💰 Current Cash Value:", cashObj and cashObj.Value or "No Cash Found")

-- Test different string variations that simulator devs commonly use
local testNames = {"RareEgg", "Rare Egg", "rare_egg", "EpicEgg", "Epic Egg"}

print("🥚 [Diagnostic] Testing string names on RollEgg...")

for _, eggName in ipairs(testNames) do
    pcall(function()
        print("Firing RollEgg with argument:", eggName)
        -- Try standard arguments: (Name, Amount)
        RollEgg:FireServer(eggName, 1)
    end)
    task.wait(0.5)
end

print("─── Checking Workspace Pedestals ───")
for _, obj in ipairs(workspace:GetChildren()) do
    if obj.Name:lower():find("egg") then
        print("Found workspace object containing 'egg':", obj.Name, obj:GetFullName())
    end
end
print("─── Test Finished ───")
