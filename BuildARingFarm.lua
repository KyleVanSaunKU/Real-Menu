local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- ─── Seed Data ───────────────────────────────────────────────────────────────

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
    if not n then return "?" end
    local s = {"","K","M","B","T","Q"}
    local i = 1
    while n >= 1000 and i < #s do n=n/1000; i=i+1 end
    return "$".. (n>=100 and string.format("%.0f",n) or n>=10 and string.format("%.1f",n) or string.format("%.2f",n)) .. s[i]
end

-- Seed data sourced directly from ReplicatedStorage.Shared.Registry.Plants
-- RollChance = weight from game (0 = not rollable). Last updated: June 3 2026
local Seeds = {
    -- COMMON (weights ~75-100)
    {name="Carrot",             rarity="Common",      cost=100,              income=3,       chance="Common"},
    {name="Beetroot",           rarity="Common",      cost=250,              income=5,       chance="Common"},
    {name="Pumpkin",            rarity="Common",      cost=500,              income=8,       chance="Common"},
    {name="Cinnamon",           rarity="Common",      cost=nil,              income=nil,     chance="?"},

    -- UNCOMMON
    {name="Wheat",              rarity="Uncommon",    cost=600,              income=12,      chance="Uncommon"},
    {name="Melon",              rarity="Uncommon",    cost=1200,             income=18,      chance="Uncommon"},
    {name="Onion",              rarity="Uncommon",    cost=2500,             income=20,      chance="Uncommon"},
    {name="Cantaloupe",         rarity="Uncommon",    cost=3500,             income=25,      chance="Uncommon"},
    {name="Watermelon",         rarity="Uncommon",    cost=5000,             income=30,      chance="Uncommon"},
    {name="Promise Lily",       rarity="Uncommon",    cost=nil,              income=22,      chance="Friend-o-Tron"},
    {name="Twinflame Tulip",    rarity="Uncommon",    cost=520000,           income=450,     chance="Not rollable"},

    -- RARE
    {name="Blueberry",          rarity="Rare",        cost=15000,            income=50,      chance="Rare"},
    {name="Cabbage",            rarity="Rare",        cost=40000,            income=85,      chance="Rare"},
    {name="Grape",              rarity="Rare",        cost=65000,            income=120,     chance="Rare"},
    {name="Peach",              rarity="Rare",        cost=120000,           income=180,     chance="Rare"},
    {name="Bamboo",             rarity="Rare",        cost=90000,            income=160,     chance="Rare"},

    -- EPIC
    {name="Corn",               rarity="Epic",        cost=200000,           income=250,     chance="Epic"},
    {name="Plum",               rarity="Epic",        cost=300000,           income=300,     chance="Epic"},
    {name="Cauliflower",        rarity="Epic",        cost=500000,           income=400,     chance="Epic"},
    {name="Nectarine",          rarity="Epic",        cost=600000,           income=480,     chance="Epic"},
    {name="Sunflower",          rarity="Epic",        cost=650000,           income=550,     chance="Epic"},
    {name="Citrus",             rarity="Epic",        cost=850000,           income=700,     chance="Epic"},
    {name="Twinflame Tulip",    rarity="Epic",        cost=520000,           income=450,     chance="Not rollable"},
    {name="Honeysuckle",        rarity="Epic",        cost=615000,           income=500,     chance="Bee Event"},
    {name="Martian Melon",      rarity="Epic",        cost=700000,           income=620,     chance="Alien Event"},
    {name="Admin Sunflower",    rarity="Epic",        cost=865000,           income=725,     chance="Admin"},

    -- LEGENDARY
    {name="Spring Onion",       rarity="Legendary",   cost=2500000,          income=1200,    chance="Legendary"},
    {name="Mango",              rarity="Legendary",   cost=4000000,          income=1600,    chance="Legendary"},
    {name="Mushroom",           rarity="Legendary",   cost=7000000,          income=2000,    chance="Legendary"},
    {name="Banana",             rarity="Legendary",   cost=9000000,          income=2500,    chance="Legendary"},
    {name="Potato",             rarity="Legendary",   cost=15000000,         income=2700,    chance="Legendary"},
    {name="Amulet Anemone",     rarity="Legendary",   cost=nil,              income=1800,    chance="Friend-o-Tron"},

    -- SECRET
    {name="Strawberry",         rarity="Secret",      cost=30000000,         income=6000,    chance="Secret"},
    {name="Glowshroom",         rarity="Secret",      cost=45000000,         income=8000,    chance="Secret"},
    {name="Beanstalk",          rarity="Secret",      cost=55000000,         income=8000,    chance="Secret"},
    {name="Tomato",             rarity="Secret",      cost=100000000,        income=12000,   chance="Secret"},
    {name="Monsoon Crown",      rarity="Secret",      cost=65000000,         income=6500,    chance="Rain Event"},
    {name="Starfruit",          rarity="Secret",      cost=130000000,        income=13000,   chance="Not rollable"},
    {name="Mooncap",            rarity="Secret",      cost=nil,              income=nil,     chance="?"},

    -- PRISMATIC
    {name="Apple",              rarity="Prismatic",   cost=500000000,        income=20000,   chance="Prismatic"},
    {name="Cherry Blossom",     rarity="Prismatic",   cost=1500000000,       income=30000,   chance="Prismatic"},
    {name="Blood Orange",       rarity="Prismatic",   cost=1200000000,       income=35000,   chance="Prismatic"},
    {name="Garlic",             rarity="Prismatic",   cost=5500000000,       income=50000,   chance="Prismatic"},
    {name="Iron Fern",          rarity="Prismatic",   cost=4000000000,       income=42500,   chance="Prismatic"},
    {name="Frostbell",          rarity="Prismatic",   cost=1750000000,       income=32000,   chance="Blizzard Event"},
    {name="Hex Sprout",         rarity="Prismatic",   cost=7500000000,       income=55000,   chance="Not rollable"},
    {name="Pineapple",          rarity="Prismatic",   cost=800000000,        income=40000,   chance="Seed Pack"},
    {name="Rush Root",          rarity="Prismatic",   cost=850000000,        income=45000,   chance="Plant Rush"},
    {name="Galaxy Hibiscus",    rarity="Prismatic",   cost=1550000000,       income=32000,   chance="Alien Event"},
    {name="Duoheart Daisy",     rarity="Prismatic",   cost=nil,              income=nil,     chance="?"},
    {name="Crimson Higanbana",  rarity="Prismatic",   cost=35000000000000,   income=225000,  chance="Not rollable"},
    {name="Glasswing",          rarity="Prismatic",   cost=nil,              income=nil,     chance="?"},

    -- DIVINE
    {name="Golden Apple",       rarity="Divine",      cost=5000000000,       income=65000,   chance="Divine"},
    {name="Cocoa",              rarity="Divine",      cost=10000000000,      income=70000,   chance="Divine"},
    {name="Crystalberry",       rarity="Divine",      cost=20000000000,      income=88000,   chance="Divine"},
    {name="Amber Wisp",         rarity="Divine",      cost=12500000000,      income=72000,   chance="Fall Event"},
    {name="Admin Bloom",        rarity="Divine",      cost=25000000000,      income=85000,   chance="Admin"},
    {name="Diamond Blossom",    rarity="Divine",      cost=2500000000,       income=55000,   chance="Seed Collector"},
    {name="Dreadcap",           rarity="Divine",      cost=25000000000,      income=95000,   chance="Not rollable"},
    {name="Compost Hydra",      rarity="Divine",      cost=115000000000,     income=125000,  chance="Composter"},
    {name="Horned Melon",       rarity="Divine",      cost=3500000000,       income=80000,   chance="Trucker"},
    {name="Pomegranate",        rarity="Divine",      cost=4000000000,       income=75000,   chance="Seed Pack"},

    -- EXOTIC
    {name="Moonflower",         rarity="Exotic",      cost=70000000000,      income=110000,  chance="Exotic"},
    {name="Passionfruit",       rarity="Exotic",      cost=100000000000,     income=120000,  chance="Exotic"},
    {name="Darkmatter Bramble", rarity="Exotic",      cost=1000000000000,    income=145000,  chance="Blackhole Event"},
    {name="Uranium Reed",       rarity="Exotic",      cost=10000000000000,   income=165000,  chance="Nuclear Event"},
    {name="Muckthorn",          rarity="Exotic",      cost=1500000000000,    income=170000,  chance="Not rollable"},
    {name="Crowned Pear",       rarity="Exotic",      cost=125000000000,     income=135000,  chance="Not rollable"},
    {name="Striped Starfruit",  rarity="Exotic",      cost=120000000000,     income=130000,  chance="Not rollable"},
    {name="Crimson Higanbana",  rarity="Exotic",      cost=35000000000000,   income=225000,  chance="Not rollable"},
    {name="Pepper",             rarity="Exotic",      cost=900000000000,     income=140000,  chance="Exotic"},
    {name="Void Fruit",         rarity="Exotic",      cost=15000000000000,   income=180000,  chance="Exotic"},
    {name="Kiwi",               rarity="Exotic",      cost=60000000000,      income=90000,   chance="Not rollable"},
    {name="Dragonfruit",        rarity="Exotic",      cost=8000000000,       income=350000,  chance="Seed Pack"},
    {name="Truckers Delight",   rarity="Exotic",      cost=nil,              income=160000,  chance="Trucker Event"},
    {name="Heartvine Bloom",    rarity="Exotic",      cost=nil,              income=nil,     chance="Friend-o-Tron"},

    -- TRANSCENDED
    {name="Durian",             rarity="Transcended", cost=100000000000000,  income=380000,  chance="Transcended"},
    {name="Ghost Pepper",       rarity="Transcended", cost=275000000000000,  income=500000,  chance="Transcended"},
    {name="Papaya",             rarity="Transcended", cost=150000000000000,  income=450000,  chance="Transcended"},
    {name="Ember Fruit",        rarity="Transcended", cost=350000000000000,  income=525000,  chance="Transcended"},
    {name="Admin Rose",         rarity="Transcended", cost=375000000000000,  income=575000,  chance="Admin"},
    {name="Soulbound Orchid",   rarity="Transcended", cost=275000000000000,  income=500000,  chance="Friend Machine"},
    {name="Muck Monarch",       rarity="Transcended", cost=200000000000000,  income=525000,  chance="Not rollable"},
    {name="Heart of Corruption",rarity="Transcended", cost=350000000000000,  income=600000,  chance="Not rollable"},
    {name="Garden Golem",       rarity="Transcended", cost=425000000000000,  income=565000,  chance="Plant Rush"},
    {name="Golden Quillflower", rarity="Transcended", cost=125000000000000,  income=425000,  chance="Not rollable"},
    {name="Aurora Lotus",       rarity="Transcended", cost=750000000000000,  income=750000,  chance="Transcended"},
    {name="Queens Blossom",     rarity="Transcended", cost=nil,              income=nil,     chance="Bee Event"},
    {name="Witherfang",         rarity="Transcended", cost=nil,              income=nil,     chance="?"},
    {name="Garden Devourer",    rarity="Transcended", cost=nil,              income=nil,     chance="Composter"},
}
local SeedByName = {}
for _,s in ipairs(Seeds) do SeedByName[s.name]=s end

