local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().AimbotEnabled = false

-- --- FASTEST POSSIBLE TARGETING ---
local function getTarget()
    local Runtime = workspace:FindFirstChild("Runtime")
    if not Runtime then return nil end
    local SlimesFolder = Runtime:FindFirstChild("Slimes")
    if not SlimesFolder then return nil end

    for _, obj in ipairs(SlimesFolder:GetChildren()) do
        if string.sub(obj.Name, 1, 6) == "Slime_" then
            return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    return nil
end

-- --- CAMERA SNAP (NO MOUSE INTERFERENCE) ---
RunService.RenderStepped:Connect(function()
    if not getgenv().AimbotEnabled then return end
    local target = getTarget()
    if target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end)

-- Toggle via Keybind 'Q'
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Q then
        getgenv().AimbotEnabled = not getgenv().AimbotEnabled
        print("Aimbot:", getgenv().AimbotEnabled and "ON" or "OFF")
    end
end)
