local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

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

local defaultOff = {
    ["WaterfallUpgrader"] = true,
    ["MalevolentFurnace"] = true
}

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
-- UI CONSTRUCTION (Crash-Proof Edition)
-- ==========================================

local success, GuiTarget = pcall(function() return CoreGui end)
if not success then GuiTarget = LocalPlayer.PlayerGui end

local TycoonGui = Instance.new("ScreenGui")
TycoonGui.Name = "TycoonAutoBuyer"
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

local TopBarExtension = Instance.new("Frame", TopBar)
TopBarExtension.Size = UDim2.new(1, 0, 0, 8)
TopBarExtension.Position = UDim2.new(0, 0, 1, -8)
TopBarExtension.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
TopBarExtension.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Hover-Track Auto-Buyer"
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

-- Draggable UI Logic
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

local currentLayoutOrder = 0

local function createToggleUI(parent, text, color, layoutOrder)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Frame.LayoutOrder = layoutOrder
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

    local Indicator = Instance.new("Frame", Button)
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    local function updateVisuals(state)
        Button.BackgroundColor3 = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
        Indicator.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end

    return Frame, Button, updateVisuals
end

-- Master & Noclip
local MasterContainer = Instance.new("Frame", MainFrame)
MasterContainer.Size = UDim2.new(1, -20, 0, 40)
MasterContainer.Position = UDim2.new(0, 10, 0, 50)
MasterContainer.BackgroundTransparency = 1
local _, MasterBtn, updateMaster = createToggleUI(MasterContainer, "Master Auto-Buy Toggle", nil, 0)

local NoclipContainer = Instance.new("Frame", MainFrame)
NoclipContainer.Size = UDim2.new(1, -20, 0, 40)
NoclipContainer.Position = UDim2.new(0, 10, 0, 95)
NoclipContainer.BackgroundTransparency = 1
local _, NoclipBtn, updateNoclip = createToggleUI(NoclipContainer, "Enable Noclip", nil, 0)

updateMaster(State.Master)
updateNoclip(State.Noclip)

MasterBtn.MouseButton1Click:Connect(function() State.Master = not State.Master updateMaster(State.Master) end)
NoclipBtn.MouseButton1Click:Connect(function() State.Noclip = not State.Noclip updateNoclip(State.Noclip) end)

-- Categories
for _, category in ipairs(ItemCategories) do
    currentLayoutOrder += 1
    local _, CatBtn, updateCat = createToggleUI(ScrollFrame, string.upper(category.Name) .. " (ALL)", category.Color, currentLayoutOrder)
    
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
        currentLayoutOrder += 1
        local _, ItemBtn, updateItem = createToggleUI(ScrollFrame, itemName, nil, currentLayoutOrder)
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
-- GHOST PLATFORM AUTO-BUYER LOGIC
-- ==========================================

local DELAY_BETWEEN_BUYS = 0.2 
local myPlot = nil   

-- Create an invisible platform so the server thinks you are standing, not falling
local HoverPlatform = Instance.new("Part")
HoverPlatform.Name = "AutoBuyPlatform"
HoverPlatform.Size = Vector3.new(10, 1, 10)
HoverPlatform.Anchored = true
HoverPlatform.Transparency = 1
HoverPlatform.CanCollide = true
HoverPlatform.Parent = workspace
HoverPlatform.CFrame = CFrame.new(0, 10000, 0) -- Hide it initially

local function findMyPlot()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
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

local function getSortedItemsOnBelt()
    if not myPlot then
        myPlot = findMyPlot()
        if not myPlot then return {} end
    end

    local belt = myPlot:FindFirstChild("Belt")
    local activeItems = belt and belt:FindFirstChild("ActiveItems")
    if not activeItems then return {} end

    local buyableItems = {}
    
    for _, item in ipairs(activeItems:GetChildren()) do
        if State.Items[item.Name] then
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                table.insert(buyableItems, {
                    Prompt = prompt,
                    Priority = ItemPriorityMap[item.Name] or 99
                })
            end
        end
    end

    table.sort(buyableItems, function(a, b) return a.Priority < b.Priority end)
    return buyableItems
end

-- Safely extracts the world position whether the prompt is on an Attachment, Part, or Model
local function getPromptPos(prompt)
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Model") then return p:GetPivot().Position end
    return nil
end

task.spawn(function()
    while task.wait(0.1) do
        if not State.Master then continue end
        
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targets = getSortedItemsOnBelt()

        for _, target in ipairs(targets) do
            if not State.Master then break end 
            
            local prompt = target.Prompt
            local targetPos = getPromptPos(prompt)

            if prompt and prompt.Enabled and targetPos then
                local originalCFrame = hrp.CFrame
                hrp.Anchored = false -- Must remain false so Humanoid state stays natural
                
                local isTracking = true
                local trackConnection = RunService.Heartbeat:Connect(function()
                    if isTracking and prompt.Parent then
                        local pos = getPromptPos(prompt)
                        if pos then
                            -- Put the platform just beneath the item
                            HoverPlatform.CFrame = CFrame.new(pos - Vector3.new(0, 3, 0))
                            -- Keep player right on top of the item
                            hrp.CFrame = CFrame.new(pos)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end)

                -- The magic fix: Wait 0.35s for the server to acknowledge your new position (Ping Buffer)
                task.wait(0.35) 

                if prompt.Enabled and fireproximityprompt then
                    fireproximityprompt(prompt)
                    -- Small buffer and second fire to guarantee it triggers through ping spikes
                    task.wait(0.05)
                    if prompt.Enabled then fireproximityprompt(prompt) end
                end

                isTracking = false
                trackConnection:Disconnect()
                
                -- Move platform away and snap back
                HoverPlatform.CFrame = CFrame.new(0, 10000, 0)
                hrp.CFrame = originalCFrame
                
                task.wait(DELAY_BETWEEN_BUYS)
            end
        end
    end
end)
