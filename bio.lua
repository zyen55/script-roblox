--[[
    FEAST AUTO CYCLE - STRICT SEQUENCE / MOBILE EXECUTOR

    Alur WAJIB:
      1. Baca counter buah pemain.
      2. Ambil bubble satu per satu sampai counter benar-benar 10/10.
      3. Baru teleport ke Feast Plate.
      4. Tunggu sampai prompt plate menunjukkan "eat" (buah sudah masuk 10/10).
      5. Jalankan Eat 10 kali, satu per satu.
      6. Tunggu sampai plate keluar dari status "eat" / kembali 0/10.
      7. Baru mulai mencari bubble untuk putaran berikutnya.

    UI HP: tombol (-)/(+), MULAI, STOP, panel dapat digeser.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("Feast Auto: jalankan script dari executor saat sudah berada di dalam game.")
end

local CONFIG = {
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

    -- Posisi berhenti di dekat PlatePromptSpot, bukan di tengah piring.
    PLATE_OFFSET = CFrame.new(0, 2, 3),
}

local running = false
local minimized = false
local currentCount = 0
local ui, panel, statusLabel, countLabel, startButton, stopButton, minButton

local function status(s)
    if statusLabel then statusLabel.Text = "Status: " .. s end
end

local function showCount(n)
    currentCount = math.clamp(tonumber(n) or 0, 0, CONFIG.MAX)
    if countLabel then
        countLabel.Text = "Buah pemain: " .. currentCount .. "/" .. CONFIG.MAX
    end
end

local function characterRoot()
    local character = LocalPlayer.Character
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
    local spot = findPath(Workspace, CONFIG.PLATE_PATH)
    local area = Workspace:FindFirstChild("FeastArea", true)

    if not spot and area then
        spot = area:FindFirstChild("PlatePromptSpot", true)
    end

    local prompt = spot and spot:FindFirstChild(CONFIG.PROMPT_NAME, true)
    if not prompt and area then
        prompt = area:FindFirstChild(CONFIG.PROMPT_NAME, true)
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

-- Hanya mengambil counter UI yang menyebut fruit/bubble/food/feast.
-- Jika counter tidak terbaca, script TIDAK akan mengarang angka.
local function readPlayerFruitCount()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end

    local found = nil
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
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

local function teleport(cf)
    local root = characterRoot()
    if not root then return false end
    root.CFrame = cf
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function findBubbleParts()
    local results = {}
    local exact = findPath(Workspace, CONFIG.BUBBLE_PATH)

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

    -- Fallback: teleport directly onto/near the bubble to trigger normal touch.
    return teleport(part.CFrame * CFrame.new(0, 2, 0))
end

local function waitForPlayerCount(target, timeout)
    local started = os.clock()
    while running and os.clock() - started < timeout do
        local n = readPlayerFruitCount()
        if n ~= nil then
            showCount(n)
            if n >= target then return true end
        end
        task.wait(0.15)
    end
    return false
end

local function collectUntilFull()
    status("Memeriksa counter buah")
    local initial = readPlayerFruitCount()
    if initial == nil then
        status("Counter buah tidak terbaca - berhenti")
        return false
    end

    showCount(initial)

    while running do
        local count = readPlayerFruitCount()
        if count == nil then
            status("Counter hilang - menunggu")
            task.wait(0.5)
        else
            showCount(count)
            if count >= CONFIG.MAX then
                status("Buah pemain sudah 10/10")
                return true
            end

            local bubble = nearestBubble()
            if not bubble then
                status("Menunggu bubble muncul (" .. count .. "/10)")
                task.wait(CONFIG.SCAN_DELAY)
            else
                status("Mengambil bubble (" .. count .. "/10)")
                local before = count
                teleport(bubble.CFrame * CFrame.new(0, 2, 0))
                touchBubble(bubble)

                local started = os.clock()
                local confirmed = false
                while running and os.clock() - started < CONFIG.PICKUP_CONFIRM_TIMEOUT do
                    task.wait(0.15)
                    local now = readPlayerFruitCount()
                    if now ~= nil then
                        showCount(now)
                        if now > before then
                            confirmed = true
                            break
                        end
                        if now >= CONFIG.MAX then
                            confirmed = true
                            break
                        end
                    end
                end

                if not confirmed then
                    status("Bubble belum menambah counter - coba lagi")
                    task.wait(0.5)
                end
            end
        end
    end
    return false
end

local function waitForPlateFull(prompt)
    status("Menunggu buah masuk ke piring")
    local started = os.clock()

    while running and os.clock() - started < CONFIG.PLATE_CONFIRM_TIMEOUT do
        if not prompt or not prompt.Parent then
            local _, newPrompt = findPlate()
            prompt = newPrompt
        end

        if prompt then
            if eatReady(prompt) then
                status("Piring terkonfirmasi penuh - Eat tersedia")
                return true, prompt
            end

            local n = plateFoodCount(prompt)
            if n ~= nil then
                status("Isi piring: " .. n .. "/10")
            end
        end
        task.wait(0.2)
    end

    status("Piring belum terkonfirmasi 10/10")
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
    for i = 1, CONFIG.MAX do
        if not running then return false end

        -- Each action is performed separately; do not spam all ten at once.
        if not eatReady(prompt) then
            status("Eat tidak tersedia sebelum langkah " .. i .. "/10")
            return false
        end

        status("Memakan buah " .. i .. "/10")
        local ok = invokeEat(prompt)
        if not ok then
            status("Interaksi Eat gagal pada " .. i .. "/10")
            return false
        end

        task.wait(CONFIG.EAT_INTERVAL)
        local _, refreshedPrompt = findPlate()
        if refreshedPrompt then prompt = refreshedPrompt end
    end

    -- Critical gate: do not start the next collection until the plate has
    -- visibly reset from Eat to its normal 0/10 state.
    status("Memastikan semua buah sudah dimakan")
    local started = os.clock()
    while running and os.clock() - started < CONFIG.EAT_CONFIRM_TIMEOUT do
        local _, refreshedPrompt = findPlate()
        if refreshedPrompt then prompt = refreshedPrompt end

        local n = plateFoodCount(prompt)
        if not eatReady(prompt) and (n == nil or n == 0) then
            status("Piring kosong - semua buah selesai dimakan")
            return true
        end

        task.wait(0.2)
    end

    status("Belum ada konfirmasi piring kosong - tidak mulai ulang")
    return false
end

local function oneCycle()
    -- Phase 1: player inventory must reach exactly max before leaving.
    if not collectUntilFull() then return false end
    if not running then return false end

    -- Recheck immediately before teleporting.
    local count = readPlayerFruitCount()
    if count == nil or count < CONFIG.MAX then
        status("Counter belum 10/10 - kembali mengumpulkan")
        return false
    end

    -- Phase 2: teleport only after confirmed 10/10.
    local spot, prompt = findPlate()
    if not spot or not spot:IsA("BasePart") or not prompt then
        status("Feast Plate / prompt tidak ditemukan")
        return false
    end

    status("10/10 terkonfirmasi - teleport ke piring")
    if not teleport(spot.CFrame * CONFIG.PLATE_OFFSET) then
        status("Teleport gagal")
        return false
    end

    -- Phase 3: wait until the plate itself confirms full / Eat.
    local full, livePrompt = waitForPlateFull(prompt)
    if not full then return false end

    -- Phase 4: eat all ten, then confirm the plate has reset.
    return eatAllAndConfirm(livePrompt)
end

-- UI cleanup for re-execution.
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

local okParent = pcall(function() ui.Parent = CoreGui end)
if not okParent then ui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(250, 174)
panel.Position = UDim2.new(0, 18, 0.38, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 29, 37)
panel.BorderSizePixel = 0
panel.Parent = ui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(76, 91, 112)
outline.Thickness = 1
outline.Parent = panel

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -52, 0, 34)
header.Position = UDim2.fromOffset(12, 3)
header.BackgroundTransparency = 1
header.Text = "FEAST AUTO"
header.TextColor3 = Color3.fromRGB(245, 247, 250)
header.TextSize = 16
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

minButton = Instance.new("TextButton")
minButton.Size = UDim2.fromOffset(34, 28)
minButton.Position = UDim2.new(1, -42, 0, 5)
minButton.BackgroundColor3 = Color3.fromRGB(57, 66, 82)
minButton.Text = "-"
minButton.TextColor3 = Color3.new(1, 1, 1)
minButton.TextSize = 22
minButton.Font = Enum.Font.GothamBold
minButton.Parent = panel
Instance.new("UICorner", minButton).CornerRadius = UDim.new(0, 7)

statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 27)
statusLabel.Position = UDim2.fromOffset(12, 43)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Siap"
statusLabel.TextColor3 = Color3.fromRGB(215, 222, 232)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = panel

countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -24, 0, 22)
countLabel.Position = UDim2.fromOffset(12, 75)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Buah pemain: 0/10"
countLabel.TextColor3 = Color3.fromRGB(180, 205, 235)
countLabel.TextSize = 12
countLabel.Font = Enum.Font.Gotham
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = panel

startButton = Instance.new("TextButton")
startButton.Size = UDim2.new(0.5, -16, 0, 42)
startButton.Position = UDim2.fromOffset(12, 119)
startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
startButton.Text = "MULAI"
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.TextSize = 14
startButton.Font = Enum.Font.GothamBold
startButton.Parent = panel
Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 8)

stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.5, -16, 0, 42)
stopButton.Position = UDim2.new(0.5, 4, 0, 119)
stopButton.BackgroundColor3 = Color3.fromRGB(170, 55, 55)
stopButton.Text = "STOP"
stopButton.TextColor3 = Color3.new(1, 1, 1)
stopButton.TextSize = 14
stopButton.Font = Enum.Font.GothamBold
stopButton.Parent = panel
Instance.new("UICorner", stopButton).CornerRadius = UDim.new(0, 8)

-- Touch-friendly dragging.
local dragging, dragInput, dragStart, startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
    if dragging and dragInput and dragStart and startPosition then
        local delta = dragInput.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

minButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    statusLabel.Visible = not minimized
    countLabel.Visible = not minimized
    startButton.Visible = not minimized
    stopButton.Visible = not minimized
    panel.Size = minimized and UDim2.fromOffset(250, 42) or UDim2.fromOffset(250, 174)
    minButton.Text = minimized and "+" or "-"
end)

local function stop()
    running = false
    status("Dihentikan")
    startButton.Text = "MULAI"
    startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
end

local function start()
    if running then return end
    running = true
    startButton.Text = "AKTIF"
    startButton.BackgroundColor3 = Color3.fromRGB(40, 130, 75)

    task.spawn(function()
        while running do
            local ok, result = pcall(oneCycle)
            if not ok then
                status("Error: " .. tostring(result))
                task.wait(1)
            elseif result then
                task.wait(CONFIG.CYCLE_PAUSE)
            else
                -- If a phase was not confirmed, do not jump ahead. Retry
                -- from the collection phase only after a short pause.
                task.wait(1)
            end
        end
        startButton.Text = "MULAI"
        startButton.BackgroundColor3 = Color3.fromRGB(35, 145, 85)
    end)
end

startButton.MouseButton1Click:Connect(start)
stopButton.MouseButton1Click:Connect(stop)

status("Siap - tekan MULAI")