-- ─── Gear Data ───────────────────────────────────────────────────────────────

local GearItems = {
    {name="Fire Spray",           cost=1000000000000000, maxStock=1},
    {name="Bubblegum Spray",      cost=250000000000000,  maxStock=1},
    {name="Cosmic Spray",         cost=25000000000000,   maxStock=1},
    {name="Prismatic Fertilizer", cost=25000000000000,   maxStock=1},
    {name="Rainbow Spray",        cost=1000000000000,    maxStock=1},
    {name="Radioactive Spray",    cost=100000000000,     maxStock=1},
    {name="Super Pet Treat",      cost=20000000000,      maxStock=1},
    {name="Super Fertilizer",     cost=15000000000,      maxStock=1},
    {name="Void Spray",           cost=10000000000,      maxStock=1},
    {name="Autumn Spray",         cost=1000000000,       maxStock=1},
    {name="Frozen Spray",         cost=750000000,        maxStock=2},
    {name="Strong Pet Treat",     cost=75000000,         maxStock=1},
    {name="Strong Fertilizer",    cost=50000000,         maxStock=2},
    {name="Wet Spray",            cost=10000000,         maxStock=2},
    {name="Acid Spray",           cost=1000000,          maxStock=3},
    {name="Normal Pet Treat",     cost=1000000,          maxStock=2},
    {name="Normal Fertilizer",    cost=500000,           maxStock=3},
}

