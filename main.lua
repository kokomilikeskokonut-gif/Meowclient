-- // 1. Services & Setup
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // Load Library
local Success, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()
end)

if not Success then
    warn("UI Library failed to load. Check the URL.")
    return
end

local PinkTheme = {
    MainColor = Color3.fromRGB(25, 25, 25),      
    AccentColor = Color3.fromRGB(255, 182, 193), 
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}

-- // 2. Configuration
local Settings = {
    Running = true,
    -- Combat
    Aimbot = false, TeamCheck = true, WallCheck = true,
    FOV = 150, FOV_Visible = true,
    Smoothness = 0.5,
    Triggerbot = false, TriggerDelay = 0,
    -- Vision
    ESP_Enabled = false, 
    -- Movement
    SpeedEnabled = false, WalkSpeed = 16, 
    JumpEnabled = false, JumpHeight = 50
}

-- // 3. Build UI
local Window = Library:new({name = "Blossom Pink Hub", theme = PinkTheme})
local MainTab = Window:page({name = "Combat"})
local VisionTab = Window:page({name = "Vision"})
local MoveTab = Window:page({name = "Movement"})

-- Combat Sections
local AimSection = MainTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})

local TrigSection = MainTab:section({name = "Triggerbot", side = "left"})
TrigSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.Triggerbot = v end})
TrigSection:slider({name = "Shot Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

local TargetSection = MainTab:section({name = "Target & FOV", side = "right"})
TargetSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
TargetSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})

-- Vision Sections
local ESPSection = VisionTab:section({name = "Visuals"})
ESPSection:toggle({name = "Highlight ESP", callback = function(v) Settings.ESP_Enabled = v end})

-- Movement Sections
local PhysSection = MoveTab:section({name = "Physics", side = "left"})
PhysSection:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
PhysSection:slider({name = "WalkSpeed", min = 16, max = 200, default = 16, callback = function(v) Settings.WalkSpeed = v end})
PhysSection:toggle({name = "Enable Jump", callback = function(v) Settings.JumpEnabled = v end})
PhysSection:slider({name = "JumpHeight", min = 50, max = 300, default = 50, callback = function(v) Settings.JumpHeight = v end})

-- // 4. FOV Circle (Drawing API)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = PinkTheme.AccentColor
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

-- // 5. Helper Functions

local function getClosestPlayer()
    local closest = nil
    local shortestDist = Settings.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and root and hum.Health > 0 then
                -- Team Check
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end

                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if onScreen then
                    local dist = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(pos.X, pos.Y)).Magnitude

                    if dist < shortestDist then
                        closest = root
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- Triggerbot Logic
local TriggerLocked = false
local function handleTriggerbot()
    if not Settings.Triggerbot or TriggerLocked then return end
    
    local mouseLocation = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    
    if result and result.Instance and result.Instance.Parent then
        local model = result.Instance.Parent
        local hum = model:FindFirstChild("Humanoid")
        local player = Players:GetPlayerFromCharacter(model)
        
        if hum and hum.Health > 0 and player then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then return end
            
            TriggerLocked = true
            task.wait(Settings.TriggerDelay)
            
            -- Use VirtualInputManager (Better than mouse1click)
            VirtualInputManager:SendMouseButtonEvent(mouseLocation.X, mouseLocation.Y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(mouseLocation.X, mouseLocation.Y, 0, false, game, 1)
            
            task.wait(0.1)
            TriggerLocked = false
        end
    end
end

-- ESP Logic (Highlight Method - Safer)
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            if Settings.ESP_Enabled then
                if not char:FindFirstChild("HighlightESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "HighlightESP"
                    hl.FillColor = PinkTheme.AccentColor
                    hl.OutlineColor = Color3.new(1,1,1)
                    hl.Parent = char
                end
            else
                if char:FindFirstChild("HighlightESP") then
                    char.HighlightESP:Destroy()
                end
            end
        end
    end
end

-- // 6. Main Loop
RunService.RenderStepped:Connect(function()
    -- FOV Circle Update
    FOVCircle.Visible = Settings.Aimbot or Settings.FOV_Visible
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Position = UserInputService:GetMouseLocation()

    if not Settings.Running then return end

    -- Physics (Movement)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        
        if Settings.SpeedEnabled then
            hum.WalkSpeed = Settings.WalkSpeed
        end
        
        if Settings.JumpEnabled then
            -- Use JumpPower or JumpHeight depending on game settings, usually JumpHeight nowadays
            hum.UseJumpPower = false
            hum.JumpHeight = Settings.JumpHeight
        end
    end

    -- Triggerbot
    handleTriggerbot()

    -- Aimbot
    if Settings.Aimbot then
        local target = getClosestPlayer()
        if target then
            -- Smooth Camera Move
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, target.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, Settings.Smoothness)
        end
    end

    -- Update ESP
    updateESP()
end)
