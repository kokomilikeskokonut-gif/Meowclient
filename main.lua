-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration Settings
local Settings = {
    Aimbot = false,
    AimbotKey = Enum.KeyCode.MouseButton2, -- Default Right Click
    UIToggleKey = Enum.KeyCode.RightShift, -- Default Right Shift
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance",
    FOV = 150,
    TargetPart = "Head",
    Smoothness = 0.5,
    -- ESP Settings
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_Names = false,
    ESP_Health = false,
    ESP_Distance = false
}

-- // 3. Create the Window
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

-- Pages
local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- // Combat Tab Sections
local AimSection = MainTab:section({name = "Aimbot"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})

-- NEW: Aimbot Keybind (Recording)
AimSection:bind({
    name = "Aimbot Key",
    default = Settings.AimbotKey,
    callback = function(key)
        Settings.AimbotKey = key
        print("Aimbot key changed to: " .. tostring(key))
    end
})

AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

AimSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) Settings.Priority = v end
})

-- // Misc Tab (UI Settings)
local UISettings = MiscTab:section({name = "UI Settings"})

-- NEW: UI Toggle Keybind (Recording)
UISettings:bind({
    name = "Menu Toggle Key",
    default = Settings.UIToggleKey,
    callback = function(key)
        Settings.UIToggleKey = key
        print("Menu toggle changed to: " .. tostring(key))
    end
})

-- // 4. Aimbot Engine logic
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    local camera = workspace.CurrentCamera
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character, camera}
    local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, rayParams)
    return (ray and ray.Instance:IsDescendantOf(targetPart.Parent))
end

local function getBestTarget()
    local target, bestVal = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    local camPos = workspace.CurrentCamera.CFrame.Position

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local part = p.Character.Head
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude

            if onScreen and mouseDist < Settings.FOV and isVisible(part) then
                if Settings.Priority == "Distance" then
                    local dist3D = (part.Position - camPos).Magnitude
                    if dist3D < bestVal then bestVal = dist3D; target = part end
                elseif Settings.Priority == "Health" then
                    local health = p.Character.Humanoid.Health
                    if health < bestVal then bestVal = health; target = part end
                end
            end
        end
    end
    return target
end

-- // 5. Rendering & Inputs
local UserInputService = game:GetService("UserInputService")

game:GetService("RunService").RenderStepped:Connect(function()
    -- Check if Aimbot Key is being pressed (Handles Mouse or Keyboard)
    local isPressed = false
    if tostring(Settings.AimbotKey):find("MouseButton") then
        isPressed = UserInputService:IsMouseButtonPressed(Settings.AimbotKey)
    else
        isPressed = UserInputService:IsKeyDown(Settings.AimbotKey)
    end

    if Settings.Aimbot and isPressed then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end
end)

-- Universal Toggle Handler
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Settings.UIToggleKey then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then
                gui.Enabled = not gui.Enabled
            end
        end
    end
end)

-- (The rest of the ESP and button code remains the same as before...)
