local shared      = _G.KS_Shared or error("KS_Shared missing")
local CoreGui     = shared.CoreGui
local UserInputService = shared.UserInputService
local KS_Editor   = _G.KS_Editor or error("KS_Editor missing")
local KS_UTIL     = _G.KS_UTIL or error("KS_UTIL missing")

local KS_Explorer = { Gui = nil, Selected = nil }

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

local function iconFor(inst)
    if inst:IsA("Folder") or inst:IsA("Model") then return "📁"
    elseif inst:IsA("Script") or inst:IsA("LocalScript") then return "📜"
    elseif inst:IsA("ModuleScript") then return "📦"
    elseif inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then return "📡"
    elseif inst:IsA("Part") or inst:IsA("MeshPart") then return "🧱"
    elseif inst:IsA("ScreenGui") then return "🖼"
    else return "🔹" end
end

local function createGui()
    if KS_Explorer.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KoroneExplorer"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled        = false
    gui.Parent         = CoreGui

    local main = Instance.new("Frame")
    main.AnchorPoint      = Vector2.new(0, 0.5)
    main.Position         = UDim2.new(0, 16, 0.5, 0)
    main.Size             = UDim2.new(0, 460, 0, 380)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    main.BorderSizePixel  = 0
    main.Parent           = gui
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 10)
    mc.Parent       = main

    local top = Instance.new("Frame")
    top.Size             = UDim2.new(1, 0, 0, 30)
    top.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    top.BorderSizePixel  = 0
    top.Parent           = main
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent       = top

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size             = UDim2.new(1, -90, 1, 0)
    title.Position         = UDim2.new(0, 8, 0, 0)
    title.Font             = Enum.Font.SourceSansSemibold
    title.TextSize         = 18
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = "🗂 Korone Explorer"
    title.Parent           = top

    local btnClose = Instance.new("TextButton")
    btnClose.Size             = UDim2.new(0, 26, 0, 22)
    btnClose.Position         = UDim2.new(1, -30, 0.5, -11)
    btnClose.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
    btnClose.BorderSizePixel  = 0
    btnClose.Font             = Enum.Font.SourceSansBold
    btnClose.Text             = "X"
    btnClose.TextSize         = 16
    btnClose.TextColor3       = Color3.new(1, 1, 1)
    btnClose.Parent           = top
    local bcc = Instance.new("UICorner")
    bcc.CornerRadius = UDim.new(0, 6)
    bcc.Parent       = btnClose

    local content = Instance.new("Frame")
    content.Position             = UDim2.new(0, 0, 0, 30)
    content.Size                 = UDim2.new(1, 0, 1, -30)
    content.BackgroundTransparency = 1
    content.Parent               = main

    local tree = Instance.new("ScrollingFrame")
    tree.Name              = "Tree"
    tree.Position          = UDim2.new(0, 4, 0, 4)
    tree.Size              = UDim2.new(0.5, -6, 1, -8)
    tree.BackgroundColor3  = Color3.fromRGB(20, 20, 22)
    tree.BorderSizePixel   = 0
    tree.ScrollBarThickness = 6
    tree.CanvasSize        = UDim2.new(0, 0, 0, 0)
    tree.Parent            = content
    local tc2 = Instance.new("UICorner")
    tc2.CornerRadius = UDim.new(0, 6)
    tc2.Parent       = tree

    local treeLayout = Instance.new("UIListLayout")
    treeLayout.Padding       = UDim.new(0, 2)
    treeLayout.FillDirection = Enum.FillDirection.Vertical
    treeLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    treeLayout.Parent        = tree

    local right = Instance.new("Frame")
    right.Position         = UDim2.new(0.5, 2, 0, 4)
    right.Size             = UDim2.new(0.5, -6, 1, -8)
    right.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    right.BorderSizePixel  = 0
    right.Parent           = content
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent       = right

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size             = UDim2.new(1, -10, 0, 24)
    nameLabel.Position         = UDim2.new(0, 5, 0, 5)
    nameLabel.Font             = Enum.Font.SourceSansSemibold
    nameLabel.TextSize         = 18
    nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
    nameLabel.TextColor3       = Color3.new(1, 1, 1)
    nameLabel.Text             = "Instance: (none)"
    nameLabel.Parent           = right

    local btnEdit = Instance.new("TextButton")
    btnEdit.Size             = UDim2.new(0, 120, 0, 24)
    btnEdit.Position         = UDim2.new(0, 6, 0, 34)
    btnEdit.BackgroundColor3 = Color3.fromRGB(56, 102, 65)
    btnEdit.BorderSizePixel  = 0
    btnEdit.Font             = Enum.Font.SourceSansSemibold
    btnEdit.Text             = "✏️ Open Editor"
    btnEdit.TextSize         = 14
    btnEdit.TextColor3       = Color3.new(1, 1, 1)
    btnEdit.Parent           = right
    local bec = Instance.new("UICorner")
    bec.CornerRadius = UDim.new(0, 6)
    bec.Parent       = btnEdit

    local btnExport = Instance.new("TextButton")
    btnExport.Size             = UDim2.new(0, 120, 0, 24)
    btnExport.Position         = UDim2.new(0, 134, 0, 34)
    btnExport.BackgroundColor3 = Color3.fromRGB(59, 89, 152)
    btnExport.BorderSizePixel  = 0
    btnExport.Font             = Enum.Font.SourceSansSemibold
    btnExport.Text             = "📤 Export JSON"
    btnExport.TextSize         = 14
    btnExport.TextColor3       = Color3.new(1, 1, 1)
    btnExport.Parent           = right
    local bex = Instance.new("UICorner")
    bex.CornerRadius = UDim.new(0, 6)
    bex.Parent       = btnExport

    local propList = Instance.new("ScrollingFrame")
    propList.Name              = "Props"
    propList.Position          = UDim2.new(0, 6, 0, 64)
    propList.Size              = UDim2.new(1, -12, 1, -70)
    propList.BackgroundTransparency = 1
    propList.BorderSizePixel   = 0
    propList.ScrollBarThickness = 6
    propList.CanvasSize        = UDim2.new(0, 0, 0, 0)
    propList.Parent            = right

    local propLayout = Instance.new("UIListLayout")
    propLayout.Padding       = UDim.new(0, 2)
    propLayout.FillDirection = Enum.FillDirection.Vertical
    propLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    propLayout.Parent        = propList

    local function addPropRow(name, val)
        local row = Instance.new("TextLabel")
        row.BackgroundTransparency = 1
        row.Size             = UDim2.new(1, -4, 0, 18)
        row.Font             = Enum.Font.SourceSans
        row.TextSize         = 13
        row.TextXAlignment   = Enum.TextXAlignment.Left
        row.TextColor3       = Color3.new(1, 1, 1)
        row.Text             = name.." = "..tostring(val)
        row.Parent           = propList
    end

    local function buildTree(inst, depth)
        depth = depth or 0
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, -4, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = true
        btn.Font             = Enum.Font.SourceSans
        btn.TextSize         = 14
        btn.TextXAlignment   = Enum.TextXAlignment.Left
        btn.TextColor3       = Color3.new(1, 1, 1)
        btn.Text             = string.rep("   ", depth)..iconFor(inst).." "..inst.Name.." ["..inst.ClassName.."]"
        btn.Parent           = tree
        local bc3 = Instance.new("UICorner")
        bc3.CornerRadius = UDim.new(0, 4)
        bc3.Parent       = btn

        local lastClick = 0
        btn.MouseButton1Click:Connect(function()
            KS_Explorer.Selected = inst
            nameLabel.Text = "Instance: "..inst.Name.." ("..inst.ClassName..")"
            for _, c in ipairs(propList:GetChildren()) do
                if c:IsA("TextLabel") then c:Destroy() end
            end
            for _, p in ipairs({"Name","ClassName","Parent","Archivable","Transparency","Anchored","CanCollide","Text","Value"}) do
                local ok, v = pcall(function() return inst[p] end)
                if ok then addPropRow(p, v) end
            end
            propList.CanvasSize = UDim2.new(0, 0, 0, propLayout.AbsoluteContentSize.Y + 8)

            local now = tick()
            if now - lastClick <= 0.3 then
                KS_Editor.Open(inst)
            end
            lastClick = now
        end)

        for _, child in ipairs(inst:GetChildren()) do
            buildTree(child, depth + 1)
        end
    end

    for _, root in ipairs({
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterGui"),
    }) do
        if root then buildTree(root, 0) end
    end

    tree.CanvasSize = UDim2.new(0, 0, 0, treeLayout.AbsoluteContentSize.Y + 8)

    btnEdit.MouseButton1Click:Connect(function()
        if KS_Explorer.Selected then
            KS_Editor.Open(KS_Explorer.Selected)
        end
    end)

    btnExport.MouseButton1Click:Connect(function()
        local inst = KS_Explorer.Selected
        if not inst then return end
        if inst:IsA("LuaSourceContainer") then
            KS_UTIL.exportScript(inst)
        else
            KS_UTIL.exportInstance(inst, { name = inst.Name })
        end
    end)

    btnClose.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    makeDraggable(top, main)
    KS_Explorer.Gui = gui
end

function KS_Explorer.Toggle()
    createGui()
    KS_Explorer.Gui.Enabled = not KS_Explorer.Gui.Enabled
end

_G.KS_Explorer = KS_Explorer
