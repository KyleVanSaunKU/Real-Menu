local workspace = game:GetService("Workspace")
local SlimesFolder = workspace:FindFirstChild("Runtime") and workspace.Runtime:FindFirstChild("Slimes")

if not SlimesFolder then
    warn("DEBUG ERROR: The 'Runtime -> Slimes' folder is currently missing.")
else
    local count = 0
    for _, obj in ipairs(SlimesFolder:GetChildren()) do
        if string.sub(obj.Name, 1, 6) == "Slime_" then
            count = count + 1
        end
    end
    print("DEBUG SUCCESS: Found " .. count .. " valid slimes starting with 'Slime_'")
end
