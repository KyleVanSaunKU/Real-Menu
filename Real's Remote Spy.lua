-- ==========================================
-- REAL'S Remote Spy
-- ==========================================

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Prevent multiple instances
if CoreGui:FindFirstChild("BetterRemoteSpy") then
    CoreGui.BetterRemoteSpy:Destroy()
end

-- ==========================================
-- 1. UI CREATION
-- ==========================================
local SpyGui = Instance.new("ScreenGui", CoreGui)
SpyGui.Name = "BetterRemoteSpy"
SpyGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", SpyGui)
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Solara Remote Spy (Incoming Only)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 18

local RemoteList = Instance.new("ScrollingFrame", MainFrame)
RemoteList.Size = UDim2.new(0, 200, 1, -40)
RemoteList.Position = UDim2.new(0, 10, 0, 40)
RemoteList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RemoteList.BorderSizePixel = 0
RemoteList.ScrollBarThickness = 4
RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)

local ListLayout = Instance.new("UIListLayout", RemoteList)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 2)

local CodeBox = Instance.new("TextBox", MainFrame)
CodeBox.Size = UDim2.new(1, -230, 1, -80)
CodeBox.Position = UDim2.new(0, 220, 0, 40)
CodeBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CodeBox.BorderSizePixel = 0
CodeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
CodeBox.Font = Enum.Font.Code
CodeBox.TextSize = 14
CodeBox.TextXAlignment = Enum.TextXAlignment.Left
CodeBox.TextYAlignment = Enum.TextYAlignment.Top
CodeBox.ClearTextOnFocus = false
CodeBox.MultiLine = true
CodeBox.TextEditable = false
CodeBox.Text = "-- Click a remote to view data sent from the Server"

local CopyBtn = Instance.new("TextButton", MainFrame)
CopyBtn.Size = UDim2.new(0, 150, 0, 30)
CopyBtn.Position = UDim2.new(0, 220, 1, -35)
CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CopyBtn.BorderSizePixel = 0
CopyBtn.Text = "Copy Code"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.TextSize = 14

local ClearBtn = Instance.new("TextButton", MainFrame)
ClearBtn.Size = UDim2.new(0, 150, 0, 30)
ClearBtn.Position = UDim2.new(0, 380, 1, -35)
ClearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ClearBtn.BorderSizePixel = 0
ClearBtn.Text = "Clear Remotes"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.TextSize = 14

-- UI Dragging Logic
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Buttons
CloseBtn.MouseButton1Click:Connect(function() SpyGui:Destroy() end)
CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(CodeBox.Text)
        CopyBtn.Text = "Copied!"
        task.wait(1)
        CopyBtn.Text = "Copy Code"
    end
end)
ClearBtn.MouseButton1Click:Connect(function()
    for _, child in pairs(RemoteList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
    CodeBox.Text = "-- Cleared"
end)

-- ==========================================
-- 2. FORMATTING LOGIC
-- ==========================================
local function getPath(instance)
    local path = {}
    local current = instance
    while current and current ~= game do
        local name = current.Name
        if string.match(name, "[^%w_]") or string.match(name, "^%d") then
            table.insert(path, 1, '["' .. name .. '"]')
        else
            table.insert(path, 1, "." .. name)
        end
        current = current.Parent
    end
    return "game" .. table.concat(path)
end

local function formatValue(value, depth)
    depth = depth or 1
    if depth > 6 then return '"[Table Limit Reached]"' end 
    
    if typeof(value) == "string" then return string.format("%q", value)
    elseif typeof(value) == "number" then return tostring(value)
    elseif typeof(value) == "boolean" then return value and "true" or "false"
    elseif typeof(value) == "Instance" then return getPath(value)
    elseif typeof(value) == "table" then
        local result = "{\n"
        local indent = string.rep("    ", depth)
        local isEmpty = true
        
        for k, v in pairs(value) do
            isEmpty = false
            local keyStr = (typeof(k) == "string") and ('["' .. k .. '"]') or ("[" .. tostring(k) .. "]")
            result = result .. indent .. keyStr .. " = " .. formatValue(v, depth + 1) .. ",\n"
        end
        
        if isEmpty then return "{}" end
        return result .. string.rep("    ", depth - 1) .. "}"
    else
        return "nil --[[" .. tostring(value) .. " (" .. typeof(value) .. ")]]"
    end
end

-- ==========================================
-- 3. INTERCEPT LOGIC (Solara Safe)
-- ==========================================
local function LogRemote(remote, args)
    local formattedArgs = {}
    for i, arg in ipairs(args) do
        formattedArgs[i] = string.format("    [%d] = %s", i, formatValue(arg, 2))
    end
    
    local argString = table.concat(formattedArgs, ",\n")
    local remotePath = getPath(remote)
    
    -- We format it as a FireServer script so you can test it, 
    -- but remember this data actually came FROM the server.
    local generatedCode = string.format("local args = {\n%s\n}\n\n%s:FireServer(unpack(args))", argString, remotePath)

    local btn = Instance.new("TextButton", RemoteList)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = " " .. remote.Name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    btn.MouseButton1Click:Connect(function()
        CodeBox.Text = generatedCode
    end)
    
    RemoteList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            local args = {...}
            LogRemote(remote, args)
        end)
    end
end

-- Scan for existing remotes
for _, v in pairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        hookRemote(v)
    end
end

-- Scan for new remotes added later
game.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") then
        hookRemote(v)
    end
end)

print("Solara Remote Spy loaded successfully!")