-- ─── Settings persistence ────────────────────────────────────────────────────

local SETTINGS_FILE = "buildaringfarm_settings.json"
local HttpService = game:GetService("HttpService")

local function saveSettings()
    local data = {
        autoRoll  = autoRollEnabled,
        autoBuy   = autoBuyEnabled,
        autoGear  = autoGearEnabled,
        autoFert  = autoFertEnabled,
        buyList   = {},
        gearList  = {},
    }
    for name in pairs(autoBuyList) do table.insert(data.buyList, name) end
    for name in pairs(gearBuyList) do table.insert(data.gearList, name) end
    pcall(writefile, SETTINGS_FILE, HttpService:JSONEncode(data))
end

local function loadSettings()
    local ok, raw = pcall(readfile, SETTINGS_FILE)
    if not ok or not raw or raw == "" then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then return end

    if data.autoRoll then autoRollEnabled = true end
    if data.autoBuy  then autoBuyEnabled  = true end
    if data.autoGear then autoGearEnabled = true end
    if data.autoFert then autoFertEnabled = true end

    if type(data.buyList) == "table" then
        for _, name in ipairs(data.buyList) do autoBuyList[name] = true end
    end
    if type(data.gearList) == "table" then
        for _, name in ipairs(data.gearList) do gearBuyList[name] = true end
    end
end

-- ─── State ───────────────────────────────────────────────────────────────────

local autoRollEnabled  = false
local autoBuyEnabled   = false
local autoGearEnabled  = false
local autoFertEnabled  = false
local isBuying = false
local buyLock  = false
local autoBuyList = {}
local gearBuyList = {}
local gearStock   = {}  -- [itemName] = currentStock (0 = out of stock)

loadSettings()  -- load state values; UI toggles synced after UI builds

-- ─── Remotes ─────────────────────────────────────────────────────────────────

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local RollSeeds       = Remotes:WaitForChild("RollSeeds")
local BuySeed         = Remotes:WaitForChild("BuySeed")
local GearTransaction = Remotes:WaitForChild("Gear"):WaitForChild("Transaction")

-- ─── GUI ─────────────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name = "RFGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- helpers
local tw = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local function mkCorner(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 6);return c end
local function mkStroke(p,col,t,a)
    local s=Instance.new("UIStroke",p);s.Color=col or C.border
    s.Thickness=t or 1;s.Transparency=a or 0;return s
end
local function mkLabel(p,txt,col,size,font,xa)
    local l=Instance.new("TextLabel",p);l.BackgroundTransparency=1
    l.Text=txt;l.TextColor3=col or C.white;l.TextSize=size or 13
    l.Font=font or Enum.Font.Gotham;l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Size=UDim2.new(1,0,1,0);return l
end
local function mkBtn(p,txt,col,tcol,size)
    local b=Instance.new("TextButton",p);b.BackgroundColor3=col or C.raised
    b.BorderSizePixel=0;b.Text=txt;b.TextColor3=tcol or C.sub
    b.Font=Enum.Font.Gotham;b.TextSize=size or 11;return b
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
    track.Size=UDim2.new(0,40,0,20)
    track.BackgroundColor3=C.raised
    track.BorderSizePixel=0
    mkCorner(track,10)
    mkStroke(track,C.border,1,0.3)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14)
    knob.Position=UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3=C.muted
    knob.BorderSizePixel=0
    mkCorner(knob,7)

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
win.Size=UDim2.new(0,240,0,0)  -- height set after rows
win.Position=UDim2.new(0,20,0.5,-110)
win.BackgroundColor3=C.bg
win.BackgroundTransparency=0.08
win.BorderSizePixel=0
mkCorner(win,10)
mkStroke(win,C.border,1,0.5)

-- block clicks from passing through to game
local winBlocker=Instance.new("TextButton",win)
winBlocker.Size=UDim2.new(1,0,1,0)
winBlocker.BackgroundTransparency=1
winBlocker.Text=""
winBlocker.ZIndex=0
winBlocker.AutoButtonColor=false

-- header
local header=Instance.new("Frame",win)
header.Size=UDim2.new(1,0,0,44)
header.BackgroundColor3=C.surface
header.BorderSizePixel=0
mkCorner(header,10)
-- patch lower corners of header
local hp=Instance.new("Frame",header)
hp.Size=UDim2.new(1,0,0.5,0);hp.Position=UDim2.new(0,0,0.5,0)
hp.BackgroundColor3=C.surface;hp.BorderSizePixel=0

local titleLbl=Instance.new("TextLabel",header)
titleLbl.Size=UDim2.new(1,-16,1,0);titleLbl.Position=UDim2.new(0,16,0,0)
titleLbl.BackgroundTransparency=1;titleLbl.Text="Build a Ring Farm"
titleLbl.TextColor3=C.white;titleLbl.Font=Enum.Font.GothamBold;titleLbl.TextSize=14
titleLbl.TextXAlignment=Enum.TextXAlignment.Left

draggable(header,win)

-- row builder
local ROW_H, ROW_GAP, START_Y = 48, 1, 45
local rowCount = 0

