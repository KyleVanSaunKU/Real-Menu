local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Configure defaults
local defaultOn = {
    "HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", "ScienceFurnace", 
    "SirachaUpgrader", "TinDropper", "FireworkUpgrader", "LemonUpgrader", "GoldDropper", "CatUpgrader", 
    "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", "WillowDropper", "CameraUpgrader", 
    "OuroborosUpgrader", "SnowmanUpgrader", "LunarFurnace", "BambooUpgrader", "PumkinUpgrader", 
    "UFOUpgrader", "PotOfGoldFurnace", "LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", 
    "PheonixFurnace", "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper"
}

local defaultOff = {
    "WaterfallUpgrader", "MalevolentFurnace"
}

-- State tracking
local State = {
    Master = false,
    Items = {}
}

for _, item in ipairs(defaultOn) do State.Items[item] = true end
for _, item in ipairs(defaultOff) do State.Items[item] = false end

-- ==========================================
-- UI CONSTRUCTION (Modern / Tailwind Style)
-- ==========================================

local GuiTarget = RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui
local TycoonGui = Instance.new("ScreenGui")
TycoonGui.Name = "TycoonAutoBuyer"
TycoonGui.ResetOnSpawn = false
TycoonGui.Parent = GuiTarget

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 450)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27) -- zinc-900
MainFrame.BorderSizePixel = 0
MainFrame.Parent = TycoonGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(39, 39, 42) -- zinc-800
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

-- Hide bottom corners of top bar
local TopBarExtension = Instance.new("Frame")
TopBarExtension.Size = UDim2.new(1, 0, 0, 8)
TopBarExtension.Position = UDim2.new(0, 0, 1, -8)
TopBarExtension.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
TopBarExtension.BorderSizePixel = 0
TopBarExtension.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Tycoon Auto-Buyer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170) -- zinc-400
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

CloseButton.MouseEnter:Connect(function()
    CloseButton.TextColor3 = Color3.fromRGB(239, 68, 68) -- red-500 on hover
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170) -- revert to zinc-400
end)

CloseButton.MouseButton1Click:Connect(function()
    State.Master = false -- Ensure the buying loop terminates
    TycoonGui:Destroy()  -- completely remove the UI
end)

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.Heartbeat:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- UI Helper to create toggles
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -110)
ScrollFrame.Position = UDim2.new(0, 10, 0, 100)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto updated by UIListLayout
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.Name
UIListLayout.Parent = ScrollFrame

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

local function createToggle(parent, name, text, isMaster)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name
    ToggleFrame.Size = UDim2.new(1, -10, 0, 35)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    ToggleFrame.Parent = parent

    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(0, 6)
    TCorner.Parent = ToggleFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(228, 228, 231)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, -50, 0.5, -10)
    Button.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- red-500 default
    Button.Text = ""
    Button.Parent = ToggleFrame

    local BCorner = Instance.new("UICorner")
    BCorner.CornerRadius = UDim.new(1, 0)
    BCorner.Parent = Button

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = UDim2.new(0, 2, 0.5, -8)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = Button

    local ICorner = Instance.new("UICorner")
    ICorner.CornerRadius = UDim.new(1, 0)
    ICorner.Parent = Indicator

    local function updateVisuals(state)
        local goalColor = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68) -- green-500 / red-500
        local goalPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = goalPos}):Play()
    end

    -- Init visuals
    local startingState = isMaster and State.Master or State.Items[name]
    updateVisuals(startingState)

    Button.MouseButton1Click:Connect(function()
        if isMaster then
            State.Master = not State.Master
            updateVisuals(State.Master)
        else
            State.Items[name] = not State.Items[name]
            updateVisuals(State.Items[name])
        end
    end)
    
    return ToggleFrame
end

-- Create Master Toggle
local MasterContainer = Instance.new("Frame")
MasterContainer.Size = UDim2.new(1, -20, 0, 45)
MasterContainer.Position = UDim2.new(0, 10, 0, 50)
MasterContainer.BackgroundTransparency = 1
MasterContainer.Parent = MainFrame

createToggle(MasterContainer, "MasterToggle", "Master Auto-Buy Toggle", true)

-- Create Item Toggles
local allItems = {}
for _, item in ipairs(defaultOn) do table.insert(allItems, item) end
for _, item in ipairs(defaultOff) do table.insert(allItems, item) end
table.sort(allItems) 

for _, itemName in ipairs(allItems) do
    createToggle(ScrollFrame, itemName, itemName, false)
end

-- ==========================================
-- AUTO-BUYER LOGIC (Spatial Math & Anchoring)
-- ==========================================

local DELAY_BETWEEN_BUYS = 0.5
local itemCache = {} 
local myPlot = nil   

-- Function to calculate plot ownership using spatial math
local function findMyPlot()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end

    local position = hrp.Position
    local plotsFolder = workspace:FindFirstChild("Plots")
    
    if not plotsFolder then return nil end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local plotZone = plot:FindFirstChild("PlotZone", true)
        
        if plotZone and plotZone:IsA("BasePart") then
            local localPos = plotZone.CFrame:PointToObjectSpace(position)
            local halfSize = plotZone.Size * 0.5
            
            if math.abs(localPos.X) <= halfSize.X and math.abs(localPos.Z) <= halfSize.Z then
                return plot
            end
        end
    end

    warn("Could not find a plot. Make sure you are standing completely inside your base's PlotZone!")
    return nil
end

local function getTarget(itemName)
    if itemCache[itemName] and itemCache[itemName].Prompt:IsDescendantOf(workspace) then
        return itemCache[itemName].Pad, itemCache[itemName].Prompt
    end

    if not myPlot then
        myPlot = findMyPlot()
        if not myPlot then return nil, nil end
    end

    local belt = myPlot:FindFirstChild("Belt")
    local activeItems = belt and belt:FindFirstChild("ActiveItems")
    
    if activeItems then
        local targetItem = activeItems:FindFirstChild(itemName)
        
        if targetItem then
            local prompt = targetItem:FindFirstChildWhichIsA("ProximityPrompt", true)
            local pad = targetItem:FindFirstChild("PurchasePad", true) 
                or targetItem:FindFirstChild("Head", true) 
                or targetItem:FindFirstChildWhichIsA("BasePart", true)

            if prompt and pad then
                itemCache[itemName] = {Pad = pad, Prompt = prompt}
                return pad, prompt
            end
        end
    end
    
    return nil, nil
end

task.spawn(function()
    while task.wait(0.1) do
        if not State.Master then continue end
        
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for itemName, isEnabled in pairs(State.Items) do
            if isEnabled and State.Master then
                
                local pad, prompt = getTarget(itemName)
                
                if pad and prompt then
                    -- Kill physical momentum to stop slipping
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    
                    -- Teleport and anchor
                    hrp.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
                    hrp.Anchored = true
                    
                    task.wait(0.2) 
                    
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    
                    task.wait(DELAY_BETWEEN_BUYS)
                    
                    -- Release anchor so player can move again if loop stops
                    hrp.Anchored = false
                end
            end
        end
    end
end)
