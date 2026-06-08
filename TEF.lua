local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- NETWORK BACKDOOR (Defined globally)
-- ==========================================
local PacketRemote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Vendor"):WaitForChild("Packet"):WaitForChild("RemoteEvent")

-- ==========================================
-- ITEM CATEGORIES
-- ==========================================
local ItemCategories = {
    { Name = "Mythical", Priority = 1, Color = Color3.fromRGB(236, 72, 153), Items = {"LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", "PhoenixFurnace", "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper", "WaterfallUpgrader", "MalevolentFurnace"} },
    { Name = "Epic", Priority = 2, Color = Color3.fromRGB(168, 85, 247), Items = {"CatUpgrader", "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", "WillowDropper", "CameraUpgrader", "OuroborosUpgrader", "SnowmanUpgrader", "LunarFurnace", "BambooUpgrader", "PumpkinUpgrader", "UFOUpgrader", "PotOfGoldFurnace"} },
    { Name = "Uncommon", Priority = 3, Color = Color3.fromRGB(56, 189, 248), Items = {"HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", "ScienceFurnace", "SrirachaUpgrader", "TinDropper", "FireworkUpgrader", "LemonUpgrader", "GoldDropper"} }
}

local State = { Master = false, Noclip = false, Items = {} }
for _, cat in ipairs(ItemCategories) do
    for _, item in ipairs(cat.Items) do State.Items[item] = true end
end

-- ==========================================
-- UI CONSTRUCTION (No Animations for Stability)
-- ==========================================

local TycoonGui = Instance.new("ScreenGui", (RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui))
local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)

local function createToggle(name, text, onClick)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, (#MainFrame:GetChildren() - 1) * 35 + 10)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    btn.MouseButton1Click:Connect(onClick)
end

createToggle("Master", "Toggle Master Auto-Buy", function() State.Master = not State.Master end)
createToggle("Noclip", "Toggle Noclip", function() State.Noclip = not State.Noclip end)

-- ==========================================
-- AUTO-BUYER LOGIC
-- ==========================================

-- NOCLIP
RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- BUYER LOOP
task.spawn(function()
    while task.wait(0.3) do
        if not State.Master then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- Find Plot & Belt
        local plot = nil
        for _, p in ipairs(workspace.Plots:GetChildren()) do
            local z = p:FindFirstChild("PlotZone", true)
            if z and z:IsA("BasePart") then
                local pos = z.CFrame:PointToObjectSpace(hrp.Position)
                if math.abs(pos.X) <= z.Size.X/2 and math.abs(pos.Z) <= z.Size.Z/2 then plot = p break end
            end
        end
        
        local active = plot and plot:FindFirstChild("Belt") and plot.Belt:FindFirstChild("ActiveItems")
        if not active then continue end

        -- Buy Items
        for _, item in ipairs(active:GetChildren()) do
            if State.Items[item.Name] then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                local pad = item:FindFirstChild("PurchasePad", true) or item:FindFirstChildWhichIsA("BasePart", true)
                
                if prompt and pad then
                    -- 1. TELEPORT
                    local oldPos = hrp.CFrame
                    hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 2, 0))
                    hrp.Anchored = true
                    task.wait(0.1)
                    
                    -- 2. FIRE BACKDOOR + PROMPT
                    pcall(function() PacketRemote:FireServer("purchase_belt_item", item) end)
                    if fireproximityprompt then fireproximityprompt(prompt) end
                    
                    -- 3. RESET
                    task.wait(0.2)
                    hrp.Anchored = false
                    hrp.CFrame = oldPos
                end
            end
        end
    end
end)
