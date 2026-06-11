print("--- STARTING SLIME PATH TEST ---")

local workspace = game:GetService("Workspace")

-- Step 1: Check SpawnPoints
local SpawnPoints = workspace:FindFirstChild("SpawnPoints")
if not SpawnPoints then
    print("ERROR: Could not find 'SpawnPoints' in workspace.")
    return
end
print("Found SpawnPoints!")

-- Step 2: Check SlimeResp
local SlimeResp = SpawnPoints:FindFirstChild("SlimeResp")
if not SlimeResp then
    print("ERROR: Could not find 'SlimeResp' inside SpawnPoints.")
    return
end
print("Found SlimeResp!")

-- Step 3: Loop through the contents
local foundSlime = false
for _, respObj in ipairs(SlimeResp:GetChildren()) do
    print("Checking inside:", respObj.Name)
    
    for _, obj in ipairs(respObj:GetChildren()) do
        print(" - Found object:", obj.Name)
        
        if string.match(obj.Name, "Slime") then
            print("   -> MATCH! Found a slime:", obj.Name)
            
            -- Check if it has a physical part we can lock onto
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildWhichIsA("BasePart") then
                 print("   -> AND it has a physical part we can target!")
            else
                 print("   -> WARNING: Slime found, but it has no physical BasePart to lock onto.")
            end
            
            foundSlime = true
        end
    end
end

if not foundSlime then
    print("WARNING: Reached the end of the folders but didn't find any object with 'Slime' in its name.")
end

print("--- END SLIME PATH TEST ---")
