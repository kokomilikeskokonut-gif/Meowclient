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
    Triggerbot = false, TriggerDelay = 0, -- UPDATED
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
TrigSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end}) -- NEW SLIDER

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

-- Triggerbot with Delay
local TriggerLocked = false
local function checkTrigger()
    if not Settings.Triggerbot or TriggerLocked then return end
    local mouse = game.Players.LocalPlayer:GetMouse()
    local target = mouse.Target
    if target and target.Parent:FindFirstChild("Humanoid") then
        local targetPlayer = game.Players:GetPlayerFromCharacter(target.Parent)
        if targetPlayer and target.Parent.Humanoid.Health > 0 then
            if Settings.TeamCheck and targetPlayer.Team == game.Players.LocalPlayer.Team then return end
            
            TriggerLocked = true
            task.wait(Settings.TriggerDelay) -- Applies the slider delay
            mouse1click()
            task.wait(0.1) -- Small cooldown to prevent spam-glitching
            TriggerLocked = false
        end
    end
end

-- Render Loop for Combat & Physics
game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then return end
    
    checkTrigger()
    
    -- (Previous Aimbot/FOV/Physics logic continues here...)
end)
