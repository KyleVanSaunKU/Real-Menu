local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Change this to "SeperatedEgg" if you want to target the other one
local TARGET_EGG = "RareEgg" 
_G.AutoHatch = true

print("🥚 Auto-Hatch Sniper Started targeting: " .. TARGET_EGG)

-- Common remote names devs use for eggs if they aren't named "Buy"
local possibleRemotes = {"OpenEgg", "HatchEgg", "BuyEgg", "PurchaseEgg", "RollEgg"}

task.spawn(function()
    while _G.AutoHatch do
        task.wait(0.5) -- Speed of opening
        
        -- 1. Try to find the Egg in the Workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == TARGET_EGG then
                
                -- METHOD A: Proximity Prompt (Holding E)
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt, 1) end)
                end
                
                -- METHOD B: Click Detector (Clicking the egg)
                local click = obj:FindFirstChildWhichIsA("ClickDetector", true)
                if click and fireclickdetector then
                    pcall(function() fireclickdetector(click) end)
                end
                
                -- METHOD C: Billboard GUI Button Clicker (If it uses a floating UI)
                if getconnections then
                    for _, ui in ipairs(obj:GetDescendants()) do
                        if ui:IsA("GuiButton") then
                            pcall(function()
                                for _, conn in ipairs(getconnections(ui.MouseButton1Click)) do conn:Fire() end
                                for _, conn in ipairs(getconnections(ui.Activated)) do conn:Fire() end
                            end)
                        end
                    end
                end
            end
        end
        
        -- METHOD D: Brute-Force the Remotes Folder
        for _, rName in ipairs(possibleRemotes) do
            local remote = Remotes:FindFirstChild(rName)
            if remote then
                if remote:IsA("RemoteEvent") then
                    pcall(function() remote:FireServer(TARGET_EGG, 1) end)
                    pcall(function() remote:FireServer(TARGET_EGG) end)
                elseif remote:IsA("RemoteFunction") then
                    task.spawn(function()
                        pcall(function() remote:InvokeServer(TARGET_EGG, 1) end)
                    end)
                end
            end
        end
        
    end
end)
