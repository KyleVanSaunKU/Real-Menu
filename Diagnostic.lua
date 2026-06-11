local ReplicatedStorage = game:GetService("ReplicatedStorage")
local keywords = {"egg", "pet", "buy", "hatch", "open", "crate"}

print("\n--- 🔍 SCANNING FOR PET/EGG REMOTES ---")
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local name = obj.Name:lower()
        for _, word in ipairs(keywords) do
            if name:find(word) then
                print("Found: [" .. obj.ClassName .. "] " .. obj:GetFullName())
                break
            end
        end
    end
end
print("----------------------------------------\n")

-- ─── The Network Interceptor ─────────────────────────────────────────────────

local gmt = getrawmetatable(game)
setreadonly(gmt, false)
local oldNamecall = gmt.__namecall

gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        local name = self.Name:lower()
        local isMatch = false
        
        -- Check if the remote being fired matches our keywords
        for _, word in ipairs(keywords) do
            if name:find(word) then
                isMatch = true
                break
            end
        end

        -- If it matches, print exactly what the game is sending
        if isMatch or self.Parent.Name == "Remotes" or self.Parent.Name == "Pets" or self.Parent.Name == "Eggs" then
            print("\n🚨 [EGG SPY] INTERCEPTED NETWORK CALL 🚨")
            print("Remote Name:   " .. self.Name)
            print("Remote Type:   " .. self.ClassName)
            print("Remote Path:   " .. self:GetFullName())
            print("Action:        " .. method)
            print("--- Arguments Sent ---")
            
            if #args == 0 then
                print("   [None] (The game sent no arguments)")
            else
                for i, v in ipairs(args) do
                    local valStr = tostring(v)
                    if type(v) == "string" then
                        valStr = '"' .. valStr .. '"'
                    end
                    print("   Arg " .. i .. ": " .. valStr .. " (" .. type(v) .. ")")
                end
            end
            print("----------------------------------------\n")
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(gmt, true)
print("✅ Mini Remote Spy Active! Go manually buy an egg and check this console.")
