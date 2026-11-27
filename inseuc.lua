-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Make sure the character is fully loaded
local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)
	character = char
end)

-- Settings & State
local cooldown = 0.5

-- Dropdown lists
local bugTypes = {
	"Ant",
	"Pillbug",
	"Giant Pillbug",
	"Caterpillar",
	"Cricket",
	"Stag Beetle",
	"Centipede",
	"Sand Scorpion"
}

local breakableTypes = {
	"Acorn",
	"Cocoon",
	"Sugar Cube"
}

local trackedTargets = {
	orb = {},
	sandorb = {},
	voidorb = {},
	feastcoin = {},
	bug = {},
	boss = {},
	breakable = {}
}

-- Anti-stuck blacklist cache
local blacklistedTargets = {}

-- Word-based name matching so "ant" matches "Ant" / "AntWorker" but not "Plant" or "Giant"
local function nameTokens(name)
	local spaced = name:gsub("(%l)(%u)", "%1 %2")
	local tokens, joined = {}, ""
	for word in spaced:lower():gmatch("%a+") do
		table.insert(tokens, word)
		joined = joined .. word
	end
	return tokens, joined
end

local function nameMatches(name, keyword)
	local key = keyword:lower():gsub("%s+", "")
	local tokens, joined = nameTokens(name)
	if joined == key then return true end
	for _, t in ipairs(tokens) do
		if t == key or t == key .. "s" then return true end
	end
	return false
end

local bugKeywords = {"centipede", "sandscorpion", "ant", "pillbug", "giantpillbug", "caterpillar", "cricket", "stagbeetle"}

local function isBugName(name)
	for _, kw in ipairs(bugKeywords) do
		if nameMatches(name, kw) then return true end
	end
	return false
end

local function registerObject(obj)
	if Players:GetPlayerFromCharacter(obj) or (obj.Parent and Players:GetPlayerFromCharacter(obj.Parent)) then
		return
	end

	local nameLower = obj.Name:lower()
	local cleanName = nameLower:gsub("%s+", "")
	local category = nil

	-- The updated Feast fruit spawns as Workspace.FeastFruit.FeastFruit.Bubble.
	-- Track only Bubble parts that are actually inside the FeastFruit container.
	if obj:IsA("BasePart") and obj.Name == "Bubble" then
		local node = obj.Parent
		while node and node ~= Workspace do
			if node.Name == "FeastFruit" then
				category = "feastcoin"
				break
			end
			node = node.Parent
		end
	end

	if cleanName:find("level", 1, true) or cleanName:find("+", 1, true) or cleanName:find("text", 1, true) then
		return
	end

	if category == "feastcoin" or cleanName:find("feastcoin", 1, true) or cleanName:find("feastcoins", 1, true) then
		category = "feastcoin"
	elseif cleanName:find("sandorb", 1, true) then
		category = "sandorb"
	elseif cleanName:find("voidorb", 1, true) then
		category = "voidorb"
	elseif cleanName:find("orb", 1, true) and not cleanName:find("orbit", 1, true) then
		category = "orb"
	elseif cleanName:find("emperorscorpion", 1, true) then
		category = "boss"
	elseif isBugName(obj.Name) then
		category = "bug"
	elseif cleanName:find("acorn", 1, true)
		or cleanName:find("cocoon", 1, true)
		or cleanName:find("sugarcube", 1, true) then
		category = "breakable"
	end

	if not category then return end

	if obj:IsA("BasePart") or obj:IsA("Model") then
		trackedTargets[category][obj] = true
	end
end

local function unregisterObject(obj)
	for _, list in pairs(trackedTargets) do
		list[obj] = nil
	end
	blacklistedTargets[obj] = nil
end

task.spawn(function()
	task.wait(1.5)
	local descendants = Workspace:GetDescendants()
	for i, obj in ipairs(descendants) do
		registerObject(obj)
		if i % 1500 == 0 then
			task.wait()
		end
	end
end)

Workspace.DescendantAdded:Connect(registerObject)
Workspace.DescendantRemoving:Connect(unregisterObject)

task.wait(0.5)

-- Safe UI container loader (Synapse, Delta, mobile executors & PlayerGui)
local parentGui = nil
pcall(function()
	if syn and syn.protect_gui then
		local sg = Instance.new("ScreenGui")
		syn.protect_gui(sg)
		parentGui = sg
	elseif gethui then
		parentGui = gethui()
	else
		parentGui = CoreGui
	end
end)

if not parentGui then
	parentGui = player:WaitForChild("PlayerGui")
end

if parentGui:FindFirstChild("DAUSHUB") then
	parentGui.DAUSHUB:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DAUSHUB"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- Floating toggle button (opens the window again)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
ToggleBtn.TextColor3 = Color3.fromRGB(180, 130, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 13
ToggleBtn.Text = "DAUS\nHUB"
ToggleBtn.ZIndex = 10
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 14)

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(160, 90, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 460)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui

local MainScale = Instance.new("UIScale")
MainScale.Parent = MainFrame
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(140, 70, 255)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex = 6
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 300, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ DAUSHUB | Insect Evolution"
Title.TextColor3 = Color3.fromRGB(240, 230, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = TopBar

local SubInfo = Instance.new("TextLabel")
SubInfo.Size = UDim2.new(0, 120, 1, 0)
SubInfo.Position = UDim2.new(1, -250, 0, 0)
SubInfo.BackgroundTransparency = 1
SubInfo.Text = "🟢 PC / Mobile"
SubInfo.TextColor3 = Color3.fromRGB(130, 220, 150)
SubInfo.Font = Enum.Font.GothamMedium
SubInfo.TextSize = 11
SubInfo.TextXAlignment = Enum.TextXAlignment.Right
SubInfo.ZIndex = 6
SubInfo.Parent = TopBar

-- Close button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Text = "X"
CloseBtn.ZIndex = 10
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

-- Minimize button (-)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -72, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Text = "-"
MinBtn.ZIndex = 10
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Sidebar
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 140, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
Sidebar.BorderSizePixel = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 240)
Sidebar.ScrollBarThickness = 0
Sidebar.ZIndex = 6
Sidebar.Parent = MainFrame

-- Content panel with auto layout
local ContentPanel = Instance.new("ScrollingFrame")
ContentPanel.Size = UDim2.new(1, -152, 1, -126)
ContentPanel.Position = UDim2.new(0, 148, 0, 122)
ContentPanel.BackgroundTransparency = 1
ContentPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentPanel.ScrollBarThickness = 4
ContentPanel.ZIndex = 6
ContentPanel.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.Parent = ContentPanel

local activeDropdowns = {}

local function closeAllDropdowns()
	for _, drop in ipairs(activeDropdowns) do
		drop.Visible = false
	end
end

-- Tabs and pages
local function makePage()
	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -152, 1, -126)
	page.Position = UDim2.new(0, 148, 0, 122)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 4
	page.ZIndex = 6
	page.Visible = false
	page.Parent = MainFrame

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = page
	return page
end

local pages = {
	Combat = ContentPanel,
	Collect = makePage(),
	Movement = makePage(),
	Player = makePage(),
	Settings = makePage(),
}
local currentPanel = pages.Combat

local tabButtons = {}

local function selectTab(name)
	closeAllDropdowns()
	for tabName, page in pairs(pages) do
		page.Visible = (tabName == name)
	end
	for tabName, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (tabName == name) and Color3.fromRGB(120, 50, 220) or Color3.fromRGB(35, 30, 55)
	end
end

local tabList = {
	{"Combat", "⚔ Combat"},
	{"Collect", "💎 Collect"},
	{"Movement", "🏃 Movement"},
	{"Player", "👤 Player"},
	{"Settings", "⚙ Settings"},
}

for i, info in ipairs(tabList) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 36)
	btn.Position = UDim2.new(0, 8, 0, 10 + (i - 1) * 44)
	btn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Text = info[2]
	btn.ZIndex = 7
	btn.Parent = Sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(function()
		selectTab(info[1])
	end)
	tabButtons[info[1]] = btn
