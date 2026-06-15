local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Grab the remote event caught by SimpleSpy
local bookEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

-- Function to pick up all books matching an exact title
local function pickupExactTitle(targetTitle)
    local count = 0
    
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child.Name == "Book" then
            local titleAttr = child:GetAttribute("title")
            
            if titleAttr and titleAttr == targetTitle then
                -- Fire the server with the Book instance and the "pickup" action
                bookEvent:FireServer(child, "pickup")
                count += 1
            end
        end
    end
    
    print("Picked up " .. count .. " copies of: " .. targetTitle)
end

-- Example Usage:
pickupExactTitle("Money Heist EP1")
