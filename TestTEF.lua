local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ITEM CATEGORIES, PRIORITIES & COLORS
-- ==========================================

local JunkyardCategories = {
    {
        Name = "Junkyard Mythical", Priority = 1, Color = Color3.fromRGB(239, 68, 68),
        Items = {"WindmillUpgrader", "CarWashUpgrader"}
    },
    {
        Name = "Junkyard Legendary", Priority = 2, Color = Color3.fromRGB(234, 179, 8),
        Items = {"BirdhouseDropper", "MoaiUpgrader", "BeetleUpgrader", "JunkUpgrader"}
    },
    {
        Name = "Junkyard Epic", Priority = 3, Color = Color3.fromRGB(168, 85, 247),
        Items = {"HorseshoeUpgrader", "PaintbrushUpgrader", "GuillotineUpgrader"}
    },
    {
        Name = "Junkyard Rare", Priority = 4, Color = Color3.fromRGB(56, 189, 248),
        Items = {"BreadUpgrader", "HotTubFurnace", "SnailUpgrader", "BurgerUpgrader"}
    },
    {
        Name = "Junkyard Uncommon", Priority = 5, Color = Color3.fromRGB(34, 197, 94),
        Items = {"FidgetSpinnerUpgrader", "ToiletDropper", "ToiletPaperUpgrader", "TeddyBearUpgrader"}
    },
    {
        Name = "Junkyard Common", Priority = 6, Color = Color3.fromRGB(255, 255, 255),
        Items = {"TungUpgrader", "ElectricFanUpgrader", "CasetteUpgrader", "DominoUpgrader", "IceCreamUpgrader"}
    }
}

local ItemCategories = {
    {
        Name = "Mythical", Priority = 1, Color = Color3.fromRGB(239, 68, 68),
        Items = {"LaserSwordUpgrader", "HotAirBalloonUpgrader", "JesterDropper", "PhoenixFurnace", "GramophoneDropper", "GhosdeeriUpgrader", "JadeDropper", "WaterfallUpgrader", "MalevolentFurnace"}
    },
    {
        Name = "Legendary", Priority = 2, Color = Color3.fromRGB(234, 179, 8),
        Items = {"ExcaliburUpgrader", "DinoUpgrader", "RubyDropper", "SatelliteUpgrader", "ScissorUpgrader", "AmethystDropper", "ButterflyFurnace", "RobosharkUpgrader", "ClioneUpgrader", "KrakenFurnace", "TopazDropper", "TomeFurnace", "VolcanicFurnace"}
    },
    {
        Name = "Epic", Priority = 3, Color = Color3.fromRGB(168, 85, 247),
        Items = {"CatUpgrader", "EmeraldFurnace", "LightningFurnace", "WateringCanUpgrader", "WillowDropper", "CameraUpgrader", "OuroborosUpgrader", "SnowmanUpgrader", "LunarFurnace", "BambooUpgrader", "PumpkinUpgrader", "UFOUpgrader", "PotOfGoldFurnace"}
    },
    {
        Name = "Rare", Priority = 4, Color = Color3.fromRGB(56, 189, 248),
        Items = {"GoalieFurnace", "SandcastleUpgrader", "CactusFurnace", "ChessUpgrader", "HeadphonesUpgrader", "CakeUpgrader", "IglooUpgrader", "SapphireDropper", "CheeseDropper", "MushroomUpgrader", "DonutUpgrader", "RubberDuckyUpgrader"}
    },
    {
        Name = "Uncommon", Priority = 5, Color = Color3.fromRGB(34, 197, 94),
        Items = {"HippoUpgrader", "MagnifyingUpgrader", "UltraUpgrader", "CheesestickUpgrader", "ScienceFurnace", "SrirachaUpgrader", "TinDropper", "FireworkUpgrader", "LemonUpgrader", "GoldDropper"}
    },
    {
        Name = "Common", Priority = 6, Color = Color3.fromRGB(255, 255, 255),
        Items = {"BasicDropper", "BasicFurnace", "BasicUpgrader", "AdvancedUpgrader", "FishboneUpgrader", "CopperDropper", "NetworkFurnace", "PuzzleUpgrader", "SoccerUpgrader", "TrafficConeUpgrader"}
    }
}

