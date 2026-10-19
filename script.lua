-- Skrip Delta Executor (Smooth Fly + Joystick Bawaan)
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")

local flyEnabled = false
local noclipEnabled = false
local flySpeed = 60 -- Kecepatan terbang

-- Variabel Fisika
local bodyVelocity = nil
local bodyGyro = nil

-- ==========================================
-- GUI UTAMA
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaScriptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 160)
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

-- Tombol Sembunyikan (-) dan Close (X)
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

-- Tombol Fitur
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

-- Tombol Melayang (Floating)
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

-- ==========================================
-- FUNGSI FLY (MENGGUNAKAN JOYSTICK BAWAAN)
-- ==========================================
local function updateFlyPhysics()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if flyEnabled and rootPart and humanoid then
        humanoid.PlatformStand = true -- Mematikan animasi jatuh
        
        -- Hapus physics lama jika ada
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end

        -- Buat BodyVelocity baru
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0,0,0)
        bodyVelocity.Parent = rootPart

        -- Buat BodyGyro agar badan tetap tegak
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 1000
        bodyGyro.D = 50
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart
    else
        -- Matikan Fly
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        if humanoid then humanoid.PlatformStand = false end
    end
end

flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    updateFlyPhysics()
end)

-- ==========================================
-- LOGIKA PERGERAKAN (SETIAP FRAME)
-- ==========================================
runService.RenderStepped:Connect(function()
    if flyEnabled then
        local character = player.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local camera = workspace.CurrentCamera
        
        if rootPart and humanoid and bodyVelocity and bodyGyro then
            -- 1. Ambil arah dari Joystick Bawaan Roblox
            local moveVector = humanoid.MoveDirection 
            
            -- Jika joystick digeser, terbang mengikuti arah kamera
            local moveDir = Vector3.new(0,0,0)
            if moveVector.Magnitude > 0 then
                -- Ambil arah berdasarkan hadap kamera
                local camCFrame = camera.CFrame
                local forward = camCFrame.LookVector
                local right = camCFrame.RightVector
                
                -- Gabungkan gerakan
                moveDir = (forward * moveVector.Z + right * moveVector.X).Unit
            end

            -- 2. Cek tombol Jump (Lompat) untuk naik ke atas
            -- (Karena di HP tidak ada tombol Ctrl, kita pakai logika: jika menekan lompat, terbang ke atas)
            if userInput:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            
            -- Opsional: Jika menekan tombol keyboard Shift/C di PC untuk turun
            if userInput:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end

            -- 3. Terapkan kecepatan
            if moveDir.Magnitude > 0 then
                bodyVelocity.Velocity = moveDir * flySpeed
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Berhenti jika joystick dilepas
            end

            -- 4. Kunci putaran badan agar tidak oleng
            bodyGyro.CFrame = camera.CFrame
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

print("Delta Script Loaded - Smooth Fly & Native Joystick")
