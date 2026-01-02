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
    MaxAimDistance = 1000, Smoothness = 0.5,
    HitboxSize = 2, -- NEW
    -- Vision
    ESP_Enabled = false, ESP_Boxes = false, ESP_Tracers = false, ESP_TracerThickness = 1,
    MaxESPDistance = 2000,
    -- Movement (NEW)
    Fly = false, FlySpeed = 50, WalkSpeed = 16, JumpHeight = 50, Noclip = false
}

-- // 3. Build UI
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"}) -- NEW WINDOW

-- Combat: Hitbox Section
local HitboxSection = MainTab:section({name = "Hitbox Expander", side = "right"})
HitboxSection:slider({name = "Head Size", min = 2, max = 20, default = 2, callback = function(v) Settings.HitboxSize = v end})

-- Movement Window
local SpeedSection = MoveTab:section({name = "Character Physics"})
SpeedSection:slider({name = "WalkSpeed", min = 16, max = 250, default = 16, callback = function(v) Settings.WalkSpeed = v end})
SpeedSection:slider({name = "JumpHeight", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

local FlySection = MoveTab:section({name = "Flight & Noclip"})
FlySection:toggle({name = "Enable Fly", callback = function(v) Settings.Fly = v end})
FlySection:slider({name = "Fly Speed", min = 10, max = 300, default = 50, callback = function(v) Settings.FlySpeed = v end})
FlySection:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})

-- // 4. Movement Engines
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer

RunService.RenderStepped:Connect(function()
    if not Settings.Running then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        -- WalkSpeed & Jump
        hum.WalkSpeed = Settings.WalkSpeed
        hum.JumpHeight = Settings.JumpHeight
        
        -- Noclip Logic
        if Settings.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        -- Fly Logic
        if Settings.Fly then
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end
            
            hrp.Velocity = moveDir * Settings.FlySpeed
            hrp.Anchored = (moveDir == Vector3.new(0,0,0)) -- Hover when still
        else
            hrp.Anchored = false
        end
    end
end)

-- // 5. Hitbox Expander Engine
task.spawn(function()
    while task.wait(0.5) do
        if not Settings.Running then break end
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if Settings.HitboxSize > 2 then
                    head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    head.Transparency = 0.6
                    head.CanCollide = false
                else
                    head.Size = Vector3.new(1.2, 1.2, 1.2)
                    head.Transparency = 0
                end
            end
        end
    end
end)