end

-- Minimize / reopen
MinBtn.MouseButton1Click:Connect(function()
	closeAllDropdowns()
	MainFrame.Visible = false
	ToggleBtn.Visible = true
end)

local function makeDraggable(guiItem, dragHandle)
	dragHandle = dragHandle or guiItem
	local dragging, dragStart, startPos
	local moved = false

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = guiItem.Position

			closeAllDropdowns()

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local scaleObj = guiItem:FindFirstChildOfClass("UIScale")
			local sc = scaleObj and scaleObj.Scale or 1
			local delta = (input.Position - dragStart) / sc
			guiItem.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
			closeAllDropdowns()
		end
	end)
end

makeDraggable(MainFrame, TopBar)
makeDraggable(ToggleBtn)

local function makeFeatureToggle(labelText, orderVal)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	row.LayoutOrder = orderVal
	row.ZIndex = 7
	row.Parent = currentPanel
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(220, 215, 240)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 8
	label.Parent = row

	local toggleBg = Instance.new("TextButton")
	toggleBg.Size = UDim2.new(0, 40, 0, 20)
	toggleBg.Position = UDim2.new(1, -48, 0.5, -10)
	toggleBg.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
	toggleBg.Text = ""
	toggleBg.ZIndex = 8
	toggleBg.Parent = row
	Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(0, 10)

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(0, 16, 0, 16)
	indicator.Position = UDim2.new(0, 2, 0.5, -8)
	indicator.BackgroundColor3 = Color3.fromRGB(150, 140, 180)
	indicator.ZIndex = 9
	indicator.Parent = toggleBg
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 8)

	local active = false
	toggleBg.MouseButton1Click:Connect(function()
		active = not active
		if active then
			toggleBg.BackgroundColor3 = Color3.fromRGB(130, 50, 230)
			indicator.Position = UDim2.new(1, -18, 0.5, -8)
			indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			toggleBg.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
			indicator.Position = UDim2.new(0, 2, 0.5, -8)
			indicator.BackgroundColor3 = Color3.fromRGB(150, 140, 180)
		end
	end)

	return function() return active end
end

local function makeMultiDropdown(titleText, itemsTable, orderVal, emptyLabel)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -8, 0, 44)
	container.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	container.LayoutOrder = orderVal
	container.ZIndex = 7
	container.Parent = currentPanel
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(220, 215, 240)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.ZIndex = 8
	label.Parent = container

	local selectBtn = Instance.new("TextButton")
	selectBtn.Size = UDim2.new(0, 140, 0, 28)
	selectBtn.Position = UDim2.new(1, -148, 0.5, -14)
	selectBtn.BackgroundColor3 = Color3.fromRGB(45, 38, 65)
	selectBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.TextSize = 11
	selectBtn.Text = (emptyLabel or "All") .. " ▾"
	selectBtn.ZIndex = 8
	selectBtn.Parent = container
	Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

	local dropList = Instance.new("ScrollingFrame")
	dropList.Size = UDim2.new(0, 140, 0, math.min(#itemsTable * 26, 120))
	dropList.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
	dropList.BorderSizePixel = 0
	dropList.CanvasSize = UDim2.new(0, 0, 0, #itemsTable * 26)
	dropList.ScrollBarThickness = 3
	dropList.Visible = false
	dropList.ZIndex = 100
	dropList.Parent = ScreenGui
	Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 6)
	Instance.new("UIStroke", dropList).Color = Color3.fromRGB(150, 70, 255)

	table.insert(activeDropdowns, dropList)

	local selected = {}

	local function refreshText()
		local n = 0
		for _ in pairs(selected) do n = n + 1 end
		selectBtn.Text = (n == 0 and (emptyLabel or "All") or (n .. " selected")) .. " ▾"
	end

	for i, itemName in ipairs(itemsTable) do
		local itemBtn = Instance.new("TextButton")
		itemBtn.Size = UDim2.new(1, 0, 0, 26)
		itemBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		itemBtn.BackgroundTransparency = 1
		itemBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
		itemBtn.Font = Enum.Font.GothamMedium
		itemBtn.TextSize = 11
		itemBtn.Text = "[ ] " .. itemName
		itemBtn.ZIndex = 101
		itemBtn.Parent = dropList

		itemBtn.MouseButton1Click:Connect(function()
			selected[itemName] = (not selected[itemName]) or nil
			if selected[itemName] then
				itemBtn.Text = "[x] " .. itemName
				itemBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
			else
				itemBtn.Text = "[ ] " .. itemName
				itemBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
			end
			refreshText()
		end)
	end

	RunService.RenderStepped:Connect(function()
		if dropList.Visible and selectBtn and selectBtn.Parent then
			local absPos = selectBtn.AbsolutePosition
			local absSize = selectBtn.AbsoluteSize
			dropList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
			dropList.Size = UDim2.new(0, absSize.X, 0, dropList.Size.Y.Offset)
		end
	end)

	selectBtn.MouseButton1Click:Connect(function()
		local currentState = dropList.Visible
		closeAllDropdowns()
		dropList.Visible = not currentState
	end)

	-- Returns the checked names; an empty list means "all"
	return function()
		local list = {}
		for _, name in ipairs(itemsTable) do
			if selected[name] then table.insert(list, name) end
		end
		return list
	end
end

local function makeStepper(prefix, orderVal, initial, minV, maxV, stepV, onChange)
	local value = initial

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 56)
	frame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	frame.LayoutOrder = orderVal
	frame.ZIndex = 7
	frame.Parent = currentPanel
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Position = UDim2.new(0, 10, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = prefix .. ": " .. value
	label.TextColor3 = Color3.fromRGB(200, 200, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 8
	label.Parent = frame

	local function makeBtn(text, xPos, delta)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 75, 0, 24)
		btn.Position = xPos
		btn.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.ZIndex = 8
		btn.Parent = frame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			value = math.clamp(value + delta, minV, maxV)
			label.Text = prefix .. ": " .. value
			if onChange then onChange(value) end
		end)
	end

	makeBtn("-" .. stepV, UDim2.new(0, 10, 0, 26), -stepV)
	makeBtn("+" .. stepV, UDim2.new(1, -85, 0, 26), stepV)

	return function() return value end
end

local function makeTextInput(titleText, orderVal, placeholder)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 66)
	frame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	frame.LayoutOrder = orderVal
	frame.ZIndex = 7
	frame.Parent = currentPanel
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 22)
	label.Position = UDim2.new(0, 10, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = titleText
	label.TextColor3 = Color3.fromRGB(220, 215, 240)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 8
	label.Parent = frame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -20, 0, 28)
	box.Position = UDim2.new(0, 10, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(45, 38, 65)
	box.TextColor3 = Color3.fromRGB(230, 220, 255)
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = Color3.fromRGB(130, 120, 160)
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 11
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 8
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	return function() return box.Text end
end

-- Build controls
-- Combat tab
currentPanel = pages.Combat
local autoBoss = makeFeatureToggle("Auto Mini Boss (Emperor Scorpion)", 1)
local autoBugs = makeFeatureToggle("Auto Farm Bugs", 2)
local getBugSel = makeMultiDropdown("Bug Types (none = all)", bugTypes, 3)
local autoPriority = makeFeatureToggle("Prioritize Highest-Tier Bugs", 4)
local autoBreakables = makeFeatureToggle("Auto Farm Breakables", 5)
local getBreakSel = makeMultiDropdown("Breakables (none = all)", breakableTypes, 6)
local autoTweenToggle = makeFeatureToggle("Smooth Tween Movement Mode", 7)
local autoSkill = makeFeatureToggle("Auto Skills (spam, no waiting)", 8)
local getSkillKeys = makeMultiDropdown("Skill Keys (PC)", {"Q", "E", "R", "F", "Z", "X", "C", "V", "1", "2", "3", "4"}, 9, "None")
local getSkillButtons = makeTextInput("On-screen Skill Buttons (names, comma separated)", 10, "e.g. Skill1, Skill2, Ability")
local getSkillInterval = makeStepper("Skill Interval (ms)", 11, 300, 50, 3000, 50)
local skillOnlyFighting = makeFeatureToggle("Skills only while fighting a target", 12)
local autoAtkSpeed = makeFeatureToggle("Attack Speed Boost (auto-find)", 13)
local getAtkMult = makeStepper("Attack Speed Multiplier (x)", 14, 2, 1, 20, 0.5)

-- Collect tab
currentPanel = pages.Collect
local autoOrbs = makeFeatureToggle("Auto Orbs", 1)
local autoSandOrbs = makeFeatureToggle("Auto SandOrbs", 2)
local autoVoidOrbs = makeFeatureToggle("Auto VoidOrbs", 3)
local autoFeastCoins = makeFeatureToggle("Auto Feast Coins", 4)
local autoFeastCycle = makeFeatureToggle("Auto Feast Cycle (collect 10 > plate > eat x10)", 5)

-- Feast Cycle status box (shared with the status strip and the cycle logic at the bottom)
local feastCycleStatus, feastCycleCount = "idle", "0/10"
local FeastInfoLabel
do
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 52)
	frame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	frame.LayoutOrder = 6
	frame.ZIndex = 7
	frame.Parent = currentPanel
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	FeastInfoLabel = Instance.new("TextLabel")
	FeastInfoLabel.Size = UDim2.new(1, -20, 1, -8)
	FeastInfoLabel.Position = UDim2.new(0, 10, 0, 4)
	FeastInfoLabel.BackgroundTransparency = 1
	FeastInfoLabel.TextColor3 = Color3.fromRGB(180, 205, 235)
	FeastInfoLabel.Font = Enum.Font.GothamMedium
	FeastInfoLabel.TextSize = 11
	FeastInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
	FeastInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
	FeastInfoLabel.TextWrapped = true
	FeastInfoLabel.ZIndex = 8
	FeastInfoLabel.Parent = frame
