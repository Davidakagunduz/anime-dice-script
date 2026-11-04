--[[
    Anime Dice — Hub Script
    Compatible: Delta Executor, Wave, Solara, Zorara (Level 7+)
    Load: loadstring(game:HttpGet("RAW_URL"))()
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Module registry
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

local function findInWorkspace(pattern)
    local results = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name:lower():find(pattern:lower()) then
            table.insert(results, v)
        end
    end
    return results
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

----------------------------------------------------------------------
-- GUI Builder
----------------------------------------------------------------------

local function createGUI()
    if GUI then GUI:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimeDiceHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 320, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 60, 200)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

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

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    -- Scroll frame for buttons
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "ButtonList"
    scroll.Size = UDim2.new(1, -20, 1, -50)
    scroll.Position = UDim2.new(0, 10, 0, 42)
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

    -- Toggle button builder
    local function addToggle(name, description, callback)
        local active = false

        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, -8, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

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
        descLabel.Size = UDim2.new(1, -60, 0, 18)
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

        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(0, 10)
        indCorner.Parent = indicator

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 16, 0, 16)
        dot.Position = UDim2.new(0, 2, 0, 2)
        dot.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
        dot.BorderSizePixel = 0
        dot.Parent = indicator

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

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
            callback(active)
        end)

        return btn
    end

    -- One-shot button builder
    local function addButton(name, description, callback)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, -8, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

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
        descLabel.Size = UDim2.new(1, -20, 0, 18)
        descLabel.Position = UDim2.new(0, 10, 0, 26)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 11
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = btn

        btn.MouseButton1Click:Connect(function()
            callback()
        end)

        return btn
    end

    -- Protect GUI from game resets
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    GUI = screenGui
    return addToggle, addButton
end

----------------------------------------------------------------------
-- Module: Auto Roll
----------------------------------------------------------------------

