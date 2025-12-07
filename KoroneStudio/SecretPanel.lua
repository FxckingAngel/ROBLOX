local shared      = _G.KS_Shared or error("KS_Shared missing")
local CoreGui     = shared.CoreGui
local UserInputService = shared.UserInputService

local KS_Secret = { Gui = nil }

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
    if KS_Secret.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KoroneSecretPanel"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled        = false
    gui.Parent         = CoreGui

    local main = Instance.new("Frame")
    main.AnchorPoint      = Vector2.new(0.5, 0.5)
    main.Position         = UDim2.new(0.5, 0, 0.5, 0)
    main.Size             = UDim2.new(0, 520, 0, 320)
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
    title.Size             = UDim2.new(1, -60, 1, 0)
    title.Position         = UDim2.new(0, 10, 0, 0)
    title.Font             = Enum.Font.SourceSansSemibold
    title.TextSize         = 18
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = "🕵️ Secret Service Panel"
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

    local codeBox = Instance.new("TextBox")
    codeBox.Size             = UDim2.new(1, -10, 0.45, 0)
    codeBox.Position         = UDim2.new(0, 5, 0, 40)
    codeBox.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    codeBox.BorderSizePixel  = 0
    codeBox.ClearTextOnFocus = false
    codeBox.MultiLine        = true
    codeBox.TextXAlignment   = Enum.TextXAlignment.Left
    codeBox.TextYAlignment   = Enum.TextYAlignment.Top
    codeBox.Font             = Enum.Font.Code
    codeBox.TextSize         = 15
    codeBox.TextColor3       = Color3.new(1, 1, 1)
    codeBox.PlaceholderText  = "-- put executor-only code here\nprint(\"hello from Korone Studio\")"
    codeBox.Parent           = main
    local cbC = Instance.new("UICorner")
    cbC.CornerRadius = UDim.new(0, 8)
    cbC.Parent       = codeBox

    local output = Instance.new("ScrollingFrame")
    output.Name              = "Output"
    output.Position          = UDim2.new(0, 5, 0.45, 40)
    output.Size              = UDim2.new(1, -10, 0, 130)
    output.BackgroundColor3  = Color3.fromRGB(12, 12, 14)
    output.BorderSizePixel   = 0
    output.ScrollBarThickness = 6
    output.CanvasSize        = UDim2.new(0, 0, 0, 0)
    output.Parent            = main
    local oc = Instance.new("UICorner")
    oc.CornerRadius = UDim.new(0, 8)
    oc.Parent       = output

    local layout = Instance.new("UIListLayout")
    layout.Padding       = UDim2.new(0, 2)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Parent        = output

    local function addLine(text, isErr)
        local row = Instance.new("TextLabel")
        row.BackgroundTransparency = 1
        row.Size             = UDim2.new(1, -4, 0, 18)
        row.Font             = Enum.Font.Code
        row.TextSize         = 14
        row.TextXAlignment   = Enum.TextXAlignment.Left
        row.TextColor3       = isErr and Color3.fromRGB(255, 120, 120) or Color3.new(1, 1, 1)
        row.Text             = text
        row.Parent           = output
        output.CanvasSize    = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end

    local btnRun = Instance.new("TextButton")
    btnRun.Size             = UDim2.new(0, 80, 0, 26)
    btnRun.Position         = UDim2.new(1, -90, 1, -32)
    btnRun.BackgroundColor3 = Color3.fromRGB(56, 102, 65)
    btnRun.BorderSizePixel  = 0
    btnRun.Font             = Enum.Font.SourceSansSemibold
    btnRun.Text             = "▶ Run"
    btnRun.TextSize         = 14
    btnRun.TextColor3       = Color3.new(1, 1, 1)
    btnRun.Parent           = main
    local brc = Instance.new("UICorner")
    brc.CornerRadius = UDim.new(0, 6)
    brc.Parent       = btnRun

    btnRun.MouseButton1Click:Connect(function()
        for _, c in ipairs(output:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        output.CanvasSize = UDim2.new(0, 0, 0, 0)

        local src = codeBox.Text or ""
        if src == "" then return end

        local fn, err = loadstring(src, "=SecretPanel")
        if not fn then
            addLine("compile error: "..tostring(err), true)
            return
        end

        local env = getfenv(fn)
        env.print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do
                table.insert(parts, tostring(select(i, ...)))
            end
            addLine(table.concat(parts, " "))
        end
        setfenv(fn, env)

        local ok, err2 = pcall(fn)
        if not ok then
            addLine("runtime error: "..tostring(err2), true)
        end
    end)

    btnClose.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    makeDraggable(top, main)
    KS_Secret.Gui = gui
end

function KS_Secret.Toggle()
    createGui()
    KS_Secret.Gui.Enabled = not KS_Secret.Gui.Enabled
end

_G.KS_Secret = KS_Secret
