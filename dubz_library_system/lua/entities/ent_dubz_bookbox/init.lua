AddCSLuaFile("shared.lua")
include("shared.lua")

local BOOK_MODELS = {
    "models/props_lab/binderblue.mdl",
    "models/props_lab/bindergreen.mdl",
    "models/props_lab/binderredlabel.mdl",
    "models/props_lab/bindergraylabel01a.mdl"
}

function ENT:Initialize()
    self:SetModel("models/props_junk/cardboard_box002a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysWake()
end

function ENT:Use(ply)
    local keys = table.GetKeys(DubzLibrary.Tutorials)

    for i = 1, math.random(2, 4) do
        local id = table.Random(keys)
        local model = table.Random(BOOK_MODELS)

        local book = ents.Create("ent_dubz_book_base")
        if IsValid(book) then
            book:SetPos(self:GetPos() + VectorRand() * 10 + Vector(0, 0, 20))
            book:SetBookID(id)
            book:SetBookModel(model)
            book:SetNWBool("Unlocked", false)
            book:Spawn()
        end
    end

    DarkRP.notify(ply, 0, 4, "You unpacked books.")
    self:Remove()
end