local ItemPriorityMap = {}
local State = { Master = false, Noclip = false, Categories = {}, Items = {} }
local VisualUpdaters = {} 
local IsJunkyardItem = {}
local IsBeltItem = {}

for _, category in ipairs(JunkyardCategories) do
    State.Categories[category.Name] = { Normal = false, Gold = false }
    for _, item in ipairs(category.Items) do
        ItemPriorityMap[item] = category.Priority
        State.Items[item] = { Normal = false, Gold = false }
        IsJunkyardItem[item] = true
    end
end

for _, category in ipairs(ItemCategories) do
    State.Categories[category.Name] = { Normal = false, Gold = false, Junk = false }
    for _, item in ipairs(category.Items) do
        ItemPriorityMap[item] = category.Priority
        State.Items[item] = { Normal = false, Gold = false, Junk = false }
        IsBeltItem[item] = true
    end
end

-- ==========================================
-- UI CONSTRUCTION
-- ==========================================

local success, GuiTarget = pcall(function() return CoreGui end)
if not success then GuiTarget = LocalPlayer.PlayerGui end

local TycoonGui = Instance.new("ScreenGui")
TycoonGui.Name = "TycoonAutoBuyer"
TycoonGui.ResetOnSpawn = false
TycoonGui.Parent = GuiTarget

local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 350, 0, 500) 
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
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
Title.Text = "The Everything Factory - Exploits Menu"
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

local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 5)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

local currentLayoutOrder = 0

local function createSingleToggleUI(parent, text, layoutOrder)
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
    Label.TextColor3 = Color3.fromRGB(228, 228, 231)
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamMedium
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

local function createDualToggleUI(parent, text, color, layoutOrder)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Frame.LayoutOrder = layoutOrder
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -100, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color or Color3.fromRGB(228, 228, 231)
    Label.TextSize = color and 12 or 14
    Label.Font = color and Enum.Font.GothamBold or Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local NormBtn = Instance.new("TextButton", Frame)
    NormBtn.Size = UDim2.new(0, 40, 0, 20)
    NormBtn.Position = UDim2.new(1, -95, 0.5, -10)
    NormBtn.Text = ""
    Instance.new("UICorner", NormBtn).CornerRadius = UDim.new(1, 0)
    local NormInd = Instance.new("Frame", NormBtn)
    NormInd.Size = UDim2.new(0, 16, 0, 16)
    NormInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", NormInd).CornerRadius = UDim.new(1, 0)
    local NormLabel = Instance.new("TextLabel", Frame)
    NormLabel.Size = UDim2.new(0, 40, 0, 10)
    NormLabel.Position = UDim2.new(1, -95, 0.5, 10)
    NormLabel.BackgroundTransparency = 1
    NormLabel.Text = "NORM"
    NormLabel.TextColor3 = Color3.fromRGB(161, 161, 170)
    NormLabel.TextSize = 9
    NormLabel.Font = Enum.Font.GothamBold

    local GoldBtn = Instance.new("TextButton", Frame)
    GoldBtn.Size = UDim2.new(0, 40, 0, 20)
    GoldBtn.Position = UDim2.new(1, -50, 0.5, -10)
    GoldBtn.Text = ""
    Instance.new("UICorner", GoldBtn).CornerRadius = UDim.new(1, 0)
    local GoldInd = Instance.new("Frame", GoldBtn)
    GoldInd.Size = UDim2.new(0, 16, 0, 16)
    GoldInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", GoldInd).CornerRadius = UDim.new(1, 0)
    local GoldLabel = Instance.new("TextLabel", Frame)
    GoldLabel.Size = UDim2.new(0, 40, 0, 10)
    GoldLabel.Position = UDim2.new(1, -50, 0.5, 10)
    GoldLabel.BackgroundTransparency = 1
    GoldLabel.Text = "GOLD"
    GoldLabel.TextColor3 = Color3.fromRGB(161, 161, 170)
    GoldLabel.TextSize = 9
    GoldLabel.Font = Enum.Font.GothamBold

    local function updateVisuals(normState, goldState)
        NormBtn.BackgroundColor3 = normState and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
        NormInd.Position = normState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        GoldBtn.BackgroundColor3 = goldState and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(82, 82, 91)
        GoldInd.Position = goldState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end
    return Frame, NormBtn, GoldBtn, updateVisuals
