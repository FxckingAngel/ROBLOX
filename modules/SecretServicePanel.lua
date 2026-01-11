--[[
	Secret Service Panel Module
	
	Advanced executor and output viewer
	for debugging and execution
]]

local Main,Lib,Apps,Settings
local Explorer, Properties, ScriptViewer, Notebook

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local SecretServicePanel = {}
	
	local window, outputBox, inputBox
	local outputHistory = {}
	local outputLimit = 1000
	
	SecretServicePanel.Print = function(message,level)
		level = level or "log"
		local entry = {
			message = tostring(message),
			level = level,
			timestamp = tick(),
			formatted = string.format("[%s] %s", level:upper(), tostring(message))
		}
		
		outputHistory[#outputHistory+1] = entry
		if #outputHistory > outputLimit then
			table.remove(outputHistory, 1)
		end
		
		SecretServicePanel.RefreshOutput()
		return entry
	end
	
	SecretServicePanel.PrintWarn = function(message)
		return SecretServicePanel.Print(message, "warn")
	end
	
	SecretServicePanel.PrintError = function(message)
		return SecretServicePanel.Print(message, "error")
	end
	
	SecretServicePanel.ExecuteCode = function(code)
		if not code or #code == 0 then return false, "Empty code" end
		
		local s,result = pcall(loadstring(code))
		
		if not s then
			SecretServicePanel.PrintError("Execution failed: "..tostring(result))
			return false, result
		end
		
		if result then
			SecretServicePanel.Print("Execution successful")
			if type(result) == "string" or type(result) == "number" then
				SecretServicePanel.Print("Return: "..tostring(result))
			end
		end
		
		return true, result
	end
	
	SecretServicePanel.ClearOutput = function()
		table.clear(outputHistory)
		SecretServicePanel.RefreshOutput()
	end
	
	SecretServicePanel.ExportOutput = function()
		local exported = {}
		for i = 1,#outputHistory do
			exported[i] = outputHistory[i].formatted
		end
		return table.concat(exported, "\n")
	end
	
	SecretServicePanel.RefreshOutput = function()
		if not outputBox then return end
		
		local lines = {}
		local colorMap = {
			log = Settings.Theme.Text,
			warn = Color3.fromRGB(255, 200, 0),
			error = Color3.fromRGB(255, 100, 100)
		}
		
		for i = math.max(1, #outputHistory-100),#outputHistory do
			local entry = outputHistory[i]
			lines[#lines+1] = entry.formatted
		end
		
		outputBox.Text = table.concat(lines, "\n")
	end
	
	SecretServicePanel.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Secret Service Panel")
		window:Resize(500, 400)
		SecretServicePanel.Window = window
		
		local contentFrame = window.GuiElems.Content
		
		-- Output box
		local outputLabel = Lib.Label.new()
		outputLabel.Text = "Output:"
		outputLabel.Position = UDim2.new(0, 5, 0, 5)
		outputLabel.Size = UDim2.new(1, -10, 0, 20)
		window:Add(outputLabel)
		
		outputBox = Instance.new("TextBox")
		outputBox.BackgroundColor3 = Settings.Theme.TextBox
		outputBox.TextColor3 = Settings.Theme.Text
		outputBox.TextSize = 12
		outputBox.Font = Enum.Font.Roboto
		outputBox.MultiLine = true
		outputBox.ReadOnly = true
		outputBox.TextXAlignment = Enum.TextXAlignment.Left
		outputBox.TextYAlignment = Enum.TextYAlignment.Top
		outputBox.Position = UDim2.new(0, 5, 0, 30)
		outputBox.Size = UDim2.new(1, -10, 0.5, -45)
		outputBox.Parent = contentFrame
		
		-- Separator
		local separator = Instance.new("Frame")
		separator.BackgroundColor3 = Settings.Theme.Outline2
		separator.BorderSizePixel = 0
		separator.Position = UDim2.new(0, 0, 0.5, -5)
		separator.Size = UDim2.new(1, 0, 0, 1)
		separator.Parent = contentFrame
		
		-- Input label
		local inputLabel = Lib.Label.new()
		inputLabel.Text = "Input:"
		inputLabel.Position = UDim2.new(0, 5, 0.5, 5)
		inputLabel.Size = UDim2.new(1, -10, 0, 20)
		window:Add(inputLabel)
		
		-- Input box
		inputBox = Instance.new("TextBox")
		inputBox.BackgroundColor3 = Settings.Theme.TextBox
		inputBox.TextColor3 = Settings.Theme.Text
		inputBox.TextSize = 12
		inputBox.Font = Enum.Font.Roboto
		inputBox.MultiLine = true
		inputBox.PlaceholderText = "Enter Lua code here..."
		inputBox.PlaceholderColor3 = Settings.Theme.PlaceholderText
		inputBox.Position = UDim2.new(0, 5, 0.5, 30)
		inputBox.Size = UDim2.new(1, -10, 0.5, -95)
		inputBox.Parent = contentFrame
		
		-- Execute button
		local executeBtn = Lib.Button.new()
		executeBtn.Text = "Execute"
		executeBtn.Position = UDim2.new(0, 5, 1, -30)
		executeBtn.Size = UDim2.new(0.5, -10, 0, 25)
		executeBtn.OnClick:Connect(function()
			SecretServicePanel.ExecuteCode(inputBox.Text)
		end)
		window:Add(executeBtn)
		
		-- Clear button
		local clearBtn = Lib.Button.new()
		clearBtn.Text = "Clear Output"
		clearBtn.Position = UDim2.new(0.5, 5, 1, -30)
		clearBtn.Size = UDim2.new(0.5, -10, 0, 25)
		clearBtn.OnClick:Connect(function()
			SecretServicePanel.ClearOutput()
		end)
		window:Add(clearBtn)
		
		SecretServicePanel.Print("Secret Service Panel Initialized")
	end
	
	return SecretServicePanel
end

if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end
