-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration & State
local Settings = {
    AimbotEnabled = false,
    SilentAimEnabled = false,
    TriggerbotEnabled = false,
    TriggerDelay = 0,
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
local Window = Library:new({name = "Blossom Combat | Elite V3", theme = PinkTheme})
local CombatTab = Window:page({name = "Combat"})

-- AIMBOT SECTION
local AimSection = CombatTab:section({name = "Aimbot Settings", side = "left"})
AimSection:toggle({name = "Enable Aimbot Lock", callback = function(v) Settings.AimbotEnabled = v end})
AimSection:slider({name = "Smoothness", min = 1, max = 100, default = 50, callback = function(v) Settings.Smoothness = v / 100 end})
AimSection:toggle({name = "Show FOV Circle", default = true, callback = function(v) Settings.FOV_Visible = v end})
AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- SILENT AIM & TRIGGER SECTION
local SilentSection = CombatTab:section({name = "Silent & Trigger", side = "right"})
SilentSection:toggle({name = "Enable Silent Aim", callback = function(v) Settings.SilentAimEnabled = v end}) -- BUTTON IS BACK
SilentSection:toggle({name = "Enable Triggerbot", callback = function(v) Settings.TriggerbotEnabled = v end})
SilentSection:slider({name = "Trigger Delay (ms)", min = 0, max = 500, default = 0, callback = function(v) Settings.TriggerDelay = v / 1000 end})

-- CHECKS SECTION
local CheckSection = CombatTab:section({name = "Target Checks", side = "left"})
CheckSection:toggle({name = "Team Check", default = true, callback = function(v) Settings.TeamCheck = v end})
CheckSection:toggle({name = "Wall Check", default = true, callback = function(v) Settings.WallCheck = v end})

-- // 4. Core Logic
local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

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

-- // 5. The Silent Aim Engine (Hook)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "FindPartOnRayWithIgnoreList" and Settings.SilentAimEnabled and not checkcaller() then
        local target = GetClosestPlayer()
        if target then
            args[1] = Ray.new(Camera.CFrame.Position, (target.Position - Camera.CFrame.Position).Unit * 1000)
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end))

-- // 6. The Aimbot & Trigger Engine
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 182, 193)

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Visible = Settings.FOV_Visible
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV

    -- Aimbot (Hold Right Click)
    if Settings.AimbotEnabled and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), Settings.Smoothness)
        end
    end

    -- Triggerbot
    if Settings.TriggerbotEnabled then
        local target = Mouse.Target
        if target and target.Parent:FindFirstChild("Humanoid") then
            local targetPlayer = game.Players:GetPlayerFromCharacter(target.Parent)
            if targetPlayer and targetPlayer ~= LocalPlayer then
                if Settings.TeamCheck and targetPlayer.Team == LocalPlayer.Team then return end
                task.wait(Settings.TriggerDelay)
                mouse1click()
            end
        end
    end
end)

print("Blossom Combat V3: UI Fixed & Silent Aim restored.")
