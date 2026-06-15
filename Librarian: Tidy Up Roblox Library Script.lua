local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up previous UI if you are re-running the script while testing
if playerGui:FindFirstChild("BookTrackerUI") then
    playerGui.BookTrackerUI:Destroy()
end

-- 1. Create the ScreenGui and Main Frame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BookTrackerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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
titleLabel.Text = "Series Tracker"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
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

-- Dictionary to group books: { ["Money Heist"] = { books = {part1, part2}, color = Color3, state = false } }
local seriesData = {}

-- 2. Find loose books in Workspace, parse titles, and group them
for _, child in ipairs(Workspace:GetChildren()) do
    if child.Name == "Book" then
        local titleAttr = child:GetAttribute("title")
        if titleAttr then
            -- Removes a space followed by "EP" and any numbers at the very end of the string
            local seriesName = string.gsub(titleAttr, "%s*EP%d+$", "")
            
            if not seriesData[seriesName] then
                -- Generate a random distinct color for the series
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

-- 3. Function to handle Highlights and BillboardGuis
local function updateVisuals(seriesName)
    local data = seriesData[seriesName]
    local state = data.state
    local color = data.color

    for _, book in ipairs(data.books) do
        -- Setup Highlight (renders through walls)
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

        -- Setup Scalable Dot (BillboardGui)
        local dotGui = book:FindFirstChild("TrackerDot")
        if not dotGui then
            dotGui = Instance.new("BillboardGui")
            dotGui.Name = "TrackerDot"
            dotGui.AlwaysOnTop = true
            
            -- UDim2.new(0, size, 0, size) uses pixel Offset instead of Scale. 
            -- This keeps the dot the exact same pixel size on your screen from any distance.
            dotGui.Size = UDim2.new(0, 15, 0, 15)
            dotGui.StudsOffset = Vector3.new(0, 2, 0) -- Hover slightly above the book

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

-- 4. Populate the UI with Toggles
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

    -- Vertical color bar indicator on the button
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 10, 1, 0)
    indicator.BackgroundColor3 = data.color
    indicator.BorderSizePixel = 0
    indicator.Parent = toggleBtn

    -- Toggle Logic
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

-- Adjust scrolling frame canvas size automatically
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)
