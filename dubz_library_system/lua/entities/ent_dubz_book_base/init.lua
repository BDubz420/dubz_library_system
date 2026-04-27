AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local model = self:GetNWString("BookModel", "models/props_lab/binderblue.mdl")
    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysWake()
    if self:GetNWBool("Unlocked", nil) == nil then
        self:SetNWBool("Unlocked", false)
    end
end

function ENT:SetBookID(id)
    self.BookID = id
    self:SetNWString("BookID", id or "")
end

function ENT:GetBookID()
    return self:GetNWString("BookID", "")
end

function ENT:SetBookModel(model)
    model = model or "models/props_lab/binderblue.mdl"
    self:SetNWString("BookModel", model)
    if self:GetModel() ~= model then
        self:SetModel(model)
    end
end

function ENT:GetBookModel()
    return self:GetNWString("BookModel", "models/props_lab/binderblue.mdl")
end
