local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local player            = Players.LocalPlayer

if CoreGui:FindFirstChild("RFGui") then CoreGui.RFGui:Destroy() end

-- ─── Colors ──────────────────────────────────────────────────────────────────

local C = {
    bg      = Color3.fromRGB(14, 16, 22),
    surface = Color3.fromRGB(20, 23, 33),
    raised  = Color3.fromRGB(26, 30, 44),
    border  = Color3.fromRGB(38, 44, 66),
    accent  = Color3.fromRGB(70, 140, 255),
    white   = Color3.fromRGB(235, 238, 255),
    sub     = Color3.fromRGB(130, 145, 185),
    muted   = Color3.fromRGB(65,  75,  110),
    green   = Color3.fromRGB(55,  200, 110),
    red     = Color3.fromRGB(210, 65,  65),
}

-- ─── Rarity Data ─────────────────────────────────────────────────────────────

local RARITY_ORDER = {"Transcended","Exotic","Divine","Prismatic","Secret","Legendary","Epic","Rare","Uncommon","Common"}
local RARITY_COLOR = {
    Common="c8c8c8", Uncommon="50c850", Rare="508cff", Epic="a050ff",
    Legendary="ffa500", Secret="dc3c3c", Prismatic="00d0d0",
    Divine="ffd200", Exotic="ff5ac8", Transcended="be00dc",
}
local function rc(h)
    return Color3.fromRGB(tonumber("0x"..h:sub(1,2)),tonumber("0x"..h:sub(3,4)),tonumber("0x"..h:sub(5,6)))
end
for k,v in pairs(RARITY_COLOR) do RARITY_COLOR[k]=rc(v) end

local function fmt(n)
    if not n or n == 0 or n == math.huge then return "?" end
    local s = {"","K","M","B","T","Q"}
    local i = 1
    while n >= 1000 and i < #s do n=n/1000; i=i+1 end
    return "$".. (n>=100 and string.format("%.0f",n) or n>=10 and string.format("%.1f",n) or string.format("%.2f",n)) .. s[i]
end

-- ─── String Currency Parser ──────────────────────────────────────────────────

local function parseMoneyString(str)
    if type(str) ~= "string" and type(str) ~= "number" then return math.huge end
    local text = tostring(str):lower():gsub(",", "")
    local numStr, suffix = text:match("(%d+%.?%d*)([a-z]*)")
    if not numStr then return math.huge end
    
    local n = tonumber(numStr)
    if not n then return math.huge end
    
    local mults = {k=1e3, m=1e6, b=1e9, t=1e12, q=1e15, qd=1e18, qn=1e21}
    return n * (mults[suffix] or 1)
end

-- ─── Dynamic Cost Finders ────────────────────────────────────────────────────

local function getPlayerCash()
    local leaderstats = player:FindFirstChild("leaderstats")
    local cashObj = leaderstats and leaderstats:FindFirstChild("Cash")
    if not cashObj then return 0 end
    local val = cashObj.Value
    if type(val) == "number" then return val end
    return parseMoneyString(val)
end

local function getGearCost(gearName)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return math.huge end
    
    local frame = pg:FindFirstChild("MainUI")
        and pg.MainUI:FindFirstChild("Menus")
        and pg.MainUI.Menus:FindFirstChild("GearShopFrame")
        and pg.MainUI.Menus.GearShopFrame:FindFirstChild("ScrollingFrame")
        
    if frame and frame:FindFirstChild(gearName) then
        local costLbl = frame[gearName]:FindFirstChild("Cost")
        if costLbl and costLbl.Text ~= "" then return parseMoneyString(costLbl.Text) end
    end
    return math.huge
end

local function scrapeSeedCostFromWorkspace(seedName)
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == seedName then
            local costLbl = obj:FindFirstChild("Cost", true)
            if costLbl and costLbl:IsA("TextLabel") and costLbl.Text ~= "" and not costLbl.Text:find("Label") then
                local cost = parseMoneyString(costLbl.Text)
                if cost ~= math.huge then return cost end
            end
        end
    end
    return math.huge
end

-- ─── Configuration & Settings Persistence ────────────────────────────────────

local FILE_NAME = "buildaring_settings.json"

