local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

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
local State = { Master = false, Noclip = false, Categories = {}, Items = {} }
local VisualUpdaters = {}

for _, category in ipairs(ItemCategories) do
    State.Categories[category.Name] = true 
    for _, item in ipairs(category.Items) do
        State.Items[item] = not defaultOff[item] 
        if defaultOff[item] then State.Categories[category.Name] = false end
    end
end

-- ==========================================
-- UI CONSTRUCTION (Crash-Proof Edition)
-- ==========================================
local success, GuiTarget = pcall(function() return CoreGui end)
if not success then GuiTarget = LocalPlayer.PlayerGui end

local TycoonGui = Instance.new("ScreenGui")
TycoonGui.Name = "TycoonWalkByBuyer"
TycoonGui.ResetOnSpawn = false
TycoonGui.Parent = GuiTarget

local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 300, 0, 500) 
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27) 
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(39, 39, 42) 
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Walk-By Auto-Buyer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton", TopBar)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170)
CloseButton.Font = Enum.Font.GothamBold

CloseButton.MouseButton1Click:Connect(function()
    State.Master = false 
    State.Noclip = false
    TycoonGui:Destroy()  
end)

-- Make UI Draggable
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
RunService.Heartbeat:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
ScrollFrame.Size = UDim2.new(1, -20, 1, -150) 
ScrollFrame.Position = UDim2.new(0, 10, 0, 140)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
Instance.new("UIListLayout", ScrollFrame).Padding = UDim.new(0, 5)

-- Toggle Generator
local function createToggleUI(parent, text, color)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color or Color3.fromRGB(228, 228, 231)
    Label.TextSize = color and 12 or 14
    Label.Font = color and Enum.Font.GothamBold or Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Button = Instance.new("TextButton", Frame)
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, -50, 0.5, -10)
    Button.Text = ""
    Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0)

    local function updateVisuals(state)
        Button.BackgroundColor3 = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
    end
    return Button, updateVisuals
end

-- Master & Noclip Toggles
local MasterContainer = Instance.new("Frame", MainFrame)
MasterContainer.Size = UDim2.new(1, -20, 0, 40)
MasterContainer.Position = UDim2.new(0, 10, 0, 50)
MasterContainer.BackgroundTransparency = 1
local MasterBtn, updateMaster = createToggleUI(MasterContainer, "Master Auto-Buy Toggle")

local NoclipContainer = Instance.new("Frame", MainFrame)
NoclipContainer.Size = UDim2.new(1, -20, 0, 40)
NoclipContainer.Position = UDim2.new(0, 10, 0, 95)
NoclipContainer.BackgroundTransparency = 1
local NoclipBtn, updateNoclip = createToggleUI(NoclipContainer, "Enable Noclip")

updateMaster(State.Master)
updateNoclip(State.Noclip)

MasterBtn.MouseButton1Click:Connect(function() State.Master = not State.Master updateMaster(State.Master) end)
NoclipBtn.MouseButton1Click:Connect(function() State.Noclip = not State.Noclip updateNoclip(State.Noclip) end)

-- Category & Item Toggles
for _, category in ipairs(ItemCategories) do
    local CatBtn, updateCat = createToggleUI(ScrollFrame, string.upper(category.Name) .. " (ALL)", category.Color)
    VisualUpdaters[category.Name] = updateCat
    updateCat(State.Categories[category.Name])

    CatBtn.MouseButton1Click:Connect(function()
        local newState = not State.Categories[category.Name]
        State.Categories[category.Name] = newState
        updateCat(newState)
        for _, item in ipairs(category.Items) do
            State.Items[item] = newState
            if VisualUpdaters[item] then VisualUpdaters[item](newState) end
        end
    end)

    for _, itemName in ipairs(category.Items) do
        local ItemBtn, updateItem = createToggleUI(ScrollFrame, itemName)
        VisualUpdaters[itemName] = updateItem
        updateItem(State.Items[itemName])

        ItemBtn.MouseButton1Click:Connect(function()
            State.Items[itemName] = not State.Items[itemName]
            updateItem(State.Items[itemName])
        end)
    end
end

-- ==========================================
-- NOCLIP LOGIC
-- ==========================================
RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ==========================================
-- WALK-BY AUTO-BUYER LOGIC (ZERO TELEPORTING)
-- ==========================================

task.spawn(function()
    -- Fast loop because you are walking and the window of opportunity is small
    while task.wait(0.05) do
        if not State.Master then continue end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Find the plot you are currently standing in
        local currentPlot = nil
        for _, plot in ipairs(workspace:WaitForChild("Plots"):GetChildren()) do
            local plotZone = plot:FindFirstChild("PlotZone", true)
            if plotZone and plotZone:IsA("BasePart") then
                local localPos = plotZone.CFrame:PointToObjectSpace(hrp.Position)
                local halfSize = plotZone.Size * 0.5
                -- Expanded Y buffer so it still registers if you jump
                if math.abs(localPos.X) <= halfSize.X and math.abs(localPos.Z) <= halfSize.Z then
                    currentPlot = plot
                    break
                end
            end
        end

        if not currentPlot then continue end
        local activeItems = currentPlot:FindFirstChild("Belt") and currentPlot.Belt:FindFirstChild("ActiveItems")
        if not activeItems then continue end

        -- Scan items on the belt
        for _, item in ipairs(activeItems:GetChildren()) do
            -- Only check items you have turned ON
            if State.Items[item.Name] then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                local promptPart = prompt and prompt.Parent

                if prompt and prompt.Enabled and promptPart and promptPart:IsA("BasePart") then
                    -- Calculate actual distance between you and the button
                    local distance = (hrp.Position - promptPart.Position).Magnitude
                    local maxDist = prompt.MaxActivationDistance or 10
                    
                    -- If you are close enough, fire it instantly
                    if distance <= maxDist + 2 then 
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end
end)
