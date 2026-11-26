
-- DAUSHUB FEAST SCANNER
-- Object detection diagnostic

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local function getRoot()
    local character = Player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local keywords = {
    "feast",
    "food",
    "bubble",
    "fruit",
    "coin",
    "apple",
    "corn",
    "pumpkin",
    "berry",
    "grape",
    "banana",
    "orange",
    "watermelon",
    "melon"
}

local function matches(name)
    name = name:lower()

    for _, keyword in ipairs(keywords) do
        if name:find(keyword, 1, true) then
            return true
        end
    end

    return false
end

local function scan()
    local root = getRoot()

    print("================================")
    print("       DAUSHUB FEAST SCAN")
    print("================================")

    if not root then
        warn("Character / HumanoidRootPart not found!")
        return
    end

    local found = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if matches(obj.Name) then

                local part

                if obj:IsA("BasePart") then
                    part = obj
                else
                    part = obj.PrimaryPart
                        or obj:FindFirstChildWhichIsA(
                            "BasePart", true
                        )
                end

                local distance = "Unknown"

                if part then
                    distance = math.floor(
                        (root.Position - part.Position).Magnitude
                    )
                end

                found += 1

                print(
                    "FOUND:", obj.Name,
                    "| TYPE:", obj.ClassName,
                    "| DISTANCE:", distance,
                    "| PATH:", obj:GetFullName()
                )
            end
        end
    end

    print("--------------------------------")
    print("TOTAL OBJECTS FOUND:", found)
    print("SCAN COMPLETE")
    print("================================")
end

scan()
