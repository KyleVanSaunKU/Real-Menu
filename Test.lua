local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().MouseAimbotEnabled = false

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
Title.Text = "Mouse Slime Aimbot"
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
    -- Updated path based on Workspace -> Runtime -> Slimes
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
        -- Check if the name starts with "Slime_"
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
RunService.RenderStepped:Connect(function()
    if not getgenv().MouseAimbotEnabled then return end

    local target = getClosestSlime()
    
    if target then
        -- Convert the 3D position of the slime into 2D screen coordinates
        local screenPoint, onScreen = Camera:WorldToViewportPoint(target.Position)
        
        -- Only move the mouse if the slime is actually visible on your screen
        if onScreen then
            -- Get current physical mouse location
            local mouseLocation = UserInputService:GetMouseLocation()
            
            -- Calculate how far the mouse needs to move
            local deltaX = screenPoint.X - mouseLocation.X
            local deltaY = screenPoint.Y - mouseLocation.Y
            
            -- Use the executor's built-in mouse mover
            if mousemoverel then
                -- Smoothing factor: dividing by 2 makes the snap slightly less robotic. 
                -- Change to (deltaX, deltaY) for instant snapping.
                mousemoverel(deltaX / 2, deltaY / 2)
            else
                warn("Your executor does not support 'mousemoverel'.")
            end
        end
    end
end)
