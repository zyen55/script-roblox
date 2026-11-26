-- DAUSHUB | AUTO FEAST CYCLE (MOBILE)
-- Standalone: collect Feast Bubbles -> walk to Feast Plate -> eat -> repeat.
-- No legacy DAUSHUB farming/combat features are included.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("DaushubFeastUI")
if old then old:Destroy() end

local running = false
local delaySeconds = 0.35
local collected = 0
local phase = "STOPPED"
local cycleCount = 0

local function characterParts()
    local character = LocalPlayer.Character
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return nil end
    return character, root, humanoid
end

local function findBubbleFolder()
    local feastFruit = Workspace:FindFirstChild("FeastFruit")
    if not feastFruit then return nil end
    return feastFruit:FindFirstChild("FeastFruit") or feastFruit
end

local function findFeastPrompt()
    local area = Workspace:FindFirstChild("FeastArea")
    local spot = area and area:FindFirstChild("PlatePromptSpot")
    local prompt = spot and spot:FindFirstChild("FeastPlatePrompt")
    return spot, prompt
end

local function getActionText(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        return string.lower(tostring(prompt.ActionText or ""))
    end
    return ""
end


-- Read the game's real fruit counter from PlayerGui, e.g. "9/10".
local function readFruitCounter()
    local matches = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local current, maximum = tostring(obj.Text or ""):match("(%d+)%s*/%s*(%d+)")
            current, maximum = tonumber(current), tonumber(maximum)
            if current and maximum == 10 and current >= 0 and current <= maximum then
                local names = string.lower(obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
                local priority = (names:find("fruit") or names:find("food") or names:find("bubble")) and 1 or 2
                table.insert(matches, {current = current, priority = priority})
            end
        end
    end
    table.sort(matches, function(a, b) return a.priority < b.priority end)
    if matches[1] then return matches[1].current, 10 end
    return nil, nil
end

local function nearestBubble()
    local folder = findBubbleFolder()
    local _, root = characterParts()
    if not folder or not root then return nil end

    local best, bestDistance = nil, math.huge
    for _, item in ipairs(folder:GetDescendants()) do
        if item:IsA("BasePart") and item.Name == "Bubble" then
            local distance = (root.Position - item.Position).Magnitude
            if distance < bestDistance then
                best, bestDistance = item, distance
            end
        end
    end
    return best
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DaushubFeastUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(292, 260)
panel.Position = UDim2.new(0.5, -146, 0.5, -130)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 82, 110)
stroke.Thickness = 1
stroke.Parent = panel

local scale = Instance.new("UIScale")
scale.Parent = panel
local function updateScale()
    local camera = Workspace.CurrentCamera
    if camera then
        local v = camera.ViewportSize
        scale.Scale = math.clamp(math.min(v.X / 350, v.Y / 460), 0.76, 1)
    end
end
updateScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(31, 39, 54)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 13)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(1, -58, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "DAUSHUB  •  FEAST CYCLE"
title.TextColor3 = Color3.fromRGB(235, 241, 255)
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(29, 27)
minimize.Position = UDim2.new(1, -36, 0, 6)
minimize.BackgroundColor3 = Color3.fromRGB(66, 79, 101)
minimize.Text = "—"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 17
minimize.Parent = header
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 7)

local function makeLabel(y, textValue, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(14, y)
    label.Size = UDim2.new(1, -28, 0, 22)
    label.Font = Enum.Font.Gotham
    label.Text = textValue
    label.TextColor3 = color or Color3.fromRGB(205, 215, 232)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = panel
    return label
end

local statusLabel = makeLabel(49, "Status: STOPPED", Color3.fromRGB(255, 190, 110))
local phaseLabel = makeLabel(74, "Tahap: Menunggu", Color3.fromRGB(190, 205, 225))
local countLabel = makeLabel(99, "Bubble: 0 / 10   |   Siklus: 0")

local delayLabel = makeLabel(128, "Jeda antar aksi: 0.35 s")
local slower = Instance.new("TextButton")
slower.Position = UDim2.fromOffset(14, 154)
slower.Size = UDim2.fromOffset(118, 30)
slower.BackgroundColor3 = Color3.fromRGB(48, 59, 79)
slower.Text = "LEBIH LAMBAT  +"
slower.TextColor3 = Color3.new(1, 1, 1)
slower.Font = Enum.Font.GothamBold
slower.TextSize = 10
slower.Parent = panel
Instance.new("UICorner", slower).CornerRadius = UDim.new(0, 7)

local faster = Instance.new("TextButton")
faster.Position = UDim2.fromOffset(160, 154)
faster.Size = UDim2.fromOffset(118, 30)
faster.BackgroundColor3 = Color3.fromRGB(48, 59, 79)
faster.Text = "LEBIH CEPAT  −"
faster.TextColor3 = Color3.new(1, 1, 1)
faster.Font = Enum.Font.GothamBold
faster.TextSize = 10
faster.Parent = panel
Instance.new("UICorner", faster).CornerRadius = UDim.new(0, 7)

local startButton = Instance.new("TextButton")
startButton.Position = UDim2.fromOffset(14, 198)
startButton.Size = UDim2.fromOffset(118, 38)
startButton.BackgroundColor3 = Color3.fromRGB(34, 145, 94)
startButton.Text = "START"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 13
startButton.Parent = panel
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)

