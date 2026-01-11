--[[
	DataStore Editor Module
	
	Browse, edit, and manage game datastores
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
	local DataStoreEditor = {}
	
	local dss = game:GetService("DataStoreService")
	local window, dataList, keystoreDropdown, valueBox
	local currentStore = nil
	local storeCache = {}
	
	DataStoreEditor.ListDataStores = function()
		if not Main.Elevated then return {} end
		
		local stores = {}
		local s,result = pcall(function()
			for i,store in pairs(dss:ListDataStoresAsync():GetPages()) do
				for _,storeName in pairs(store) do
					stores[#stores+1] = storeName
				end
			end
		end)
		
		return s and stores or {}
	end
	
	DataStoreEditor.OpenDataStore = function(storeName)
		if not Main.Elevated then return false end
		
		local s,store = pcall(function()
			return dss:GetDataStore(storeName)
		end)
		
		if s and store then
			currentStore = {name = storeName, store = store}
			storeCache[storeName] = {}
			DataStoreEditor.RefreshKeys()
			return true
		end
		return false
	end
	
	DataStoreEditor.RefreshKeys = function()
		if not currentStore then return end
		
		local keys = {}
		local s,result = pcall(function()
			for i,key in pairs(currentStore.store:ListKeysAsync():GetPages()) do
				for _,keyName in pairs(key) do
					keys[#keys+1] = keyName
					storeCache[currentStore.name][keyName] = nil
				end
			end
		end)
		
		table.sort(keys)
		DataStoreEditor.DisplayKeys(keys)
	end
	
	DataStoreEditor.DisplayKeys = function(keys)
		if not dataList then return end
		
		dataList:ClearAllChildren()
		
		for i = 1,#keys do
			local key = keys[i]
			local btn = Instance.new("TextButton")
			btn.BackgroundColor3 = Settings.Theme.Button
			btn.TextColor3 = Settings.Theme.Text
			btn.Size = UDim2.new(1, 0, 0, 25)
			btn.Text = key
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Parent = dataList
			
			btn.MouseButton1Click:Connect(function()
				DataStoreEditor.LoadKey(key)
			end)
		end
	end
	
	DataStoreEditor.LoadKey = function(key)
		if not currentStore then return end
		
		local s,value = pcall(function()
			if storeCache[currentStore.name][key] ~= nil then
				return storeCache[currentStore.name][key]
			end
			return currentStore.store:GetAsync(key)
		end)
		
		if s and value then
			storeCache[currentStore.name][key] = value
			local valueStr = game:GetService("HttpService"):JSONEncode(value)
			valueBox.Text = valueStr
		else
			valueBox.Text = "Error loading key or key doesn't exist"
		end
	end
	
	DataStoreEditor.SetKey = function(key,value)
		if not currentStore then return false end
		
		local s,result = pcall(function()
			return currentStore.store:SetAsync(key, value)
		end)
		
		if s then
			storeCache[currentStore.name][key] = value
			return true
		end
		return false
	end
	
	DataStoreEditor.DeleteKey = function(key)
		if not currentStore then return false end
		
		local s,result = pcall(function()
			return currentStore.store:RemoveAsync(key)
		end)
		
		if s then
			storeCache[currentStore.name][key] = nil
			return true
		end
		return false
	end
	
	DataStoreEditor.Init = function()
		window = Lib.Window.new()
		window:SetTitle("DataStore Editor")
		window:Resize(600, 400)
		DataStoreEditor.Window = window
		
		local contentFrame = window.GuiElems.Content
		
		-- Store selector
		local storeLabel = Lib.Label.new()
		storeLabel.Text = "DataStore:"
		storeLabel.Position = UDim2.new(0, 5, 0, 5)
		storeLabel.Size = UDim2.new(0, 50, 0, 20)
		window:Add(storeLabel)
		
		local storeDropdown = Lib.DropDown.new()
		storeDropdown.Position = UDim2.new(0, 60, 0, 5)
		storeDropdown.Size = UDim2.new(1, -130, 0, 20)
		storeDropdown.OnSelect:Connect(function(storeName)
			if storeName then
				DataStoreEditor.OpenDataStore(storeName)
			end
		end)
		window:Add(storeDropdown)
		
		local refreshBtn = Lib.Button.new()
		refreshBtn.Text = "Refresh"
		refreshBtn.Position = UDim2.new(1, -65, 0, 5)
		refreshBtn.Size = UDim2.new(0, 60, 0, 20)
		refreshBtn.OnClick:Connect(function()
			local stores = DataStoreEditor.ListDataStores()
			storeDropdown:SetOptions(stores)
		end)
		window:Add(refreshBtn)
		
		-- Key list
		local keyLabel = Lib.Label.new()
		keyLabel.Text = "Keys:"
		keyLabel.Position = UDim2.new(0, 5, 0, 35)
		keyLabel.Size = UDim2.new(0.4, -10, 0, 20)
		window:Add(keyLabel)
		
		dataList = Instance.new("ScrollingFrame")
		dataList.BackgroundColor3 = Settings.Theme.TextBox
		dataList.BorderColor3 = Settings.Theme.Outline2
		dataList.Size = UDim2.new(0, 400, 0, 0)
		dataList.Position = UDim2.new(0, 5, 0, 60)
		dataList.Size = UDim2.new(0.4, -10, 1, -125)
		dataList.CanvasSize = UDim2.new(0, 0, 0, 0)
		dataList.ScrollBarThickness = 4
		dataList.Parent = contentFrame
		
		local layout = Instance.new("UIListLayout", dataList)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)
		
		-- Value display/editor
		local valueLabel = Lib.Label.new()
		valueLabel.Text = "Value:"
		valueLabel.Position = UDim2.new(0.4, 10, 0, 35)
		valueLabel.Size = UDim2.new(0.6, -20, 0, 20)
		window:Add(valueLabel)
		
		valueBox = Instance.new("TextBox")
		valueBox.BackgroundColor3 = Settings.Theme.TextBox
		valueBox.TextColor3 = Settings.Theme.Text
		valueBox.TextSize = 12
		valueBox.Font = Enum.Font.Roboto
		valueBox.MultiLine = true
		valueBox.Position = UDim2.new(0.4, 10, 0, 60)
		valueBox.Size = UDim2.new(0.6, -20, 1, -125)
		valueBox.Parent = contentFrame
		
		-- Buttons
		local saveBtn = Lib.Button.new()
		saveBtn.Text = "Save Value"
		saveBtn.Position = UDim2.new(0.4, 10, 1, -30)
		saveBtn.Size = UDim2.new(0.3, -15, 0, 25)
		window:Add(saveBtn)
		
		local deleteBtn = Lib.Button.new()
		deleteBtn.Text = "Delete Key"
		deleteBtn.Position = UDim2.new(0.7, 5, 1, -30)
		deleteBtn.Size = UDim2.new(0.3, -15, 0, 25)
		window:Add(deleteBtn)
		
		-- Load initial stores
		local stores = DataStoreEditor.ListDataStores()
		storeDropdown:SetOptions(stores)
	end
	
	return DataStoreEditor
end

if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end
