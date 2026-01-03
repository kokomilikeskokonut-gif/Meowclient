-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()
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
    ESP_Distance = false,
    -- Movement Settings
    SpeedEnabled = false,
    WalkSpeed = 16,
    InfJump = false,
    Noclip = false,
    Bhop = false,
    Spinbot = false,
    SpinSpeed = 50
}

-- // 3. Build the UI
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- Aimbot Sections (Combat Tab)
local AimSection = MainTab:section({name = "Aimbot Main"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
AimSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) Settings.Priority = v end
})

local FOVSection = MainTab:section({name = "FOV & Range Settings"})
FOVSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})
FOVSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
FOVSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})

-- Movement Sections (Misc Tab)
local MoveSection = MiscTab:section({name = "Movement Improvements", side = "left"})
MoveSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
MoveSection:slider({name = "Speed Value", min = 16, max = 300, default = 16, callback = function(v) Settings.WalkSpeed = v end})
MoveSection:toggle({name = "Infinite Jump", callback = function(v) Settings.InfJump = v end})
MoveSection:toggle({name = "Auto-Bhop", callback = function(v) Settings.Bhop = v end})

local PhysicsSection = MiscTab:section({name = "Physics Fun", side = "right"})
PhysicsSection:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
PhysicsSection:toggle({name = "Spinbot", callback = function(v) Settings.Spinbot = v end})
PhysicsSection:slider({name = "Spin Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.SpinSpeed = v end})

-- // 4. Helper Functions
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
    local char = game.Players.LocalPlayer.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then return nil end

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local part = p.Character.Head
            local dist3D = (part.Position - char.HumanoidRootPart.Position).Magnitude
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

-- // 5. Main Loop (Handles Aimbot + Movement + Noclip)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1

game:GetService("RunService").Heartbeat:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    -- FOV Update
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    -- Aimbot Logic
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end

    -- Movement Engine (Speed / Bhop / Noclip / Spin)
    if char and hrp and hum then
        -- Speed Fix
        if Settings.SpeedEnabled then
            hum.WalkSpeed = Settings.WalkSpeed
        else
            hum.WalkSpeed = 16
        end

        -- Bhop
        if Settings.Bhop and game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            if hum.FloorMaterial ~= Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end

        -- Spinbot
        if Settings.Spinbot then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
        end
        
        -- Noclip Fix
        if Settings.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- // 6. Infinite Jump Input
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Settings.InfJump then
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

print("Blossom Hub: Movement & Combat Unified.")