local DEFAULT_SEEDS = {
    -- Common
    {name="Beetroot", rarity="Common"}, {name="Carrot", rarity="Common"}, {name="Pumpkin", rarity="Common"},
    -- Uncommon
    {name="Cantaloupe", rarity="Uncommon"}, {name="Melon", rarity="Uncommon"}, {name="Onion", rarity="Uncommon"}, {name="Watermelon", rarity="Uncommon"}, {name="Wheat", rarity="Uncommon"},
    -- Rare
    {name="Bamboo", rarity="Rare"}, {name="Blueberry", rarity="Rare"}, {name="Cabbage", rarity="Rare"}, {name="Grape", rarity="Rare"}, {name="Peach", rarity="Rare"},
    -- Epic
    {name="Cauliflower", rarity="Epic"}, {name="Citrus", rarity="Epic"}, {name="Corn", rarity="Epic"}, {name="Honeysuckle", rarity="Epic"}, {name="Martian Melon", rarity="Epic"}, {name="Nectarine", rarity="Epic"}, {name="Plum", rarity="Epic"}, {name="Sunflower", rarity="Epic"}, {name="Twinflame Tulip", rarity="Epic"},
    -- Legendary
    {name="Amulet Anemone", rarity="Legendary"}, {name="Banana", rarity="Legendary"}, {name="Mango", rarity="Legendary"}, {name="Mushroom", rarity="Legendary"}, {name="Potato", rarity="Legendary"}, {name="Spring Onion", rarity="Legendary"},
    -- Secret
    {name="Admin Crownflower", rarity="Secret"}, {name="Beanstalk", rarity="Secret"}, {name="Glasswing", rarity="Secret"}, {name="Monsoon Crown", rarity="Secret"}, {name="Starfruit", rarity="Secret"}, {name="Strawberry", rarity="Secret"}, {name="Tomato", rarity="Secret"},
    -- Prismatic
    {name="Apple", rarity="Prismatic"}, {name="Blood Orange", rarity="Prismatic"}, {name="Cherry Blossom", rarity="Prismatic"}, {name="Cinnamon", rarity="Prismatic"}, {name="Duoheart Daisy", rarity="Prismatic"}, {name="Galaxy Hibiscus", rarity="Prismatic"}, {name="Garlic", rarity="Prismatic"}, {name="Hex Sprout", rarity="Prismatic"}, {name="Iron Fern", rarity="Prismatic"}, {name="Pineapple", rarity="Prismatic"}, {name="Rush Root", rarity="Prismatic"},
    -- Divine
    {name="Admin Bloom", rarity="Divine"}, {name="Cocoa", rarity="Divine"}, {name="Compost Hydra", rarity="Divine"}, {name="Crystalberry", rarity="Divine"}, {name="Diamond Blossom", rarity="Divine"}, {name="Dreadcap", rarity="Divine"}, {name="Golden Apple", rarity="Divine"}, {name="Horned Melon", rarity="Divine"}, {name="Pomegranate", rarity="Divine"},
    -- Exotic
    {name="Crimson Higanbana", rarity="Exotic"}, {name="Dragonfruit", rarity="Exotic"}, {name="Elder Dragonroot", rarity="Exotic"}, {name="Heartvine", rarity="Exotic"}, {name="Kiwi", rarity="Exotic"}, {name="Moonflower", rarity="Exotic"}, {name="Passionfruit", rarity="Exotic"}, {name="Pepper", rarity="Exotic"}, {name="Striped Starfruit", rarity="Exotic"}, {name="Truckers Delight", rarity="Exotic"}, {name="Void Fruit", rarity="Exotic"},
    -- Transcended
    {name="Durian", rarity="Transcended"}, {name="Ember Fruit", rarity="Transcended"}, {name="Garden Devourer", rarity="Transcended"}, {name="Garden Golem", rarity="Transcended"}, {name="Ghost Pepper", rarity="Transcended"}, {name="Heart of Corruption", rarity="Transcended"}, {name="Papaya", rarity="Transcended"}, {name="Queens Blossom", rarity="Transcended"}
}

local CONFIG_GEARS = {
    "Fire Spray", "Bubblegum Spray", "Cosmic Spray", "Prismatic Fertilizer",
    "Rainbow Spray", "Radioactive Spray", "Super Pet Treat", "Super Fertilizer",
    "Void Spray", "Autumn Spray", "Frozen Spray", "Strong Pet Treat",
    "Strong Fertilizer", "Wet Spray", "Acid Spray", "Normal Pet Treat", "Normal Fertilizer"
}

local CONFIG_SEEDS = {}
local SeedByName = {}
local GearItems = {}

for _, name in ipairs(CONFIG_GEARS) do
    table.insert(GearItems, {name = name, maxStock = 1})
end

local autoRollEnabled  = false
local autoBuyEnabled   = false
local autoGearEnabled  = false
local autoFertEnabled  = false
local autoSellEnabled  = false
local autoBuyList = {}
local gearBuyList = {}
local gearStock   = {}
local gearLocks   = {} 

local function saveSettings()
    if not writefile then return end
    local data = {
        autoRoll  = autoRollEnabled,
        autoBuy   = autoBuyEnabled,
        autoGear  = autoGearEnabled,
        autoFert  = autoFertEnabled,
        autoSell  = autoSellEnabled,
        buyList   = {},
        gearList  = {},
        seedData  = {}
    }
    for name in pairs(autoBuyList) do table.insert(data.buyList, name) end
    for name in pairs(gearBuyList) do table.insert(data.gearList, name) end
    for _, seed in ipairs(CONFIG_SEEDS) do
        data.seedData[seed.name] = { rarity = seed.rarity, cost = seed.cost or 0 }
    end
    pcall(function() writefile(FILE_NAME, HttpService:JSONEncode(data)) end)
end

local function loadSettings()
    -- Initialize defaults
    for _, defaultItem in ipairs(DEFAULT_SEEDS) do
        local item = {name = defaultItem.name, rarity = defaultItem.rarity, cost = 0, income = 1}
        table.insert(CONFIG_SEEDS, item)
        SeedByName[item.name] = item
    end

    -- Load from file
    if isfile and readfile and isfile(FILE_NAME) then
        local success, savedData = pcall(function() return HttpService:JSONDecode(readfile(FILE_NAME)) end)
        if success and type(savedData) == "table" then
            
            if savedData.autoRoll then autoRollEnabled = true end
            if savedData.autoBuy  then autoBuyEnabled  = true end
            if savedData.autoGear then autoGearEnabled = true end
            if savedData.autoFert then autoFertEnabled = true end
            if savedData.autoSell then autoSellEnabled = true end

            if type(savedData.buyList) == "table" then
                for _, name in ipairs(savedData.buyList) do autoBuyList[name] = true end
            end
            if type(savedData.gearList) == "table" then
                for _, name in ipairs(savedData.gearList) do gearBuyList[name] = true end
            end
            
            if type(savedData.seedData) == "table" then
                for seedName, savedInfo in pairs(savedData.seedData) do
                    if SeedByName[seedName] then
                        if savedInfo.cost then SeedByName[seedName].cost = savedInfo.cost end
                        if savedInfo.rarity then SeedByName[seedName].rarity = savedInfo.rarity end
                    else
                        -- Catch new unlisted seeds
                        local newItem = {name = seedName, rarity = savedInfo.rarity or "Common", cost = savedInfo.cost or 0, income = 1}
                        table.insert(CONFIG_SEEDS, newItem)
                        SeedByName[seedName] = newItem
                    end
                end
            end
        end
    end
    saveSettings()
