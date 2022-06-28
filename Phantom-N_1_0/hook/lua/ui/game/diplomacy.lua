--*****************************************************************************
--* Summary: UI for the diplomacy control
--*          Hook for Phantom by novaprim3
--*****************************************************************************

local shareResources = false
local alliedVictory = false
lockTeams = false

function BuildPlayerLines()
    local sessionOptions = SessionGetScenarioInfo().Options

    if table.getsize(parent.Items) > 0 then
        for i, _ in parent.Items do
            local index = i
            parent.Items[index]:Destroy()
            parent.Items[index] = nil
        end
        if parent.alliedBG then
            parent.alliedBG:Destroy()
        end
        if parent.enemyBG then
            parent.enemyBG:Destroy()
        end
    end
    local function CreateEntry(data, isAlly)
        local entry = Bitmap(parent)
        entry.Depth:Set(function() return parent.Depth() + 10 end)
        entry:SetSolidColor('00000000')
        
        entry.typeIcon = Bitmap(entry)
        LayoutHelpers.AtLeftIn(entry.typeIcon, entry)
        if data.human then
            entry.typeIcon:SetTexture(UIUtil.UIFile('/game/options-diplomacy-panel/icon-person_bmp.dds'))
        else
            entry.typeIcon:SetTexture(UIUtil.UIFile('/game/options-diplomacy-panel/icon-ai_bmp.dds'))
        end
        
        entry.factionIcon = Bitmap(entry)
        LayoutHelpers.RightOf(entry.factionIcon, entry.typeIcon)
        LayoutHelpers.AtTopIn(entry.factionIcon, entry, 1)
        LayoutHelpers.AtVerticalCenterIn(entry.typeIcon, entry.factionIcon)
        
        entry.color = Bitmap(entry.factionIcon)
        LayoutHelpers.FillParent(entry.color, entry.factionIcon)
        entry.color.Depth:Set(function() return entry.factionIcon.Depth() - 1 end)
        
        if data.outOfGame then
            entry.factionIcon:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
            entry.color:SetSolidColor('ff000000')
        else
            entry.factionIcon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
            entry.color:SetSolidColor(data.color)
        end
        entry.name = UIUtil.CreateText(entry, data.nickname, 16, UIUtil.bodyFont)
        entry.name.Right:Set(entry.Right)
        LayoutHelpers.RightOf(entry.name, entry.factionIcon, 5)
        LayoutHelpers.AtTopIn(entry.name, entry.factionIcon)
        entry.name:SetClipToWidth(true)
        
        entry.Data = data
        #LOG('Making entry for: ', repr(data))
        if isAlly then
            if data.human and not data.outOfGame then
                entry.giveUnitBtn = UIUtil.CreateButton(entry, 
                    '/dialogs/toggle_btn/toggle-d_btn_up.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_down.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_over.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_dis.dds', 
                    '<LOC diplomacy_0011>Units', 12)
                entry.giveUnitBtn.label:SetFont(UIUtil.bodyFont, 12)
                LayoutHelpers.Below(entry.giveUnitBtn, entry.factionIcon, -2)
                LayoutHelpers.AtLeftIn(entry.giveUnitBtn, entry)
                entry.giveUnitBtn.OnClick = function(self, modifiers)
                    UIUtil.QuickDialog(GetFrame(0), LOCF("<LOC unitxfer_0000>Give Selected Units to %s?", entry.Data.nickname), 
                        '<LOC _Yes>', function() 
                            SimCallback({Func="GiveUnitsToPlayer", Args={ From=GetFocusArmy(), To=entry.Data.armyIndex},} , true)
                        end, 
                        '<LOC _No>', nil, nil, nil, nil, {worldCover = false, enterButton = 1, escapeButton = 2})
                end
                Tooltip.AddButtonTooltip(entry.giveUnitBtn, 'dip_give_units')
                
                entry.giveResourcesBtn = UIUtil.CreateButton(entry, 
                    '/dialogs/toggle_btn/toggle-d_btn_up.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_down.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_over.dds', 
                    '/dialogs/toggle_btn/toggle-d_btn_dis.dds', 
                    '<LOC diplomacy_0012>Resources', 12)
                entry.giveResourcesBtn.label:SetFont(UIUtil.bodyFont, 12)
                LayoutHelpers.RightOf(entry.giveResourcesBtn, entry.giveUnitBtn)
                entry.giveResourcesBtn.OnClick = function(self, modifiers)
                    CreateShareResourcesDialog(entry)
                end
                Tooltip.AddButtonTooltip(entry.giveResourcesBtn, 'dip_give_resources')
            end
            
            #if sessionOptions and sessionOptions.TeamLock == "locked" then
            #else
                if not data.outOfGame then
                    entry.breakBtn = UIUtil.CreateButton(entry, 
                        '/dialogs/toggle_btn/toggle-d_btn_up.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_down.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_over.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                        '<LOC diplomacy_0013>Break', 12)
                    entry.breakBtn.label:SetFont(UIUtil.bodyFont, 12)
                    LayoutHelpers.Below(entry.breakBtn, entry.factionIcon, -2)
                    LayoutHelpers.AtRightIn(entry.breakBtn, entry)
                    LayoutHelpers.ResetLeft(entry.breakBtn)
                    entry.breakBtn.OnClick = function(self, checked)
                        SimCallback({Func = 'DiplomacyHandler', Args = {Action = 'break', From = GetFocusArmy(), To = data.armyIndex}})
                        ForkThread(function()
                            WaitSeconds(1)
                            BuildPlayerLines()
                        end)
                    end
                    Tooltip.AddButtonTooltip(entry.breakBtn, 'dip_break_alliance')
                end
            #end
        elseif data.human then
            #if sessionOptions and sessionOptions.TeamLock == "locked" then
            #else
                if not data.outOfGame then
                    entry.offerBtn = UIUtil.CreateButton(entry, 
                        '/dialogs/toggle_btn/toggle-d_btn_up.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_down.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_over.dds', 
                        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
                        '<LOC diplomacy_0014>Offer', 12)
                    entry.offerBtn.label:SetFont(UIUtil.bodyFont, 12)
                    LayoutHelpers.AtRightIn(entry.offerBtn, entry)
                    LayoutHelpers.AtBottomIn(entry.offerBtn, entry)
                    entry.offerBtn.OnClick = function(self, checked)
                        self:Disable()
                        SimCallback({Func = 'DiplomacyHandler', Args = {Action = 'offer', From = GetFocusArmy(), To = data.armyIndex}})
                    end
                    Tooltip.AddButtonTooltip(entry.offerBtn, 'dip_offer_alliance')
                end
            #end
        end
        
        entry.Height:Set(function()
                if (isAlly or data.human) and not data.outOfGame then
                    return 40
                else
                    return entry.factionIcon.Height() + 4
                end
            end)
        entry.Width:Set(function() return parent.Width() - 20 end)
        
        return entry
    end
    # end CreateEntry()
    
    parent.Items = {}
    
    local allyControls = {}
    local enemyControls = {}
    
    local i = 1
    for index, playerInfo in GetArmiesTable().armiesTable do
        if playerInfo.civilian or index == GetFocusArmy() then continue end
        playerInfo.armyIndex = index
        if IsAlly(GetFocusArmy(), index) then
            table.insert(allyControls, playerInfo)
        else
            table.insert(enemyControls, playerInfo)
        end
        i = i + 1
    end
    
    i = 1
    if table.getn(allyControls) > 0 then
        parent.Items[i] = UIUtil.CreateText(parent, LOC('<LOC diplomacy_0002>Allies'), 18, UIUtil.bodyFont)
        parent.Items[i]:SetColor('ff00ff72')
        parent.Items[i]:SetDropShadow(true)
        parent.Items[i].Depth:Set(function() return parent.Depth() + 10 end)
        LayoutHelpers.AtLeftTopIn(parent.Items[i], parent, 8, 10)
        
        #parent.Items[i].srCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/game/toggle_btn/toggle')
        #parent.Items[i].srCheck.label = Bitmap(parent.Items[i].srCheck, UIUtil.UIFile('/game/toggle_btn/icon-shared-resources_bmp.dds'))
        #parent.Items[i].srCheck.label:DisableHitTest()
        #LayoutHelpers.AtCenterIn(parent.Items[i].srCheck.label, parent.Items[i].srCheck)
        #parent.Items[i].srCheck:SetCheck(shareResources, true)
        #parent.Items[i].srCheck.OnCheck = function(self, checked)
        #    shareResources = checked
        #    SimCallback( {  Func = "SetResourceSharing",
        #                    Args = { Army = GetFocusArmy(),
        #                             Value = checked,
        #                           }
        #                 }
        #               )
        #end
        #Tooltip.AddCheckboxTooltip(parent.Items[i].srCheck, 'dip_share_resources')
        
        #parent.Items[i].avCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/game/toggle_btn/toggle')
        #parent.Items[i].avCheck.label = Bitmap(parent.Items[i].avCheck, UIUtil.UIFile('/game/toggle_btn/icon-allied-victory_bmp.dds'))
        #parent.Items[i].avCheck.label:DisableHitTest()
        #LayoutHelpers.AtCenterIn(parent.Items[i].avCheck.label, parent.Items[i].avCheck)
        #parent.Items[i].avCheck:SetCheck(alliedVictory, true)
        #parent.Items[i].avCheck.OnCheck = function(self, checked)
        #    alliedVictory = checked
        #    SimCallback( {  Func = "RequestAlliedVictory",
        #                    Args = { Army = GetFocusArmy(),
        #                             Value = checked,
        #                           }
        #                 }
        #               )
        #end
        #Tooltip.AddCheckboxTooltip(parent.Items[i].avCheck, 'dip_allied_victory')
        
        #LayoutHelpers.AtRightTopIn(parent.Items[i].srCheck, parent, 2, 6)
        #LayoutHelpers.LeftOf(parent.Items[i].avCheck, parent.Items[i].srCheck)
        
        i = i + 1
        local lastAllyControl = false
        for index, info in allyControls do
            parent.Items[i] = CreateEntry(info, true)
            LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 12)
            if table.getsize(allyControls) != index then
                parent.Items[i].Seperator = Bitmap(parent.Items[i], UIUtil.UIFile('/game/options-diplomacy-panel/line-allies_bmp.dds'))
                local curI = i
                parent.Items[i].Seperator.Top:Set(function() return parent.Items[curI].Bottom() + 12 end)
                LayoutHelpers.AtHorizontalCenterIn(parent.Items[i].Seperator, parent.Items[i], 2)
            end
            lastAllyControl = parent.Items[i]
            i = i + 1
        end
        
        parent.alliedBG = Bitmap(parent, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_t.dds'))
        parent.alliedBG.Top:Set(function() return parent.Top() + 2 end)
        parent.alliedBG.Left:Set(parent.Left)
        
        parent.alliedBG.bottomBG = Bitmap(parent.alliedBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_b.dds'))
        parent.alliedBG.bottomBG.Depth:Set(parent.alliedBG.Depth)
        parent.alliedBG.bottomBG.Left:Set(parent.alliedBG.Left)
        parent.alliedBG.bottomBG.Top:Set(function() return lastAllyControl.Bottom() + 5 end)
        
        parent.alliedBG.middleBG = Bitmap(parent.alliedBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-allies_bmp_m.dds'))
        parent.alliedBG.middleBG.Depth:Set(parent.alliedBG.Depth)
        parent.alliedBG.middleBG.Top:Set(parent.alliedBG.Bottom)
        parent.alliedBG.middleBG.Left:Set(parent.alliedBG.Left)
        parent.alliedBG.middleBG.Bottom:Set(parent.alliedBG.bottomBG.Top)
    end
    
    parent.Items[i] = UIUtil.CreateText(parent, LOC('<LOC diplomacy_0003>Enemies'), 18, UIUtil.bodyFont)
    parent.Items[i].Depth:Set(function() return parent.Depth() + 10 end)
    parent.Items[i]:SetDropShadow(true)
    parent.Items[i]:SetColor('ffff3c00')
    
    local enemyTitle = parent.Items[i]
    local lastEnemyControl = false
    
    if SessionGetScenarioInfo().Options.Ranked then
        parent.Items[i].odCheck = UIUtil.CreateCheckboxStd(parent.Items[i], '/dialogs/toggle_btn/toggle')
        parent.Items[i].odCheck.label = UIUtil.CreateText(parent.Items[i].odCheck, LOC('<LOC _Draw>Draw'), 12, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(parent.Items[i].odCheck.label, parent.Items[i].odCheck)
        Tooltip.AddCheckboxTooltip(parent.Items[i].odCheck, 'dip_offer_draw')
        parent.Items[i].odCheck:SetCheck(drawOffered, true)
        parent.Items[i].odCheck.OnCheck = function(self, checked)
            drawOffered = checked
            SimCallback( {  Func = "SetOfferDraw",
                            Args = { Army = GetFocusArmy(),
                                     Value = checked,
                                   }
                         }
                       )
            local msg = '<LOC diplomacy_0000>has offered a draw.'
            if not checked then
                msg = '<LOC diplomacy_0001>has rescinded their draw offer.'
            end
            SessionSendChatMessage({to = 'all', ConsoleOutput = msg})
        end
    end
    
    if i == 1 then
        LayoutHelpers.AtLeftTopIn(parent.Items[i], parent, 6, 10)
        if parent.Items[i].odCheck then
            LayoutHelpers.AtRightTopIn(parent.Items[i].odCheck, parent, 6, 8)
        end
    else
        LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 40)
        if parent.Items[i].odCheck then
            LayoutHelpers.AtTopIn(parent.Items[i].odCheck, parent.Items[i])
            LayoutHelpers.AtRightIn(parent.Items[i].odCheck, parent)
        end
    end
    i = i + 1
    for index, info in enemyControls do
        parent.Items[i] = CreateEntry(info)
        LayoutHelpers.Below(parent.Items[i], parent.Items[i-1], 2)
        lastEnemyControl = parent.Items[i]
        if table.getsize(enemyControls) != index then
            parent.Items[i].Seperator = Bitmap(parent.Items[i], UIUtil.UIFile('/game/options-diplomacy-panel/line-enemies_bmp.dds'))
            parent.Items[i].Seperator.Top:Set(parent.Items[i].Bottom)
            LayoutHelpers.AtHorizontalCenterIn(parent.Items[i].Seperator, parent.Items[i], 2)
        end
        i = i + 1
    end
    
    parent.enemyBG = Bitmap(parent, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_t.dds'))
    parent.enemyBG.Top:Set(function() return enemyTitle.Top() - 8 end)
    parent.enemyBG.Left:Set(parent.Left)
    parent.enemyBG.bottomBG = Bitmap(parent.enemyBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_b.dds'))
    parent.enemyBG.bottomBG.Depth:Set(parent.enemyBG.Depth)
    parent.enemyBG.bottomBG.Left:Set(parent.enemyBG.Left)
    parent.enemyBG.middleBG = Bitmap(parent.enemyBG, UIUtil.UIFile('/game/options-diplomacy-panel/panel-enemy_bmp_m.dds'))
    parent.enemyBG.middleBG.Depth:Set(parent.enemyBG.Depth)
    parent.enemyBG.middleBG.Top:Set(parent.enemyBG.Bottom)
    parent.enemyBG.middleBG.Left:Set(parent.enemyBG.Left)
    parent.enemyBG.middleBG.Bottom:Set(parent.enemyBG.bottomBG.Top)
    if lastEnemyControl then
        parent.enemyBG.bottomBG.Top:Set(function() return lastEnemyControl.Bottom() end)
    else
        parent.enemyBG.bottomBG.Top:Set(function() return enemyTitle.Bottom() end)
    end
        
    parent.Height:Set(function() 
            local height = 0
            for i, item in parent.Items do
                local index = i
                if i == 1 then
                    height = item.Height()
                else
                    height = height + (item.Bottom() - parent.Items[index-1].Bottom())
                end
            end
            return height + 10
        end)
end
