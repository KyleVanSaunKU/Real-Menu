local ReplicatedStorage = game:GetService("ReplicatedStorage")
local keywords = {"egg", "pet", "hatch", "open", "buy"}

print("\n--- 🔍 SOLARA-SAFE REMOTE SCANNER ---")

-- 1. Scan for Remotes
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local name = obj.Name:lower()
        for _, word in ipairs(keywords) do
            if name:find(word) then
                print("[REMOTE] " .. obj:GetFullName())
                break
            end
        end
    end
end

-- 2. Scan Workspace for Physical Eggs (to get their exact names)
print("\n--- 🥚 SCANNING WORKSPACE FOR EGGS ---")
for _, obj in ipairs(workspace:GetChildren()) do
    local name = obj.Name:lower()
    if name:find("egg") or name:find("pet") then
        print("[PHYSICAL EGG] " .. obj.Name)
    end
end
print("--------------------------------------\n")
