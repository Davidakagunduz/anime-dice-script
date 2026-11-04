--[[
    Anime Dice — Hub Script
    Compatible: Delta Executor, Wave, Solara, Zorara (Level 7+)
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/Davidakagunduz/anime-dice-script/master/main.lua"))()
]]

-- Visible error popup so Delta doesn't swallow errors silently
local function _notify(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = t, Text = m, Duration = 5})
    end)
end

_notify("Anime Dice Hub", "Script en cours de chargement...")

local ok, err = pcall(function()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local _spawn = (task and task.spawn) or spawn
local _wait = (task and task.wait) or wait
local _delay = (task and task.delay) or delay

local Modules = {}
local ActiveLoops = {}
local GUI = nil

----------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------

local function findRemote(name)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            if v.Name == name or v.Name:lower():find(name:lower()) then
                return v
            end
        end
    end
    return nil
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

----------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------

local function createGUI()
    if GUI then pcall(function() GUI:Destroy() end) end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimeDiceHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Parent: try CoreGui first (works on most executors), then gethui, then PlayerGui
    local guiParent = nil
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
        end
        screenGui.Parent = game:GetService("CoreGui")
        guiParent = "CoreGui"
    end)
    if not guiParent then
        pcall(function()
            screenGui.Parent = gethui()
            guiParent = "gethui"
        end)
    end
    if not guiParent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    pcall(function()
        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", mainFrame)
        stroke.Color = Color3.fromRGB(100, 60, 200)
        stroke.Thickness = 2
    end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    pcall(function() Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8) end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "Anime Dice Hub"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "X"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -33, 0, 3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    pcall(function() Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6) end)

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -46)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- Toggle builder
    local function addToggle(name, description, callback)
        local active = false

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scroll
        pcall(function() Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6) end)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = name
        nameLabel.Size = UDim2.new(1, -60, 0, 22)
        nameLabel.Position = UDim2.new(0, 10, 0, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = description
        descLabel.Size = UDim2.new(1, -60, 0, 16)
        descLabel.Position = UDim2.new(0, 10, 0, 26)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 40, 0, 20)
        indicator.Position = UDim2.new(1, -50, 0.5, -10)
        indicator.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
        indicator.BorderSizePixel = 0
        indicator.Parent = btn
        pcall(function() Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 10) end)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 16, 0, 16)
        dot.Position = UDim2.new(0, 2, 0, 2)
        dot.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
        dot.BorderSizePixel = 0
        dot.Parent = indicator
        pcall(function() Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0) end)

        btn.MouseButton1Click:Connect(function()
            active = not active
            if active then
                indicator.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                dot.Position = UDim2.new(0, 22, 0, 2)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            else
                indicator.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
                dot.Position = UDim2.new(0, 2, 0, 2)
                dot.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
            end
            pcall(callback, active)
        end)
    end

    -- Button builder
    local function addButton(name, description, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 48)
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scroll
        pcall(function() Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6) end)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = name
        nameLabel.Size = UDim2.new(1, -20, 0, 22)
        nameLabel.Position = UDim2.new(0, 10, 0, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(180, 160, 255)
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = btn

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = description
        descLabel.Size = UDim2.new(1, -20, 0, 16)
        descLabel.Position = UDim2.new(0, 10, 0, 26)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn

        btn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end

    GUI = screenGui
    return addToggle, addButton, mainFrame
end

----------------------------------------------------------------------
-- Modules
----------------------------------------------------------------------

-- Auto Roll
local function setupAutoRoll(addToggle)
    addToggle("Auto Roll", "Lance les des automatiquement", function(on)
        ActiveLoops.AutoRoll = on
        if on then
            notify("Auto Roll", "Active")
            _spawn(function()
                while ActiveLoops.AutoRoll do
                    pcall(function()
                        local remote = findRemote("Roll") or findRemote("roll") or findRemote("RollDice")
                        if remote then
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer()
                            elseif remote:IsA("RemoteFunction") then
                                remote:InvokeServer()
                            end
                        end
                    end)

                    pcall(function()
                        local gui = LocalPlayer:FindFirstChild("PlayerGui")
                        if gui then
                            for _, v in pairs(gui:GetDescendants()) do
                                if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
                                    if v.Name:lower():find("roll") then
                                        pcall(firesignal, v, "MouseButton1Click")
                                        pcall(firesignal, v, "Activated")
                                    end
                                end
                            end
                        end
                    end)
                    _wait(0.3)
                end
            end)
        else
            notify("Auto Roll", "Desactive")
        end
    end)
end

-- Auto Collect
local function setupAutoCollect(addToggle)
    addToggle("Auto Collect", "Collecte les recompenses", function(on)
        ActiveLoops.AutoCollect = on
        if on then
            notify("Auto Collect", "Active")
            _spawn(function()
                while ActiveLoops.AutoCollect do
                    pcall(function()
                        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                local n = v.Name:lower()
                                if n:find("collect") or n:find("claim") or n:find("pickup") or n:find("reward") then
                                    pcall(function() v:FireServer() end)
                                end
                            end
                        end
                    end)

                    pcall(function()
                        local hrp = getHRP()
                        if hrp then
                            for _, v in pairs(workspace:GetDescendants()) do
                                if v:IsA("BasePart") and v.CanCollide == false then
                                    local n = v.Name:lower()
                                    if n:find("collect") or n:find("coin") or n:find("gem") or n:find("orb") or n:find("drop") then
                                        if (v.Position - hrp.Position).Magnitude < 200 then
                                            pcall(firetouchinterest, hrp, v, 0)
                                            _wait()
                                            pcall(firetouchinterest, hrp, v, 1)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    _wait(0.5)
                end
            end)
        else
            notify("Auto Collect", "Desactive")
        end
    end)
end

-- Auto Farm
local function setupAutoFarm(addToggle)
    addToggle("Auto Farm", "Roll + collect + merge en boucle", function(on)
        ActiveLoops.AutoFarm = on
        if on then
            notify("Auto Farm", "Active")
            _spawn(function()
                while ActiveLoops.AutoFarm do
                    pcall(function()
                        local roll = findRemote("Roll") or findRemote("roll") or findRemote("RollDice")
                        if roll then
                            if roll:IsA("RemoteEvent") then roll:FireServer()
                            else roll:InvokeServer() end
                        end
                    end)
                    _wait(0.8)

                    pcall(function()
                        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                            if v:IsA("RemoteEvent") then
                                local n = v.Name:lower()
                                if n:find("collect") or n:find("claim") or n:find("reward") or n:find("accept") then
                                    pcall(function() v:FireServer() end)
                                end
                            end
                        end
                    end)

                    pcall(function()
                        local merge = findRemote("Merge") or findRemote("merge") or findRemote("Upgrade")
                        if merge and merge:IsA("RemoteEvent") then merge:FireServer() end
                    end)
                    _wait(1.2)
                end
            end)
        else
            notify("Auto Farm", "Desactive")
        end
    end)
end

-- Speed
local function setupSpeed(addToggle)
    addToggle("Speed x3", "Vitesse de deplacement x3", function(on)
        ActiveLoops.Speed = on
        if on then
            notify("Speed", "Active")
            _spawn(function()
                while ActiveLoops.Speed do
                    pcall(function()
                        local hum = getCharacter():FindFirstChildOfClass("Humanoid")
                        if hum then hum.WalkSpeed = 48 end
                    end)
                    _wait(0.5)
                end
            end)
        else
            pcall(function()
                local hum = getCharacter():FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
            notify("Speed", "Desactive")
        end
    end)
end

-- Infinite Jump
local function setupInfJump(addToggle)
    addToggle("Infinite Jump", "Sauter en l'air", function(on)
        ActiveLoops.InfJump = on
        if on then
            notify("Inf Jump", "Active")
            ActiveLoops.InfJumpConn = UserInputService.JumpRequest:Connect(function()
                if ActiveLoops.InfJump then
                    pcall(function()
                        getCharacter():FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                    end)
                end
            end)
        else
            if ActiveLoops.InfJumpConn then
                ActiveLoops.InfJumpConn:Disconnect()
                ActiveLoops.InfJumpConn = nil
            end
            notify("Inf Jump", "Desactive")
        end
    end)
end

-- ESP
local function setupESP(addToggle)
    addToggle("Player ESP", "Voir les joueurs a travers les murs", function(on)
        ActiveLoops.ESP = on
        if on then
            notify("ESP", "Active")
            _spawn(function()
                while ActiveLoops.ESP do
                    pcall(function()
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local char = player.Character
                                if not char:FindFirstChild("ESPHighlight") then
                                    local hl = Instance.new("Highlight")
                                    hl.Name = "ESPHighlight"
                                    hl.FillColor = Color3.fromRGB(255, 0, 100)
                                    hl.FillTransparency = 0.7
                                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                                    hl.OutlineTransparency = 0
                                    hl.Adornee = char
                                    hl.Parent = char
                                end

                                local head = char:FindFirstChild("Head")
                                if head and not head:FindFirstChild("ESPTag") then
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name = "ESPTag"
                                    bb.Size = UDim2.new(0, 120, 0, 30)
                                    bb.StudsOffset = Vector3.new(0, 3, 0)
                                    bb.AlwaysOnTop = true
                                    bb.Parent = head

                                    local tag = Instance.new("TextLabel")
                                    tag.Size = UDim2.new(1, 0, 1, 0)
                                    tag.BackgroundTransparency = 1
                                    tag.Text = player.DisplayName
                                    tag.TextColor3 = Color3.fromRGB(255, 255, 0)
                                    tag.Font = Enum.Font.GothamBold
                                    tag.TextSize = 14
                                    tag.TextStrokeTransparency = 0.4
                                    tag.Parent = bb
                                end
                            end
                        end
                    end)
                    _wait(2)
                end

                pcall(function()
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Character then
                            local hl = p.Character:FindFirstChild("ESPHighlight")
                            if hl then hl:Destroy() end
                            local h = p.Character:FindFirstChild("Head")
                            if h then local t = h:FindFirstChild("ESPTag") if t then t:Destroy() end end
                        end
                    end
                end)
            end)
        else
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character then
                        local hl = p.Character:FindFirstChild("ESPHighlight")
                        if hl then hl:Destroy() end
                        local h = p.Character:FindFirstChild("Head")
                        if h then local t = h:FindFirstChild("ESPTag") if t then t:Destroy() end end
                    end
                end
            end)
            notify("ESP", "Desactive")
        end
    end)
end

-- Luck Boost
local function setupLuck(addToggle)
    addToggle("Luck Boost", "Multiplie les rolls pour garder le meilleur", function(on)
        ActiveLoops.Luck = on
        if on then
            notify("Luck Boost", "Active")
            if hookmetamethod then
                pcall(function()
                    local old
                    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        if ActiveLoops.Luck and method == "FireServer" and self:IsA("RemoteEvent") then
                            local n = self.Name:lower()
                            if n:find("roll") or n:find("gacha") or n:find("summon") then
                                for i = 1, 3 do
                                    _spawn(function() pcall(old, self, ...) end)
                                end
                            end
                        end
                        return old(self, ...)
                    end))
                end)
            else
                notify("Luck Boost", "hookmetamethod non dispo")
            end
        else
            notify("Luck Boost", "Desactive")
        end
    end)
