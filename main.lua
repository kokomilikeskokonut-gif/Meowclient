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
    Triggerbot = false, -- RESTORED
    -- Vision
    ESP_Enabled = false, ESP_Boxes = false, ESP_Names = false,
    ESP_Health = false, ESP_Tracers = false, ESP_TracerThickness = 1,
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

local TrigSection = MainTab:section({name = "Triggerbot", side = "left"})
TrigSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})

local TargetSection = MainTab:section({name = "Target & FOV", side = "right"})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "FOV Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.FOV_Thickness = v end})
TargetSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})

-- Vision Sections
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})
ESPSection:toggle({name = "Health ESP", callback = function(v) Settings.ESP_Health = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:slider({name = "Tracer Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.ESP_TracerThickness = v end})

-- Movement Sections
local PhysSection = MoveTab:section({name = "Physics Toggles", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed", min = 16, max = 250, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
PhysSection:slider({name = "JumpHeight", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

-- // 4. ENGINES

-- Triggerbot Logic
local function checkTrigger()
    if not Settings.Triggerbot then return end
    local mouse = game.Players.LocalPlayer:GetMouse()
    local target = mouse.Target
    if target and target.Parent:FindFirstChild("Humanoid") then
        local targetPlayer = game.Players:GetPlayerFromCharacter(target.Parent)
        if targetPlayer then
            if Settings.TeamCheck and targetPlayer.Team == game.Players.LocalPlayer.Team then return end
            mouse1click()
        end
    end
end

-- Aimbot Visibility Check
local function isVisible(part)
    if not Settings.WallCheck then return true end
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, cam}
    local ray = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position), params)
    return not ray or ray.Instance:IsDescendantOf(part.Parent)
end

-- Main Render Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    -- Update FOV
    FOVCircle.Visible = Settings.FOV_Visible; FOVCircle.Radius = Settings.FOV; FOVCircle.Thickness = Settings.FOV_Thickness
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    
    -- Triggerbot Check
    checkTrigger()

    -- Aimbot Logic
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget() -- Uses the getTarget function from the previous stable version
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end

    -- Movement Physics
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        char.Humanoid.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
    end
end)

-- (ESP AddESP function and initialization from previous version remains here)
