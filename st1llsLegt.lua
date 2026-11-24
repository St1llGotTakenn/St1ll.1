local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer:WaitForChild("PlayerGui")

-- ============ UI ============
local sg = Instance.new("ScreenGui")
sg.Name = "ESP_UI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 210, 0, 110)
frame.Position = UDim2.new(0, 8, 0, 45)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local function makeLbl(y, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -12, 0, 25)
	l.Position = UDim2.new(0, 8, 0, y)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextSize = 14
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = frame
	return l
end

local playerLbl = makeLbl(5, "[P] Player ESP: KAPALI")
local chestLbl  = makeLbl(30, "[X] Chest ESP: KAPALI")
local handsLbl  = makeLbl(55, "[G] Chroma Hands: KAPALI")
local medLbl    = makeLbl(80, "[M] Medical Box ESP: KAPALI")

-- ============ CHROMA ============
local hue = 0

-- ============ PLAYER ESP ============
local PLAYER_HL = "PlayerESP"
local NAME_TAG = "ESPNameTag"
local playerESPActive = false
local trackedPlayers = {}

local function addPlayerESP(plr, char)
	if not char or not plr then return end
	local entry = trackedPlayers[plr] or {}

	if not char:FindFirstChild(PLAYER_HL) then
		local h = Instance.new("Highlight")
		h.Name = PLAYER_HL
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Adornee = char
		h.Parent = char
		entry.hl = h
	end

	local head = char:FindFirstChild("Head")
	if head then
		local existing = head:FindFirstChild(NAME_TAG)
		if not existing then
			local bb = Instance.new("BillboardGui")
			bb.Name = NAME_TAG
			bb.Size = UDim2.new(0, 200, 0, 30)
			bb.StudsOffset = Vector3.new(0, 2.5, 0)
			bb.AlwaysOnTop = true
			bb.Parent = head
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Text = plr.Name
			txt.TextSize = 16
			txt.Font = Enum.Font.GothamBold
			txt.TextStrokeTransparency = 0.3
			txt.TextStrokeColor3 = Color3.new(0, 0, 0)
			txt.TextColor3 = Color3.new(1, 1, 1)
			txt.Parent = bb
			entry.tagText = txt
		else
			entry.tagText = existing:FindFirstChildOfClass("TextLabel")
		end
	end

	trackedPlayers[plr] = entry
end

local function removePlayerESP(plr, char)
	if char then
		local h = char:FindFirstChild(PLAYER_HL)
		if h then h:Destroy() end
		local head = char:FindFirstChild("Head")
		if head then
			local tag = head:FindFirstChild(NAME_TAG)
			if tag then tag:Destroy() end
		end
	end
	trackedPlayers[plr] = nil
end

local function hookPlayer(plr)
	if plr == LocalPlayer then return end
	local function onChar(char)
		if playerESPActive then addPlayerESP(plr, char) end
	end
	if plr.Character then onChar(plr.Character) end
	plr.CharacterAdded:Connect(onChar)
end

for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(plr)
	removePlayerESP(plr, plr.Character)
end)

-- ============ CHEST ESP ============
local CHEST_HL = "ChestHighlight"
local chestESPActive = false
local chestList = {}

local map = workspace:WaitForChild("map")
local chests = map:WaitForChild("map_interact"):WaitForChild("chests")

local function addChestESP()
	chestList = {}
	for _, chest in ipairs(chests:GetChildren()) do
		local top = chest:FindFirstChild("top", true)
		if top and top:IsA("MeshPart") and not chest:FindFirstChild(CHEST_HL) then
			local h = Instance.new("Highlight")
			h.Name = CHEST_HL
			h.FillTransparency = 0.5
			h.OutlineTransparency = 0
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Adornee = chest
			h.Parent = chest
			table.insert(chestList, h)
		end
	end
end

local function removeChestESP()
	for _, h in ipairs(chestList) do
		if h and h.Parent then h:Destroy() end
	end
	chestList = {}
end

-- ============ MEDICAL BOX ESP (klasör başına TEK highlight) ============
local MED_HL = "MedicalBoxESP"
local medESPActive = false
local medList = {}

local function addMedESP()
	medList = {}
	for _, klasor in ipairs(chests:GetChildren()) do
		if klasor.Name == "Medical Box" and not klasor:FindFirstChild(MED_HL) then
			-- Klasörün içindeki ilk BasePart'ı adornee olarak kullan
			local target
			for _, obj in ipairs(klasor:GetDescendants()) do
				if obj:IsA("BasePart") then
					target = obj
					break
				end
			end
			if target then
				local h = Instance.new("Highlight")
				h.Name = MED_HL
				h.FillTransparency = 0.5
				h.OutlineTransparency = 0
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Adornee = target
				h.Parent = klasor
				table.insert(medList, h)
			end
		end
	end
end

local function removeMedESP()
	for _, h in ipairs(medList) do
		if h and h.Parent then h:Destroy() end
	end
	medList = {}
	-- Klasörlerde kalan varsa temizle
	for _, klasor in ipairs(chests:GetChildren()) do
		local h = klasor:FindFirstChild(MED_HL)
		if h then h:Destroy() end
	end
end

-- ============ CHROMA HANDS ============
local STRIPES = 8
local handsActive = false
local leftHand, rightHand
local leftParts, rightParts

local function findViewmodel()
	local cam = workspace.CurrentCamera
	if cam then
		local vm = cam:FindFirstChild("viewmodel")
		if vm then return vm end
	end
	return workspace:FindFirstChild("viewmodel")
