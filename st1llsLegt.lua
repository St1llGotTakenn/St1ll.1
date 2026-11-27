local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "St1lls Dzielnica script",
   Icon = 0, 
   LoadingTitle = "dz",
   LoadingSubtitle = "by St1ll",
   ShowText = "st1ll", 
   Theme = "Serenity", 
   ToggleUIKeybind = "K", 
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, 
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, 
      FileName = "St1llConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink", 
      RememberJoins = true 
   },
   KeySystem = false, 
})

-- ============ DEĞİŞKENLER & SERVİSLER ============
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Renk ve Ayarlar
local ESPColor = Color3.fromHSV(0, 1, 1) 
local FriendESPColor = Color3.fromRGB(255, 255, 0) -- Arkadaşlar için varsayılan SARI
local hue = 0
local ChromaActive = false 

-- Player ESP
local PLAYER_HL = "PlayerESP"
local NAME_TAG = "ESPNameTag"
local playerESPActive = false
local trackedPlayers = {}

-- Chest ESP
local chestESPActive = false
local CHEST_HL = "ChestHighlight"
local chestList = {}

-- Medical ESP
local medESPActive = false
local MED_HL = "MedicalBoxESP"
local medList = {}

-- Hands
local handsActive = false
local STRIPES = 8
local leftHand, rightHand, leftParts, rightParts

-- Crosshair
local crosshairActive = false
local crosshairGui = nil
local crosshairInnerDot = nil

local map = workspace:WaitForChild("map")
local chests = map:WaitForChild("map_interact"):WaitForChild("chests")

-- ============ FONKSİYONLAR (PLAYER ESP) ============
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
Players.PlayerRemoving:Connect(function(plr) removePlayerESP(plr, plr.Character) end)

-- ============ FONKSİYONLAR (CHEST ESP) ============
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

-- ============ FONKSİYONLAR (MEDICAL ESP) ============
local function addMedESP()
	medList = {}
	for _, klasor in ipairs(chests:GetChildren()) do
		if klasor.Name == "Medical Box" and not klasor:FindFirstChild(MED_HL) then
			local target
			for _, obj in ipairs(klasor:GetDescendants()) do
				if obj:IsA("BasePart") then target = obj; break end
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
	for _, klasor in ipairs(chests:GetChildren()) do
		local h = klasor:FindFirstChild(MED_HL)
		if h then h:Destroy() end
	end
end

-- ============ FONKSİYONLAR (HANDS) ============
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
	leftHand, rightHand, leftParts, rightParts = nil, nil, nil, nil
end

local function getArm(vm, side)
	if not vm then return nil end
	local names = side == "Left" and {"Left Arm", "LeftArm", "left arm", "leftarm"} or {"Right Arm", "RightArm", "right arm", "rightarm"}
	for _, n in ipairs(names) do
		local p = vm:FindFirstChild(n, true)
		if p and p:IsA("BasePart") then return p end
	end
	return nil
end

-- Ölünce Chroma Hands'i sıfırlama sistemi
LocalPlayer.CharacterAdded:Connect(function()
    if handsActive then
        task.wait(0.5)
        stopHands()
        startHands()
    end
end)

-- ============ RENDER DÖNGÜSÜ ============
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc = acc + dt
	if acc < 0.03 then return end -- 30 FPS
	acc = 0

	-- Rengi belirle
	if ChromaActive then
		hue = (hue + 0.01) % 1
		ESPColor = Color3.fromHSV(hue, 1, 1)
	end

	-- Player ESP Renk Güncelle (Roblox API Arkadaş Kontrolü)
	if playerESPActive then
		for plr, entry in pairs(trackedPlayers) do
            local isFriend = false
            -- pcall ile koruyoruz (bazen API geç yanıt verebilir, hata vermesin)
            pcall(function()
                isFriend = LocalPlayer:IsFriendsWith(plr.UserId)
            end)

            local colorToUse = isFriend and FriendESPColor or ESPColor

			if entry.hl and entry.hl.Parent then
				entry.hl.FillColor = colorToUse
				entry.hl.OutlineColor = colorToUse
			end
			if entry.tagText and entry.tagText.Parent then
				entry.tagText.TextColor3 = colorToUse
			end
		end
	end

	if chestESPActive then
		for _, h in ipairs(chestList) do
			if h and h.Parent then h.FillColor = ESPColor; h.OutlineColor = ESPColor end
		end
	end
	if medESPActive then
		for _, h in ipairs(medList) do
			if h and h.Parent then h.FillColor = ESPColor; h.OutlineColor = ESPColor end
		end
	end

    -- Crosshair Renk Güncellemesi
    if crosshairActive and crosshairInnerDot and crosshairInnerDot.Parent then
        crosshairInnerDot.BackgroundColor3 = ESPColor
    end
