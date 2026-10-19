-- Skrip contoh untuk Delta Executor (Fly & NoClip)
-- Gunakan dengan bijak. Risiko ditanggung pengguna.

local player = game:GetService("Players").LocalPlayer
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Variabel status
local flyEnabled = false
local noclipEnabled = false
local flySpeed = 50

-- Fungsi untuk membuat GUI sederhana
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaScriptGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true -- GUI bisa digeser
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Delta Script Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Tombol Fly
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 30)
flyButton.Position = UDim2.new(0.05, 0, 0.3, 0)
flyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyButton.Text = "Fly: OFF"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.SourceSans
flyButton.TextSize = 16
flyButton.Parent = frame

-- Tombol NoClip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 30)
noclipButton.Position = UDim2.new(0.05, 0, 0.55, 0)
noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipButton.Text = "NoClip: OFF"
noclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipButton.Font = Enum.Font.SourceSans
noclipButton.TextSize = 16
noclipButton.Parent = frame

-- Logika Fly
flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if flyEnabled and humanoid and rootPart then
        humanoid.PlatformStand = true
    else
        if humanoid then humanoid.PlatformStand = false end
    end
end)

-- Loop untuk Fly (dijalankan setiap frame)
runService.RenderStepped:Connect(function()
    if flyEnabled then
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local camera = workspace.CurrentCamera
            if rootPart and camera then
                -- Gerakan maju berdasarkan arah kamera
                local moveDirection = Vector3.new()
                if userInput:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if userInput:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if userInput:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if userInput:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                if userInput:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                if moveDirection.Magnitude > 0 then
                    rootPart.Velocity = moveDirection.Unit * flySpeed
                else
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

-- Logika NoClip
noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipButton.Text = "NoClip: " .. (noclipEnabled and "ON" or "OFF")
end)

-- Loop untuk NoClip (dijalankan setiap 0.1 detik)
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

print("Delta Script Loaded")