end

local function setHandsTransparency(vm, t)
	for _, name in ipairs({"Left Arm", "Right Arm", "leftarmbloodpart", "rightarmbloodpart", "LeftArm", "RightArm"}) do
		local p = vm:FindFirstChild(name, true)
		if p then p.LocalTransparencyModifier = t end
	end
end

local function makeHand(name)
	local model = Instance.new("Model")
	model.Name = name
	local parts = {}
	for i = 1, STRIPES do
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe" .. i
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.CastShadow = false
		stripe.Material = Enum.Material.Neon
		stripe.Transparency = 0
		stripe.Size = Vector3.new(1, 1, 1)
		stripe.Parent = model
		parts[i] = stripe
	end
	return model, parts
end

local function updateHand(parts, cf, size, color)
	local stripeHeight = size.Y / STRIPES
	for i = 1, STRIPES do
		local s = parts[i]
		local offsetY = -size.Y/2 + (i - 0.5) * stripeHeight
		s.Size = Vector3.new(size.X * 1.01, stripeHeight * 0.5, size.Z * 1.01)
		s.CFrame = cf * CFrame.new(0, offsetY, 0)
		s.Color = color
	end
end

local function startHands()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local old = cam:FindFirstChild("ChromaHands")
	if old then old:Destroy() end

	local chroma = Instance.new("Model")
	chroma.Name = "ChromaHands"
	chroma.Parent = cam

	leftHand, leftParts = makeHand("LeftChroma")
	leftHand.Parent = chroma
	rightHand, rightParts = makeHand("RightChroma")
	rightHand.Parent = chroma
end

local function stopHands()
	local cam = workspace.CurrentCamera
	if cam then
		local chroma = cam:FindFirstChild("ChromaHands")
		if chroma then chroma:Destroy() end
	end
	local vm = findViewmodel()
	if vm then setHandsTransparency(vm, 0) end
	leftHand = nil
	rightHand = nil
	leftParts = nil
	rightParts = nil
end

local function getArm(vm, side)
	if not vm then return nil end
	local names
	if side == "Left" then
		names = {"Left Arm", "LeftArm", "left arm", "leftarm"}
	else
		names = {"Right Arm", "RightArm", "right arm", "rightarm"}
	end
	for _, n in ipairs(names) do
		local p = vm:FindFirstChild(n, true)
		if p and p:IsA("BasePart") then return p end
	end
	return nil
end

-- ============ CHROMA DÖNGÜSÜ (ESP renkleri, 20 FPS) ============
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc = acc + dt
	if acc < 0.05 then return end
	acc = 0

	hue = (hue + 0.015) % 1
	local color = Color3.fromHSV(hue, 1, 1)

	if playerESPActive then
		for plr, entry in pairs(trackedPlayers) do
			if entry.hl and entry.hl.Parent then
				entry.hl.FillColor = color
				entry.hl.OutlineColor = color
			end
			if entry.tagText and entry.tagText.Parent then
				entry.tagText.TextColor3 = color
			end
		end
	end

	if chestESPActive then
		for _, h in ipairs(chestList) do
			if h and h.Parent then
				h.FillColor = color
				h.OutlineColor = color
			end
		end
	end

	if medESPActive then
		for _, h in ipairs(medList) do
			if h and h.Parent then
				h.FillColor = color
				h.OutlineColor = color
			end
		end
	end
end)

-- ============ HANDS AYRI DÖNGÜ (her frame, titremesiz) ============
RunService:BindToRenderStep("ChromaHandsUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not handsActive or not leftHand or not rightHand then return end

	local vm = findViewmodel()
	if not vm then return end

	setHandsTransparency(vm, 1)

	local color = Color3.fromHSV(hue, 1, 1)
	local la = getArm(vm, "Left")
	if la then updateHand(leftParts, la.CFrame, la.Size, color) end
	local ra = getArm(vm, "Right")
	if ra then updateHand(rightParts, ra.CFrame, ra.Size, color) end
end)

-- ============ TUŞLAR ============
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.P then
		playerESPActive = not playerESPActive
		if playerESPActive then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character then addPlayerESP(plr, plr.Character) end
			end
		else
			for plr, _ in pairs(trackedPlayers) do
				removePlayerESP(plr, plr.Character)
			end
		end
		playerLbl.Text = "[P] Player ESP: " .. (playerESPActive and "AÇIK" or "KAPALI")
		playerLbl.TextColor3 = playerESPActive and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
	elseif input.KeyCode == Enum.KeyCode.X then
		chestESPActive = not chestESPActive
		if chestESPActive then addChestESP() else removeChestESP() end
		chestLbl.Text = "[X] Chest ESP: " .. (chestESPActive and "AÇIK" or "KAPALI")
		chestLbl.TextColor3 = chestESPActive and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
	elseif input.KeyCode == Enum.KeyCode.G then
		handsActive = not handsActive
		if handsActive then startHands() else stopHands() end
		handsLbl.Text = "[G] Chroma Hands: " .. (handsActive and "AÇIK" or "KAPALI")
		handsLbl.TextColor3 = handsActive and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
	elseif input.KeyCode == Enum.KeyCode.M then
		medESPActive = not medESPActive
		if medESPActive then addMedESP() else removeMedESP() end
		medLbl.Text = "[M] Medical Box ESP: " .. (medESPActive and "AÇIK" or "KAPALI")
		medLbl.TextColor3 = medESPActive and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
	end
end)