local function addRow(label, hasConfig, configLabel)
    local y = START_Y + rowCount*(ROW_H+ROW_GAP)
    rowCount += 1

    local sep=Instance.new("Frame",win)
    sep.Size=UDim2.new(1,-24,0,1);sep.Position=UDim2.new(0,12,0,y-1)
    sep.BackgroundColor3=C.border;sep.BorderSizePixel=0;sep.BackgroundTransparency=0.6

    local row=Instance.new("Frame",win)
    row.Size=UDim2.new(1,0,0,ROW_H);row.Position=UDim2.new(0,0,0,y)
    row.BackgroundTransparency=1

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0,100,1,0);lbl.Position=UDim2.new(0,16,0,0)
    lbl.BackgroundTransparency=1;lbl.Text=label
    lbl.TextColor3=C.white;lbl.Font=Enum.Font.GothamBold;lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local track,setToggle,getToggle=mkToggle(row)
    track.Position=UDim2.new(1,-52,0.5,-10)

    local cfgBtn
    if hasConfig then
        cfgBtn=mkBtn(row,configLabel or "Config",C.surface,C.sub,10)
        cfgBtn.Size=UDim2.new(0,44,0,20)
        cfgBtn.Position=UDim2.new(1,-100,0.5,-10)
        mkCorner(cfgBtn,5)
        mkStroke(cfgBtn,C.border,1,0.5)
    end

    return track,setToggle,getToggle,cfgBtn
end

local rollTrack,setRoll,getRoll             = addRow("Auto Roll")
local buyTrack,setBuy,getBuy,buyCfgBtn      = addRow("Auto Buy","Seeds","Seeds")
local gearTrack,setGear,getGear,gearCfgBtn = addRow("Auto Gear",true,"Items")
local fertTrack,setFert,getFert             = addRow("Auto Fert")

-- status + footer
local statusY = START_Y + rowCount*(ROW_H+ROW_GAP) + 4

local sep=Instance.new("Frame",win)
sep.Size=UDim2.new(1,-24,0,1);sep.Position=UDim2.new(0,12,0,statusY-2)
sep.BackgroundColor3=C.border;sep.BorderSizePixel=0;sep.BackgroundTransparency=0.6

local statusRow=Instance.new("Frame",win)
statusRow.Size=UDim2.new(1,0,0,24);statusRow.Position=UDim2.new(0,0,0,statusY+2)
statusRow.BackgroundTransparency=1

local statusDot=Instance.new("Frame",statusRow)
statusDot.Size=UDim2.new(0,6,0,6);statusDot.Position=UDim2.new(0,14,0.5,-3)
statusDot.BackgroundColor3=C.muted;statusDot.BorderSizePixel=0;mkCorner(statusDot,3)

local statusLbl=Instance.new("TextLabel",statusRow)
statusLbl.Size=UDim2.new(1,-30,1,0);statusLbl.Position=UDim2.new(0,26,0,0)
statusLbl.BackgroundTransparency=1;statusLbl.Text="Idle"
statusLbl.TextColor3=C.muted;statusLbl.Font=Enum.Font.Gotham;statusLbl.TextSize=11
statusLbl.TextXAlignment=Enum.TextXAlignment.Left

local footer=Instance.new("TextLabel",win)
footer.Size=UDim2.new(1,-16,0,34);footer.Position=UDim2.new(0,8,0,statusY+24)
footer.BackgroundTransparency=1
footer.Text="made by @Jacksblox\nGet Executors at vanishhub.com"
footer.TextColor3=Color3.fromRGB(190,200,240);footer.Font=Enum.Font.Gotham;footer.TextSize=11
footer.TextXAlignment=Enum.TextXAlignment.Center
footer.LineHeight=1.3

win.Size=UDim2.new(0,240,0,statusY+58)

local function setStatus(txt,col,dotCol)
    statusLbl.Text=txt;statusLbl.TextColor3=col or C.muted
    statusDot.BackgroundColor3=dotCol or C.muted
end

-- ─── Panel Builder ───────────────────────────────────────────────────────────

