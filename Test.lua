local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Step 1: Locate the Remotes folder
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
    warn("ERROR: Could not find 'Remotes' inside ReplicatedStorage.")
    return
end

-- --- UI SETUP ---
local guiParent = (gethui and gethui()) or CoreGui
if guiParent:FindFirstChild("RemoteTriggerMenu") then
    guiParent.RemoteTriggerMenu:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoteTriggerMenu"
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 300) -- Taller frame to fit a list
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Text = " Remote Trigger Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local ExitButton = Instance.new("TextButton")
ExitButton.Size = UDim2.new(0, 30, 0, 30)
ExitButton.Position = UDim2.new(1, -30, 0, 0)
ExitButton.BackgroundTransparency = 1
ExitButton.Text = "X"
ExitButton.TextColor3 = Color3.fromRGB(255, 50, 50)
ExitButton.Font = Enum.Font.SourceSansBold
ExitButton.TextSize = 16
ExitButton.Parent = MainFrame

ExitButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- --- SCROLLING FRAME SETUP ---
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollFrame

-- Automatically expand the scroll area based on how many remotes exist
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

-- --- POPULATE REMOTES ---
local count = 0
for _, remote in ipairs(RemotesFolder:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        count = count + 1
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -10, 0, 30)
        Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        
        -- Distinguish Events (Orange) from Functions (Blue)
        if remote:IsA("RemoteEvent") then
            Btn.Text = "🔥 " .. remote.Name
            Btn.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            Btn.Text = "⚡ " .. remote.Name
            Btn.TextColor3 = Color3.fromRGB(100, 200, 255)
        end
        
        Btn.Font = Enum.Font.SourceSansBold
        Btn.TextSize = 14
        Btn.Parent = ScrollFrame

        -- Handle the actual firing
        Btn.MouseButton1Click:Connect(function()
            print("Attempting to fire:", remote.Name)
            
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
            elseif remote:IsA("RemoteFunction") then
                -- InvokeServer can freeze your game if the server doesn't respond. 
                -- We wrap it in task.spawn so it runs safely in the background.
                task.spawn(function()
                    local success, err = pcall(function()
                        remote:InvokeServer()
                    end)
                    if not success then
                        warn("Failed to invoke " .. remote.Name .. " - " .. tostring(err))
                    end
                end)
            end
        end)
    end
end

print("Loaded " .. count .. " remotes into the menu.")
