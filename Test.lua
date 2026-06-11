local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().MouseAimbotEnabled = false

-- --- CONFIGURATION ---
-- Tweak these two numbers if it's still too fast or too slow
local Smoothness = 4 -- Higher number = slower, smoother mouse movement. Lower number = faster snap.
local Deadzone = 5   -- If the cursor is within this many pixels of the target, it stops moving.

-- --- UI SETUP ---
local guiParent = (gethui and gethui()) or CoreGui

if guiParent:FindFirstChild("StabilizedMouseAimbot") then
    guiParent.StabilizedMouseAimbot:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StabilizedMouseAimbot"
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
Title.Text = "Smooth Mouse Aimbot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "Mouse Aim: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

-- --- BUTTON LOGIC ---
ToggleButton.MouseButton1Click:Connect(function()
    getgenv().MouseAimbotEnabled = not getgenv().MouseAimbotEnabled
    if getgenv().MouseAimbotEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        ToggleButton.Text = "Mouse Aim: ON"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleButton.Text = "Mouse Aim: OFF"
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

-- --- STABILIZED MOUSE MOVEMENT LOOP ---
RunService.RenderStepped:Connect(function()
    if not getgenv().MouseAimbotEnabled then return end

    local target = getClosestSlime()
    
    if target then
        -- Convert 3D position to 2D screen coordinates
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.Position)
        
        -- Only attempt to move if the target is actually on the screen
        if onScreen then
            local mouseLocation = UserInputService:GetMouseLocation()
            
            local deltaX = screenPoint.X - mouseLocation.X
            local deltaY = screenPoint.Y - mouseLocation.Y
            
            -- Calculate the total 2D distance the mouse needs to travel
            local mouseDistance = math.sqrt((deltaX ^ 2) + (deltaY ^ 2))
            
            -- Apply deadzone check and smoothness
            if mouseDistance > Deadzone then
                if mousemoverel then
                    mousemoverel(deltaX / Smoothness, deltaY / Smoothness)
                end
            end
        end
    end
end)
