local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

print("=============================================")
print("🚀 RUNNING INSPECTION FOR: " .. player.Name)
print("=============================================")

-- 1. Scan ReplicatedStorage Remotes for any pet/egg handling network code
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if remotesFolder then
    print("\n📦 Checking ReplicatedStorage.Remotes:")
    for _, child in ipairs(remotesFolder:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local lowerName = child.Name:lower()
            if lowerName:find("pet") or lowerName:find("egg") or lowerName:find("hatch") or lowerName:find("buy") then
                print(" -> Found Relevant Remote:", child:GetFullName())
            end
        end
    end
else
    print("\n⚠️ Remotes folder not found in ReplicatedStorage.")
end

-- 2. Inspect the PetFrame GUI for interactive buttons
local petMenu = player:WaitForChild("PlayerGui")
    :WaitForChild("MainUI")
    :WaitForChild("Menus")
    :WaitForChild("PetFrame")

print("\n🖥️ Scanning PlayerGui.MainUI.Menus.PetFrame:")
if petMenu then
    for _, descendant in ipairs(petMenu:GetDescendants()) do
        if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
            print(" -> Button Element:", descendant.Name, "Full Path: ", descendant:GetFullName())
        end
    end
else
    print("⚠️ PetFrame menu could not be located.")
end
print("=============================================")
print("📋 Copy and paste the console output above!")
print("=============================================")
