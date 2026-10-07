print("[ACE extras] загрузка v3.2...")
local ACE = _G.ACE
if not ACE then warn("[ACE extras] _G.ACE пуст"); return end

if _G._ACE_ExtrasLoaded == ACE then
	warn("[ACE extras] уже загружен")
	return
end
_G._ACE_ExtrasLoaded = ACE

local S = ACE
local C = S.C
local addR = S.addR
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local SG = S.SG

C.itemEsp = C.itemEsp or false
C.freecam = C.freecam or false
C.freecamSpeed = C.freecamSpeed or 15
C.favKeys = C.favKeys or ""

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

-- ITEM ESP
if S.toggles.itemEsp then
	print("[ACE extras] Item ESP уже есть")
else
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
end

-- FREECAM
if S.toggles.freecam then
	print("[ACE extras] Freecam уже есть")
else
	local fcConns = {}
	local fcData = nil
	local freeButtons = {}
	local touchLook = nil

	local function hideHotkeysForFreecam()
		for _,e in ipairs(S.screenButtons) do
			if e.btn and e.btn.Parent then e.btn.Visible = false end
		end
		if S._customJumpBtn and S._customJumpBtn.Parent then S._customJumpBtn.Visible = false end
	end
	local function restoreHotkeys()
		S.refreshScreenButtons()
		if S._customJumpBtn and S._customJumpBtn.Parent then
			S._customJumpBtn.Visible = not S.C.stealthHidden
		end
	end
	local function showFreeButtons()
		for _,b in ipairs(freeButtons) do b.Visible = true end
	end
	local function hideFreeButtons()
		for _,b in ipairs(freeButtons) do b.Visible = false end
	end

	local function createFreeBtn(text, x, y, onDown, onUp)
		local btn = Instance.new("TextButton", SG)
		btn.Size = UDim2.new(0, 50, 0, 50)
		btn.Position = UDim2.new(0.5, x, 1, y)
		btn.BackgroundColor3 = Color3.fromRGB(40, 90, 130)
		btn.BackgroundTransparency = 0.2
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(180, 230, 255)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 20
		btn.AutoButtonColor = false
		btn.Visible = false
		btn.ZIndex = 60
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0.5, 0)
		local st = Instance.new("UIStroke", btn)
		st.Color = Color3.fromRGB(120, 200, 255); st.Thickness = 2
		btn.MouseButton1Down:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(70, 140, 190)
			if onDown then onDown() end
		end)
		btn.MouseButton1Up:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(40, 90, 130)
			if onUp then onUp() end
		end)
		table.insert(freeButtons, btn)
		return btn
	end

	-- Только движение и вертикаль
	createFreeBtn("W", -120, -170, function() if fcData then fcData.fwd=1 end end, function() if fcData then fcData.fwd=0 end end)
	createFreeBtn("A", -180, -110, function() if fcData then fcData.left=1 end end, function() if fcData then fcData.left=0 end end)
	createFreeBtn("S", -120, -110, function() if fcData then fcData.back=1 end end, function() if fcData then fcData.back=0 end end)
	createFreeBtn("D", -60, -110, function() if fcData then fcData.right=1 end end, function() if fcData then fcData.right=0 end end)
	createFreeBtn("↑", 60, -170, function() if fcData then fcData.up=1 end end, function() if fcData then fcData.up=0 end end)
	createFreeBtn("↓", 60, -110, function() if fcData then fcData.down=1 end end, function() if fcData then fcData.down=0 end end)
	createFreeBtn("×", 130, -140, function() S._setFreecam(false) end, nil)

	-- хелпер: попадает ли точка в кнопку
	local function isOnFreeButton(pos)
		for _, b in ipairs(freeButtons) do
			if b.Visible then
				local bp = b.AbsolutePosition
				local bs = b.AbsoluteSize
				if pos.X >= bp.X and pos.X <= bp.X + bs.X
					and pos.Y >= bp.Y and pos.Y <= bp.Y + bs.Y then
					return true
				end
			end
		end
		return false
	end

	local function startFreecam()
		local cam = workspace.CurrentCamera
		local cf = cam.CFrame
		fcData = {
			cam = cam, pos = cf.Position,
			yaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z),
			pitch = math.asin(math.clamp(cf.LookVector.Y,-1,1)),
			fwd=0,back=0,left=0,right=0,up=0,down=0
		}
		local ch = LP.Character
		if ch then
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if hum then cam.CameraSubject = nil end
		end

		-- КЛАВИАТУРА/МЫШЬ
		fcConns[1] = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement and not touchLook then
				fcData.yaw = fcData.yaw - math.rad(i.Delta.X)*0.3
				fcData.pitch = math.clamp(fcData.pitch - math.rad(i.Delta.Y)*0.3, -math.pi/2+0.01, math.pi/2-0.01)
			end
		end)

		-- ТАЧ: свайп в любом месте кроме кнопок = поворот
		fcConns[2] = UIS.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				if not isOnFreeButton(i.Position) then
					touchLook = {
						startPos = i.Position,
						startYaw = fcData.yaw,
						startPitch = fcData.pitch
					}
				end
			end
		end)
		fcConns[3] = UIS.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch and touchLook then
				local dx = i.Position.X - touchLook.startPos.X
				local dy = i.Position.Y - touchLook.startPos.Y
				fcData.yaw = touchLook.startYaw - dx * 0.008
				fcData.pitch = math.clamp(touchLook.startPitch - dy * 0.008, -math.pi/2+0.01, math.pi/2-0.01)
			end
		end)
		fcConns[4] = UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				touchLook = nil
			end
		end)

		-- клавиатура для движения
		fcConns[5] = UIS.InputBegan:Connect(function(i,gp)
			if gp or not fcData then return end
			if i.KeyCode==Enum.KeyCode.W then fcData.fwd=1
			elseif i.KeyCode==Enum.KeyCode.S then fcData.back=1
			elseif i.KeyCode==Enum.KeyCode.A then fcData.left=1
			elseif i.KeyCode==Enum.KeyCode.D then fcData.right=1
			elseif i.KeyCode==Enum.KeyCode.Space then fcData.up=1
			elseif i.KeyCode==Enum.KeyCode.LeftControl then fcData.down=1 end
		end)
		fcConns[6] = UIS.InputEnded:Connect(function(i)
			if not fcData then return end
			if i.KeyCode==Enum.KeyCode.W then fcData.fwd=0
			elseif i.KeyCode==Enum.KeyCode.S then fcData.back=0
			elseif i.KeyCode==Enum.KeyCode.A then fcData.left=0
			elseif i.KeyCode==Enum.KeyCode.D then fcData.right=0
			elseif i.KeyCode==Enum.KeyCode.Space then fcData.up=0
			elseif i.KeyCode==Enum.KeyCode.LeftControl then fcData.down=0 end
		end)

		fcConns[7] = RS.RenderStepped:Connect(function(dt)
			if not fcData then return end
			local spd = C.freecamSpeed * dt
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
		touchLook = nil
		local ch = LP.Character
		if ch then
			local hum = ch:FindFirstChildOfClass("Humanoid")
			if hum then workspace.CurrentCamera.CameraSubject = hum end
		end
	end
	S._startFreecam = startFreecam
	S._stopFreecam = stopFreecam
	S._freeButtons = freeButtons

	function S._setFreecam(on)
		if on == C.freecam then return end
		C.freecam = on
		local tog = S.toggles.freecam
		if tog and tog.btn then
			if on then
				tog.btn.BackgroundColor3 = Color3.fromRGB(0,120,0); tog.btn.Text = "Freecam: ВКЛ"
			else
				tog.btn.BackgroundColor3 = Color3.fromRGB(50,50,50); tog.btn.Text = "Freecam: ВЫКЛ"
			end
		end
		if on then
			startFreecam(); hideHotkeysForFreecam(); showFreeButtons()
		else
			stopFreecam(); restoreHotkeys(); hideFreeButtons()
		end
	end

	addR("Visual","Freecam",function(b)
		S._setFreecam(not C.freecam)
	end,false,"freecam")
end

-- PLAYER INFO
local infoPanel = Instance.new("Frame", SG)
infoPanel.Size = UDim2.new(0,240,0,180)
infoPanel.Position = UDim2.new(0.5,-120,0.5,-90)
infoPanel.BackgroundColor3 = Color3.fromRGB(22,22,28)
infoPanel.BorderSizePixel = 0
infoPanel.Visible = false
infoPanel.ZIndex = 100
Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", infoPanel).Color = Color3.fromRGB(120,180,255)
local ipTitle = Instance.new("TextLabel", infoPanel)
ipTitle.Size = UDim2.new(1,0,0,28); ipTitle.BackgroundColor3 = Color3.fromRGB(42,42,42)
ipTitle.BorderSizePixel = 0; ipTitle.Text = "Инфо игрока"
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
ipText.BackgroundTransparency = 1; ipText.Text = ""
ipText.TextColor3 = Color3.fromRGB(220,220,220)
ipText.Font = Enum.Font.Code; ipText.TextSize = 11
ipText.TextXAlignment = Enum.TextXAlignment.Left
ipText.TextYAlignment = Enum.TextYAlignment.Top
ipText.TextWrapped = true
ipClose.MouseButton1Click:Connect(function() infoPanel.Visible = false end)
local ipTarget = nil
local ipConn = nil
local function showInfo(p)
	ipTarget = p; infoPanel.Visible = true
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
		ipText.Text = table.concat({
			"Имя: "..ipTarget.Name,
			"Ник: "..ipTarget.DisplayName,
			"UserID: "..ipTarget.UserId,
			"HP: "..(hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "?"),
			"Дист: "..dist.." studs",
			"Оружие: "..(tool and tool.Name or "—"),
			"Аккаунт: "..(ipTarget.AccountAge or "?").." дн.",
		}, "\n")
	end)
