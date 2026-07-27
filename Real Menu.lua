-- ==========================================
-- REAL'S MENU
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
    local Wait = task.wait

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
    -- FLING HELPER FUNCTIONS
    -- ==========================================
    local function getPlrHum(char) return char and char:FindFirstChildOfClass("Humanoid") end
    local function getHead(char) return char and (char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso")) end
    local function getRoot(char) return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")) end
    local flingManager = { cFlingOldPos = nil, lFlingOldPos = nil }

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
    btnInvis.Size = UDim2.new(0.95, 0, 0, 30); btnInvis.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
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
        if invis_on then btnInvis.Text = "INVIS: ON"; btnInvis.BackgroundColor3 = Color3.fromRGB(0, 180, 100); setInvisState(true) 
        else btnInvis.Text = "INVIS: OFF"; btnInvis.BackgroundColor3 = Color3.fromRGB(200, 60, 60); setInvisState(false) end
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
    btnSpeed.Size = UDim2.new(0.95, 0, 0, 30); btnSpeed.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
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
            btnSpeed.Text = "SPEED: OFF"; btnSpeed.BackgroundColor3 = Color3.fromRGB(200, 60, 60); if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
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

    -- === GLOBAL AIM TARGET VARIABLE ===
    local aimTargetPart = "Head"

    -- === AIMBOT (AUTO-LOCK/CAMERA-LOCK to Closest Player) ===
    local btnAutoLock = GH.createBtn("AIMBOT: OFF", Color3.fromRGB(200, 60, 60), 5)
    local lock_on = false
    local lockConnection = nil

    -- Function to iterate through all active players to find the closest target to the LocalPlayer
    local function getNearestPlayerTarget()
        local closestTarget = nil
        local shortestDistance = math.huge
        local localChar = GH.player.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        if not localRoot then return nil end

        for _, p in pairs(GH.Players:GetPlayers()) do
            if p ~= GH.player and p.Character then
                -- Try to find the selected part, safely fall back to HumanoidRootPart if missing
                local target = p.Character:FindFirstChild(aimTargetPart) or p.Character:FindFirstChild("HumanoidRootPart")
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")

                -- Ensure the target is alive and has the required parts
                if target and root and hum and hum.Health > 0 then
                    local distance = (localRoot.Position - root.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestTarget = target
                    end
                end
            end
        end
        return closestTarget
    end

    GH.RegisterButton(btnAutoLock, function()
        lock_on = not lock_on
        btnAutoLock.Text = lock_on and "AIMBOT: ON" or "AIMBOT: OFF"
        btnAutoLock.BackgroundColor3 = lock_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if lock_on then
            if not lockConnection then
                lockConnection = GH.RunService.RenderStepped:Connect(function()
                    local aimTarget = getNearestPlayerTarget()
                    local currentCamera = workspace.CurrentCamera
                    
                    if aimTarget and currentCamera then
                        -- Forces the camera to look directly at the target
                        currentCamera.CFrame = CFrame.lookAt(currentCamera.CFrame.Position, aimTarget.Position)
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

    -- === CLICK FLING ===
    local btnClickFling = GH.createBtn("CLICK FLING: OFF", Color3.fromRGB(200, 60, 60), 6)
    local click_fling_on = false

    GH.RegisterButton(btnClickFling, function()
        click_fling_on = not click_fling_on
        btnClickFling.Text = click_fling_on and "CLICK FLING: ON" or "CLICK FLING: OFF"
        btnClickFling.BackgroundColor3 = click_fling_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
    end)

    local Mouse = GH.player:GetMouse()
    Mouse.Button1Down:Connect(function()
        if not click_fling_on then return end
        
        local Target = Mouse.Target
        if Target and Target.Parent and Target.Parent:IsA("Model") and GH.Players:GetPlayerFromCharacter(Target.Parent) then
            local targetUser = GH.Players:GetPlayerFromCharacter(Target.Parent)
            if targetUser == GH.player then return end
            
            local TargetPlayer = targetUser
            local Character = GH.player.Character
            local Humanoid = getPlrHum(Character)
            local RootPart = Humanoid and Humanoid.RootPart
            local TCharacter = TargetPlayer.Character
            local THumanoid = getPlrHum(TCharacter)
            local TRootPart = THumanoid and THumanoid.RootPart
            local THead = getHead(TCharacter)
            local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
            local Handle = Accessory and Accessory:FindFirstChild("Handle")

            if Character and Humanoid and RootPart then
                if not flingManager.cFlingOldPos or RootPart.Velocity.Magnitude < 50 then
                    flingManager.cFlingOldPos = RootPart.CFrame
                end
                if THead then
                    workspace.CurrentCamera.CameraSubject = THead
                elseif Handle then
                    workspace.CurrentCamera.CameraSubject = Handle
                elseif THumanoid and TRootPart then
                    workspace.CurrentCamera.CameraSubject = THumanoid
                end
                
                if not TCharacter or not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

                local function FPos(BasePart, Pos, Ang)
                    RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                    Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                    RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                    RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                end

                local function SFBasePart(BasePart)
                    local TimeToWait = 2
                    local Time = tick()
                    local Angle = 0
                    repeat
                        if RootPart and THumanoid and TCharacter and TCharacter.Parent then
                            if BasePart.Velocity.Magnitude < 50 then
                                Angle = Angle + 100
                                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                            else
                                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) Wait()
                                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) Wait()
                            end
                        else
                            break
                        end
                    until not BasePart or not BasePart.Parent or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= GH.Players or TargetPlayer.Character ~= TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
                end

                local targetPart = TRootPart or THead or Handle

                local OrgDestroyHeight = workspace.FallenPartsDestroyHeight
                workspace.FallenPartsDestroyHeight = 0 / 0
                
                local BV = Instance.new("BodyVelocity")
                BV.Parent = RootPart
                BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
                BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
                
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                
                if TRootPart and THead then
                    if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
                elseif TRootPart and not THead then
                    SFBasePart(TRootPart)
                elseif not TRootPart and THead then
                    SFBasePart(THead)
                elseif not TRootPart and not THead and Accessory and Handle then
                    SFBasePart(Handle)
                end
                
                if BV then BV:Destroy() end
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                workspace.CurrentCamera.CameraSubject = Humanoid
                
                repeat
                    if RootPart and flingManager.cFlingOldPos then
                        RootPart.CFrame = flingManager.cFlingOldPos * CFrame.new(0, 0.5, 0)
                        Character:SetPrimaryPartCFrame(flingManager.cFlingOldPos * CFrame.new(0, 0.5, 0))
                        Humanoid:ChangeState("GettingUp")
                        for _, x in next, Character:GetChildren() do
                            if x:IsA("BasePart") then
                                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                            end
                        end
                    end
                    Wait()
                until not RootPart or (RootPart.Position - flingManager.cFlingOldPos.p).Magnitude < 25
                workspace.FallenPartsDestroyHeight = OrgDestroyHeight
            end
        end
    end)

    -- === WALK FLING ===
    local btnWalkFling = GH.createBtn("WALK FLING: OFF", Color3.fromRGB(200, 60, 60), 7)
    local walk_fling_on = false

    local function startWalkFlingLoop()
        task.spawn(function()
            local movel = 0.1
            while walk_fling_on do
                GH.RunService.Heartbeat:Wait()
                local character = GH.player.Character
                local root = getRoot(character)
                
                if character and character.Parent and root and root.Parent then
                    local vel = root.Velocity
                    root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

                    GH.RunService.RenderStepped:Wait()
                    if character and character.Parent and root and root.Parent then
                        root.Velocity = vel
                    end

                    GH.RunService.Stepped:Wait()
                    if character and character.Parent and root and root.Parent then
                        root.Velocity = vel + Vector3.new(0, movel, 0)
                        movel = movel * -1
                    end
                else
                    GH.RunService.Heartbeat:Wait()
                end
            end
        end)
    end

    GH.RegisterButton(btnWalkFling, function()
        walk_fling_on = not walk_fling_on
        if walk_fling_on then
            btnWalkFling.Text = "WALK FLING: ON"
            btnWalkFling.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            startWalkFlingLoop()
        else
            btnWalkFling.Text = "WALK FLING: OFF"
            btnWalkFling.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        end
    end)

    -- === NPC AIMBOT ===
    -- Auto-locks the camera to the closest non-player Humanoid (NPC)
    local btnNpcAimbot = GH.createBtn("NPC AIMBOT: OFF", Color3.fromRGB(200, 60, 60), 8)
    local npc_lock_on = false
    local npcLockConnection = nil

    -- Function to scan the workspace and find the closest NPC's target part
    local function getNearestNPCTarget()
        local closestTarget = nil
        local shortestDistance = math.huge
        local localChar = GH.player.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        if not localRoot then return nil end

        for _, v in pairs(workspace:GetDescendants()) do
            -- Look for Models that are NOT players
            if v:IsA("Model") and not GH.Players:GetPlayerFromCharacter(v) then
                local target = v:FindFirstChild(aimTargetPart) or v:FindFirstChild("HumanoidRootPart")
                local root = v:FindFirstChild("HumanoidRootPart")
                
                -- Use FindFirstChildOfClass to safely ignore things named "Humanoid" that aren't actually Humanoids
                local hum = v:FindFirstChildOfClass("Humanoid")

                -- Ensure the NPC has a physical root and target part
                if target and root then
                    -- If it has a real Humanoid, make sure it's alive. If it uses a custom health system without a Humanoid, target it anyway.
                    if not hum or (hum and hum.Health > 0) then
                        local distance = (localRoot.Position - root.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestTarget = target
                        end
                    end
                end
            end
        end
        return closestTarget
    end

    GH.RegisterButton(btnNpcAimbot, function()
        npc_lock_on = not npc_lock_on
        btnNpcAimbot.Text = npc_lock_on and "NPC AIMBOT: ON" or "NPC AIMBOT: OFF"
        btnNpcAimbot.BackgroundColor3 = npc_lock_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if npc_lock_on then
            if not npcLockConnection then
                -- Bound to RenderStepped to smoothly lock the camera every frame
                npcLockConnection = GH.RunService.RenderStepped:Connect(function()
                    local aimTarget = getNearestNPCTarget()
                    local currentCamera = workspace.CurrentCamera
                    
                    if aimTarget and currentCamera then
                        currentCamera.CFrame = CFrame.lookAt(currentCamera.CFrame.Position, aimTarget.Position)
                    end
                end)
            end
        else
            if npcLockConnection then
                npcLockConnection:Disconnect()
                npcLockConnection = nil
            end
        end
    end)

    -- === AIM PART TOGGLE ===
    -- Switches the target part for both Player and NPC aimbots
    local btnAimPart = GH.createBtn("AIM PART: HEAD", Color3.fromRGB(80, 100, 140), 9)
    
    GH.RegisterButton(btnAimPart, function()
        if aimTargetPart == "Head" then
            aimTargetPart = "HumanoidRootPart"
            btnAimPart.Text = "AIM PART: TORSO"
            btnAimPart.BackgroundColor3 = Color3.fromRGB(140, 100, 80)
        else
            aimTargetPart = "Head"
            btnAimPart.Text = "AIM PART: HEAD"
            btnAimPart.BackgroundColor3 = Color3.fromRGB(80, 100, 140)
        end
    end)

    -- === PLAYER ESP ===
    -- Draws outlines around players and a dot over their head if they are far away
    local btnEsp = GH.createBtn("PLAYERS: OFF", Color3.fromRGB(200, 60, 60), 10)
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
    local btnScan = GH.createBtn("SCAN BODY", Color3.fromRGB(200, 60, 60), 11)
    GH.RegisterButton(btnScan, function()
        if not GH.player.Character then return end; local cnt = 0
        for _, v in pairs(GH.player.Character:GetDescendants()) do 
            if v:IsA("BasePart") and (v.Name == "HumanoidRootPart" or v.BrickColor == BrickColor.new("Medium stone grey")) and not v:IsA("MeshPart") then v.Transparency = 1; cnt = cnt + 1 end 
        end
        btnScan.Text = "CLEAN: " .. cnt; btnScan.BackgroundColor3 = Color3.fromRGB(0, 180, 100); task.wait(1)
        btnScan.Text = "SCAN BODY"; btnScan.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    end)

    -- === NPC ESP ===
    -- Works identical to Player ESP but scans workspace for non-player Humanoids
    local btnNpc = GH.createBtn("NPC: OFF", Color3.fromRGB(200, 60, 60), 12); local npc_on = false
    GH.RegisterButton(btnNpc, function() npc_on = not npc_on; btnNpc.Text = npc_on and "NPC: ON" or "NPC: OFF"; btnNpc.BackgroundColor3 = npc_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
        for _, v in pairs(workspace:GetDescendants()) do if v:IsA("Model") and (v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart")) and not GH.Players:GetPlayerFromCharacter(v) then local h = v:FindFirstChild("GhostNPC"); if npc_on and not h then local nh = Instance.new("Highlight", v); nh.Name = "GhostNPC"; nh.FillColor = Color3.fromRGB(255, 215, 0); nh.OutlineColor = Color3.fromRGB(255, 215, 0); nh.FillTransparency = 0.5; nh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop elseif not npc_on and h then h:Destroy() end end end 
    end)
    GH.RunService.Stepped:Connect(function() if npc_on then for _, v in pairs(workspace:GetDescendants()) do if v:IsA("Model") and (v:FindFirstChild("Humanoid") or v:FindFirstChild("HumanoidRootPart")) and not GH.Players:GetPlayerFromCharacter(v) and not v:FindFirstChild("GhostNPC") then local nh = Instance.new("Highlight", v); nh.Name = "GhostNPC"; nh.FillColor = Color3.fromRGB(255, 215, 0); nh.OutlineColor = Color3.fromRGB(255, 215, 0); nh.FillTransparency = 0.5; nh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end end end end)

    -- === LIGHT ===
    -- Attaches a bright pointlight to your character for dark areas
    local btnLight = Instance.new("TextButton", scroll)
    btnLight.Name = ""
    btnLight.Size = UDim2.new(0.95, 0, 0, 30)
    btnLight.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    btnLight.Text = "LIGHT: OFF"
    btnLight.TextColor3 = Color3.new(1, 1, 1)
    btnLight.Font = Enum.Font.Arcade
    btnLight.TextSize = 12
    btnLight.LayoutOrder = 13
    btnLight.ClipsDescendants = true
    btnLight.AutoLocalize = false
    btnLight.TextYAlignment = Enum.TextYAlignment.Center

    local lightPadding = Instance.new("UIPadding", btnLight)
    lightPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnLight).CornerRadius = UDim.new(0, 6)

    local arrowLight = Instance.new("TextButton", btnLight)
    arrowLight.Name = "ArrowToggle"
    arrowLight.Size = UDim2.new(0, 30, 0, 30)
    arrowLight.Position = UDim2.new(1, -30, 0, 0)
    arrowLight.BackgroundTransparency = 1
    arrowLight.Text = "V"
    arrowLight.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowLight.Font = Enum.Font.Arcade
    arrowLight.TextSize = 14
    arrowLight.AutoLocalize = false

    local lightSliderC = Instance.new("Frame", btnLight)
    lightSliderC.Name = ""
    lightSliderC.Size = UDim2.new(1, 0, 0, 35)
    lightSliderC.Position = UDim2.new(0, 0, 0, 18)
    lightSliderC.BackgroundTransparency = 1
    lightSliderC.Visible = false
    local lightSliderBg = Instance.new("Frame", lightSliderC)
    lightSliderBg.Size = UDim2.new(0.8, 0, 0, 4)
    lightSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0)
    lightSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    lightSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", lightSliderBg).CornerRadius = UDim.new(1, 0)
    local lightSliderFill = Instance.new("Frame", lightSliderBg)
    lightSliderFill.Size = UDim2.new(60 / 120, 0, 1, 0)
    lightSliderFill.BackgroundColor3 = Color3.new(1, 1, 1)
    lightSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", lightSliderFill).CornerRadius = UDim.new(1, 0)
    local lightSliderTrig = Instance.new("TextButton", lightSliderBg)
    lightSliderTrig.Size = UDim2.new(1, 0, 6, 0)
    lightSliderTrig.Position = UDim2.new(0, 0, -2.5, 0)
    lightSliderTrig.BackgroundTransparency = 1
    lightSliderTrig.Text = ""
    lightSliderTrig.ZIndex = 10
    local lightValText = Instance.new("TextLabel", lightSliderC)
    lightValText.Size = UDim2.new(1, 0, 0, 15)
    lightValText.Position = UDim2.new(0, 0, 0.45, 0)
    lightValText.BackgroundTransparency = 1
    lightValText.Text = "RADIUS: 60"
    lightValText.TextColor3 = Color3.fromRGB(200, 200, 200)
    lightValText.Font = Enum.Font.Arcade
    lightValText.TextSize = 10
    lightValText.AutoLocalize = false

    local light_on, light_expanded, dragLight, lightRadius, maxLightRadius = false, false, false, 60, 120

    arrowLight.MouseButton1Click:Connect(function()
        GH.playSound()
        light_expanded = not light_expanded
        if light_expanded then
            arrowLight.Text = "^"; btnLight.TextYAlignment = Enum.TextYAlignment.Top; lightPadding.PaddingTop = UDim.new(0, 6)
            btnLight:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); lightSliderC.Visible = true
        else
            arrowLight.Text = "V"; btnLight.TextYAlignment = Enum.TextYAlignment.Center; lightPadding.PaddingTop = UDim.new(0, 0)
            btnLight:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); lightSliderC.Visible = false
        end
    end)

    GH.RegisterButton(btnLight, function()
        light_on = not light_on
        local char = GH.player.Character
        if light_on then 
            btnLight.Text = "LIGHT: ON"
            btnLight.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            if char and char:FindFirstChild("HumanoidRootPart") then 
                for _, v in pairs(char.HumanoidRootPart:GetChildren()) do if v.Name == "GhostHubLight" then v:Destroy() end end
                local l = Instance.new("PointLight", char.HumanoidRootPart)
                l.Name = "GhostHubLight"
                l.Range = lightRadius
                l.Brightness = 2
                l.Color = Color3.new(1, 1, 1) 
            end 
        else 
            btnLight.Text = "LIGHT: OFF"
            btnLight.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            if char then for _, v in pairs(char:GetDescendants()) do if v.Name == "GhostHubLight" then v:Destroy() end end end 
        end 
    end)

    local function setLightScale(input)
        local p = math.clamp((input.Position.X - lightSliderBg.AbsolutePosition.X) / lightSliderBg.AbsoluteSize.X, 0, 1)
        lightSliderFill.Size = UDim2.new(p, 0, 1, 0)
        lightRadius = math.floor(p * maxLightRadius)
        lightValText.Text = "RADIUS: " .. lightRadius
        if light_on and GH.player.Character and GH.player.Character:FindFirstChild("HumanoidRootPart") then
            local l = GH.player.Character.HumanoidRootPart:FindFirstChild("GhostHubLight")
            if l then l.Range = lightRadius end
        end
    end

    lightSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragLight = true; setLightScale(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragLight and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setLightScale(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragLight = false end end)

    -- === FPS BOOST ===
    -- Removes shadows, fog, and complex materials to boost frame rate
    local btnFps = GH.createBtn("FPS BOOST: OFF", Color3.fromRGB(200, 60, 60), 14)
    local fps_on, fps_cache, lighting_cache = false, {}, {}
    GH.RegisterButton(btnFps, function() fps_on = not fps_on; btnFps.Text = fps_on and "FPS BOOST: ON" or "FPS BOOST: OFF"; btnFps.BackgroundColor3 = fps_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)
        if fps_on then lighting_cache = {GS = game.Lighting.GlobalShadows, FE = game.Lighting.FogEnd}; game.Lighting.GlobalShadows = false; game.Lighting.FogEnd = 9e9; for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Terrain") then if not fps_cache[v] then fps_cache[v] = {M = v.Material, R = v.Reflectance, C = v.CastShadow} end; v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0; v.CastShadow = false end end
        else game.Lighting.GlobalShadows = true; game.Lighting.FogEnd = lighting_cache.FE or 100000; for part, props in pairs(fps_cache) do if part and part.Parent then part.Material = props.M; part.Reflectance = props.R; part.CastShadow = props.C end end; fps_cache = {} end
    end)

    -- === JUMP (Slider) ===
    -- Forces jumping and overrides anti-jump constraints
    local btnJump = Instance.new("TextButton", scroll)
    btnJump.Name = ""
    btnJump.Size = UDim2.new(0.95, 0, 0, 30)
    btnJump.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    btnJump.Text = "JUMP: OFF"
    btnJump.TextColor3 = Color3.new(1, 1, 1)
    btnJump.Font = Enum.Font.Arcade
    btnJump.TextSize = 12
    btnJump.LayoutOrder = 15
    btnJump.ClipsDescendants = true
    btnJump.AutoLocalize = false
    btnJump.TextYAlignment = Enum.TextYAlignment.Center

    local jumpPadding = Instance.new("UIPadding", btnJump)
    jumpPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnJump).CornerRadius = UDim.new(0, 6)

    local arrowJump = Instance.new("TextButton", btnJump)
    arrowJump.Name = "ArrowToggle"
    arrowJump.Size = UDim2.new(0, 30, 0, 30)
    arrowJump.Position = UDim2.new(1, -30, 0, 0)
    arrowJump.BackgroundTransparency = 1
    arrowJump.Text = "V"
    arrowJump.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowJump.Font = Enum.Font.Arcade
    arrowJump.TextSize = 14
    arrowJump.AutoLocalize = false

    local jumpSliderC = Instance.new("Frame", btnJump)
    jumpSliderC.Name = ""
    jumpSliderC.Size = UDim2.new(1, 0, 0, 35)
    jumpSliderC.Position = UDim2.new(0, 0, 0, 18)
    jumpSliderC.BackgroundTransparency = 1
    jumpSliderC.Visible = false
    local jumpSliderBg = Instance.new("Frame", jumpSliderC)
    jumpSliderBg.Size = UDim2.new(0.8, 0, 0, 4)
    jumpSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0)
    jumpSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    jumpSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", jumpSliderBg).CornerRadius = UDim.new(1, 0)
    local jumpSliderFill = Instance.new("Frame", jumpSliderBg)
    jumpSliderFill.Size = UDim2.new(50 / 300, 0, 1, 0)
    jumpSliderFill.BackgroundColor3 = Color3.new(1, 1, 1)
    jumpSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", jumpSliderFill).CornerRadius = UDim.new(1, 0)
    local jumpSliderTrig = Instance.new("TextButton", jumpSliderBg)
    jumpSliderTrig.Size = UDim2.new(1, 0, 6, 0)
    jumpSliderTrig.Position = UDim2.new(0, 0, -2.5, 0)
    jumpSliderTrig.BackgroundTransparency = 1
    jumpSliderTrig.Text = ""
    jumpSliderTrig.ZIndex = 10
    local jumpValText = Instance.new("TextLabel", jumpSliderC)
    jumpValText.Size = UDim2.new(1, 0, 0, 15)
    jumpValText.Position = UDim2.new(0, 0, 0.45, 0)
    jumpValText.BackgroundTransparency = 1
    jumpValText.Text = "POWER: 50"
    jumpValText.TextColor3 = Color3.fromRGB(200, 200, 200)
    jumpValText.Font = Enum.Font.Arcade
    jumpValText.TextSize = 10
    jumpValText.AutoLocalize = false

    local jump_unlock_on, jump_expanded, dragJump, jumpPowerVal, maxJumpPower = false, false, false, 50, 300
    local jumpLoop = nil

    arrowJump.MouseButton1Click:Connect(function()
        GH.playSound()
        jump_expanded = not jump_expanded
        if jump_expanded then
            arrowJump.Text = "^"; btnJump.TextYAlignment = Enum.TextYAlignment.Top; jumpPadding.PaddingTop = UDim.new(0, 6)
            btnJump:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); jumpSliderC.Visible = true
        else
            arrowJump.Text = "V"; btnJump.TextYAlignment = Enum.TextYAlignment.Center; jumpPadding.PaddingTop = UDim.new(0, 0)
            btnJump:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); jumpSliderC.Visible = false
        end
    end)

    GH.RegisterButton(btnJump, function()
        jump_unlock_on = not jump_unlock_on
        if jump_unlock_on then 
            btnJump.Text = "JUMP: ON"; btnJump.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            if jumpLoop then jumpLoop:Disconnect() end
            jumpLoop = GH.RunService.Stepped:Connect(function() 
                if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then 
                    GH.player.Character.Humanoid.UseJumpPower = true
                    GH.player.Character.Humanoid.JumpPower = jumpPowerVal
                    if GH.player.Character.Humanoid.JumpHeight < (jumpPowerVal / 5) then GH.player.Character.Humanoid.JumpHeight = (jumpPowerVal / 5) end
                    GH.player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) 
                end 
            end)
        else 
            btnJump.Text = "JUMP: OFF"; btnJump.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            if jumpLoop then jumpLoop:Disconnect(); jumpLoop = nil end
            if GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then 
                GH.player.Character.Humanoid.JumpPower = 50
                GH.player.Character.Humanoid.JumpHeight = 7.2
            end 
        end
    end)

    local function setJumpScale(input)
        local p = math.clamp((input.Position.X - jumpSliderBg.AbsolutePosition.X) / jumpSliderBg.AbsoluteSize.X, 0, 1)
        jumpSliderFill.Size = UDim2.new(p, 0, 1, 0)
        jumpPowerVal = math.floor(p * maxJumpPower)
        if jumpPowerVal < 50 then jumpPowerVal = 50 end
        jumpValText.Text = "POWER: " .. jumpPowerVal
        if jump_unlock_on and GH.player.Character and GH.player.Character:FindFirstChild("Humanoid") then
            GH.player.Character.Humanoid.JumpPower = jumpPowerVal
        end
    end

    jumpSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragJump = true; setJumpScale(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragJump and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setJumpScale(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragJump = false end end)

    -- === WAYPOINTS (Dynamic Multiple Load Points) ===
    local btnWaypoints = GH.createBtn("LOAD POINTS", Color3.fromRGB(200, 60, 60), 16)
    btnWaypoints.ClipsDescendants = true
    btnWaypoints.TextYAlignment = Enum.TextYAlignment.Center

    local wayPadding = Instance.new("UIPadding", btnWaypoints)
    wayPadding.PaddingTop = UDim.new(0, 0)

    local arrowWay = Instance.new("TextButton", btnWaypoints)
    arrowWay.Name = "ArrowToggle"
    arrowWay.Size = UDim2.new(0, 30, 0, 30)
    arrowWay.Position = UDim2.new(1, -30, 0, 0)
    arrowWay.BackgroundTransparency = 1
    arrowWay.Text = "V"
    arrowWay.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowWay.Font = Enum.Font.Arcade
    arrowWay.TextSize = 14

    local wayContainer = Instance.new("Frame", btnWaypoints)
    wayContainer.Size = UDim2.new(1, 0, 0, 0)
    wayContainer.Position = UDim2.new(0, 0, 0, 25)
    wayContainer.BackgroundTransparency = 1
    wayContainer.Visible = false

    local wayLayout = Instance.new("UIListLayout", wayContainer)
    wayLayout.Padding = UDim.new(0, 5)
    wayLayout.SortOrder = Enum.SortOrder.LayoutOrder
    wayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local btnAddPoint = Instance.new("TextButton", wayContainer)
    btnAddPoint.Size = UDim2.new(0.85, 0, 0, 25)
    btnAddPoint.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    btnAddPoint.Text = "+ ADD POINT"
    btnAddPoint.TextColor3 = Color3.new(1, 1, 1)
    btnAddPoint.Font = Enum.Font.Arcade
    btnAddPoint.TextSize = 12
    btnAddPoint.LayoutOrder = 9999 -- Keeps it at the bottom
    Instance.new("UICorner", btnAddPoint).CornerRadius = UDim.new(0, 4)

    local way_expanded = false
    local activePointsCount = 0
    local totalPointsCreated = 0

    local function updateWaypointsUI()
        local itemHeight = 30 -- 25 size + 5 padding
        local totalItems = activePointsCount + 1 -- count of active load buttons plus the add button
        local containerHeight = (totalItems * itemHeight) + 5

        if way_expanded then
            arrowWay.Text = "^"
            btnWaypoints.TextYAlignment = Enum.TextYAlignment.Top
            wayPadding.PaddingTop = UDim.new(0, 6)
            wayContainer.Visible = true
            btnWaypoints:TweenSize(UDim2.new(0.95, 0, 0, 30 + containerHeight), "Out", "Quad", 0.3, true)
        else
            arrowWay.Text = "V"
            btnWaypoints.TextYAlignment = Enum.TextYAlignment.Center
            wayPadding.PaddingTop = UDim.new(0, 0)
            wayContainer.Visible = false
            btnWaypoints:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true)
        end
    end

    arrowWay.MouseButton1Click:Connect(function()
        GH.playSound()
        way_expanded = not way_expanded
        updateWaypointsUI()
    end)

    GH.RegisterButton(btnWaypoints, function()
        way_expanded = not way_expanded
        updateWaypointsUI()
    end)

    btnAddPoint.MouseButton1Click:Connect(function()
        GH.playSound()
        local char = GH.player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            activePointsCount = activePointsCount + 1
            totalPointsCreated = totalPointsCreated + 1
            local savedCF = char.HumanoidRootPart.CFrame
            local pointId = totalPointsCreated

            -- The main LOAD button
            local btnLoad = Instance.new("TextButton", wayContainer)
            btnLoad.Size = UDim2.new(0.85, 0, 0, 25)
            btnLoad.BackgroundColor3 = Color3.fromRGB(80, 100, 140)
            btnLoad.Text = "LOAD POINT " .. pointId
            btnLoad.TextColor3 = Color3.new(1, 1, 1)
            btnLoad.Font = Enum.Font.Arcade
            btnLoad.TextSize = 12
            btnLoad.LayoutOrder = pointId
            Instance.new("UICorner", btnLoad).CornerRadius = UDim.new(0, 4)

            -- The DELETE ("X") button attached to it
            local btnDel = Instance.new("TextButton", btnLoad)
            btnDel.Size = UDim2.new(0, 25, 0, 25)
            btnDel.Position = UDim2.new(1, -25, 0, 0)
            btnDel.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            btnDel.Text = "X"
            btnDel.TextColor3 = Color3.new(1, 1, 1)
            btnDel.Font = Enum.Font.Arcade
            btnDel.TextSize = 12
            Instance.new("UICorner", btnDel).CornerRadius = UDim.new(0, 4)

            -- Loading Event
            btnLoad.MouseButton1Click:Connect(function()
                GH.playSound()
                local currentChar = GH.player.Character
                if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                    currentChar.HumanoidRootPart.CFrame = savedCF
                    btnLoad.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                    task.delay(0.2, function()
                        if btnLoad and btnLoad.Parent then
                            btnLoad.BackgroundColor3 = Color3.fromRGB(80, 100, 140)
                        end
                    end)
                end
            end)

            -- Deletion Event
            btnDel.MouseButton1Click:Connect(function()
                GH.playSound()
                btnLoad:Destroy()
                activePointsCount = activePointsCount - 1
                updateWaypointsUI()
            end)

            -- Temporarily pulse the add button to show feedback
            btnAddPoint.Text = "SAVED!"
            task.delay(0.5, function()
                if btnAddPoint and btnAddPoint.Parent then
                    btnAddPoint.Text = "+ ADD POINT"
                end
            end)

            updateWaypointsUI()
        end
    end)

    -- === POCKET INVENTORY ===
    -- Creates a custom UI window to manually manage Backpack tools (useful if the game disables inventory)
    local btnPocket = GH.createBtn("POCKET INV: OFF", Color3.fromRGB(200, 60, 60), 17)
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

    -- === SPAWN PLATFORM ===
    -- Spawns a secure platform under the player's feet
    local btnPlatform = Instance.new("TextButton", scroll)
    btnPlatform.Name = "" -- Obfuscated
    btnPlatform.Size = UDim2.new(0.95, 0, 0, 30)
    btnPlatform.BackgroundColor3 = Color3.fromRGB(80, 100, 140) -- Distinct blue color for utility
    btnPlatform.Text = "PLATFORM" 
    btnPlatform.TextColor3 = Color3.new(1, 1, 1)
    btnPlatform.Font = Enum.Font.Arcade
    btnPlatform.TextSize = 12
    btnPlatform.LayoutOrder = 18 
    btnPlatform.ClipsDescendants = true
    btnPlatform.AutoLocalize = false
    btnPlatform.TextYAlignment = Enum.TextYAlignment.Center

    local platPadding = Instance.new("UIPadding", btnPlatform)
    platPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnPlatform).CornerRadius = UDim.new(0, 6)

    local arrowPlat = Instance.new("TextButton", btnPlatform)
    arrowPlat.Name = "ArrowToggle" 
    arrowPlat.Size = UDim2.new(0, 30, 0, 30)
    arrowPlat.Position = UDim2.new(1, -30, 0, 0)
    arrowPlat.BackgroundTransparency = 1
    arrowPlat.Text = "V"
    arrowPlat.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowPlat.Font = Enum.Font.Arcade
    arrowPlat.TextSize = 14
    arrowPlat.AutoLocalize = false

    local platSliderC = Instance.new("Frame", btnPlatform)
    platSliderC.Name = "" 
    platSliderC.Size = UDim2.new(1, 0, 0, 35)
    platSliderC.Position = UDim2.new(0, 0, 0, 18)
    platSliderC.BackgroundTransparency = 1
    platSliderC.Visible = false

    local platSliderBg = Instance.new("Frame", platSliderC)
    platSliderBg.Size = UDim2.new(0.8, 0, 0, 4)
    platSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0)
    platSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    platSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", platSliderBg).CornerRadius = UDim.new(1, 0)

    local platSliderFill = Instance.new("Frame", platSliderBg)
    platSliderFill.Size = UDim2.new(15 / 1000, 0, 1, 0)
    platSliderFill.BackgroundColor3 = Color3.new(1, 1, 1)
    platSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", platSliderFill).CornerRadius = UDim.new(1, 0)

    local platSliderTrig = Instance.new("TextButton", platSliderBg)
    platSliderTrig.Size = UDim2.new(1, 0, 6, 0)
    platSliderTrig.Position = UDim2.new(0, 0, -2.5, 0)
    platSliderTrig.BackgroundTransparency = 1
    platSliderTrig.Text = ""
    platSliderTrig.ZIndex = 10

    local platValText = Instance.new("TextLabel", platSliderC)
    platValText.Size = UDim2.new(1, 0, 0, 15)
    platValText.Position = UDim2.new(0, 0, 0.45, 0)
    platValText.BackgroundTransparency = 1
    platValText.Text = "SIZE: 15"
    platValText.TextColor3 = Color3.fromRGB(200, 200, 200)
    platValText.Font = Enum.Font.Arcade
    platValText.TextSize = 10
    platValText.AutoLocalize = false

    local plat_expanded, dragPlat, platSize, maxPlatSize = false, false, 15, 1000

    -- Handle dropdown animation
    arrowPlat.MouseButton1Click:Connect(function()
        GH.playSound()
        plat_expanded = not plat_expanded
        if plat_expanded then
            arrowPlat.Text = "^"; btnPlatform.TextYAlignment = Enum.TextYAlignment.Top; platPadding.PaddingTop = UDim.new(0, 6)
            btnPlatform:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); platSliderC.Visible = true
        else
            arrowPlat.Text = "V"; btnPlatform.TextYAlignment = Enum.TextYAlignment.Center; platPadding.PaddingTop = UDim.new(0, 0)
            btnPlatform:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); platSliderC.Visible = false
        end
    end)

    -- Handle the platform spawn execution
    GH.RegisterButton(btnPlatform, function()
        -- Flash green briefly for UI feedback
        btnPlatform.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        task.delay(0.2, function() btnPlatform.BackgroundColor3 = Color3.fromRGB(80, 100, 140) end)

        local char = GH.player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            -- Optional: Delete the previous platform to prevent clutter. 
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name == "GhostHubPlatform" then v:Destroy() end
            end

            local p = Instance.new("Part")
            p.Name = "GhostHubPlatform"
            p.Size = Vector3.new(platSize, 1, platSize)
            p.Anchored = true
            p.CanCollide = true
            p.Transparency = 0.3
            p.BrickColor = BrickColor.new("Lily white")
            p.Material = Enum.Material.Neon
            
            -- HRP is ~3 studs above ground. Offset 3.5 down so the player stands flush on it.
            p.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, -3.5, 0)
            p.Parent = workspace
        end
    end)

    -- Handle slider physics
    local function setPlatScale(input)
        local p = math.clamp((input.Position.X - platSliderBg.AbsolutePosition.X) / platSliderBg.AbsoluteSize.X, 0, 1)
        platSliderFill.Size = UDim2.new(p, 0, 1, 0)
        platSize = math.floor(p * maxPlatSize)
        if platSize < 4 then platSize = 4 end -- Minimum size so you don't slip off
        platValText.Text = "SIZE: " .. platSize
    end

    platSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragPlat = true; setPlatScale(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragPlat and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setPlatScale(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragPlat = false end end)

    -- === HOVER HIGHLIGHT ===
    -- Highlights objects your mouse hovers over. Bypasses CanQuery=false and invisible walls.
    local btnHoverHighlight = GH.createBtn("HOVER HIGHLIGHT: OFF", Color3.fromRGB(200, 60, 60), 19) 
    local hover_high_on = false
    local hoverLoop = nil
    local hoverClickConn = nil
    local partAddedConn = nil
    local currentHoverPart = nil
    local canQueryCache = {} -- Stores parts we modified so we can safely revert them later

    -- Create the temporary highlight for the hover effect
    local tempHighlight = Instance.new("Highlight")
    tempHighlight.Name = "GhostTempHighlight"
    tempHighlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan for hover
    tempHighlight.OutlineColor = Color3.new(1, 1, 1)
    tempHighlight.FillTransparency = 0.5

    -- Helper function to force parts to be raycast-able
    local function forceQueryable(part)
        if part:IsA("BasePart") and part.CanQuery == false then
            canQueryCache[part] = true
            part.CanQuery = true
        end
    end

    -- Custom Raycast function to bypass the Transparency=1 limitation
    local function getHoverTarget()
        local mouse = GH.player:GetMouse()
        local ray = mouse.UnitRay
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {GH.player.Character}
        
        local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
        return result and result.Instance or nil
    end

    GH.RegisterButton(btnHoverHighlight, function()
        hover_high_on = not hover_high_on
        if hover_high_on then
            btnHoverHighlight.Text = "HOVER HIGHLIGHT: ON"
            btnHoverHighlight.BackgroundColor3 = Color3.fromRGB(0, 180, 100)

            -- 1. Scan existing parts and force them to be queryable
            for _, v in pairs(workspace:GetDescendants()) do
                forceQueryable(v)
            end

            -- 2. Listen for any new parts spawning in and force them too
            partAddedConn = workspace.DescendantAdded:Connect(forceQueryable)

            -- Loop to handle the hover effect
            hoverLoop = GH.RunService.RenderStepped:Connect(function()
                local target = getHoverTarget()
                if target and target:IsA("BasePart") then
                    if target ~= currentHoverPart then
                        currentHoverPart = target
                        tempHighlight.Parent = currentHoverPart
                    end
                else
                    currentHoverPart = nil
                    tempHighlight.Parent = nil
                end
            end)

            -- Click listener to lock the highlight
            hoverClickConn = GH.UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local target = getHoverTarget()
                    if target and target:IsA("BasePart") then
                        local existing = target:FindFirstChild("GhostPermHighlight")
                        if existing then
                            existing:Destroy()
                        else
                            local perm = Instance.new("Highlight")
                            perm.Name = "GhostPermHighlight"
                            perm.FillColor = Color3.fromRGB(0, 255, 0) -- Green for locked
                            perm.OutlineColor = Color3.new(1, 1, 1)
                            perm.FillTransparency = 0.5
                            perm.Parent = target
                        end
                    end
                end
            end)
        else
            btnHoverHighlight.Text = "HOVER HIGHLIGHT: OFF"
            btnHoverHighlight.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            
            -- Clean up connections
            if hoverLoop then hoverLoop:Disconnect(); hoverLoop = nil end
            if hoverClickConn then hoverClickConn:Disconnect(); hoverClickConn = nil end
            if partAddedConn then partAddedConn:Disconnect(); partAddedConn = nil end
            
            tempHighlight.Parent = nil
            currentHoverPart = nil
            
            -- Revert all the parts we modified back to their original state
            for part, _ in pairs(canQueryCache) do
                if part and part.Parent then
                    part.CanQuery = false
                end
            end
            table.clear(canQueryCache)
        end
    end)
        
    -- === CLEAR HIGHLIGHTS ===
    -- Wipes all locked highlights from the map
    local btnClearHighlights = GH.createBtn("CLEAR HIGHLIGHTS", Color3.fromRGB(200, 60, 60), 20)
    GH.RegisterButton(btnClearHighlights, function()
        btnClearHighlights.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        local count = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Highlight") and v.Name == "GhostPermHighlight" then
                v:Destroy()
                count = count + 1
            end
        end
        btnClearHighlights.Text = "CLEARED: " .. count
        task.wait(1)
        btnClearHighlights.Text = "CLEAR HIGHLIGHTS"
        btnClearHighlights.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    end)
    
    -- === FREE MOUSE ===
    -- Unlocks the mouse and makes it visible, useful for games that lock the cursor to the center
    local btnFreeMouse = GH.createBtn("FREE MOUSE: OFF", Color3.fromRGB(200, 60, 60), 21)
    local mouse_freed = false
    local mouseLoop = nil

    GH.RegisterButton(btnFreeMouse, function()
        mouse_freed = not mouse_freed
        if mouse_freed then
            btnFreeMouse.Text = "FREE MOUSE: ON"
            btnFreeMouse.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            
            -- Use RenderStepped to constantly fight any game scripts trying to lock it back
            if not mouseLoop then
                mouseLoop = GH.RunService.RenderStepped:Connect(function()
                    GH.UserInputService.MouseIconEnabled = true
                    GH.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
            end
        else
            btnFreeMouse.Text = "FREE MOUSE: OFF"
            btnFreeMouse.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            
            if mouseLoop then
                mouseLoop:Disconnect()
                mouseLoop = nil
            end
        end
    end)

    -- === LOOP TARGET FLING ===
    local btnLoopFling = GH.createBtn("LOOP FLING: OFF", Color3.fromRGB(200, 60, 60), 22)
    
    local boxLoopTarget = Instance.new("TextBox", scroll)
    boxLoopTarget.Size = UDim2.new(0.95, 0, 0, 30)
    boxLoopTarget.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    boxLoopTarget.TextColor3 = Color3.new(1, 1, 1)
    boxLoopTarget.PlaceholderText = "Target Username..."
    boxLoopTarget.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    boxLoopTarget.Font = Enum.Font.Arcade
    boxLoopTarget.TextSize = 12
    boxLoopTarget.LayoutOrder = 23
    boxLoopTarget.ClearTextOnFocus = false
    Instance.new("UICorner", boxLoopTarget).CornerRadius = UDim.new(0, 6)

    local loop_target_on = false
    local LOOPPROTECT = nil

    local function startLoopTargetAction()
        task.spawn(function()
            while loop_target_on do
                local targetName = boxLoopTarget.Text
                if targetName == "" then 
                    Wait(0.1)
                    continue 
                end

                local AllBool = false
                local GetPlayer = function(Name)
                    Name = string.lower(Name)
                    if Name == "all" or Name == "others" then
                        AllBool = true
                        return
                    elseif Name == "random" then
                        local GetPlayers = GH.Players:GetPlayers()
                        if table.find(GetPlayers, GH.player) then table.remove(GetPlayers, table.find(GetPlayers, GH.player)) end
                        return GetPlayers[math.random(#GetPlayers)]
                    else
                        for _, x in next, GH.Players:GetPlayers() do
                            if x ~= GH.player then
                                if x.Name:lower():match("^"..Name) then
                                    return x
                                elseif x.DisplayName:lower():match("^"..Name) then
                                    return x
                                end
                            end
                        end
                    end
                end

                local FlingDeluxePro = function(TargetPlayer)
                    if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end
                    local Character = GH.player.Character
                    local Humanoid = getPlrHum(Character)
                    local HRP = Humanoid and Humanoid.RootPart
                    local camera = workspace.CurrentCamera
                    
                    LOOPPROTECT = Instance.new("Part")
                    LOOPPROTECT.Size = Vector3.new(1, 1, 1)
                    LOOPPROTECT.Transparency = 1
                    LOOPPROTECT.CanCollide = false
                    LOOPPROTECT.Anchored = false
                    LOOPPROTECT.Parent = camera
                    
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = HRP
                    weld.Part1 = LOOPPROTECT
                    weld.Parent = LOOPPROTECT
                    
                    local bodyGyro = Instance.new("BodyGyro")
                    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                    bodyGyro.D = 1000
                    bodyGyro.P = 2000
                    bodyGyro.Parent = LOOPPROTECT
                    
                    local RootPart = HRP
                    local TCharacter = TargetPlayer.Character
                    local THumanoid, TRootPart, THead, Accessory, Handle
                    
                    if not TCharacter then if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end return end
                    if getPlrHum(TCharacter) then THumanoid = getPlrHum(TCharacter) end
                    if THumanoid and THumanoid.RootPart then TRootPart = THumanoid.RootPart end
                    if getHead(TCharacter) then THead = getHead(TCharacter) end
                    if TCharacter:FindFirstChildOfClass("Accessory") then Accessory = TCharacter:FindFirstChildOfClass("Accessory") end
                    if Accessory and Accessory:FindFirstChild("Handle") then Handle = Accessory.Handle end
                    
                    if Character and Humanoid and HRP then
                        if not flingManager.lFlingOldPos or RootPart.Velocity.Magnitude < 50 then
                            flingManager.lFlingOldPos = RootPart.CFrame
                        end
                        if THumanoid and THumanoid.Sit and not AllBool then return end
                        
                        if THead then
                            workspace.CurrentCamera.CameraSubject = THead
                        elseif not THead and Handle then
                            workspace.CurrentCamera.CameraSubject = Handle
                        elseif THumanoid and TRootPart then
                            workspace.CurrentCamera.CameraSubject = THumanoid
                        end
                        
                        if not TCharacter or not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
                        
                        local FPos = function(BasePart, Pos, Ang)
                            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                        end
                        
                        local SFBasePart = function(BasePart)
                            local TimeToWait = 2
                            local Time = tick()
                            local Angle = 0
                            repeat
                                if RootPart and THumanoid and TCharacter and TCharacter.Parent then
                                    if BasePart.Velocity.Magnitude < 50 then
                                        Angle = Angle + 100
                                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) Wait()
                                    else
                                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) Wait()
                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) Wait()
                                    end
                                else
                                    break
                                end
                            until not BasePart or not BasePart.Parent or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= GH.Players or TargetPlayer.Character ~= TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
                            if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end
                        end
                        
                        local OrgDestroyHeight = workspace.FallenPartsDestroyHeight
                        workspace.FallenPartsDestroyHeight = 0/0
                        
                        local BV = Instance.new("BodyVelocity")
                        BV.Parent = RootPart
                        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
                        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
                        
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                        
                        if TRootPart and THead then
                            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
                        elseif TRootPart and not THead then
                            SFBasePart(TRootPart)
                        elseif not TRootPart and THead then
                            SFBasePart(THead)
                        elseif not TRootPart and not THead and Accessory and Handle then
                            SFBasePart(Handle)
                        end
                        
                        if BV then BV:Destroy() end
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                        workspace.CurrentCamera.CameraSubject = Humanoid
                        
                        repeat
                            if RootPart and flingManager.lFlingOldPos then
                                RootPart.CFrame = flingManager.lFlingOldPos * CFrame.new(0, 0.5, 0)
                                Character:SetPrimaryPartCFrame(flingManager.lFlingOldPos * CFrame.new(0, 0.5, 0))
                                Humanoid:ChangeState("GettingUp")
                                for _, x in next, Character:GetChildren() do
                                    if x:IsA("BasePart") then
                                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                                    end
                                end
                            end
                            Wait()
                        until not RootPart or (RootPart.Position - flingManager.lFlingOldPos.p).Magnitude < 25
                        workspace.FallenPartsDestroyHeight = OrgDestroyHeight
                        if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end
                    end
                end

                if AllBool then
                    for _, x in next, GH.Players:GetPlayers() do
                        if not loop_target_on then break end
                        FlingDeluxePro(x)
                    end
                else
                    local TP = GetPlayer(targetName)
                    if TP and TP ~= GH.player and TP.UserId ~= 1414978355 then
                        FlingDeluxePro(TP)
                    end
                end
                Wait(0.5)
            end
        end)
    end

    GH.RegisterButton(btnLoopFling, function()
        loop_target_on = not loop_target_on
        if loop_target_on then
            btnLoopFling.Text = "LOOP FLING: ON"
            btnLoopFling.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            startLoopTargetAction()
        else
            btnLoopFling.Text = "LOOP FLING: OFF"
            btnLoopFling.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end
        end
    end)
    
    -- === ROBLOX INV ===
    -- Turns the core Roblox inventory GUI bar on/off
    local btnRobloxInv = GH.createBtn("ROBLOX INV: ON", Color3.fromRGB(0, 180, 100), 24)
    GH.RegisterButton(btnRobloxInv, function()
        if btnRobloxInv.Text == "ROBLOX INV: OFF" then pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end); btnRobloxInv.Text = "ROBLOX INV: ON"; btnRobloxInv.BackgroundColor3 = Color3.fromRGB(0, 180, 100)        
        else pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end); btnRobloxInv.Text = "ROBLOX INV: OFF"; btnRobloxInv.BackgroundColor3 = Color3.fromRGB(200, 60, 60) end    
    end)

    -- === AUTO-HOVER (PLAYER & NPC) ===
    local btnPlayerHover = Instance.new("TextButton", scroll)
    btnPlayerHover.Name = ""
    btnPlayerHover.Size = UDim2.new(0.95, 0, 0, 30)
    btnPlayerHover.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    btnPlayerHover.Text = "PLAYER HOVER: OFF"
    btnPlayerHover.TextColor3 = Color3.new(1, 1, 1)
    btnPlayerHover.Font = Enum.Font.Arcade
    btnPlayerHover.TextSize = 12
    btnPlayerHover.LayoutOrder = 25
    btnPlayerHover.ClipsDescendants = true
    btnPlayerHover.AutoLocalize = false
    btnPlayerHover.TextYAlignment = Enum.TextYAlignment.Center

    local hoverPadding = Instance.new("UIPadding", btnPlayerHover)
    hoverPadding.PaddingTop = UDim.new(0, 0)
    Instance.new("UICorner", btnPlayerHover).CornerRadius = UDim.new(0, 6)

    local arrowHover = Instance.new("TextButton", btnPlayerHover)
    arrowHover.Name = "ArrowToggle"
    arrowHover.Size = UDim2.new(0, 30, 0, 30)
    arrowHover.Position = UDim2.new(1, -30, 0, 0)
    arrowHover.BackgroundTransparency = 1
    arrowHover.Text = "V"
    arrowHover.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowHover.Font = Enum.Font.Arcade
    arrowHover.TextSize = 14
    arrowHover.AutoLocalize = false

    local hoverSliderC = Instance.new("Frame", btnPlayerHover)
    hoverSliderC.Name = ""
    hoverSliderC.Size = UDim2.new(1, 0, 0, 35)
    hoverSliderC.Position = UDim2.new(0, 0, 0, 18)
    hoverSliderC.BackgroundTransparency = 1
    hoverSliderC.Visible = false
    local hoverSliderBg = Instance.new("Frame", hoverSliderC)
    hoverSliderBg.Size = UDim2.new(0.8, 0, 0, 4)
    hoverSliderBg.Position = UDim2.new(0.1, 0, 0.2, 0)
    hoverSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hoverSliderBg.BorderSizePixel = 0
    Instance.new("UICorner", hoverSliderBg).CornerRadius = UDim.new(1, 0)
    local hoverSliderFill = Instance.new("Frame", hoverSliderBg)
    hoverSliderFill.Size = UDim2.new(0.5, 0, 1, 0)
    hoverSliderFill.BackgroundColor3 = Color3.new(1, 1, 1)
    hoverSliderFill.BorderSizePixel = 0
    Instance.new("UICorner", hoverSliderFill).CornerRadius = UDim.new(1, 0)
    local hoverSliderTrig = Instance.new("TextButton", hoverSliderBg)
    hoverSliderTrig.Size = UDim2.new(1, 0, 6, 0)
    hoverSliderTrig.Position = UDim2.new(0, 0, -2.5, 0)
    hoverSliderTrig.BackgroundTransparency = 1
    hoverSliderTrig.Text = ""
    hoverSliderTrig.ZIndex = 10
    local hoverValText = Instance.new("TextLabel", hoverSliderC)
    hoverValText.Size = UDim2.new(1, 0, 0, 15)
    hoverValText.Position = UDim2.new(0, 0, 0.45, 0)
    hoverValText.BackgroundTransparency = 1
    hoverValText.Text = "Y-OFFSET: 0"
    hoverValText.TextColor3 = Color3.fromRGB(200, 200, 200)
    hoverValText.Font = Enum.Font.Arcade
    hoverValText.TextSize = 10
    hoverValText.AutoLocalize = false

    local btnNpcHover = GH.createBtn("NPC HOVER: OFF", Color3.fromRGB(200, 60, 60), 26)
    
    local player_hover_on, npc_hover_on = false, false
    local playerHoverConn, npcHoverConn = nil, nil
    local hover_expanded, dragHover, hoverOffset, maxHoverOffset = false, false, 0, 50

    arrowHover.MouseButton1Click:Connect(function()
        GH.playSound(); hover_expanded = not hover_expanded
        if hover_expanded then
            arrowHover.Text = "^"; btnPlayerHover.TextYAlignment = Enum.TextYAlignment.Top; hoverPadding.PaddingTop = UDim.new(0, 6)
            btnPlayerHover:TweenSize(UDim2.new(0.95, 0, 0, 60), "Out", "Quad", 0.3, true); hoverSliderC.Visible = true
        else
            arrowHover.Text = "V"; btnPlayerHover.TextYAlignment = Enum.TextYAlignment.Center; hoverPadding.PaddingTop = UDim.new(0, 0)
            btnPlayerHover:TweenSize(UDim2.new(0.95, 0, 0, 30), "Out", "Quad", 0.3, true); hoverSliderC.Visible = false
        end
    end)

    local function setHoverScale(input)
        local p = math.clamp((input.Position.X - hoverSliderBg.AbsolutePosition.X) / hoverSliderBg.AbsoluteSize.X, 0, 1)
        hoverSliderFill.Size = UDim2.new(p, 0, 1, 0)
        hoverOffset = math.floor((p * (maxHoverOffset * 2)) - maxHoverOffset)
        hoverValText.Text = "Y-OFFSET: " .. hoverOffset
    end

    hoverSliderTrig.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragHover = true; setHoverScale(i) end end)
    GH.UserInputService.InputChanged:Connect(function(i) if dragHover and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then setHoverScale(i) end end)
    GH.UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragHover = false end end)

    -- Player Hover Logic
    GH.RegisterButton(btnPlayerHover, function()
        player_hover_on = not player_hover_on
        btnPlayerHover.Text = player_hover_on and "PLAYER HOVER: ON" or "PLAYER HOVER: OFF"
        btnPlayerHover.BackgroundColor3 = player_hover_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if player_hover_on then
            if npc_hover_on then
                npc_hover_on = false
                btnNpcHover.Text = "NPC HOVER: OFF"
                btnNpcHover.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if npcHoverConn then npcHoverConn:Disconnect(); npcHoverConn = nil end
            end

            if not playerHoverConn then
                playerHoverConn = GH.RunService.Heartbeat:Connect(function()
                    local targetPart = getNearestPlayerTarget()
                    local char = GH.player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart and hrp then
                        local hoverPos = targetPart.Position + Vector3.new(0, hoverOffset, 0)
                        local _, ry, _ = hrp.CFrame:ToOrientation()
                        -- Center exactly on the target Part + Slider Offset. Force character to look down (pitch=-90) and maintain yaw (ry).
                        hrp.CFrame = CFrame.new(hoverPos) * CFrame.fromOrientation(math.rad(-90), ry, 0)
                        hrp.Velocity = Vector3.zero 
                        hrp.RotVelocity = Vector3.zero
                    end
                end)
            end
        else
            if playerHoverConn then
                playerHoverConn:Disconnect()
                playerHoverConn = nil
            end
        end
    end)

    -- NPC Hover Logic
    GH.RegisterButton(btnNpcHover, function()
        npc_hover_on = not npc_hover_on
        btnNpcHover.Text = npc_hover_on and "NPC HOVER: ON" or "NPC HOVER: OFF"
        btnNpcHover.BackgroundColor3 = npc_hover_on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(200, 60, 60)

        if npc_hover_on then
            if player_hover_on then
                player_hover_on = false
                btnPlayerHover.Text = "PLAYER HOVER: OFF"
                btnPlayerHover.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if playerHoverConn then playerHoverConn:Disconnect(); playerHoverConn = nil end
            end

            if not npcHoverConn then
                npcHoverConn = GH.RunService.Heartbeat:Connect(function()
                    local targetPart = getNearestNPCTarget()
                    local char = GH.player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart and hrp then
                        local hoverPos = targetPart.Position + Vector3.new(0, hoverOffset, 0)
                        local _, ry, _ = hrp.CFrame:ToOrientation()
                        hrp.CFrame = CFrame.new(hoverPos) * CFrame.fromOrientation(math.rad(-90), ry, 0)
                        hrp.Velocity = Vector3.zero 
                        hrp.RotVelocity = Vector3.zero
                    end
                end)
            end
        else
            if npcHoverConn then
                npcHoverConn:Disconnect()
                npcHoverConn = nil
            end
        end
    end)

    -- === AUTO M1 / ANTI-AFK ===
    GH.btnAntiAfk = GH.createBtn("AUTO M1: OFF", Color3.fromRGB(200, 60, 60), 27)
    GH.anti_afk_on = false
    GH.antiAfkLoop = nil
    GH.afkConnection = nil
    GH.VirtualUser = game:GetService("VirtualUser")

    GH.RegisterButton(GH.btnAntiAfk, function()
        GH.anti_afk_on = not GH.anti_afk_on
        if GH.anti_afk_on then
            GH.btnAntiAfk.Text = "AUTO M1: ON"
            GH.btnAntiAfk.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            
            if not GH.afkConnection then
                GH.afkConnection = GH.player.Idled:Connect(function()
                    GH.VirtualUser:CaptureController()
                    GH.VirtualUser:ClickButton2(Vector2.new(0, 0)) 
                end)
            end

            GH.antiAfkLoop = task.spawn(function()
                while GH.anti_afk_on do
                    GH.VirtualUser:CaptureController()
                    GH.VirtualUser:ClickButton1(Vector2.new(0, 0))
                    task.wait(0.1) -- Adjust this number to change how fast it clicks
                end
            end)
        else
            GH.btnAntiAfk.Text = "AUTO M1: OFF"
            GH.btnAntiAfk.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            
            if GH.antiAfkLoop then
                task.cancel(GH.antiAfkLoop)
                GH.antiAfkLoop = nil
            end
            if GH.afkConnection then
                GH.afkConnection:Disconnect()
                GH.afkConnection = nil
            end
        end
    end)
    
    -- ==========================================
    -- RESET & DEATH HANDLING
    -- ==========================================

    if hover_high_on then
        hover_high_on = false
        pcall(function()
            btnHoverHighlight.Text = "HOVER HIGHLIGHT: OFF"
            btnHoverHighlight.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            if hoverLoop then hoverLoop:Disconnect(); hoverLoop = nil end
            if hoverClickConn then hoverClickConn:Disconnect(); hoverClickConn = nil end
            if partAddedConn then partAddedConn:Disconnect(); partAddedConn = nil end
            tempHighlight.Parent = nil
            currentHoverPart = nil
            
            -- Revert cache on death
            for part, _ in pairs(canQueryCache) do
                if part and part.Parent then part.CanQuery = false end
            end
            table.clear(canQueryCache)
        end)
    end
    
    -- Safely disables active cheat loops when the player dies to prevent the game crashing
    local function resetToggles()
        if player_hover_on then
            player_hover_on = false
            pcall(function()
                btnPlayerHover.Text = "PLAYER HOVER: OFF"
                btnPlayerHover.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if playerHoverConn then playerHoverConn:Disconnect(); playerHoverConn = nil end
            end)
        end
        if npc_hover_on then
            npc_hover_on = false
            pcall(function()
                btnNpcHover.Text = "NPC HOVER: OFF"
                btnNpcHover.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if npcHoverConn then npcHoverConn:Disconnect(); npcHoverConn = nil end
            end)
        end
        if light_on then
            light_on = false
            pcall(function()
                btnLight.Text = "LIGHT: OFF"
                btnLight.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            end)
        end
        if jump_unlock_on then
            jump_unlock_on = false
            pcall(function()
                btnJump.Text = "JUMP: OFF"
                btnJump.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if jumpLoop then jumpLoop:Disconnect(); jumpLoop = nil end
            end)
        end
        if invis_on then
            invis_on = false
            pcall(function() 
                btnInvis.Text = "INVIS: OFF"; btnInvis.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                for _, o in pairs(workspace:GetChildren()) do if o.Name == 'invischair' then pcall(function() o:Destroy() end) end end
            end)
        end
        if isSpeedBoosted then
            isSpeedBoosted = false
            pcall(function() btnSpeed.Text = "SPEED: OFF"; btnSpeed.BackgroundColor3 = Color3.fromRGB(200, 60, 60); if speedLoop then speedLoop:Disconnect(); speedLoop = nil end end)
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
        if npc_lock_on then
            npc_lock_on = false
            pcall(function()
                btnNpcAimbot.Text = "NPC AIMBOT: OFF"
                btnNpcAimbot.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if npcLockConnection then 
                    npcLockConnection:Disconnect() 
                    npcLockConnection = nil 
                end
            end)
        end
        if mouse_freed then
            mouse_freed = false
            pcall(function()
                btnFreeMouse.Text = "FREE MOUSE: OFF"
                btnFreeMouse.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if mouseLoop then
                    mouseLoop:Disconnect()
                    mouseLoop = nil
                end
            end)
        end
        if click_fling_on then
            click_fling_on = false
            pcall(function()
                btnClickFling.Text = "CLICK FLING: OFF"
                btnClickFling.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            end)
        end
        if walk_fling_on then
            walk_fling_on = false
            pcall(function()
                btnWalkFling.Text = "WALK FLING: OFF"
                btnWalkFling.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            end)
        end
        if loop_target_on then
            loop_target_on = false
            pcall(function()
                btnLoopFling.Text = "LOOP FLING: OFF"
                btnLoopFling.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                if LOOPPROTECT then LOOPPROTECT:Destroy() LOOPPROTECT = nil end
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
        [Enum.KeyCode.B] = btnAutoLock,
        [Enum.KeyCode.F] = btnClickFling,
        [Enum.KeyCode.G] = btnWalkFling
    }

    for key, button in pairs(defaultBinds) do
        GH.Keybinds[key] = {func = GH.ButtonLogics[button], btn = button}
        button.Text = button.Text .. " [" .. key.Name .. "]"
    end

    print("REAL MENU LOADED")
end)

-- Error message if the script fails to execute
if not success then warn("ERROR: " .. tostring(err)) end
