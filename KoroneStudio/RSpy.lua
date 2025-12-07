local shared      = _G.KS_Shared or error("KS_Shared missing")
local CoreGui     = shared.CoreGui
local UserInputService = shared.UserInputService
local HttpService = shared.HttpService

local KS_RSpy = { Gui = nil, Enabled = true, AddLog = nil }

local function makeDraggable(header, frame)
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
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
                frame.Position.X.Scale, frame.Position.X.Offset + delta.X,
                frame.Position.Y.Scale, frame.Position.Y.Offset + delta.Y
            )
        end
    end)
end

local function createGui()
    if KS_RSpy.Gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "KoroneRemoteSpy"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Enabled        = false
    gui.Parent         = CoreGui

    local main = Instance.new("Frame")
    main.AnchorPoint      = Vector2.new(1, 0.5)
    main.Position         = UDim2.new(1, -16, 0.5, 0)
    main.Size             = UDim2.new(0, 480, 0, 260)
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
    title.Size             = UDim2.new(1, -110, 1, 0)
    title.Position         = UDim2.new(0, 8, 0, 0)
    title.Font             = Enum.Font.SourceSansSemibold
    title.TextSize         = 18
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Text             = "📡 Korone Remote Spy"
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

    local btnToggle = Instance.new("TextButton")
    btnToggle.Size             = UDim2.new(0, 90, 0, 22)
    btnToggle.Position         = UDim2.new(1, -130, 0.5, -11)
    btnToggle.BackgroundColor3 = Color3.fromRGB(45, 90, 45)
    btnToggle.BorderSizePixel  = 0
    btnToggle.Font             = Enum.Font.SourceSansSemibold
    btnToggle.Text             = "Enabled"
    btnToggle.TextSize         = 14
    btnToggle.TextColor3       = Color3.new(1, 1, 1)
    btnToggle.Parent           = top
    local btc = Instance.new("UICorner")
    btc.CornerRadius = UDim.new(0, 6)
    btc.Parent       = btnToggle

    local log = Instance.new("ScrollingFrame")
    log.Name              = "Log"
    log.Position          = UDim2.new(0, 4, 0, 34)
    log.Size              = UDim2.new(1, -8, 1, -38)
    log.BackgroundColor3  = Color3.fromRGB(20, 20, 22)
    log.BorderSizePixel   = 0
    log.ScrollBarThickness = 6
    log.CanvasSize        = UDim2.new(0, 0, 0, 0)
    log.Parent            = main
    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 6)
    lc.Parent       = log

    local layout = Instance.new("UIListLayout")
    layout.Padding       = UDim.new(0, 2)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder     = Enum.SortOrder.LayoutOrder
    layout.Parent        = log

    local function addLog(text)
        local row = Instance.new("TextLabel")
        row.BackgroundTransparency = 1
        row.Size             = UDim2.new(1, -4, 0, 18)
        row.Font             = Enum.Font.SourceSans
        row.TextSize         = 13
        row.TextXAlignment   = Enum.TextXAlignment.Left
        row.TextColor3       = Color3.new(1, 1, 1)
        row.Text             = text
        row.Parent           = log
        log.CanvasSize       = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end

    KS_RSpy.AddLog = addLog

    btnToggle.MouseButton1Click:Connect(function()
        KS_RSpy.Enabled = not KS_RSpy.Enabled
        btnToggle.Text = KS_RSpy.Enabled and "Enabled" or "Disabled"
        btnToggle.BackgroundColor3 = KS_RSpy.Enabled and Color3.fromRGB(45, 90, 45) or Color3.fromRGB(90, 45, 45)
    end)

    btnClose.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    makeDraggable(top, main)
    KS_RSpy.Gui = gui
end

do
    local hook = rawget(getfenv(), "hookmetamethod") or hookmetamethod
    local getncm = rawget(getfenv(), "getnamecallmethod") or getnamecallmethod
    if hook and getncm then
        local old
        old = hook(game, "__namecall", function(self, ...)
            local method = getncm()
            if KS_RSpy.Enabled and (method == "FireServer" or method == "InvokeServer") then
                if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                    local args = {...}
                    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, args)
                    if ok and KS_RSpy.AddLog then
                        KS_RSpy.AddLog(("[%s] %s(%s)"):format(method, self:GetFullName(), encoded))
                    end
                end
            end
            return old(self, ...)
        end)
    else
        warn("[KoroneRemoteSpy] hookmetamethod/getnamecallmethod not available; executor too weak.")
    end
end

function KS_RSpy.Toggle()
    createGui()
    KS_RSpy.Gui.Enabled = not KS_RSpy.Gui.Enabled
end

_G.KS_RSpy = KS_RSpy
