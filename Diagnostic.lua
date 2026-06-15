local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local bookEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

local function pickupClosestBook()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then 
        warn("Character not found.")
        return 
    end

    local closestBook = nil
    local shortestDistance = 10 -- The max distance the server allows

    -- Find the nearest legitimate book that isn't already on a shelf
    for _, book in ipairs(CollectionService:GetTagged("Book")) do
        if book:GetAttribute("PlacedSlotId") == nil then
            local dist = (rootPart.Position - book.Position).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closestBook = book
            end
        end
    end

    if closestBook then
        local titleAttr = closestBook:GetAttribute("title") or closestBook:GetAttribute("Title")
        print("Sending pickup request for:", titleAttr)
        
        -- Fire the remote
        bookEvent:FireServer(closestBook, "pickup")
    else
        warn("No loose books found within 10 studs!")
    end
end

pickupClosestBook()
