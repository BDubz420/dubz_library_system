DubzLibrary = DubzLibrary or {}

DubzLibrary.Tutorials = {
    ["meth"] = {
        name = "Meth Cooking Guide",
        pages = {
            [[
                <h1>Meth Cooking Guide</h1>
                <p><b>Step 1:</b> Buy a lab</p>
                <p><b>Step 2:</b> Get ingredients</p>
            ]],
            [[
                <h1>Safety</h1>
                <p><b>Step 3:</b> Don't explode</p>
            ]]
        },
        price = 150
    }
}

DubzLibrary.Shelf = DubzLibrary.Shelf or {
    MaxSlots = 6,
    EarnPerUse = 25
}

DubzLibrary.Checkout = DubzLibrary.Checkout or {
    MaxBooks = 6
}

function DubzLibrary.GetBookData(id)
    if not id or id == "" then return nil end
    return DubzLibrary.Tutorials[id]
end

function DubzLibrary.IsLibrarian(ply)
    if not IsValid(ply) then return false end
    local job = ""
    if ply.getDarkRPVar then
        job = string.lower(tostring(ply:getDarkRPVar("job") or ""))
    end
    if job == "" and ply.Team then
        job = string.lower(tostring(team.GetName(ply:Team()) or ""))
    end
    return string.find(job, "librar", 1, true) ~= nil or string.find(job, "library", 1, true) ~= nil
end

function DubzLibrary.CanReadBookObject(obj, ply)
    if not IsValid(ply) then return false end
    if not IsValid(obj) then return false end
    if obj:GetNWBool("Unlocked", false) then return true end
    if DubzLibrary.IsLibrarian(ply) then return true end
    return false
end

function DubzLibrary.ApplyEntityBookState(ent, src)
    if not IsValid(ent) or not IsValid(src) then return end
    ent:SetBookID(src:GetNWString("BookID", ""))
    if ent.SetBookModel then
        local model = src.GetBookModel and src:GetBookModel() or src:GetNWString("BookModel", src:GetModel() or "models/props_lab/binderblue.mdl")
        ent:SetBookModel(model)
    end
    ent:SetNWBool("Unlocked", src:GetNWBool("Unlocked", false))
end

function DubzLibrary.ApplyWeaponBookState(wep, src, ply)
    if not IsValid(wep) or not IsValid(src) then return end
    wep:SetBookID(src:GetNWString("BookID", ""))
    if wep.SetBookModel then
        local model = src.GetBookModel and src:GetBookModel() or src:GetNWString("BookModel", src:GetModel() or "models/props_lab/binderblue.mdl")
        wep:SetBookModel(model)
    end
    wep:SetNWBool("Unlocked", src:GetNWBool("Unlocked", false))
    wep:SetNWBool("LibraryAccess", DubzLibrary.IsLibrarian(ply))
end

