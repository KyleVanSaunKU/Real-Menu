local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("--- BOOK & SHELF TRACKER SCRIPT STARTED ---")

-- Clean up previous UI for testing
if playerGui:FindFirstChild("BookTrackerUI") then
    playerGui.BookTrackerUI:Destroy()
end

-- 1. Create the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BookTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mouseUnlocker = Instance.new("TextButton")
mouseUnlocker.Size = UDim2.new(0, 0, 0, 0)
mouseUnlocker.BackgroundTransparency = 1
mouseUnlocker.Text = ""
mouseUnlocker.Modal = true
mouseUnlocker.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0, 20, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Series Tracker (Press M)"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -40)
scrollFrame.Position = UDim2.new(0, 0, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = scrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingLeft = UDim.new(0, 5)
padding.PaddingRight = UDim.new(0, 5)
padding.Parent = scrollFrame

-- Data Storage
local seriesData = {}
local shelvesByCategory = {}

-- 2. Visual Helper Functions (Using SelectionBox to bypass the 31 Limit)
local function applyVisualsToBook(book, color, state)
    local selection = book:FindFirstChild("TrackerSelection")
    if not selection then
        selection = Instance.new("SelectionBox")
        selection.Name = "TrackerSelection"
        selection.Color3 = color -- Outline Color
        selection.SurfaceColor3 = color -- Fill Color
        selection.SurfaceTransparency = 0.6
        selection.LineThickness = 0.05
        selection.Adornee = book
        selection.Parent = book
    end
    selection.Visible = state

    local dotGui = book:FindFirstChild("TrackerDot")
    if not dotGui then
        dotGui = Instance.new("BillboardGui")
        dotGui.Name = "TrackerDot"
        dotGui.AlwaysOnTop = true
        dotGui.Size = UDim2.new(0, 15, 0, 15)
        dotGui.StudsOffset = Vector3.new(0, 2, 0) 

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(1, 0, 1, 0)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        
        dot.Parent = dotGui
        dotGui.Parent = book
    end
    dotGui.Enabled = state
end

local function applyVisualsToShelf(shelf, color, state)
    local selection = shelf:FindFirstChild("TrackerShelfSelection")
    if not selection then
        selection = Instance.new("SelectionBox")
        selection.Name = "TrackerShelfSelection"
        selection.Color3 = color
        selection.SurfaceColor3 = color
        selection.SurfaceTransparency = 0.85 -- Kept highly transparent so it's not obnoxious
        selection.LineThickness = 0.03
        selection.Adornee = shelf
        selection.Parent = shelf
    end
    
    -- Update the color in case a different series in the same category is toggled
    selection.Color3 = color
    selection.SurfaceColor3 = color
    selection.Visible = state
end

local function updateAllShelves()
    local activeCategories = {}
    
    for sName, data in pairs(seriesData) do
        if data.state and data.category then
            activeCategories[data.category] = data.color
        end
    end

    for category, shelves in pairs(shelvesByCategory) do
        local isActive = activeCategories[category] ~= nil
        local displayColor = activeCategories[category] or Color3.new(1, 1, 1)
        
        for _, shelf in ipairs(shelves) do
            applyVisualsToShelf(shelf, displayColor, isActive)
        end
    end
end

local function toggleSeries(seriesName)
    local data = seriesData[seriesName]
    data.state = not data.state
    
    if data.button then
        if data.state then
            data.button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            data.button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            data.button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end

    for _, book in ipairs(data.books) do
        applyVisualsToBook(book, data.color, data.state)
    end
    
    updateAllShelves()
end

local function createToggleButton(seriesName, color)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = seriesName
    toggleBtn.Size = UDim2.new(1, 0, 0, 35)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggleBtn.Text = seriesName
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = scrollFrame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 10, 1, 0)
    indicator.BackgroundColor3 = color
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        toggleSeries(seriesName)
    end)

    return toggleBtn
end

-- 3. Core Logic for Scanning Objects
local function handleNewObject(child)
    if string.match(child.Name, "^Book%s*$") then
        local titleAttr = child:GetAttribute("title") or child:GetAttribute("Title")
        local catAttr = child:GetAttribute("Category") or child:GetAttribute("category")
        
        if titleAttr then
            titleAttr = tostring(titleAttr) 
            -- Upgraded matching to catch: "EP1", "Ep 1", "EP  1", "ep1"
            local seriesName = string.gsub(titleAttr, "%s*[Ee][Pp]%s*%d+$", "")
            
            if not seriesData[seriesName] then
                local h = math.random()
                local newColor = Color3.fromHSV(h, 0.8, 1)
                seriesData[seriesName] = {
                    books = {},
                    color = newColor,
                    state = false,
                    category = catAttr and tostring(catAttr) or nil,
                    button = createToggleButton(seriesName, newColor)
                }
            end
            
            table.insert(seriesData[seriesName].books, child)
            
            if seriesData[seriesName].state then
                applyVisualsToBook(child, seriesData[seriesName].color, true)
            end
        end
        
    elseif string.match(child.Name, "^Shelf%s*$") then
        local catAttr = child:GetAttribute("Category") or child:GetAttribute("category")
        
        if catAttr then
            catAttr = tostring(catAttr)
            
            if not shelvesByCategory[catAttr] then
                shelvesByCategory[catAttr] = {}
            end
            
            table.insert(shelvesByCategory[catAttr], child)
            updateAllShelves()
        end
    end
end

-- 4. Execution
print("Scanning Workspace...")
for _, child in ipairs(Workspace:GetDescendants()) do
    handleNewObject(child)
end
print("Scan Complete.")

Workspace.DescendantAdded:Connect(handleNewObject)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

local isMenuOpen = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.M then
        isMenuOpen = not isMenuOpen
        mainFrame.Visible = isMenuOpen
        mouseUnlocker.Modal = isMenuOpen 
    end
end)