end

local function createTripleToggleUI(parent, text, color, layoutOrder)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 32)
    Frame.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    Frame.LayoutOrder = layoutOrder
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -145, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = color or Color3.fromRGB(228, 228, 231)
    Label.TextSize = color and 12 or 14
    Label.Font = color and Enum.Font.GothamBold or Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local NormBtn = Instance.new("TextButton", Frame)
    NormBtn.Size = UDim2.new(0, 40, 0, 20)
    NormBtn.Position = UDim2.new(1, -140, 0.5, -10)
    NormBtn.Text = ""
    Instance.new("UICorner", NormBtn).CornerRadius = UDim.new(1, 0)
    local NormInd = Instance.new("Frame", NormBtn)
    NormInd.Size = UDim2.new(0, 16, 0, 16)
    NormInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", NormInd).CornerRadius = UDim.new(1, 0)
    local NormLabel = Instance.new("TextLabel", Frame)
    NormLabel.Size = UDim2.new(0, 40, 0, 10)
    NormLabel.Position = UDim2.new(1, -140, 0.5, 10)
    NormLabel.BackgroundTransparency = 1
    NormLabel.Text = "NORM"
    NormLabel.TextColor3 = Color3.fromRGB(161, 161, 170)
    NormLabel.TextSize = 9
    NormLabel.Font = Enum.Font.GothamBold

    local GoldBtn = Instance.new("TextButton", Frame)
    GoldBtn.Size = UDim2.new(0, 40, 0, 20)
    GoldBtn.Position = UDim2.new(1, -95, 0.5, -10)
    GoldBtn.Text = ""
    Instance.new("UICorner", GoldBtn).CornerRadius = UDim.new(1, 0)
    local GoldInd = Instance.new("Frame", GoldBtn)
    GoldInd.Size = UDim2.new(0, 16, 0, 16)
    GoldInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", GoldInd).CornerRadius = UDim.new(1, 0)
    local GoldLabel = Instance.new("TextLabel", Frame)
    GoldLabel.Size = UDim2.new(0, 40, 0, 10)
    GoldLabel.Position = UDim2.new(1, -95, 0.5, 10)
    GoldLabel.BackgroundTransparency = 1
    GoldLabel.Text = "GOLD"
    GoldLabel.TextColor3 = Color3.fromRGB(161, 161, 170)
    GoldLabel.TextSize = 9
    GoldLabel.Font = Enum.Font.GothamBold

    local JunkBtn = Instance.new("TextButton", Frame)
    JunkBtn.Size = UDim2.new(0, 40, 0, 20)
    JunkBtn.Position = UDim2.new(1, -50, 0.5, -10)
    JunkBtn.Text = ""
    Instance.new("UICorner", JunkBtn).CornerRadius = UDim.new(1, 0)
    local JunkInd = Instance.new("Frame", JunkBtn)
    JunkInd.Size = UDim2.new(0, 16, 0, 16)
    JunkInd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", JunkInd).CornerRadius = UDim.new(1, 0)
    local JunkLabel = Instance.new("TextLabel", Frame)
    JunkLabel.Size = UDim2.new(0, 40, 0, 10)
    JunkLabel.Position = UDim2.new(1, -50, 0.5, 10)
    JunkLabel.BackgroundTransparency = 1
    JunkLabel.Text = "JUNK"
    JunkLabel.TextColor3 = Color3.fromRGB(161, 161, 170)
    JunkLabel.TextSize = 9
    JunkLabel.Font = Enum.Font.GothamBold

    local function updateVisuals(normState, goldState, junkState)
        NormBtn.BackgroundColor3 = normState and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
        NormInd.Position = normState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        GoldBtn.BackgroundColor3 = goldState and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(82, 82, 91)
        GoldInd.Position = goldState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        
        JunkBtn.BackgroundColor3 = junkState and Color3.fromRGB(139, 69, 19) or Color3.fromRGB(82, 82, 91)
        JunkInd.Position = junkState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    end
    return Frame, NormBtn, GoldBtn, JunkBtn, updateVisuals