end

local function refreshFeastInfo()
	if FeastInfoLabel then
		FeastInfoLabel.Text = "Feast Cycle: " .. feastCycleStatus .. "\nPlayer fruit: " .. feastCycleCount
	end
end
refreshFeastInfo()

-- Movement tab
currentPanel = pages.Movement
local autoSpeed = makeFeatureToggle("Speed Boost (WalkSpeed)", 1)
local getSpeedValue = makeStepper("Walk Speed", 2, 50, 16, 300, 10)
local autoSpeedCF = makeFeatureToggle("Speed: CFrame Mode (if WalkSpeed resets)", 3)
local autoFly = makeFeatureToggle("Fly (look + move to steer)", 4)
local getFlySpeed = makeStepper("Fly Speed", 5, 60, 10, 300, 10)

-- Player tab
currentPanel = pages.Player
local autoRespawn = makeFeatureToggle("Auto Respawn & Continue", 2)
local autoFps = makeFeatureToggle("Low Graphics Mode (FPS Boost)", 3)
local autoClickBtns = makeFeatureToggle("Auto Click Buttons (upgrade / trait / evolve)", 4)
local getClickNames = makeTextInput("Button Names to Click (comma separated)", 5, "e.g. Upgrade, Evolve, Claim")

-- Status strip (always visible above the pages)
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -156, 0, 64)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
StatusFrame.Position = UDim2.new(0, 148, 0, 52)
StatusFrame.ZIndex = 7
StatusFrame.Parent = MainFrame
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 1, 0)
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Target: idle\nDone: 0  |  Time: 00:00:00"
StatusLabel.TextColor3 = Color3.fromRGB(180, 230, 190)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.ZIndex = 8
StatusLabel.Parent = StatusFrame

-- UI size (auto-fits small phone screens in landscape)
currentPanel = pages.Settings
local applyUiScale
local getUiScale = makeStepper("UI Size (%)", 4, 100, 50, 130, 10, function()
	if applyUiScale then applyUiScale() end
end)

applyUiScale = function()
	local cam = Workspace.CurrentCamera
	local view = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local auto = math.min(1, (view.X - 16) / 540, (view.Y - 16) / 460)
	MainScale.Scale = math.clamp(auto * getUiScale() / 100, 0.4, 1.3)
end
applyUiScale()

do
	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyUiScale)
	end
end

-- Max time per target + skip
local TimeFrame = Instance.new("Frame")
TimeFrame.Size = UDim2.new(1, -8, 0, 88)
TimeFrame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
TimeFrame.LayoutOrder = 2
TimeFrame.ZIndex = 7
TimeFrame.Parent = pages.Settings
Instance.new("UICorner", TimeFrame).CornerRadius = UDim.new(0, 8)

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, 0, 0, 22)
TimeLabel.Position = UDim2.new(0, 10, 0, 4)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "Max Time Per Target: 30s"
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
TimeLabel.Font = Enum.Font.GothamMedium
TimeLabel.TextSize = 12
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
TimeLabel.ZIndex = 8
TimeLabel.Parent = TimeFrame

local TimeMinus = Instance.new("TextButton")
TimeMinus.Size = UDim2.new(0, 75, 0, 24)
TimeMinus.Position = UDim2.new(0, 10, 0, 26)
TimeMinus.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
TimeMinus.Text = "-5s"
TimeMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeMinus.Font = Enum.Font.GothamBold
TimeMinus.TextSize = 11
TimeMinus.ZIndex = 8
TimeMinus.Parent = TimeFrame
Instance.new("UICorner", TimeMinus).CornerRadius = UDim.new(0, 6)

local TimePlus = Instance.new("TextButton")
TimePlus.Size = UDim2.new(0, 75, 0, 24)
TimePlus.Position = UDim2.new(1, -85, 0, 26)
TimePlus.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
TimePlus.Text = "+5s"
TimePlus.TextColor3 = Color3.fromRGB(255, 255, 255)
TimePlus.Font = Enum.Font.GothamBold
TimePlus.TextSize = 11
TimePlus.ZIndex = 8
TimePlus.Parent = TimeFrame
Instance.new("UICorner", TimePlus).CornerRadius = UDim.new(0, 6)

local SkipBtn = Instance.new("TextButton")
SkipBtn.Size = UDim2.new(0.5, -15, 0, 26)
SkipBtn.Position = UDim2.new(0, 10, 0, 56)
SkipBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 220)
SkipBtn.Text = "Skip Target"
SkipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SkipBtn.Font = Enum.Font.GothamBold
SkipBtn.TextSize = 11
SkipBtn.ZIndex = 8
SkipBtn.Parent = TimeFrame
Instance.new("UICorner", SkipBtn).CornerRadius = UDim.new(0, 6)

local IgnoreBtn = Instance.new("TextButton")
IgnoreBtn.Size = UDim2.new(0.5, -15, 0, 26)
IgnoreBtn.Position = UDim2.new(0.5, 5, 0, 56)
IgnoreBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 80)
IgnoreBtn.Text = "Ignore This Name"
IgnoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IgnoreBtn.Font = Enum.Font.GothamBold
IgnoreBtn.TextSize = 11
IgnoreBtn.ZIndex = 8
IgnoreBtn.Parent = TimeFrame
Instance.new("UICorner", IgnoreBtn).CornerRadius = UDim.new(0, 6)


-- Cooldown adjuster
local CDFrame = Instance.new("Frame")
CDFrame.Size = UDim2.new(1, -8, 0, 56)
CDFrame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
CDFrame.LayoutOrder = 1
CDFrame.ZIndex = 7
CDFrame.Parent = pages.Settings
Instance.new("UICorner", CDFrame).CornerRadius = UDim.new(0, 8)

