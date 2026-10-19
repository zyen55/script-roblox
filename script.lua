-- Skrip Delta Executor (Fly & NoClip + Fix & Close Button)
local player = game:GetService("Players").LocalPlayer
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local flyEnabled = false
local noclipEnabled = false
local flySpeed = 50

-- Membuat GUI Utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaScriptGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 160)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true 
mainFrame.Parent = screenGui

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Delta Script Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = mainFrame

-- Tombol Close (X) di pojok kanan atas
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = mainFrame

-- Tombol Fly
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 30)
flyButton.Position = UDim2.new(0.05, 0, 0.3, 0)
flyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyButton.Text = "Fly: OFF"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.SourceSans
flyButton.TextSize = 16
flyButton.Parent = mainFrame

-- Tombol NoClip
local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 30)
noclipButton.Position = UDim2.new(0.05, 0, 0.6, 0)
noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipButton.Text = "NoClip: OFF"
noclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipButton.Font = Enum.Font.SourceSans
noclipButton.TextSize = 16
noclipButton.Parent = mainFrame

-- Tombol untuk membuka menu lagi jika di-close
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 100, 0, 30)
openButton.Position = UDim2.new(0, 20, 0, 60)
openButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
openButton.Text = "Buka Menu"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.Font = Enum.Font.SourceSansBold
openButton.TextSize = 14
openButton.Visible = false -- Disembunyikan secara default
openButton.Parent = screenGui

-- Logika Tombol Tutup & Buka
closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openButton.Visible = true
end)

openButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openButton.Visible = false
end)

-- Logika Fly
flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if flyEnabled and humanoid and rootPart then
            humanoid.PlatformStand = true
            rootPart.Velocity = Vector3.new(0,0,0) -- Reset velocity agar tidak jatuh
        else
            if humanoid then humanoid.PlatformStand = false end
            if rootPart then rootPart.Velocity = Vector3.new(0,0,0) end
        end
    end
end)

-- Loop untuk Fly (Posisi CFrame agar tidak tembus tanah)
runService.RenderStepped:Connect(function()
    if flyEnabled then
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local camera = workspace.CurrentCamera
            if rootPart and camera then
                local moveDirection = Vector3.new(0,0,0)
                if userInput:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
                if userInput:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
                if userInput:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
                if userInput:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
                if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
                if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
                
                if moveDirection.Magnitude > 0 then
                    -- Menggunakan CFrame untuk pergerakan yang lebih stabil dari tembus tanah
                    rootPart.CFrame = rootPart.CFrame + (moveDirection.Unit * flySpeed * 0.02)
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

-- Loop untuk NoClip
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

print("Delta Script Loaded - Updated Version")
