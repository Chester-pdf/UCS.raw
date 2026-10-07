print("[ACE extras] загрузка...")
local ACE = _G.ACE
if not ACE then warn("[ACE extras] _G.ACE пуст — ACE не загружен"); return end
local S = ACE
local C = S.C
local addR = S.addR
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TeleSvc = game:GetService("TeleportService")
local Http = game:GetService("HttpService")
local SG = S.SG

C.itemEsp = C.itemEsp or false
C.freecam = C.freecam or false
C.freecamSpeed = C.freecamSpeed or 50
C.favKeys = C.favKeys or ""

-- ===== ITEM ESP =====
local itemHl = {}
local ITEM_NAMES = {"drop","item","pickup","loot","resource","coin","gem","gold","wood","scrap","candy","ore","chest","crate","food","potion","ingot","bar"}
local function isItemObj(o)
	if not o or not o.Parent then return false end
	if o:IsA("Tool") then return true end
	if o:IsA("Model") or o:IsA("BasePart") then
		local n = string.lower(o.Name)
		for _,p in ipairs(ITEM_NAMES) do
			if string.find(n,p,1,true) then return true end
		end
	end
	return false
end
local function addItemHL(o)
	if itemHl[o] then return end
	local hl = Instance.new("Highlight",o)
	hl.Name = "ACE_ITEM_HL"
	hl.FillColor = Color3.fromRGB(255,200,0)
	hl.FillTransparency = 0.5
	hl.OutlineColor = Color3.fromRGB(255,255,100)
	itemHl[o] = hl
end
local function clearItems()
	for o,hl in pairs(itemHl) do pcall(function() hl:Destroy() end) end
	itemHl = {}
end
local function scanItems()
	for _,o in ipairs(workspace:GetDescendants()) do
		if isItemObj(o) then addItemHL(o) end
	end
end

addR("Visual","Item ESP",function(b)
	C.itemEsp = not C.itemEsp
	if C.itemEsp then
		b.BackgroundColor3 = Color3.fromRGB(0,120,0)
		b.Text = "Item ESP: ВКЛ"
		scanItems()
		S.addT("ItemEspSync",function()
			for _,o in ipairs(workspace:GetDescendants()) do
				if isItemObj(o) and not itemHl[o] then addItemHL(o) end
			end
			for o,hl in pairs(itemHl) do
				if not o.Parent then pcall(function() hl:Destroy() end); itemHl[o]=nil end
			end
		end,0.5)
	else
		b.BackgroundColor3 = Color3.fromRGB(50,50,50)
		b.Text = "Item ESP: ВЫКЛ"
		S.delT("ItemEspSync")
		clearItems()
	end
end,false,"itemEsp")

