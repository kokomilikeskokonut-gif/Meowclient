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
    Fly = false, FlySpeed = 50, Noclip = false, Spinbot = false
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

-- Movement Sections
local PhysSection = MoveTab:section({name = "Physics Toggles", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed", min = 16, max = 250, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
PhysSection:slider({name = "JumpHeight", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

local SpecialSection = MoveTab:section({name = "Special Movement", side = "right"})
SpecialSection:toggle({name = "Spinbot", callback = function(v) Settings.Spinbot = v end})
SpecialSection:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
SpecialSection:toggle({name = "Enable Fly", callback = function(v) Settings.Fly = v end})

-- // 4. ENGINES

-- Fixed Wallcheck (Raycasting)
local function isVisible(part)
    if not Settings.WallCheck then return true end
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, cam} -- This ignores YOU
    
    local direction = (part.Position - cam.CFrame.Position)
    local result = workspace:Raycast(cam.CFrame.Position, direction, params)
    
    -- If it hits nothing or hits the target's character, they are visible
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

-- Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function getTarget()
    local target, dist = nil, Settings.FOV
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health <= 0 then continue end
            
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
    
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    -- Update FOV
    FOVCircle.Visible = Settings.FOV_Visible; FOVCircle.Radius = Settings.FOV; FOVCircle.Thickness = Settings.FOV_Thickness
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    
    -- Combat
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget()
        if t then
            local goal = CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position)
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(goal, Settings.Smoothness)
        end
    end

    -- Physics & Specials
    if hum and hrp then
        hum.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        hum.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
        
        if Settings.Spinbot then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
        end
        
        if Settings.Noclip then
            for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
    end
end)

-- (ESP Additions from previous working version here)