local CDLabel = Instance.new("TextLabel")
CDLabel.Size = UDim2.new(1, 0, 0, 22)
CDLabel.Position = UDim2.new(0, 10, 0, 4)
CDLabel.BackgroundTransparency = 1
CDLabel.Text = "Cooldown: " .. tostring(cooldown) .. "s"
CDLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
CDLabel.Font = Enum.Font.GothamMedium
CDLabel.TextSize = 12
CDLabel.TextXAlignment = Enum.TextXAlignment.Left
CDLabel.ZIndex = 8
CDLabel.Parent = CDFrame

local Minus = Instance.new("TextButton")
Minus.Size = UDim2.new(0, 75, 0, 24)
Minus.Position = UDim2.new(0, 10, 0, 26)
Minus.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
Minus.Text = "-0.05s"
Minus.TextColor3 = Color3.fromRGB(255, 255, 255)
Minus.Font = Enum.Font.GothamBold
Minus.TextSize = 11
Minus.ZIndex = 8
Minus.Parent = CDFrame
Instance.new("UICorner", Minus).CornerRadius = UDim.new(0, 6)

local Plus = Instance.new("TextButton")
Plus.Size = UDim2.new(0, 75, 0, 24)
Plus.Position = UDim2.new(1, -85, 0, 26)
Plus.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
Plus.Text = "+0.05s"
Plus.TextColor3 = Color3.fromRGB(255, 255, 255)
Plus.Font = Enum.Font.GothamBold
Plus.TextSize = 11
Plus.ZIndex = 8
Plus.Parent = CDFrame
Instance.new("UICorner", Plus).CornerRadius = UDim.new(0, 6)

Minus.MouseButton1Click:Connect(function()
	cooldown = math.max(0.01, math.floor((cooldown - 0.05) * 100 + 0.5) / 100)
	CDLabel.Text = "Cooldown: " .. tostring(cooldown) .. "s"
end)

Plus.MouseButton1Click:Connect(function()
	cooldown = math.min(5.0, math.floor((cooldown + 0.05) * 100 + 0.5) / 100)
	CDLabel.Text = "Cooldown: " .. tostring(cooldown) .. "s"
end)

selectTab("Combat")

-- Floating button only reopens the window
ToggleBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	closeAllDropdowns()
end)

local forceRetarget = false  -- set when the character dies so the loop picks a fresh target
local skipRequested = false  -- set by the Skip Target button
local ignoreRequested = false  -- set by the Ignore Name button
local fightingNow = false  -- true while locked on a bug/boss/breakable
local ignoredNames = {}  -- lowercase names the player told the script to ignore

-- Core movement logic: teleport once, then stay on the target until it dies
local STAY_DISTANCE = 15      -- re-teleport only if the target moved farther than this (studs)
local FIGHT_TIMEOUT = 30      -- safety: give up on a bug/boss/breakable after this many seconds
local ORB_TIMEOUT = 1         -- orbs are skipped after this many seconds

local function teleportTo(targetCFrame)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if autoTweenToggle() then
		local dist = (root.Position - targetCFrame.Position).Magnitude
		local tween = TweenService:Create(root, TweenInfo.new(math.max(0.05, dist / 150), Enum.EasingStyle.Linear), {CFrame = targetCFrame})
		tween:Play()
		tween.Completed:Wait()
	else
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		root.CFrame = targetCFrame
	end
end

local function getTargetPart(obj)
	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

-- True while at least one part of the object is still visible (not faded out).
local function isVisible(obj)
	if obj:IsA("BasePart") then
		return obj.Transparency < 0.95
	end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.95 then
			return true
		end
	end
	return false
end

-- Bugs/boss/breakables (incl. their carcass) count as gone when the object is removed, emptied or fully faded out.
-- Orbs are also treated as gone if their health value says so.
local function isGone(obj, category)
	if not obj or not obj.Parent or not obj:IsDescendantOf(Workspace) then return true end
	if category == "bug" or category == "boss" or category == "breakable" or category == "feastcoin" then
		-- Feast bubbles may be removed or faded when collected.
		return not isVisible(obj)
	end
	local hum = obj:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return true end
	local healthVal = obj:FindFirstChild("Health")
	if healthVal and healthVal:IsA("ValueBase") and type(healthVal.Value) == "number" and healthVal.Value <= 0 then
		return true
	end
	return false
end

local function isDeadState(obj)
	local hum = obj:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return true end
	local healthVal = obj:FindFirstChild("Health")
	if healthVal and healthVal:IsA("ValueBase") and type(healthVal.Value) == "number" and healthVal.Value <= 0 then
		return true
	end
	return false
end

local function getBugRank(obj)
	local rank = 0
	for i, name in ipairs(bugTypes) do
		if nameMatches(obj.Name, name) then rank = i end
	end
	return rank
end

local excludedWords = {"spawn", "zone", "area", "trigger", "region", "marker", "hitbox", "boundary", "detector", "portal", "checkpoint", "template"}

local function hasExcludedWord(name)
	local lower = name:lower()
	for _, w in ipairs(excludedWords) do
		if lower:find(w, 1, true) then return true end
	end
	return false
end

-- Filters out decoys: spawners/zones, invisible parts, loose sub-parts of a tracked model, ignored names
local function isCandidateOk(obj, category)
	if ignoredNames[obj.Name:lower()] then return false end

	if category == "bug" or category == "boss" or category == "breakable" then
		if hasExcludedWord(obj.Name) then return false end

		local node = obj.Parent
		while node and node ~= Workspace do
			if hasExcludedWord(node.Name) then return false end
			node = node.Parent
		end

		local parent = obj.Parent
		if obj:IsA("BasePart") and parent and parent:IsA("Model") and trackedTargets[category][parent] then
			return false
		end

		if not isVisible(obj) then return false end
	end

	return true
end

-- targetNames: nil, a single name, or a list of names (empty list = no filter)
local function getClosest(category, yOffset, targetNames, usePriority)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil, nil end

	local closestCFrame = nil
	local closestObj = nil
	local shortestDist = math.huge
	local bestRank = -1
	local list = trackedTargets[category]

	local filters = nil
	if type(targetNames) == "string" then
		filters = {targetNames}
	elseif type(targetNames) == "table" and #targetNames > 0 then
		filters = targetNames
	end

	for obj in pairs(list) do
		if not obj or not obj.Parent or blacklistedTargets[obj] then
			list[obj] = nil
		else
			local nameMatch = true
			if filters then
				nameMatch = false
				for _, wanted in ipairs(filters) do
					if nameMatches(obj.Name, wanted) then
						nameMatch = true
						break
					end
				end
			end

			if nameMatch and isCandidateOk(obj, category) then
				local targetPart = nil
				if obj:IsA("BasePart") then
					targetPart = obj
				elseif obj:IsA("Model") then
					targetPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
				end

				-- Skip dead targets only for non-bugs so you can still eat bug carcasses.
				local isValid = true
				if category ~= "bug" and category ~= "boss" then
					local hum = obj:FindFirstChildOfClass("Humanoid")
					local healthVal = obj:FindFirstChild("Health")
					if hum and hum.Health <= 0 then
						isValid = false
					end
					if healthVal and healthVal:IsA("ValueBase") and healthVal.Value <= 0 then
						isValid = false
					end
				end

				if targetPart and isValid then
					local dist = (root.Position - targetPart.Position).Magnitude
					local rank = 0
					if usePriority and category == "bug" then
						rank = getBugRank(obj)
					end
					if rank > bestRank or (rank == bestRank and dist < shortestDist) then
						bestRank = rank
						shortestDist = dist
						closestCFrame = targetPart.CFrame + Vector3.new(0, yOffset, 0)
						closestObj = obj
					end
				end
			end
		end
	end

	return closestCFrame, closestObj
end

-- Feast controller: collect 10 disappearing fruit bubbles, then stand at the plate.
-- The final eat action is intentionally left manual as requested by the game mechanic.
local feastCollected = 0
local feastPhase = "collect"
local feastPrompt = nil
local feastPlateSpot = nil
local feastReady = false

