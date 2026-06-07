local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ITEM CATEGORIES, PRIORITIES & DEFAULTS
-- ==========================================

local ItemCategories = {
    {
        Name = "Mythical",
        Priority = 1,
        Color = Color3.fromRGB(236, 72, 153), 
        Items = {
            "LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", "PhoenixFurnace", 
            "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper", "WaterfallUpgrader", "MalevolentFurnace"
        }
    },
    {
        Name = "Epic",
        Priority = 2,
        Color = Color3.fromRGB(168, 85, 247), 
        Items = {
            "CatUpgrader", "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", 
            "WillowDropper", "CameraUpgrader", "OuroborosUpgrader", "SnowmanUpgrader", 
            "LunarFurnace", "BambooUpgrader", "PumpkinUpgrader", "UFOUpgrader", "PotOfGoldFurnace"
        }
    },
    {
        Name = "Uncommon",
        Priority = 3,
        Color = Color3.fromRGB(56, 189, 248), 
        Items = {
            "HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", 
            "ScienceFurnace", "SrirachaUpgrader", "TinDropper", "FireworkUpgrader", 
            "LemonUpgrader", "GoldDropper"
        }
    }
}

local defaultOff = {
    ["WaterfallUpgrader"] = true,
    ["MalevolentFurnace"] = true
}

local ItemPriorityMap = {}
local State = {
    Master = false,
    Noclip = false, -- Noclip restored
    Categories = {},
    Items = {}
}
local VisualUpdaters = {} 

for _, category in ipairs(ItemCategories) do
    State.Categories[category.Name] = true 
    for _, item in ipairs(category.Items) do
        ItemPriorityMap[item] = category.Priority
        State.Items[item] = not defaultOff[item] 
        if defaultOff[item] then
            State.Categories[category.Name] = false
        end
    end
end

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
MainFrame.Size = UDim2.new(0, 300, 0, 500) -- Taller to fit Noclip
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27) 
MainFrame.BorderSizePixel = 0
MainFrame.Parent = TycoonGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(39, 39, 42) 
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

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

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

CloseButton.MouseEnter:Connect(function() CloseButton.TextColor3 = Color3.fromRGB(239, 68, 68) end)
CloseButton.MouseLeave:Connect(function() CloseButton.TextColor3 = Color3.fromRGB(161, 161, 170) end)

CloseButton.MouseButton1Click:Connect(function()
    State.Master = false 
    State.Noclip = false
    TycoonGui:Destroy()  
end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -150) -- Adjusted for Noclip
ScrollFrame.Position = UDim2.new(0, 10, 0, 140)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder 
UIListLayout.Parent = ScrollFrame

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

local currentLayoutOrder = 0

local function createCategoryHeader(parent, category)
    currentLayoutOrder += 1
    
    local HeaderFrame = Instance.new("Frame")
    HeaderFrame.Size = UDim2.new(1, -10, 0, 32)
    HeaderFrame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    HeaderFrame.BackgroundTransparency = 0.5 
    HeaderFrame.LayoutOrder = currentLayoutOrder
    HeaderFrame.Parent = parent

    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 6)
    HCorner.Parent = HeaderFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(category.Name) .. " (ALL)"
    Label.TextColor3 = category.Color
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = HeaderFrame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 40, 0, 20)
    Button.Position = UDim2.new(1, -50, 0.5, -10)
    Button.BackgroundColor3 = Color3.fromRGB(239, 68, 68) 
    Button.Text = ""
    Button.Parent = HeaderFrame

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
        local goalColor = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68) 
        local goalPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = goalPos}):Play()
    end

    VisualUpdaters[category.Name] = updateVisuals
    updateVisuals(State.Categories[category.Name])

    Button.MouseButton1Click:Connect(function()
        local newState = not State.Categories[category.Name]
        State.Categories[category.Name] = newState
        updateVisuals(newState)
        
        for _, item in ipairs(category.Items) do
            State.Items[item] = newState
            if VisualUpdaters[item] then VisualUpdaters[item](newState) end
        end
    end)
end

