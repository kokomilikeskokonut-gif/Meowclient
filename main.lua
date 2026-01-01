-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration & State
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
    Priority = "Distance", -- "Distance" or "Health"
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

-- // 3. Build the UI
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MiscTab = Window:page({name = "Misc"})

-- Combat Section
local AimSection = MainTab:section({name = "Aimbot Settings"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

-- Fixed Priority Dropdown
AimSection:dropdown({
    name = "Target Priority",
    content = {"Distance", "Health"},
    default = "Distance",
    callback = function(v) 
        Settings.Priority = v 
        print("Priority set to: " .. v) -- Helpful for debugging
    end
})

AimSection:slider({name = "Aim Speed", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- Vision Section
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Master Switch", callback = function(v) Settings.ESP_Enabled = v end})
ESPSection:toggle({name = "Box ESP", callback = function(v) Settings.ESP_Boxes = v end})
ESPSection:toggle({name = "Tracers", callback = function(v) Settings.ESP_Tracers = v end})
ESPSection:toggle({name = "Name ESP", callback = function(v) Settings.ESP_Names = v end})
ESPSection:toggle({name = "Health ESP", callback = function(v) Settings.ESP_Health = v end})
ESPSection:toggle({name = "Distance ESP", callback = function(v) Settings.ESP_Distance = v end})

-- Misc Section
local PhysSection = MiscTab:section({name = "Physics"})
PhysSection:button({name = "Enable Part Drag", callback = function() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))() 
end})

-- // 4. Target & Visibility Engines
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    local camera = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    if not char then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, camera}
    
    local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, rayParams)
    return (ray and ray.Instance:IsDescendantOf(targetPart.Parent))
end

local function getBestTarget()
    local target, bestVal = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    local cam = workspace.CurrentCamera

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character.Humanoid.Health <= 0 then continue end
            
            local part = p.Character.Head
            local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
            local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude

            if onScreen and mouseDist < Settings.FOV and isVisible(part) then
                if Settings.Priority == "Distance" then
                    -- Priority: Closest to your camera in 3D space
                    local dist3D = (part.Position - cam.CFrame.Position).Magnitude
                    if dist3D < bestVal then
                        bestVal = dist3D
                        target = part
                    end
                elseif Settings.Priority == "Health" then
                    -- Priority: Lowest current HP
                    local hp = p.Character.Humanoid.Health
                    if hp < bestVal then
                        bestVal = hp
                        target = part
                    end
                end
            end
        end
    end
    return target
end

-- // 5. Rendering & Aimbot Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1
FOVCircle.Visible = true

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    -- Right-Click Check
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getBestTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
                CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), 
                Settings.Smoothness
            )
        end
    end
end)

-- // 6. Simple ESP System
local function CreateESP(plr)
    local Box = Drawing.new("Square")
    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")
    
    Box.Color = Color3.fromRGB(255, 182, 193)
    Tracer.Color = Color3.fromRGB(255, 182, 193)
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Outline = true
    Name.Center = true

    local update
    update = game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.ESP_Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
            local hrp = plr.Character.HumanoidRootPart
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                Box.Visible = Settings.ESP_Boxes
                Tracer.Visible = Settings.ESP_Tracers
                Name.Visible = Settings.ESP_Names
                
                if Settings.ESP_Boxes then
                    local size = 1500 / pos.Z
                    Box.Size = Vector2.new(size, size * 1.5)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - (size * 1.5) / 2)
                end
                if Settings.ESP_Tracers then
                    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                end
                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    Name.Text = plr.Name .. (Settings.ESP_Health and " [" .. math.floor(plr.Character.Humanoid.Health) .. "]" or "")
                end
            else Box.Visible = false; Tracer.Visible = false; Name.Visible = false end
        else
            Box.Visible = false; Tracer.Visible = false; Name.Visible = false
            if not plr.Parent then update:Disconnect() end
        end
    end)
end

for _, p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then CreateESP(p) end end
game.Players.PlayerAdded:Connect(CreateESP)

-- // 7. UI Toggle (Right Shift)
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then
                gui.Enabled = not gui.Enabled
            end
        end
    end
end)
