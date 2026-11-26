--[[
    FEAST AUTO CYCLE - MOBILE
    Flow: Collect 10 bubbles -> teleport to Feast Plate -> wait for deposit
          -> press Eat 10 times individually -> repeat.

    UI:
      (-)  Minimize / restore
      MULAI Start automation
      STOP  Stop automation

    Notes:
      - Designed around the Feast paths supplied by the user.
      - Uses executor-supported touch/prompt functions when available.
      - If the game changes its object paths or HUD counter, update the
        CONFIG section below.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local CONFIG = {
    MaxFruit = 10,
    BubblePath = {"FeastFruit", "FeastFruit", "Bubble"},
    PlatePath = {"FeastArea", "PlatePromptSpot"},
    PromptName = "FeastPlatePrompt",
    BubbleScanInterval = 0.35,
    CollectTimeout = 7,
    DepositTimeout = 12,
    EatDelay = 0.35,
    CycleDelay = 0.8,
    TeleportOffset = CFrame.new(0, 2, 3),
    RestorePosition = false, -- set true to return to the previous position after each cycle
}

local running = false
local minimized = false
local statusText = "Siap"
local collectedThisCycle = 0
local previousPosition = nil
local ui, panel, statusLabel, countLabel, minimizeButton
local startButton, stopButton

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function setStatus(message)
    statusText = message
    if statusLabel then
        statusLabel.Text = "Status: " .. message
    end
end

local function setCount(value)
    collectedThisCycle = value
    if countLabel then
        countLabel.Text = "Bubble: " .. tostring(value) .. "/" .. tostring(CONFIG.MaxFruit)
    end
end

local function safeFindPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

local function getBubbleContainer()
    local exact = safeFindPath(Workspace, CONFIG.BubblePath)
    if exact then return exact end

    local feastFruit = Workspace:FindFirstChild("FeastFruit", true)
    if feastFruit then
        local bubble = feastFruit:FindFirstChild("Bubble", true)
        if bubble then return bubble.Parent end
    end
    return nil
end

local function getPlateParts()
    local spot = safeFindPath(Workspace, CONFIG.PlatePath)
    if not spot then
        local area = Workspace:FindFirstChild("FeastArea", true)
        spot = area and area:FindFirstChild("PlatePromptSpot", true)
    end

    local prompt = nil
    if spot then
        prompt = spot:FindFirstChild(CONFIG.PromptName, true)
    end

    if not prompt then
        local area = Workspace:FindFirstChild("FeastArea", true)
        if area then
            prompt = area:FindFirstChild(CONFIG.PromptName, true)
            if not spot then
                spot = area:FindFirstChild("PlatePromptSpot", true)
            end
        end
    end

    return spot, prompt
end

local function getPromptAction(prompt)
    if not prompt then return "" end
    return string.lower(tostring(prompt.ActionText or ""))
end

local function isEatReady(prompt)
    local action = getPromptAction(prompt)
    return action == "eat" or string.find(action, "eat", 1, true) ~= nil
end

local function getPlateCount(prompt)
    if not prompt then return nil end
    local action = tostring(prompt.ActionText or "")
    local n = string.match(action, "%((%d+)%s*/%s*10")
    if n then return tonumber(n) end
    n = string.match(action, "(%d+)%s*/%s*10")
    if n then return tonumber(n) end
    return nil
end

-- Reads a visible player HUD counter such as 9/10.
local function readFruitCounter()
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end

    local best = nil
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local text = tostring(obj.Text or "")
            local a, b = string.match(text, "(%d+)%s*/%s*(10)")
            if a and b then
                local lower = string.lower(obj.Name .. " " .. text)
                if string.find(lower, "fruit", 1, true)
                    or string.find(lower, "bubble", 1, true)
                    or string.find(lower, "food", 1, true)
                    or string.find(lower, "feast", 1, true) then
                    best = tonumber(a)
                end
            end
        end
    end
    return best
end

local function teleportTo(cf)
    local root = getRoot()
    if not root then return false end
    root.CFrame = cf
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function touchPart(part)
    local root = getRoot()
    if not root or not part or not part:IsA("BasePart") then return false end

    local touchFn = firetouchinterest
    if type(touchFn) == "function" then
        pcall(function()
            touchFn(root, part, 0)
            task.wait(0.08)
            touchFn(root, part, 1)
        end)
        return true
    end

    -- Fallback: briefly place the character on the bubble so normal touch
    -- detection can occur in executors without firetouchinterest.
    pcall(function()
        root.CFrame = part.CFrame + Vector3.new(0, 2, 0)
    end)
    return true
end

local function getBubbleParts()
    local container = getBubbleContainer()
    local found = {}

    if container then
        if container:IsA("BasePart") then
            table.insert(found, container)
        else
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "bubble", 1, true) then
                    table.insert(found, obj)
                end
            end
        end
    end

    -- Fallback search for bubble-named BaseParts in Workspace.
    if #found == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and string.lower(obj.Name) == "bubble" then
                table.insert(found, obj)
            end
        end
    end

    return found
end

local function chooseNearestBubble()
    local root = getRoot()
    if not root then return nil end

    local nearest, distance = nil, math.huge
    for _, bubble in ipairs(getBubbleParts()) do
        if bubble and bubble.Parent and bubble:IsDescendantOf(Workspace) then
            local d = (root.Position - bubble.Position).Magnitude
            if d < distance then
                nearest, distance = bubble, d
            end
        end
    end
    return nearest
end

local function collectOneBubble()
    local bubble = chooseNearestBubble()
    if not bubble then
        setStatus("Mencari bubble...")
        task.wait(CONFIG.BubbleScanInterval)
        return false
    end

    local oldCounter = readFruitCounter()
    local oldPosition = getRoot() and getRoot().CFrame
    setStatus("Mengambil bubble")
    teleportTo(bubble.CFrame + Vector3.new(0, 2, 0))
    touchPart(bubble)

    local started = os.clock()
    while running and os.clock() - started < CONFIG.CollectTimeout do
        task.wait(0.15)
        local newCounter = readFruitCounter()
        if oldCounter ~= nil and newCounter ~= nil and newCounter > oldCounter then
            return true
        end
        if not bubble.Parent or not bubble:IsDescendantOf(Workspace) then
            return true
        end
        -- Some game versions do not expose the inventory counter. Give the
        -- touch interaction time to register before using local cycle count.
        if os.clock() - started > 1.2 then
            return true
        end
    end

    if oldPosition and getRoot() then
        -- no forced return; the next bubble can be reached directly
    end
    return false
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt, 1)
        end)
        if ok then return true end
    end

    -- Fallback for executors exposing prompt input methods.
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.05))
        prompt:InputHoldEnd()
    end)
    return ok
