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

-- Aimbot Section
local AimSection = MainTab:section({name = "Aimbot Settings"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
AimSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})

AimSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) Settings.Priority = v end
})

AimSection:slider({name = "Max Aim Distance", min = 50, max = 5000, default = 1000, callback = function(v) Settings.MaxAimDistance = v end})
AimSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- Triggerbot Section
local TriggerSection = MainTab:section({name = "Triggerbot"})
TriggerSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})
TriggerSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

-- Vision Section
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
    local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * Settings.MaxAimDistance, rayParams)
    return (ray and ray.Instance:IsDescendantOf(targetPart.Parent))
end

local function getBestTarget()
    local target, bestVal = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    local myPos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character.HumanoidRootPart.Position
    if not myPos then return nil end

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local part = p.Character.Head
            local dist3D = (part.Position - myPos).Magnitude
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

-- // 5. Main Loops
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    -- Aimbot
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end

    -- Triggerbot
    if Settings.Triggerbot then
        local mouse = game.Players.LocalPlayer:GetMouse()
        local target = mouse.Target
        if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
            local plr = game.Players:GetPlayerFromCharacter(target.Parent)
            if plr and plr ~= game.Players.LocalPlayer then
                if Settings.TeamCheck and plr.Team == game.Players.LocalPlayer.Team then return end
                task.wait(Settings.TriggerDelay)
                mouse1click()
            end
        end
    end
end)

-- // 6. ESP Engine (Distance Capped)
local function CreateESP(plr)
    local Box = Drawing.new("Square")
    local Name = Drawing.new("Text")
    Box.Color = Color3.fromRGB(255, 182, 193)
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Outline = true
    Name.Center = true

    game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.ESP_Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local myHrp = game.Players.LocalPlayer.Character.HumanoidRootPart
            local dist = (hrp.Position - myHrp.Position).Magnitude
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

            if onScreen and dist <= Settings.MaxESPDistance then
                Box.Visible = Settings.ESP_Boxes
                Name.Visible = Settings.ESP_Names
                if Settings.ESP_Boxes then
                    local size = 1500 / pos.Z
                    Box.Size = Vector2.new(size, size * 1.5)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - (size * 1.5) / 2)
                end
                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    Name.Text = plr.Name .. (Settings.ESP_Distance and " [" .. math.floor(dist) .. "m]" or "")
                end
            else Box.Visible = false; Name.Visible = false end
        else Box.Visible = false; Name.Visible = false end
    end)
end
-- (Add PlayerAdded connections and Toggle logic from previous version)