end

local function createSectionHeaderUI(parent, text, layoutOrder)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, -10, 0, 24)
    Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    Frame.LayoutOrder = layoutOrder
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(150, 150, 150)
    Label.TextSize = 11
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Center
    return Frame
end

local MasterContainer = Instance.new("Frame", MainFrame)
MasterContainer.Size = UDim2.new(1, -20, 0, 40)
MasterContainer.Position = UDim2.new(0, 10, 0, 50)
MasterContainer.BackgroundTransparency = 1
local _, MasterBtn, updateMaster = createSingleToggleUI(MasterContainer, "Enable Auto-Buy", 0)

local NoclipContainer = Instance.new("Frame", MainFrame)
NoclipContainer.Size = UDim2.new(1, -20, 0, 40)
NoclipContainer.Position = UDim2.new(0, 10, 0, 95)
NoclipContainer.BackgroundTransparency = 1
local _, NoclipBtn, updateNoclip = createSingleToggleUI(NoclipContainer, "Enable Noclip", 0)

updateMaster(State.Master)
updateNoclip(State.Noclip)

MasterBtn.MouseButton1Click:Connect(function() State.Master = not State.Master updateMaster(State.Master) end)
NoclipBtn.MouseButton1Click:Connect(function() State.Noclip = not State.Noclip updateNoclip(State.Noclip) end)

local function populateJunkyardCategoryUI(categoriesList, headerText)
    currentLayoutOrder += 1
    createSectionHeaderUI(ScrollFrame, headerText, currentLayoutOrder)

    for _, category in ipairs(categoriesList) do
        currentLayoutOrder += 1
        local _, CatMain, CatGold, updateCat = createDualToggleUI(ScrollFrame, string.upper(category.Name) .. " (ALL)", category.Color, currentLayoutOrder)
        updateCat(false, false)

        CatMain.MouseButton1Click:Connect(function()
            State.Categories[category.Name].Normal = not State.Categories[category.Name].Normal
            for _, item in ipairs(category.Items) do 
                State.Items[item].Normal = State.Categories[category.Name].Normal
                if VisualUpdaters[item] then VisualUpdaters[item](State.Items[item].Normal, State.Items[item].Gold) end
            end
            updateCat(State.Categories[category.Name].Normal, State.Categories[category.Name].Gold)
        end)
        
        CatGold.MouseButton1Click:Connect(function()
            State.Categories[category.Name].Gold = not State.Categories[category.Name].Gold
            for _, item in ipairs(category.Items) do 
                State.Items[item].Gold = State.Categories[category.Name].Gold
                if VisualUpdaters[item] then VisualUpdaters[item](State.Items[item].Normal, State.Items[item].Gold) end
            end
            updateCat(State.Categories[category.Name].Normal, State.Categories[category.Name].Gold)
        end)

        for _, itemName in ipairs(category.Items) do
            currentLayoutOrder += 1
            local _, ItemMain, ItemGold, updateItem = createDualToggleUI(ScrollFrame, itemName, nil, currentLayoutOrder)
            VisualUpdaters[itemName] = updateItem
            updateItem(false, false)

            ItemMain.MouseButton1Click:Connect(function()
                State.Items[itemName].Normal = not State.Items[itemName].Normal
                updateItem(State.Items[itemName].Normal, State.Items[itemName].Gold)
            end)
            ItemGold.MouseButton1Click:Connect(function()
                State.Items[itemName].Gold = not State.Items[itemName].Gold
                updateItem(State.Items[itemName].Normal, State.Items[itemName].Gold)
            end)
        end
    end
end