local stopButton = Instance.new("TextButton")
stopButton.Position = UDim2.fromOffset(160, 198)
stopButton.Size = UDim2.fromOffset(118, 38)
stopButton.BackgroundColor3 = Color3.fromRGB(163, 62, 69)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 13
stopButton.Parent = panel
Instance.new("UICorner", stopButton).CornerRadius = UDim.new(0, 8)

local footer = makeLabel(239, "Bubble → Plate → Eat → Repeat", Color3.fromRGB(130, 145, 166))
footer.TextSize = 10

local restore = Instance.new("TextButton")
restore.Name = "RestoreButton"
restore.Size = UDim2.fromOffset(48, 48)
restore.Position = UDim2.new(0, 15, 0.55, 0)
restore.BackgroundColor3 = Color3.fromRGB(35, 113, 190)
restore.Text = "D"
restore.TextColor3 = Color3.new(1, 1, 1)
restore.Font = Enum.Font.GothamBlack
restore.TextSize = 22
restore.Visible = false
restore.Parent = gui
Instance.new("UICorner", restore).CornerRadius = UDim.new(1, 0)
local restoreStroke = Instance.new("UIStroke")
restoreStroke.Color = Color3.fromRGB(150, 205, 255)
restoreStroke.Thickness = 1.5
restoreStroke.Parent = restore

minimize.MouseButton1Click:Connect(function()
    panel.Visible = false
    restore.Visible = true
end)
restore.MouseButton1Click:Connect(function()
    panel.Visible = true
    restore.Visible = false
end)

local function refresh()
    statusLabel.Text = running and "Status: RUNNING" or "Status: STOPPED"
    statusLabel.TextColor3 = running and Color3.fromRGB(110, 235, 165) or Color3.fromRGB(255, 190, 110)
    phaseLabel.Text = "Tahap: " .. phase
    countLabel.Text = string.format("Bubble: %d / 10   |   Siklus: %d", collected, cycleCount)
    delayLabel.Text = string.format("Jeda antar aksi: %.2f s", delaySeconds)
end

slower.MouseButton1Click:Connect(function()
    delaySeconds = math.clamp(delaySeconds + 0.10, 0.10, 2)
    refresh()
end)
faster.MouseButton1Click:Connect(function()
    delaySeconds = math.clamp(delaySeconds - 0.05, 0.10, 2)
    refresh()
end)

local function waitWhileRunning(seconds)
    local elapsed = 0
    while running and elapsed < seconds do
        local step = math.min(0.1, seconds - elapsed)
        task.wait(step)
        elapsed += step
    end
    return running
end

local function collectOneBubble()
    local bubble = nearestBubble()
    if not bubble then
        phase = "Mencari Bubble"
        refresh()
        return false
    end

    local character, root = characterParts()
    if not character or not root then
        phase = "Menunggu karakter"
        refresh()
        return false
    end

    local beforeCount, maximum = readFruitCounter()
    if beforeCount == nil then
        phase = "Indikator buah 9/10 tidak ditemukan"
        refresh()
        return false
    end
    collected = beforeCount
    if beforeCount >= maximum then return true end

    phase = string.format("Mengambil Bubble (%d/%d)", beforeCount, maximum)
    refresh()
    pcall(function() root.CFrame = bubble.CFrame + Vector3.new(0, 2, 0) end)

    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(root, bubble, 0)
            task.wait(0.08)
            firetouchinterest(root, bubble, 1)
        end)
    else
        pcall(function() root.CFrame = bubble.CFrame end)
    end

    -- Count only after the player's HUD counter really increases.
    local deadline = os.clock() + 3.5
    while running and os.clock() < deadline do
        local nowCount = readFruitCounter()
        if nowCount ~= nil then
            collected = nowCount
            refresh()
            if nowCount > beforeCount then return true end
        end
        task.wait(0.12)
    end

    phase = "Bubble belum terkonfirmasi di indikator"
    refresh()
    return false
