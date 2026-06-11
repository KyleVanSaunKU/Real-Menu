local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("--- 🥚 INSPECTING VISIBLE RARE EGG OBJECTS ---")
for _, obj in ipairs(workspace:GetChildren()) do
    if obj.Name == "RareEgg" then
        print("Found visible RareEgg instance:", obj)
        
        -- Check for prompts, click detectors, or touch pads inside the model
        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                print(" -> Found ProximityPrompt:", descendant:GetFullName())
            elseif descendant:IsA("ClickDetector") then
                print(" -> Found ClickDetector:", descendant:GetFullName())
            elseif descendant.Name == "TouchTransmitter" or descendant.Name == "TouchInterest" then
                print(" -> Found Touch/Hitbox part:", descendant:GetFullName())
            elseif descendant:IsA("GuiButton") then
                print(" -> Found UI Button inside egg model:", descendant:GetFullName())
            end
        end
    end
end

print("\n--- 🖥️ CHECKING PLAYER GUI MENUS FOR EGG/PET SHOPS ---")
local mainUI = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MainUI")
local menus = mainUI and mainUI:FindFirstChild("Menus")
if menus then
    for _, menu in ipairs(menus:GetChildren()) do
        if menu.Name:lower():find("egg") or menu.Name:lower():find("pet") or menu.Name:lower():find("shop") then
            print(" -> Potentially relevant menu in PlayerGui:", menu:GetFullName())
        end
    end
end
print("--- END INSPECTION ---")
