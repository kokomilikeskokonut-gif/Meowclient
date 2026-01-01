-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration Settings
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance",
    FOV = 150,
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

-- // 3. Create the Window
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

-- Pages
local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- // Combat Tab Sections
local AimSection = MainTab:section({name = "Aimbot"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

AimSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) Settings.Priority = v end
})

AimSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- // Vision Tab Sections (ESP)
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})
ESPSection:toggle({name = "Health ESP", callback = function(v) Settings.ESP_Health = v end})
ESPSection:toggle({name = "Distance ESP", callback = function(v) Settings.ESP_Distance = v end})

-- // Misc Tab Section
local PhysSection = MiscTab:section({name = "Physics"})
PhysSection:button({name = "Enable Part Drag", callback = function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))() 
end})

-- // 4. Aimbot & ESP Logic
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
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            local part = p.Character.Head
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
            if onScreen and mouseDist < Settings.FOV and isVisible(part) then
                if Settings.Priority == "Distance" then
                    local dist3D = (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                    if dist3D < bestVal then bestVal = dist3D; target = part end
                elseif Settings.Priority == "Health" then
                    if p.Character.Humanoid.Health < bestVal then bestVal = p.Character.Humanoid.Health; target = part end
                end
            end
        end
    end
    return target
end

-- // 5. ESP Engine
local function CreateESP(plr)
    local Box = Drawing.new("Square")
    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
    Box.Color = Color3.fromRGB(255, 182, 193)
    Tracer.Color = Color3.fromRGB(255, 182, 193)
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Outline = true
    Name.Center = true

    game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.ESP_Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
            local hrp = plr.Character.HumanoidRootPart
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                if Settings.ESP_Boxes then
                    local sizeX = 1000 / pos.Z
                    local sizeY = 1500 / pos.Z
                    Box.Size = Vector2.new(sizeX, sizeY)
                    Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    Box.Visible = true
                else Box.Visible = false end

                if Settings.ESP_Tracers then
                    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else Tracer.Visible = false end

                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, pos.Y - 30)
                    Name.Text = plr.Name .. (Settings.ESP_Health and " [" .. math.floor(plr.Character.Humanoid.Health) .. "HP]" or "")
                    Name.Visible = true
                else Name.Visible = false end
            else Box.Visible = false; Tracer.Visible = false; Name.Visible = false end
        else Box.Visible = false; Tracer.Visible = false; Name.Visible = false end
    end)
end

for _, p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then CreateESP(p) end end
game.Players.PlayerAdded:Connect(CreateESP)

-- // 6. Main Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1
FOVCircle.Visible = true

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end
end)

-- // Toggle UI
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then
                gui.Enabled = not gui.Enabled
            end
        end
    end
end)

print("Blossom Pink Hub Loaded Successfully.")
