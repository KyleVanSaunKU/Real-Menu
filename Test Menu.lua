-- ==========================================
-- SCRIPT INITIALIZATION & NAMESPACE
-- ==========================================

-- A table to store script data globally
getgenv().GH = {}

-- Wrap the entire script in a protected call to catch and handle any errors without breaking
local success, err = pcall(function()
    
    -- ==========================================
    -- SERVICE DECLARATIONS
    -- ==========================================
        
    -- Fetch the required Roblox services for the script to function
    local Players = game:GetService("Players") -- Players
    local RunService = game:GetService("RunService") -- Used for loops tied to game frames (Stepped, RenderStepped)
    local UserInputService = game:GetService("UserInputService") -- Detects key presses and mouse clicks
    local StarterGui = game:GetService("StarterGui") -- GUI
    local Workspace = game:GetService("Workspace") -- WorkSpace
    local CoreGui = game:GetService("CoreGui") -- Hidden GUI container for exploit scripts
    local Debris = game:GetService("Debris") -- Used to clean up instances automatically
    local player = Players.LocalPlayer -- Get your local Player
    local camera = Workspace.CurrentCamera -- Get your Players camera

    -- Store references in the global GH table for easy access inside functions
    GH.Players = Players -- Players
    GH.RunService = RunService -- Frames
    GH.UserInputService = UserInputService -- Key Presses
    GH.player = player -- Player
    GH.camera = camera -- Camera
    GH.Keybinds = {} -- Stores the currently active keybinds
    GH.ButtonLogics = {} -- Maps a UI button to its specific function
    GH.bindingBtn = nil -- Tracks which button is currently waiting for a keybind input
    GH.bindingOrigText = "" -- Stores the original text of a button while it is being bound again

    -- ==========================================
    -- KEYBIND LOGIC OVERHAUL
    -- ==========================================
        
    -- Listens for any keyboard or mouse input
    UserInputService.InputBegan:Connect(function(input, gpe)
        -- If the user is currently trying to bind a key to a button
        if GH.bindingBtn then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                        
                -- Unbind the key completely if they press Escape or Backspace
                if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace then
                    for k, v in pairs(GH.Keybinds) do
                        if v.btn == GH.bindingBtn then GH.Keybinds[k] = nil end
                    end
                    GH.bindingBtn.Text = GH.bindingOrigText
                    GH.bindingBtn = nil
                    return
                end
                
                -- Check for and remove overlapping binds if the key is already used by another button
                if GH.Keybinds[key] and GH.Keybinds[key].btn ~= GH.bindingBtn then
                    local oldBtn = GH.Keybinds[key].btn
                    GH.Keybinds[key] = nil
                    oldBtn.Text = string.split(oldBtn.Text, " [")[1] -- Remove the "[Key]" text from the UI visually
                end

                -- Remove any old binds for the current button before assigning the new one
                for k, v in pairs(GH.Keybinds) do
                    if v.btn == GH.bindingBtn then GH.Keybinds[k] = nil end
                end

                -- Save the new keybind and update the button's text to show it
                GH.Keybinds[key] = {func = GH.ButtonLogics[GH.bindingBtn], btn = GH.bindingBtn}
                GH.bindingBtn.Text = GH.bindingOrigText .. " [" .. key.Name .. "]"
                GH.bindingBtn = nil
            end
        -- If not currently binding and not typing in chat then execute the mapped function if the pressed key is in the Keybinds table
        elseif not gpe then
            if input.UserInputType == Enum.UserInputType.Keyboard and GH.Keybinds[input.KeyCode] then
                GH.playSound()
                GH.Keybinds[input.KeyCode].func()
            end
        end
    end)

    -- ==========================================
    -- GUI CLEANUP & SETUP
    -- ==========================================
        
    -- Destroys existing versions of this menu to prevent duplicates when re-executing
    if player:FindFirstChild("PlayerGui") then
        if player.PlayerGui:FindFirstChild("UnifiedModernGui") then 
            player.PlayerGui.UnifiedModernGui:Destroy() 
        end
        if player.PlayerGui:FindFirstChild("PinnedButtonsGui") then 
            player.PlayerGui.PinnedButtonsGui:Destroy() 
        end
    end
    if CoreGui:FindFirstChild("PinnedButtonsGui") then 
        CoreGui.PinnedButtonsGui:Destroy() 
    end

    -- Create the GUI layer for buttons dragged out of the main menu
    local pinGui = Instance.new("ScreenGui")
    pinGui.Name = "PinnedButtonsGui" -- Kept as string for cleanup logic
    
    -- Attempt to put it in CoreGui (hidden from game detection), fallback to PlayerGui
    if not pcall(function() pinGui.Parent = CoreGui end) then 
        pinGui.Parent = player.PlayerGui 
    end
    
    pinGui.ResetOnSpawn = false
    GH.pinGui = pinGui

    local PinnedItems = {} 
    local BlockClicks = {}

    -- Function to play a UI click sound (chefs kiss)
    GH.playSound = function()
        local s = Instance.new("Sound")
        s.Name = ""
        s.SoundId = "rbxassetid://4590662766"
        s.Volume = 1
        s.Parent = pinGui
        s:Play()
        Debris:AddItem(s, 2) -- Automatically deletes the sound object after 2 seconds
    end

    -- ==========================================
    -- DRAG & PIN MECHANICS
    -- ==========================================
        
    -- Makes UI elements draggable across the screen
    GH.makeDraggable = function(obj, callback)
        local dragging = false
        local dragInput
        local dragStart
        local startPos
        local isClick = true

        obj.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                isClick = true
                dragStart = input.Position
                startPos = obj.Position
                
                local con
                con = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        con:Disconnect()
                        dragging = false
                        if isClick and callback then GH.playSound(); callback() end
                    end
                end)
            end
        end)

        obj.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 5 then
                    isClick = false
                    obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end)
    end

    -- Registers a button to the system, handling clicks, holding, and right-clicks for binding buttons
    GH.RegisterButton = function(btn, logicFunc)
        GH.ButtonLogics[btn] = logicFunc
        
        -- Auto add any keybinds to the UI and updates the button text to display the assigned hotkey (e.g., "SPEED: OFF [X]")
        local isUpdatingText = false
        btn:GetPropertyChangedSignal("Text"):Connect(function()
            if isUpdatingText then return end
            if btn.Text == "[PRESS KEY]" then return end
            if string.match(btn.Text, " %[[^%]]+]$") then return end
            
            local boundKey = nil
            for k, v in pairs(GH.Keybinds) do
                if v.btn == btn then boundKey = k.Name; break end
            end
            
            if boundKey then
                isUpdatingText = true
                btn.Text = btn.Text .. " [" .. boundKey .. "]"
                isUpdatingText = false
            end
        end)

        -- Execute the button/functions on left-clicks
        btn.MouseButton1Click:Connect(function()
            -- Cancel binding if they accidentally clicked the button itself
            if GH.bindingBtn == btn then
                GH.bindingBtn.Text = GH.bindingOrigText
                GH.bindingBtn = nil
                return
            end
            
            if BlockClicks[btn] then BlockClicks[btn] = false; return end
            local s = Instance.new("Sound", btn)
            s.SoundId = "rbxassetid://4590662766"; s.Volume = 1; s:Play(); s.PlayOnRemove = true; s:Destroy()
            logicFunc() 
        end)

        local isHolding = false
        local startTime = 0
        local parentScroll = btn:FindFirstAncestorOfClass("ScrollingFrame")

        btn.InputBegan:Connect(function(input)
            -- Start the Keybind Listener on right-clicks
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if GH.bindingBtn and GH.bindingBtn ~= btn then 
                    GH.bindingBtn.Text = GH.bindingOrigText 
                end
                
                GH.bindingBtn = btn
                GH.bindingOrigText = string.split(btn.Text, " [")[1]
                btn.Text = "[PRESS KEY]"
            end

            -- UI Mover logic on left-clicks
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if GH.bindingBtn == btn then return end 
                
                isHolding = true; startTime = tick()
                local startCanvasPos = parentScroll and parentScroll.CanvasPosition or Vector2.new(0, 0)
                
                task.spawn(function()
                    while isHolding do
                        task.wait(0.1)
                        if not isHolding then break end
                        -- Cancel hold if they start scrolling the menu instead
                        if parentScroll and (parentScroll.CanvasPosition - startCanvasPos).Magnitude > 2 then isHolding = false; break end
                        
                        -- If held for 0.5 seconds, create a "Pinned" draggable clone of the button on the screen
                        if tick() - startTime >= 0.5 then
                            isHolding = false; BlockClicks[btn] = true; GH.playSound() 
                            
                            if PinnedItems[btn] then 
                                PinnedItems[btn]:Destroy(); PinnedItems[btn] = nil 
                            else
                                local clone = btn:Clone()
                                clone.Name = "" -- Obfuscated
                                clone.Parent = pinGui
                                clone.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, 30)
                                clone.Position = UDim2.new(0.5, -(btn.AbsoluteSize.X / 2), 0.5, -50)
                                
                                -- Clean up extra UI elements inside the clone (like padding/arrows)
                                for _, c in pairs(clone:GetChildren()) do 
                                    if c:IsA("LocalScript") or c:IsA("UIPadding") or c:IsA("Frame") or (c:IsA("TextButton") and c.Name == "ArrowToggle") then c:Destroy() end 
                                end
                                
                                clone.TextYAlignment = Enum.TextYAlignment.Center
                                GH.makeDraggable(clone, function() logicFunc() end)
                                
                                -- Sync the clone's text and color to match the original button
                                btn:GetPropertyChangedSignal("Text"):Connect(function() if clone.Parent then clone.Text = btn.Text end end)
                                btn:GetPropertyChangedSignal("BackgroundColor3"):Connect(function() if clone.Parent then clone.BackgroundColor3 = btn.BackgroundColor3 end end)
                                
                               -- Close Button for the "Pinned" buttons
                                local closeCloneBtn = Instance.new("TextButton", clone)
                                closeCloneBtn.Name = "" -- Obfuscated
                                closeCloneBtn.Size = UDim2.new(0, 20, 0, 20) 
                                closeCloneBtn.Position = UDim2.new(1, -20, 0, 0)
                                closeCloneBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                                closeCloneBtn.Text = "X"
                                closeCloneBtn.TextColor3 = Color3.new(1, 1, 1)
                                closeCloneBtn.Font = Enum.Font.Arcade
                                closeCloneBtn.TextSize = 12
                                closeCloneBtn.ZIndex = 10
                                Instance.new("UICorner", closeCloneBtn).CornerRadius = UDim.new(0, 6)

                                closeCloneBtn.MouseButton1Click:Connect(function()
                                    GH.playSound()
                                    clone:Destroy()
                                    PinnedItems[btn] = nil
                                end)
                                PinnedItems[btn] = clone
                            end 
                            break
                        end
                    end
                end)
                
                local endCon
                endCon = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then isHolding = false; endCon:Disconnect() end end)
            end
        end)
        
        -- Destroy pinned clone if original button is destroyed
        btn.AncestryChanged:Connect(function() if not btn.Parent and PinnedItems[btn] then PinnedItems[btn]:Destroy() end end)
    end

    -- ==========================================
    -- MAIN MENU UI CREATION
    -- ==========================================
        
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = GH.pinGui.Parent 
    screenGui.Name = "UnifiedModernGui" -- Kept as string for cleanup logic
    screenGui.ResetOnSpawn = false
    screenGui.AutoLocalize = false 
    screenGui.DisplayOrder = 100 
    GH.mainGui = screenGui 

    -- Main Hub Window
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "" -- Obfuscated
    mainFrame.Size = UDim2.new(0, 180, 0, 185) 
    mainFrame.Position = UDim2.new(0.5, -90, 0.5, -90)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(60, 60, 60); stroke.Thickness = 1

    local titleLabel = Instance.new("TextLabel", mainFrame)
    titleLabel.Size = UDim2.new(1, -50, 0, 25); titleLabel.Position = UDim2.new(0, 10, 0, 2)
    titleLabel.BackgroundTransparency = 1; titleLabel.Text = "REAL'S MENU" 
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200); titleLabel.Font = Enum.Font.Arcade
    titleLabel.TextSize = 13; titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Close Button
    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 20, 0, 20); closeBtn.Position = UDim2.new(1, -25, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60); closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1); closeBtn.Font = Enum.Font.Arcade
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy(); GH.pinGui:Destroy() end)

    -- Minimize Button
    local minBtn = Instance.new("TextButton", mainFrame)
    minBtn.Size = UDim2.new(0, 20, 0, 20); minBtn.Position = UDim2.new(1, -50, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80); minBtn.Text = "-"
    minBtn.TextColor3 = Color3.new(1, 1, 1); minBtn.Font = Enum.Font.Arcade
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)
    
    -- Handles tweening (smooth animation) to hide/show the menu
    minBtn.MouseButton1Click:Connect(function() 
        if mainFrame.Size.Y.Offset > 50 then 
            mainFrame:TweenSize(UDim2.new(0, 180, 0, 30), "Out", "Quad", 0.3, true); minBtn.Text = "+" 
        else 
            mainFrame:TweenSize(UDim2.new(0, 180, 0, 185), "Out", "Quad", 0.3, true); minBtn.Text = "-" 
        end 
    end)

    -- Scrolling frame for the function buttons
    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -10, 1, -35); scroll.Position = UDim2.new(0, 5, 0, 35)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 5); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Helper function to rapidly generate standard UI buttons
    GH.createBtn = function(text, color, order)
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(0.95, 0, 0, 30); btn.BackgroundColor3 = color; btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.Arcade; btn.TextSize = 12
        btn.LayoutOrder = order; btn.AutoButtonColor = true; btn.AutoLocalize = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- ==========================================
    -- CHEAT FUNCTIONS
    -- ==========================================

    -- === INVISIBILITY ===
    local btnInvis = Instance.new("TextButton", scroll)
    btnInvis.Name = ""; -- Obfuscated
    btnInvis.Size = UDim2.new(0.95, 0, 0, 30); btnInvis.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    btnInvis.Text = "INVIS: OFF"; btnInvis.TextColor3 = Color3.new(1, 1, 1); btnInvis.Font = Enum.Font.Arcade
    btnInvis.TextSize = 12; btnInvis.LayoutOrder = 1; btnInvis.ClipsDescendants = true
    btnInvis.AutoLocalize = false; btnInvis.TextYAlignment = Enum.TextYAlignment.Center

    local invisPadding = Instance.new("UIPadding", btnInvis); invisPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnInvis).CornerRadius = UDim.new(0, 6)

    -- Dropdown arrow for slider
    local arrowInvis = Instance.new("TextButton", btnInvis)
    arrowInvis.Name = "ArrowToggle"; -- Kept as string for cleanup clone logic
    arrowInvis.Size = UDim2.new(0, 30, 0, 30); arrowInvis.Position = UDim2.new(1, -30, 0, 0)
    arrowInvis.BackgroundTransparency = 1; arrowInvis.Text = "V"; arrowInvis.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowInvis.Font = Enum.Font.Arcade; arrowInvis.TextSize = 14; arrowInvis.AutoLocalize = false

    -- Slider UI elements
    local invisSliderC = Instance.new("Frame", btnInvis)
    invisSliderC.Name = ""; -- Obfuscated
    invisSliderC.Size = UDim2.new(1, 0, 0, 35)
    invisSliderC.Position = UDim2.new(0, 0, 0, 18); invisSliderC.BackgroundTransparency = 1; invisSliderC.Visible = false
    local invisSliderBg = Instance.new("Frame", invisSliderC)
    invisSliderBg.Size = UDim2.new(0.8, 0, 0, 4); invisSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0)
    invisSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); invisSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", invisSliderBg).CornerRadius = UDim.new(1, 0)
    local invisSliderFill = Instance.new("Frame", invisSliderBg)
    invisSliderFill.Size = UDim2.new(0.4, 0, 1, 0); invisSliderFill.BackgroundColor3 = Color3.new(1, 1, 1); invisSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", invisSliderFill).CornerRadius = UDim.new(1, 0)
    local invisSliderTrig = Instance.new("TextButton", invisSliderBg)
    invisSliderTrig.Size = UDim2.new(1, 0, 6, 0); invisSliderTrig.Position = UDim2.new(0, 0, -2.5, 0)
    invisSliderTrig.BackgroundTransparency = 1; invisSliderTrig.Text = ""; invisSliderTrig.ZIndex = 10
    local invisValText = Instance.new("TextLabel", invisSliderC)
    invisValText.Size = UDim2.new(1, 0, 0, 15); invisValText.Position = UDim2.new(0, 0, 0.45, 0)
    invisValText.BackgroundTransparency = 1; invisValText.Text = "OFFSET: -100"; invisValText.TextColor3 = Color3.fromRGB(200, 200, 200)
    invisValText.Font = Enum.Font.Arcade; invisValText.TextSize = 10; invisValText.AutoLocalize = false

    local invis_on, invis_expanded, invisOffset, dragInvis, maxInvisOffset = false, false, -100, false, 500

    -- Expands the button to reveal the Y-Offset slider
    arrowInvis.MouseButton1Click:Connect(function()
        GH.playSound(); invis_expanded = not invis_expanded
        if invis_expanded then
            arrowInvis.Text = "^"; btnInvis.TextYAlignment = Enum.TextYAlignment.Top; invisPadding.PaddingTop = UDim.new(0, 6)
            btnInvis:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); invisSliderC.Visible = true
        else
            arrowInvis.Text = "V"; btnInvis.TextYAlignment = Enum.TextYAlignment.Center; invisPadding.PaddingTop = UDim.new(0, 0)
            btnInvis:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); invisSliderC.Visible = false
        end
    end)

    -- Performs the actual invisibility trick using a hidden seat welded to the player
    local function setInvisState(state)
        local c = GH.player.Character; if not c then return end
        for _, o in pairs(workspace:GetChildren()) do if o.Name == 'invischair' then pcall(function() o:Destroy() end) end end
        for _, v in pairs(c:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end end
        if state then
            local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
            task.wait(0.05); local scf = r.CFrame; local under = r.Position + Vector3.new(0, invisOffset, 0); c:MoveTo(under); task.wait(0.1)
            local s = Instance.new("Seat", workspace); s.Anchored = true; s.CanCollide = false; s.Transparency = 1
            s.Position = under; s.Name = "invischair"; local w = Instance.new("Weld", s); w.Part0 = s; w.Part1 = r
            task.wait(); s.CFrame = scf; s.Anchored = false
            for _, v in pairs(c:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0.5 end end
        end
    end

    GH.RegisterButton(btnInvis, function()
        invis_on = not invis_on
        if invis_on then btnInvis.Text = "INVIS: ON"; btnInvis.BackgroundColor3 = Color3.fromRGB(0, 200, 100); setInvisState(true) 
        else btnInvis.Text = "INVIS: OFF"; btnInvis.BackgroundColor3 = Color3.fromRGB(0, 120, 215); setInvisState(false) end
    end)

    local function setInvisScale(input)
        local p = math.clamp((input.Position.X - invisSliderBg.AbsolutePosition.X) / invisSliderBg.AbsoluteSize.X, 0, 1)
        invisSliderFill.Size = UDim2.new(p, 0, 1, 0); invisOffset = math.floor((p * (maxInvisOffset * 2)) - maxInvisOffset)
        invisValText.Text = "OFFSET: " .. invisOffset
    end

    invisSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragInvis = true; setInvisScale(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragInvis and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setInvisScale(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then if dragInvis then dragInvis = false; if invis_on then setInvisState(true) end end end end)

    -- === SPEED ===
    -- Slider UI and execution logic for forcing the player's walkspeed on every frame
    local btnSpeed = Instance.new("TextButton", scroll)
    btnSpeed.Name = ""; -- Obfuscated
    btnSpeed.Size = UDim2.new(0.95, 0, 0, 30); btnSpeed.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    btnSpeed.Text = "SPEED: OFF"; btnSpeed.TextColor3 = Color3.new(1, 1, 1); btnSpeed.Font = Enum.Font.Arcade
    btnSpeed.TextSize = 12; btnSpeed.LayoutOrder = 2; btnSpeed.ClipsDescendants = true; btnSpeed.AutoLocalize = false; btnSpeed.TextYAlignment = Enum.TextYAlignment.Center

    local speedPadding = Instance.new("UIPadding", btnSpeed); speedPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnSpeed).CornerRadius = UDim.new(0, 6)
    local arrowSpeed = Instance.new("TextButton", btnSpeed)
    arrowSpeed.Name = "ArrowToggle"; -- Kept as string for cleanup clone logic
    arrowSpeed.Size = UDim2.new(0, 30, 0, 30); arrowSpeed.Position = UDim2.new(1, -30, 0, 0)
    arrowSpeed.BackgroundTransparency = 1; arrowSpeed.Text = "V"; arrowSpeed.TextColor3 = Color3.fromRGB(255, 255, 255); arrowSpeed.Font = Enum.Font.Arcade; arrowSpeed.TextSize = 14; arrowSpeed.AutoLocalize = false
    local speedSliderC = Instance.new("Frame", btnSpeed)
    speedSliderC.Name = ""; -- Obfuscated
    speedSliderC.Size = UDim2.new(1, 0, 0, 35); speedSliderC.Position = UDim2.new(0, 0, 0, 18); speedSliderC.BackgroundTransparency = 1; speedSliderC.Visible = false
    local speedSliderBg = Instance.new("Frame", speedSliderC)
    speedSliderBg.Size = UDim2.new(0.8, 0, 0, 4); speedSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0); speedSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); speedSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", speedSliderBg).CornerRadius = UDim.new(1, 0)
    local speedSliderFill = Instance.new("Frame", speedSliderBg)
    speedSliderFill.Size = UDim2.new(48 / 300, 0, 1, 0); speedSliderFill.BackgroundColor3 = Color3.new(1, 1, 1); speedSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", speedSliderFill).CornerRadius = UDim.new(1, 0)
    local speedSliderTrig = Instance.new("TextButton", speedSliderBg)
    speedSliderTrig.Size = UDim2.new(1, 0, 6, 0); speedSliderTrig.Position = UDim2.new(0, 0, -2.5, 0); speedSliderTrig.BackgroundTransparency = 1; speedSliderTrig.Text = ""; speedSliderTrig.ZIndex = 10
    local speedValText = Instance.new("TextLabel", speedSliderC)
    speedValText.Size = UDim2.new(1, 0, 0, 15); speedValText.Position = UDim2.new(0, 0, 0.45, 0); speedValText.BackgroundTransparency = 1
    speedValText.Text = "VAL: 48"; speedValText.TextColor3 = Color3.fromRGB(200, 200, 200); speedValText.Font = Enum.Font.Arcade; speedValText.TextSize = 10; speedValText.AutoLocalize = false

    local isSpeedBoosted, speed_expanded, walkSpeedVal, speedLoop, dragSpeed = false, false, 48, nil, false

    arrowSpeed.MouseButton1Click:Connect(function()
        GH.playSound(); speed_expanded = not speed_expanded
        if speed_expanded then
            arrowSpeed.Text = "^"; btnSpeed.TextYAlignment = Enum.TextYAlignment.Top; speedPadding.PaddingTop = UDim.new(0, 6)
            btnSpeed:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); speedSliderC.Visible = true
        else
            arrowSpeed.Text = "V"; btnSpeed.TextYAlignment = Enum.TextYAlignment.Center; speedPadding.PaddingTop = UDim.new(0, 0)
            btnSpeed:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); speedSliderC.Visible = false
        end
    end)

    GH.RegisterButton(btnSpeed, function()
        isSpeedBoosted = not isSpeedBoosted
        if isSpeedBoosted then
            btnSpeed.Text = "SPEED: ON"; btnSpeed.BackgroundColor3 = Color3.fromRGB(0, 180, 100); if speedLoop then speedLoop:Disconnect() end
            -- Binds to Stepped to continuously force speed, overriding anti-cheats or game scripts that reset it
            speedLoop = GH.RunService.Stepped:Connect(function() if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") and GH.player.Character.Humanoid.WalkSpeed ~= walkSpeedVal then GH.player.Character.Humanoid.WalkSpeed = walkSpeedVal end end)
        else
            btnSpeed.Text = "SPEED: OFF"; btnSpeed.BackgroundColor3 = Color3.fromRGB(255, 170, 0); if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
            if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then GH.player.Character.Humanoid.WalkSpeed = 16 end
        end
    end)

    local function setSpeed(input)
        local p = math.clamp((input.Position.X - speedSliderBg.AbsolutePosition.X) / speedSliderBg.AbsoluteSize.X, 0, 1)
        speedSliderFill.Size = UDim2.new(p, 0, 1, 0); walkSpeedVal = math.floor(p * 300); if walkSpeedVal < 16 then walkSpeedVal = 16 end
        speedValText.Text = "VAL: " .. walkSpeedVal; if isSpeedBoosted and GH.player.Character then GH.player.Character.Humanoid.WalkSpeed = walkSpeedVal end
    end
    
    speedSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragSpeed = true; setSpeed(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragSpeed and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setSpeed(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragSpeed = false end end)

    -- === FLY ===
    -- Employs BodyGyro and BodyVelocity physics to manipulate character movement mid-air
    local btnFly = Instance.new("TextButton", scroll)
    btnFly.Name = ""; -- Obfuscated
    btnFly.Size = UDim2.new(0.95, 0, 0, 30); btnFly.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    btnFly.Text = "FLY: OFF"; btnFly.TextColor3 = Color3.new(1, 1, 1); btnFly.Font = Enum.Font.Arcade; btnFly.TextSize = 12
    btnFly.LayoutOrder = 3; btnFly.ClipsDescendants = true; btnFly.AutoLocalize = false; btnFly.TextYAlignment = Enum.TextYAlignment.Center

    local flyPadding = Instance.new("UIPadding", btnFly); flyPadding.PaddingTop = UDim.new(0, 0); Instance.new("UICorner", btnFly).CornerRadius = UDim.new(0, 6)
    local arrowFly = Instance.new("TextButton", btnFly); arrowFly.Name = "ArrowToggle"; -- Kept as string for cleanup clone logic
    arrowFly.Size = UDim2.new(0, 30, 0, 30); arrowFly.Position = UDim2.new(1, -30, 0, 0)
    arrowFly.BackgroundTransparency = 1; arrowFly.Text = "V"; arrowFly.TextColor3 = Color3.fromRGB(255, 255, 255); arrowFly.Font = Enum.Font.Arcade; arrowFly.TextSize = 14; arrowFly.AutoLocalize = false

    local flySliderC = Instance.new("Frame", btnFly); flySliderC.Name = ""; -- Obfuscated
    flySliderC.Size = UDim2.new(1, 0, 0, 35); flySliderC.Position = UDim2.new(0, 0, 0, 18); flySliderC.BackgroundTransparency = 1; flySliderC.Visible = false
    local flySliderBg = Instance.new("Frame", flySliderC); flySliderBg.Size = UDim2.new(0.8, 0, 0, 4); flySliderBg.Position = UDim2.new(0.1, 0, 0.2, 0); flySliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); flySliderBg.BorderSizePixel = 0; Instance.new("UICorner", flySliderBg).CornerRadius = UDim.new(1, 0)
    local flySliderFill = Instance.new("Frame", flySliderBg); flySliderFill.Size = UDim2.new(50 / 300, 0, 1, 0); flySliderFill.BackgroundColor3 = Color3.new(1, 1, 1); flySliderFill.BorderSizePixel = 0; Instance.new("UICorner", flySliderFill).CornerRadius = UDim.new(1, 0)
    local flySliderTrig = Instance.new("TextButton", flySliderBg); flySliderTrig.Size = UDim2.new(1, 0, 6, 0); flySliderTrig.Position = UDim2.new(0, 0, -2.5, 0); flySliderTrig.BackgroundTransparency = 1; flySliderTrig.Text = ""; flySliderTrig.ZIndex = 10
    local flyText = Instance.new("TextLabel", flySliderC); flyText.Size = UDim2.new(1, 0, 0, 15); flyText.Position = UDim2.new(0, 0, 0.45, 0); flyText.BackgroundTransparency = 1; flyText.Text = "SPEED: 50"; flyText.TextColor3 = Color3.fromRGB(200, 200, 200); flyText.Font = Enum.Font.Arcade; flyText.TextSize = 10; flyText.AutoLocalize = false; flyText.ZIndex = 1

    local fly_on, fly_expanded, flySpeed, maxFlySpeed, dragFly = false, false, 50, 300, false
    local smoothVel, flyBodyGyro, flyBodyVelocity, flyConnection = Vector3.zero, nil, nil, nil
    
    arrowFly.MouseButton1Click:Connect(function()
        GH.playSound(); fly_expanded = not fly_expanded
        if fly_expanded then arrowFly.Text = "^"; btnFly.TextYAlignment = Enum.TextYAlignment.Top; flyPadding.PaddingTop = UDim.new(0, 6); btnFly:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); flySliderC.Visible = true
        else arrowFly.Text = "V"; btnFly.TextYAlignment = Enum.TextYAlignment.Center; flyPadding.PaddingTop = UDim.new(0, 0); btnFly:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); flySliderC.Visible = false end
    end)

    GH.RegisterButton(btnFly, function()
        fly_on = not fly_on
        if fly_on then 
            btnFly.Text = "FLY: ON"; btnFly.BackgroundColor3 = Color3.fromRGB(0, 180, 100); local c = GH.player.Character; if not c then return end
            local r = c:FindFirstChild("HumanoidRootPart"); local h = c:FindFirstChild("Humanoid"); if not r or not h then return end
            
            -- Set PlatformStand true so animations don't interfere
            h.PlatformStand = true; 
            -- BodyGyro keeps the player pointing where the camera is looking
            flyBodyGyro = Instance.new("BodyGyro", r); flyBodyGyro.P = 9e4; flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9); flyBodyGyro.cframe = r.CFrame
            -- BodyVelocity physically pushes the player through the air
            flyBodyVelocity = Instance.new("BodyVelocity", r); flyBodyVelocity.velocity = Vector3.zero; flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9); smoothVel = Vector3.zero
            
            flyConnection = GH.RunService.RenderStepped:Connect(function()
                if not c or not h then return end; local md = h.MoveDirection; local tv = Vector3.zero
                -- Calculate flight direction based on Camera vector and player movement input (WASD)
                if md.Magnitude > 0 then local cl = GH.camera.CFrame.LookVector; local cr = GH.camera.CFrame.RightVector; local fl = (cl * Vector3.new(1, 0, 1)).Unit; local fr = (cr * Vector3.new(1, 0, 1)).Unit; tv = (cl * md:Dot(fl) + cr * md:Dot(fr)) * flySpeed end
                smoothVel = smoothVel:Lerp(tv, 0.15); flyBodyGyro.cframe = GH.camera.CFrame; flyBodyVelocity.velocity = smoothVel  
            end)
        else 
            btnFly.Text = "FLY: OFF"; btnFly.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end; if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end; if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
            if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then GH.player.Character.Humanoid.PlatformStand = false end
        end
    end)

    local function setFly(input) local p = math.clamp((input.Position.X - flySliderBg.AbsolutePosition.X) / flySliderBg.AbsoluteSize.X, 0, 1); flySliderFill.Size = UDim2.new(p, 0, 1, 0); flySpeed = math.floor(p * maxFlySpeed); if flySpeed < 10 then flySpeed = 10 end; flyText.Text = "SPEED: " .. flySpeed end
    flySliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragFly = true; setFly(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragFly and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setFly(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragFly = false end end)

    -- === NOCLIP ===
    -- Allows walking through walls by setting character part collisions to false
    local btnNoclip = GH.createBtn("NOCLIP: OFF", Color3.fromRGB(200, 60, 60), 4)
    local noclip_on = false
    local noclipConnection = nil

    GH.RegisterButton(btnNoclip, function()
        noclip_on = not noclip_on
        btnNoclip.Text = noclip_on and "NOCLIP: ON" or "NOCLIP: OFF"
        btnNoclip.BackgroundColor3 = noclip_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if noclip_on then
            if not noclipConnection then
                -- Bound to Stepped because physics step overwrites CanCollide every frame
                noclipConnection = GH.RunService.Stepped:Connect(function()
                    if GH.player.Character then
                        for _, v in pairs(GH.player.Character:GetDescendants()) do
                            if v:IsA("BasePart") and v.CanCollide then
                                v.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if GH.player.Character then
                local hum = GH.player.Character:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end)

    -- === AIMBOT (AUTO-LOCK/CAMERA-LOCK to Closest Player's Head) ===
    local btnAutoLock = GH.createBtn("AIMBOT: OFF", Color3.fromRGB(200, 60, 60), 5)
    local lock_on = false
    local lockConnection = nil

    -- Function to iterate through all active players to find the closest Head part to the LocalPlayer
    local function getNearestPlayerHead()
        local closestHead = nil
        local shortestDistance = math.huge
        local localChar = GH.player.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        if not localRoot then return nil end

        for _, p in pairs(GH.Players:GetPlayers()) do
            if p ~= GH.player and p.Character then
                local head = p.Character:FindFirstChild("Head")
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")

                -- Ensure the target is alive and has the required parts
                if head and root and hum and hum.Health > 0 then
                    local distance = (localRoot.Position - root.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestHead = head
                    end
                end
            end
        end
        return closestHead
    end

    GH.RegisterButton(btnAutoLock, function()
        lock_on = not lock_on
        btnAutoLock.Text = lock_on and "AIMBOT: ON" or "AIMBOT: OFF"
        btnAutoLock.BackgroundColor3 = lock_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if lock_on then
            if not lockConnection then
                lockConnection = GH.RunService.RenderStepped:Connect(function()
                    local targetHead = getNearestPlayerHead()
                    local currentCamera = workspace.CurrentCamera
                    
                    if targetHead and currentCamera then
                        -- Forces the camera to look directly at the target's head
                        currentCamera.CFrame = CFrame.lookAt(currentCamera.CFrame.Position, targetHead.Position)
                    end
                end)
            end
        else
            if lockConnection then
                lockConnection:Disconnect()
                lockConnection = nil
            end
        end
    end)

    -- === PLAYER ESP ===
    -- Draws outlines around players and a dot over their head if they are far away
    local btnEsp = GH.createBtn("PLAYERS: OFF", Color3.fromRGB(200, 60, 60), 6)
    local esp_on = false
    local minDotDistance = 40

    GH.RegisterButton(btnEsp, function()
        esp_on = not esp_on
        btnEsp.Text = esp_on and "PLAYERS: ON" or "PLAYERS: OFF"
        btnEsp.BackgroundColor3 = esp_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
        
        -- Cleanup ESP instances when toggled off
        if not esp_on then
            for _, p in pairs(GH.Players:GetPlayers()) do
                if p.Character then
                    local h = p.Character:FindFirstChild("GhostESP_Highlight")
                    if h then h:Destroy() end
                    local b = p.Character:FindFirstChild("GhostESP_Dot")
                    if b then b:Destroy() end
                end
            end
        end
    end)

    GH.RunService.Stepped:Connect(function()
        if esp_on then
            local localChar = GH.player.Character
            local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

            for _, p in pairs(GH.Players:GetPlayers()) do
                if p ~= GH.player and p.Character then
                    local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetRoot then
                        local highlight = p.Character:FindFirstChild("GhostESP_Highlight")
                        if not highlight then
                            highlight = Instance.new("Highlight", p.Character)
                            highlight.Name = "GhostESP_Highlight"
                            highlight.FillColor = Color3.new(0, 1, 0)
                            highlight.OutlineColor = Color3.new(0, 1, 0)
                            highlight.FillTransparency = 0.5
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end

                        local dotGui = p.Character:FindFirstChild("GhostESP_Dot")
                        if not dotGui then
                            dotGui = Instance.new("BillboardGui", p.Character)
                            dotGui.Name = "GhostESP_Dot"
                            dotGui.Adornee = targetRoot
                            dotGui.AlwaysOnTop = true
                            dotGui.Size = UDim2.new(0, 15, 0, 15)
                            
                            local marker = Instance.new("Frame", dotGui)
                            marker.Size = UDim2.new(1, 0, 1, 0)
                            marker.BackgroundColor3 = Color3.new(0, 1, 0)
                            marker.BorderSizePixel = 0
                            Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)
                        end

                        if localRoot then
                            local dist = (localRoot.Position - targetRoot.Position).Magnitude
                            if dist < minDotDistance then
                                dotGui.Enabled = false 
                            else
                                dotGui.Enabled = true
                            end
                        end
                    end
                end
            end
        end
    end)

    -- === SCAN BODY ===
    -- Deletes unneeded character accessories visually to clean up avatar
    local btnScan = GH.createBtn("SCAN BODY", Color3.fromRGB(45, 45, 45), 7)
    GH.RegisterButton(btnScan, function()
        if not GH.player.Character then return end; local cnt = 0
        for _, v in pairs(GH.player.Character:GetDescendants()) do 
            if v:IsA("BasePart") and (v.Name == "HumanoidRootPart" or v.BrickColor == BrickColor.new("Medium stone grey")) and not v:IsA("MeshPart") then v.Transparency = 1; cnt = cnt + 1 end 
        end
        btnScan.Text = "CLEAN: " .. cnt; btnScan.BackgroundColor3 = Color3.fromRGB(0, 180, 100); task.wait(1)
        btnScan.Text = "SCAN BODY"; btnScan.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end)

    -- === NPC ESP ===
    -- Works identical to Player ESP but scans workspace for non-player Humanoids
    local btnNpc = GH.createBtn("NPC: OFF", Color3.fromRGB(200, 60, 60), 8); local npc_on = false
    GH.RegisterButton(btnNpc, function() npc_on = not npc_on; btnNpc.Text = npc_on and "NPC: ON" or "NPC: OFF"; btnNpc.BackgroundColor3 = npc_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
        for _, v in pairs(workspace:GetDescendants()) do if v:IsA("Model") and (v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart")) and not GH.Players:GetPlayerFromCharacter(v) then local h = v:FindFirstChild("GhostNPC"); if npc_on and not h then local nh = Instance.new("Highlight", v); nh.Name = "GhostNPC"; nh.FillColor = Color3.fromRGB(255, 215, 0); nh.OutlineColor = Color3.fromRGB(255, 215, 0); nh.FillTransparency = 0.5; nh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop elseif not npc_on and h then h:Destroy() end end end 
    end)
    GH.RunService.Stepped:Connect(function() if npc_on then for _, v in pairs(workspace:GetDescendants()) do if v:IsA("Model") and (v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart")) and not GH.Players:GetPlayerFromCharacter(v) and not v:FindFirstChild("GhostNPC") then local nh = Instance.new("Highlight", v); nh.Name = "GhostNPC"; nh.FillColor = Color3.fromRGB(255, 215, 0); nh.OutlineColor = Color3.fromRGB(255, 215, 0); nh.FillTransparency = 0.5; nh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end end end end)

    -- === LIGHT ===
    -- Attaches a bright pointlight to your character for dark areas
    local btnLight = GH.createBtn("LIGHT: OFF", Color3.fromRGB(200, 60, 60), 9); local light_on = false
    GH.RegisterButton(btnLight, function() light_on = not light_on; local char = GH.player.Character
        if light_on then btnLight.Text = "LIGHT: ON"; btnLight.BackgroundColor3 = Color3.fromRGB(0, 180, 100); if char and char:FindFirstChild("HumanoidRootPart") then for _, v in pairs(char.HumanoidRootPart:GetChildren()) do if v.Name == "GhostHubLight" then v:Destroy() end end; local l = Instance.new("PointLight", char.HumanoidRootPart); l.Name = "GhostHubLight"; l.Range = 60; l.Brightness = 2; l.Color = Color3.new(1, 1, 1) end 
        else btnLight.Text = "LIGHT: OFF"; btnLight.BackgroundColor3 = Color3.fromRGB(200, 60, 60); if char then for _, v in pairs(char:GetDescendants()) do if v.Name == "GhostHubLight" then v:Destroy() end end end end 
    end)

    -- === FPS BOOST ===
    -- Removes shadows, fog, and complex materials to boost frame rate
    local btnFps = GH.createBtn("FPS BOOST: OFF", Color3.fromRGB(200, 60, 60), 10)
    local fps_on, fps_cache, lighting_cache = false, {}, {}
    GH.RegisterButton(btnFps, function() fps_on = not fps_on; btnFps.Text = fps_on and "FPS BOOST: ON" or "FPS BOOST: OFF"; btnFps.BackgroundColor3 = fps_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
        if fps_on then lighting_cache = {GS = game.Lighting.GlobalShadows, FE = game.Lighting.FogEnd}; game.Lighting.GlobalShadows = false; game.Lighting.FogEnd = 9e9; for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then if not fps_cache[v] then fps_cache[v] = {M = v.Material, R = v.Reflectance, C = v.CastShadow} end; v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0; v.CastShadow = false end end
        else game.Lighting.GlobalShadows = true; game.Lighting.FogEnd = lighting_cache.FE or 100000; for part, props in pairs(fps_cache) do if part and part.Parent then part.Material = props.M; part.Reflectance = props.R; part.CastShadow = props.C end end; fps_cache = {} end
    end)

    -- === UNLOCK JUMP ===
    -- Forces jumping and overrides anti-jump constraints (Will lock jump if disabled after menu launch)
    local btnJump = GH.createBtn("UNLOCK JUMP: OFF", Color3.fromRGB(0, 120, 215), 11); local jump_unlock_on, jumpLoop = false, nil
    GH.RegisterButton(btnJump, function()
        jump_unlock_on = not jump_unlock_on
        if jump_unlock_on then btnJump.Text = "UNLOCK JUMP: ON"; btnJump.BackgroundColor3 = Color3.fromRGB(0, 180, 100); if jumpLoop then jumpLoop:Disconnect() end; jumpLoop = GH.RunService.Stepped:Connect(function() if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then if GH.player.Character.Humanoid.JumpPower < 50 then GH.player.Character.Humanoid.JumpPower = 50 end; if GH.player.Character.Humanoid.JumpHeight < 7.2 then GH.player.Character.Humanoid.JumpHeight = 7.2 end; GH.player.Character.Humanoid.UseJumpPower = true; GH.player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end end)
        else btnJump.Text = "UNLOCK JUMP: OFF"; btnJump.BackgroundColor3 = Color3.fromRGB(0, 120, 215); if jumpLoop then jumpLoop:Disconnect(); jumpLoop = nil end; if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then GH.player.Character.Humanoid.JumpPower = 0; GH.player.Character.Humanoid.JumpHeight = 0; GH.player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end end
    end)

    -- === SET / LOAD WAYPOINT ===
    -- Records current position for teleporting back to later
    local btnSetCP = GH.createBtn("SET POINT", Color3.fromRGB(40, 40, 40), 12); local SavedCFrame = nil
    GH.RegisterButton(btnSetCP, function() if GH.player.Character and GH.player.Character:FindFirstChild("HumanoidRootPart") then SavedCFrame = GH.player.Character.HumanoidRootPart.CFrame; btnSetCP.Text = "SAVED!"; btnSetCP.BackgroundColor3 = Color3.fromRGB(50, 150, 50); task.wait(0.5); btnSetCP.Text = "SET POINT"; btnSetCP.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end end)

    local btnLoadCP = GH.createBtn("LOAD POINT", Color3.fromRGB(40, 40, 40), 13)
    GH.RegisterButton(btnLoadCP, function() if GH.player.Character and GH.player.Character:FindFirstChild("HumanoidRootPart") and SavedCFrame then GH.player.Character.HumanoidRootPart.CFrame = SavedCFrame; btnLoadCP.BackgroundColor3 = Color3.fromRGB(50, 150, 50); task.wait(0.2); btnLoadCP.BackgroundColor3 = Color3.fromRGB(40, 40, 40) else btnLoadCP.Text = "NO POINT!"; task.wait(0.5); btnLoadCP.Text = "LOAD POINT" end end)

    -- === POCKET INVENTORY ===
    -- Creates a custom UI window to manually manage Backpack tools (useful if the game disables inventory)
    local btnPocket = GH.createBtn("POCKET INV: OFF", Color3.fromRGB(200, 60, 60), 14)
    local invFrame, iScroll = nil, nil
    local invConnections = {}

    local function updateInvList()
        if not invFrame or not iScroll then return end
        for _, c in pairs(iScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        
        local list = {}
        local bp = GH.player:FindFirstChild("Backpack")
        local char = GH.player.Character

        if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end end       
        if char then for _, t in pairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end end
        
        table.sort(list, function(a, b) return a.Name < b.Name end) 
        
        for i, t in pairs(list) do
            local eq = (char and t.Parent == char)
            local b = Instance.new("TextButton", iScroll); b.LayoutOrder = i; b.Size = UDim2.new(1, -4, 0, 32); b.BackgroundColor3 = eq and Color3.fromRGB(48, 50, 58) or Color3.fromRGB(42, 44, 50); b.Text = ""; b.AutoButtonColor = false; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)            
            local l = Instance.new("TextLabel", b); l.Text = t.Name; l.Size = UDim2.new(1, -12, 1, 0); l.Position = UDim2.new(0, 10, 0, 0); l.BackgroundTransparency = 1; l.Font = Enum.Font.Arcade; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextColor3 = eq and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 160)       
            if eq then local ind = Instance.new("Frame", b); ind.Size = UDim2.new(0, 3, 0.6, 0); ind.Position = UDim2.new(0, 0, 0.2, 0); ind.BackgroundColor3 = Color3.fromRGB(80, 150, 255); Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2) end        
            
            b.MouseButton1Click:Connect(function() 
                local currentChar = GH.player.Character
                if currentChar and currentChar:FindFirstChild("Humanoid") then 
                    if eq then 
                        currentChar.Humanoid:UnequipTools() 
                    else 
                        if t and t.Parent then currentChar.Humanoid:EquipTool(t) end
                    end 
                end 
            end)          
        end
    end

    local function setupInvConnections()
        for _, c in pairs(invConnections) do c:Disconnect() end
        invConnections = {}
        if not invFrame then return end
        
        local bp = GH.player:FindFirstChild("Backpack")
        if bp then
            table.insert(invConnections, bp.ChildAdded:Connect(function(c) if c:IsA("Tool") then updateInvList() end end))
            table.insert(invConnections, bp.ChildRemoved:Connect(function(c) if c:IsA("Tool") then updateInvList() end end))
        end
        local char = GH.player.Character
        if char then
            table.insert(invConnections, char.ChildAdded:Connect(function(c) if c:IsA("Tool") then updateInvList() end end))
            table.insert(invConnections, char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then updateInvList() end end))
        end
    end

    GH.RegisterButton(btnPocket, function()
        if invFrame then 
            invFrame:Destroy(); invFrame = nil
            btnPocket.Text = "POCKET INV: OFF"; btnPocket.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            for _, c in pairs(invConnections) do c:Disconnect() end; invConnections = {}
            return 
        end 
        btnPocket.Text = "POCKET INV: ON"; btnPocket.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        invFrame = Instance.new("Frame", GH.mainGui); invFrame.Size = UDim2.new(0, 180, 0, 175); invFrame.Position = UDim2.new(0.5, 100, 0.5, -90); invFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 38); invFrame.Active = true; invFrame.Draggable = true; Instance.new("UICorner", invFrame).CornerRadius = UDim.new(0, 12)        
        local h = Instance.new("Frame", invFrame); h.Size = UDim2.new(1, 0, 0, 34); h.BackgroundColor3 = Color3.fromRGB(38, 40, 46); local t = Instance.new("TextLabel", h); t.Text = "Inventory"; t.Font = Enum.Font.Arcade; t.TextSize = 12; t.TextColor3 = Color3.new(1, 1, 1); t.Size = UDim2.new(1, -10, 1, 0); t.Position = UDim2.new(0, 10, 0, 0); t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
        local c = Instance.new("Frame", invFrame); c.Size = UDim2.new(1, -6, 1, -40); c.Position = UDim2.new(0, 3, 0, 37); c.BackgroundTransparency = 1; iScroll = Instance.new("ScrollingFrame", c); iScroll.Size = UDim2.new(1, 0, 1, 0); iScroll.BackgroundTransparency = 1; iScroll.ScrollBarThickness = 2; iScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 80); iScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; iScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        local il = Instance.new("UIListLayout", iScroll); il.Padding = UDim.new(0, 4); il.SortOrder = Enum.SortOrder.LayoutOrder
        
        setupInvConnections()
        updateInvList()
    end)

    -- === ROBLOX INV ===
    -- Turns the core Roblox inventory GUI bar on/off
    local btnRobloxInv = GH.createBtn("ROBLOX INV: ON", Color3.fromRGB(0, 180, 100), 15)
    GH.RegisterButton(btnRobloxInv, function()
        if btnRobloxInv.Text == "ROBLOX INV: OFF" then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end); btnRobloxInv.Text = "ROBLOX INV: ON"; btnRobloxInv.BackgroundColor3 = Color3.fromRGB(0, 180, 100)        
        else pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end); btnRobloxInv.Text = "ROBLOX INV: OFF"; btnRobloxInv.BackgroundColor3 = Color3.fromRGB(200, 60, 60) end    
    end)
    
    -- ==========================================
    -- RESET & DEATH HANDLING
    -- ==========================================
        
    -- Safely disables active cheat loops when the player dies to prevent the game crashing
    local function resetToggles()
        if invis_on then
            invis_on = false
            pcall(function() 
                btnInvis.Text = "INVIS: OFF"; btnInvis.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                for _, o in pairs(workspace:GetChildren()) do if o.Name == 'invischair' then pcall(function() o:Destroy() end) end end
            end)
        end
        if isSpeedBoosted then
            isSpeedBoosted = false
            pcall(function() btnSpeed.Text = "SPEED: OFF"; btnSpeed.BackgroundColor3 = Color3.fromRGB(255, 170, 0); if speedLoop then speedLoop:Disconnect(); speedLoop = nil end end)
        end
        if fly_on then
            fly_on = false
            pcall(function() 
                btnFly.Text = "FLY: OFF"; btnFly.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
                if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
                if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
            end)
        end
        if noclip_on then 
            noclip_on = false
            pcall(function() 
                btnNoclip.Text = "NOCLIP: OFF"
                btnNoclip.BackgroundColor3 = Color3.fromRGB(200, 60, 60) 
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
            end) 
        end
        if invFrame then updateInvList() end 
        if lock_on then
            lock_on = false
            pcall(function()
                btnAutoLock.Text = "AIMBOT: OFF"
                btnAutoLock.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if lockConnection then 
                    lockConnection:Disconnect() 
                    lockConnection = nil 
                end
            end)
        end
    end

    -- Hook up the reset functions to player death and respawn events
    if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then GH.player.Character.Humanoid.Died:Connect(resetToggles) end
    GH.player.CharacterAdded:Connect(function(char)
        resetToggles(); local hum = char:WaitForChild("Humanoid", 5)
        if hum then hum.Died:Connect(resetToggles) end
        
        task.spawn(function()
            task.wait(0.5) 
            if invFrame then
                setupInvConnections()
                updateInvList()
            end
        end)
    end)

    -- ==========================================
    -- INITIALIZATION COMPLETE
    -- ==========================================
        
    -- Initialize Default Keybinds on Script Launch
    local defaultBinds = {
        [Enum.KeyCode.Z] = btnInvis,
        [Enum.KeyCode.X] = btnSpeed,
        [Enum.KeyCode.C] = btnFly,
        [Enum.KeyCode.V] = btnNoclip,
        [Enum.KeyCode.B] = btnAutoLock
    }

    for key, button in pairs(defaultBinds) do
        GH.Keybinds[key] = {func = GH.ButtonLogics[button], btn = button}
        button.Text = button.Text .. " [" .. key.Name .. "]"
    end

    print("REAL MENU LOADED")
end)

-- Error message if the script fails to execute
if not success then warn("ERROR: " .. tostring(err)) end
