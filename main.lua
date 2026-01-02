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
    -- Whitelist System
    Whitelist = {},
    WhitelistEnabled = true,
    IgnoreFriends = true,
    -- Combat
    Aimbot = false, TeamCheck = true, WallCheck = true,
    FOV = 150, FOV_Visible = true, FOV_Thickness = 1,
    Smoothness = 0.5,
    Triggerbot = false, TriggerDelay = 0,
    -- Vision
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_Names = false,
    ESP_Health = false,
    ESP_Tracers = false,
    ESP_TracerThickness = 1,
    MaxESPDistance = 2000,
    -- Movement
    SpeedEnabled = false, WalkSpeed = 16, 
    JumpEnabled = false, JumpHeight = 50, 
    Fly = false, FlySpeed = 50, Noclip = false
}

-- // 3. Build UI
local Window = Library:new({name = "Meow client", theme = PinkTheme})

local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"})

-- Combat Sections
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

-- Whitelist Section
local WhiteSection = MainTab:section({name = "Whitelist Manager", side = "left"})
WhiteSection:toggle({name = "Use Whitelist", default = true, callback = function(v) Settings.WhitelistEnabled = v end})
WhiteSection:toggle({name = "Ignore Friends", default = true, callback = function(v) Settings.IgnoreFriends = v end})
WhiteSection:textbox({name = "Whitelist Player", placeholder = "Username...", callback = function(val)
    for _, p in pairs(game.Players:GetPlayers()) do
        if p.Name:lower():sub(1, #val) == val:lower() then
            if table.find(Settings.Whitelist, p.Name) then
                for i, n in ipairs(Settings.Whitelist) do if n == p.Name then table.remove(Settings.Whitelist, i) end end
            else
                table.insert(Settings.Whitelist, p.Name)
            end
        end
    end
end})

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

-- Whitelist Logic
local function isWhitelisted(player)
    if not Settings.WhitelistEnabled then return false end
    if table.find(Settings.Whitelist, player.Name) then return true end
    if Settings.IgnoreFriends and game.Players.LocalPlayer:IsFriendsWith(player.UserId) then return true end
    return false
end

-- Aimbot Target Logic
local function isVisible(part)
    if not Settings.WallCheck then return true end
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, cam}
    local ray = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position), params)
    return not ray or ray.Instance:IsDescendantOf(part.Parent)
end

local function getTarget()
    local target, dist = nil, Settings.FOV
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if isWhitelisted(p) then continue end -- [WHITELIST CHECK]
            if Settings.TeamCheck and p.Team == game.Players.LocalPlayer.Team then continue end
            if p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health <= 0 then continue end
            
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.Head.Position)
            local mag = (Vector2.new(pos.X, pos.Y) - game:GetService("UserInputService"):GetMouseLocation()).Magnitude
            if onScreen and mag < dist and isVisible(p.Character.Head) then
                dist = mag; target = p.Character.Head
            end
        end
    end
    return target
end

-- ESP Engine
local function AddESP(p)
    local Box = Drawing.new("Square")
    local Name = Drawing.new("Text")
    local Tracer = Drawing.new("Line")
    local Health = Drawing.new("Text")

    Box.Color = PinkTheme.AccentColor
    Box.Thickness = 1
    Box.Filled = false
    
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Size = 13
    Name.Outline = true
    Name.Center = true

    Health.Color = Color3.fromRGB(0, 255, 0)
    Health.Size = 13
    Health.Outline = true
    Health.Center = true

    Tracer.Color = PinkTheme.AccentColor

    game:GetService("RunService").RenderStepped:Connect(function()
        if Settings.Running and Settings.ESP_Enabled and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            local hrp = p.Character.HumanoidRootPart
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and hum.Health > 0 then
                -- Color code Whitelisted players in ESP
                local displayColor = isWhitelisted(p) and Color3.fromRGB(255, 255, 0) or PinkTheme.AccentColor
                Box.Color = displayColor
                Tracer.Color = displayColor

                if Settings.ESP_Boxes then
                    local size = 2500 / pos.Z
                    Box.Size = Vector2.new(size, size * 1.5)
                    Box.Position = Vector2.new(pos.X - size / 2, pos.Y - (size * 1.5) / 2)
                    Box.Visible = true
                else Box.Visible = false end

                if Settings.ESP_Names then
                    Name.Position = Vector2.new(pos.X, pos.Y - (2500 / pos.Z) / 1.5 - 15)
                    Name.Text = (isWhitelisted(p) and "[WL] " or "") .. p.Name
                    Name.Visible = true
                else Name.Visible = false end

                if Settings.ESP_Health then
                    Health.Position = Vector2.new(pos.X, pos.Y + (2500 / pos.Z) / 1.5 + 5)
                    Health.Text = "HP: " .. math.floor(hum.Health)
                    Health.Visible = true
                else Health.Visible = false end

                if Settings.ESP_Tracers then
                    Tracer.Thickness = Settings.ESP_TracerThickness
                    Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else Tracer.Visible = false end
            else
                Box.Visible = false; Name.Visible = false; Health.Visible = false; Tracer.Visible = false
            end
        else
            Box.Visible = false; Name.Visible = false; Health.Visible = false; Tracer.Visible = false
        end
    end)
end

-- Initialize ESP
for _, p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then AddESP(p) end end
game.Players.PlayerAdded:Connect(AddESP)

-- Main Render Loop
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = PinkTheme.AccentColor

game:GetService("RunService").RenderStepped:Connect(function()
    if not Settings.Running then FOVCircle:Remove() return end
    FOVCircle.Visible = Settings.FOV_Visible; FOVCircle.Radius = Settings.FOV; FOVCircle.Thickness = Settings.FOV_Thickness
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget()
        if t then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end

    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.SpeedEnabled and Settings.WalkSpeed or 16
        char.Humanoid.JumpHeight = Settings.JumpEnabled and Settings.JumpHeight or 50
    end
end)

