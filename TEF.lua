local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- NETWORK BACKDOOR
-- ==========================================
local PacketRemote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Vendor"):WaitForChild("Packet"):WaitForChild("RemoteEvent")

-- ==========================================
-- STATE
-- ==========================================
local State = { Master = false, Noclip = false, Items = {} }

-- ==========================================
-- UI CONSTRUCTION (No Animations, No Tweens)
-- ==========================================
local TycoonGui = Instance.new("ScreenGui", (RunService:IsStudio() and LocalPlayer.PlayerGui or CoreGui))
TycoonGui.Name = "TycoonAutoBuyer"

local MainFrame = Instance.new("Frame", TycoonGui)
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 27)

local function createToggle(parent, text, onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, (#parent:GetChildren() - 1) * 35 + 10)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.MouseButton1Click:Connect(function()
        onClick(btn)
    end)
    return btn
end

createToggle(MainFrame, "Toggle Master Auto-Buy", function(b) 
    State.Master = not State.Master 
    b.BackgroundColor3 = State.Master and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(39, 39, 42)
end)

createToggle(MainFrame, "Toggle Noclip", function(b) 
    State.Noclip = not State.Noclip 
    b.BackgroundColor3 = State.Noclip and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(39, 39, 42)
end)

-- ==========================================
-- BUYER LOGIC
-- ==========================================

-- NOCLIP
RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- BUYER LOOP
task.spawn(function()
    while task.wait(0.5) do
        if not State.Master then continue end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- Find Plot
        local plot = nil
        for _, p in ipairs(workspace.Plots:GetChildren()) do
            local z = p:FindFirstChild("PlotZone", true)
            if z and z:IsA("BasePart") then
                local pos = z.CFrame:PointToObjectSpace(hrp.Position)
                if math.abs(pos.X) <= z.Size.X/2 and math.abs(pos.Z) <= z.Size.Z/2 then plot = p break end
            end
        end
        
        if not plot or not plot:FindFirstChild("Belt") then continue end
        local active = plot.Belt:FindFirstChild("ActiveItems")
        if not active then continue end

        for _, item in ipairs(active:GetChildren()) do
            if not State.Master then break end
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            local pad = item:FindFirstChild("PurchasePad", true) or item:FindFirstChildWhichIsA("BasePart", true)
            
            if prompt and pad then
                -- 1. TELEPORT & ANCHOR
                local oldPos = hrp.CFrame
                hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 1.5, 0))
                hrp.Anchored = true
                task.wait(0.1)
                
                -- 2. FIRE BACKDOOR + PROMPT
                pcall(function() PacketRemote:FireServer("purchase_belt_item", item) end)
                if fireproximityprompt then fireproximityprompt(prompt) end
                
                -- 3. RESET
                task.wait(0.2)
                hrp.Anchored = false
                hrp.CFrame = oldPos
                task.wait(0.2)
            end
        end
    end
end)