end)

RunService:BindToRenderStep("ChromaHandsUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not handsActive or not leftHand or not rightHand then return end
	local vm = findViewmodel()
	if not vm then return end
	setHandsTransparency(vm, 1)
	
	local la = getArm(vm, "Left")
	if la then updateHand(leftParts, la.CFrame, la.Size, ESPColor) end
	local ra = getArm(vm, "Right")
	if ra then updateHand(rightParts, ra.CFrame, ra.Size, ESPColor) end
end)

-- ============ RAYFIELD MENÜ EKLENTİLERİ ============
local VisualTab = Window:CreateTab("Visual", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- 1. Visual Sekmesi
VisualTab:CreateToggle({
   Name = "Player ESP",
   CurrentValue = false,
   Flag = "PlayerESP_Toggle",
   Callback = function(state)
       playerESPActive = state
       if state then
           for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer and plr.Character then addPlayerESP(plr, plr.Character) end
           end
       else
           for plr, _ in pairs(trackedPlayers) do removePlayerESP(plr, plr.Character) end
       end
   end,
})

VisualTab:CreateToggle({
   Name = "Chest ESP",
   CurrentValue = false,
   Flag = "ChestESP_Toggle",
   Callback = function(state)
       chestESPActive = state
       if state then addChestESP() else removeChestESP() end
   end,
})

VisualTab:CreateToggle({
   Name = "Medical Box ESP",
   CurrentValue = false,
   Flag = "MedESP_Toggle",
   Callback = function(state)
       medESPActive = state
       if state then addMedESP() else removeMedESP() end
   end,
})

VisualTab:CreateToggle({
   Name = "Chroma Hands",
   CurrentValue = false,
   Flag = "Hands_Toggle",
   Callback = function(state)
       handsActive = state
       if state then startHands() else stopHands() end
   end,
})

VisualTab:CreateToggle({
   Name = "Chroma Crosshair",
   CurrentValue = false,
   Flag = "Crosshair_Toggle",
   Callback = function(Value)
       crosshairActive = Value
       local playerGui = LocalPlayer:WaitForChild("PlayerGui")
       
       if not Value then
           local existing = playerGui:FindFirstChild("ChromaCrosshair")
           if existing then existing:Destroy() end
           crosshairGui = nil
           crosshairInnerDot = nil
           return
       end
       
       crosshairGui = Instance.new("ScreenGui")
       crosshairGui.Name = "ChromaCrosshair"
       crosshairGui.ResetOnSpawn = false
       crosshairGui.IgnoreGuiInset = true
       crosshairGui.Parent = playerGui

       local outerDot = Instance.new("Frame")
       outerDot.Size = UDim2.new(0, 10, 0, 10)
       outerDot.Position = UDim2.new(0.5, -5, 0.5, -5)
       outerDot.BackgroundColor3 = Color3.new(0, 0, 0)
       outerDot.BackgroundTransparency = 0.3
       outerDot.BorderSizePixel = 0
       outerDot.Parent = crosshairGui
       
       local outerCorner = Instance.new("UICorner")
       outerCorner.CornerRadius = UDim.new(1, 0)
       outerCorner.Parent = outerDot

       crosshairInnerDot = Instance.new("Frame")
       crosshairInnerDot.Name = "InnerDot"
       crosshairInnerDot.Size = UDim2.new(0, 6, 0, 6)
       crosshairInnerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
       crosshairInnerDot.BackgroundColor3 = ESPColor
       crosshairInnerDot.BorderSizePixel = 0
       crosshairInnerDot.Parent = outerDot
       
       local innerCorner = Instance.new("UICorner")
       innerCorner.CornerRadius = UDim.new(1, 0)
       innerCorner.Parent = crosshairInnerDot
   end,
})

VisualTab:CreateToggle({
   Name = "Motion Blur",
   CurrentValue = false,
   Flag = "MotionBlur_Toggle",
   Callback = function(Value)
       local cam = workspace.CurrentCamera
       local blur = cam:FindFirstChild("DynamicMotionBlur")
       if not Value then
           if blur then blur:Destroy() end
           if _G.MotionBlurConn then _G.MotionBlurConn:Disconnect(); _G.MotionBlurConn = nil end
           return
       end
       if not blur then
           blur = Instance.new("BlurEffect")
           blur.Name = "DynamicMotionBlur"
           blur.Size = 0
           blur.Parent = cam
       end
       local lastLook = cam.CFrame.LookVector
       _G.MotionBlurConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
           if not blur or not blur.Parent then return end
           local currentLook = cam.CFrame.LookVector
           local lookDiff = (currentLook - lastLook).Magnitude
           local targetSize = lookDiff * 350
           if targetSize > 45 then targetSize = 45 end 
           blur.Size = blur.Size + (targetSize - blur.Size) * math.min(dt * 20, 1)
           lastLook = currentLook
       end)
   end,
})