local function findFeastPrompt()
	local area = Workspace:FindFirstChild("FeastArea")
	local spot = area and area:FindFirstChild("PlatePromptSpot")
	local prompt = spot and spot:FindFirstChild("FeastPlatePrompt")
	return spot, prompt
end

local function getFeastPromptText()
	local spot, prompt = findFeastPrompt()
	feastPlateSpot, feastPrompt = spot, prompt
	if prompt and prompt:IsA("ProximityPrompt") then
		return string.lower(prompt.ActionText or "")
	end
	return ""
end

-- Main farm loop (priority: orbs > Feast fruit > boss > bugs > breakables)
local function pickTarget()
	local cf, obj

	if autoOrbs() then
		cf, obj = getClosest("orb", 0)
		if cf then return cf, obj, "orb", 0 end
	end
	if autoSandOrbs() then
		cf, obj = getClosest("sandorb", 0)
		if cf then return cf, obj, "sandorb", 0 end
	end
	if autoVoidOrbs() then
		cf, obj = getClosest("voidorb", 0)
		if cf then return cf, obj, "voidorb", 0 end
	end
	if autoFeastCoins() then
		cf, obj = getClosest("feastcoin", 0)
		if cf then return cf, obj, "feastcoin", 0 end
	end
	if autoBoss() then
		cf, obj = getClosest("boss", 3)
		if cf then return cf, obj, "boss", 3 end
	end
	if autoBugs() then
		cf, obj = getClosest("bug", 3, getBugSel(), autoPriority())
		if cf then return cf, obj, "bug", 3 end
	end
	if autoBreakables() then
		cf, obj = getClosest("breakable", 3, getBreakSel())
		if cf then return cf, obj, "breakable", 3 end
	end
	return nil
end

local function formatTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
end

local startTick = tick()
local killCount = 0
task.spawn(function()
	local currentObj, currentCategory, currentY, targetStart = nil, nil, 0, 0
	local manualPauseUntil = 0

	local function step()
		local root = character and character:FindFirstChild("HumanoidRootPart")

		local lockInfo = ""

		-- Auto Feast Cycle owns the character while it is on: pause the normal farm loop
		if autoFeastCycle() then
			currentObj = nil
			fightingNow = false
			StatusLabel.Text = string.format(
				"Target: Feast Cycle - %s\nDone: %d  |  Fruit: %s  |  Time: %s",
				feastCycleStatus, killCount, feastCycleCount, formatTime(tick() - startTick)
			)
			return
		end

		if forceRetarget then
			currentObj = nil
			forceRetarget = false
		end

		if skipRequested then
			if currentObj then blacklistedTargets[currentObj] = true end
			currentObj = nil
			skipRequested = false
		end

		if ignoreRequested then
			if currentObj then
				ignoredNames[currentObj.Name:lower()] = true
				blacklistedTargets[currentObj] = true
			end
			currentObj = nil
			ignoreRequested = false
		end

		-- Manual movement: release the target and pause auto-teleport for a few seconds
		local humCtl = character and character:FindFirstChildOfClass("Humanoid")
		if humCtl and humCtl.MoveDirection.Magnitude > 0.1 then
			manualPauseUntil = tick() + 3
			if currentObj then
				blacklistedTargets[currentObj] = true
				currentObj = nil
			end
		end

		if not autoFeastCoins() then
			feastCollected = 0
			feastPhase = "collect"
			feastReady = false
		end

		-- Release the lock when the matching feature (or every farm feature) is switched off
		local categoryToggle = {
			orb = autoOrbs, sandorb = autoSandOrbs, voidorb = autoVoidOrbs,
			feastcoin = autoFeastCoins,
			boss = autoBoss, bug = autoBugs, breakable = autoBreakables,
		}
		if currentObj then
			local toggleFn = categoryToggle[currentCategory]
			if not toggleFn or not toggleFn() then
				currentObj = nil
			end
		end

		if root and tick() >= manualPauseUntil then
			-- Still locked on a target: stay on it until it is gone
			if currentObj then
				local isOrb = (currentCategory == "orb" or currentCategory == "sandorb"
					or currentCategory == "voidorb" or currentCategory == "feastcoin")
				local limit = isOrb and ORB_TIMEOUT or FIGHT_TIMEOUT
				local gone = isGone(currentObj, currentCategory)
				lockInfo = string.format(" (%s, %ds left)",
					isDeadState(currentObj) and "carcass" or "alive",
					math.max(0, math.floor(limit - (tick() - targetStart))))

				if gone or (tick() - targetStart) >= limit then
					if currentCategory == "feastcoin" and gone then
						feastCollected = math.min(10, feastCollected + 1)
						if feastCollected >= 10 then feastPhase = "deposit" end
					elseif gone and not isOrb then
						killCount = killCount + 1
					end
					blacklistedTargets[currentObj] = true
					currentObj = nil
				else
					local part = getTargetPart(currentObj)
					if part and (root.Position - part.Position).Magnitude > STAY_DISTANCE then
						pcall(teleportTo, part.CFrame + Vector3.new(0, currentY, 0))
					end
				end
			end

			-- Feast deposit phase: approach the prompt spot and wait for the plate to say "eat".
			if autoFeastCoins() and feastPhase == "deposit" then
				local spot, prompt = findFeastPrompt()
				feastPlateSpot, feastPrompt = spot, prompt
				local action = getFeastPromptText()
				if action == "eat" then
					feastReady = true
					lockInfo = " (plate full - click eat manually)"
				elseif spot and spot:IsA("BasePart") then
					feastReady = false
					if (root.Position - spot.Position).Magnitude > 7 then
						currentObj = nil
						pcall(teleportTo, spot.CFrame + Vector3.new(0, 2, 0))
					end
				else
					lockInfo = " (waiting for Feast plate)"
				end
			elseif not currentObj then
				local cf, obj, cat, y = pickTarget()
				if cf and obj then
					currentObj, currentCategory, currentY, targetStart = obj, cat, y, tick()
					pcall(teleportTo, cf)
				end
			end

			-- After the player manually eats the full plate, reset the Feast cycle.
			if autoFeastCoins() and feastPhase == "deposit" and feastReady then
				local action = getFeastPromptText()
				if action ~= "eat" and action ~= "" then
					feastCollected = 0
					feastPhase = "collect"
					feastReady = false
				end
			end
		end

		fightingNow = currentObj ~= nil
			and (currentCategory == "bug" or currentCategory == "boss" or currentCategory == "breakable")

		StatusLabel.Text = string.format(
			"Target: %s\nDone: %d  |  Feast: %d/10  |  Time: %s",
			(tick() < manualPauseUntil) and "paused (manual move)"
				or (autoFeastCoins() and feastPhase == "deposit" and (feastReady and "Feast plate full - click eat manually" or "Feast: depositing fruit")
				or (currentObj and (currentCategory .. " - " .. currentObj.Name .. " [" .. (currentObj.Parent and currentObj.Parent.Name or "?") .. "]" .. lockInfo) or "searching...")),
			killCount,
			feastCollected,
			formatTime(tick() - startTick)
		)
	end

	while ScreenGui and ScreenGui.Parent do
		local ok, err = pcall(step)
		if not ok then warn("[DAUSHUB] " .. tostring(err)) end
		task.wait(cooldown)
	end
end)

-- GUI helpers (used by Auto Respawn)
local function isGuiVisible(obj)
	local node = obj
	while node and node ~= game do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("ScreenGui") and not node.Enabled then return false end
		node = node.Parent
	end
	return obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0
end

