local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().AimbotEnabled = false
getgenv().AimbotKeybind = Enum.KeyCode.Q -- Default Keybind

local isBinding = false -- Tracks if the user is currently assigning a new key

-- --- UI SETUP ---
local guiParent = (gethui and gethui()) or CoreGui

if guiParent:FindFirstChild("FastSlimeAimbot") then
    guiParent.FastSlimeAimbot:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FastSlimeAimbot"
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 80)
MainFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "Fast Camera Aimbot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

-- --- EXIT BUTTON ---
local ExitButton = Instance.new("TextButton")
ExitButton.Size = UDim2.new(0, 20, 0, 20)
ExitButton.Position = UDim2.new(1, -25, 0, 2)
ExitButton.BackgroundTransparency = 1
ExitButton.Text = "X"
ExitButton.TextColor3 = Color3.fromRGB(255, 50, 50)
ExitButton.Font = Enum.Font.SourceSansBold
ExitButton.TextSize = 16
ExitButton.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "Aimbot [Q]: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

local TargetHighlight = Instance.new("Highlight")
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
TargetHighlight.FillTransparency = 0.5

-- --- TOGGLE LOGIC ---
local function UpdateAimbotState(forceState)
    if forceState ~= nil then
        getgenv().AimbotEnabled = forceState
    else
        getgenv().AimbotEnabled = not getgenv().AimbotEnabled
    end

    local keyName = getgenv().AimbotKeybind.Name

    if getgenv().AimbotEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "Aimbot [" .. keyName .. "]: ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Text = "Aimbot [" .. keyName .. "]: OFF"
        TargetHighlight.Parent = nil
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    if not isBinding then
        UpdateAimbotState()
    end
end)

ToggleButton.MouseButton2Click:Connect(function()
    isBinding = true
    ToggleButton.Text = "...Press New Key..."
    ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- --- KEYBOARD INPUT LOGIC ---
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBinding then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            getgenv().AimbotKeybind = input.KeyCode
            isBinding = false
            UpdateAimbotState(getgenv().AimbotEnabled)
        end
    elseif not gameProcessed then
        if input.KeyCode == getgenv().AimbotKeybind then
            UpdateAimbotState()
        end
    end
end)

-- --- OPTIMIZED TARGETING LOGIC ---
local function getFirstSlime()
    local Runtime = workspace:FindFirstChild("Runtime")
    if not Runtime then return nil end

    local SlimesFolder = Runtime:FindFirstChild("Slimes")
    if not SlimesFolder then return nil end

    for _, obj in ipairs(SlimesFolder:GetChildren()) do
        if string.sub(obj.Name, 1, 6) == "Slime_" then
            local targetPart = obj:FindFirstChild("HumanoidRootPart") 
                or obj:FindFirstChild("PrimaryPart") 
                or obj:FindFirstChildWhichIsA("BasePart")
            
            -- Instantly return the first valid part found and kill the loop
            if targetPart then
                return targetPart
            end
        end
    end

    return nil
end

-- --- CAMERA SNAP LOOP ---
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    if not getgenv().AimbotEnabled then return end

    local target = getFirstSlime()
    
    if target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        
        if target.Parent and target.Parent ~= TargetHighlight.Parent then
            TargetHighlight.Parent = target.Parent
        end
    else
        TargetHighlight.Parent = nil
    end
end)

-- --- EXIT BUTTON LOGIC ---
ExitButton.MouseButton1Click:Connect(function()
    if renderConnection then renderConnection:Disconnect() end
    getgenv().AimbotEnabled = false
    TargetHighlight:Destroy()
    ScreenGui:Destroy()
end)
