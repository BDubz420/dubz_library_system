include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

net.Receive("DubzLibrary_OpenBook", function()
    local title = net.ReadString()
    local pages = net.ReadTable()

    local frame = vgui.Create("DFrame")
    frame:SetSize(950, 620)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)

    local currentPage = 1

    -- 🎨 Book background
    frame.Paint = function(self, w, h)
        -- outer cover
        draw.RoundedBox(8, 0, 0, w, h, Color(50, 35, 20))

        -- pages
        draw.RoundedBox(6, 10, 10, w - 20, h - 20, Color(235, 225, 200))

        -- center seam
        draw.RoundedBox(0, w/2 - 3, 20, 6, h - 40, Color(120, 100, 70))
    end

    -- ✖ Close button
    local close = vgui.Create("DButton", frame)
    close:SetSize(28, 28)
    close:SetPos(frame:GetWide() - 38, 12)
    close:SetText("✕")
    close.DoClick = function() frame:Close() end

    -- 📖 Title
    local titleLabel = vgui.Create("DLabel", frame)
    titleLabel:SetText(title)
    titleLabel:SetFont("Trebuchet24")
    titleLabel:SetColor(Color(40, 30, 20))
    titleLabel:SizeToContents()
    titleLabel:SetPos(frame:GetWide()/2 - titleLabel:GetWide()/2, 20)

    -- 🧾 HTML wrapper (book styling)
    local function WrapHTML(content)
        return [[
            <html>
            <body style="
                background-color:#ebe1c8;
                font-family:'Georgia';
                color:#2b1d0e;
                padding:20px;
                line-height:1.6;
            ">
                <style>
                    h1 {
                        text-align:center;
                        font-size:24px;
                        margin-bottom:15px;
                    }
                    p {
                        font-size:16px;
                        margin:8px 0;
                    }
                </style>
        ]] .. content .. [[
            </body>
            </html>
        ]]
    end

    -- 📄 Left page
    local left = vgui.Create("DHTML", frame)
    left:SetPos(30, 70)
    left:SetSize(400, 500)

    -- 📄 Right page
    local right = vgui.Create("DHTML", frame)
    right:SetPos(frame:GetWide()/2 + 20, 70)
    right:SetSize(400, 500)

    -- 🔄 Render pages
    local function Render()
        left:SetHTML(WrapHTML(pages[currentPage] or ""))
        right:SetHTML(WrapHTML(pages[currentPage + 1] or ""))
    end

    Render()

    -- 🔄 Page flipping
    frame.OnMousePressed = function(self, code)
        if code == MOUSE_RIGHT then
            currentPage = math.min(currentPage + 2, #pages)
            Render()
        elseif code == MOUSE_LEFT then
            currentPage = math.max(currentPage - 2, 1)
            Render()
        end
    end

    -- 🔢 Page numbers
    local function DrawPageNumbers()
        local leftNum = vgui.Create("DLabel", frame)
        leftNum:SetText(tostring(currentPage))
        leftNum:SetColor(Color(90, 70, 50))
        leftNum:SizeToContents()
        leftNum:SetPos(400, 570)

        local rightNum = vgui.Create("DLabel", frame)
        rightNum:SetText(tostring(currentPage + 1))
        rightNum:SetColor(Color(90, 70, 50))
        rightNum:SizeToContents()
        rightNum:SetPos(frame:GetWide()/2 + 350, 570)
    end

    DrawPageNumbers()
end)

hook.Add("HUDPaint", "DubzLibrary_BookLookInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not tr or not IsValid(tr.Entity) then return end

    local ent = tr.Entity

    -- Resolve correct entity (handles shelf/desk parenting)
    if ent:GetClass() ~= "ent_dubz_book_base" then
        if IsValid(ent:GetParent()) and ent:GetParent():GetClass() == "ent_dubz_book_base" then
            ent = ent:GetParent()
        else
            for _, child in ipairs(ent:GetChildren()) do
                if IsValid(child) and child:GetClass() == "ent_dubz_book_base" then
                    ent = child
                    break
                end
            end
        end
    end

    if not IsValid(ent) or ent:GetClass() ~= "ent_dubz_book_base" then return end

    if ply:GetPos():DistToSqr(ent:GetPos()) > (150 * 150) then return end

    local id = ent:GetNWString("BookID", "")
    if id == "" then return end

    local data = DubzLibrary.Tutorials[id]
    if not data then return end

    local unlocked = ent:GetNWBool("Unlocked", false)

    local color = unlocked and Color(120,255,120) or Color(255,180,120)
    local status = unlocked and "UNLOCKED" or "LOCKED"

    local y = ScrH()/2 + 40

    draw.SimpleTextOutlined(
        data.name .. " - $" .. tostring(data.price or 0),
        "Trebuchet24",
        ScrW()/2,
        y,
        color,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,
        1,
        color_black
    )

    draw.SimpleTextOutlined(
        status,
        "Trebuchet18",
        ScrW()/2,
        y + 24,
        color,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,
        1,
        color_black
    )
end)