end

loadSettings()

-- ─── Remotes ─────────────────────────────────────────────────────────────────

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local RollSeeds       = Remotes:WaitForChild("RollSeeds")
local BuySeed         = Remotes:WaitForChild("BuySeed")
local GearTransaction = Remotes:WaitForChild("Gear"):WaitForChild("Transaction")
local SellCrates      = Remotes:WaitForChild("SellCrates")

-- ─── GUI Base ────────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name = "RFGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local function mkCorner(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 6);return c end
local function mkStroke(p,col,t,a)
    local s=Instance.new("UIStroke",p);s.Color=col or C.border;s.Thickness=t or 1;s.Transparency=a or 0;return s
end
local function mkLabel(p,txt,col,size,font,xa)
    local l=Instance.new("TextLabel",p);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=col or C.white
    l.TextSize=size or 13;l.Font=font or Enum.Font.Gotham;l.TextXAlignment=xa or Enum.TextXAlignment.Left;l.Size=UDim2.new(1,0,1,0);return l
end
local function mkBtn(p,txt,col,tcol,size)
    local b=Instance.new("TextButton",p);b.BackgroundColor3=col or C.raised;b.BorderSizePixel=0;b.Text=txt
    b.TextColor3=tcol or C.sub;b.Font=Enum.Font.Gotham;b.TextSize=size or 11;return b
end

local function draggable(handle,target)
    local drag,ds,sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp=target.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

local function mkToggle(parent)
    local track=Instance.new("Frame",parent)
    track.Size=UDim2.new(0,40,0,20);track.BackgroundColor3=C.raised;track.BorderSizePixel=0;mkCorner(track,10);mkStroke(track,C.border,1,0.3)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14);knob.Position=UDim2.new(0,3,0.5,-7);knob.BackgroundColor3=C.muted;knob.BorderSizePixel=0;mkCorner(knob,7)
    local on=false
    local function set(state)
        on=state
        if state then
            TweenService:Create(track,tw,{BackgroundColor3=C.accent}):Play()
            TweenService:Create(knob,tw,{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=C.white}):Play()
        else
            TweenService:Create(track,tw,{BackgroundColor3=C.raised}):Play()
            TweenService:Create(knob,tw,{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=C.muted}):Play()
        end
    end
    return track,set,function() return on end
end

-- ─── Main Window ─────────────────────────────────────────────────────────────

local win=Instance.new("Frame",gui)
win.Size=UDim2.new(0,240,0,0);win.Position=UDim2.new(0,20,0.5,-110);win.BackgroundColor3=C.bg
win.BackgroundTransparency=0.08;win.BorderSizePixel=0;win.ClipsDescendants=true
mkCorner(win,10);mkStroke(win,C.border,1,0.5)

local header=Instance.new("Frame",win)
header.Size=UDim2.new(1,0,0,44);header.BackgroundColor3=C.surface;header.BorderSizePixel=0;mkCorner(header,10)
local hp=Instance.new("Frame",header)
hp.Size=UDim2.new(1,0,0.5,0);hp.Position=UDim2.new(0,0,0.5,0);hp.BackgroundColor3=C.surface;hp.BorderSizePixel=0

local titleLbl=Instance.new("TextLabel",header)
titleLbl.Size=UDim2.new(1,-70,1,0);titleLbl.Position=UDim2.new(0,16,0,0);titleLbl.BackgroundTransparency=1
titleLbl.Text="Build a Ring Farm";titleLbl.TextColor3=C.white;titleLbl.Font=Enum.Font.GothamBold;titleLbl.TextSize=14;titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local closeBtn=Instance.new("TextButton",header)
closeBtn.Size=UDim2.new(0,24,0,24);closeBtn.Position=UDim2.new(1,-30,0.5,-12);closeBtn.BackgroundColor3=Color3.fromRGB(55,25,25)
closeBtn.BorderSizePixel=0;closeBtn.Text="X";closeBtn.TextColor3=C.red;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=12;closeBtn.AutoButtonColor=false;mkCorner(closeBtn,5)

local minBtn=Instance.new("TextButton",header)
minBtn.Size=UDim2.new(0,24,0,24);minBtn.Position=UDim2.new(1,-60,0.5,-12);minBtn.BackgroundColor3=C.raised
minBtn.BorderSizePixel=0;minBtn.Text="-";minBtn.TextColor3=C.white;minBtn.Font=Enum.Font.GothamBold;minBtn.TextSize=14;minBtn.AutoButtonColor=false;mkCorner(minBtn,5)

draggable(header,win)

local ROW_H, ROW_GAP, START_Y = 48, 1, 45
local rowCount = 0