-- 2. Settings Sekmesi
SettingsTab:CreateToggle({
    Name = "Chroma Modu (Gökkuşağı)",
    CurrentValue = false,
    Flag = "Chroma_Mod_Toggle",
    Callback = function(state) ChromaActive = state end,
})

SettingsTab:CreateColorPicker({
   Name = "Arkadaş ESP Rengi",
   Color = FriendESPColor,
   Flag = "Friend_ColorPicker",
   Callback = function(color) FriendESPColor = color end,
})

SettingsTab:CreateColorPicker({
   Name = "Sabit ESP Rengi",
   Color = ESPColor,
   Flag = "ESP_ColorPicker",
   Callback = function(color)
       if not ChromaActive then ESPColor = color end
   end,
})

-- FOV Slider
local TargetFOV = 70
SettingsTab:CreateSlider({
   Name = "Kamera FOV",
   Range = {70, 120},
   Increment = 1,
   Suffix = " FOV",
   CurrentValue = 70,
   Flag = "FOV_Slider",
   Callback = function(Value) 
       TargetFOV = Value 
       if workspace.CurrentCamera then
           workspace.CurrentCamera.FieldOfView = TargetFOV
       end
   end,
})

-- Bağımsız FOV Zorlama Döngüsü
game:GetService("RunService").RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView ~= TargetFOV then
        cam.FieldOfView = TargetFOV
    end
end)

local FullbrightToggle = VisualTab:CreateToggle({
   Name = "Fullbright (Gece Görüşü)",
   CurrentValue = false,
   Flag = "Fullbright_Toggle",
   Callback = function(Value)
       local Lighting = game:GetService("Lighting")
       
       if Value then
           -- AÇILDIĞINDA: Etrafı aydınlat ve gölgeleri yok et
           -- Mevcut ayarları kaydet (Kapatınca geri dönmek için)
           _G.OldBrightness = Lighting.Brightness
           _G.OldAmbient = Lighting.Ambient
           _G.OldOutdoorAmbient = Lighting.OutdoorAmbient
           _G.OldGlobalShadows = Lighting.GlobalShadows
           
           Lighting.Brightness = 3 -- Işık şiddeti (Max 3'tür)
           Lighting.Ambient = Color3.fromRGB(200, 200, 200) -- Her yeri eşit aydınlat
           Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
           Lighting.GlobalShadows = false -- Gölgeleri kapat (Fullbright için önemli)
           Lighting.EnvironmentDiffuseScale = 1
           Lighting.EnvironmentSpecularScale = 1
       else
           -- KAPATILDIĞINDA: Eski ayarlara geri dön
           if _G.OldBrightness then Lighting.Brightness = _G.OldBrightness end
           if _G.OldAmbient then Lighting.Ambient = _G.OldAmbient end
           if _G.OldOutdoorAmbient then Lighting.OutdoorAmbient = _G.OldOutdoorAmbient end
           if _G.OldGlobalShadows ~= nil then Lighting.GlobalShadows = _G.OldGlobalShadows end
           Lighting.EnvironmentDiffuseScale = 0
           Lighting.EnvironmentSpecularScale = 0
       end
   end,
})
