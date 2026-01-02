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
    Aimbot = false, AimStyle = "Smooth", TeamCheck = true, WallCheck = true,
    Priority = "Distance", FOV = 150, FOV_Visible = true, FOV_Thickness = 1,
    MaxAimDistance = 1000, Smoothness = 0.5, HitboxSize = 2,
    Triggerbot = false, TriggerDelay = 0,
    -- Vision
    ESP_Enabled = false, ESP_Boxes = false, ESP_Tracers = false, 
    ESP_TracerThickness = 1, ESP_Names = false, ESP_Health = false, MaxESPDistance = 2000,
    -- Movement
    Fly = false, FlySpeed = 50, 
    SpeedEnabled = false, WalkSpeed = 16, 
    JumpEnabled = false, JumpHeight = 50, 
    Noclip = false, Spinbot = false
}

-- // 3. Build UI
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"})

-- Combat Sections
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:dropdown({name = "Aimbot Style", content = {"Smooth", "Rage"}, default = "Smooth", callback = function(v) Settings.AimStyle = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

local TargetSection = MainTab:section({name = "Target & FOV", side = "right"})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "FOV Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.FOV_Thickness = v end})
TargetSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
TargetSection:slider({name = "Hitbox Expander", min = 2, max = 20, default = 2, callback = function(v) Settings.HitboxSize = v end})

-- Vision Tab
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:slider({name = "Tracer Thickness", min = 1, max = 10, default = 1, callback = function(v) Settings.ESP_TracerThickness = v end})

-- Movement Tab
local PhysSection = MoveTab:section({name = "Physical Toggles", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed Value", min = 16, max = 250, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
PhysSection:slider({name = "Jump Value", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

local SpecialSection = MoveTab:section({name = "Specials", side = "right"})
SpecialSection:toggle({name = "Spinbot", callback = function(v) Settings.Spinbot = v end})
SpecialSection:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
SpecialSection:toggle({name = "Flight", callback = function(v) Settings.Fly = v end})

-- // 4. ENGINES

-- Anti-AFK Logic
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Main Render Loop (Aimbot, Movement, Spinbot)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    -- FOV Update
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Thickness = Settings.FOV_Thickness
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()

    -- Movement Checks
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
    
    -- Aimbot Logic
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget() -- Uses target function from previous code
        if t then
            local goal = CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position)
            workspace.CurrentCamera.CFrame = (Settings.AimStyle == "Rage" and goal or workspace.CurrentCamera.CFrame:Lerp(goal, Settings.Smoothness))
        end
    end
end)
