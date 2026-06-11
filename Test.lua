local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Added VIM
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().AimbotEnabled = false

-- --- UI SETUP ---
local guiParent = (gethui and gethui()) or CoreGui

if guiParent:FindFirstChild("MouseSlimeAimbot") then
    guiParent.MouseSlimeAimbot:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MouseSlimeAimbot"
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
Title.Text = "VIM Slime Aimbot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "Aimbot: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

local TargetHighlight = Instance.new("Highlight")
TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
TargetHighlight.FillTransparency = 0.5

-- --- BUTTON LOGIC ---
ToggleButton.MouseButton1Click:Connect(function()
    getgenv().AimbotEnabled = not getgenv().AimbotEnabled
    if getgenv().AimbotEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "Aimbot: ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Text = "Aimbot: OFF"
        TargetHighlight.Parent = nil
    end
end)

-- --- TARGETING LOGIC ---
local function getClosestSlime()
    local Runtime = workspace:FindFirstChild("Runtime")
    if not Runtime then return nil end

    local SlimesFolder = Runtime:FindFirstChild("Slimes")
    if not SlimesFolder then return nil end

    local closestSlime = nil
    local shortestDistance = math.huge
    local character = LocalPlayer.Character
    local playerPos = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position

    if not playerPos then return nil end

    for _, obj in ipairs(SlimesFolder:GetChildren()) do
        if string.sub(obj.Name, 1, 6) == "Slime_" then
            local targetPart = obj:FindFirstChild("HumanoidRootPart") 
                or obj:FindFirstChild("PrimaryPart") 
                or obj:FindFirstChildWhichIsA("BasePart")
            
            if targetPart then
                local distance = (playerPos - targetPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestSlime = targetPart
                end
            end
        end
    end

    return closestSlime
end

-- --- MOUSE MOVEMENT LOOP ---
-- Tweak this value between 0.1 and 1. (1 = instant snap, 0.2 = smooth tracking)
local Smoothing = 0.5 

RunService.RenderStepped:Connect(function()
    if not getgenv().AimbotEnabled then return end

    local target = getClosestSlime()
    
    if target then
        -- 1. Convert 3D position to 2D screen position
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.Position)
        
        -- 2. Only move the mouse if the slime is actually visible on your screen
        if onScreen then
            -- 3. Get current mouse location
            local mouseLocation = UserInputService:GetMouseLocation()
            
            -- 4. Calculate the new absolute position with smoothing
            local newX = mouseLocation.X + (screenPoint.X - mouseLocation.X) * Smoothing
            local newY = mouseLocation.Y + (screenPoint.Y - mouseLocation.Y) * Smoothing
            
            -- 5. Force the mouse to move using Roblox's VirtualInputManager
            VirtualInputManager:SendMouseMoveEvent(newX, newY, workspace)
        end
        
        -- Update visual highlight
        if target.Parent and target.Parent ~= TargetHighlight.Parent then
            TargetHighlight.Parent = target.Parent
        end
    else
        TargetHighlight.Parent = nil
    end
end)
