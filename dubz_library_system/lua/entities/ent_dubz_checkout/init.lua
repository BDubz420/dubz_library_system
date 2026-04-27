AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_interiors/Furniture_Desk01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysWake()

    local reg = ents.Create("prop_physics")
    reg:SetModel("models/props_c17/cashregister01a.mdl")
    reg:SetPos(self:GetPos() + self:GetForward() * 4 + self:GetUp() * 32 + self:GetRight() * 17)
    reg:SetAngles(self:GetAngles() + Angle(0, -90, 0))
    reg:SetParent(self)
    reg:SetMoveType(MOVETYPE_NONE)
    reg:SetSolid(SOLID_NONE)
    reg:Spawn()

    self.Register = reg
    self.Books = {}
    self.MaxBooks = DubzLibrary.Checkout.MaxBooks or 6
    self.NextUseTime = 0
    self.NextBusyNotify = 0
    self.Occupant = NULL
end

function ENT:CanUseNow()
    local t = CurTime()
    if (self.NextUseTime or 0) > t then return false end
    self.NextUseTime = t + 0.45
    return true
end

function ENT:NotifyBusy(ply, msg)
    local t = CurTime()
    if (self.NextBusyNotify or 0) > t then return end
    self.NextBusyNotify = t + 1.25
    if IsValid(ply) then
        DarkRP.notify(ply, 1, 4, msg)
    end
end

function ENT:CleanBooks()
    for i = #self.Books, 1, -1 do
        local data = self.Books[i]
        if not data or not IsValid(data.entity) then
            table.remove(self.Books, i)
        end
    end
end

function ENT:RefreshOccupant()
    self:CleanBooks()
    local occ = NULL
    for _, data in ipairs(self.Books) do
        if IsValid(data.buyer) and not DubzLibrary.IsLibrarian(data.buyer) then
            occ = data.buyer
            break
        end
    end
    self.Occupant = occ
end

function ENT:RebuildStack()
    for i, data in ipairs(self.Books) do
        local book = data.entity
        if not IsValid(book) then continue end
        local pos = self:GetPos() + self:GetRight() * -7 + self:GetForward() * -5 + self:GetUp() * (21 + (i - 1) * 2.5)
        book:SetParent(self)
        book:SetMoveType(MOVETYPE_NONE)
        book:SetSolid(SOLID_VPHYSICS)
        book:SetUseType(SIMPLE_USE)
        book:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        book:SetPos(pos)
        book:SetAngles(self:GetAngles() + Angle(0, 90, 90))
    end
end

function ENT:AddBook(book, buyer)
    self:CleanBooks()
    self:RefreshOccupant()

    if #self.Books >= self.MaxBooks then return false, "Counter is full." end
    if not IsValid(book) or not IsValid(buyer) then return false, "Invalid book." end

    if book:GetNWBool("Unlocked", false) then
        return false, "This book is already unlocked."
    end

    if IsValid(self.Occupant) and self.Occupant ~= buyer then
        return false, "Counter is occupied. Please wait your turn."
    end

    table.insert(self.Books, {
        entity = book,
        buyer = buyer
    })

    if not DubzLibrary.IsLibrarian(buyer) then
        self.Occupant = buyer
    end

    self:RebuildStack()
    return true
end

function ENT:GetCurrentPriceAndBuyer()
    self:CleanBooks()
    self:RefreshOccupant()

    if #self.Books == 0 then return 0, nil, 0 end

    local buyer = nil
    local total = 0
    local count = 0

    for _, data in ipairs(self.Books) do
        local book = data.entity
        if IsValid(book) and not book:GetNWBool("Unlocked", false) and IsValid(data.buyer) and not DubzLibrary.IsLibrarian(data.buyer) then
            buyer = data.buyer
            local t = DubzLibrary.GetBookData(book:GetNWString("BookID", ""))
            if t then
                total = total + (t.price or 0)
                count = count + 1
            end
        end
    end

    return total, buyer, count
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not self:CanUseNow() then return end

    self:CleanBooks()
    self:RefreshOccupant()

    if #self.Books == 0 then
        self:NotifyBusy(ply, "Wait for a customer to place a book here for sale.")
        return
    end

    local total, buyer, count = self:GetCurrentPriceAndBuyer()

    if count <= 0 then
        self:NotifyBusy(ply, "Clear the counter.")
        return
    end

    if not DubzLibrary.IsLibrarian(ply) then
        return
    end

    if not IsValid(buyer) then
        self:NotifyBusy(ply, "Wait for a customer to place a book here for sale.")
        return
    end

    if buyer == ply then
        self:NotifyBusy(ply, "Your own books do not need checkout.")
        return
    end

    if not buyer:canAfford(total) then
        DarkRP.notify(buyer, 1, 4, "You do not have enough money for these books.")
        DarkRP.notify(ply, 1, 4, "Customer does not have enough money.")
        return
    end

    buyer:addMoney(-total)
    ply:addMoney(total)

    for _, data in ipairs(self.Books) do
        local book = data.entity
        if IsValid(book) and data.buyer == buyer and not book:GetNWBool("Unlocked", false) then
            book:SetNWBool("Unlocked", true)
        end
    end

    DarkRP.notify(buyer, 0, 4, "Purchase completed. Pick up your books from the counter.")
    DarkRP.notify(ply, 0, 4, "Sale completed: $" .. total)

    self:RebuildStack()
end
