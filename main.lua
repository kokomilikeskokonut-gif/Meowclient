-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meowclient/refs/heads/main/movement"))()
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
    FOV_Visible = false,
    MaxAimDistance = 1000,
    MaxESPDistance = 2000,
    TargetPart = "Head",
    Smoothness = 0.5,
    SpeedEnabled = false,
    WalkSpeed = 16,
    JumpEnabled = false,
    JumpHeight = 50,
    InfJump = false,
    Noclip = false,
    Bhop = false,
    Spinbot = false,
    SpinSpeed = 50,
    -- ESP Settings
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    ESP_Names = false,
    ESP_Health = false,
    ESP_Distance = false
}

-- // 3. Build the UI
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- COLUMN 1: Aimbot Main
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

-- COLUMN 2: FOV & Range (Fixes Overlap)
local FOVSection = MainTab:section({name = "FOV & Range Settings"})
FOVSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})
FOVSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
FOVSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
FOVSection:slider({name = "Max Aim Distance", min = 50, max = 5000, default = 1000, callback = function(v) Settings.MaxAimDistance = v end})

-- Triggerbot Section
local TriggerSection = MainTab:section({name = "Triggerbot"})
TriggerSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})
TriggerSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

-- Vision Section (ESP)
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:slider({name = "Max ESP Distance", min = 100, max = 10000, default = 2000, callback = function(v) Settings.MaxESPDistance = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})
ESPSection:toggle({name = "Health ESP", callback = function(v) Settings.ESP_Health = v end})
ESPSection:toggle({name = "Distance ESP", callback = function(v) Settings.ESP_Distance = v end})

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

-- // 5. ESP Engine (FIXED)
local function CreateESP(plr)
    local Box = Drawing.new("Square")
    local Name = Drawing.new("Text")
    local Tracer = Drawing.new("Line")

    Box.Color = Color3.fromRGB(255, 182, 193)
    Box.Thickness = 1
    Tracer.Color = Color3.fromRGB(255, 182, 193)
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Outline = true
    Name.Center = true

    local updater
    updater = game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.Running and Settings.ESP_Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local myHrp = game.Players.LocalPlayer.Character.HumanoidRootPart
            local dist = (hrp.Position - myHrp.Position).Magnitude
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

            if onScreen and dist <= Settings.MaxESPDistance then
                Box.Visible = Settings.ESP_Boxes
                Name.Visible = Settings.ESP_Names
                Tracer.Visible = Settings.ESP_Tracers

                if Settings.ESP_Boxes then
                    local size = 2500 / pos.Z
                    Box.Size = Vector2.new(size, size * 1.5)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - (size * 1.5) / 2)
                end
                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    Name.Text = plr.Name .. (Settings.ESP_Distance and " [" .. math.floor(dist) .. "]" or "")
                end
                if Settings.ESP_Tracers then
                    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                end
            else
                Box.Visible = false; Name.Visible = false; Tracer.Visible = false
            end
        else
            Box.Visible = false; Name.Visible = false; Tracer.Visible = false
            if not plr.Parent or not Settings.Running then
                Box:Remove(); Name:Remove(); Tracer:Remove(); updater:Disconnect()
            end
        end
    end)
end

-- Initialize ESP for existing and new players
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then CreateESP(p) end
end
game.Players.PlayerAdded:Connect(CreateESP)

-- // 6. Main Render Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end

    if Settings.Triggerbot then
        local mouse = game.Players.LocalPlayer:GetMouse()
        if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
            local p = game.Players:GetPlayerFromCharacter(mouse.Target.Parent)
            if p and p ~= game.Players.LocalPlayer then
                if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then return end
                task.wait(Settings.TriggerDelay)
                mouse1click()
            end
        end
    end
end)
-- Inside the RenderStepped loop:
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
        local hum = char.Humanoid
        local hrp = char.HumanoidRootPart
        
        -- Speed & Jump Logic
        hum.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        hum.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
        
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
        
        -- Noclip
        if Settings.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
-- Add these right after MiscTab is defined
local MoveSection = MiscTab:section({name = "Movement", side = "left"})
MoveSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
MoveSection:slider({name = "WalkSpeed", min = 16, max = 300, default = 16, callback = function(v) Settings.WalkSpeed = v end})
MoveSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
MoveSection:slider({name = "Jump Height", min = 50, max = 500, default = 50, callback = function(v) Settings.JumpHeight = v end})

local AdvanceMove = MiscTab:section({name = "Advanced Physics", side = "right"})
AdvanceMove:toggle({name = "Infinite Jump", callback = function(v) Settings.InfJump = v end})
AdvanceMove:toggle({name = "Auto-Bhop", callback = function(v) Settings.Bhop = v end})
AdvanceMove:toggle({name = "Noclip", callback = function(v) Settings.Noclip = v end})
AdvanceMove:toggle({name = "Spinbot", callback = function(v) Settings.Spinbot = v end})
-- // 7. Global Inputs
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftControl then
        Settings.Running = false
        Settings.ESP_Enabled = false
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then gui:Destroy() end
        end
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then gui.Enabled = not gui.Enabled end
        end
    end
end)
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Settings.InfJump then
        local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

