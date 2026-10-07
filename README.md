The script will work correctly only because of this connection:
local files = {
	{
		name="UCS",
		urls={
			"https://raw.githubusercontent.com/Chester-pdf/UCS.lua/main/main.raw?t="..tostring(tick()),
			"https://cdn.jsdelivr.net/gh/Chester-pdf/UCS.lua@main/main.raw",
			"https://raw.githack.com/Chester-pdf/UCS.lua/main/main.raw",
		},
		required=true,
	},
}

local loaded = {}
for _, f in ipairs(files) do
	print("[UCS] загрузка "..f.name.."...")

	local src, usedUrl
	for _, url in ipairs(f.urls) do
		print("[UCS] пробую: "..url)
		local ok, r = pcall(function() return game:HttpGet(url) end)
		if ok and r and #r > 500 then
			src = r
			usedUrl = url
			print("[UCS] ✓ скачано "..#r.." байт")
			break
		else
			print("[UCS] ✗ "..tostring(ok and ("коротко: "..#(r or "")) or r))
		end
	end

	if not src then
		warn("[UCS] "..f.name.." — все URL недоступны")
		if f.required then break end
	else
		local fn, perr = loadstring(src)
		if not fn then
			warn("[UCS] "..f.name.." — ошибка компиляции: "..tostring(perr))
			if f.required then break end
		else
			print("[UCS] запускаю "..f.name.."...")
			local ok2, err2 = pcall(fn)
			if ok2 then
				loaded[#loaded+1] = f.name
				print("[UCS] "..f.name.." OK")
			else
				warn("[UCS] "..f.name.." — runtime: "..tostring(err2))
			end
		end
	end
	task.wait(0.3)
end

if #loaded > 0 then
	print("[UCS] Загружено: "..table.concat(loaded, ", "))
else
	warn("[UCS] Ничего не загружено")
end
Скрипт будет работать корректно лишь из-за этого соединения:
local files = {
	{
		name="UCS",
		urls={
			"https://raw.githubusercontent.com/Chester-pdf/UCS.lua/main/main.raw?t="..tostring(tick()),
			"https://cdn.jsdelivr.net/gh/Chester-pdf/UCS.lua@main/main.raw",
			"https://raw.githack.com/Chester-pdf/UCS.lua/main/main.raw",
		},
		required=true,
	},
}

local loaded = {}
for _, f in ipairs(files) do
	print("[UCS] загрузка "..f.name.."...")

	local src, usedUrl
	for _, url in ipairs(f.urls) do
		print("[UCS] пробую: "..url)
		local ok, r = pcall(function() return game:HttpGet(url) end)
		if ok and r and #r > 500 then
			src = r
			usedUrl = url
			print("[UCS] ✓ скачано "..#r.." байт")
			break
		else
			print("[UCS] ✗ "..tostring(ok and ("коротко: "..#(r or "")) or r))
		end
	end

	if not src then
		warn("[UCS] "..f.name.." — все URL недоступны")
		if f.required then break end
	else
		local fn, perr = loadstring(src)
		if not fn then
			warn("[UCS] "..f.name.." — ошибка компиляции: "..tostring(perr))
			if f.required then break end
		else
			print("[UCS] запускаю "..f.name.."...")
			local ok2, err2 = pcall(fn)
			if ok2 then
				loaded[#loaded+1] = f.name
				print("[UCS] "..f.name.." OK")
			else
				warn("[UCS] "..f.name.." — runtime: "..tostring(err2))
			end
		end
	end
	task.wait(0.3)
end

if #loaded > 0 then
	print("[UCS] Загружено: "..table.concat(loaded, ", "))
else
	warn("[UCS] Ничего не загружено")
end
