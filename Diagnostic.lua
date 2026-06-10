local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("=====================================")
print("  STARTING AUTO-COLLECT DIAGNOSTIC   ")
print("=====================================")

-- STEP 1: Find Plot
local function findMyPlot()
    local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Map")
    if plotsFolder and plotsFolder.Name == "Map" and plotsFolder:FindFirstChild("Plots") then
        plotsFolder = plotsFolder.Plots
    end

    if not plotsFolder then 
        print("❌ ERROR: Could not find 'Plots' folder in Workspace.")
        return nil 
    end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local ownerVal = plot:FindFirstChild("Owner")
        if ownerVal and (ownerVal.Value == LocalPlayer or ownerVal.Value == LocalPlayer.Name) then
            print("✅ STEP 1 SUCCESS: Found your plot -> " .. plot.Name)
            return plot
        end
    end
    print("❌ ERROR: Could not find a plot owned by you.")
    return nil
end

local plot = findMyPlot()
if not plot then return end

-- STEP 2: Find PlacedItems
local placedItems = plot:FindFirstChild("PlacedItems")
if not placedItems then
    print("❌ ERROR: Could not find 'PlacedItems' folder inside your plot.")
    return
end
print("✅ STEP 2 SUCCESS: Found 'PlacedItems' folder.")

-- STEP 3: Find Furnace and Prompt
local furnaceObj = nil
local targetPrompt = nil

print("🔍 Scanning for Furnaces...")
for _, item in ipairs(placedItems:GetChildren()) do
    if string.find(string.lower(item.Name), "furnace") then
        print("   -> Found Furnace Model: " .. item.Name)
        
        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            print("✅ STEP 3 SUCCESS: Found ProximityPrompt inside -> " .. prompt:GetFullName())
            furnaceObj = item
            targetPrompt = prompt
            break
        else
            print("   ⚠️ WARNING: Found furnace, but it has no ProximityPrompt inside it!")
        end
    end
end

if not targetPrompt then
    print("❌ ERROR: Scan complete. No usable ProximityPrompt was found in any Furnace.")
    return
end

-- STEP 4: Attempt Teleport and Execute
print("🚀 STEP 4: Attempting to Teleport and Auto-Collect...")
local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

if hrp then
    local promptPart = targetPrompt.Parent
    local pos = promptPart:IsA("Attachment") and promptPart.WorldPosition or promptPart:IsA("BasePart") and promptPart.Position or promptPart:IsA("Model") and promptPart:GetPivot().Position
    
    if pos then
        local oldCFrame = hrp.CFrame
        hrp.Anchored = true
        hrp.CFrame = CFrame.new(pos)
        print("   -> Teleported to prompt. Waiting 0.5s for server sync...")
        task.wait(0.5) 
        
        print("   -> Firing ProximityPrompt...")
        local oldLoS = targetPrompt.RequiresLineOfSight
        targetPrompt.RequiresLineOfSight = false
        
        if fireproximityprompt then
            pcall(function() fireproximityprompt(targetPrompt) end)
            task.wait(0.1)
            pcall(function() fireproximityprompt(targetPrompt) end) -- Double tap just in case
            print("✅ EXECUTED: fireproximityprompt was triggered.")
        else
            print("❌ ERROR: Your executor does not support fireproximityprompt.")
        end
        
        targetPrompt.RequiresLineOfSight = oldLoS
        hrp.Anchored = false
        hrp.CFrame = oldCFrame
        
        print("=====================================")
        print(" DIAGNOSTIC COMPLETE. CHECK YOUR CASH")
        print("=====================================")
    else
        print("❌ ERROR: Could not determine the physical position of the prompt.")
    end
else
    print("❌ ERROR: Could not find your character's HumanoidRootPart.")
end
