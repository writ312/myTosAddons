local acutil = require('acutil')
local acutil = {}
RestoreQS = {
    author = 'writ',
    name = 'savequickslot',
    user = nil,    
}

function RestoreQS:new()
    self.settings = {}
    self.settingsFileLoc = string.format("../addons/%s/settings.json", string.lower(self.name))
 
    function self:save()
        acutil.saveJSON(self.settingsFileLoc, self.settings)
    end
    function self:load()
        local t, err = acutil.loadJSON(self.settingsFileLoc, self.settings)
        if err then
            self.settings = {}
        else
            self.settings = t
        end
    end
    function self:backup(index)
        local frame= ui.GetFrame("quickslotnexpbar")
        local list = {}
        for i = 1 , 40 do
            local slot = GET_CHILD_RECURSIVELY(frame, "slot"..srcIndex, "ui::CSlot")
            local icon = icon:GetIcon()
            if icon ~= nil then
                --add: type(skill or item), classId
                local obj = {}
                local iconInfo = slot:GetInfo()
                obj.category = iconInfo.category
                obj.invIndex = iconInfo.ext
                obj.type = iconInfo.type
                obj.guid = iconInfo:GetIESID()
            end
            table.insert(list,obj)
        end
        self.settings[self.user][index] = list
        self:save()
    end
    function self:restore(index)
        local list = self.settings[self.user][index]
        local frame= ui.GetFrame("quickslotnexpbar")
        for i = 1 , 40 do
            local slot = GET_CHILD_RECURSIVELY(frame, "slot"..i, "ui::CSlot")
            local obj = list[i]
            if obj then
                -- Check: can use skill.
                SET_QUICK_SLOT(slot, obj.category, obj.type, obj.guid, 1, true);
            end
        end
    end
    function self:updateUI()
        local setting = self.settings[self.user]

    end
end

setmetatable(RestoreQS, {__call = RestoreQS.new});
local restQS = RestoreQS()
restQS:load()

function RESTORE_QS_UPDATE_SLOTVIEW()
end

function RESTORE_QS_BTN_CLICK(frame,control,type,index)
-- type: backup, restore
    if type == "backup" then
        restQS:backup(index)
    elseif type == 'restore' then
        restQS:restore(list)
    end
end

function RESTORE_QS_OPEN()
end

function SAVEQUICKSLOT_ON_INIT(addon,frame)
    restQS.user = GETMYPCNAME()
end
