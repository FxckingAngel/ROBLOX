local shared      = _G.KS_Shared or error("KS_Shared missing")
local CoreGui     = shared.CoreGui
local UserInputService = shared.UserInputService
local KS_UTIL     = _G.KS_UTIL or error("KS_UTIL missing")

local KS_Editor = { Gui = nil, CurrentInstance = nil }

local function makeDraggable(header, frame)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function createGui()
    if KS_Editor.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KoroneEditor"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = CoreGui

    local main = Instance.new("Frame")
    main.AnchorPoint      = Vector2.new(0.5, 0.5)
    main.Position         = UDim2.new(0.5, 0, 0.5, 0)
    main.Size             = UDim2.new(0, 720, 0, 430)
    main.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    main.BorderSizePixel  = 0
    main.Parent           = gui
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 10)
    mc.Parent       = main

    local top = Instance.new("Frame")
    top.Size             = UDim2.new(1, 0, 0, 32)
    top.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
    top.BorderSizePixel  = 0
    top.Parent           = main
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent       = top

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size             = UDim2.new(1, -180, 1, 0)
    title.Position         = UDim2.new(0, 12, 0, 0)
    title.Font             = Enum.Font.SourceSansSemibold
    title.TextSize         = 18
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = "✏️ Korone Script Editor"
    title.Parent           = top

    local btnClose = Instance.new("TextButton")
    btnClose.Size             = UDim2.new(0, 26, 0, 22)
    btnClose.Position         = UDim2.new(1, -32, 0.5, -11)
    btnClose.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
    btnClose.BorderSizePixel  = 0
    btnClose.Font             = Enum.Font.SourceSansBold
    btnClose.Text             = "X"
    btnClose.TextSize         = 16
    btnClose.TextColor3       = Color3.new(1, 1, 1)
    btnClose.Parent           = top
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent       = btnClose

    local btnSave = Instance.new("TextButton")
    btnSave.Size             = UDim2.new(0, 80, 0, 22)
    btnSave.Position         = UDim2.new(1, -210, 0.5, -11)
    btnSave.BackgroundColor3 = Color3.fromRGB(45, 90, 45)
    btnSave.BorderSizePixel  = 0
    btnSave.Font             = Enum.Font.SourceSansSemibold
    btnSave.Text             = "💾 Save"
    btnSave.TextSize         = 14
    btnSave.TextColor3       = Color3.new(1, 1, 1)
    btnSave.Parent           = top
    local bs = Instance.new("UICorner")
    bs.CornerRadius = UDim.new(0, 6)
    bs.Parent       = btnSave

    local btnExport = Instance.new("TextButton")
    btnExport.Size             = UDim2.new(0, 80, 0, 22)
    btnExport.Position         = UDim2.new(1, -122, 0.5, -11)
    btnExport.BackgroundColor3 = Color3.fromRGB(45, 60, 100)
    btnExport.BorderSizePixel  = 0
    btnExport.Font             = Enum.Font.SourceSansSemibold
    btnExport.Text             = "📤 Export"
    btnExport.TextSize         = 14
    btnExport.TextColor3       = Color3.new(1, 1, 1)
    btnExport.Parent           = top
    local be = Instance.new("UICorner")
    be.CornerRadius = UDim.new(0, 6)
    be.Parent       = btnExport

    local content = Instance.new("Frame")
    content.Position             = UDim2.new(0, 0, 0, 32)
    content.Size                 = UDim2.new(1, 0, 1, -32)
    content.BackgroundTransparency = 1
    content.Parent               = main

    local tabs = Instance.new("Frame")
    tabs.Size             = UDim2.new(0, 120, 1, 0)
    tabs.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
    tabs.BorderSizePixel  = 0
    tabs.Parent           = content
    local tbc = Instance.new("UICorner")
    tbc.CornerRadius = UDim.new(0, 10)
    tbc.Parent       = tabs

    local scriptTab = Instance.new("TextButton")
    scriptTab.Size             = UDim2.new(1, 0, 0, 30)
    scriptTab.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    scriptTab.BorderSizePixel  = 0
    scriptTab.Font             = Enum.Font.SourceSansSemibold
    scriptTab.Text             = "📜 Script"
    scriptTab.TextSize         = 16
    scriptTab.TextColor3       = Color3.new(1, 1, 1)
    scriptTab.Parent           = tabs

    local propTab = Instance.new("TextButton")
    propTab.Size             = UDim2.new(1, 0, 0, 30)
    propTab.Position         = UDim2.new(0, 0, 0, 32)
    propTab.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    propTab.BorderSizePixel  = 0
    propTab.Font             = Enum.Font.SourceSansSemibold
    propTab.Text             = "⚙️ Properties"
    propTab.TextSize         = 16
    propTab.TextColor3       = Color3.fromRGB(0.8,0.8,0.8)
    propTab.Parent           = tabs

    local right = Instance.new("Frame")
    right.Position         = UDim2.new(0, 124, 0, 0)
    right.Size             = UDim2.new(1, -124, 1, 0)
    right.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    right.BorderSizePixel  = 0
    right.Parent           = content

    local searchBox = Instance.new("TextBox")
    searchBox.Size             = UDim2.new(0, 220, 0, 24)
    searchBox.Position         = UDim2.new(0, 6, 0, 6)
    searchBox.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    searchBox.BorderSizePixel  = 0
    searchBox.Font             = Enum.Font.SourceSans
    searchBox.PlaceholderText  = "🔍 search in script..."
    searchBox.ClearTextOnFocus = false
    searchBox.TextColor3       = Color3.new(1, 1, 1)
    searchBox.TextSize         = 14
    searchBox.Parent           = right
    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(0, 6)
    sbc.Parent       = searchBox

    local searchNext = Instance.new("TextButton")
    searchNext.Size             = UDim2.new(0, 70, 0, 24)
    searchNext.Position         = UDim2.new(0, 232, 0, 6)
    searchNext.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    searchNext.BorderSizePixel  = 0
    searchNext.Font             = Enum.Font.SourceSansSemibold
    searchNext.Text             = "Next"
    searchNext.TextSize         = 14
    searchNext.TextColor3       = Color3.new(1, 1, 1)
    searchNext.Parent           = right
    local snc = Instance.new("UICorner")
    snc.CornerRadius = UDim.new(0, 6)
    snc.Parent       = searchNext

    local scriptScroll = Instance.new("ScrollingFrame")
    scriptScroll.Name              = "ScriptScroll"
    scriptScroll.Position          = UDim2.new(0, 6, 0, 34)
    scriptScroll.Size              = UDim2.new(1, -12, 1, -40)
    scriptScroll.BackgroundColor3  = Color3.fromRGB(16, 16, 18)
    scriptScroll.BorderSizePixel   = 0
    scriptScroll.ScrollBarThickness = 6
    scriptScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
    scriptScroll.Parent            = right
    local ssc = Instance.new("UICorner")
    ssc.CornerRadius = UDim.new(0, 6)
    ssc.Parent       = scriptScroll

    local codeBox = Instance.new("TextBox")
    codeBox.BackgroundTransparency = 1
    codeBox.Size             = UDim2.new(1, -8, 1, -8)
    codeBox.Position         = UDim2.new(0, 4, 0, 4)
    codeBox.ClearTextOnFocus = false
    codeBox.MultiLine        = true
    codeBox.TextXAlignment   = Enum.TextXAlignment.Left
    codeBox.TextYAlignment   = Enum.TextYAlignment.Top
    codeBox.Font             = Enum.Font.Code
    codeBox.TextSize         = 15
    codeBox.TextColor3       = Color3.new(1, 1, 1)
    codeBox.Text             = ""
    codeBox.Parent           = scriptScroll

    codeBox:GetPropertyChangedSignal("TextBounds"):Connect(function()
        scriptScroll.CanvasSize = UDim2.new(0, 0, 0, codeBox.TextBounds.Y + 12)
    end)

    local propFrame = Instance.new("ScrollingFrame")
    propFrame.Name              = "PropFrame"
    propFrame.Position          = UDim2.new(0, 6, 0, 34)
    propFrame.Size              = UDim2.new(1, -12, 1, -40)
    propFrame.BackgroundColor3  = Color3.fromRGB(16, 16, 18)
    propFrame.BorderSizePixel   = 0
    propFrame.ScrollBarThickness = 6
    propFrame.CanvasSize        = UDim2.new(0, 0, 0, 0)
    propFrame.Visible           = false
    propFrame.Parent            = right
    local pfc = Instance.new("UICorner")
    pfc.CornerRadius = UDim.new(0, 6)
    pfc.Parent       = propFrame

    local propLayout = Instance.new("UIListLayout")
    propLayout.Padding       = UDim.new(0, 4)
    propLayout.FillDirection = Enum.FillDirection.Vertical
    propLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    propLayout.Parent        = propFrame

    local function refreshProps(inst)
        for _, child in ipairs(propFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        if not inst then return end

        local show = {
            "Name","ClassName","Archivable",
            "Transparency","Anchored","CanCollide",
            "Text","Value","Enabled","Visible"
        }

        for _, propName in ipairs(show) do
            local ok, val = pcall(function() return inst[propName] end)
            if ok then
                local row = Instance.new("Frame")
                row.Size                 = UDim2.new(1, -8, 0, 26)
                row.BackgroundTransparency = 1
                row.Parent               = propFrame

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size             = UDim2.new(0.35, 0, 1, 0)
                lbl.Font             = Enum.Font.SourceSans
                lbl.TextSize         = 14
                lbl.TextXAlignment   = Enum.TextXAlignment.Left
                lbl.TextColor3       = Color3.new(1, 1, 1)
                lbl.Text             = propName
                lbl.Parent           = row

                local box = Instance.new("TextBox")
                box.Size             = UDim2.new(0.65, -4, 1, 0)
                box.Position         = UDim2.new(0.35, 4, 0, 0)
                box.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
                box.BorderSizePixel  = 0
                box.ClearTextOnFocus = false
                box.Font             = Enum.Font.Code
                box.TextSize         = 14
                box.TextXAlignment   = Enum.TextXAlignment.Left
                box.TextColor3       = Color3.new(1, 1, 1)
                box.Text             = tostring(val)
                box.Parent           = row
                local bc2 = Instance.new("UICorner")
                bc2.CornerRadius = UDim.new(0, 4)
                bc2.Parent       = box

                local original = val
                box.FocusLost:Connect(function(enter)
                    if not enter then return end
                    local text = box.Text
                    local newVal = text
                    local t = typeof(original)
                    if t == "number" then
                        newVal = tonumber(text) or original
                    elseif t == "boolean" then
                        local l = string.lower(text)
                        newVal = (l == "true" or l == "1" or l == "yes")
                    end

                    local okSet, err = pcall(function()
                        inst[propName] = newVal
                    end)

                    if not okSet then
                        warn("[KoroneEditor] Failed to set "..propName..": "..tostring(err))
                        box.Text = tostring(original)
                    else
                        original = newVal
                    end
                end)
            end
        end

        propFrame.CanvasSize = UDim2.new(0, 0, 0, propLayout.AbsoluteContentSize.Y + 8)
    end

    local function selectTab(which)
        if which == "script" then
            scriptScroll.Visible = true
            propFrame.Visible    = false
            scriptTab.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
            propTab.BackgroundColor3   = Color3.fromRGB(26, 26, 30)
        else
            scriptScroll.Visible = false
            propFrame.Visible    = true
            scriptTab.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
            propTab.BackgroundColor3   = Color3.fromRGB(40, 40, 48)
        end
    end

    scriptTab.MouseButton1Click:Connect(function() selectTab("script") end)
    propTab.MouseButton1Click:Connect(function() selectTab("props") end)

    local lastIndex = 1
    local function doSearch()
        local q    = searchBox.Text
        local text = codeBox.Text
        if q == "" or text == "" then return end
        local start = string.find(string.lower(text), string.lower(q), lastIndex, true)
        if not start then
            start = string.find(string.lower(text), string.lower(q), 1, true)
            lastIndex = 1
        end
        if start then
            local before    = string.sub(text, 1, start)
            local _, lines  = string.gsub(before, "\n", "")
            codeBox.CursorPosition = start + #q
            scriptScroll.CanvasPosition = Vector2.new(0, (lines - 1) * 16)
            lastIndex = start + #q
        end
    end

    searchNext.MouseButton1Click:Connect(doSearch)
    searchBox.FocusLost:Connect(function(enter)
        if enter then
            lastIndex = 1
            doSearch()
        end
    end)

    btnClose.MouseButton1Click:Connect(function()
        gui.Enabled               = false
        KS_Editor.CurrentInstance = nil
    end)

    btnSave.MouseButton1Click:Connect(function()
        local inst = KS_Editor.CurrentInstance
        if not inst then return end
        if inst:IsA("LuaSourceContainer") then
            local src = codeBox.Text or ""
            KS_UTIL.applyScriptSource(inst, src)
            KS_UTIL.exportScript(inst)
            print("[KoroneEditor] Saved script + exported file.")
        else
            refreshProps(inst)
        end
    end)

    btnExport.MouseButton1Click:Connect(function()
        local inst = KS_Editor.CurrentInstance
        if not inst then return end
        if inst:IsA("LuaSourceContainer") then
            KS_UTIL.exportScript(inst)
        else
            KS_UTIL.exportInstance(inst, { name = inst.Name })
        end
    end)

    makeDraggable(top, main)

    KS_Editor.Gui = gui
    KS_Editor.Widgets = {
        Title        = title,
        CodeBox      = codeBox,
        SelectTab    = selectTab,
        RefreshProps = refreshProps,
    }
end

function KS_Editor.Open(inst)
    if not inst or typeof(inst) ~= "Instance" then
        error("KoroneEditor.Open expects an Instance")
    end
    createGui()
    KS_Editor.Gui.Enabled     = true
    KS_Editor.CurrentInstance = inst

    local w = KS_Editor.Widgets
    w.Title.Text = ("✏️ Korone Editor — %s (%s)"):format(inst.Name, inst.ClassName)
    if inst:IsA("LuaSourceContainer") then
        w.CodeBox.Text = KS_UTIL.getScriptSource(inst)
        w.SelectTab("script")
    else
        w.CodeBox.Text = "-- Not a script. Use the ⚙️ Properties tab."
        w.SelectTab("props")
    end
    w.RefreshProps(inst)
end

_G.KS_Editor = KS_Editor