end

local function goToPlateAndDeposit()
    local spot, prompt = getPlateParts()
    if not spot or not spot:IsA("BasePart") or not prompt then
        setStatus("Plate/prompt tidak ditemukan")
        return false
    end

    setStatus("Teleport ke piring")
    local target = spot.CFrame * CONFIG.TeleportOffset
    if not teleportTo(target) then return false end

    local started = os.clock()
    while running and os.clock() - started < CONFIG.DepositTimeout do
        task.wait(0.2)

        if isEatReady(prompt) then
            return true
        end

        local plateCount = getPlateCount(prompt)
        local inventoryCount = readFruitCounter()

        -- Deposit is automatic when close to the plate. Stay beside it while
        -- the server updates the plate counter / prompt text.
        if plateCount ~= nil and plateCount >= CONFIG.MaxFruit then
            return true
        end

        if inventoryCount ~= nil and inventoryCount == 0 and plateCount ~= nil
            and plateCount >= CONFIG.MaxFruit then
            return true
        end

        local root = getRoot()
        if root and (root.Position - target.Position).Magnitude > 7 then
            teleportTo(target)
        end
    end

    return isEatReady(prompt)
end

local function eatTenTimes()
    local spot, prompt = getPlateParts()
    if not prompt then
        setStatus("Prompt makan tidak ditemukan")
        return false
    end

    setStatus("Makan 10 kali")
    for i = 1, CONFIG.MaxFruit do
        if not running then return false end

        local started = os.clock()
        while running and not isEatReady(prompt) and os.clock() - started < 5 do
            task.wait(0.15)
        end

        if not running then return false end
        if not isEatReady(prompt) then
            setStatus("Menunggu tombol Eat")
            return false
        end

        setStatus("Makan " .. tostring(i) .. "/10")
        triggerPrompt(prompt)
        task.wait(CONFIG.EatDelay)
    end
    return true
end

