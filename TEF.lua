local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ITEM CATEGORIES & STATE
-- ==========================================
local ItemCategories = {
    { Name = "Mythical", Priority = 1, Color = Color3.fromRGB(236, 72, 153), Items = {"LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", "PhoenixFurnace", "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper", "WaterfallUpgrader", "MalevolentFurnace"} },
    { Name = "Epic", Priority = 2, Color = Color3.fromRGB(168, 85, 247), Items = {"CatUpgrader", "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", "WillowDropper", "CameraUpgrader", "OuroborosUpgrader", "SnowmanUpgrader", "LunarFurnace", "BambooUpgrader", "PumpkinUpgrader", "UFOUpgrader", "PotOfGoldFurnace"} },
    { Name = "Uncommon", Priority = 3, Color = Color3.fromRGB(56, 189, 248), Items = {"HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", "ScienceFurnace", "SrirachaUpgrader", "TinDropper", "FireworkUpgrader", "LemonUpgrader", "GoldDropper"} }
}

local defaultOff = { ["WaterfallUpgrader"] = true, ["MalevolentFurnace"] = true }
local ItemPriorityMap = {}
local State = { Master = false, Noclip = false, Categories = {}, Items = {} }

for _, category in ipairs(ItemCategories) do
    State.Categories[category.Name] = true 
    for _, item in ipairs(category.Items) do
        ItemPriorityMap[item] = category.Priority
        State.Items[item] = not defaultOff[item] 
        if defaultOff[item] then State.Categories[category.Name] = false end
    end
end

-- ==========================================
-- UI CONSTRUCTION (Crash-Proof, No Animations)
-- ==========================================
local TycoonGui = Instance.new("ScreenGui", (RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui))
TycoonGui.Name = "TycoonAutoBuyer"
TycoonGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 300, 0, 500)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -110)
ScrollFrame.Position = UDim2.new(0, 10, 0, 100)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
Instance.new("UIListLayout", ScrollFrame).Padding = UDim.new(0, 5)

local function createToggle(parent, name, text, isMaster)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(228, 228, 231)
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local function update(state)
        btn.BackgroundColor3 = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
    end
    
    btn.MouseButton1Click:Connect(function()
        if isMaster then
            State.Master = not State.Master
            update(State.Master)
        elseif name == "NoclipToggle" then
            State.Noclip = not State.Noclip
            update(State.Noclip)
        else
            State.Items[name] = not State.Items[name]
            update(State.Items[name])
        end
    end)
    
    update(isMaster and State.Master or (name == "NoclipToggle" and State.Noclip or State.Items[name]))
end

createToggle(MainFrame, "MasterToggle", "Master Auto-Buy Toggle", true)
createToggle(MainFrame, "NoclipToggle", "Enable Noclip", false)

for _, cat in ipairs(ItemCategories) do
    for _, item in ipairs(cat.Items) do createToggle(ScrollFrame, item, item, false) end
end

-- ==========================================
-- NOCLIP LOGIC
-- ==========================================
RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ==========================================
-- VIRTUAL INPUT AUTO-BUYER (LITERALLY PRESSES 'E')
-- ==========================================

local function findMyPlot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, plot in ipairs(workspace:WaitForChild("Plots"):GetChildren()) do
        local plotZone = plot:FindFirstChild("PlotZone", true)
        if plotZone and plotZone:IsA("BasePart") then
            local localPos = plotZone.CFrame:PointToObjectSpace(hrp.Position)
            local halfSize = plotZone.Size * 0.5
            if math.abs(localPos.X) <= halfSize.X and math.abs(localPos.Z) <= halfSize.Z then
                return plot
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.2) do
        if not State.Master then continue end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local plot = findMyPlot()
        local activeItems = plot and plot:FindFirstChild("Belt") and plot.Belt:FindFirstChild("ActiveItems")
        if not activeItems then continue end

        local buyableItems = {}
        for _, item in ipairs(activeItems:GetChildren()) do
            if State.Items[item.Name] then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    table.insert(buyableItems, {Prompt = prompt, Priority = ItemPriorityMap[item.Name] or 99})
                end
            end
        end
        table.sort(buyableItems, function(a, b) return a.Priority < b.Priority end)

        for _, target in ipairs(buyableItems) do
            if not State.Master then break end 
            
            local prompt = target.Prompt
            local promptPart = prompt and prompt.Parent

            if prompt and promptPart and promptPart:IsA("BasePart") then
                -- 1. TELEPORT TO THE BUTTON
                local originalCFrame = hrp.CFrame
                hrp.CFrame = CFrame.new(promptPart.Position + Vector3.new(0, 1.5, 0))
                hrp.Anchored = true
                
                -- Wait for the ProximityPrompt UI to actually appear on your screen natively
                task.wait(0.25) 
                
                if prompt.Enabled then
                    -- 2. PHYSICALLY PRESS 'E'
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    
                    -- Hold it down for exactly how long the prompt requires (plus a tiny ping buffer)
                    local holdTime = prompt.HoldDuration > 0 and prompt.HoldDuration or 0.1
                    task.wait(holdTime + 0.1)
                    
                    -- 3. RELEASE 'E'
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
                
                -- 4. CLEANUP & RETURN
                task.wait(0.1)
                hrp.Anchored = false
                hrp.CFrame = originalCFrame
                
                task.wait(0.3) -- Cooldown before the next item
            end
        end
    end
end)
