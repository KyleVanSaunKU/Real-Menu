local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up previous UI for testing
if playerGui:FindFirstChild("BookTrackerUI") then
    playerGui.BookTrackerUI:Destroy()
end

-- Wait for the game to actually load the map before scanning
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(2) -- Extra buffer for streaming or slow-loading maps

-- 1. Create the ScreenGui and Main Frame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BookTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Invisible button that forces the mouse to unlock in First-Person
local mouseUnlocker = Instance.new("TextButton")
mouseUnlocker.Size = UDim2.new(0, 0, 0, 0)
mouseUnlocker.BackgroundTransparency = 1
mouseUnlocker.Text = ""
mouseUnlocker.Modal = true -- THIS is what frees the mouse
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

local seriesData = {}

-- 2. Find books in Workspace using GetDescendants (Catches everything)
for _, child in ipairs(Workspace:GetDescendants()) do
    if child.Name == "Book" then
        local titleAttr = child:GetAttribute("title")
        if titleAttr then
            local seriesName = string.gsub(titleAttr, "%s*EP%d+$", "")
            
            if not seriesData[seriesName] then
                local h = math.random()
                local seriesColor = Color3.fromHSV(h, 0.8, 1)

                seriesData[seriesName] = {
                    books = {},
                    color = seriesColor,
                    state = false
                }
            end
            table.insert(seriesData[seriesName].books, child)
        end
    end
end

-- 3. Function to handle Highlights and Dots
local function updateVisuals(seriesName)
    local data = seriesData[seriesName]
    local state = data.state
    local color = data.color

    for _, book in ipairs(data.books) do
        local highlight = book:FindFirstChild("TrackerHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "TrackerHighlight"
            highlight.FillColor = color
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = book
        end
        highlight.Enabled = state

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
end

-- 4. Populate the UI
for sName, data in pairs(seriesData) do
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = sName
    toggleBtn.Size = UDim2.new(1, 0, 0, 35)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggleBtn.Text = sName
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = scrollFrame

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 10, 1, 0)
    indicator.BackgroundColor3 = data.color
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        data.state = not data.state
        if data.state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        updateVisuals(sName)
    end)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- 5. Toggle Menu & First-Person Mouse Control
local isMenuOpen = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.M then
        isMenuOpen = not isMenuOpen
        mainFrame.Visible = isMenuOpen
        mouseUnlocker.Modal = isMenuOpen -- Unlocks/Locks the mouse
    end
end)
