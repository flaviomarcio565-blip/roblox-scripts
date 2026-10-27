--!strict
-- Universal Roblox Security Testing Framework (Single-File Version for Brookhaven)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

-- Configurações Globais
local Config = {
	ESP = {
		Enabled = true,
		ChamsEnabled = true,
		Color = Color3.fromRGB(0, 255, 128),
		Transparency = 0.4,
	},
	Movement = {
		SpeedEnabled = true,
		WalkSpeed = 32, -- Velocidade de movimento ajustável
	}
}

-- 1. Interface Gráfica (GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SecurityTestingFrameworkGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function()
	screenGui.Parent = CoreGui
end)
if not success then
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
end

-- Botão Flutuante
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "TogglePanelButton"
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0, 20, 0, 20)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
toggleBtn.TextColor3 = Color3.fromRGB(0, 162, 255)
toggleBtn.Text = "🛡️"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleBtn

-- Janela Principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Barra de Título Arrastável
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
titleBar.Text = "  Brookhaven Testing Framework"
titleBar.TextColor3 = Color3.fromRGB(240, 240, 240)
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Lógica de Arrastar Janela
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	mainFrame.Visible = isOpen
end)

-- 2. Sistema ESP (Apenas Nickname + Distância + Chams)
local espCache = {}

local function removeESP(character: Model)
	if espCache[character] then
		if espCache[character].Highlight then espCache[character].Highlight:Destroy() end
		if espCache[character].Billboard then espCache[character].Billboard:Destroy() end
		espCache[character] = nil
	end
end

RunService.RenderStepped:Connect(function()
	if not Config.ESP.Enabled then
		for char, _ in pairs(espCache) do removeESP(char) end
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart") :: Part
			
			if hrp then
				local entry = espCache[char]
				if not entry then
					entry = {}
					
					-- Chams / Destaque Visual
					if Config.ESP.ChamsEnabled then
						local hl = Instance.new("Highlight")
						hl.FillColor = Config.ESP.Color
						hl.FillTransparency = Config.ESP.Transparency
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.OutlineTransparency = 0.2
						hl.Adornee = char
						hl.Parent = char
						entry.Highlight = hl
					end

					-- BillboardGui para Nome e Distância
					local bg = Instance.new("BillboardGui")
					bg.Size = UDim2.new(0, 200, 0, 50)
					bg.StudsOffset = Vector3.new(0, 3.5, 0)
					bg.AlwaysOnTop = true
					
					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextColor3 = Config.ESP.Color
					textLabel.TextScaled = true
					textLabel.Font = Enum.Font.GothamBold
					textLabel.Parent = bg
					
					bg.Parent = hrp
					entry.Billboard = bg
					
					espCache[char] = entry
				end

				-- Atualização em tempo real da distância
				if entry.Billboard then
					local label = entry.Billboard:FindFirstChildOfClass("TextLabel")
					local myChar = localPlayer.Character
					if label and myChar and myChar:FindFirstChild("HumanoidRootPart") then
						local myHrp = myChar.HumanoidRootPart :: Part
						local dist = (hrp.Position - myHrp.Position).Magnitude
						label.Text = string.format("%s\n[%d m]", player.DisplayName, math.round(dist))
					end
				end
			else
				removeESP(char)
			end
		end
	end
end)

-- Limpeza automática ao remover personagens
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		removeESP(player.Character)
	end
end)

-- 3. Sistema de Velocidade (MovementController)
RunService.Heartbeat:Connect(function()
	if localPlayer.Character then
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if Config.Movement.SpeedEnabled then
				humanoid.WalkSpeed = Config.Movement.WalkSpeed
			end
		end
	end
end)

print("[Framework] Carregado com sucesso no executor!")