-- ===== FREECAM =====
local fcConns = {}
local fcData = nil
local function startFreecam()
	local cam = workspace.CurrentCamera
	local cf = cam.CFrame
	fcData = {
		cam = cam,
		pos = cf.Position,
		yaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z),
		pitch = math.asin(math.clamp(cf.LookVector.Y,-1,1)),
		fwd=0,back=0,left=0,right=0,up=0,down=0
	}
	UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	local ch = LP.Character
	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = nil end
	end
	fcConns[1] = UIS.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then
			fcData.yaw = fcData.yaw - math.rad(i.Delta.X)*0.3
			fcData.pitch = math.clamp(fcData.pitch - math.rad(i.Delta.Y)*0.3, -math.pi/2+0.01, math.pi/2-0.01)
		end
	end)
	fcConns[2] = UIS.InputBegan:Connect(function(i,gp)
		if gp then return end
		if i.KeyCode==Enum.KeyCode.W then fcData.fwd=1
		elseif i.KeyCode==Enum.KeyCode.S then fcData.back=1
		elseif i.KeyCode==Enum.KeyCode.A then fcData.left=1
		elseif i.KeyCode==Enum.KeyCode.D then fcData.right=1
		elseif i.KeyCode==Enum.KeyCode.Space then fcData.up=1
		elseif i.KeyCode==Enum.KeyCode.LeftControl then fcData.down=1
		end
	end)
	fcConns[3] = UIS.InputEnded:Connect(function(i)
		if i.KeyCode==Enum.KeyCode.W then fcData.fwd=0
		elseif i.KeyCode==Enum.KeyCode.S then fcData.back=0
		elseif i.KeyCode==Enum.KeyCode.A then fcData.left=0
		elseif i.KeyCode==Enum.KeyCode.D then fcData.right=0
		elseif i.KeyCode==Enum.KeyCode.Space then fcData.up=0
		elseif i.KeyCode==Enum.KeyCode.LeftControl then fcData.down=0
		end
	end)
	fcConns[4] = RS.RenderStepped:Connect(function(dt)
		if not fcData then return end
		local spd = C.freecamSpeed * dt * 10
		local look = CFrame.fromEulerAnglesYXZ(fcData.pitch, fcData.yaw, 0)
		local mv = Vector3.zero
		mv = mv + look.LookVector * (fcData.fwd - fcData.back) * spd
		mv = mv + look.RightVector * (fcData.right - fcData.left) * spd
		mv = mv + Vector3.new(0,1,0) * (fcData.up - fcData.down) * spd
		fcData.pos = fcData.pos + mv
		cam.CFrame = CFrame.new(fcData.pos) * look
	end)
end
local function stopFreecam()
	for _,c in ipairs(fcConns) do pcall(function() c:Disconnect() end) end
	fcConns = {}
	fcData = nil
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	local ch = LP.Character
	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then workspace.CurrentCamera.CameraSubject = hum end
	end
end
S._startFreecam = startFreecam
S._stopFreecam = stopFreecam

addR("Visual","Freecam",function(b)
	C.freecam = not C.freecam
	if C.freecam then
		b.BackgroundColor3 = Color3.fromRGB(0,120,0)
		b.Text = "Freecam: ВКЛ"
		startFreecam()
	else
		b.BackgroundColor3 = Color3.fromRGB(50,50,50)
		b.Text = "Freecam: ВЫКЛ"
		stopFreecam()
	end
end,false,"freecam")

-- ===== PLAYER INFO PANEL =====
local infoPanel = Instance.new("Frame", SG)
infoPanel.Size = UDim2.new(0,240,0,180)
infoPanel.Position = UDim2.new(0.5,-120,0.5,-90)
infoPanel.BackgroundColor3 = Color3.fromRGB(22,22,28)
infoPanel.BorderSizePixel = 0
infoPanel.Visible = false
infoPanel.ZIndex = 100
Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0,8)
local ipStroke = Instance.new("UIStroke", infoPanel)
ipStroke.Color = Color3.fromRGB(120,180,255); ipStroke.Thickness = 1.5

local ipTitle = Instance.new("TextLabel", infoPanel)
ipTitle.Size = UDim2.new(1,0,0,28)
ipTitle.BackgroundColor3 = Color3.fromRGB(42,42,42)
ipTitle.BorderSizePixel = 0
ipTitle.Text = "Инфо игрока"
ipTitle.TextColor3 = Color3.fromRGB(120,180,255)
ipTitle.Font = Enum.Font.SourceSansBold; ipTitle.TextSize = 12
Instance.new("UICorner", ipTitle).CornerRadius = UDim.new(0,8)

local ipClose = Instance.new("TextButton", infoPanel)
ipClose.Size = UDim2.new(0,28,0,28); ipClose.Position = UDim2.new(1,-28,0,0)
ipClose.BackgroundTransparency = 1; ipClose.Text = "×"
ipClose.TextColor3 = Color3.new(1,1,1); ipClose.Font = Enum.Font.SourceSansBold; ipClose.TextSize = 16
ipClose.ZIndex = 101

