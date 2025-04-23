-- Script de Parkour para Roblox
-- Este script cria uma interface gráfica profissional para gravar e reproduzir ações de parkour.
-- Use em um executor externo. Siga os comentários para adaptar ou adicionar novos parkours.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- ### Módulo GUI
local GUI = {}
function GUI:CreateWindow()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ParkourGUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer.PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 400, 0, 300)
    Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

   -- Barra de título
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, -90, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.Text = "Parkour Creator"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 18
    TitleLabel.Parent = TitleBar

  -- Botões de controle
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.Text = "X"
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.SourceSans
    CloseButton.TextSize = 18
    CloseButton.Parent = Frame
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
    MinimizeButton.Text = "–"
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.Font = Enum.Font.SourceSans
    MinimizeButton.TextSize = 18
    MinimizeButton.Parent = Frame
    MinimizeButton.MouseButton1Click:Connect(function()
        Frame.Visible = not Frame.Visible
    end)

    local MaximizeButton = Instance.new("TextButton")
    MaximizeButton.Size = UDim2.new(0, 30, 0, 30)
    MaximizeButton.Position = UDim2.new(1, -90, 0, 0)
    MaximizeButton.Text = "☐"
    MaximizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MaximizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MaximizeButton.Font = Enum.Font.SourceSans
    MaximizeButton.TextSize = 18
    MaximizeButton.Parent = Frame

  -- Funcionalidade de Arrastar
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return Frame, ScreenGui
end

-- ### Módulo de Gravação
local Recording = {}
local recording = false
local recordedActions = {}

function Recording:Start()
    recording = true
    recordedActions = {}
    local lastPosition = RootPart.Position
    while recording do
        local currentPosition = RootPart.Position
        local currentCFrame = RootPart.CFrame
        if (currentPosition - lastPosition).Magnitude > 0.1 then
            table.insert(recordedActions, {
                position = currentPosition,
                cframe = currentCFrame,
                timestamp = tick(),
                jumping = Humanoid.Jump
            })
            lastPosition = currentPosition
        end
        wait(0.05)
    end
end

function Recording:Stop()
    recording = false
end

-- ### Módulo de Detecção
local Detection = {}
local detectionMethod = "Raycasting" -- Pode mudar para "Região 3" também

function Detection:DetectObstacles(position)
    if detectionMethod == "Raycasting" then
        local rayOrigin = position
        local rayDirection = Vector3.new(0, -10, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        return result and result.Position or nil
    elseif detectionMethod == "Region3" then
        local region = Region3.new(position - Vector3.new(5, 5, 5), position + Vector3.new(5, 5, 5))
        local parts = workspace:FindPartsInRegion3(region, Character, 100)
        return #parts > 0 and parts[1].Position or nil
    end
end

-- ### Módulo de reprodução
local Playback = {}
function Playback:ExecuteActions(actions)
    for i, action in ipairs(actions) do
        local targetPosition = action.position
        Humanoid:MoveTo(targetPosition)
        local tween = TweenService:Create(RootPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = action.cframe})
        tween:Play()
        if action.jumping then
            Humanoid.Jump = true
        end
        wait(math.random(0.05, 0.15))
    end
end

-- ### Configuração principal
local frame, screenGui = GUI:CreateWindow()

-- Botão Gravar
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(0, 100, 0, 50)
RecordButton.Position = UDim2.new(0, 10, 0, 40)
RecordButton.Text = "Record"
RecordButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.Font = Enum.Font.SourceSans
RecordButton.TextSize = 18
RecordButton.Parent = frame
RecordButton.MouseButton1Click:Connect(function()
    if recording then
        Recording:Stop()
        RecordButton.Text = "Record"
    else
        spawn(Recording.Start)
        RecordButton.Text = "Stop"
    end
end)

-- Botão Executar
local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Size = UDim2.new(0, 100, 0, 50)
ExecuteButton.Position = UDim2.new(0, 120, 0, 40)
ExecuteButton.Text = "Execute"
ExecuteButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.Font = Enum.Font.SourceSans
ExecuteButton.TextSize = 18
ExecuteButton.Parent = frame
ExecuteButton.MouseButton1Click:Connect(function()
    Playback:ExecuteActions(recordedActions)
end)