local function makePanel(title, w, h)
    local p=Instance.new("Frame",gui)
    p.Size=UDim2.new(0,w,0,h)
    p.BackgroundColor3=C.bg
    p.BorderSizePixel=0
    p.Visible=false
    mkCorner(p,10)
    mkStroke(p,C.border,1,0.4)
    -- blocker sits behind everything at ZIndex 1
    local blocker=Instance.new("TextButton",p)
    blocker.Size=UDim2.new(1,0,1,0)
    blocker.BackgroundTransparency=1
    blocker.Text=""
    blocker.ZIndex=1
    blocker.AutoButtonColor=false

    local hdr=Instance.new("Frame",p)
    hdr.Size=UDim2.new(1,0,0,40)
    hdr.BackgroundColor3=C.surface
    hdr.BorderSizePixel=0
    hdr.ZIndex=2
    mkCorner(hdr,10)
    local hpatch=Instance.new("Frame",hdr)
    hpatch.Size=UDim2.new(1,0,0.5,0);hpatch.Position=UDim2.new(0,0,0.5,0)
    hpatch.BackgroundColor3=C.surface;hpatch.BorderSizePixel=0;hpatch.ZIndex=2

    local abar=Instance.new("Frame",hdr)
    abar.Size=UDim2.new(0,3,0,18);abar.Position=UDim2.new(0,12,0.5,-9)
    abar.BackgroundColor3=C.accent;abar.BorderSizePixel=0;abar.ZIndex=3;mkCorner(abar,2)

    local tlbl=Instance.new("TextLabel",hdr)
    tlbl.Size=UDim2.new(1,-60,1,0);tlbl.Position=UDim2.new(0,22,0,0)
    tlbl.BackgroundTransparency=1;tlbl.Text=title
    tlbl.TextColor3=C.white;tlbl.Font=Enum.Font.GothamBold;tlbl.TextSize=13
    tlbl.TextXAlignment=Enum.TextXAlignment.Left;tlbl.ZIndex=3

    local xBtn=Instance.new("TextButton",hdr)
    xBtn.Size=UDim2.new(0,24,0,24);xBtn.Position=UDim2.new(1,-30,0.5,-12)
    xBtn.BackgroundColor3=Color3.fromRGB(55,25,25)
    xBtn.BorderSizePixel=0
    xBtn.Text="X";xBtn.TextColor3=C.red
    xBtn.Font=Enum.Font.GothamBold;xBtn.TextSize=12
    xBtn.ZIndex=4;xBtn.AutoButtonColor=false
    mkCorner(xBtn,5)

    draggable(hdr,p)

    -- all / none buttons
    local allBtn=mkBtn(p,"All",C.surface,C.sub,10)
    allBtn.Size=UDim2.new(0,40,0,20);allBtn.Position=UDim2.new(0,12,0,46)
    allBtn.ZIndex=3
    mkCorner(allBtn,5);mkStroke(allBtn,C.border,1,0.5)

    local noneBtn=mkBtn(p,"None",C.surface,C.sub,10)
    noneBtn.Size=UDim2.new(0,44,0,20);noneBtn.Position=UDim2.new(0,56,0,46)
    noneBtn.ZIndex=3
    mkCorner(noneBtn,5);mkStroke(noneBtn,C.border,1,0.5)

    -- scroll
    local scroll=Instance.new("ScrollingFrame",p)
    scroll.Size=UDim2.new(1,-8,1,-72);scroll.Position=UDim2.new(0,4,0,68)
    scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=2;scroll.ScrollBarImageColor3=C.accent
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.ZIndex=2

    local layout=Instance.new("UIListLayout",scroll)
    layout.Padding=UDim.new(0,2);layout.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",scroll)
    pad.PaddingLeft=UDim.new(0,6);pad.PaddingRight=UDim.new(0,6);pad.PaddingTop=UDim.new(0,4)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
    end)

    local function positionNextTo()
        p.Position=UDim2.new(
            win.Position.X.Scale,
            win.Position.X.Offset+win.AbsoluteSize.X+8,
            win.Position.Y.Scale,
            win.Position.Y.Offset
        )
    end

    return p,scroll,layout,xBtn,allBtn,noneBtn,positionNextTo
end

-- ─── Seed Panel ──────────────────────────────────────────────────────────────

local seedPanel,seedScroll,seedLayout,seedClose,seedAll,seedNone,seedPos = makePanel("Seeds",300,480)
local seedPanelOpen=false
local seedToggles={}

-- only show seeds obtainable from the seed roll
local NOT_FROM_ROLL = {
    ["Not rollable"]=true,["Friend-o-Tron"]=true,["Trucker Event"]=true,
    ["Alien Event"]=true,["Bee Event"]=true,["Plant Rush"]=true,
    ["Seed Pack"]=true,["Seed Collector"]=true,["Composter"]=true,
    ["Friend Machine"]=true,["Trucker"]=true,["?"]=true,
}

local idx=0
for _,rarity in ipairs(RARITY_ORDER) do
    local group={}
    for _,s in ipairs(Seeds) do
        if s.rarity==rarity and not NOT_FROM_ROLL[s.chance] then
            table.insert(group,s)
        end
    end
    if #group==0 then continue end

    -- header
    idx+=1
    local hdr=Instance.new("Frame",seedScroll)
    hdr.Size=UDim2.new(1,0,0,18);hdr.BackgroundTransparency=1;hdr.LayoutOrder=idx
    local hl=mkLabel(hdr,rarity,RARITY_COLOR[rarity],9,Enum.Font.GothamBold)
    hl.TextTransparency=0.2

    for _,seed in ipairs(group) do
        idx+=1
        local row=Instance.new("Frame",seedScroll)
        row.Size=UDim2.new(1,0,0,50);row.BackgroundColor3=C.surface
        row.BorderSizePixel=0;row.LayoutOrder=idx
        mkCorner(row,7)

        local nameL=mkLabel(row,seed.name,RARITY_COLOR[rarity],12,Enum.Font.GothamBold)
        nameL.Size=UDim2.new(1,-50,0,22);nameL.Position=UDim2.new(0,10,0,5)

        local infoL=mkLabel(row,
            "Cost "..fmt(seed.cost).."  ·  "..seed.chance,
            C.muted,9,Enum.Font.Gotham)
        infoL.Size=UDim2.new(1,-50,0,14);infoL.Position=UDim2.new(0,10,0,27)
        infoL.TextTruncate=Enum.TextTruncate.AtEnd

        local ttrack,setT,getT=mkToggle(row)
        ttrack.Size=UDim2.new(0,36,0,18);ttrack.Position=UDim2.new(1,-42,0.5,-9)

        ttrack.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local s=not getT();setT(s);autoBuyList[seed.name]=s or nil;saveSettings()
            end
        end)
        seedToggles[seed.name]={set=setT,get=getT}
    end
end