if SERVER then
    util.AddNetworkString("DubzLibrary_PlaceBook")
    util.AddNetworkString("DubzLibrary_PlaceBookOnDesk")
    util.AddNetworkString("DubzLibrary_OpenBook")

    local function PlayerCooldown(ply, key, delay)
        if not IsValid(ply) then return false end
        ply.DubzLibraryCooldowns = ply.DubzLibraryCooldowns or {}
        local t = CurTime()
        local nextTime = ply.DubzLibraryCooldowns[key] or 0
        if nextTime > t then return false end
        ply.DubzLibraryCooldowns[key] = t + delay
        return true
    end

    net.Receive("DubzLibrary_PlaceBook", function(_, ply)
        if not PlayerCooldown(ply, "place_book_shelf", 0.45) then return end

        local shelf = net.ReadEntity()
        local hitPos = net.ReadVector()

        if not IsValid(shelf) or shelf:GetClass() ~= "ent_dubz_bookshelf" then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_dubz_book" then return end

        local slot = shelf:GetClosestSlot(hitPos)
        if not slot then
            DarkRP.notify(ply, 1, 4, "No free shelf slot nearby.")
            return
        end

        if shelf:PlaceBookFromWeapon(slot, wep, ply) then
            ply:StripWeapon("weapon_dubz_book")
            DarkRP.notify(ply, 0, 4, "Book placed on shelf.")
        else
            DarkRP.notify(ply, 1, 4, "Could not place book on shelf.")
        end
    end)

    net.Receive("DubzLibrary_PlaceBookOnDesk", function(_, ply)
        if not PlayerCooldown(ply, "place_book_desk", 0.45) then return end

        local desk = net.ReadEntity()
        if not IsValid(desk) or desk:GetClass() ~= "ent_dubz_checkout" then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_dubz_book" then return end

        if wep:GetNWBool("Unlocked", false) then
            DarkRP.notify(ply, 1, 4, "This book is already unlocked.")
            return
        end

        local bookID = wep:GetNWString("BookID", "")
        if bookID == "" then return end

        local book = ents.Create("ent_dubz_book_base")
        if not IsValid(book) then return end

        DubzLibrary.ApplyEntityBookState(book, wep)
        book:Spawn()

        local ok, msg = desk:AddBook(book, ply)
        if ok then
            ply:StripWeapon("weapon_dubz_book")
            DarkRP.notify(ply, 0, 4, "Book placed on counter.")
        else
            book:Remove()
            if msg and msg ~= "" then
                DarkRP.notify(ply, 1, 4, msg)
            end
        end
    end)

    hook.Add("PlayerUse", "DubzLibrary_PickupBooks", function(ply, ent)
        if not IsValid(ply) or not IsValid(ent) then return end

        local bookID = ent:GetNWString("BookID", "")
        if bookID == "" then return end

        if not PlayerCooldown(ply, "pickup_book_use", 0.35) then
            return true
        end

        if ply:HasWeapon("weapon_dubz_book") then
            DarkRP.notify(ply, 1, 4, "You're already holding a book.")
            return true
        end

        local shelf = ent:GetNWEntity("ShelfParent")
        if IsValid(shelf) and shelf:GetClass() == "ent_dubz_bookshelf" then
            for slotIdx, bookEnt in pairs(shelf.Slots or {}) do
                if bookEnt == ent then
                    shelf:RemoveBook(slotIdx, true)
                    break
                end
            end

            ply:Give("weapon_dubz_book")
            local wep = ply:GetWeapon("weapon_dubz_book")
            if IsValid(wep) then
                DubzLibrary.ApplyWeaponBookState(wep, ent, ply)
            end
            ply:SelectWeapon("weapon_dubz_book")

            if ent:GetNWBool("Unlocked", false) then
                DarkRP.notify(ply, 0, 4, "Book picked up.")
            elseif DubzLibrary.IsLibrarian(ply) then
                DarkRP.notify(ply, 0, 4, "Book picked up with library access.")
            else
                DarkRP.notify(ply, 1, 4, "Take this to checkout to purchase it.")
            end

            if IsValid(ent) then ent:Remove() end
            return true
        end

        local parent = ent:GetParent()
        if IsValid(parent) and parent:GetClass() == "ent_dubz_checkout" then
            local removedIndex = nil
            for i, data in ipairs(parent.Books or {}) do
                if data.entity == ent then
                    removedIndex = i
                    break
                end
            end

            if removedIndex then
                table.remove(parent.Books, removedIndex)
            end

            ply:Give("weapon_dubz_book")
            local wep = ply:GetWeapon("weapon_dubz_book")
            if IsValid(wep) then
                DubzLibrary.ApplyWeaponBookState(wep, ent, ply)

                wep:SetNWBool("Unlocked", ent:GetNWBool("Unlocked", false))
            end
            ply:SelectWeapon("weapon_dubz_book")

            if IsValid(ent) then ent:Remove() end

            parent:CleanBooks()
            parent:RebuildStack()
            parent:RefreshOccupant()

            if wep and IsValid(wep) and wep:GetNWBool("Unlocked", false) then
                DarkRP.notify(ply, 0, 4, "Book picked up from counter.")
            elseif DubzLibrary.IsLibrarian(ply) then
                DarkRP.notify(ply, 0, 4, "Book picked up with library access.")
            else
                DarkRP.notify(ply, 1, 4, "Take this to checkout to purchase it.")
            end
            return true
        end

        if ent:GetClass() == "ent_dubz_book_base" then
            ply:Give("weapon_dubz_book")
            local wep = ply:GetWeapon("weapon_dubz_book")
            if IsValid(wep) then
                DubzLibrary.ApplyWeaponBookState(wep, ent, ply)
            end
            ply:SelectWeapon("weapon_dubz_book")
            ent:Remove()

            if wep and IsValid(wep) and wep:GetNWBool("Unlocked", false) then
                DarkRP.notify(ply, 0, 4, "Book picked up.")
            elseif DubzLibrary.IsLibrarian(ply) then
                DarkRP.notify(ply, 0, 4, "Book picked up with library access.")
            else
                DarkRP.notify(ply, 1, 4, "Take this to checkout to purchase it.")
            end
            return true
        end
    end)
end