local function populateBeltCategoryUI(categoriesList, headerText)
    currentLayoutOrder += 1
    createSectionHeaderUI(ScrollFrame, headerText, currentLayoutOrder)

    for _, category in ipairs(categoriesList) do
        currentLayoutOrder += 1
        local _, CatNorm, CatGold, CatJunk, updateCat = createTripleToggleUI(ScrollFrame, string.upper(category.Name) .. " (ALL)", category.Color, currentLayoutOrder)
        updateCat(false, false, false)

        CatNorm.MouseButton1Click:Connect(function()
            State.Categories[category.Name].Normal = not State.Categories[category.Name].Normal
            for _, item in ipairs(category.Items) do 
                State.Items[item].Normal = State.Categories[category.Name].Normal
                if VisualUpdaters[item] then VisualUpdaters[item](State.Items[item].Normal, State.Items[item].Gold, State.Items[item].Junk) end
            end
            updateCat(State.Categories[category.Name].Normal, State.Categories[category.Name].Gold, State.Categories[category.Name].Junk)
        end)
        
        CatGold.MouseButton1Click:Connect(function()
            State.Categories[category.Name].Gold = not State.Categories[category.Name].Gold
            for _, item in ipairs(category.Items) do 
                State.Items[item].Gold = State.Categories[category.Name].Gold
                if VisualUpdaters[item] then VisualUpdaters[item](State.Items[item].Normal, State.Items[item].Gold, State.Items[item].Junk) end
            end
            updateCat(State.Categories[category.Name].Normal, State.Categories[category.Name].Gold, State.Categories[category.Name].Junk)
        end)

        CatJunk.MouseButton1Click:Connect(function()
            State.Categories[category.Name].Junk = not State.Categories[category.Name].Junk
            for _, item in ipairs(category.Items) do 
                State.Items[item].Junk = State.Categories[category.Name].Junk
                if VisualUpdaters[item] then VisualUpdaters[item](State.Items[item].Normal, State.Items[item].Gold, State.Items[item].Junk) end
            end
            updateCat(State.Categories[category.Name].Normal, State.Categories[category.Name].Gold, State.Categories[category.Name].Junk)
        end)

        for _, itemName in ipairs(category.Items) do
            currentLayoutOrder += 1
            local _, ItemNorm, ItemGold, ItemJunk, updateItem = createTripleToggleUI(ScrollFrame, itemName, nil, currentLayoutOrder)
            VisualUpdaters[itemName] = updateItem
            updateItem(false, false, false)

            ItemNorm.MouseButton1Click:Connect(function()
                State.Items[itemName].Normal = not State.Items[itemName].Normal
                updateItem(State.Items[itemName].Normal, State.Items[itemName].Gold, State.Items[itemName].Junk)
            end)
            ItemGold.MouseButton1Click:Connect(function()
                State.Items[itemName].Gold = not State.Items[itemName].Gold
                updateItem(State.Items[itemName].Normal, State.Items[itemName].Gold, State.Items[itemName].Junk)
            end)
            ItemJunk.MouseButton1Click:Connect(function()
                State.Items[itemName].Junk = not State.Items[itemName].Junk
                updateItem(State.Items[itemName].Normal, State.Items[itemName].Gold, State.Items[itemName].Junk)
            end)
        end
    end
end

populateJunkyardCategoryUI(JunkyardCategories, "--- JUNKYARD NATIVE ITEMS ---")
populateBeltCategoryUI(ItemCategories, "--- BELT ITEMS ---")

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
-- GHOST PLATFORM & BUY LOGIC
-- ==========================================

local DELAY_BETWEEN_BUYS = 0.2 
local HoverPlatform = Instance.new("Part")
HoverPlatform.Name = "AutoBuyPlatform"
HoverPlatform.Size = Vector3.new(10, 1, 10)
HoverPlatform.Anchored = true
HoverPlatform.Transparency = 1
HoverPlatform.CanCollide = true
HoverPlatform.Parent = workspace
HoverPlatform.CFrame = CFrame.new(0, 10000, 0)

local function isItemGold(item)
    local hitbox = item:FindFirstChild("Hitbox")
    if hitbox and (hitbox:FindFirstChild("Gold_01") or hitbox:FindFirstChild("Gold_02")) then 
        return true 
    end
    
    for _, desc in ipairs(item:GetDescendants()) do
        if desc.Name == "Gold_01" or desc.Name == "Gold_02" then
            return true
        end
    end
    
    return false
end

local function getPromptPos(prompt)
    local p = prompt.Parent
    if not p then return nil end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Model") then return p:GetPivot().Position end
    return nil
end

