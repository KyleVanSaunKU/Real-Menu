local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().AimbotEnabled = false
getgenv().AimbotKeybind = Enum.KeyCode.Q 

local isBinding = false 

-- --- UI SETUP ---
local guiParent = (gethui and gethui()) or CoreGui

if guiParent:FindFirstChild("FastMouseAimbot") then
    guiParent.FastMouseAimbot:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FastMouseAimbot"
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
Title.Text = "Fast Mouse Aimbot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

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
ToggleButton.Text = "Mouse Aim [Q]: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

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
        ToggleButton.Text = "Mouse Aim [" .. keyName .. "]: ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Text = "Mouse Aim [" .. keyName .. "]: OFF"
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
            
            if targetPart then
                return targetPart
            end
        end
    end

    return nil
end

-- --- MOUSE SNAP LOOP ---
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    if not getgenv().AimbotEnabled then return end

    local target = getFirstSlime()
    
    if target then
        -- Convert 3D target position to 2D screen coordinates
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.Position)
        
        -- Only move mouse if the slime is visibly rendered on your monitor
        if onScreen then
            local mouseLocation = UserInputService:GetMouseLocation()
            
            local deltaX = screenPoint.X - mouseLocation.X
            local deltaY = screenPoint.Y - mouseLocation.Y
            
            -- Deadzone check: If the mouse is already within 3 pixels of the center, don't move it.
            -- This stops the cursor from aggressively vibrating once it hits the target.
            local distance = math.sqrt((deltaX ^ 2) + (deltaY ^ 2))
            
            if distance > 3 and mousemoverel then
                -- Dividing by 2 keeps it lightning fast but prevents engine freakout
                mousemoverel(deltaX / 2, deltaY / 2)
            end
        end
    end
end)

-- --- EXIT BUTTON LOGIC ---
ExitButton.MouseButton1Click:Connect(function()
    if renderConnection then renderConnection:Disconnect() end
    getgenv().AimbotEnabled = false
    ScreenGui:Destroy()
end)