local function addRow(label, hasConfig, configLabel)
    local y = START_Y + rowCount*(ROW_H+ROW_GAP); rowCount += 1
    local sep=Instance.new("Frame",win)
    sep.Size=UDim2.new(1,-24,0,1);sep.Position=UDim2.new(0,12,0,y-1);sep.BackgroundColor3=C.border;sep.BorderSizePixel=0;sep.BackgroundTransparency=0.6
    local row=Instance.new("Frame",win)
    row.Size=UDim2.new(1,0,0,ROW_H);row.Position=UDim2.new(0,0,0,y);row.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0,100,1,0);lbl.Position=UDim2.new(0,16,0,0);lbl.BackgroundTransparency=1;lbl.Text=label
    lbl.TextColor3=C.white;lbl.Font=Enum.Font.GothamBold;lbl.TextSize=13;lbl.TextXAlignment=Enum.TextXAlignment.Left
    local track,setToggle,getToggle=mkToggle(row)
    track.Position=UDim2.new(1,-52,0.5,-10)
    local cfgBtn
    if hasConfig then
        cfgBtn=mkBtn(row,configLabel or "Config",C.surface,C.sub,10);cfgBtn.Size=UDim2.new(0,44,0,20)
        cfgBtn.Position=UDim2.new(1,-100,0.5,-10);mkCorner(cfgBtn,5);mkStroke(cfgBtn,C.border,1,0.5)
    end
    return track,setToggle,getToggle,cfgBtn
end

local rollTrack,setRoll,getRoll             = addRow("Auto Roll")
local buyTrack,setBuy,getBuy,buyCfgBtn      = addRow("Auto Buy","Seeds","Seeds")
local gearTrack,setGear,getGear,gearCfgBtn  = addRow("Auto Gear",true,"Items")
local fertTrack,setFert,getFert             = addRow("Auto Fert")
local sellTrack,setSell,getSell             = addRow("Auto Sell") 

local statusY = START_Y + rowCount*(ROW_H+ROW_GAP) + 4
local statusRow=Instance.new("Frame",win)
statusRow.Size=UDim2.new(1,0,0,24);statusRow.Position=UDim2.new(0,0,0,statusY+2);statusRow.BackgroundTransparency=1

local statusDot=Instance.new("Frame",statusRow)
statusDot.Size=UDim2.new(0,6,0,6);statusDot.Position=UDim2.new(0,14,0.5,-3);statusDot.BackgroundColor3=C.muted;statusDot.BorderSizePixel=0;mkCorner(statusDot,3)

local statusLbl=Instance.new("TextLabel",statusRow)
statusLbl.Size=UDim2.new(1,-30,1,0);statusLbl.Position=UDim2.new(0,26,0,0);statusLbl.BackgroundTransparency=1
statusLbl.Text="Idle";statusLbl.TextColor3=C.muted;statusLbl.Font=Enum.Font.Gotham;statusLbl.TextSize=11;statusLbl.TextXAlignment=Enum.TextXAlignment.Left

local footer=Instance.new("TextLabel",win)
footer.Size=UDim2.new(1,-16,0,34);footer.Position=UDim2.new(0,8,0,statusY+24);footer.BackgroundTransparency=1
footer.Text="made by @Jacksblox\nGet Executors at vanishhub.com";footer.TextColor3=Color3.fromRGB(190,200,240)
footer.Font=Enum.Font.Gotham;footer.TextSize=11;footer.TextXAlignment=Enum.TextXAlignment.Center

local expandedHeight = statusY+58
win.Size=UDim2.new(0,240,0,expandedHeight)

local isMinimized = false
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    TweenService:Create(win, tw, {Size=UDim2.new(0,240,0,isMinimized and 44 or expandedHeight)}):Play()
end)

local function setStatus(txt,col,dotCol)
    statusLbl.Text=txt;statusLbl.TextColor3=col or C.muted
    statusDot.BackgroundColor3=dotCol or C.muted
end

-- ─── Panel Builder ───────────────────────────────────────────────────────────

