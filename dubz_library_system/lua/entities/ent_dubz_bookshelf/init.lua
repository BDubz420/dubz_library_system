AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_interiors/Furniture_shelf01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysWake()

    self.Slots = {}
    self.Books = {}
    self.SlotPositions = {
        Vector(0, -19, 27), -- Top shelf left pos
        Vector(0, -16, 27),
        Vector(0, -13, 27),
        Vector(0, -10, 27),
        Vector(0, -7, 27),
        Vector(0, -4, 27),
        Vector(0, -1, 27),
        Vector(0, 1, 27),
        Vector(0, 4, 27),
        Vector(0, 7, 27),
        Vector(0, 10, 27),
        Vector(0, 13, 27),
        Vector(0, 16, 27),
        Vector(0, 19, 27), -- Top shelf right pos
        
        Vector(0, -19, 11), -- second down from top left side
        Vector(0, -16, 11),
        Vector(0, -13, 11),
        Vector(0, -10, 11),
        Vector(0, -7, 11),
        Vector(0, -4, 11),
        Vector(0, -1, 11),
        Vector(0, 1, 11),
        Vector(0, 4, 11),
        Vector(0, 7, 11),
        Vector(0, 10, 11),
        Vector(0, 13, 11),
        Vector(0, 16, 11),
        Vector(0, 19, 11), -- second down right side
        
        Vector(0, -19, -6), -- third down from top left side
        Vector(0, -16, -6),
        Vector(0, -13, -6),
        Vector(0, -10, -6),
        Vector(0, -7, -6),
        Vector(0, -4, -6),
        Vector(0, -1, -6),
        Vector(0, 1, -6),
        Vector(0, 4, -6),
        Vector(0, 7, -6),
        Vector(0, 10, -6),
        Vector(0, 13, -6),
        Vector(0, 16, -6),
        Vector(0, 19, -6), -- third down right side
        
        Vector(0, -19, -23), -- fourth down from top left side
        Vector(0, -16, -23),
        Vector(0, -13, -23),
        Vector(0, -10, -23),
        Vector(0, -7, -23),
        Vector(0, -4, -23),
        Vector(0, -1, -23),
        Vector(0, 1, -23),
        Vector(0, 4, -23),
        Vector(0, 7, -23),
        Vector(0, 10, -23),
        Vector(0, 13, -23),
        Vector(0, 16, -23),
        Vector(0, 19, -23), -- fourth down right side
        
        Vector(0, -19, -39), -- bottom shelf left side
        Vector(0, -16, -39),
        Vector(0, -13, -39),
        Vector(0, -10, -39),
        Vector(0, -7, -39),
        Vector(0, -4, -39),
        Vector(0, -1, -39),
        Vector(0, 1, -39),
        Vector(0, 4, -39),
        Vector(0, 7, -39),
        Vector(0, 10, -39),
        Vector(0, 13, -39),
        Vector(0, 16, -39),
        Vector(0, 19, -39), -- bottom shelf right side

    }

    for i = 1, #self.SlotPositions do
        self.Slots[i] = nil
    end
end


function ENT:GetClosestSlot(worldPos)
    local bestEmpty, bestDist = nil, math.huge
    local bestAny, bestAnyDist = nil, math.huge

    for i, offset in ipairs(self.SlotPositions) do
        local slotPos = self:LocalToWorld(offset)
        local d = slotPos:DistToSqr(worldPos)
        if d < bestAnyDist then
            bestAnyDist = d
            bestAny = i
        end
        if not self.Slots[i] and d < bestDist then
            bestDist = d
            bestEmpty = i
        end
    end

    if bestEmpty then return bestEmpty end

    if bestAny then
        local radius = 6
        for step = 1, #self.SlotPositions do
            local left = bestAny - step
            local right = bestAny + step
            if left >= 1 and not self.Slots[left] then return left end
            if right <= #self.SlotPositions and not self.Slots[right] then return right end
            if step >= radius then break end
        end
    end

    return nil
end

function ENT:ApplyBookToSlot(book, slotIndex, ply)
    if not IsValid(book) then return false end
    if not slotIndex or self.Slots[slotIndex] then return false end

    local offset = self.SlotPositions[slotIndex]
    local pos = self:LocalToWorld(offset)
    local ang = self:GetAngles()

    book:SetPos(pos)
    book:SetAngles(ang)
    book:SetParent(self)
    book:SetMoveType(MOVETYPE_NONE)
    book:SetSolid(SOLID_VPHYSICS)
    book:SetUseType(SIMPLE_USE)
    book:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    book:SetNWEntity("ShelfParent", self)
    if IsValid(ply) then
        book:SetNWEntity("BookOwner", ply)
    end

    self.Slots[slotIndex] = book
    return true
end

function ENT:PlaceBook(slotIndex, bookID, ply, model, unlocked)
    if not slotIndex then return false end
    if self.Slots[slotIndex] then return false end

    local book = ents.Create("ent_dubz_book_base")
    if not IsValid(book) then return false end

    book:SetBookID(bookID)
    book:SetBookModel(model or "models/props_lab/binderblue.mdl")
    book:SetNWBool("Unlocked", unlocked or false)
    book:Spawn()

    if not self:ApplyBookToSlot(book, slotIndex, ply) then
        book:Remove()
        return false
    end
    return true
end

function ENT:PlaceBookFromWeapon(slotIndex, wep, ply)
    if not IsValid(wep) then return false end
    local bookID = wep:GetNWString("BookID", "")
    if bookID == "" then return false end
    local model = wep.GetBookModel and wep:GetBookModel() or wep:GetNWString("BookModel", "models/props_lab/binderblue.mdl")
    local unlocked = wep:GetNWBool("Unlocked", false)
    return self:PlaceBook(slotIndex, bookID, ply, model, unlocked)
end

function ENT:RemoveBook(slotIndex, keepEntity)
    if not slotIndex or not self.Slots[slotIndex] then return end
    local book = self.Slots[slotIndex]
    self.Slots[slotIndex] = nil
    if IsValid(book) then
        book:SetNWEntity("ShelfParent", NULL)
        book:SetParent(nil)
        book:SetMoveType(MOVETYPE_VPHYSICS)
        book:SetSolid(SOLID_VPHYSICS)
        book:SetUseType(SIMPLE_USE)
        book:SetCollisionGroup(COLLISION_GROUP_NONE)
        if not keepEntity then
            book:Remove()
        end
    end
end
