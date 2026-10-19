-- Skrip Delta Executor (Fly + WalkSpeed + Atur Kecepatan)
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")

local flyEnabled = false
local noclipEnabled = false
local walkEnabled = false
local flySpeed = 30
local walkSpeed = 32
local defaultWalkSpeed = 16
local isDescending = false

-- ==========================================
-- GUI UTAMA
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaScriptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 280)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Delta Script Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = mainFrame

local function makeButton(text, pos, size, color, textSize)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = textSize or 16
    b.Parent = mainFrame
    return b
end

local minBtn = makeButton("-", UDim2.new(1, -60, 0, 0), UDim2.new(0, 30, 0, 30), Color3.fromRGB(200, 150, 50), 20)
local closeBtn = makeButton("X", UDim2.new(1, -30, 0, 0), UDim2.new(0, 30, 0, 30), Color3.fromRGB(150, 50, 50), 16)

local btnSize = UDim2.new(0.9, 0, 0, 32)
local grey = Color3.fromRGB(70, 70, 70)

local flyButton = makeButton("Fly: OFF", UDim2.new(0.05, 0, 0, 40), btnSize, grey)
-- baris atur fly speed ada di y = 78
local noclipButton = makeButton("NoClip: OFF", UDim2.new(0.05, 0, 0, 116), btnSize, grey)
local walkButton = makeButton("WalkSpeed: OFF", UDim2.new(0.05, 0, 0, 154), btnSize, grey)
-- baris atur walk speed ada di y = 192
local descendBtn = makeButton("Tahan untuk Turun", UDim2.new(0.05, 0, 0, 232), btnSize, Color3.fromRGB(100, 100, 200), 14)
descendBtn.Visible = false

local floatingBtn = Instance.new("TextButton")
floatingBtn.Size = UDim2.new(0, 45, 0, 45)
floatingBtn.Position = UDim2.new(0, 20, 0, 100)
floatingBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
floatingBtn.Text = "DS"
floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.Font = Enum.Font.SourceSansBold
floatingBtn.TextSize = 20
floatingBtn.Visible = false
floatingBtn.Active = true
floatingBtn.Draggable = true
floatingBtn.Parent = screenGui

descendBtn.MouseButton1Down:Connect(function() isDescending = true end)
descendBtn.MouseButton1Up:Connect(function() isDescending = false end)
descendBtn.MouseLeave:Connect(function() isDescending = false end)

-- ==========================================
-- BARIS ATUR KECEPATAN (- nilai +)
-- ==========================================
local function createSpeedRow(yPos, name, getValue, setValue, step, minV, maxV)
    local minus = makeButton("-", UDim2.new(0.05, 0, 0, yPos), UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(150, 70, 70), 20)
    local plus = makeButton("+", UDim2.new(0.75, 0, 0, yPos), UDim2.new(0.2, 0, 0, 30), Color3.fromRGB(70, 150, 70), 20)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.44, 0, 0, 30)
    label.Position = UDim2.new(0.28, 0, 0, yPos)
    label.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Parent = mainFrame

    local function refresh()
        label.Text = name .. ": " .. getValue()
    end
    refresh()

    minus.MouseButton1Click:Connect(function()
        setValue(math.max(minV, getValue() - step))
        refresh()
    end)
    plus.MouseButton1Click:Connect(function()
        setValue(math.min(maxV, getValue() + step))
        refresh()
    end)
end

createSpeedRow(78, "Fly Speed",
    function() return flySpeed end,
    function(v) flySpeed = v end,
    5, 5, 200)

createSpeedRow(192, "Walk Speed",
    function() return walkSpeed end,
    function(v) walkSpeed = v end,
    4, 16, 200)

-- ==========================================
-- FUNGSI FLY
-- ==========================================
local function updateFlyPhysics()
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if flyEnabled then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    else
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    descendBtn.Visible = flyEnabled
    updateFlyPhysics()
end)

runService.Heartbeat:Connect(function(dt)
    if not flyEnabled then return end

    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    if not (humanoid and rootPart and cam) then return end

    local localMove = cam.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
    local moveDir = (cam.CFrame.LookVector * -localMove.Z)
                  + (cam.CFrame.RightVector * localMove.X)

    if userInput:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if isDescending then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    if moveDir.Magnitude > 0.05 then
        local step = moveDir.Unit * flySpeed * dt
        local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
        rootPart.CFrame = CFrame.lookAt(rootPart.Position + step, rootPart.Position + step + look)
    end
end)

-- ==========================================
-- WALK SPEED
-- ==========================================
walkButton.MouseButton1Click:Connect(function()
    walkEnabled = not walkEnabled
    walkButton.Text = "WalkSpeed: " .. (walkEnabled and "ON" or "OFF")

    if not walkEnabled then
        local character = player.Character
        local humanoid = char
