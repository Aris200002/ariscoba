--
-- Parser konfigurasi AI (lihat lua/AiChar/AiCompat.lua)
-- Binding C++: Classes/Systems/LuaBindings.hpp (MonAI, HeroAI, BulletAI, TrapAI, Transform, Clone, Battle)
--
local M = {}

local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

-- Tentukan jenis section dari judul "#...."
local function sectionKind(title)
    title = title:lower()
    if title:find('main') then return 'main' end
    if title:find('trap') then return 'trap' end
    if title:find('trans') then return 'transform' end
    if title:find('clone') or title:find('summon') then return 'clone' end
    if title:find('kugutsu') or title:find('kuchiyose') then return 'hero' end
    if title:find('mon') then return 'mon' end
    if title:find('bullet') or title:find('proj') then return 'bullet' end
    if title:find('char') or title:find('hero') then return 'hero' end
    return nil
end

function M.load(text)
    local section = nil
    local main = {}

    for rawLine in text:gmatch('[^\r\n]+') do
        -- buang komentar "-- ..." (satu baris penuh maupun di ujung baris)
        local line = trim((rawLine:gsub('%-%-.*$', '')))
        if line ~= '' then
            if line:sub(1, 1) == '#' then
                section = sectionKind(line:sub(2))
                if not section then
                    log('[AiCompat] section tidak dikenal: ' .. line)
                end
            elseif section == 'main' then
                for name in line:gmatch('[\'"]?([%w_]+)[\'"]?') do
                    main[#main + 1] = name
                end
            elseif section == 'clone' then
                -- "Caster = {Nama, waktu}" atau "Caster = {Nama, id, waktu}"
                local caster, body = line:match('^([%w_]+)%s*=%s*{(.-)}$')
                local parts = {}
                if body then
                    for part in body:gmatch('[^,]+') do
                        part = trim(part):gsub('^[\'"]', ''):gsub('[\'"]$', '')
                        parts[#parts + 1] = part
                    end
                end
                local cname = parts[1]
                local n2, n3 = tonumber(parts[2]), tonumber(parts[3])
                if caster and cname and cname:match('^[%w_]+$') and #parts == 2 and n2 then
                    Clone.add(caster, cname, n2)
                elseif caster and cname and cname:match('^[%w_]+$') and #parts == 3 and n2 and n3 then
                    Clone.add(caster, cname, n2, n3)
                else
                    log('[AiCompat] baris tidak valid: ' .. line)
                end
            elseif section == 'hero' or section == 'mon' or section == 'bullet' or section == 'transform' or section == 'trap' then
                -- "Nama = AI" atau (khusus Mons) "Nama = AI, Master, MonSambungan"
                -- ("-" berarti kosong)
                local name, rest = line:match('^([%w_]+)%s*=%s*(.+)$')
                local ai, owner, link
                if name then
                    local parts = {}
                    for part in rest:gmatch('[^,]+') do
                        part = trim(part):gsub('^[\'"]', ''):gsub('[\'"]$', '')
                        parts[#parts + 1] = part
                    end
                    ai = parts[1]
                    owner = parts[2]
                    link = parts[3]
                    if owner == '-' then owner = nil end
                    if link == '-' then link = nil end
                    if not ai or not ai:match('^[%w_]+$') then name = nil end
                end
                if name then
                    if section == 'hero' then
                        HeroAI.clone(name, ai)
                    elseif section == 'mon' then
                        MonAI.clone(name, ai, owner, link)
                    elseif section == 'trap' then
                        TrapAI.clone(name, ai, owner)
                    elseif section == 'transform' then
                        Transform.clone(name, ai)
                    else
                        BulletAI.clone(name, ai, owner)
                    end
                else
                    log('[AiCompat] baris tidak valid: ' .. line)
                end
            end
        end
    end

    -- Main characters: menggantikan daftar karakter battle bawaan
    if #main > 0 then
        for _, name in ipairs(Battle.chars()) do Battle.removeChar(name) end
        Battle.addChars(main)
        -- jaga-jaga: jangan sampai pool kosong
        if #Battle.chars() == 0 then Battle.resetChars() end
    end
end

return M