local function makePanel(title, w, h)
    local p=Instance.new("Frame",gui)
    p.Size=UDim2.new(0,w,0,h);p.BackgroundColor3=C.bg;p.BorderSizePixel=0;p.Visible=false;mkCorner(p,10);mkStroke(p,C.border,1,0.4)

    local hdr=Instance.new("Frame",p)
    hdr.Size=UDim2.new(1,0,0,40);hdr.BackgroundColor3=C.surface;hdr.BorderSizePixel=0;hdr.ZIndex=2;mkCorner(hdr,10)
    
    local tlbl=Instance.new("TextLabel",hdr)
    tlbl.Size=UDim2.new(1,-60,1,0);tlbl.Position=UDim2.new(0,22,0,0);tlbl.BackgroundTransparency=1;tlbl.Text=title
    tlbl.TextColor3=C.white;tlbl.Font=Enum.Font.GothamBold;tlbl.TextSize=13;tlbl.TextXAlignment=Enum.TextXAlignment.Left;tlbl.ZIndex=3

    local xBtn=Instance.new("TextButton",hdr)
    xBtn.Size=UDim2.new(0,24,0,24);xBtn.Position=UDim2.new(1,-30,0.5,-12);xBtn.BackgroundColor3=Color3.fromRGB(55,25,25)
    xBtn.BorderSizePixel=0;xBtn.Text="X";xBtn.TextColor3=C.red;xBtn.Font=Enum.Font.GothamBold;xBtn.TextSize=12
    xBtn.ZIndex=4;xBtn.AutoButtonColor=false;mkCorner(xBtn,5)

    draggable(hdr,p)

    local allBtn=mkBtn(p,"All",C.surface,C.sub,10)
    allBtn.Size=UDim2.new(0,40,0,20);allBtn.Position=UDim2.new(0,12,0,46);allBtn.ZIndex=3;mkCorner(allBtn,5);mkStroke(allBtn,C.border,1,0.5)

    local noneBtn=mkBtn(p,"None",C.surface,C.sub,10)
    noneBtn.Size=UDim2.new(0,44,0,20);noneBtn.Position=UDim2.new(0,56,0,46);noneBtn.ZIndex=3;mkCorner(noneBtn,5);mkStroke(noneBtn,C.border,1,0.5)

    local scroll=Instance.new("ScrollingFrame",p)
    scroll.Size=UDim2.new(1,-8,1,-72);scroll.Position=UDim2.new(0,4,0,68);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=2;scroll.ScrollBarImageColor3=C.accent;scroll.CanvasSize=UDim2.new(0,0,0,0);scroll.ZIndex=2
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Native Scrolling Fix

    local layout=Instance.new("UIListLayout",scroll)
    layout.Padding=UDim.new(0,2);layout.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",scroll)
    pad.PaddingLeft=UDim.new(0,6);pad.PaddingRight=UDim.new(0,6);pad.PaddingTop=UDim.new(0,4)

    local function positionNextTo()
        p.Position=UDim2.new(win.Position.X.Scale, win.Position.X.Offset+win.AbsoluteSize.X+8, win.Position.Y.Scale, win.Position.Y.Offset)
    end
    return p,scroll,layout,xBtn,allBtn,noneBtn,positionNextTo
end

-- ─── Seed Panel ──────────────────────────────────────────────────────────────

local seedPanel,seedScroll,seedLayout,seedClose,seedAll,seedNone,seedPos = makePanel("Seeds",300,480)
local seedPanelOpen=false
local seedToggles={}

local idx=0
for _,rarity in ipairs(RARITY_ORDER) do
    local group={}
    for _,s in ipairs(CONFIG_SEEDS) do if s.rarity==rarity then table.insert(group,s) end end
    if #group==0 then continue end

    idx+=1
    local hdr=Instance.new("Frame",seedScroll)
    hdr.Size=UDim2.new(1,0,0,24);hdr.BackgroundTransparency=1;hdr.LayoutOrder=idx
    
    local hl=mkLabel(hdr,rarity,RARITY_COLOR[rarity],11,Enum.Font.GothamBold)
    hl.TextTransparency=0.1; hl.Size=UDim2.new(1,-50,1,0); hl.Position=UDim2.new(0,6,0,0)
    
    local rTrack, rSet, rGet = mkToggle(hdr)
    rTrack.Position=UDim2.new(1,-42,0.5,-10)

    local myToggles = {}

    for _,seed in ipairs(group) do
        idx+=1
        local row=Instance.new("Frame",seedScroll)
        row.Size=UDim2.new(1,0,0,50);row.BackgroundColor3=C.surface;row.BorderSizePixel=0;row.LayoutOrder=idx;mkCorner(row,7)

        local nameL=mkLabel(row,seed.name,RARITY_COLOR[rarity],12,Enum.Font.GothamBold)
        nameL.Size=UDim2.new(1,-50,0,22);nameL.Position=UDim2.new(0,10,0,5)

        -- Load visual prices instantly from JSON Cache
        local initialCostText = "Cost ?"
        if seed.cost and seed.cost > 0 then
            initialCostText = "Cost " .. fmt(seed.cost)
        end

        local infoL=mkLabel(row, initialCostText, C.muted,9,Enum.Font.Gotham)
        infoL.Size=UDim2.new(1,-50,0,14);infoL.Position=UDim2.new(0,10,0,27);infoL.TextTruncate=Enum.TextTruncate.AtEnd

        local ttrack,setT,getT=mkToggle(row)
        ttrack.Size=UDim2.new(0,36,0,18);ttrack.Position=UDim2.new(1,-42,0.5,-9)
        table.insert(myToggles, {set=setT, get=getT, name=seed.name})

        ttrack.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local s=not getT();setT(s);autoBuyList[seed.name]=s or nil;saveSettings()
            end
        end)
        seedToggles[seed.name]={set=setT,get=getT, label=infoL}
    end

    rTrack.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            local s = not rGet(); rSet(s)
            for _, t in ipairs(myToggles) do t.set(s); autoBuyList[t.name] = s or nil end
            saveSettings()
        end
    end)
end

seedAll.MouseButton1Click:Connect(function()
    for _,s in ipairs(CONFIG_SEEDS) do autoBuyList[s.name]=true;if seedToggles[s.name] then seedToggles[s.name].set(true) end end
    saveSettings()
end)
seedNone.MouseButton1Click:Connect(function()
    table.clear(autoBuyList)
    for _,s in ipairs(CONFIG_SEEDS) do if seedToggles[s.name] then seedToggles[s.name].set(false) end end
    saveSettings()
end)

local function openSeed()
    seedPanelOpen=true;seedPos();seedPanel.Visible=true
    buyCfgBtn.BackgroundColor3=C.accent;buyCfgBtn.TextColor3=C.white
end
local function closeSeed()
    seedPanelOpen=false;seedPanel.Visible=false
    buyCfgBtn.BackgroundColor3=C.surface;buyCfgBtn.TextColor3=C.sub
end
seedClose.MouseButton1Click:Connect(closeSeed)
buyCfgBtn.MouseButton1Click:Connect(function() if seedPanelOpen then closeSeed() else openSeed() end end)