local function executeBuy(target, hrp)
    local prompt = target.Prompt
    local targetPos = getPromptPos(prompt)

    if prompt and prompt.Enabled and targetPos then
        local originalCFrame = hrp.CFrame
        hrp.Anchored = false 
        
        local isTracking = true
        local trackConnection = RunService.Heartbeat:Connect(function()
            if isTracking and prompt.Parent then
                local pos = getPromptPos(prompt)
                if pos then
                    HoverPlatform.CFrame = CFrame.new(pos - Vector3.new(0, 3, 0))
                    hrp.CFrame = CFrame.new(pos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)

        task.wait(0.35) 

        if prompt.Enabled and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.05)
            if prompt.Enabled then fireproximityprompt(prompt) end
        end

        isTracking = false
        trackConnection:Disconnect()
        
        HoverPlatform.CFrame = CFrame.new(0, 10000, 0)
        hrp.CFrame = originalCFrame
        
        task.wait(DELAY_BETWEEN_BUYS)
    end
end

-- ==========================================
-- BELT ITEMS LOOP
-- ==========================================

local function findMyPlot()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Map")
    if plotsFolder and plotsFolder.Name == "Map" and plotsFolder:FindFirstChild("Plots") then
        plotsFolder = plotsFolder.Plots
    end
    if not plotsFolder then return nil end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
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

local myPlot = nil 
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
        if IsBeltItem[item.Name] then
            local itemState = State.Items[item.Name]
            if itemState then
                local isGold = isItemGold(item)
                local shouldBuy = false
                
                if isGold and itemState.Gold then shouldBuy = true
                elseif not isGold and itemState.Normal then shouldBuy = true end
                
                if shouldBuy then
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        table.insert(buyableItems, {Prompt = prompt, Priority = ItemPriorityMap[item.Name] or 99})
                    end
                end
            end
        end
    end
    table.sort(buyableItems, function(a, b) return a.Priority < b.Priority end)
    return buyableItems
end

task.spawn(function()
    while task.wait(0.1) do
        if not State.Master then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targets = getSortedItemsOnBelt()
        for _, target in ipairs(targets) do
            if not State.Master then break end 
            executeBuy(target, hrp)
        end
    end
end)

-- ==========================================
-- JUNKYARD ITEMS LOOP
-- ==========================================

local function getSortedJunkyardItems()
    local mapFolder = workspace:FindFirstChild("Map")
    local jyFolder = mapFolder and mapFolder:FindFirstChild("Junkyard")
    local jyItemsFolder = jyFolder and jyFolder:FindFirstChild("JunkyardItems")
    if not jyItemsFolder then return {} end

    local buyableItems = {}
    
    for _, itemSpawn in ipairs(jyItemsFolder:GetChildren()) do
        for _, obj in ipairs(itemSpawn:GetChildren()) do
            
            local itemState = State.Items[obj.Name]
            if itemState and typeof(itemState) == "table" then
                local isGold = isItemGold(obj)
                local shouldBuy = false
                
                if IsJunkyardItem[obj.Name] then
                    if isGold and itemState.Gold then shouldBuy = true
                    elseif not isGold and itemState.Normal then shouldBuy = true end
                
                elseif IsBeltItem[obj.Name] then
                    if itemState.Junk then 
                        if isGold and itemState.Gold then shouldBuy = true
                        elseif not isGold and itemState.Normal then shouldBuy = true end
                    end
                end
                
                if shouldBuy then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        local alreadyAdded = false
                        for _, existing in ipairs(buyableItems) do
                            if existing.Prompt == prompt then alreadyAdded = true break end
                        end
                        
                        if not alreadyAdded then
                            table.insert(buyableItems, {Prompt = prompt, Priority = ItemPriorityMap[obj.Name] or 99})
                        end
                    end
                end
            end
        end
    end
    
    table.sort(buyableItems, function(a, b) return a.Priority < b.Priority end)
    return buyableItems
end

task.spawn(function()
    while task.wait(1) do
        if not State.Master then continue end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local targets = getSortedJunkyardItems()
        for _, target in ipairs(targets) do
            if not State.Master then break end 
            executeBuy(target, hrp)
        end
    end
end)
