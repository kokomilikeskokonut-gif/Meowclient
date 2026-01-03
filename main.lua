-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration & State
local Settings = {
    -- Combat Logic
    AimbotEnabled = false,
    SilentAimEnabled = false,
    TeamCheck = true,
    WallCheck = true,
    
    -- Customization
    TargetPart = "Head",
    Smoothness = 0.5, -- Higher = faster/snappier
    FOV = 150,
    FOV_Visible = true,
}

local PinkTheme = {
    MainColor = Color3.fromRGB(25, 25, 25),      
    AccentColor = Color3.fromRGB(255, 182, 193), 
    BackgroundColor = Color3.fromRGB(20, 20, 20), 
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.fromRGB(255, 255, 255)
}

-- // 3. Build the UI
local Window = Library:new({name = "Blossom Combat | Hub", theme = PinkTheme})
local CombatTab = Window:page({name = "Combat Features"})

-- Aimbot Section
local AimSection = CombatTab:section({name = "Aimbot & Silent Aim"})
AimSection:toggle({name = "Enable Aimbot (Lock)", callback = function(v) Settings.AimbotEnabled = v end})
AimSection:toggle({name = "Enable Silent Aim", callback = function(v) Settings.SilentAimEnabled = v end})
AimSection:toggle({name = "Team Check", default = true, callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

-- Customization Section
local AdjustSection = CombatTab:section({name = "Adjustments"})
AdjustSection:slider({
    name = "Aimbot Smoothness", 
    min = 1, 
    max = 100, 
    default = 50, 
    callback = function(v) 
        -- Converts 1-100 scale to a 0.01-1.0 scale for Lerp
        Settings.Smoothness = v / 100 
    end
})

local FOVSection = CombatTab:section({name = "FOV Settings"})
FOVSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})
FOVSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- // 4. Core Combat Functions
local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer

local function IsVisible(part)
    if not Settings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local ray = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, params)
    return (ray and ray.Instance:IsDescendantOf(part.Parent))
end

local function GetClosestPlayer()
    local target = nil
    local shortestDist = Settings.FOV
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.TargetPart) then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local part = p.Character[Settings.TargetPart]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude

            if onScreen and dist < shortestDist then
                if IsVisible(part) then
                    shortestDist = dist
                    target = part
                end
            end
        end
    end
    return target
end

-- // 5. The Silent Aim Engine
local oldIndex
oldIndex = hookmetatable(game, {
    __index = newcclosure(function(self, index)
        if index == "Hit" and Settings.SilentAimEnabled and not checkcaller() then
            local target = GetClosestPlayer()
            if target then
                return target.CFrame
            end
        end
        return oldIndex(self, index)
    end)
})

-- // 6. The Aimbot Engine
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 182, 193)

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV

    if Settings.AimbotEnabled and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            -- Uses the Smoothness setting to determine how fast the camera snaps
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
end)

print("Blossom Combat Hub Loaded.")
