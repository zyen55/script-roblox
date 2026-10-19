-- Skrip Delta Executor (Kontrol Fly Mengikuti Kamera)
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")

local flyEnabled = false
local noclipEnabled = false
local flySpeed = 65

local bodyVelocity = nil
local bodyGyro = nil
local isDescending = false

-- ==========================================
-- GUI UTAMA
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaScriptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 200)
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

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -60, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 20
minBtn.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 35)
flyButton.Position = UDim2.new(0.05, 0, 0, 45)
flyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyButton.Text = "Fly: OFF"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.SourceSansBold
flyButton.TextSize = 16
flyButton.Parent = mainFrame

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 35)
noclipButton.Position = UDim2.new(0.05, 0, 0, 95)
noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipButton.Text = "NoClip: OFF"
noclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipButton.Font = Enum.Font.SourceSansBold
noclipButton.TextSize = 16
noclipButton.Parent = mainFrame

local descendBtn = Instance.new("TextButton")
descendBtn.Size = UDim2.new(0.9, 0, 0, 35)
descendBtn.Position = UDim2.new(0.05, 0, 0, 145)
descendBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
descendBtn.Text = "Tahan untuk Turun"
descendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
descendBtn.Font = Enum.Font.SourceSansBold
descendBtn.TextSize = 14
descendBtn.Visible = false
descendBtn.Parent = mainFrame

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
-- FUNGSI FLY
-- ==========================================
local function updateFlyPhysics()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if flyEnabled and rootPart and humanoid then
        humanoid.PlatformStand = true
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 1000
        bodyGyro.D = 50
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        if humanoid then humanoid.PlatformStand = false end
    end
end

flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    descendBtn.Visible = flyEnabled
    updateFlyPhysics()
end)

-- ==========================================
-- LOGIKA PERGERAKAN (MENGIKUTI KAMERA)
-- ==========================================
runService.RenderStepped:Connect(function()
    if not flyEnabled then return end

    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera

    if humanoid and rootPart and bodyVelocity and bodyGyro and cam then
        -- Ubah arah joystick (world space) ke input maju/kanan relatif kamera
        local localMove = cam.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
        local forwardAmount = -localMove.Z
        local rightAmount = localMove.X

        local moveDir = (cam.CFrame.LookVector * forwardAmount)
                      + (cam.CFrame.RightVector * rightAmount)

        -- Naik (Spasi / tombol lompat)
        if userInput:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end

        -- Turun (tombol GUI)
        if isDescending then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        -- Badan selalu menghadap arah kamera
        bodyGyro.CFrame = CFrame.new(rootPart.Position)
            * CFrame.Angles(0, math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z), 0)

        if moveDir.Magnitude > 0.05 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.zero
        end
    end
end)

-- ==========================================
-- LOGIKA NOCLIP & TOMBOL SEMBUNYI
-- ==========================================
noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipButton.Text = "NoClip: " .. (noclipEnabled and "ON" or "OFF")
end)

task.spawn(function()
    while task.wait(0.1) do
        if noclipEnabled then
            local character = player.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

local function hideMenu()
    mainFrame.Visible = false
    floatingBtn.Visible = true
end

local function showMenu()
    mainFrame.Visible = true
    floatingBtn.Visible = false
end

closeBtn.MouseButton1Click:Connect(hideMenu)
minBtn.MouseButton1Click:Connect(hideMenu)
floatingBtn.MouseButton1Click:Connect(showMenu)

print("Delta Script Loaded - Fly Mengikuti Kamera")