local function createToggle(parent, name, text, toggleType)
    if toggleType == "Item" then currentLayoutOrder += 1 end
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name
    ToggleFrame.Size = UDim2.new(1, -10, 0, 35)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    ToggleFrame.LayoutOrder = toggleType == "Item" and currentLayoutOrder or 0
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
    Button.BackgroundColor3 = Color3.fromRGB(239, 68, 68) 
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
        local goalColor = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68) 
        local goalPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = goalColor}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = goalPos}):Play()
    end

    VisualUpdaters[name] = updateVisuals

    local startingState = false
    if toggleType == "Master" then startingState = State.Master
    elseif toggleType == "Noclip" then startingState = State.Noclip
    else startingState = State.Items[name] end
    
    updateVisuals(startingState)

    Button.MouseButton1Click:Connect(function()
        if toggleType == "Master" then
            State.Master = not State.Master
            updateVisuals(State.Master)
        elseif toggleType == "Noclip" then
            State.Noclip = not State.Noclip
            updateVisuals(State.Noclip)
        else
            State.Items[name] = not State.Items[name]
            updateVisuals(State.Items[name])
        end
    end)
    return ToggleFrame
end

local MasterContainer = Instance.new("Frame")
MasterContainer.Size = UDim2.new(1, -20, 0, 40)
MasterContainer.Position = UDim2.new(0, 10, 0, 50)
MasterContainer.BackgroundTransparency = 1
MasterContainer.Parent = MainFrame

createToggle(MasterContainer, "MasterToggle", "Master Auto-Buy Toggle", "Master")

local NoclipContainer = Instance.new("Frame")
NoclipContainer.Size = UDim2.new(1, -20, 0, 40)
NoclipContainer.Position = UDim2.new(0, 10, 0, 95)
NoclipContainer.BackgroundTransparency = 1
NoclipContainer.Parent = MainFrame

createToggle(NoclipContainer, "NoclipToggle", "Enable Noclip", "Noclip")

for _, category in ipairs(ItemCategories) do
    createCategoryHeader(ScrollFrame, category)
    for _, itemName in ipairs(category.Items) do
        createToggle(ScrollFrame, itemName, itemName, "Item")
    end
end

-- ==========================================
-- NOCLIP LOGIC (RunService Stepped)
-- ==========================================
RunService.Stepped:Connect(function()
    if State.Noclip then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==========================================
-- AUTO-BUYER LOGIC (100% Legitimate Simulation)
-- ==========================================

local DELAY_BETWEEN_BUYS = 0.2 
local myPlot = nil   

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
            local pad = item:FindFirstChild("PurchasePad", true) or item:FindFirstChild("Head", true) or item:FindFirstChildWhichIsA("BasePart", true)
            
            if prompt and pad then
                table.insert(buyableItems, {
                    Prompt = prompt,
                    Pad = pad,
                    Priority = ItemPriorityMap[item.Name] or 99
                })
            end
        end
    end

    table.sort(buyableItems, function(a, b)
        return a.Priority < b.Priority
    end)

    return buyableItems
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
            
            local pad = target.Pad
            local prompt = target.Prompt

            if pad and pad.Parent and prompt and prompt.Parent then
                hrp.Anchored = true
                
                -- The "Glue": Continuously updates position to track the moving item
                local isTracking = true
                local trackConnection = RunService.Heartbeat:Connect(function()
                    if isTracking and pad and pad.Parent then
                        -- Hovering 2.5 studs up ensures we don't clip inside the mesh, keeping Line Of Sight clear!
                        hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 2.5, 0))
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
                
                -- Wait 0.2s while tracking so the server registers we are standing on the item
                task.wait(0.2)
                
                if prompt.Enabled then
                    -- We NO LONGER spoof LineOfSight, Distance, or HoldDuration. 
                    -- We play by the game's rules to bypass the server checks.
                    
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    
                    -- THE FIX: Stay glued to the part for the exact required HoldDuration so the server accepts it!
                    local requiredHoldTime = prompt.HoldDuration or 0
                    task.wait(requiredHoldTime + 0.15) -- Add 0.15s ping buffer
                end
                
                -- Un-glue and move to the next item
                isTracking = false
                trackConnection:Disconnect()
                hrp.Anchored = false
                
                task.wait(DELAY_BETWEEN_BUYS)
            end
        end
    end
end)
