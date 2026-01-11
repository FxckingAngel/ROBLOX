--[[
	Script Viewer App Module
	
	A professional script viewer with decompilation,
	syntax highlighting, and advanced features
]]

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local ScriptViewer = {}

	local window, codeFrame, statusLabel, currentScript
	local decompileCache = {}
	local cacheOrder = {}
	local cacheCount = 0
	local maxCacheSize = 50

	-- Configuration
	local Config = {
		UseCache = true,
		CacheTimeout = 3600,
		FormatCode = true,
		ShowLineNumbers = true,
		MaxLines = 100000,
	}

	-- Get available decompiler
	local function getDecompiler()
		local priorities = {"decompile", "getdecompile", "decompiler"}
		for i = 1, #priorities do
			local func = _G[priorities[i]] or (env and env[priorities[i]])
			if type(func) == "function" then
				return func, priorities[i]
			end
		end
		return nil
	end

	-- Cache management
	local function cacheSet(key, value)
		if not Config.UseCache then return end

		-- Remove oldest if at capacity
		if cacheCount >= maxCacheSize then
			local oldest = cacheOrder[1]
			if oldest then
				decompileCache[oldest] = nil
				table.remove(cacheOrder, 1)
				cacheCount = cacheCount - 1
			end
		end

		-- Add new entry
		decompileCache[key] = {
			value = value,
			timestamp = tick()
		}
		table.insert(cacheOrder, key)
		cacheCount = cacheCount + 1
	end

	local function cacheGet(key)
		if not Config.UseCache then return nil end

		local entry = decompileCache[key]
		if not entry then return nil end

		-- Check timeout
		if tick() - entry.timestamp > Config.CacheTimeout then
			decompileCache[key] = nil
			return nil
		end

		return entry.value
	end

	-- Generate fallback placeholder
	local function generatePlaceholder(scr, errorMsg)
		local info = {
			"--[[",
			"\tScript Viewer - Decompilation Unavailable",
			"\t",
			"\tScript Name: " .. (scr.Name or "Unknown"),
			"\tScript Type: " .. (scr.ClassName or "Unknown"),
			"\tLocation: " .. pcall(function() return scr:GetFullName() end) or "Unknown",
			"\tDecompiler Status: " .. (errorMsg or "No decompiler available"),
			"]]",
			"",
			"-- Script source is not available",
			"-- Possible reasons:",
			"-- • No decompiler installed (Synapse, etc.)",
			"-- • Script source is protected/obfuscated",
			"-- • Script is bytecode-compiled",
			"-- • Insufficient permissions to read source",
			"",
		}

		if scr:IsA("LocalScript") then
			table.insert(info, "local parent = script.Parent")
			table.insert(info, "-- LocalScript functionality hidden")
		elseif scr:IsA("Script") then
			table.insert(info, "-- Server Script functionality hidden")
		elseif scr:IsA("ModuleScript") then
			table.insert(info, "local module = {}")
			table.insert(info, "")
			table.insert(info, "-- Module functionality hidden")
			table.insert(info, "")
			table.insert(info, "return module")
		end

		return table.concat(info, "\n")
	end

	-- Validate source
	local function validateSource(source)
		if not source or type(source) ~= "string" then
			return false, "Invalid source type"
		end

		if #source == 0 then
			return false, "Empty source"
		end

		if #source > Config.MaxLines then
			return false, "Source exceeds maximum lines"
		end

		-- Basic syntax check
		local testFunc = loadstring(source)
		if not testFunc then
			return false, "Invalid Lua syntax"
		end

		return true
	end

	-- Format source code
	local function formatSource(source)
		if not Config.FormatCode then
			return source
		end

		local lines = source:split("\n")
		local formatted = {}
		local indentLevel = 0
		local indentStr = "  " -- 2 spaces

		for i = 1, #lines do
			local line = lines[i]
			local trimmed = line:match("^%s*(.-)%s*$") or ""

			-- Decrease indent for closing keywords
			if trimmed:match("^end%s*($|%-%)") or
				trimmed:match("^until%s*($|%-%)") or
				trimmed:match("^else%s*($|%-%)") or
				trimmed:match("^elseif%s*($|%-%)") then
				indentLevel = math.max(0, indentLevel - 1)
			end

			-- Add formatted line
			if #trimmed > 0 then
				formatted[#formatted + 1] = (indentStr):rep(indentLevel) .. trimmed
			else
				formatted[#formatted + 1] = ""
			end

			-- Increase indent for opening keywords
			if trimmed:match("then%s*$") or
				trimmed:match("do%s*$") or
				trimmed:match("function%s+%w+%s*%(") or
				trimmed:match("repeat%s*$") or
				trimmed:match("^if%s+") then
				indentLevel = indentLevel + 1
			end
		end

		return table.concat(formatted, "\n")
	end

	-- Main decompilation function
	local function decompileScript(scr)
		if not scr or not scr:IsA("LuaSourceContainer") then
			return nil, "Invalid script object"
		end

		-- Check cache
		local cacheKey = scr:GetFullName()
		local cached = cacheGet(cacheKey)
		if cached then
			return cached.source, "cached"
		end

		-- Get decompiler
		local decompileFunc, decompilerName = getDecompiler()
		local source, status = nil, nil

		if decompileFunc then
			-- Try decompiler
			local s, result = pcall(function()
				return decompileFunc(scr)
			end)

			if s and result and type(result) == "string" and #result > 0 then
				local valid, valError = validateSource(result)
				if valid then
					source = result
					status = decompilerName
				else
					status = "Validation failed: " .. valError
				end
			else
				status = "Decompiler error"
			end
		else
			status = "No decompiler"
		end

		-- Fallback to source property
		if not source then
			local s, result = pcall(function()
				return scr.Source
			end)

			if s and result and type(result) == "string" and #result > 0 then
				source = result
				status = "source_property"
			end
		end

		-- Generate placeholder if all failed
		if not source then
			source = generatePlaceholder(scr, status)
			status = "fallback"
		end

		-- Format code
		if source and Config.FormatCode and status ~= "fallback" then
			source = formatSource(source)
		end

		-- Cache result
		if source and status ~= "fallback" then
			cacheSet(cacheKey, {source = source, status = status})
		end

		return source, status
	end

	-- Update status label
	local function updateStatus(status, scriptName)
		if statusLabel then
			local statusText = "Status: "
			local color = Settings.Theme.Text

			if status == "cached" then
				statusText = statusText .. "Cached"
				color = Color3.fromRGB(100, 200, 100)
			elseif status == "decompile" or status == "getdecompile" then
				statusText = statusText .. "Decompiled (" .. status .. ")"
				color = Color3.fromRGB(100, 200, 100)
			elseif status == "source_property" then
				statusText = statusText .. "Direct Source"
				color = Color3.fromRGB(100, 150, 200)
			elseif status == "fallback" then
				statusText = statusText .. "Placeholder"
				color = Color3.fromRGB(200, 150, 100)
			else
				statusText = statusText .. status
				color = Color3.fromRGB(200, 100, 100)
			end

			statusLabel.Text = statusText
			statusLabel.TextColor3 = color
		end
	end

	-- View script
	function ScriptViewer.ViewScript(scr)
		if not scr then
			return
		end

		currentScript = scr
		local source, status = decompileScript(scr)

		if source then
			codeFrame:SetText(source)
			updateStatus(status, scr.Name)
			window:Show()
		else
			updateStatus("Error loading script", scr.Name)
		end
	end

	-- Get current script
	function ScriptViewer.GetCurrentScript()
		return currentScript
	end

	-- Clear cache
	function ScriptViewer.ClearCache()
		decompileCache = {}
		cacheOrder = {}
		cacheCount = 0
	end

	-- Copy to clipboard
	local function copyToClipboard()
		local source = codeFrame:GetText()
		if env.setclipboard then
			env.setclipboard(source)
		elseif setclipboard then
			setclipboard(source)
		else
			updateStatus("Clipboard unavailable")
			return
		end
		updateStatus("Copied to clipboard")
	end

	-- Save to file
	local function saveToFile()
		local source = codeFrame:GetText()
		if not env.writefile and not writefile then
			updateStatus("File write unavailable")
			return
		end

		local scriptName = currentScript and currentScript.Name or "Script"
		local filename = "DexExport_" .. scriptName .. "_" .. os.time() .. ".lua"

		local writeFunc = env.writefile or writefile
		if writeFunc then
			local s, err = pcall(writeFunc, filename, source)
			if s then
				updateStatus("Saved to: " .. filename)
			else
				updateStatus("Save failed: " .. tostring(err))
			end
		end
	end

	-- Initialize UI
	function ScriptViewer.Init()
		window = Lib.Window.new()
		window:SetTitle("Script Viewer")
		window:Resize(600, 400)
		ScriptViewer.Window = window

		local contentFrame = window.GuiElems.Content

		-- Status bar
		statusLabel = Instance.new("TextLabel")
		statusLabel.BackgroundTransparency = 1
		statusLabel.TextColor3 = Settings.Theme.Text
		statusLabel.TextSize = 12
		statusLabel.Font = Enum.Font.SourceSans
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel.Position = UDim2.new(0, 5, 0, 2)
		statusLabel.Size = UDim2.new(0.6, -10, 0, 18)
		statusLabel.Text = "Status: Ready"
		statusLabel.Parent = contentFrame

		-- Copy button
		local copyBtn = Instance.new("TextButton", contentFrame)
		copyBtn.BackgroundColor3 = Settings.Theme.Button
		copyBtn.BackgroundTransparency = 0.3
		copyBtn.TextColor3 = Settings.Theme.Text
		copyBtn.TextSize = 11
		copyBtn.Font = Enum.Font.SourceSans
		copyBtn.Position = UDim2.new(0.6, 5, 0, 2)
		copyBtn.Size = UDim2.new(0.2, -10, 0, 18)
		copyBtn.Text = "Copy"
		copyBtn.BorderSizePixel = 0
		copyBtn.MouseButton1Click:Connect(copyToClipboard)
		copyBtn.MouseEnter:Connect(function()
			copyBtn.BackgroundTransparency = 0.1
		end)
		copyBtn.MouseLeave:Connect(function()
			copyBtn.BackgroundTransparency = 0.3
		end)

		-- Save button
		local saveBtn = Instance.new("TextButton", contentFrame)
		saveBtn.BackgroundColor3 = Settings.Theme.Button
		saveBtn.BackgroundTransparency = 0.3
		saveBtn.TextColor3 = Settings.Theme.Text
		saveBtn.TextSize = 11
		saveBtn.Font = Enum.Font.SourceSans
		saveBtn.Position = UDim2.new(0.8, 5, 0, 2)
		saveBtn.Size = UDim2.new(0.2, -10, 0, 18)
		saveBtn.Text = "Save"
		saveBtn.BorderSizePixel = 0
		saveBtn.MouseButton1Click:Connect(saveToFile)
		saveBtn.MouseEnter:Connect(function()
			saveBtn.BackgroundTransparency = 0.1
		end)
		saveBtn.MouseLeave:Connect(function()
			saveBtn.BackgroundTransparency = 0.3
		end)

		-- Code frame
		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0, 0, 0, 24)
		codeFrame.Frame.Size = UDim2.new(1, 0, 1, -24)
		codeFrame.Frame.Parent = contentFrame

		-- Initialize with empty placeholder
		codeFrame:SetText("-- Script Viewer Ready\n-- Select a script from the Explorer to view its source")

		updateStatus("Ready")
	end

	return ScriptViewer
end

-- Module wrapper
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end
