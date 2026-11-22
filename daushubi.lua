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
local tweenUsage = false
local selectedBugIndex = 1
local selectedBreakIndex = 1

-- Dropdown lists
local bugTypes = {
	"All",
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
	"All",
	"Acorn",
	"Cocoon",
	"Sugar Cube"
}

local trackedTargets = {
	orb = {},
	sandorb = {},
	voidorb = {},
	bug = {},
	boss = {},
	breakable = {}
}

-- Anti-stuck blacklist cache
local blacklistedTargets = {}

local function registerObject(obj)
	if Players:GetPlayerFromCharacter(obj) or (obj.Parent and Players:GetPlayerFromCharacter(obj.Parent)) then
		return
	end

	local nameLower = obj.Name:lower()
	local cleanName = nameLower:gsub("%s+", "")
	local category = nil

	if cleanName:find("level", 1, true) or cleanName:find("+", 1, true) or cleanName:find("text", 1, true) then
		return
	end

	if cleanName:find("sandorb", 1, true) then
		category = "sandorb"
	elseif cleanName:find("voidorb", 1, true) then
		category = "voidorb"
	elseif cleanName:find("orb", 1, true) and not cleanName:find("orbit", 1, true) then
		category = "orb"
	elseif cleanName:find("emperorscorpion", 1, true) then
		category = "boss"
	elseif cleanName:find("centipede", 1, true)
		or cleanName:find("sandscorpion", 1, true)
		or cleanName:find("ant", 1, true)
		or cleanName:find("pillbug", 1, true)
		or cleanName:find("giantpillbug", 1, true)
		or cleanName:find("caterpillar", 1, true)
		or cleanName:find("cricket", 1, true)
		or cleanName:find("stagbeetle", 1, true) then
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
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui
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
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 6
Sidebar.Parent = MainFrame

local TabMainBtn = Instance.new("TextButton")
TabMainBtn.Size = UDim2.new(1, -16, 0, 36)
TabMainBtn.Position = UDim2.new(0, 8, 0, 10)
TabMainBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 220)
TabMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabMainBtn.Font = Enum.Font.GothamBold
TabMainBtn.TextSize = 12
TabMainBtn.Text = "🏠 Main"
TabMainBtn.ZIndex = 7
TabMainBtn.Parent = Sidebar
Instance.new("UICorner", TabMainBtn).CornerRadius = UDim.new(0, 8)

-- Content panel with auto layout
local ContentPanel = Instance.new("ScrollingFrame")
ContentPanel.Size = UDim2.new(1, -152, 1, -60)
ContentPanel.Position = UDim2.new(0, 148, 0, 52)
ContentPanel.BackgroundTransparency = 1
ContentPanel.CanvasSize = UDim2.new(0, 0, 0, 620)
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
			local delta = input.Position - dragStart
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
	row.Parent = ContentPanel
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

local function makeDropdown(titleText, itemsTable, orderVal, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -8, 0, 44)
	container.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
	container.LayoutOrder = orderVal
	container.ZIndex = 7
	container.Parent = ContentPanel
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
	label.ZIndex = 8
	label.Parent = container

	local selectBtn = Instance.new("TextButton")
	selectBtn.Size = UDim2.new(0, 140, 0, 28)
	selectBtn.Position = UDim2.new(1, -148, 0.5, -14)
	selectBtn.BackgroundColor3 = Color3.fromRGB(45, 38, 65)
	selectBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.TextSize = 11
	selectBtn.Text = itemsTable[1] .. " ▾"
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

	local currentIndex = 1
	for i, itemName in ipairs(itemsTable) do
		local itemBtn = Instance.new("TextButton")
		itemBtn.Size = UDim2.new(1, 0, 0, 26)
		itemBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		itemBtn.BackgroundTransparency = 1
		itemBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
		itemBtn.Font = Enum.Font.GothamMedium
		itemBtn.TextSize = 11
		itemBtn.Text = itemName
		itemBtn.ZIndex = 101
		itemBtn.Parent = dropList

		itemBtn.MouseButton1Click:Connect(function()
			currentIndex = i
			selectBtn.Text = itemName .. " ▾"
			dropList.Visible = false
			callback(currentIndex)
		end)
	end

	RunService.RenderStepped:Connect(function()
		if dropList.Visible and selectBtn and selectBtn.Parent then
			local absPos = selectBtn.AbsolutePosition
			local absSize = selectBtn.AbsoluteSize
			dropList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
		end
	end)

	selectBtn.MouseButton1Click:Connect(function()
		local currentState = dropList.Visible
		closeAllDropdowns()
		dropList.Visible = not currentState
	end)

	return function() return currentIndex end
