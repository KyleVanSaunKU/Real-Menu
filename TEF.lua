local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ITEM CONFIGURATION
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
local State = { Master = false, Categories = {}, Items = {} }
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

local GuiTarget = RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui
local TycoonGui = Instance.new("ScreenGui")
TycoonGui.Name = "TycoonAutoBuyer"
TycoonGui.ResetOnSpawn = false
TycoonGui.Parent = GuiTarget

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 480)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = TycoonGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Tycoon Auto-Buyer (Direct)"
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
ScrollFrame.Size = UDim2.new(1, -20, 1, -110)
ScrollFrame.Position = UDim2.new(0, 10, 0, 100)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 5)

local currentLayoutOrder = 0

local function createToggle(parent, name, text, isMaster, categoryData)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
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
        if isMaster then
            State.Master = not State.Master
            update(State.Master)
        elseif categoryData then
            State.Categories[categoryData.Name] = not State.Categories[categoryData.Name]
            local s = State.Categories[categoryData.Name]
            update(s)
            for _, item in ipairs(categoryData.Items) do
                State.Items[item] = s
                if VisualUpdaters[item] then VisualUpdaters[item](s) end
            end
        else
            State.Items[name] = not State.Items[name]
            update(State.Items[name])
        end
    end)
    update(isMaster and State.Master or (categoryData and State.Categories[categoryData.Name] or State.Items[name]))
end

createToggle(MainFrame, "Master", "Master Auto-Buy", true)
for _, cat in ipairs(ItemCategories) do
    createToggle(ScrollFrame, cat.Name, cat.Name .. " (ALL)", false, cat)
    for _, item in ipairs(cat.Items) do createToggle(ScrollFrame, item, item, false) end
end

-- ==========================================
-- AUTO-BUYER LOGIC (Direct Trigger)
-- ==========================================

local function getMyPlot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, plot in ipairs(workspace:FindFirstChild("Plots"):GetChildren()) do
        local zone = plot:FindFirstChild("PlotZone", true)
        if zone and zone:IsA("BasePart") then
            local p = zone.CFrame:PointToObjectSpace(hrp.Position)
            local s = zone.Size * 0.5
            if math.abs(p.X) <= s.X and math.abs(p.Z) <= s.Z then return plot end
        end
    end
end

task.spawn(function()
    while task.wait(0.3) do
        if not State.Master then continue end
        local plot = getMyPlot()
        local activeItems = plot and plot:FindFirstChild("Belt") and plot.Belt:FindFirstChild("ActiveItems")
        if not activeItems then continue end

        local triggerArgs = {[1] = LocalPlayer}
        for _, item in ipairs(activeItems:GetChildren()) do
            if State.Items[item.Name] then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    pcall(function() prompt:Triggered(table.unpack(triggerArgs)) end)
                    task.wait(0.05)
                end
            end
        end
    end
end)