seedAll.MouseButton1Click:Connect(function()
    for _,s in ipairs(Seeds) do autoBuyList[s.name]=true;if seedToggles[s.name] then seedToggles[s.name].set(true) end end
    saveSettings()
end)
seedNone.MouseButton1Click:Connect(function()
    table.clear(autoBuyList)
    for _,s in ipairs(Seeds) do if seedToggles[s.name] then seedToggles[s.name].set(false) end end
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

local gearPanel,gearScroll,gearLayout,gearClose2,gearAll,gearNone,gearPos = makePanel("Gear Shop",250,0)
local gearPanelOpen=false
local gearToggles={}
local gearStockLabels={}

local gi=0
for _,item in ipairs(GearItems) do
    gi+=1
    local row=Instance.new("Frame",gearScroll)
    row.Size=UDim2.new(1,0,0,50);row.BackgroundColor3=C.surface
    row.BorderSizePixel=0;row.LayoutOrder=gi;mkCorner(row,7)

    local nL=mkLabel(row,item.name,C.white,12,Enum.Font.GothamBold)
    nL.Size=UDim2.new(1,-50,0,22);nL.Position=UDim2.new(0,10,0,5)

    local stockLbl=mkLabel(row,"",C.muted,9,Enum.Font.Gotham)
    stockLbl.Size=UDim2.new(1,-50,0,14);stockLbl.Position=UDim2.new(0,10,0,27)
    stockLbl.Text="Cost "..fmt(item.cost).."  ·  Max "..item.maxStock.."  ·  Checking..."
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

-- fix gear panel height after building
gearLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local h=math.min(gearLayout.AbsoluteContentSize.Y+80,480)
    gearPanel.Size=UDim2.new(0,250,0,h)
    gearScroll.CanvasSize=UDim2.new(0,0,0,gearLayout.AbsoluteContentSize.Y+8)
end)

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
    gearPanel.Position=UDim2.new(
        win.Position.X.Scale, win.Position.X.Offset+win.AbsoluteSize.X+8,
        win.Position.Y.Scale, win.Position.Y.Offset+50
    )
    gearPanel.Visible=true
    gearCfgBtn.BackgroundColor3=C.accent;gearCfgBtn.TextColor3=C.white
end
local function closeGear()
    gearPanelOpen=false;gearPanel.Visible=false
    gearCfgBtn.BackgroundColor3=C.surface;gearCfgBtn.TextColor3=C.sub
end
gearClose2.MouseButton1Click:Connect(closeGear)
gearCfgBtn.MouseButton1Click:Connect(function() if gearPanelOpen then closeGear() else openGear() end end)

-- ─── Toggle Handlers ─────────────────────────────────────────────────────────

-- ─── Apply loaded settings to UI ─────────────────────────────────────────────

if autoRollEnabled then setRoll(true) end
if autoBuyEnabled  then setBuy(true)  end
if autoGearEnabled then setGear(true) end
if autoFertEnabled then setFert(true) end
for name in pairs(autoBuyList) do if seedToggles[name] then seedToggles[name].set(true) end end
for name in pairs(gearBuyList) do if gearToggles[name] then gearToggles[name].set(true) end end

rollTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoRollEnabled=not getRoll();setRoll(autoRollEnabled)
    setStatus(autoRollEnabled and "Rolling" or "Idle",autoRollEnabled and C.accent or C.muted,autoRollEnabled and C.accent or C.muted)
    saveSettings()
end)
buyTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoBuyEnabled=not getBuy();setBuy(autoBuyEnabled)
    saveSettings()
end)
gearTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoGearEnabled=not getGear();setGear(autoGearEnabled)
    saveSettings()
end)

-- ─── Gear Stock Polling ──────────────────────────────────────────────────────
-- Stock is in PlayerGui.MainUI.Menus.GearShopFrame.ScrollingFrame.[Name].GearImage.Rarity
-- Text format: "Stock: X"

local function getStockLabel(itemName)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local frame = pg:FindFirstChild("MainUI")
        and pg.MainUI:FindFirstChild("Menus")
        and pg.MainUI.Menus:FindFirstChild("GearShopFrame")
        and pg.MainUI.Menus.GearShopFrame:FindFirstChild("ScrollingFrame")
        and pg.MainUI.Menus.GearShopFrame.ScrollingFrame:FindFirstChild(itemName)
    if not frame then return nil end
    local img = frame:FindFirstChild("GearImage")
    return img and img:FindFirstChild("Rarity")
end

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
    local stockStr = stock > 0 and ("In Stock: "..stock) or "Out of Stock"
    gearStockLabels[name].Text = "Cost "..fmt(item.cost).."  ·  "..stockStr
    gearStockLabels[name].TextColor3 = stock > 0 and C.green or C.red
end

local function buyGearItem(item)
    for _ = 1, item.maxStock do
        local ok, res = pcall(function() return GearTransaction:InvokeServer(item.name) end)
        if not ok or not res then break end
        task.wait(0.4)
    end
end

local function watchGearShop()
    local pg = player:WaitForChild("PlayerGui")
    local scroll = pg:WaitForChild("MainUI")
        :WaitForChild("Menus")
        :WaitForChild("GearShopFrame")
        :WaitForChild("ScrollingFrame")

    for _, item in ipairs(GearItems) do
        local itemFrame = scroll:FindFirstChild(item.name)
        if not itemFrame then continue end
        local stockLbl = itemFrame:FindFirstChild("GearImage")
            and itemFrame.GearImage:FindFirstChild("Rarity")
        if not stockLbl then continue end

        -- read initial stock immediately
        updateStockLabel(item.name, parseStock(stockLbl))

        -- watch for any change
        stockLbl:GetPropertyChangedSignal("Text"):Connect(function()
            local newStock = parseStock(stockLbl)
            local prev = gearStock[item.name] or 0
            updateStockLabel(item.name, newStock)

            if autoGearEnabled and gearBuyList[item.name] and newStock > 0 then
                task.spawn(function()
                    task.wait(0.3)
                    buyGearItem(item)
                end)
            end
        end)
    end
end

task.spawn(watchGearShop)

-- ─── Toast Notification ──────────────────────────────────────────────────────

local toastFrame = Instance.new("Frame", gui)
toastFrame.Size = UDim2.new(0, 320, 0, 60)
toastFrame.Position = UDim2.new(0.5, -160, 0.42, 0)
toastFrame.BackgroundColor3 = C.bg
toastFrame.BackgroundTransparency = 1
toastFrame.BorderSizePixel = 0
toastFrame.Visible = false
mkCorner(toastFrame, 10)
mkStroke(toastFrame, C.border, 1.2, 0)

local toastSeedName = Instance.new("TextLabel", toastFrame)
toastSeedName.Size = UDim2.new(1, -20, 0, 28)
toastSeedName.Position = UDim2.new(0, 10, 0, 8)
toastSeedName.BackgroundTransparency = 1
toastSeedName.Font = Enum.Font.GothamBold
toastSeedName.TextSize = 20
toastSeedName.TextXAlignment = Enum.TextXAlignment.Center
toastSeedName.TextTransparency = 1

