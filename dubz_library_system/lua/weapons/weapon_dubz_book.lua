if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Book"
SWEP.Author = "Lowkey Networks - BDubz420"
SWEP.Instructions = "Left click to place the book. Right click to read it."
SWEP.Category = "Dubz Library"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.HoldType = "slam"
SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:SetBookID(id)
    self.BookID = id
    self:SetNWString("BookID", id or "")
end

function SWEP:GetBookID()
    return self:GetNWString("BookID", "")
end

function SWEP:SetBookModel(model)
    self:SetNWString("BookModel", model or "models/props_lab/binderblue.mdl")
end

function SWEP:GetBookModel()
    return self:GetNWString("BookModel", "models/props_lab/binderblue.mdl")
end

function SWEP:CanReadNow()
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    return self:GetNWBool("Unlocked", false) or self:GetNWBool("LibraryAccess", false) or DubzLibrary.IsLibrarian(owner)
end

function SWEP:Deploy()
    if not SERVER then return true end
    if IsValid(self._bookModel) then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return true end

    local book = ents.Create("prop_physics")
    if not IsValid(book) then return true end

    book:SetModel(self:GetBookModel())
    book:SetPos(ply:GetPos() + ply:GetForward() * 10 + ply:GetUp() * 40)
    book:SetAngles(Angle(0, ply:EyeAngles().y + 90, 0))
    book:SetParent(ply)
    book:Fire("SetParentAttachmentMaintainOffset", "eyes", 0.01)
    book:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    book:Spawn()
    book:Activate()

    self._bookModel = book
    return true
end

local function SafeRemove(ent)
    if IsValid(ent) then ent:Remove() end
end

function SWEP:Holster()
    if SERVER then SafeRemove(self._bookModel) end
    return true
end

function SWEP:OnDrop()
    if SERVER then SafeRemove(self._bookModel) end
end

function SWEP:OnRemove()
    if SERVER then SafeRemove(self._bookModel) end
end

function SWEP:PrimaryAttack()
    if not CLIENT then return end
    self:SetNextPrimaryFire(CurTime() + 0.45)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) then return end

    local targetClass = tr.Entity:GetClass()
    if targetClass == "ent_dubz_bookshelf" then
        net.Start("DubzLibrary_PlaceBook")
            net.WriteEntity(tr.Entity)
            net.WriteVector(tr.HitPos)
        net.SendToServer()
    elseif targetClass == "ent_dubz_checkout" then
        net.Start("DubzLibrary_PlaceBookOnDesk")
            net.WriteEntity(tr.Entity)
        net.SendToServer()
    end
end

function SWEP:SecondaryAttack()
    if not SERVER then return end
    self:SetNextSecondaryFire(CurTime() + 0.45)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if not self:CanReadNow() then
        DarkRP.notify(ply, 1, 4, "You must purchase this book first.")
        return
    end

    local id = self:GetBookID()
    local data = DubzLibrary.GetBookData(id)
    if not data then return end

    net.Start("DubzLibrary_OpenBook")
        net.WriteString(data.name or "Unknown Book")
        net.WriteTable(data.pages or {})
    net.Send(ply)
end

function SWEP:Reload()
    if not SERVER then return end
    self:SetNextPrimaryFire(CurTime() + 0.45)
    self:SetNextSecondaryFire(CurTime() + 0.45)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local id = self:GetBookID()
    if id == "" then return end

    local book = ents.Create("ent_dubz_book_base")
    if not IsValid(book) then return end

    book:SetPos(ply:GetPos() + Vector(0, 0, 20))
    DubzLibrary.ApplyEntityBookState(book, self)
    book:Spawn()

    ply:StripWeapon("weapon_dubz_book")
    DarkRP.notify(ply, 0, 4, "Book dropped.")
end
