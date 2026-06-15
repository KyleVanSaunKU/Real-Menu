local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local bookEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

-- Function to smoothly fly your character to a destination
local function tweenTo(targetCFrame)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Calculate distance to determine how long the flight should take
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local speed = 35 -- Studs per second. Keep this reasonable to bypass velocity anti-cheats.
    local timeToTravel = distance / speed

    -- Freeze the character so gravity doesn't mess up the flight
    rootPart.Anchored = true 

    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait() -- Pause the script until we arrive
    
    rootPart.Anchored = false
    task.wait(0.2) -- Give the server a split second to register our new location
end

local function autoFarmSeries(targetSeries)
    -- ONLY grab objects the game has officially tagged as books
    local allBooks = CollectionService:GetTagged("Book")
    local pickedUpCount = 0
    local maxCarry = 6 -- The limit established in the LocalScript

    for _, book in ipairs(allBooks) do
        if pickedUpCount >= maxCarry then
            print("Inventory full! Reached max capacity of " .. maxCarry .. ".")
            break
        end

        local titleAttr = book:GetAttribute("title") or book:GetAttribute("Title")
        
        if titleAttr then
            local seriesName = string.gsub(titleAttr, "%s*EP%d+$", "")
            
            -- Make sure the book isn't already on a shelf or held by someone else
            local isPlaced = book:GetAttribute("PlacedSlotId") ~= nil
            
            if seriesName == targetSeries and not isPlaced then
                print("Flying to: " .. titleAttr)
                
                -- Fly slightly behind/above the book so we don't clip into shelves
                tweenTo(book.CFrame + Vector3.new(0, 2, 2))
                
                -- Fire the remote
                bookEvent:FireServer(book, "pickup")
                pickedUpCount += 1
                
                -- Wait for the server to process the pickup before moving to the next one
                task.wait(0.5) 
            end
        end
    end
    
    print("Finished farming " .. pickedUpCount .. " books from the " .. targetSeries .. " series.")
end

-- Example Usage:
autoFarmSeries("Money Heist")