end
local function walkToPlate()
    local spot, prompt = findFeastPrompt()
    if not spot or not spot:IsA("BasePart") or not prompt or not prompt:IsA("ProximityPrompt") then
        phase = "Menunggu Feast Plate"
        refresh()
        return false
    end

    local _, root, humanoid = characterParts()
    if not root or not humanoid then return false end

    phase = "Berjalan ke Feast Plate"
    refresh()
    local started = os.clock()
    while running and os.clock() - started < 30 do
        local _, currentRoot, currentHumanoid = characterParts()
        if not currentRoot or not currentHumanoid then return false end

        if getActionText(prompt) == "eat" then return true end

        local hudCount = readFruitCounter()
        if hudCount ~= nil and hudCount < 10 then
            -- HUD counter decreased after reaching the plate: deposit registered.
            task.wait(0.35)
            if getActionText(prompt) == "eat" then return true end
        end

        if (currentRoot.Position - spot.Position).Magnitude > 4 then
            currentHumanoid:MoveTo(spot.Position)
        end
        task.wait(0.25)
    end
    return getActionText(prompt) == "eat"
end
local function activateEat(prompt)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)
        if ok then return true end
    end

    -- Fallback: emulate the prompt's configured keyboard key (usually E).
    local key = prompt.KeyboardKeyCode
    if key and key ~= Enum.KeyCode.Unknown then
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.08)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
        return ok
    end
    return false
end

local function eatPlate()
    local spot, prompt = findFeastPrompt()
    if not spot or not prompt or not prompt:IsA("ProximityPrompt") then
        phase = "Prompt Feast tidak ditemukan"
        refresh()
        return false
    end

    phase = "Menunggu piring penuh"
    refresh()
    local waitStart = os.clock()
    while running and os.clock() - waitStart < 35 do
        if getActionText(prompt) == "eat" then break end
        task.wait(0.2)
    end
    if not running or getActionText(prompt) ~= "eat" then
        phase = "Piring belum siap"
        refresh()
        return false
    end

    phase = "Eating 1 / 10"
    refresh()
    for i = 1, 10 do
        if not running then return false end
        -- Reacquire prompt in case the game recreates it.
        local _, currentPrompt = findFeastPrompt()
        if currentPrompt and currentPrompt:IsA("ProximityPrompt") then
            prompt = currentPrompt
        end
        if getActionText(prompt) ~= "eat" then
            -- If the game changes the action text between bites, wait briefly for it.
            local changedAt = os.clock()
            while running and os.clock() - changedAt < 2 and getActionText(prompt) ~= "eat" do
                task.wait(0.1)
            end
        end
        if getActionText(prompt) ~= "eat" then
            phase = "Menunggu piring siap lagi"
            refresh()
            return false
        end

        phase = string.format("Eating %d / 10", i)
        refresh()
        if not activateEat(prompt) then
            phase = "Interaksi eat gagal"
            refresh()
            return false
        end
        if not waitWhileRunning(math.max(0.35, delaySeconds)) then return false end
    end

    phase = "Menunggu piring kosong"
    refresh()
    local emptyStart = os.clock()
    while running and os.clock() - emptyStart < 8 do
        if getActionText(prompt) ~= "eat" then
            return true
        end
        task.wait(0.2)
    end
    -- Ten prompt interactions have been sent; allow the game to update before restarting.
    return running
end

local function mainLoop()
    while running do
        local actualCount, maximum = readFruitCounter()
        if actualCount == nil then
            collected = 0
            phase = "Tidak menemukan indikator buah 9/10"
            refresh()
            waitWhileRunning(1)
        else
            collected = actualCount
            refresh()

            while running and collected < maximum do
                local gotOne = collectOneBubble()
                if gotOne then
                    waitWhileRunning(delaySeconds)
                else
                    waitWhileRunning(0.5)
                end
            end

            if not running then break end

            local verifiedCount = readFruitCounter()
            if verifiedCount == 10 then
                collected = verifiedCount
                phase = "10/10 terverifikasi - menuju piring"
                refresh()
                local reached = walkToPlate()
                if not running then break end

                if reached then
                    eatPlate()
                    if running then
                        cycleCount = cycleCount + 1
                        collected = 0
                        phase = "Mengulang siklus"
                        refresh()
                        waitWhileRunning(0.7)
                    end
                else
                    phase = "Deposit belum terkonfirmasi"
                    refresh()
                    waitWhileRunning(1)
                end
            else
                collected = verifiedCount or 0
                phase = "Belum 10/10 - lanjut mengumpulkan"
                refresh()
                waitWhileRunning(0.5)
            end
        end
    end
    phase = "Dihentikan"
    refresh()
end

startButton.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    phase = "Memulai"
    refresh()
    task.spawn(mainLoop)
end)

stopButton.MouseButton1Click:Connect(function()
    running = false
    phase = "Menghentikan"
    refresh()
end)

-- Drag panel by its header and move the floating restore icon.
local function makeDraggable(handle, object)
    local dragging = false
    local dragInput, dragStart, startPosition
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(header, panel)
makeDraggable(restore, restore)

gui.Destroying:Connect(function()
    running = false
end)

refresh()
