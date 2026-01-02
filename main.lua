-- // 1. Load Library & Theme Overrider
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- Apply the Deep Charcoal & Pink Theme from your image
local PinkTheme = {
    MainColor = Color3.fromRGB(25, 25, 25),      -- Deep Charcoal Background
    AccentColor = Color3.fromRGB(255, 182, 193), -- Blossom Pink Accents
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}

-- // 2. Configuration & State
local Settings = {
    Running = true,
    Aimbot = false,
    Triggerbot = false,
    TriggerDelay = 0,
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance",
    FOV = 150,
    FOV_Visible = true,
    MaxAimDistance = 1000,
    MaxESPDistance = 2000,
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

-- // 3. Build UI with Two-Column Layout
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig",
    theme = PinkTheme -- Applying the custom theme
})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- Left Column: Aimbot Main
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
AimSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})

-- Right Column: Target & Smoothness
local TargetSection = MainTab:section({name = "Target Settings", side = "right"})
TargetSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) Settings.Priority = v end
})
TargetSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "Max Range", min = 50, max = 5000, default = 1000, callback = function(v) Settings.MaxAimDistance = v end})

-- Triggerbot (Bottom Left)
local TriggerSection = MainTab:section({name = "Triggerbot", side = "left"})
TriggerSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})
TriggerSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

-- Vision Tab
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:slider({name = "Max ESP Distance", min = 100, max = 10000, default = 2000, callback = function(v) Settings.MaxESPDistance = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})
ESPSection:toggle({name = "Health ESP", callback = function(v) Settings.ESP_Health = v end})

-- // 4. Aimbot & ESP Engines
local function getBestTarget()
    local target, bestVal = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    local myChar = game.Players.LocalPlayer.Character
    if not (myChar and myChar:FindFirstChild("HumanoidRootPart")) then return nil end

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local part = p.Character.Head
            local dist3D = (part.Position - myChar.HumanoidRootPart.Position).Magnitude
            if dist3D > Settings.MaxAimDistance then continue end

            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude

            if onScreen and mouseDist < Settings.FOV then
                if Settings.Priority == "Distance" then
                    if dist3D < bestVal then bestVal = dist3D; target = part end
                elseif Settings.Priority == "Health" then
                    if p.Character.Humanoid.Health < bestVal then bestVal = p.Character.Humanoid.Health; target = part end
                end
            end
        end
    end
    return target
end

-- // 5. Rendering Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor
FOVCircle.Thickness = 1

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end
end)

-- // 6. Cleanup & Toggle
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftControl then
        Settings.Running = false
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then gui:Destroy() end
        end
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then gui.Enabled = not gui.Enabled end
        end
    end
end)
