-- ==========================================
-- REAL'S Click TP
-- ==========================================

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local screenGui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 180, 0, 70)
frame.Position = UDim2.new(0.05, 0, 0.5, 0)
frame.Active = true
frame.Draggable = true
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0.5, 0)
title.Text = "MADE BY REAL"
title.BackgroundTransparency = 1
spawn(function() while true do for i = 0, 1, 0.01 do title.TextColor3 = Color3.fromHSV(i, 1, 1) task.wait(0.05) end end end)

local tpButton = Instance.new("TextButton", frame)
tpButton.Size = UDim2.new(0.9, 0, 0.4, 0)
tpButton.Position = UDim2.new(0.05, 0, 0.55, 0)
tpButton.Text = "Click-TP (ON)"
local tpEnabled = true
tpButton.MouseButton1Click:Connect(function()
    tpEnabled = not tpEnabled
    tpButton.Text = tpEnabled and "Click-TP (ON)" or "Click-TP (OFF)"
end)

mouse.Button1Down:Connect(function()
    if tpEnabled and mouse.Target then player.Character:MoveTo(mouse.Hit.p) end
end)