end

-- Build controls
local autoOrbs = makeFeatureToggle("Auto Orbs", 1)
local autoSandOrbs = makeFeatureToggle("Auto SandOrbs", 2)
local autoVoidOrbs = makeFeatureToggle("Auto VoidOrbs", 3)

local autoBugs = makeFeatureToggle("Auto Farm Bugs", 4)
local getBugTier = makeDropdown("Target Bug Name", bugTypes, 5, function(idx)
	selectedBugIndex = idx
end)

local autoBoss = makeFeatureToggle("Auto Mini Boss (Emperor Scorpion)", 6)

local autoBreakables = makeFeatureToggle("Auto Farm Breakables", 7)
local getBreakTier = makeDropdown("Target Breakable Name", breakableTypes, 8, function(idx)
	selectedBreakIndex = idx
end)

local autoTweenToggle = makeFeatureToggle("Smooth Tween Movement Mode", 9)

-- Cooldown adjuster
local CDFrame = Instance.new("Frame")
CDFrame.Size = UDim2.new(1, -8, 0, 56)
CDFrame.BackgroundColor3 = Color3.fromRGB(20, 17, 30)
CDFrame.LayoutOrder = 10
CDFrame.ZIndex = 7
CDFrame.Parent = ContentPanel
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

-- Floating button only reopens the window
ToggleBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	closeAllDropdowns()
end)

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
	if category == "bug" or category == "boss" or category == "breakable" then
		-- Some games keep the object but fade it out / empty it instead of removing it.
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

local function getClosest(category, yOffset, targetNameStr)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil, nil end

	local closestCFrame = nil
	local closestObj = nil
	local shortestDist = math.huge
	local list = trackedTargets[category]

	for obj in pairs(list) do
		if not obj or not obj.Parent or blacklistedTargets[obj] then
			list[obj] = nil
		else
			local nameMatch = true
			if targetNameStr then
				nameMatch = false
				local objNameLower = obj.Name:lower():gsub("%s+", "")
				local cleanTarget = targetNameStr:lower():gsub("%s+", "")
				if objNameLower:find(cleanTarget, 1, true) then
					nameMatch = true
				end
			end

			if nameMatch then
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
					if dist < shortestDist then
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

-- Main farm loop (priority: orbs > boss > bugs > breakables)
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
	if autoBoss() then
		cf, obj = getClosest("boss", 3)
		if cf then return cf, obj, "boss", 3 end
	end
	if autoBugs() then
		local bugName = bugTypes[getBugTier()]
		if bugName == "All" then bugName = nil end
		cf, obj = getClosest("bug", 3, bugName)
		if cf then return cf, obj, "bug", 3 end
	end
	if autoBreakables() then
		local breakName = breakableTypes[getBreakTier()]
		if breakName == "All" then breakName = nil end
		cf, obj = getClosest("breakable", 3, breakName)
		if cf then return cf, obj, "breakable", 3 end
	end
	return nil
end

task.spawn(function()
	local currentObj, currentCategory, currentY, targetStart = nil, nil, 0, 0

	while ScreenGui and ScreenGui.Parent do
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if root then
			-- Still locked on a target: stay on it until it dies
			if currentObj then
				local isOrb = (currentCategory == "orb" or currentCategory == "sandorb" or currentCategory == "voidorb")
				local limit = isOrb and ORB_TIMEOUT or FIGHT_TIMEOUT

				if isGone(currentObj, currentCategory) or (tick() - targetStart) >= limit then
					blacklistedTargets[currentObj] = true
					currentObj = nil
				else
					local part = getTargetPart(currentObj)
					if part and (root.Position - part.Position).Magnitude > STAY_DISTANCE then
						pcall(teleportTo, part.CFrame + Vector3.new(0, currentY, 0))
					end
				end
			end

			-- No target: pick the next one and teleport to it once
			if not currentObj then
				local cf, obj, cat, y = pickTarget()
				if cf and obj then
					currentObj, currentCategory, currentY, targetStart = obj, cat, y, tick()
					pcall(teleportTo, cf)
				end
			end
		end

		task.wait(cooldown)
	end
end)
