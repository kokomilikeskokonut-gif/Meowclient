-- // 1. Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // 2. Load UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

local Settings = {
    Aimbot = false,
    WallCheck = true,
    TeamCheck = true,
    FOV = 150,
    Smoothness = 0.2, -- 0.1 is very smooth, 1.0 is instant snap
    -- Movement
    SpeedEnabled = false, WalkSpeed = 16,
    JumpEnabled = false, JumpHeight = 50
}

-- // 3. UI Setup
local Window = Library:new({name = "Blossom Legit", theme = {
    MainColor = Color3.fromRGB(25, 25, 25),      
    AccentColor = Color3.fromRGB(255, 182, 193), 
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}})

local MainTab = Window:page({name = "Combat"})
local MoveTab = Window:page({name = "Movement"})

MainTab:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
MainTab:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
MainTab:toggle({name = "Team Check", default = true, callback = function(v) Settings.TeamCheck = v end})
MainTab:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})
MainTab:slider({name = "Smoothness", min = 1, max = 100, default = 20, callback = function(v) Settings.Smoothness = v / 100 end})

MoveTab:toggle({name = "Enable Speed", callback = function(v) Settings.SpeedEnabled = v end})
MoveTab:slider({name = "WalkSpeed", min = 16, max = 200, default = 16, callback = function(v) Settings.WalkSpeed = v end})

-- // 4. FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Transparency = 1
FOVCircle.Filled = false

-- // 5. Logic Functions

-- Wall Check (Raycasting)
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    
    local rayParams = RaycastParams.new()
    -- Ignore yourself and the target's character model so the ray doesn't hit their own arm
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastResult = workspace:Raycast(origin, direction, rayParams)
    
    -- If raycastResult is nil, the path is clear
    return raycastResult == nil 
end

-- Find Target in FOV
local function getClosestPlayer()
    local target = nil
    local shortestDist = Settings.FOV
    local mouseLoc = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local hum = player.Character:FindFirstChild("Humanoid")

            if hum and hum.Health > 0 then
                -- Team Check
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
                
                -- Screen Check
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                    if dist < shortestDist then
                        -- Wall Check
                        if isVisible(head) then
                            target = head
                            shortestDist = dist
                        end
                    end
                end
            end
        end
    end
    return target
end

-- // 6. Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Visual
    FOVCircle.Visible = Settings.Aimbot
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Position = UserInputService:GetMouseLocation()

    -- Movement Physics
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if Settings.SpeedEnabled then
            hum.WalkSpeed = Settings.WalkSpeed
        end
    end

    -- Aimbot Execution
    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayer()
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mouseLoc = UserInputService:GetMouseLocation()
            
            -- Smoothly move camera towards target
            local moveX = (targetPos.X - mouseLoc.X) * Settings.Smoothness
            local moveY = (targetPos.Y - mouseLoc.Y) * Settings.Smoothness
            
            mousemoverel(moveX, moveY)
        end
    end
end)