local function collectText(node)
	local parts = {}
	if node:IsA("TextButton") or node:IsA("TextLabel") then
		table.insert(parts, node.Text)
	end
	for _, d in ipairs(node:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("TextLabel") then
			table.insert(parts, d.Text)
		end
	end
	return table.concat(parts, " "):lower()
end

local function countButtons(node)
	local n = 0
	for _, d in ipairs(node:GetDescendants()) do
		if d:IsA("GuiButton") then n = n + 1 end
	end
	if node:IsA("GuiButton") then n = n + 1 end
	return n
end

local function getCardText(btn)
	local node = btn
	for _ = 1, 3 do
		local text = collectText(node)
		if text:gsub("%s+", "") ~= "" then return text end
		node = node.Parent
		if not node or node:IsA("LayerCollector") then break end
		if countButtons(node) > 1 then break end
	end
	return ""
end

local function clickGui(btn)
	local fired = false
	if getconnections then
		for _, sig in ipairs({btn.MouseButton1Click, btn.Activated}) do
			local ok, conns = pcall(getconnections, sig)
			if ok and conns then
				for _, c in ipairs(conns) do
					pcall(function() c:Fire() end)
					fired = true
				end
			end
		end
	end
	if not fired and firesignal then
		local ok1 = pcall(firesignal, btn.MouseButton1Click)
		local ok2 = pcall(firesignal, btn.Activated)
		fired = ok1 or ok2
	end
	if not fired then
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			local inset = game:GetService("GuiService"):GetGuiInset()
			local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
			vim:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, true, game, 0)
			task.wait(0.05)
			vim:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, false, game, 0)
		end)
	end
end

-- Anti-AFK
pcall(function()
	local VirtualUser = game:GetService("VirtualUser")
	player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

-- Auto respawn & continue
local function hookDeath(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end

	hum.Died:Connect(function()
		forceRetarget = true
		if not autoRespawn() then return end

		task.wait(2)
		for _ = 1, 10 do
			if character ~= char or not ScreenGui.Parent then break end

			local clicked = false
			for _, d in ipairs(player.PlayerGui:GetDescendants()) do
				if d:IsA("GuiButton") and not d:IsDescendantOf(ScreenGui) and isGuiVisible(d) then
					local text = getCardText(d)
					if text:find("respawn", 1, true) or text:find("revive", 1, true) then
						pcall(clickGui, d)
						clicked = true
						break
					end
				end
			end

			if not clicked then break end
			task.wait(2)
		end
	end)
end

task.spawn(hookDeath, character)
player.CharacterAdded:Connect(hookDeath)

-- Low graphics mode (reversible)
local savedQuality = nil
local savedShadows = nil
local savedEffects = {}

local function applyLowGraphics()
	local Lighting = game:GetService("Lighting")

	pcall(function()
		local rendering = settings().Rendering
		if savedQuality == nil then savedQuality = rendering.QualityLevel end
		rendering.QualityLevel = Enum.QualityLevel.Level01
	end)

	if savedShadows == nil then savedShadows = Lighting.GlobalShadows end
	Lighting.GlobalShadows = false

	for _, d in ipairs(Lighting:GetChildren()) do
		if d:IsA("PostEffect") and d.Enabled then
			savedEffects[d] = true
			d.Enabled = false
		end
	end

	local descendants = Workspace:GetDescendants()
	for i, d in ipairs(descendants) do
		if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
			or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")) and d.Enabled then
			savedEffects[d] = true
			d.Enabled = false
		end
		if i % 2000 == 0 then task.wait() end
	end
end

local function restoreGraphics()
	local Lighting = game:GetService("Lighting")

	if savedQuality ~= nil then
		pcall(function() settings().Rendering.QualityLevel = savedQuality end)
		savedQuality = nil
	end
	if savedShadows ~= nil then
		Lighting.GlobalShadows = savedShadows
		savedShadows = nil
	end
	for inst in pairs(savedEffects) do
		if inst and inst.Parent then
			pcall(function() inst.Enabled = true end)
		end
	end
	savedEffects = {}
end

task.spawn(function()
	local wasOn = false
	while ScreenGui and ScreenGui.Parent do
		local on = autoFps()
		if on then
			pcall(applyLowGraphics)
			wasOn = true
			task.wait(5)
		else
			if wasOn then
				pcall(restoreGraphics)
				wasOn = false
			end
			task.wait(1)
		end
	end
end)

-- Max time per target + skip handlers
TimeMinus.MouseButton1Click:Connect(function()
	FIGHT_TIMEOUT = math.max(5, FIGHT_TIMEOUT - 5)
	TimeLabel.Text = "Max Time Per Target: " .. FIGHT_TIMEOUT .. "s"
end)

TimePlus.MouseButton1Click:Connect(function()
	FIGHT_TIMEOUT = math.min(180, FIGHT_TIMEOUT + 5)
	TimeLabel.Text = "Max Time Per Target: " .. FIGHT_TIMEOUT .. "s"
end)

SkipBtn.MouseButton1Click:Connect(function()
	skipRequested = true
end)

-- Speed boost + fly
local speedHum, speedOrig, speedConn = nil, nil, nil
local flyBV, flyBG = nil, nil

local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

RunService.Heartbeat:Connect(function(dt)
	if not ScreenGui.Parent then
		stopFly()
		return
	end

	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local cam = Workspace.CurrentCamera

	-- Speed boost (restores the original speed when switched off)
	if autoSpeed() and hum then
		if speedHum ~= hum then
			if speedConn then speedConn:Disconnect() end
			speedHum = hum
			speedOrig = hum.WalkSpeed
			-- If the game resets WalkSpeed, put our value back immediately
			speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if autoSpeed() and hum.WalkSpeed ~= getSpeedValue() then
					hum.WalkSpeed = getSpeedValue()
				end
			end)
		end
		if hum.WalkSpeed ~= getSpeedValue() then
			hum.WalkSpeed = getSpeedValue()
		end
	elseif speedHum then
		if speedConn then
			speedConn:Disconnect()
			speedConn = nil
		end
		if speedHum.Parent then
			speedHum.WalkSpeed = speedOrig or 16
		end
		speedHum = nil
	end

	-- CFrame speed mode: adds extra movement on top of the normal speed (for games that keep resetting WalkSpeed)
	if autoSpeedCF() and root and hum and hum.Health > 0 and not autoFly() and hum.MoveDirection.Magnitude > 0.1 then
		local extra = math.max(0, getSpeedValue() - 16)
		root.CFrame = root.CFrame + hum.MoveDirection * (extra * dt)
	end

	-- Fly: move with the stick / WASD, steer up and down with the camera angle (Space / Shift also work on PC)
	if autoFly() and root and hum and cam and hum.Health > 0 then
		if not flyBV or flyBV.Parent ~= root then
			stopFly()
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			flyBV.Velocity = Vector3.new(0, 0, 0)
			flyBV.Parent = root

			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			flyBG.P = 9e4
			flyBG.Parent = root
		end

		hum.PlatformStand = true

		local rel = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
		local dir = cam.CFrame.LookVector * (-rel.Z) + cam.CFrame.RightVector * rel.X
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			dir = dir - Vector3.new(0, 1, 0)
		end

		flyBV.Velocity = dir * getFlySpeed()
		flyBG.CFrame = cam.CFrame
	elseif flyBV then
		stopFly()
	end
end)

IgnoreBtn.MouseButton1Click:Connect(function()
	ignoreRequested = true
end)

-- Auto skills: re-fires your skills as soon as the game allows (the game's own cooldown still applies)
local skillVIM = nil
pcall(function() skillVIM = game:GetService("VirtualInputManager") end)

local skillKeyCodes = {
	Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, R = Enum.KeyCode.R, F = Enum.KeyCode.F,
	Z = Enum.KeyCode.Z, X = Enum.KeyCode.X, C = Enum.KeyCode.C, V = Enum.KeyCode.V,
	["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three, ["4"] = Enum.KeyCode.Four,
}

local skillButtons = {}
local lastSkillButtonScan = 0

local function parseKeywords(text)
	local list = {}
	for part in tostring(text):gmatch("[^,]+") do
		local kw = part:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if kw ~= "" then table.insert(list, kw) end
	end
	return list
end

local function refreshSkillButtons(keywords)
	skillButtons = {}
	if #keywords == 0 then return end
	for _, d in ipairs(player.PlayerGui:GetDescendants()) do
		if d:IsA("GuiButton") and not d:IsDescendantOf(ScreenGui) then
			local hay = (d.Name .. " " .. getCardText(d)):lower()
			for _, kw in ipairs(keywords) do
				if hay:find(kw, 1, true) then
					table.insert(skillButtons, d)
					break
				end
			end
		end
	end
end

task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		if autoSkill() and (not skillOnlyFighting() or fightingNow) then
			-- Keyboard keys
			if skillVIM then
				for _, key in ipairs(getSkillKeys()) do
					local code = skillKeyCodes[key]
					if code then
						pcall(function()
							skillVIM:SendKeyEvent(true, code, false, game)
							task.wait(0.03)
							skillVIM:SendKeyEvent(false, code, false, game)
						end)
					end
				end
			end

			-- On-screen buttons (mobile)
			local keywords = parseKeywords(getSkillButtons())
			if #keywords > 0 then
				if tick() - lastSkillButtonScan > 2 then
					lastSkillButtonScan = tick()
					pcall(refreshSkillButtons, keywords)
				end
				for _, btn in ipairs(skillButtons) do
					if btn.Parent and isGuiVisible(btn) then
						pcall(clickGui, btn)
					end
				end
			end
		end
		task.wait(math.max(0.05, getSkillInterval() / 1000))
	end
end)

-- Auto click buttons (upgrades / trait choices / evolve / claim ...)
local clickCache = {}
local lastClickScan = 0

task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		if autoClickBtns() then
			local keywords = parseKeywords(getClickNames())
			if #keywords > 0 then
				if tick() - lastClickScan > 1.5 then
					lastClickScan = tick()
					clickCache = {}
					pcall(function()
						for _, d in ipairs(player.PlayerGui:GetDescendants()) do
							if d:IsA("GuiButton") and not d:IsDescendantOf(ScreenGui) then
								local hay = (d.Name .. " " .. getCardText(d)):lower()
								for _, kw in ipairs(keywords) do
									if hay:find(kw, 1, true) then
										table.insert(clickCache, d)
										break
									end
								end
							end
						end
					end)
				end
				for _, btn in ipairs(clickCache) do
					if btn.Parent and isGuiVisible(btn) then
						pcall(clickGui, btn)
					end
				end
			end
		end
		task.wait(1)
	end
end)

-- Attack speed boost: finds client-side attack speed values by name, multiplies them, restores them when switched off
local function makeValueTracker(matchFn)
	local tracker = {entries = {}, lastScan = 0, active = false}
	local index = setmetatable({}, {__mode = "k"})

	function tracker.scan()
		local list = {}

		local function add(inst, key, kind)
			index[inst] = index[inst] or {}
			local e = index[inst][key]
			if not e then
				e = {inst = inst, key = key}
				if kind == "attr" then
					e.get = function() return inst:GetAttribute(key) end
					e.set = function(v) inst:SetAttribute(key, v) end
				else
					e.get = function() return inst.Value end
					e.set = function(v) inst.Value = v end
				end
				e.isInt = inst:IsA("IntValue")
				e.orig = e.get()
				index[inst][key] = e
			end
			table.insert(list, e)
		end

		local function consider(inst)
			local path = inst:GetFullName()
			for key, val in pairs(inst:GetAttributes()) do
				if type(val) == "number" and matchFn(path .. "." .. key) then
					add(inst, key, "attr")
				end
			end
			if (inst:IsA("NumberValue") or inst:IsA("IntValue")) and matchFn(path) then
				add(inst, "Value", "value")
			end
		end

		for _, base in ipairs({player, character}) do
			if base then
				consider(base)
				for _, d in ipairs(base:GetDescendants()) do
					consider(d)
				end
			end
		end

		tracker.entries = list
	end

	function tracker.apply(on, targetFn)
		if on then
			tracker.active = true
			if tick() - tracker.lastScan > 3 then
				tracker.lastScan = tick()
				pcall(tracker.scan)
			end
			for _, e in ipairs(tracker.entries) do
				if e.inst.Parent then
					pcall(function()
						local cur = e.get()
						if type(cur) ~= "number" then return end
						-- the game changed it on its own (e.g. an upgrade): treat that as the new original
						if e.lastSet ~= nil and cur ~= e.lastSet then e.orig = cur end
						local target = targetFn(e)
						if e.isInt then target = math.floor(target + 0.5) end
						if cur ~= target then e.set(target) end
						e.lastSet = target
					end)
				end
			end
		elseif tracker.active then
			for _, e in ipairs(tracker.entries) do
				if e.lastSet ~= nil and e.inst.Parent then
					pcall(e.set, e.orig)
				end
				e.lastSet = nil
			end
			tracker.active = false
			tracker.lastScan = 0
		end
	end

	return tracker
end

local function cleanPath(path)
	return (path:lower():gsub("[^%a]", ""))
end

local atkSpeedTracker = makeValueTracker(function(path)
	local c = cleanPath(path)
	return c:find("attackspeed", 1, true) or c:find("atkspeed", 1, true)
		or c:find("aspd", 1, true) or c:find("attackrate", 1, true)
end)

task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		atkSpeedTracker.apply(autoAtkSpeed(), function(e) return e.orig * getAtkMult() end)
		task.wait(0.2)
	end
end)