-- ─── Gear Panel ──────────────────────────────────────────────────────────────

local gearPanel,gearScroll,gearLayout,gearClose2,gearAll,gearNone,gearPos = makePanel("Gear Shop",250,480)
local gearPanelOpen=false
local gearToggles={}
local gearStockLabels={}

local gi=0
for _,item in ipairs(GearItems) do
    gi+=1
    local row=Instance.new("Frame",gearScroll)
    row.Size=UDim2.new(1,0,0,50);row.BackgroundColor3=C.surface;row.BorderSizePixel=0;row.LayoutOrder=gi;mkCorner(row,7)

    local nL=mkLabel(row,item.name,C.white,12,Enum.Font.GothamBold)
    nL.Size=UDim2.new(1,-50,0,22);nL.Position=UDim2.new(0,10,0,5)

    local initialCost = getGearCost(item.name)
    local stockLbl=mkLabel(row,"",C.muted,9,Enum.Font.Gotham)
    stockLbl.Size=UDim2.new(1,-50,0,14);stockLbl.Position=UDim2.new(0,10,0,27)
    stockLbl.Text="Cost "..fmt(initialCost).."  ·  Max "..item.maxStock.."  ·  Checking..."
    gearStockLabels[item.name]=stockLbl

    local ttrack,setT,getT=mkToggle(row)
    ttrack.Size=UDim2.new(0,36,0,18);ttrack.Position=UDim2.new(1,-42,0.5,-9)

    ttrack.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            local s=not getT();setT(s);gearBuyList[item.name]=s or nil;saveSettings()
        end
    end)
    gearToggles[item.name]={set=setT,get=getT}
end

gearAll.MouseButton1Click:Connect(function()
    for _,item in ipairs(GearItems) do gearBuyList[item.name]=true;if gearToggles[item.name] then gearToggles[item.name].set(true) end end
    saveSettings()
end)
gearNone.MouseButton1Click:Connect(function()
    table.clear(gearBuyList)
    for _,item in ipairs(GearItems) do if gearToggles[item.name] then gearToggles[item.name].set(false) end end
end)

local function openGear()
    gearPanelOpen=true
    gearPanel.Position=UDim2.new(win.Position.X.Scale, win.Position.X.Offset+win.AbsoluteSize.X+8, win.Position.Y.Scale, win.Position.Y.Offset+50)
    gearPanel.Visible=true
    gearCfgBtn.BackgroundColor3=C.accent;gearCfgBtn.TextColor3=C.white
end
local function closeGear()
    gearPanelOpen=false;gearPanel.Visible=false
    gearCfgBtn.BackgroundColor3=C.surface;gearCfgBtn.TextColor3=C.sub
end
gearClose2.MouseButton1Click:Connect(closeGear)
gearCfgBtn.MouseButton1Click:Connect(function() if gearPanelOpen then closeGear() else openGear() end end)

-- ─── Load Setting Values To UI Toggles ───────────────────────────────────────

if autoRollEnabled then setRoll(true) end
if autoBuyEnabled  then setBuy(true)  end
if autoGearEnabled then setGear(true) end
if autoFertEnabled then setFert(true) end
if autoSellEnabled then setSell(true) end

for name in pairs(autoBuyList) do if seedToggles[name] then seedToggles[name].set(true) end end
for name in pairs(gearBuyList) do if gearToggles[name] then gearToggles[name].set(true) end end

rollTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoRollEnabled=not getRoll();setRoll(autoRollEnabled);saveSettings()
end)
buyTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoBuyEnabled=not getBuy();setBuy(autoBuyEnabled);saveSettings()
end)
gearTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoGearEnabled=not getGear();setGear(autoGearEnabled);saveSettings()
end)
sellTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoSellEnabled=not getSell();setSell(autoSellEnabled);saveSettings()
end)

-- ─── Gear Stock Polling & Purchasing ─────────────────────────────────────────

local function parseStock(lbl)
    if not lbl then return 0 end
    return tonumber(lbl.Text:match("Stock: (%d+)")) or 0
end

local function updateStockLabel(name, stock)
    gearStock[name] = stock
    if not gearStockLabels[name] then return end
    local item
    for _,g in ipairs(GearItems) do if g.name==name then item=g;break end end
    if not item then return end
    
    local currentCost = getGearCost(name)
    local stockStr = stock > 0 and ("In Stock: "..stock) or "Out of Stock"
    gearStockLabels[name].Text = "Cost "..fmt(currentCost).."  ·  "..stockStr
    gearStockLabels[name].TextColor3 = stock > 0 and C.green or C.red
end

local function buyGearItem(item, dynamicCost)
    if gearLocks[item.name] then return end 
    if getPlayerCash() < dynamicCost then return end
    
    gearLocks[item.name] = true
    task.spawn(function()
        local simCash = getPlayerCash()
        for _ = 1, item.maxStock do
            if simCash < dynamicCost then break end
            simCash = simCash - dynamicCost
            task.spawn(function() pcall(function() GearTransaction:InvokeServer(item.name) end) end)
            task.wait(0.4)
        end
        gearLocks[item.name] = false
    end)
end

