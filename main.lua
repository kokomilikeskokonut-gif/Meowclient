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
    -- Combat
    Aimbot = false, TeamCheck = true, WallCheck = true,
    FOV = 150, FOV_Visible = true, FOV_Thickness = 1,
    Smoothness = 0.5,
    Triggerbot = false, TriggerDelay = 0,
    -- Vision
    ESP_Enabled = false, ESP_Tracers = false, ESP_TracerThickness = 1,
    -- Movement
    SpeedEnabled = false, WalkSpeed = 16, 
    JumpEnabled = false, JumpHeight = 50, 
    Fly = false, FlySpeed = 50, Noclip = false
}

-- // 3. Build UI
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"})

-- Combat Sections
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

local TargetSection = MainTab:section({name = "Target & FOV", side = "right"})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "FOV Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.FOV_Thickness = v end})
TargetSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})

local TrigSection = MainTab:section({name = "Triggerbot", side = "left"})
TrigSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})
TrigSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

-- Vision Sections
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:slider({name = "Tracer Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.ESP_TracerThickness = v end})

-- Movement Sections
local PhysSection = MoveTab:section({name = "Physics Toggles", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed", min = 16, max = 250, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
PhysSection:slider({name = "JumpHeight", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

local FlySection = MoveTab:section({name = "Special Movement", side = "right"})
FlySection:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
FlySection:toggle({name = "Enable Fly", callback = function(v) Settings.Fly = v end})
FlySection:slider({name = "Fly Speed", min = 10, max = 300, default = 50, callback = function(v) Settings.FlySpeed = v end})

-- // 4. ENGINES (Aimbot, ESP, Movement)
local function isVisible(part)
    if not Settings.WallCheck then return true end
    local cam = workspace.CurrentCamera
    local ray = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position).Unit * 1000, RaycastParams.new())
    return not ray or ray.Instance:IsDescendantOf(part.Parent)
end

local function getTarget()
    local target, dist = nil, Settings.FOV
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.Head.Position)
            local mag = (Vector2.new(pos.X, pos.Y) - game:GetService("UserInputService"):GetMouseLocation()).Magnitude
            if onScreen and mag < dist and isVisible(p.Character.Head) then
                dist = mag; target = p.Character.Head
            end
        end
    end
    return target
end

-- Main Render Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    -- Update FOV
    FOVCircle.Visible = Settings.FOV_Visible; FOVCircle.Radius = Settings.FOV; FOVCircle.Thickness = Settings.FOV_Thickness
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    
    -- Combat (Smooth Only)
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget()
        if t then
            local goal = CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position)
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(goal, Settings.Smoothness)
        end
    end

    -- Movement (Speed & Jump Toggles)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        hum.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        hum.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
        
        if Settings.Noclip then
            for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
    end
end)

-- ESP Initialization
local function AddESP(p)
    local t = Drawing.new("Line"); t.Color = PinkTheme.AccentColor
    game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.ESP_Enabled and Settings.ESP_Tracers and p.Character and p.Character:FindFirstChild("Head") then
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.Head.Position)
            t.Visible = onScreen; t.Thickness = Settings.ESP_TracerThickness
            t.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y)
            t.To = Vector2.new(pos.X, pos.Y)
        else t.Visible = false end
    end)
end
for _, p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then AddESP(p) end end
game.Players.PlayerAdded:Connect(AddESP)