local ipText = Instance.new("TextLabel", infoPanel)
ipText.Size = UDim2.new(1,-20,1,-40); ipText.Position = UDim2.new(0,10,0,34)
ipText.BackgroundTransparency = 1
ipText.Text = ""
ipText.TextColor3 = Color3.fromRGB(220,220,220)
ipText.Font = Enum.Font.Code; ipText.TextSize = 11
ipText.TextXAlignment = Enum.TextXAlignment.Left
ipText.TextYAlignment = Enum.TextYAlignment.Top
ipText.TextWrapped = true

ipClose.MouseButton1Click:Connect(function() infoPanel.Visible = false end)

local ipTarget = nil
local ipConn = nil
local function showInfo(p)
	ipTarget = p
	infoPanel.Visible = true
	if ipConn then ipConn:Disconnect() end
	ipConn = RS.Heartbeat:Connect(function()
		if not ipTarget or not infoPanel.Visible then return end
		local ch = ipTarget.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local myCh = LP.Character
		local myHrp = myCh and myCh:FindFirstChild("HumanoidRootPart")
		local dist = "?"
		if hrp and myHrp then dist = string.format("%.0f", (hrp.Position - myHrp.Position).Magnitude) end
		local tool = ch and ch:FindFirstChildOfClass("Tool")
		local lines = {
			"Имя: "..ipTarget.Name,
			"Ник: "..ipTarget.DisplayName,
			"UserID: "..ipTarget.UserId,
			"HP: "..(hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "?"),
			"Дист: "..dist.." studs",
			"Оружие: "..(tool and tool.Name or "—"),
			"Аккаунт: "..(ipTarget.AccountAge or "?").." дн.",
			"Команда: "..(ipTarget.Team and ipTarget.Team.Name or "нет"),
		}
		ipText.Text = table.concat(lines, "\n")
	end)
end
S._showPlayerInfo = showInfo

-- ===== GAME INFO DUMPER =====
local dumperPanel = Instance.new("Frame", SG)
dumperPanel.Size = UDim2.new(0,320,0,400)
dumperPanel.Position = UDim2.new(0.5,-160,0.5,-200)
dumperPanel.BackgroundColor3 = Color3.fromRGB(20,20,26)
dumperPanel.BorderSizePixel = 0
dumperPanel.Visible = false
dumperPanel.ZIndex = 100
Instance.new("UICorner", dumperPanel).CornerRadius = UDim.new(0,8)
local dpStroke = Instance.new("UIStroke", dumperPanel)
dpStroke.Color = Color3.fromRGB(100,220,180); dpStroke.Thickness = 1.5

local dpTitle = Instance.new("TextLabel", dumperPanel)
dpTitle.Size = UDim2.new(1,0,0,28)
dpTitle.BackgroundColor3 = Color3.fromRGB(42,42,42)
dpTitle.BorderSizePixel = 0
dpTitle.Text = "Game Info Dumper"
dpTitle.TextColor3 = Color3.fromRGB(100,220,180)
dpTitle.Font = Enum.Font.SourceSansBold; dpTitle.TextSize = 12
Instance.new("UICorner", dpTitle).CornerRadius = UDim.new(0,8)

local dpClose = Instance.new("TextButton", dumperPanel)
dpClose.Size = UDim2.new(0,28,0,28); dpClose.Position = UDim2.new(1,-28,0,0)
dpClose.BackgroundTransparency = 1; dpClose.Text = "×"
dpClose.TextColor3 = Color3.new(1,1,1); dpClose.Font = Enum.Font.SourceSansBold; dpClose.TextSize = 16
dpClose.ZIndex = 101

local dpCopy = Instance.new("TextButton", dumperPanel)
dpCopy.Size = UDim2.new(0,80,0,24); dpCopy.Position = UDim2.new(1,-90,0,32)
dpCopy.BackgroundColor3 = Color3.fromRGB(0,120,180); dpCopy.BorderSizePixel = 0
dpCopy.Text = "COPY"; dpCopy.TextColor3 = Color3.new(1,1,1)
dpCopy.Font = Enum.Font.SourceSansBold; dpCopy.TextSize = 10
Instance.new("UICorner", dpCopy).CornerRadius = UDim.new(0,4)

