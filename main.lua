-- // 1. Configuration & Settings
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    FOV = 150,
    TargetPart = "Head",
    Smoothness = 0.05
}

-- // 2. Load the Library (Using your GitHub Raw Link)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 3. Build the Menu
local Window = Library:new({
    name = "Blossom Pink Hub",
    ConfigName = "BlossomConfig"
})

-- Create Pages
local CombatPage = Window:page({name = "Combat"})
local MiscPage = Window:page({name = "Misc"})

-- Aimbot Section
local AimSection = CombatPage:section({name = "Aimbot"})

AimSection:toggle({
    name = "Enable Aimbot",
    callback = function(v) Settings.Aimbot = v end
})

AimSection:toggle({
    name = "Team Check",
    callback = function(v) Settings.TeamCheck = v end
})

AimSection:slider({
    name = "FOV Size",
    min = 50,
    max = 500,
    default = 150,
    callback = function(v) Settings.FOV = v end
})

-- Destruction Section (Kill All)
local DestSection = CombatPage:section({name = "Destruction"})
DestSection:button({
    name = "FE Kill All",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/FE%20Kill%20All.lua"))()
    end
})

-- Misc Section (Part Drag)
local MiscSection = MiscPage:section({name = "Physics"})
MiscSection:button({
    name = "Enable Part Drag",
    callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))()
    end
})

-- // 4. Aimbot Engine & FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193) -- Blossom Pink
FOVCircle.Thickness = 2
FOVCircle.Visible = true

local function getTarget()
    local target, shortestDist = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character then
            if Settings.TeamCheck and plr.Team == game.Players.LocalPlayer.Team then continue end
            local head = plr.Character:FindFirstChild(Settings.TargetPart)
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if dist < shortestDist and dist < Settings.FOV then
                        shortestDist = dist
                        target = head
                    end
                end
            end
        end
    end
    return target
end

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getTarget()
        if t then
            local cam = workspace.CurrentCamera
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.Position), Settings.Smoothness)
        end
    end
end)

-- // 5. Right Shift to Toggle UI
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        -- Find the UI by name (This looks for the main Frame in CoreGui)
        local main = game:GetService("CoreGui"):FindFirstChild("main")
        if main then
            main.Visible = not main.Visible
        end
    end
end)

print("Blossom Pink Hub successfully loaded!")