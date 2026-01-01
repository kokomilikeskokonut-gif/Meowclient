-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration Settings
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    WallCheck = true, -- NEW: Wallcheck setting
    FOV = 150,
    TargetPart = "Head",
    Smoothness = 0.5
}

-- // 3. Create the Window
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

-- Pages
local MainTab = Window:page({name = "Combat"})
local MiscTab = Window:page({name = "Glitches"})

-- Aimbot Section
local AimSection = MainTab:section({name = "Aimbot"})
AimSection:toggle({name = "Enable Aimbot", callback = function(v) Settings.Aimbot = v end})
AimSection:toggle({name = "Team Check", callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end}) -- NEW TOGGLE

AimSection:slider({
    name = "Aim Speed", 
    min = 1, 
    max = 100, 
    default = 50, 
    callback = function(v) Settings.Smoothness = v / 100 end
})

AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- // 4. Aimbot Engine Functions

-- Wallcheck Function: Fires an invisible beam to see if anything is blocking the view
local function isVisible(targetPart)
    if not Settings.WallCheck then return true end
    
    local char = game.Players.LocalPlayer.Character
    local camera = workspace.CurrentCamera
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char, camera} -- Don't hit yourself or the camera
    
    local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, raycastParams)
    
    if ray and ray.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

local function getClosest()
    local target, shortestDist = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and plr.Team == game.Players.LocalPlayer.Team then continue end
            
            local part = plr.Character:FindFirstChild(Settings.TargetPart)
            if part and plr.Character.Humanoid.Health > 0 then
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                
                if onScreen and isVisible(part) then -- Check if on screen AND not behind wall
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if dist < shortestDist and dist < Settings.FOV then
                        shortestDist = dist
                        target = part
                    end
                end
            end
        end
    end
    return target
end

-- // 5. Rendering & FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 2
FOVCircle.Visible = true

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    -- Improved MouseButton2 check (Right Click)
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getClosest()
        if t then
            local cam = workspace.CurrentCamera
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), Settings.Smoothness)
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

-- Buttons for your other scripts
local KillSection = MainTab:section({name = "Destruction"})
KillSection:button({name = "FE Kill All", callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/FE%20Kill%20All.lua"))()
end})

local DragSection = MiscTab:section({name = "Physics"})
DragSection:button({name = "Enable Part Drag", callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))()
end})
