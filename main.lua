-- // 1. Load the Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/ui.lua"))()

-- // 2. Configuration Settings
local Settings = {
    Aimbot = false,
    TeamCheck = true,
    FOV = 150,
    TargetPart = "Head",
    Smoothness = 0.5 -- Default speed (0.1 = slow, 1.0 = instant)
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

-- // NEW: Smoothness Slider
AimSection:slider({
    name = "Aim Speed (Smoothness)", 
    min = 1, 
    max = 100, 
    default = 50, 
    callback = function(v) 
        -- We divide by 100 so the slider feels natural (1 to 100)
        Settings.Smoothness = v / 100 
    end
})

AimSection:slider({name = "FOV Radius", min = 50, max = 800, default = 150, callback = function(v) Settings.FOV = v end})

-- Destruction Section
local KillSection = MainTab:section({name = "Destruction"})
KillSection:button({name = "FE Kill All", callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/FE%20Kill%20All.lua"))()
end})

-- Physics Section
local DragSection = MiscTab:section({name = "Physics"})
DragSection:button({name = "Enable Part Drag", callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kokomilikeskokonut-gif/Meow/refs/heads/main/1-main/projects/%5BFE%5D%20Part%20Drag%20(0%20DESYNC).lua"))()
end})

-- // 4. Aimbot Logic & FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Thickness = 2
FOVCircle.Visible = true

local function getClosest()
    local target, shortestDist = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") then
            if Settings.TeamCheck and plr.Team == game.Players.LocalPlayer.Team then continue end
            local part = plr.Character:FindFirstChild(Settings.TargetPart)
            if part and plr.Character.Humanoid.Health > 0 then
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                if onScreen then
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

game:GetService("RunService").RenderStepped:Connect(function()
    FOVCircle.Position = game:GetService("UserInputService"):GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    if Settings.Aimbot and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getClosest()
        if t then
            -- The LERP function uses the Smoothness variable to decide speed
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
                CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Position), 
                Settings.Smoothness
            )
        end
    end
end)

-- // 5. Right Shift Toggle Logic
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "main" or gui:FindFirstChild("Main")) then
                gui.Enabled = not gui.Enabled
            end
        end
    end
end)

print("Blossom Pink Hub Loaded. Adjust 'Aim Speed' for faster tracking!")