task.spawn(function()
    while true do
        task.wait(2)
        
        local pg = player:FindFirstChild("PlayerGui")
        local scroll = pg and pg:FindFirstChild("MainUI")
            and pg.MainUI:FindFirstChild("Menus")
            and pg.MainUI.Menus:FindFirstChild("GearShopFrame")
            and pg.MainUI.Menus.GearShopFrame:FindFirstChild("ScrollingFrame")
            
        if scroll then
            for _, item in ipairs(GearItems) do
                local itemFrame = scroll:FindFirstChild(item.name)
                local stockLbl = itemFrame and itemFrame:FindFirstChild("GearImage") and itemFrame.GearImage:FindFirstChild("Rarity")
                if stockLbl then updateStockLabel(item.name, parseStock(stockLbl)) end
            end
        end
        
        if autoGearEnabled then
            local availableGears = {}
            for _, item in ipairs(GearItems) do
                if gearBuyList[item.name] and (gearStock[item.name] or 0) > 0 then
                    local currentCost = getGearCost(item.name)
                    if currentCost ~= math.huge then table.insert(availableGears, {item = item, cost = currentCost}) end
                end
            end
            table.sort(availableGears, function(a, b) return a.cost < b.cost end)
            for _, data in ipairs(availableGears) do buyGearItem(data.item, data.cost) end
        end
    end
end)

-- ─── Toast Notification ──────────────────────────────────────────────────────

local toastFrame = Instance.new("Frame", gui)
toastFrame.Size = UDim2.new(0, 320, 0, 60); toastFrame.Position = UDim2.new(0.5, -160, 0.42, 0)
toastFrame.BackgroundColor3 = C.bg; toastFrame.BackgroundTransparency = 1; toastFrame.BorderSizePixel = 0; toastFrame.Visible = false
mkCorner(toastFrame, 10); mkStroke(toastFrame, C.border, 1.2, 0)

local toastSeedName = Instance.new("TextLabel", toastFrame)
toastSeedName.Size = UDim2.new(1, -20, 0, 28); toastSeedName.Position = UDim2.new(0, 10, 0, 8)
toastSeedName.BackgroundTransparency = 1; toastSeedName.Font = Enum.Font.GothamBold; toastSeedName.TextSize = 20
toastSeedName.TextXAlignment = Enum.TextXAlignment.Center; toastSeedName.TextTransparency = 1

local toastSub = Instance.new("TextLabel", toastFrame)
toastSub.Size = UDim2.new(1, -20, 0, 16); toastSub.Position = UDim2.new(0, 10, 0, 36)
toastSub.BackgroundTransparency = 1; toastSub.Text = "Seed Purchased"; toastSub.TextColor3 = C.sub
toastSub.Font = Enum.Font.Gotham; toastSub.TextSize = 12; toastSub.TextXAlignment = Enum.TextXAlignment.Center; toastSub.TextTransparency = 1

local function showToast(seedName)
    local seed = SeedByName[seedName]
    local col = seed and RARITY_COLOR[seed.rarity] or C.white
    toastSeedName.Text = seedName; toastSeedName.TextColor3 = col; toastFrame.Visible = true

    local s = toastFrame:FindFirstChildWhichIsA("UIStroke"); if s then s.Color = col end
    local fadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
    TweenService:Create(toastFrame, fadeIn, {BackgroundTransparency=0.1}):Play()
    TweenService:Create(toastSeedName, fadeIn, {TextTransparency=0}):Play()
    TweenService:Create(toastSub, fadeIn, {TextTransparency=0}):Play()

    task.delay(2.2, function()
        local fadeOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
        TweenService:Create(toastFrame, fadeOut, {BackgroundTransparency=1}):Play()
        TweenService:Create(toastSeedName, fadeOut, {TextTransparency=1}):Play()
        TweenService:Create(toastSub, fadeOut, {TextTransparency=1}):Play()
        task.wait(0.5); toastFrame.Visible = false
    end)
end

-- ─── The Reliable Auto Buy Pipeline ──────────────────────────────────────────

local pendingBuys = {}

-- Listen to the server to map the Slot ID (1-6) to the Seed Name
RollSeeds.OnClientEvent:Connect(function(rolledSeeds)
    if type(rolledSeeds) ~= "table" then return end
    for slotIndex, seedName in pairs(rolledSeeds) do
        if type(seedName) == "string" then
            pendingBuys[tonumber(slotIndex) or slotIndex] = seedName
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        
        -- If we have seeds in the queue...
        if next(pendingBuys) ~= nil then
            
            if autoBuyEnabled then
                -- The exact 2.5s spin timer you suggested
                task.wait(2.5) 
                
                local simCash = getPlayerCash()

                for slot, seedName in pairs(pendingBuys) do
                    if autoBuyList[seedName] then
                        local cost = SeedByName[seedName].cost
                        
                        -- Scrape cost if we haven't saved it yet
                        if not cost or cost == 0 or cost == math.huge then
                            cost = scrapeSeedCostFromWorkspace(seedName)
                            if cost ~= math.huge then
                                SeedByName[seedName].cost = cost
                                saveSettings()
                                if seedToggles[seedName] and seedToggles[seedName].label then
                                    seedToggles[seedName].label.Text = "Cost " .. fmt(cost)
                                end
                            end
                        end

                        -- If we can afford it, buy it safely
                        if cost ~= math.huge and simCash >= cost then
                            BuySeed:FireServer(slot)
                            simCash = simCash - cost
                            showToast(seedName)
                            
                            -- CRITICAL FIX: 0.4s yield so the server doesn't drop the packet!
                            task.wait(0.4) 
                        end
                    end
                end
                
                -- Clear queue so Auto Roll can fire again
                table.clear(pendingBuys)
                
            else
                -- If Auto Buy is OFF, we still need to clear the queue so Auto Roll doesn't get jammed
                task.wait(3)
                table.clear(pendingBuys)
            end
        end
    end
end)

