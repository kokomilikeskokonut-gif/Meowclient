-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration & State
local Settings = {
    AimbotEnabled = false,
    SilentAimEnabled = false, -- Note: This works via Camera redirection in this version
    TeamCheck = true,
    WallCheck = true,
    TargetPart = "Head",
    Smoothness = 0.5,
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
local Window = Library:new({name = "Blossom Combat | Fixed", theme = PinkTheme})
local CombatTab = Window:page({name = "Combat Features"})

local AimSection = CombatTab:section({name = "Aimbot & Targeting"})
AimSection:toggle({name = "Enable Aimbot (Lock)", callback = function(v) Settings.AimbotEnabled = v end})
AimSection:toggle({name = "Enable Team Check", default = true, callback = function(v) Settings.TeamCheck = v end})
AimSection:toggle({name = "Enable Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})
AimSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})

local FOVSection = CombatTab:section({name = "FOV Settings"})
FOVSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})
FOVSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- // 4. Core Logic
local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer

local function IsVisible(part)
    if not Settings.WallCheck then return true end
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 2048)
    local partHit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return partHit and partHit:IsDescendantOf(part.Parent)
end

local function GetClosestPlayer()
    local target = nil
    local shortestDist = Settings.FOV
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.TargetPart) then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            if p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health <= 0 then continue end
            
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

-- // 5. The Engine (RenderStepped is more reliable)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Filled = false

game:GetService("RunService").RenderStepped:Connect(function()
    -- Update FOV Circle
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV

    -- Aimbot Logic (Right Click to Lock)
    if Settings.AimbotEnabled and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            local lookAt = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, Settings.Smoothness)
        end
    end
end)

print("Blossom Fixed Combat Hub Loaded.")
