-- // 1. Load Library & Theme
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

local PinkTheme = {
    MainColor = Color3.fromRGB(25, 25, 25),      
    AccentColor = Color3.fromRGB(255, 182, 193), 
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}

-- // 2. Configuration & State
local Settings = {
    Running = true,
    Aimbot = false,
    AimStyle = "Smooth", -- NEW: "Smooth" or "Rage"
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance",
    FOV = 150,
    FOV_Visible = true,
    FOV_Thickness = 1,
    MaxAimDistance = 1000,
    MaxESPDistance = 2000,
    TargetPart = "Head",
    Smoothness = 0.5,
    -- ESP Settings
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_TracerThickness = 1,
    ESP_Names = false,
    ESP_Health = false
}

-- // 3. Build UI
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig",
    theme = PinkTheme
})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- Left Column: Aimbot Main
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})

-- NEW: Aimbot Style Dropdown
AimSection:dropdown({
    name = "Aimbot Style",
    content = {"Smooth", "Rage"},
    default = "Smooth",
    callback = function(v) Settings.AimStyle = v end
})

AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
AimSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})

-- Right Column: Target Settings
local TargetSection = MainTab:section({name = "Target Settings", side = "right"})
TargetSection:dropdown({name = "Target Priority", content = {"Distance", "Health"}, default = "Distance", callback = function(v) Settings.Priority = v end})
TargetSection:slider({name = "Smoothness Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "FOV Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.FOV_Thickness = v end})
TargetSection:slider({name = "Max Range", min = 50, max = 5000, default = 1000, callback = function(v) Settings.MaxAimDistance = v end})

-- Vision Tab
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:slider({name = "Max ESP Distance", min = 100, max = 10000, default = 2000, callback = function(v) Settings.MaxESPDistance = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:slider({name = "Tracer Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.ESP_TracerThickness = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})

-- // 4. Fixed Wallcheck & Target Logic
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    
    local camera = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    if not char then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, camera}
    
    -- Cast ray from Camera to the Target Part
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local ray = workspace:Raycast(origin, direction, rayParams)
    
    -- If the ray hits nothing or hits the target character, they are visible
    if not ray or ray.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

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

            if onScreen and mouseDist < Settings.FOV and isVisible(part) then
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

-- // 5. Rendering & Aimbot Styles Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Thickness = Settings.FOV_Thickness
    
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            local cam = workspace.CurrentCamera
            if Settings.AimStyle == "Rage" then
                -- Rage: Instant Snap
                cam.CFrame = CFrame.new(cam.CFrame.Position, t.Position)
            else
                -- Smooth: Uses Slider
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), Settings.Smoothness)
            end
        end
    end
end)

-- (Keep the same Cleanup and Toggle inputs as previous version)