-- Background Cost Scraper (Updates UI quietly while you play if new seeds spawn)
task.spawn(function()
    while true do
        task.wait(2)
        for _, obj in ipairs(workspace:GetChildren()) do
            local seedData = SeedByName[obj.Name]
            if seedData and (not seedData.cost or seedData.cost == 0) then
                local costLbl = obj:FindFirstChild("Cost", true)
                if costLbl and costLbl:IsA("TextLabel") and costLbl.Text ~= "" and not costLbl.Text:find("Label") then
                    local cost = parseMoneyString(costLbl.Text)
                    if cost ~= math.huge then
                        seedData.cost = cost
                        saveSettings()
                        if seedToggles[obj.Name] and seedToggles[obj.Name].label then
                            seedToggles[obj.Name].label.Text = "Cost " .. fmt(cost)
                        end
                    end
                end
            end
        end
    end
end)

-- ─── Smart Auto Roll Loop ────────────────────────────────────────────────────

local lastRollTime = 0

RunService.Heartbeat:Connect(function()
    if not autoRollEnabled then return end
    
    -- Do not fire a roll if we are currently waiting for a spin or processing buys
    if next(pendingBuys) ~= nil then return end
    
    local now = tick()
    if now - lastRollTime > 0.5 then
        lastRollTime = now
        RollSeeds:FireServer()
    end
end)

-- ─── Dynamic UI Status Loop ──────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(0.2)
        if autoRollEnabled then
            if next(pendingBuys) ~= nil then
                setStatus("Spinning/Buying...", C.accent, C.accent)
            else
                setStatus("Rolling", C.green, C.green)
            end
        else
            setStatus("Idle", C.muted, C.muted)
        end
    end
end)

-- ─── Auto Sell Crates ────────────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(5)
        if autoSellEnabled then pcall(function() SellCrates:FireServer() end) end
    end
end)

-- ─── Auto Fertilizer ─────────────────────────────────────────────────────────

local UseFertilizer = Remotes:WaitForChild("UseFertilizer")

local FERT_RARITY_RANK = {
    Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,
    Secret=6,Prismatic=7,Divine=8,Exotic=9,Transcended=10
}

local MUTATION_RANK = {
    Fire=10, Bubblegum=9, Cosmic=8, Rainbow=7, Radioactive=6,
    Void=5, Autumn=4, Frozen=3, Wet=2, Acid=1, Normal=0, Farm=0
}

local floorMultipliers = {}
local harvestedData = {}
local plantsData = {}

local function loadGCPlantData()
    local ok, gc = pcall(getgc, true)
    if not ok then return end
    local seen = {}
    for _, obj in ipairs(gc) do
        if type(obj) ~= "table" or seen[obj] then continue end
        seen[obj] = true

        pcall(function()
            if type(obj.Name)=="string" and type(obj.Level)=="number" and type(obj.Mutation)=="string" and type(obj.FloorKey)=="string" then
                local fk = obj.FloorKey
                if not floorMultipliers[fk] then floorMultipliers[fk] = obj.EarningsMultiplier end
                local key = obj.Name.."|"..fk.."|"..obj.Mutation
                if not harvestedData[key] then harvestedData[key] = {mult=obj.EarningsMultiplier, level=obj.Level, mutation=obj.Mutation, name=obj.Name, floor=fk} end
            end
        end)
    end
end
task.spawn(loadGCPlantData)

local function getFertilizers()
    local list = {}
    local backpack = player:WaitForChild("Backpack")
    for _, tool in ipairs(backpack:GetChildren()) do
        local boost = tool:GetAttribute("Boost")
        local key   = tool:GetAttribute("gearKey")
        if boost and key and key:lower():find("fertilizer") then
            table.insert(list, {key=key, boost=boost})
        end
    end
    table.sort(list, function(a,b) return a.boost > b.boost end)
    return list
end

local function getPlantedDirts()
    local ok, plotName = pcall(function() return Remotes.Plot.GetPlot:InvokeServer() end)
    if not ok or not plotName then return {} end

    local plotModel = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Plots") and workspace.Map.Plots:FindFirstChild(tostring(plotName))
    if not plotModel then return {} end

    local dirts = {}
    for _, obj in ipairs(plotModel:GetDescendants()) do
        if obj.Name == "Dirt" and obj:IsA("BasePart") then
            local parentName = obj.Parent and obj.Parent.Name or ""
            if parentName:match("^Plot%d+$") then
                table.insert(dirts, {part=obj, score=1}) 
            end
        end
    end
    return dirts
end

local function runAutoFert()
    local dirts = getPlantedDirts()
    if #dirts == 0 then return end
    local ferts = getFertilizers()
    if #ferts == 0 then return end

    local char = player.Character
    for _, dirt in ipairs(dirts) do
        local toolKey = ferts[1].key
        local tool = nil
        for _, t in ipairs(player:WaitForChild("Backpack"):GetChildren()) do
            if t:GetAttribute("gearKey") == toolKey then tool = t; break end
        end
        if tool and char then tool.Parent = char end
        pcall(function() UseFertilizer:FireServer(dirt.part) end)
        task.wait(0.4)
    end
end

fertTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoFertEnabled=not getFert();setFert(autoFertEnabled)
    if autoFertEnabled then task.spawn(runAutoFert) end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if autoFertEnabled then pcall(runAutoFert) end
    end
end)