Modules.AutoRoll = function(addToggle)
    addToggle("Auto Roll", "Lance les dés automatiquement", function(on)
        if on then
            ActiveLoops.AutoRoll = true
            notify("Auto Roll", "Activé")
            task.spawn(function()
                while ActiveLoops.AutoRoll do
                    local remote = findRemote("Roll") or findRemote("roll") or findRemote("RollDice")
                    if remote then
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer()
                        elseif remote:IsA("RemoteFunction") then
                            pcall(function() remote:InvokeServer() end)
                        end
                    end

                    -- Fallback: look for a roll button in the PlayerGui and fire it
                    local gui = LocalPlayer:FindFirstChild("PlayerGui")
                    if gui then
                        for _, v in pairs(gui:GetDescendants()) do
                            if v:IsA("TextButton") or v:IsA("ImageButton") then
                                if v.Name:lower():find("roll") and v.Visible then
                                    pcall(function() firesignal(v, "MouseButton1Click") end)
                                    pcall(function() firesignal(v, "Activated") end)
                                end
                            end
                        end
                    end

                    task.wait(0.3)
                end
            end)
        else
            ActiveLoops.AutoRoll = false
            notify("Auto Roll", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Auto Collect
----------------------------------------------------------------------

Modules.AutoCollect = function(addToggle)
    addToggle("Auto Collect", "Collecte les récompenses / items au sol", function(on)
        if on then
            ActiveLoops.AutoCollect = true
            notify("Auto Collect", "Activé")
            task.spawn(function()
                while ActiveLoops.AutoCollect do
                    -- Fire all collect/claim/pickup remotes
                    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local n = v.Name:lower()
                            if n:find("collect") or n:find("claim") or n:find("pickup") or n:find("reward") then
                                pcall(function() v:FireServer() end)
                            end
                        end
                    end

                    -- Touch collectible parts in workspace
                    local hrp = getHRP()
                    if hrp then
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("BasePart") and v.CanCollide == false then
                                local n = v.Name:lower()
                                if n:find("collect") or n:find("coin") or n:find("gem") or n:find("orb") or n:find("drop") then
                                    if (v.Position - hrp.Position).Magnitude < 200 then
                                        firetouchinterest(hrp, v, 0)
                                        task.wait()
                                        firetouchinterest(hrp, v, 1)
                                    end
                                end
                            end
                        end
                    end

                    task.wait(0.5)
                end
            end)
        else
            ActiveLoops.AutoCollect = false
            notify("Auto Collect", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Auto Farm
----------------------------------------------------------------------

Modules.AutoFarm = function(addToggle)
    addToggle("Auto Farm", "Farm automatique (roll + collect + repeat)", function(on)
        if on then
            ActiveLoops.AutoFarm = true
            notify("Auto Farm", "Activé — farm en boucle")
            task.spawn(function()
                while ActiveLoops.AutoFarm do
                    -- Roll
                    local roll = findRemote("Roll") or findRemote("roll") or findRemote("RollDice")
                    if roll then
                        pcall(function()
                            if roll:IsA("RemoteEvent") then
                                roll:FireServer()
                            else
                                roll:InvokeServer()
                            end
                        end)
                    end
                    task.wait(0.8)

                    -- Collect / claim
                    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") then
                            local n = v.Name:lower()
                            if n:find("collect") or n:find("claim") or n:find("reward") or n:find("accept") then
                                pcall(function() v:FireServer() end)
                            end
                        end
                    end

                    -- Merge / upgrade if available
                    local merge = findRemote("Merge") or findRemote("merge") or findRemote("Upgrade")
                    if merge and merge:IsA("RemoteEvent") then
                        pcall(function() merge:FireServer() end)
                    end

                    task.wait(1.2)
                end
            end)
        else
            ActiveLoops.AutoFarm = false
            notify("Auto Farm", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Speed Boost
----------------------------------------------------------------------

Modules.Speed = function(addToggle)
    addToggle("Speed Boost", "Vitesse de déplacement x3", function(on)
        if on then
            ActiveLoops.Speed = true
            notify("Speed", "Activé")
            task.spawn(function()
                while ActiveLoops.Speed do
                    local char = getCharacter()
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.WalkSpeed = 48
                    end
                    task.wait(0.5)
                end
            end)
        else
            ActiveLoops.Speed = false
            local char = getCharacter()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
            notify("Speed", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Teleport
----------------------------------------------------------------------

Modules.Teleport = function(addButton)
    addButton("TP to Spawn", "Téléportation au spawn", function()
        local hrp = getHRP()
        local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
        if hrp and spawn then
            hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            notify("Teleport", "Téléporté au spawn")
        end
    end)

    addButton("TP to Nearest NPC", "Téléportation au PNJ le plus proche", function()
        local hrp = getHRP()
        if not hrp then return end

        local closest, dist = nil, math.huge
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Humanoid") and v.Parent ~= getCharacter() then
                local root = v.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (root.Position - hrp.Position).Magnitude
                    if d < dist then
                        closest = root
                        dist = d
                    end
                end
            end
        end

        if closest then
            hrp.CFrame = closest.CFrame + Vector3.new(0, 3, 0)
            notify("Teleport", "Téléporté au PNJ (" .. math.floor(dist) .. " studs)")
        else
            notify("Teleport", "Aucun PNJ trouvé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Luck Manipulation
----------------------------------------------------------------------

Modules.Luck = function(addToggle)
    addToggle("Luck Boost", "Intercepte les rolls pour forcer les raretés hautes", function(on)
        if on then
            ActiveLoops.Luck = true
            notify("Luck Boost", "Activé — hook namecall actif")

            -- Hook __namecall to intercept roll results and retry on low rarity
            if hookmetamethod then
                local old
                old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    if ActiveLoops.Luck then
                        -- Intercept server responses that look like roll results
                        if method == "InvokeServer" and self:IsA("RemoteFunction") then
                            local n = self.Name:lower()
                            if n:find("roll") or n:find("gacha") or n:find("summon") then
                                -- Fire multiple times, keep best result
                                local best = nil
                                for i = 1, 5 do
                                    local ok, result = pcall(old, self, ...)
                                    if ok and result then
                                        if type(result) == "table" then
                                            local rarity = result.Rarity or result.rarity or result.Tier or result.tier or 0
                                            if not best or (tonumber(rarity) or 0) > (tonumber(best.Rarity or best.rarity or best.Tier or best.tier or 0) or 0) then
                                                best = result
                                            end
                                        else
                                            best = result
                                            break
                                        end
                                    end
                                    task.wait(0.1)
                                end
                                return best
                            end
                        end

                        -- Intercept FireServer to send extra roll attempts
                        if method == "FireServer" and self:IsA("RemoteEvent") then
                            local n = self.Name:lower()
                            if n:find("roll") or n:find("gacha") or n:find("summon") then
                                for i = 1, 3 do
                                    task.spawn(function()
                                        pcall(old, self, ...)
                                    end)
                                end
                            end
                        end
                    end
                    return old(self, ...)
                end))
            else
                notify("Luck Boost", "hookmetamethod non disponible sur cet executor")
            end
        else
            ActiveLoops.Luck = false
            notify("Luck Boost", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: Infinite Jump
----------------------------------------------------------------------

Modules.InfJump = function(addToggle)
    addToggle("Infinite Jump", "Sauter indéfiniment en l'air", function(on)
        if on then
            ActiveLoops.InfJump = true
            notify("Inf Jump", "Activé — espace pour sauter en l'air")

            local uis = UserInputService
            ActiveLoops.InfJumpConn = uis.JumpRequest:Connect(function()
                if ActiveLoops.InfJump then
                    local char = getCharacter()
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            ActiveLoops.InfJump = false
            if ActiveLoops.InfJumpConn then
                ActiveLoops.InfJumpConn:Disconnect()
                ActiveLoops.InfJumpConn = nil
            end
            notify("Inf Jump", "Désactivé")
        end
    end)
end

----------------------------------------------------------------------
-- Module: ESP (player highlight)
----------------------------------------------------------------------

Modules.ESP = function(addToggle)
    addToggle("Player ESP", "Voir les joueurs à travers les murs", function(on)
        if on then
            ActiveLoops.ESP = true
            notify("ESP", "Activé")
            task.spawn(function()
                while ActiveLoops.ESP do
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

                            -- Nametag
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
                    task.wait(2)
                end

                -- Cleanup on disable
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Character then
                        local hl = player.Character:FindFirstChild("ESPHighlight")
                        if hl then hl:Destroy() end
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local tag = head:FindFirstChild("ESPTag")
                            if tag then tag:Destroy() end
                        end
                    end
                end
            end)
        else
            ActiveLoops.ESP = false
            notify("ESP", "Désactivé")
            -- Immediate cleanup
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    local hl = player.Character:FindFirstChild("ESPHighlight")
                    if hl then hl:Destroy() end
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local tag = head:FindFirstChild("ESPTag")
                        if tag then tag:Destroy() end
                    end
                end
            end
        end
    end)
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------

local addToggle, addButton = createGUI()

Modules.AutoRoll(addToggle)
Modules.AutoCollect(addToggle)
Modules.AutoFarm(addToggle)
Modules.Luck(addToggle)
Modules.Speed(addToggle)
Modules.InfJump(addToggle)
Modules.ESP(addToggle)
Modules.Teleport(addButton)

notify("Anime Dice Hub", "Chargé — ouvre le menu en jeu", 5)

-- Toggle GUI with RightShift
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local main = GUI and GUI:FindFirstChild("Main")
        if main then
            main.Visible = not main.Visible
        end
    end
end)