-- ============================================================
-- Feast Auto Cycle (merged from bio.lua), switched by the "Auto Feast Cycle" toggle
-- Strict flow:
--   1. Read the player's fruit counter.
--   2. Collect bubbles one by one until the counter is really 10/10.
--   3. Only then teleport to the Feast Plate.
--   4. Wait until the plate prompt shows "eat".
--   5. Eat 10 times, one by one.
--   6. Wait until the plate leaves "eat" / is back to 0/10.
--   7. Only then start looking for bubbles again.
-- ============================================================
do
	local FEAST = {
		MAX = 10,
		BUBBLE_PATH = {"FeastFruit", "FeastFruit", "Bubble"},
		PLATE_PATH = {"FeastArea", "PlatePromptSpot"},
		PROMPT_NAME = "FeastPlatePrompt",

		SCAN_DELAY = 0.25,
		PICKUP_CONFIRM_TIMEOUT = 5,
		PLATE_CONFIRM_TIMEOUT = 25,
		EAT_CONFIRM_TIMEOUT = 20,
		EAT_INTERVAL = 0.65,
		CYCLE_PAUSE = 0.8,

		-- Stop near the PlatePromptSpot, not in the middle of the plate
		PLATE_OFFSET = CFrame.new(0, 2, 3),
	}

	local function isRunning()
		return ScreenGui.Parent ~= nil and autoFeastCycle()
	end

	local function status(text)
		feastCycleStatus = text
		refreshFeastInfo()
	end

	local function showCount(n)
		feastCycleCount = math.clamp(tonumber(n) or 0, 0, FEAST.MAX) .. "/" .. FEAST.MAX
		refreshFeastInfo()
	end

	local function characterRoot()
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	local function findPath(root, path)
		local node = root
		for _, name in ipairs(path) do
			node = node and node:FindFirstChild(name)
			if not node then return nil end
		end
		return node
	end

	local function findPlate()
		local spot = findPath(Workspace, FEAST.PLATE_PATH)
		local area = Workspace:FindFirstChild("FeastArea", true)

		if not spot and area then
			spot = area:FindFirstChild("PlatePromptSpot", true)
		end

		local prompt = spot and spot:FindFirstChild(FEAST.PROMPT_NAME, true)
		if not prompt and area then
			prompt = area:FindFirstChild(FEAST.PROMPT_NAME, true)
		end

		return spot, prompt
	end

	local function actionText(prompt)
		return prompt and string.lower(tostring(prompt.ActionText or "")) or ""
	end

	local function eatReady(prompt)
		return string.find(actionText(prompt), "eat", 1, true) ~= nil
	end

	local function plateFoodCount(prompt)
		if not prompt then return nil end
		local a = tostring(prompt.ActionText or "")
		local n = string.match(a, "%((%d+)%s*/%s*10")
		if not n then n = string.match(a, "(%d+)%s*/%s*10") end
		return n and tonumber(n) or nil
	end

	-- Only reads UI counters that mention fruit/bubble/food/feast (our own window is ignored).
	-- If the counter cannot be read, the script does NOT make up a number.
	local function readPlayerFruitCount()
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if not pg then return nil end

		local found = nil
		for _, obj in ipairs(pg:GetDescendants()) do
			if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
				and not obj:IsDescendantOf(ScreenGui) then
				local txt = tostring(obj.Text or "")
				local num = string.match(txt, "(%d+)%s*/%s*10")
				if num then
					local tag = string.lower(obj.Name .. " " .. txt)
					if string.find(tag, "fruit", 1, true)
						or string.find(tag, "bubble", 1, true)
						or string.find(tag, "food", 1, true)
						or string.find(tag, "feast", 1, true) then
						found = tonumber(num)
					end
				end
			end
		end
		return found
	end

	local function feastTeleport(cf)
		local root = characterRoot()
		if not root then return false end
		root.CFrame = cf
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	local function findBubbleParts()
		local results = {}
		local exact = findPath(Workspace, FEAST.BUBBLE_PATH)

		if exact then
			if exact:IsA("BasePart") then
				table.insert(results, exact)
			else
				for _, v in ipairs(exact:GetDescendants()) do
					if v:IsA("BasePart") and string.find(string.lower(v.Name), "bubble", 1, true) then
						table.insert(results, v)
					end
				end
			end
		end

		if #results == 0 then
			local ff = Workspace:FindFirstChild("FeastFruit", true)
			if ff then
				for _, v in ipairs(ff:GetDescendants()) do
					if v:IsA("BasePart") and string.find(string.lower(v.Name), "bubble", 1, true) then
						table.insert(results, v)
					end
				end
			end
		end

		return results
	end

	local function nearestBubble()
		local root = characterRoot()
		if not root then return nil end

		local best, bestDistance = nil, math.huge
		for _, part in ipairs(findBubbleParts()) do
			if part.Parent and part:IsDescendantOf(Workspace) then
				local d = (root.Position - part.Position).Magnitude
				if d < bestDistance then
					best, bestDistance = part, d
				end
			end
		end
		return best
	end

	local function touchBubble(part)
		local root = characterRoot()
		if not root or not part then return false end

		if type(firetouchinterest) == "function" then
			local ok = pcall(function()
				firetouchinterest(root, part, 0)
				task.wait(0.12)
				firetouchinterest(root, part, 1)
			end)
			if ok then return true end
		end

		-- Fallback: teleport onto the bubble to trigger a normal touch
		return feastTeleport(part.CFrame * CFrame.new(0, 2, 0))
	end

	local function collectUntilFull()
		status("Checking fruit counter")
		local initial = readPlayerFruitCount()
		if initial == nil then
			status("Fruit counter not readable - retrying")
			return false
		end

		showCount(initial)

		while isRunning() do
			local count = readPlayerFruitCount()
			if count == nil then
				status("Counter lost - waiting")
				task.wait(0.5)
			else
				showCount(count)
				if count >= FEAST.MAX then
					status("Player fruit is 10/10")
					return true
				end

				local bubble = nearestBubble()
				if not bubble then
					status("Waiting for bubble (" .. count .. "/10)")
					task.wait(FEAST.SCAN_DELAY)
				else
					status("Collecting bubble (" .. count .. "/10)")
					local before = count
					feastTeleport(bubble.CFrame * CFrame.new(0, 2, 0))
					touchBubble(bubble)

					local started = os.clock()
					local confirmed = false
					while isRunning() and os.clock() - started < FEAST.PICKUP_CONFIRM_TIMEOUT do
						task.wait(0.15)
						local now = readPlayerFruitCount()
						if now ~= nil then
							showCount(now)
							if now > before or now >= FEAST.MAX then
								confirmed = true
								break
							end
						end
					end

					if not confirmed then
						status("Bubble did not add to counter - retrying")
						task.wait(0.5)
					end
				end
			end
		end
		return false
	end

	local function waitForPlateFull(prompt)
		status("Waiting for fruit to enter the plate")
		local started = os.clock()

		while isRunning() and os.clock() - started < FEAST.PLATE_CONFIRM_TIMEOUT do
			if not prompt or not prompt.Parent then
				local _, newPrompt = findPlate()
				prompt = newPrompt
			end

			if prompt then
				if eatReady(prompt) then
					status("Plate confirmed full - Eat available")
					return true, prompt
				end

				local n = plateFoodCount(prompt)
				if n ~= nil then
					status("Plate: " .. n .. "/10")
				end
			end
			task.wait(0.2)
		end

		status("Plate not confirmed 10/10")
		return false, prompt
	end

	local function invokeEat(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then return false end

		if type(fireproximityprompt) == "function" then
			local ok = pcall(function()
				fireproximityprompt(prompt, 1)
			end)
			return ok
		end

		local ok = pcall(function()
			prompt:InputHoldBegin()
			task.wait(math.max(prompt.HoldDuration, 0.05))
			prompt:InputHoldEnd()
		end)
		return ok
	end

	local function eatAllAndConfirm(prompt)
		for i = 1, FEAST.MAX do
			if not isRunning() then return false end

			-- Each action is performed separately; never spam all ten at once
			if not eatReady(prompt) then
				status("Eat not available before step " .. i .. "/10")
				return false
			end

			status("Eating fruit " .. i .. "/10")
			if not invokeEat(prompt) then
				status("Eat interaction failed at " .. i .. "/10")
				return false
			end

			task.wait(FEAST.EAT_INTERVAL)
			local _, refreshedPrompt = findPlate()
			if refreshedPrompt then prompt = refreshedPrompt end
		end

		-- Critical gate: do not collect again until the plate has reset from Eat to 0/10
		status("Confirming all fruit was eaten")
		local started = os.clock()
		while isRunning() and os.clock() - started < FEAST.EAT_CONFIRM_TIMEOUT do
			local _, refreshedPrompt = findPlate()
			if refreshedPrompt then prompt = refreshedPrompt end

			local n = plateFoodCount(prompt)
			if not eatReady(prompt) and (n == nil or n == 0) then
				status("Plate empty - all fruit eaten")
				return true
			end

			task.wait(0.2)
		end

		status("No empty-plate confirmation - not restarting")
		return false
	end

	local function oneCycle()
		-- Phase 1: the player's counter must reach exactly 10 before leaving
		if not collectUntilFull() then return false end
		if not isRunning() then return false end

		-- Re-check right before teleporting
		local count = readPlayerFruitCount()
		if count == nil or count < FEAST.MAX then
			status("Counter not 10/10 - collecting again")
			return false
		end

		-- Phase 2: teleport only after a confirmed 10/10
		local spot, prompt = findPlate()
		if not spot or not spot:IsA("BasePart") or not prompt then
			status("Feast plate / prompt not found")
			return false
		end

		status("10/10 confirmed - teleporting to plate")
		if not feastTeleport(spot.CFrame * FEAST.PLATE_OFFSET) then
			status("Teleport failed")
			return false
		end

		-- Phase 3: wait until the plate itself confirms full / Eat
		local full, livePrompt = waitForPlateFull(prompt)
		if not full then return false end

		-- Phase 4: eat all ten, then confirm the plate has reset
		return eatAllAndConfirm(livePrompt)
	end

	task.spawn(function()
		local wasOn = false
		while ScreenGui and ScreenGui.Parent do
			if autoFeastCycle() then
				wasOn = true
				local ok, result = pcall(oneCycle)
				if not ok then
					status("Error: " .. tostring(result))
					task.wait(1)
				elseif result then
					task.wait(FEAST.CYCLE_PAUSE)
				else
					-- A phase was not confirmed: never jump ahead, retry from collecting after a pause
					task.wait(1)
				end
			else
				if wasOn then
					wasOn = false
					status("Stopped")
				end
				task.wait(0.3)
			end
		end
	end)
end