local toastSub = Instance.new("TextLabel", toastFrame)
toastSub.Size = UDim2.new(1, -20, 0, 16)
toastSub.Position = UDim2.new(0, 10, 0, 36)
toastSub.BackgroundTransparency = 1
toastSub.Text = "Seed Purchased"
toastSub.TextColor3 = C.sub
toastSub.Font = Enum.Font.Gotham
toastSub.TextSize = 12
toastSub.TextXAlignment = Enum.TextXAlignment.Center
toastSub.TextTransparency = 1

local toastActive = false

local function showToast(seedName)
    local seed = SeedByName[seedName]
    local col = seed and RARITY_COLOR[seed.rarity] or C.white
    toastSeedName.Text = seedName
    toastSeedName.TextColor3 = col
    toastFrame.Visible = true
    toastActive = true

    -- reset stroke color to rarity
    local s = toastFrame:FindFirstChildWhichIsA("UIStroke")
    if s then s.Color = col end

    local fadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
    TweenService:Create(toastFrame, fadeIn, {BackgroundTransparency=0.1}):Play()
    TweenService:Create(toastSeedName, fadeIn, {TextTransparency=0}):Play()
    TweenService:Create(toastSub, fadeIn, {TextTransparency=0}):Play()

    task.delay(2.2, function()
        local fadeOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
        TweenService:Create(toastFrame, fadeOut, {BackgroundTransparency=1}):Play()
        TweenService:Create(toastSeedName, fadeOut, {TextTransparency=1}):Play()
        TweenService:Create(toastSub, fadeOut, {TextTransparency=1}):Play()
        task.wait(0.5)
        toastFrame.Visible = false
        toastActive = false
    end)
end

-- ─── Auto Buy Seeds ──────────────────────────────────────────────────────────

RollSeeds.OnClientEvent:Connect(function(rolledSeeds)
    if not autoBuyEnabled then return end
    if buyLock then return end
    if type(rolledSeeds)~="table" then return end

    local queue={}
    for slotIndex,seedName in ipairs(rolledSeeds) do
        if type(seedName)=="string" and autoBuyList[seedName] then
            table.insert(queue,{slot=slotIndex,name=seedName})
        end
    end
    if #queue==0 then return end

    buyLock=true;isBuying=true
    task.spawn(function()
        task.wait(0.2)
        for _,entry in ipairs(queue) do
            BuySeed:FireServer(entry.slot)
            showToast(entry.name)
            task.wait(0.8)
        end
        task.wait(0.5)
        isBuying=false;buyLock=false
    end)
end)

-- ─── Gear Poll Loop ──────────────────────────────────────────────────────────
-- Every 2s, check all selected items for stock and buy them

task.spawn(function()
    while true do
        task.wait(2)
        if not autoGearEnabled then continue end
        for _, item in ipairs(GearItems) do
            if not gearBuyList[item.name] then continue end
            if (gearStock[item.name] or 0) > 0 then
                buyGearItem(item)
            end
        end
    end
end)

-- ─── Auto Fertilizer ─────────────────────────────────────────────────────────
-- All logic defined first so fertTrack handler can reference runAutoFert

local UseFertilizer = Remotes:WaitForChild("UseFertilizer")

local FERT_RARITY_RANK = {
    Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,
    Secret=6,Prismatic=7,Divine=8,Exotic=9,Transcended=10
}

-- Mutation quality rank (by spray cost, highest = best)
local MUTATION_RANK = {
    Fire=10, Bubblegum=9, Cosmic=8, Rainbow=7, Radioactive=6,
    Void=5, Autumn=4, Frozen=3, Wet=2, Acid=1, Normal=0, Farm=0
}

-- Floor multiplier cache: [floorKey] = EarningsMultiplier
local floorMultipliers = {}
-- HarvestedCrops: [Name|FloorKey|Mutation] = {mult, level} — best per combo
local harvestedData = {}
-- Plants: individual plant data keyed by plot ID
local plantsData = {}  -- [plotId] = {PlantName, PlantLevel, PlantMutation, FertilizerBoostRemaining, ...}