end

-- Teleport
local function setupTeleport(addButton)
    addButton("TP to Spawn", "Teleportation au spawn", function()
        pcall(function()
            local hrp = getHRP()
            local sp = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
            if hrp and sp then
                hrp.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
                notify("Teleport", "Teleporte au spawn")
            end
        end)
    end)

    addButton("TP to Nearest NPC", "Teleportation au PNJ le plus proche", function()
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local closest, dist = nil, math.huge
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Humanoid") and v.Parent ~= getCharacter() then
                    local root = v.Parent:FindFirstChild("HumanoidRootPart")
                    if root then
                        local d = (root.Position - hrp.Position).Magnitude
                        if d < dist then closest = root; dist = d end
                    end
                end
            end
            if closest then
                hrp.CFrame = closest.CFrame + Vector3.new(0, 3, 0)
                notify("Teleport", "Teleporte (" .. math.floor(dist) .. " studs)")
            end
        end)
    end)
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------

local addToggle, addButton, mainFrame = createGUI()

setupAutoRoll(addToggle)
setupAutoCollect(addToggle)
setupAutoFarm(addToggle)
setupLuck(addToggle)
setupSpeed(addToggle)
setupInfJump(addToggle)
setupESP(addToggle)
setupTeleport(addButton)

notify("Anime Dice Hub", "Charge! RightShift = menu")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if mainFrame then mainFrame.Visible = not mainFrame.Visible end
    end
end)

end)

if not ok then
    _notify("ERREUR", tostring(err))
    warn("[AnimeDiceHub] Erreur: " .. tostring(err))
end