local dpRescan = Instance.new("TextButton", dumperPanel)
dpRescan.Size = UDim2.new(0,80,0,24); dpRescan.Position = UDim2.new(1,-180,0,32)
dpRescan.BackgroundColor3 = Color3.fromRGB(60,60,80); dpRescan.BorderSizePixel = 0
dpRescan.Text = "ReScan"; dpRescan.TextColor3 = Color3.new(1,1,1)
dpRescan.Font = Enum.Font.SourceSansBold; dpRescan.TextSize = 10
Instance.new("UICorner", dpRescan).CornerRadius = UDim.new(0,4)

local dpScroll = Instance.new("ScrollingFrame", dumperPanel)
dpScroll.Size = UDim2.new(1,-16,1,-70); dpScroll.Position = UDim2.new(0,8,0,62)
dpScroll.BackgroundColor3 = Color3.fromRGB(12,12,16); dpScroll.BorderSizePixel = 0
dpScroll.ScrollBarThickness = 4; dpScroll.ScrollBarImageColor3 = Color3.fromRGB(100,220,180)
dpScroll.CanvasSize = UDim2.new(0,0,0,0)
dpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", dpScroll).CornerRadius = UDim.new(0,4)

local dpText = Instance.new("TextLabel", dpScroll)
dpText.Size = UDim2.new(1,-8,0,0); dpText.Position = UDim2.new(0,4,0,4)
dpText.AutomaticSize = Enum.AutomaticSize.Y
dpText.BackgroundTransparency = 1
dpText.Text = ""
dpText.TextColor3 = Color3.fromRGB(200,200,200)
dpText.Font = Enum.Font.Code; dpText.TextSize = 10
dpText.TextXAlignment = Enum.TextXAlignment.Left
dpText.TextYAlignment = Enum.TextYAlignment.Top
dpText.TextWrapped = true