local function loadGCPlantData()
    local ok, gc = pcall(getgc, true)
    if not ok then return end
    local seen = {}
    for _, obj in ipairs(gc) do
        if type(obj) ~= "table" or seen[obj] then continue end
        seen[obj] = true

        pcall(function()
            -- HarvestedCrops entries: {Name, Level, Mutation, EarningsMultiplier, FloorKey, Quantity}
            if type(obj.Name)=="string" and type(obj.Level)=="number" and
               type(obj.Mutation)=="string" and type(obj.EarningsMultiplier)=="number" and
               type(obj.FloorKey)=="string" then
                local fk = obj.FloorKey
                if not floorMultipliers[fk] then
                    floorMultipliers[fk] = obj.EarningsMultiplier
                end
                local key = obj.Name.."|"..fk.."|"..obj.Mutation
                if not harvestedData[key] then
                    harvestedData[key] = {mult=obj.EarningsMultiplier, level=obj.Level, mutation=obj.Mutation, name=obj.Name, floor=fk}
                end
            end

            -- Individual Plants entries: {PlantName, PlantLevel, PlantMutation, PlantStage, ...}
            if type(obj.PlantName)=="string" and type(obj.PlantLevel)=="number" and
               type(obj.PlantMutation)=="string" then
                -- store by content since we don't have the key here
                local entry = {
                    name = obj.PlantName,
                    level = obj.PlantLevel,
                    mutation = obj.PlantMutation,
                    stage = obj.PlantStage or 0,
                    maxStages = obj.PlantMaxStages or 1,
                    fullyGrown = obj.PlantFullyGrown or false,
                    fertBoost = obj.FertilizerBoostRemaining or 0,
                }
                -- key by name+mutation to dedupe
                local pk = obj.PlantName.."|"..obj.PlantMutation.."|"..(obj.PlantLevel or 0)
                if not plantsData[pk] then plantsData[pk] = entry end
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

local function scoreSinglePlant(plantModel)
    -- each plant has numbered stage sub-models (1, 2, 3...)
    -- a mutation = ANY stage has a MutationVFX child (it's binary, 0 or 1)
    local stages = 0
    local hasMutation = false
    for _, child in ipairs(plantModel:GetChildren()) do
        if tonumber(child.Name) then
            stages += 1
            for _, sub in ipairs(child:GetChildren()) do
                if sub.Name:lower():find("mutation") then
                    hasMutation = true
                end
            end
        end
    end
    return stages, hasMutation and 1 or 0
end

local function getFloorKey(dirtPath)
    -- extract FloorX from path, default to Floor1 if no FloorX prefix
    local floor = dirtPath:match("(Floor%d+)%.FarmPlot")
    return floor or "Floor1"
end

local function scoreDirt(dirtPart)
    local plantName = nil
    local plantCount = 0
    for _, child in ipairs(dirtPart:GetChildren()) do
        if child:IsA("Model") then
            if not plantName then plantName = child.Name end
            plantCount += 1
        end
    end
    if not plantName or plantCount == 0 then return nil end

    local seed = SeedByName[plantName]
    local baseIncome = seed and seed.income or 1
    local floorKey = getFloorKey(dirtPart:GetFullName())
    local floorMult = floorMultipliers[floorKey] or 1

    -- find the best matching HarvestedCrops entry for this plant+floor
    local bestScore = 0
    local bestMut = "None"
    local bestLevel = 58
    for key, entry in pairs(harvestedData) do
        if entry.name == plantName and entry.floor == floorKey then
            local mutRank = MUTATION_RANK[entry.mutation] or 0
            local s = baseIncome * entry.mult * (1 + mutRank * 0.15) * (1 + (entry.level - 50) * 0.01)
            if s > bestScore then
                bestScore = s
                bestMut = entry.mutation
                bestLevel = entry.level
            end
        end
    end

    if bestScore == 0 then
        -- fallback: base income × floor multiplier
        bestScore = baseIncome * floorMult
    end

    return bestScore, plantName, plantCount, bestMut
end

local function getPlantedDirts()
    local ok, plotName = pcall(function()
        return Remotes.Plot.GetPlot:InvokeServer()
    end)
    if not ok or not plotName then return {} end

    local plotModel = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Plots")
        and workspace.Map.Plots:FindFirstChild(tostring(plotName))
    if not plotModel then return {} end

    local seenInstances = {}  -- deduplicate by instance reference, NOT path
    local dirts = {}

    for _, obj in ipairs(plotModel:GetDescendants()) do
        if obj.Name == "Dirt" and obj:IsA("BasePart") and not seenInstances[obj] then
            local parentName = obj.Parent and obj.Parent.Name or ""
            if not parentName:match("^Plot%d+$") then continue end
            seenInstances[obj] = true

            local floorKey = obj:GetFullName():match("(Floor%d+)%.FarmPlot") or "Floor1"
            local score, plantName, plantCount, bestMut = scoreDirt(obj)
            if score and plantName then
                table.insert(dirts, {part=obj, plant=plantName, score=score, count=plantCount, mutations=bestMut, floor=floorKey})
            end
        end
    end

    table.sort(dirts, function(a,b) return a.score > b.score end)
    return dirts
end

local function getFertTool(key)
    -- find tool in backpack or character
    local char = player.Character
    local backpack = player:WaitForChild("Backpack")
    for _, t in ipairs(backpack:GetChildren()) do
        if t:GetAttribute("gearKey") == key then return t end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("gearKey") == key then return t end
        end
    end
    return nil
end

local function equipFert(key)
    local char = player.Character
    if not char then return nil end
    local tool = getFertTool(key)
    if tool and tool.Parent ~= char then
        tool.Parent = char
        task.wait(0.15)
    end
    return tool
end

local function getCount(key)
    -- parse "(xN)" from tool name or count matching tools
    local tool = getFertTool(key)
    if not tool then return 0 end
    local n = tool.Name:match("%(x(%d+)%)")
    return n and tonumber(n) or 1
end

local function runAutoFert()
    local dirts = getPlantedDirts()
    if #dirts == 0 then return end
    local ferts = getFertilizers()
    if #ferts == 0 then return end

    local char = player.Character
    local equippedKey = nil

    for i, dirt in ipairs(dirts) do
        -- pick best fertilizer still available
        local fert = nil
        for _, f in ipairs(ferts) do
            if getFertTool(f.key) then fert = f; break end
        end
        if not fert then break end

        -- equip if needed
        if equippedKey ~= fert.key then
            local tool = getFertTool(fert.key)
            if tool and char then
                tool.Parent = char
                task.wait(0.25)
            end
            equippedKey = fert.key
        end

        local tool = getFertTool(fert.key)
        if not tool then equippedKey = nil; continue end

        pcall(function() UseFertilizer:FireServer(dirt.part) end)
        task.wait(0.4)
    end

    -- unequip
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("gearKey") then
                t.Parent = player:WaitForChild("Backpack")
            end
        end
    end
end

fertTrack.InputBegan:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    autoFertEnabled=not getFert();setFert(autoFertEnabled)
    if autoFertEnabled then task.spawn(runAutoFert) end
end)

task.spawn(function()
    while true do
        task.wait(300)
        if autoFertEnabled then runAutoFert() end
    end
end)

-- ─── Auto Roll Loop ──────────────────────────────────────────────────────────

local ROLL_INTERVAL = 1
local lastRoll = 0

RunService.Heartbeat:Connect(function()
    if not autoRollEnabled or isBuying then return end
    local now=tick()
    if now-lastRoll>=ROLL_INTERVAL then
        lastRoll=now
        RollSeeds:FireServer()
    end
end)