local function runCycle()
    setCount(0)
    setStatus("Mengumpulkan bubble")

    local noProgress = 0
    while running and collectedThisCycle < CONFIG.MaxFruit do
        local before = readFruitCounter()
        local ok = collectOneBubble()
        if not running then return end

        if ok then
            local after = readFruitCounter()
            if before ~= nil and after ~= nil then
                setCount(math.clamp(after, 0, CONFIG.MaxFruit))
            else
                setCount(collectedThisCycle + 1)
            end
            noProgress = 0
        else
            noProgress = noProgress + 1
            if noProgress >= 8 then
                setStatus("Bubble belum ditemukan")
                task.wait(1)
                noProgress = 0
            end
        end

        local hud = readFruitCounter()
        if hud ~= nil then
            setCount(math.clamp(hud, 0, CONFIG.MaxFruit))
        end
        task.wait(CONFIG.BubbleScanInterval)
    end

    if not running then return end

    if CONFIG.RestorePosition and getRoot() then
        previousPosition = getRoot().CFrame
    end

    if not goToPlateAndDeposit() then
        setStatus("Gagal deposit - coba ulang")
        task.wait(1)
        return
    end

    if not eatTenTimes() then
        task.wait(1)
        return
    end

    if CONFIG.RestorePosition and previousPosition then
        teleportTo(previousPosition)
        previousPosition = nil
    end

    setStatus("Siklus selesai")
    task.wait(CONFIG.CycleDelay)
end

local function startAutomation()
    if running then return end
    running = true
    startButton.Text = "BERJALAN"
    startButton.BackgroundColor3 = Color3.fromRGB(40, 130, 75)
    setStatus("Memulai...")

    task.spawn(function()
        while running do
            local ok, err = pcall(runCycle)
            if not ok then
                setStatus("Error: " .. tostring(err))
                task.wait(1)
            end
            if running then task.wait(0.2) end
        end
        setStatus("Dihentikan")
        startButton.Text = "MULAI"
        startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
    end)
end

local function stopAutomation()
    running = false
    setStatus("Menghentikan...")
    if startButton then
        startButton.Text = "MULAI"
        startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
    end
end

-- Remove an earlier copy of this UI if the script is executed again.
pcall(function()
    local old = CoreGui:FindFirstChild("FeastAutoCycleMobile")
    if old then old:Destroy() end
end)
pcall(function()
    local old = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FeastAutoCycleMobile")
    if old then old:Destroy() end
end)

ui = Instance.new("ScreenGui")
ui.Name = "FeastAutoCycleMobile"
ui.ResetOnSpawn = false
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = pcall(function()
    ui.Parent = CoreGui
end)
if not parented then
    ui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(245, 166)
panel.Position = UDim2.new(0, 18, 0.38, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 29, 37)
panel.BorderSizePixel = 0
panel.Parent = ui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(76, 91, 112)
stroke.Thickness = 1
stroke.Parent = panel

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -48, 0, 34)
header.Position = UDim2.fromOffset(12, 3)
header.BackgroundTransparency = 1
header.Text = "FEAST AUTO"
header.TextColor3 = Color3.fromRGB(245, 247, 250)
header.TextSize = 16
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.fromOffset(32, 28)
minimizeButton.Position = UDim2.new(1, -40, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(57, 66, 82)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 22
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = panel
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 7)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 24)
statusLabel.Position = UDim2.fromOffset(12, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Siap"
statusLabel.TextColor3 = Color3.fromRGB(215, 222, 232)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -24, 0, 22)
countLabel.Position = UDim2.fromOffset(12, 66)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Bubble: 0/10"
countLabel.TextColor3 = Color3.fromRGB(180, 205, 235)
countLabel.TextSize = 12
countLabel.Font = Enum.Font.Gotham
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = panel

startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.5, -16, 0, 42)
startButton.Position = UDim2.fromOffset(12, 108)
startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
startButton.Text = "MULAI"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = panel
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)

stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.5, -16, 0, 42)
stopButton.Position = UDim2.new(0.5, 4, 0, 108)
stopButton.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = panel
Instance.new("UICorner", stopButton).CornerRadius = UDim.new(0, 8)

-- Drag panel using touch or mouse.
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput and dragStart and startPos then
        local delta = dragInput.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    statusLabel.Visible = not minimized
    countLabel.Visible = not minimized
    startButton.Visible = not minimized
    stopButton.Visible = not minimized
    panel.Size = minimized and UDim2.fromOffset(245, 40) or UDim2.fromOffset(245, 166)
    minimizeButton.Text = minimized and "+" or "-"
end)

startButton.MouseButton1Click:Connect(startAutomation)
stopButton.MouseButton1Click:Connect(stopAutomation)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if running then
        setStatus("Karakter respawn - lanjut")
    end
end)

setStatus("Siap - tekan MULAI")
