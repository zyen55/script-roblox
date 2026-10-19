-- Skrip Delta Executor (Fly Mobile & Hide/Show Tab)
local player = game:GetService("Players").LocalPlayer
local userInput = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local flyEnabled = false
local noclipEnabled = false
local flySpeed = 2 -- Kecepatan fly (sesuaikan jika terlalu lambat/cepat)

-- Variabel untuk kontrol Mobile
local mobileMove = {Up=false, Down=false, Left=false, Right=false, Ascend=false, Descend=false}

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

-- Header Menu
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Delta Script Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = mainFrame

-- Tombol Minimize (-)
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -60, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 20
minBtn.Parent = mainFrame

-- Tombol Close (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame

-- Tombol Fly & NoClip
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0.9, 0, 0, 30)
flyButton.Position = UDim2.new(0.05, 0, 0, 40)
flyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyButton.Text = "Fly: OFF"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.Font = Enum.Font.SourceSansBold
flyButton.TextSize = 16
flyButton.Parent = mainFrame

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(0.9, 0, 0, 30)
noclipButton.Position = UDim2.new(0.05, 0, 0, 80)
noclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipButton.Text = "NoClip: OFF"
noclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipButton.Font = Enum.Font.SourceSansBold
noclipButton.TextSize = 16
noclipButton.Parent = mainFrame

-- Panel Kontrol Mobile (Hanya muncul saat Fly ON)
local mobilePanel = Instance.new("Frame")
mobilePanel.Size = UDim2.new(0.9, 0, 0, 120)
mobilePanel.Position = UDim2.new(0.05, 0, 0, 130)
mobilePanel.BackgroundTransparency = 1
mobilePanel.Visible = false
mobilePanel.Parent = mainFrame

-- Fungsi pembuat tombol Mobile
local function createMobileBtn(text, posX, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = UDim2.new(0, posX, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Parent = mobilePanel
    return btn
end

-- Layout Tombol Mobile (seperti D-Pad)
local btnW = createMobileBtn("W", 50, 0)
local btnA = createMobileBtn("A", 10, 40)
local btnS = createMobileBtn("S", 50, 40)
local btnD = createMobileBtn("D", 90, 40)
local btnSpace = createMobileBtn("^", 150, 40) -- Naik
local btnCtrl = createMobileBtn("v", 150, 80) -- Turun

-- Fungsi Tahan Tombol (Mobile)
local function bindMobileBtn(btn, key)
    btn.MouseButton1Down:Connect(function() mobileMove[key] = true end)
    btn.MouseButton1Up:Connect(function() mobileMove[key] = false end)
    btn.MouseLeave:Connect(function() mobileMove[key] = false end) -- Jika jari bergeser
end

bindMobileBtn(btnW, "Up")
bindMobileBtn(btnS, "Down")
bindMobileBtn(btnA, "Left")
bindMobileBtn(btnD, "Right")
bindMobileBtn(btnSpace, "Ascend")
bindMobileBtn(btnCtrl, "Descend")


-- ==========================================
-- TOMBOL MELAYANG (Saat menu disembunyikan)
-- ==========================================
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
floatingBtn.Draggable = true -- Bisa digeser-geser
floatingBtn.Parent = screenGui

-- Logika Sembunyikan / Munculkan
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


-- ==========================================
-- LOGIKA FLY & NOCLIP
-- ==========================================
flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
    mobilePanel.Visible = flyEnabled -- Tampilkan kontrol mobile jika fly ON
    
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if flyEnabled and humanoid and rootPart then
            humanoid.PlatformStand = true
            rootPart.Velocity = Vector3.new(0,0,0)
        else
            if humanoid then humanoid.PlatformStand = false end
            if rootPart then rootPart.Velocity = Vector3.new(0,0,0) end
        end
    end
end)

noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipButton.Text = "NoClip: " .. (noclipEnabled and "ON" or "OFF")
end)

-- Loop Pergerakan Fly (Mendukung Keyboard & Mobile)
runService.RenderStepped:Connect(function()
    if flyEnabled then
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local camera = workspace.CurrentCamera
            if rootPart and camera then
                local moveDir = Vector3.new(0,0,0)
                
                -- Cek Input Keyboard (PC)
                if userInput:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if userInput:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if userInput:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if userInput:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                -- Cek Input Tombol Mobile
                if mobileMove.Up then moveDir = moveDir + camera.CFrame.LookVector end
                if mobileMove.Down then moveDir = moveDir - camera.CFrame.LookVector end
                if mobileMove.Left then moveDir = moveDir - camera.CFrame.RightVector end
                if mobileMove.Right then moveDir = moveDir + camera.CFrame.RightVector end
                if mobileMove.Ascend then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if mobileMove.Descend then moveDir = moveDir - Vector3.new(0, 1, 0) end

                -- Aplikasikan pergerakan
                if moveDir.Magnitude > 0 then
                    rootPart.CFrame = rootPart.CFrame + (moveDir.Unit * flySpeed)
                end
            end
        end
    end
end)

-- Loop NoClip
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

print("Delta Script Loaded - Mobile & Hide Version")
