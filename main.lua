-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration & State
local Settings = {
    Running = true,
    -- Combat
    Aimbot = false,
    Triggerbot = false,
    TriggerDelay = 0,
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance",
    FOV = 150,
    FOV_Visible = true,
    MaxAimDistance = 1000,
    TargetPart = "Head",
    Smoothness = 0.5,
    -- Visuals
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_Names = false,
    MaxESPDistance = 2000,
    -- Movement (Main Hub)
    SpeedEnabled = false,
    WalkSpeed = 16,
    InfJump = false,
    Bhop = false,
    Noclip = false,
    Spinbot = false,
    SpinSpeed = 50,
    -- Extras (Second Window)
    FlyEnabled = false,
    FlySpeed = 50
}

local PinkTheme = {
    MainColor = Color3.fromRGB(25, 25, 25),      
    AccentColor = Color3.fromRGB(255, 182, 193), 
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}

-- // 3. WINDOW 1: MAIN HUB
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})
local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"})

-- Combat UI
local AimSection = MainTab:section({name = "Aimbot"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- Movement UI (The requested features)
local PhysSection = MoveTab:section({name = "Basic Physics", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed", min = 16, max = 300, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Auto-Bhop", callback = function(v) Settings.Bhop = v end})
PhysSection:toggle({name = "Infinite Jump", callback = function(v) Settings.InfJump = v end})

local AdvancedMove = MoveTab:section({name = "Advanced", side = "right"})
AdvancedMove:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
AdvancedMove:toggle({name = "Spinbot", callback = function(v) Settings.Spinbot = v end})
AdvancedMove:slider({name = "Spin Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.SpinSpeed = v end})

-- // 4. WINDOW 2: EXTRAS (Fly & Teleport)
local ExtraWindow = Library:new({name = "Blossom Extras", theme = PinkTheme})
local ExtraTab = ExtraWindow:page({name = "Utility"})

local FlySection = ExtraTab:section({name = "Flight"})
FlySection:toggle({name = "Enable Fly", callback = function(v) Settings.FlyEnabled = v end})
FlySection:slider({name = "Fly Speed", min = 10, max = 500, default = 50, callback = function(v) Settings.FlySpeed = v end})

local TPSection = ExtraTab:section({name = "Player Teleport"})
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then
        TPSection:button({name = "TP to: "..p.Name, callback = function()
            local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and targetHrp then hrp.CFrame = targetHrp.CFrame end
        end})
    end
end

-- // 5. THE UNIFIED ENGINE
game:GetService("RunService").Heartbeat:Connect(function()
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if char and hum and hrp then
        -- Force Movement Stats
        hum.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        
        -- Auto Bhop
        if Settings.Bhop and game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        -- Spinbot
        if Settings.Spinbot then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
        end

        -- Noclip
        if Settings.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        -- Fly Logic
        if Settings.FlyEnabled then
            local cam = workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            local uis = game:GetService("UserInputService")
            if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            hrp.Velocity = dir * Settings.FlySpeed
            hum.PlatformStand = true
        else
            hum.PlatformStand = false
        end
    end
end)

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Settings.InfJump then
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