local function dumpGame()
	local lines = {}
	table.insert(lines, "=== GAME INFO ===")
	table.insert(lines, "Place: "..tostring(game.PlaceId))
	table.insert(lines, "JobId: "..tostring(game.JobId))
	table.insert(lines, "")
	local rstorage = game:GetService("ReplicatedStorage")
	local counts = {RemoteEvent=0, RemoteFunction=0, ModuleScript=0, Script=0, LocalScript=0}
	local remotes, modules = {}, {}
	for _,o in ipairs(rstorage:GetDescendants()) do
		if counts[o.ClassName] then counts[o.ClassName] = counts[o.ClassName] + 1 end
		if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
			table.insert(remotes, o:GetFullName())
		elseif o:IsA("ModuleScript") then
			table.insert(modules, o:GetFullName())
		end
	end
	table.insert(lines, "=== REPLICATEDSTORAGE ===")
	for k,v in pairs(counts) do table.insert(lines, k..": "..v) end
	table.insert(lines, "")
	table.insert(lines, "=== REMOTES ("..#remotes..") ===")
	for _,r in ipairs(remotes) do table.insert(lines, r) end
	table.insert(lines, "")
	table.insert(lines, "=== MODULES ("..#modules..") ===")
	for _,m in ipairs(modules) do table.insert(lines, m) end
	table.insert(lines, "")
	table.insert(lines, "=== PLAYERS ("..#Players:GetPlayers()..") ===")
	for _,p in ipairs(Players:GetPlayers()) do
		table.insert(lines, p.Name.." ["..p.UserId.."]")
	end
	local npcCount = 0
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("Humanoid") and not Players:GetPlayerFromCharacter(o.Parent) then
			npcCount = npcCount + 1
		end
	end
	table.insert(lines, "")
	table.insert(lines, "=== NPC: "..npcCount.." ===")
	return table.concat(lines, "\n")
end

local lastDump = nil
local function refreshDump()
	lastDump = dumpGame()
	dpText.Text = lastDump
end
dpRescan.MouseButton1Click:Connect(refreshDump)
dpCopy.MouseButton1Click:Connect(function()
	if not lastDump then refreshDump() end
	if setclipboard then
		pcall(function() setclipboard(lastDump) end)
		S.notify("Скопировано", Color3.fromRGB(0,180,0))
	else
		print("=== DUMP ===")
		print(lastDump)
	end
end)
dpClose.MouseButton1Click:Connect(function() dumperPanel.Visible = false end)

addR("Settings","📊 Game Info Dumper",function(b)
	if not dumperPanel.Visible then
		refreshDump()
		dumperPanel.Visible = true
	else
		dumperPanel.Visible = false
	end
end,false)

-- ===== FAVORITES + SEARCH =====
local function getFavs()
	local t = {}
	if C.favKeys == "" then return t end
	for k in string.gmatch(C.favKeys, "([^,]+)") do t[k] = true end
	return t
end
local function setFavs(t)
	local list = {}
	for k in pairs(t) do table.insert(list, k) end
	C.favKeys = table.concat(list, ",")
end
local function toggleFav(key)
	local f = getFavs()
	if f[key] then f[key] = nil else f[key] = true end
	setFavs(f)
end

local favPanel = Instance.new("Frame", SG)
favPanel.Size = UDim2.new(0, 280, 0, 400)
favPanel.Position = UDim2.new(0.5, -140, 0.5, -200)
favPanel.BackgroundColor3 = Color3.fromRGB(20,20,26)
favPanel.BorderSizePixel = 0
favPanel.Visible = false
favPanel.ZIndex = 100
Instance.new("UICorner", favPanel).CornerRadius = UDim.new(0,8)
local fpStroke = Instance.new("UIStroke", favPanel)
fpStroke.Color = Color3.fromRGB(255,200,80); fpStroke.Thickness = 1.5

local fpTitle = Instance.new("TextLabel", favPanel)
fpTitle.Size = UDim2.new(1,0,0,28)
fpTitle.BackgroundColor3 = Color3.fromRGB(42,42,42)
fpTitle.BorderSizePixel = 0
fpTitle.Text = "⭐ Избранное + Поиск"
fpTitle.TextColor3 = Color3.fromRGB(255,200,80)
fpTitle.Font = Enum.Font.SourceSansBold; fpTitle.TextSize = 12
Instance.new("UICorner", fpTitle).CornerRadius = UDim.new(0,8)

local fpClose = Instance.new("TextButton", favPanel)
fpClose.Size = UDim2.new(0,28,0,28); fpClose.Position = UDim2.new(1,-28,0,0)
fpClose.BackgroundTransparency = 1; fpClose.Text = "×"
fpClose.TextColor3 = Color3.new(1,1,1); fpClose.Font = Enum.Font.SourceSansBold; fpClose.TextSize = 16
fpClose.ZIndex = 101

local fpSearch = Instance.new("TextBox", favPanel)
fpSearch.Size = UDim2.new(1,-16,0,26); fpSearch.Position = UDim2.new(0,8,0,34)
fpSearch.BackgroundColor3 = Color3.fromRGB(40,40,50); fpSearch.BorderSizePixel = 0
fpSearch.PlaceholderText = "Поиск функции..."
fpSearch.Text = ""; fpSearch.TextColor3 = Color3.new(1,1,1)
fpSearch.PlaceholderColor3 = Color3.fromRGB(140,140,140)
fpSearch.Font = Enum.Font.SourceSans; fpSearch.TextSize = 11
fpSearch.ClearTextOnFocus = false
Instance.new("UICorner", fpSearch).CornerRadius = UDim.new(0,4)

local fpScroll = Instance.new("ScrollingFrame", favPanel)
fpScroll.Size = UDim2.new(1,-16,1,-70); fpScroll.Position = UDim2.new(0,8,0,66)
fpScroll.BackgroundColor3 = Color3.fromRGB(12,12,16); fpScroll.BorderSizePixel = 0
fpScroll.ScrollBarThickness = 4; fpScroll.ScrollBarImageColor3 = Color3.fromRGB(255,200,80)
fpScroll.CanvasSize = UDim2.new(0,0,0,0)
fpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", fpScroll).CornerRadius = UDim.new(0,4)
Instance.new("UIListLayout", fpScroll).Padding = UDim.new(0,3)

local function rebuildFavList()
	for _,c in ipairs(fpScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local f = getFavs()
	local q = string.lower(fpSearch.Text or "")
	for key, tog in pairs(S.toggles) do
		if tog and tog.btn then
			local txt = tog.btn.Text or key
			local show = f[key] or (q ~= "" and string.find(string.lower(txt), q, 1, true))
			if show then
				local row = Instance.new("Frame", fpScroll)
				row.Size = UDim2.new(1,-6,0,26)
				row.BackgroundColor3 = f[key] and Color3.fromRGB(60,50,20) or Color3.fromRGB(40,40,48)
				row.BorderSizePixel = 0
				Instance.new("UICorner", row).CornerRadius = UDim.new(0,3)
				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1,-60,1,0); lbl.Position = UDim2.new(0,6,0,0)
				lbl.BackgroundTransparency = 1
				lbl.Text = txt
				lbl.TextColor3 = Color3.fromRGB(220,220,220)
				lbl.Font = Enum.Font.SourceSansBold; lbl.TextSize = 10
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextTruncate = Enum.TextTruncate.AtEnd
				local star = Instance.new("TextButton", row)
				star.Size = UDim2.new(0,24,1,-4); star.Position = UDim2.new(1,-26,0,2)
				star.BackgroundColor3 = f[key] and Color3.fromRGB(180,140,20) or Color3.fromRGB(60,60,60)
				star.BorderSizePixel = 0
				star.Text = f[key] and "★" or "☆"
				star.TextColor3 = Color3.new(1,1,1)
				star.Font = Enum.Font.SourceSansBold; star.TextSize = 14
				Instance.new("UICorner", star).CornerRadius = UDim.new(0,3)
				star.MouseButton1Click:Connect(function()
					toggleFav(key); rebuildFavList()
				end)
				local run = Instance.new("TextButton", row)
				run.Size = UDim2.new(0,30,1,-4); run.Position = UDim2.new(1,-58,0,2)
				run.BackgroundColor3 = Color3.fromRGB(0,120,60)
				run.BorderSizePixel = 0
				run.Text = "▶"
				run.TextColor3 = Color3.new(1,1,1)
				run.Font = Enum.Font.SourceSansBold; run.TextSize = 12
				Instance.new("UICorner", run).CornerRadius = UDim.new(0,3)
				run.MouseButton1Click:Connect(function()
					pcall(function() tog.cb(tog.btn, "toggle") end)
				end)
			end
		end
	end
end
fpSearch:GetPropertyChangedSignal("Text"):Connect(rebuildFavList)
fpClose.MouseButton1Click:Connect(function() favPanel.Visible = false end)

addR("Settings","⭐ Избранное + Поиск",function(b)
	if not favPanel.Visible then
		rebuildFavList()
		favPanel.Visible = true
	else
		favPanel.Visible = false
	end
end,false)

-- ===== CLEANUP =====
S._extrasCleanup = function()
	S.delT("ItemEspSync")
	clearItems()
	stopFreecam()
	if ipConn then ipConn:Disconnect() end
	if dumperPanel then dumperPanel:Destroy() end
	if favPanel then favPanel:Destroy() end
	if infoPanel then infoPanel:Destroy() end
end

print("[ACE extras] готово — Item ESP, Freecam, Player Info, Dumper, Fav")
