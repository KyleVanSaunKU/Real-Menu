local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local bookEvent = ReplicatedStorage:WaitForChild("BookNetworkEvent")

local function teleportAndStare(targetSeries)
    local allBooks = CollectionService:GetTagged("Book")
    local pickedUpCount = 0
    local maxCarry = 6 -- Server limit from the local script

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Save where you are standing so we can put you back later
    local originalCFrame = rootPart.CFrame

    for _, book in ipairs(allBooks) do
        if pickedUpCount >= maxCarry then
            print("Inventory full! Reached max capacity.")
            break
        end

        local titleAttr = book:GetAttribute("title") or book:GetAttribute("Title")
        local isPlaced = book:GetAttribute("PlacedSlotId") ~= nil
        
        if titleAttr and not isPlaced then
            local seriesName = string.gsub(titleAttr, "%s*EP%d+$", "")
            
            if seriesName == targetSeries then
                print("Locking onto: " .. titleAttr)
                
                -- 1. Calculate a spot exactly 3 studs away from the book
                local standPosition = book.Position + Vector3.new(0, 0, 3)
                
                -- 2. Teleport AND force the character's torso to face the book perfectly
                rootPart.CFrame = CFrame.lookAt(standPosition, book.Position)
                
                -- 3. Force your actual camera to look directly at it too
                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, book.Position)
                
                -- 4. Give the server 0.25 seconds to register your new position and rotation
                task.wait(0.25)
                
                -- 5. Fire the pickup remote
                bookEvent:FireServer(book, "pickup")
                pickedUpCount += 1
                
                -- Cooldown between books
                task.wait(0.2) 
            end
        end
    end
    
    -- Put you back where you started
    task.wait(0.1)
    rootPart.CFrame = originalCFrame
    
    print("Successfully picked up " .. pickedUpCount .. " books from: " .. targetSeries)
end

-- Example Usage:
teleportAndStare("Money Heist")