end
S._showPlayerInfo = showInfo

-- GAME INFO DUMPER
if S.toggles.gameDumper then
	print("[ACE extras] Game Info Dumper уже есть")
else
	local dumperPanel = Instance.new("Frame", SG)
	dumperPanel.Size = UDim2.new(0,320,0,400)
	dumperPanel.Position = UDim2.new(0.5,-160,0.5,-200)
	dumperPanel.BackgroundColor3 = Color3.fromRGB(20,20,26)
	dumperPanel.BorderSizePixel = 0; dumperPanel.Visible = false; dumperPanel.ZIndex = 100
	Instance.new("UICorner", dumperPanel).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", dumperPanel).Color = Color3.fromRGB(100,220,180)
	local dpTitle = Instance.new("TextLabel", dumperPanel)
	dpTitle.Size = UDim2.new(1,0,0,28); dpTitle.BackgroundColor3 = Color3.fromRGB(42,42,42)
	dpTitle.BorderSizePixel = 0; dpTitle.Text = "Game Info Dumper"
	dpTitle.TextColor3 = Color3.fromRGB(100,220,180)
	dpTitle.Font = Enum.Font.SourceSansBold; dpTitle.TextSize = 12
	Instance.new("UICorner", dpTitle).CornerRadius = UDim.new(0,8)
	local dpClose = Instance.new("TextButton", dumperPanel)
	dpClose.Size = UDim2.new(0,28,0,28); dpClose.Position = UDim2.new(1,-28,0,0)
	dpClose.BackgroundTransparency = 1; dpClose.Text = "×"
	dpClose.TextColor3 = Color3.new(1,1,1); dpClose.Font = Enum.Font.SourceSansBold; dpClose.TextSize = 16
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
	dpScroll.ScrollBarThickness = 4; dpScroll.CanvasSize = UDim2.new(0,0,0,0)
	dpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UICorner", dpScroll).CornerRadius = UDim.new(0,4)
	local dpText = Instance.new("TextLabel", dpScroll)
	dpText.Size = UDim2.new(1,-8,0,0); dpText.Position = UDim2.new(0,4,0,4)
	dpText.AutomaticSize = Enum.AutomaticSize.Y; dpText.BackgroundTransparency = 1
	dpText.TextColor3 = Color3.fromRGB(200,200,200)
	dpText.Font = Enum.Font.Code; dpText.TextSize = 10
	dpText.TextXAlignment = Enum.TextXAlignment.Left
	dpText.TextYAlignment = Enum.TextYAlignment.Top
	dpText.TextWrapped = true
	local function dumpGame()
		local lines = {"=== GAME INFO ===","Place: "..tostring(game.PlaceId),"JobId: "..tostring(game.JobId),""}
		local rs = game:GetService("ReplicatedStorage")
		local remotes, modules = {}, {}
		for _,o in ipairs(rs:GetDescendants()) do
			if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then table.insert(remotes, o:GetFullName())
			elseif o:IsA("ModuleScript") then table.insert(modules, o:GetFullName()) end
		end
		table.insert(lines, "=== REMOTES ("..#remotes..") ===")
		for _,r in ipairs(remotes) do table.insert(lines, r) end
		table.insert(lines, "")
		table.insert(lines, "=== MODULES ("..#modules..") ===")
		for _,m in ipairs(modules) do table.insert(lines, m) end
		local npcCount = 0
		for _,o in ipairs(workspace:GetDescendants()) do
			if o:IsA("Humanoid") and not Players:GetPlayerFromCharacter(o.Parent) then npcCount = npcCount + 1 end
		end
		table.insert(lines, ""); table.insert(lines, "=== NPC: "..npcCount.." ===")
		return table.concat(lines, "\n")
	end
	local lastDump = nil
	local function refreshDump() lastDump = dumpGame(); dpText.Text = lastDump end
	dpRescan.MouseButton1Click:Connect(refreshDump)
	dpCopy.MouseButton1Click:Connect(function()
		if not lastDump then refreshDump() end
		if setclipboard then pcall(function() setclipboard(lastDump) end); S.notify("Скопировано",Color3.fromRGB(0,180,0))
		else print(lastDump) end
	end)
	dpClose.MouseButton1Click:Connect(function() dumperPanel.Visible = false end)
	addR("Settings","📊 Game Info Dumper",function(b)
		if not dumperPanel.Visible then refreshDump(); dumperPanel.Visible = true
		else dumperPanel.Visible = false end
	end,false,"gameDumper")
end

-- SEARCH + STARS
local funRows = {}
local rowOrder = {}

local function fixTabOrder(tab)
	local lay = tab:FindFirstChildOfClass("UIListLayout")
	if lay then lay.SortOrder = Enum.SortOrder.LayoutOrder end
	local idx = 0
	for _, child in ipairs(tab:GetChildren()) do
		if child.Name ~= "ACE_SearchBox" and child:IsA("GuiObject") then
			local ok = pcall(function() return child.LayoutOrder end)
			if ok then
				idx = idx + 1
				rowOrder[child] = idx
				child.LayoutOrder = idx
			end
		end
	end
end

local function indexRows()
	funRows = {}
	rowOrder = {}
	for _, tabName in ipairs({"Main","Func","Visual","WP","Addons","Settings"}) do
		local tab = S.Tabs[tabName]
		if tab then
			fixTabOrder(tab)
			for _, child in ipairs(tab:GetChildren()) do
				if child:IsA("Frame") then
					for k, t in pairs(S.toggles) do
						if t.btn and t.btn.Parent == child then
							funRows[child] = k
							break
						end
					end
				end
			end
		end
	end
end

local function reorderAll()
	local favs = getFavs()
	local favIdx = 0
	for row, key in pairs(funRows) do
		if row and row.Parent then
			if favs[key] then
				favIdx = favIdx + 1
				row.LayoutOrder = -10000 + favIdx
			else
				row.LayoutOrder = rowOrder[row] or 99999
			end
		end
	end
end

local function addStar(row, key)
	if row:FindFirstChild("ACE_FavStar") then return end
	local mainBtn, sldMinus, sldPlus = nil, nil, nil
	for _, c in ipairs(row:GetChildren()) do
		if c:IsA("TextButton") and c.Name ~= "ACE_FavStar" then
			if not mainBtn then mainBtn = c
			elseif not sldMinus then sldMinus = c
			else sldPlus = c end
		end
	end
	if not mainBtn then return end

	if sldPlus then
		mainBtn.Size = UDim2.new(1, -88, 1, 0)
		sldMinus.Size = UDim2.new(0, 25, 1, 0); sldMinus.Position = UDim2.new(1, -86, 0, 0)
		sldPlus.Size = UDim2.new(0, 25, 1, 0);  sldPlus.Position = UDim2.new(1, -58, 0, 0)
	else
		mainBtn.Size = UDim2.new(1, -32, 1, 0)
	end

	local star = Instance.new("TextButton", row)
	star.Name = "ACE_FavStar"
	star.Size = UDim2.new(0, 26, 1, 0)
	star.Position = UDim2.new(1, -28, 0, 0)
	star.BackgroundColor3 = Color3.fromRGB(60,60,60)
	star.BorderSizePixel = 0
	star.Text = "☆"
	star.TextColor3 = Color3.fromRGB(255,220,80)
	star.Font = Enum.Font.SourceSansBold
	star.TextSize = 14
	star.ZIndex = 5
	Instance.new("UICorner", star).CornerRadius = UDim.new(0,4)
	local function refreshStar()
		local favs = getFavs()
		if favs[key] then
			star.Text = "★"; star.BackgroundColor3 = Color3.fromRGB(180,140,20)
		else
			star.Text = "☆"; star.BackgroundColor3 = Color3.fromRGB(60,60,60)
		end
	end
	refreshStar()
	star.MouseButton1Click:Connect(function()
		toggleFav(key); refreshStar(); reorderAll()
	end)
end

local function addSearchToTab(tabName)
	local tab = S.Tabs[tabName]
	if not tab or tab:FindFirstChild("ACE_SearchBox") then return end
	local box = Instance.new("TextBox", tab)
	box.Name = "ACE_SearchBox"
	box.Size = UDim2.new(1, -5, 0, 28)
	box.BackgroundColor3 = Color3.fromRGB(45,45,45)
	box.BorderSizePixel = 0
	box.PlaceholderText = "🔍 поиск..."
	box.Text = ""
	box.TextColor3 = Color3.new(1,1,1)
	box.PlaceholderColor3 = Color3.fromRGB(140,140,140)
	box.Font = Enum.Font.SourceSansBold
	box.TextSize = 11
	box.ClearTextOnFocus = false
	box.LayoutOrder = -99999
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(box.Text or "")
		for row, _ in pairs(funRows) do
			if row and row.Parent == tab then
				local mainBtn = nil
				for _, c in ipairs(row:GetChildren()) do
					if c:IsA("TextButton") and c.Name ~= "ACE_FavStar" then mainBtn = c; break end
				end
				if mainBtn then
					local txt = string.lower(mainBtn.Text or "")
					row.Visible = (q == "") or (string.find(txt, q, 1, true) ~= nil)
				end
			end
		end
	end)
end

task.spawn(function()
	task.wait(0.7)
	indexRows()
	for _, tabName in ipairs({"Main","Func","Visual","WP","Addons","Settings"}) do
		addSearchToTab(tabName)
	end
	for row, key in pairs(funRows) do
		if row and row.Parent then addStar(row, key) end
	end
	reorderAll()
	local n = 0
	for _ in pairs(funRows) do n = n + 1 end
	print("[ACE extras] search+stars готовы, fun-rows: "..n)
end)

S._extrasCleanup = function()
	S.delT("ItemEspSync")
	if S._setFreecam and C.freecam then S._setFreecam(false) end
	if ipConn then ipConn:Disconnect() end
	if S._freeButtons then
		for _,b in ipairs(S._freeButtons) do pcall(function() b:Destroy() end) end
	end
	if infoPanel then infoPanel:Destroy() end
end

print("[ACE extras] готово v3.2")
