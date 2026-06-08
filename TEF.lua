local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- NETWORK BACKDOOR DEFINITION
-- ==========================================
local PacketRemote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Vendor"):WaitForChild("Packet"):WaitForChild("RemoteEvent")

-- ==========================================
-- ITEM CATEGORIES, PRIORITIES & DEFAULTS
-- ==========================================

local ItemCategories = {
    {
        Name = "Mythical", Priority = 1, Color = Color3.fromRGB(236, 72, 153),
        Items = {"LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", "PhoenixFurnace", "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper", "WaterfallUpgrader", "MalevolentFurnace"}
    },
    {
        Name = "Epic", Priority = 2, Color = Color3.fromRGB(168, 85, 247),
        Items = {"CatUpgrader", "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", "WillowDropper", "CameraUpgrader", "OuroborosUpgrader", "SnowmanUpgrader", "LunarFurnace", "BambooUpgrader", "PumpkinUpgrader", "UFOUpgrader", "PotOfGoldFurnace"}
    },
    {
        Name = "Uncommon", Priority = 3, Color = Color3.fromRGB(56, 189, 248),
        Items = {"HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", "ScienceFurnace", "SrirachaUpgrader", "TinDropper", "FireworkUpgrader", "LemonUpgrader", "GoldDropper"}
    }
}

local defaultOff = {["WaterfallUpgrader"] = true, ["MalevolentFurnace"] = true}
local ItemPriorityMap = {}
local State = { Master = false, Noclip = false, Categories = {}, Items = {} }
local VisualUpdaters = {} 

for _, category in ipairs(ItemCategories) do
    State.Categories[category.Name] = true 
    for _, item in ipairs(category.Items) do
        ItemPriorityMap[item] = category.Priority
        State.Items[item] = not defaultOff[item] 
        if defaultOff[item] then State.Categories[category.Name] = false end
    end
end

-- ==========================================
-- UI CONSTRUCTION
-- ==========================================

local TycoonGui = Instance.new("ScreenGui", (RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui))
TycoonGui.Name = "TycoonAutoBuyer"
TycoonGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 300, 0, 500)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Tycoon Auto-Buyer (Hybrid)"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold

local CloseButton = Instance.new("TextButton", TopBar)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170)
CloseButton.MouseButton1Click:Connect(function() TycoonGui:Destroy() end)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -150)
ScrollFrame.Position = UDim2.new(0, 10, 0, 140)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
Instance.new("UIListLayout", ScrollFrame).Padding = UDim.new(0, 5)

local currentLayoutOrder = 0

local function createToggle(parent, name, text, isMaster, categoryData)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 16, 0, 16)
    indicator.Position = UDim2.new(0, 2, 0.5, -8)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local function update(state)
        btn.BackgroundColor3 = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
        indicator.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end
    VisualUpdaters[name] = update
    
    btn.MouseButton1Click:Connect(function()
        if isMaster then State.Master = not State.Master update(State.Master)
        elseif name == "NoclipToggle" then State.Noclip = not State.Noclip update(State.Noclip)
        elseif categoryData then
            State.Categories[categoryData.Name] = not State.Categories[categoryData.Name]
            local s = State.Categories[categoryData.Name]
            update(s)
            for _, item in ipairs(categoryData.Items) do
                State.Items[item] = s
                if VisualUpdaters[item] then VisualUpdaters[item](s) end
            end
        else State.Items[name] = not State.Items[name] update(State.Items[name]) end
    end)
    update(isMaster and State.Master or (categoryData and State.Categories[categoryData.Name] or (name == "NoclipToggle" and State.Noclip or State.Items[name])))
end

createToggle(MainFrame, "Master", "Master Auto-Buy", true)
createToggle(MainFrame, "NoclipToggle", "Enable Noclip", false)
for _, cat in ipairs(ItemCategories) do
    createToggle(ScrollFrame, cat.Name, cat.Name .. " (ALL)", false, cat)
    for _, item in ipairs(cat.Items) do createToggle(ScrollFrame, item, item, false) end
end

-- ==========================================
-- AUTO-BUYER LOGIC
-- ==========================================

RunService.Stepped:Connect(function()
    if State.Noclip then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if not State.Master then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- Find Plot
        local plot = nil
        for _, p in ipairs(workspace.Plots:GetChildren()) do
            local z = p:FindFirstChild("PlotZone", true)
            if z and z:IsA("BasePart") then
                local pos = z.CFrame:PointToObjectSpace(hrp.Position)
                local size = z.Size * 0.5
                if math.abs(pos.X) <= size.X and math.abs(pos.Z) <= size.Z then plot = p break end
            end
        end
        
        if not plot then continue end
        local active = plot:FindFirstChild("Belt") and plot.Belt:FindFirstChild("ActiveItems")
        if not active then continue end

        local targets = {}
        for _, item in ipairs(active:GetChildren()) do
            if State.Items[item.Name] then
                table.insert(targets, {Instance = item, Prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true), Pad = item:FindFirstChild("PurchasePad", true) or item:FindFirstChildWhichIsA("BasePart", true)})
            end
        end

        for _, t in ipairs(targets) do
            if not State.Master then break end
            
            -- PHYSICAL SYNC
            hrp.CFrame = CFrame.new(t.Pad.Position + Vector3.new(0, 1.5, 0))
            hrp.Anchored = true
            task.wait(0.05)
            
            -- NETWORK BACKDOOR + PHYSICAL TRIGGER
            pcall(function() PacketRemote:FireServer("purchase_belt_item", t.Instance) end)
            if t.Prompt then pcall(function() t.Prompt:Triggered(LocalPlayer) end) end
            
            task.wait(0.15)
            hrp.Anchored = false
            task.wait(0.1)
        end
    end
end)
