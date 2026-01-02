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
    Aimbot = false, AimStyle = "Smooth", TeamCheck = true, WallCheck = true,
    Priority = "Distance", FOV = 150, FOV_Visible = true, FOV_Thickness = 1,
    MaxAimDistance = 1000, Smoothness = 0.5, HitboxSize = 2,
    -- Movement
    SpeedEnabled = false, WalkSpeed = 16, 
    JumpEnabled = false, JumpHeight = 50, 
    Noclip = false, Spinbot = false
}

-- // 3. Build UI
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})
local MainTab = Window:page({name = "Combat"})
local MoveTab = Window:page({name = "Movement"})

-- Combat Sections
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:dropdown({name = "Aimbot Style", content = {"Smooth", "Rage"}, default = "Smooth", callback = function(v) Settings.AimStyle = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

local TargetSection = MainTab:section({name = "Target & FOV", side = "right"})
TargetSection:dropdown({name = "Priority", content = {"Distance", "Health"}, default = "Distance", callback = function(v) Settings.Priority = v end})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
TargetSection:slider({name = "Hitbox Expander", min = 2, max = 20, default = 2, callback = function(v) Settings.HitboxSize = v end})

-- // 4. CORE AIMBOT ENGINE (FIXED)
local function isVisible(part)
    if not Settings.WallCheck then return true end
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, cam}
    
    local result = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position).Unit * 1000, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getBestTarget()
    local target, bestVal = nil, math.huge
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local cam = workspace.CurrentCamera
    local lp = game.Players.LocalPlayer

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == lp.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local head = p.Character.Head
            local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
            local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

            if onScreen and mouseDist <= Settings.FOV and isVisible(head) then
                if Settings.Priority == "Distance" then
                    local dist3D = (head.Position - cam.CFrame.Position).Magnitude
                    if dist3D < bestVal then
                        bestVal = dist3D
                        target = head
                    end
                elseif Settings.Priority == "Health" then
                    local hp = p.Character.Humanoid.Health
                    if hp < bestVal then
                        bestVal = hp
                        target = head
                    end
                end
            end
        end
    end
    return target
end

-- // 5. MAIN LOOP
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor
FOVCircle.Thickness = 1

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    -- Update FOV
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()

    -- Movement (Speed/Jump/Spin)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        hum.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        hum.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
        if Settings.Spinbot then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0) end
    end

    -- Aimbot Execution
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            local cam = workspace.CurrentCamera
            local goal = CFrame.new(cam.CFrame.Position, t.Position)
            
            if Settings.AimStyle == "Rage" then
                cam.CFrame = goal
            else
                cam.CFrame = cam.CFrame:Lerp(goal, Settings.Smoothness)
            end
        end
    end
end)

-- Hitbox loop
task.spawn(function()
    while task.wait(0.5) do
        if not Settings.Running then break end
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                p.Character.Head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                p.Character.Head.Transparency = (Settings.HitboxSize > 2 and 0.5 or 0)
                p.Character.Head.CanCollide = false
            end
        end
    end
end)

-- Anti-AFK
game.Players.LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
