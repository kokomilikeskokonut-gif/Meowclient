-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration Settings
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true,
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
local VisionTab = Window:page({name = "Vision"}) -- NEW PAGE
local MiscTab = Window:page({name = "Misc"})

-- // Combat Tab Sections
local AimSection = MainTab:section({name = "Aimbot"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
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

-- // 4. ESP Engine Logic
local function CreateESP(plr)
    local Box = Drawing.new("Square")
    local Tracer = Drawing.new("Line")
    local Name = Drawing.new("Text")
    local Dist = Drawing.new("Text")
    
    Box.Color = Color3.fromRGB(255, 182, 193) -- Blossom Pink
    Box.Thickness = 1
    Tracer.Color = Color3.fromRGB(255, 182, 193)
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Center = true
    Name.Outline = true
    Dist.Color = Color3.fromRGB(255, 255, 255)
    Dist.Center = true
    Dist.Outline = true

    local updater
    updater = game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.ESP_Enabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local hrp = plr.Character.HumanoidRootPart
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude

            if onScreen then
                -- Box ESP logic
                if Settings.ESP_Boxes then
                    local sizeX = 1000 / pos.Z
                    local sizeY = 1500 / pos.Z
                    Box.Size = Vector2.new(sizeX, sizeY)
                    Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    Box.Visible = true
                else Box.Visible = false end

                -- Tracers logic
                if Settings.ESP_Tracers then
                    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else Tracer.Visible = false end

                -- Name ESP logic
                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, (pos.Y - (1500 / pos.Z) / 2) - 15)
                    Name.Text = plr.Name .. (Settings.ESP_Health and " [" .. math.floor(plr.Character.Humanoid.Health) .. "%]" or "")
                    Name.Visible = true
                else Name.Visible = false end

                -- Distance logic
                if Settings.ESP_Distance then
                    Dist.Position = Vector2.new(pos.X, (pos.Y + (1500 / pos.Z) / 2) + 5)
                    Dist.Text = math.floor(distance) .. " studs"
                    Dist.Visible = true
                else Dist.Visible = false end
            else
                Box.Visible = false; Tracer.Visible = false; Name.Visible = false; Dist.Visible = false
            end
        else
            Box.Visible = false; Tracer.Visible = false; Name.Visible = false; Dist.Visible = false
            if not plr.Parent then updater:Disconnect() end
        end
    end)
end

-- Apply ESP to all players
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then CreateESP(p) end
end
game.Players.PlayerAdded:Connect(CreateESP)

-- // 5. Aimbot Logic (Enhanced)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 1
FOVCircle.Visible = true

local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    local camera = workspace.CurrentCamera
    local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, RaycastParams.new())
    return (ray and ray.Instance:IsDescendantOf(targetPart.Parent))
end

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = nil
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        local dist = Settings.FOV
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
                local hrp = p.Character.Head
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                if onScreen and isVisible(hrp) then
                    local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if mag < dist then
                        dist = mag
                        target = hrp
                    end
                end
            end
        end
        if target then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Position), Settings.Smoothness)
        end
    end
end)

-- // 6. Toggle Hub (Right Shift)
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then
                gui.Enabled = not gui.Enabled
            end
        end
    end
end)

-- Other scripts
local KillSection = MainTab:section({name = "Destruction"})
KillSection:button({name = "FE Kill All", callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/FE%20Kill%20All.lua"))() end})

local DragSection = MiscTab:section({name = "Physics"})
DragSection:button({name = "Enable Part Drag", callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))() end})
