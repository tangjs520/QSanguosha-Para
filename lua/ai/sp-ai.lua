sgs.weapon_range.SPMoonSpear = 3

sgs.ai_skill_invoke.sp_moonspear = function(self, data)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitNoColor, 0)
	for _, target in ipairs(self.enemies) do
		if self.player:canSlash(target) and not self:slashProhibit(slash ,target) then
		return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.sp_moonspear = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_playerchosen_intention.sp_moonspear = 80

function sgs.ai_slash_prohibit.weidi(self, to, card)
	if to:isLord() then return false end
	local lord = self.room:getLord()
	for _, askill in sgs.qlist(lord:getVisibleSkillList()) do
		if askill:objectName() ~= "weidi" and askill:isLordSkill() then
			local filter = sgs.ai_slash_prohibit[askill:objectName()]
			if  type(filter) == "function" and filter(self, to, card) then return true end
		end
	end
end

sgs.ai_skill_discard.yongsi = function(self, discard_num, min_num, optional, include_equip)
	self:assignKeep(self.player:getHp(), true)
	if optional then return {} end
	local flag = "h"
	local equips = self.player:getEquips()
	if include_equip and not (equips:isEmpty() or self.player:isJilei(equips:first())) then flag = flag .. "e" end
	local cards = self.player:getCards(flag)
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") then
				for _, enemy in ipairs(self.enemies) do
					if enemy:canSlash(self.player) and self:isEquip("GudingBlade", enemy) then return 6 end
				end
				if self.player:isWounded() then
					return -2
				end
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then
				return 4
			end
		elseif self:hasSkills(sgs.lose_equip_skill) then
			return 5
		else
			return 0
		end
	end
	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num -1
	end
	for _, card in ipairs(cards) do
		if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then
			break
		end
		if not self.player:isJilei(card) then
			table.insert(to_discard, card:getId())
		end
	end
	return to_discard
end

sgs.ai_chaofeng.yuanshu = 3

sgs.ai_skill_invoke.danlao = function(self, data)
	local effect = data:toCardUse()
	local current = self.room:getCurrent()
	if effect.card:isKindOf("GodSalvation") and self.player:isWounded() then
		return false
	elseif effect.card:isKindOf("AmazingGrace") and
		(self.player:getSeat() - current:getSeat()) % (global_room:alivePlayerCount()) < global_room:alivePlayerCount()/2 then
		return false
	else
		return true
	end
end

sgs.ai_skill_invoke.jilei = function(self, data)
	local damage = data:toDamage()
	if not damage then return false end
	self.jilei_source = damage.from
	return self:isEnemy(damage.from)
end

sgs.ai_skill_choice.jilei = function(self, choices)
	local tmptrick = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuitNoColor, 0)
	if (self:isEquip("Crossbow",self.jilei_source) and self.jilei_source:inMyAttackRange(self.player)) or
		 self.jilei_source:isJilei(tmptrick) then
		return "basic"
	else
		return "trick"
	end
end

local function yuanhu_validate(self, equip_type, is_handcard)
	local is_SilverLion = false
	if equip_type == "SilverLion" then
		equip_type = "Armor"
		is_SilverLion = true
	end
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type ~= "Weapon" then
		if equip_type == "DefensiveHorse" or equip_type == "OffensiveHorse" then self:sort(targets, "hp") end
		if equip_type == "Armor" then self:sort(targets, "handcard") end
		if is_SilverLion then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
					local seat_diff = enemy:getSeat() - self.player:getSeat()
					local alive_count = self.room:alivePlayerCount()
					if seat_diff < 0 then seat_diff = seat_diff + alive_count end
					if seat_diff > alive_count / 2.5 + 1 then return enemy	end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("bazhen") or enemy:hasSkill("yizhong") then
					return enemy
				end
			end
		end
		for _, friend in ipairs(targets) do
			if not self:isEquip(equip_type, friend) then
				if equip_type == "Armor" then
					if not self:needKongcheng(friend) and not self:hasSkills("bazhen|yizhong", friend) then return friend end
				else
					if friend:isWounded() and not friend:hasSkill("longhun") then return friend end
				end
			end
		end
	else
		for _, friend in ipairs(targets) do
			if not self:isEquip(equip_type, friend) then
				for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
					if friend:distanceTo(aplayer) == 1 then
						if self:isFriend(aplayer) and not aplayer:containsTrick("YanxiaoCard")
							and (aplayer:containsTrick("indulgence") or aplayer:containsTrick("supply_shortage")
								or (aplayer:containsTrick("lightning") and self:hasWizard(self.enemies))) then
							self.room:setPlayerFlag(aplayer, "YuanhuToChoose")
							return friend
						end
					end
				end
				self:sort(self.enemies, "defense")
				for _, enemy in ipairs(self.enemies) do
					if friend:distanceTo(enemy) == 1 and not enemy:isNude() then
						self.room:setPlayerFlag(enemy, "YuanhuToChoose")
						return friend
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@yuanhu"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isEquip("SilverLion") and yuanhu_validate(self, "SilverLion", false) then
		local player = yuanhu_validate(self, "SilverLion", false)
		local card_id = self.player:getArmor():getEffectiveId()
		return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
	end
	if self.player:getOffensiveHorse() and yuanhu_validate(self, "OffensiveHorse", false) then
		local player = yuanhu_validate(self, "OffensiveHorse", false)
		local card_id = self.player:getOffensiveHorse():getEffectiveId()
		return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
	end
	if self.player:getWeapon() and yuanhu_validate(self, "Weapon", false) then
		local player = yuanhu_validate(self, "Weapon", false)
		local card_id = self.player:getWeapon():getEffectiveId()
		return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3
		and yuanhu_validate(self, "Armor", false) then
		local player = yuanhu_validate(self, "Armor", false)
		local card_id = self.player:getArmor():getEffectiveId()
		return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") and yuanhu_validate(self, "DefensiveHorse", true) then
			local player = yuanhu_validate(self, "DefensiveHorse", true)
			local card_id = card:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") and yuanhu_validate(self, "OffensiveHorse", true) then
			local player = yuanhu_validate(self, "OffensiveHorse", true)
			local card_id = card:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and yuanhu_validate(self, "Weapon", true) then
			local player = yuanhu_validate(self, "Weapon", true)
			local card_id = card:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") and yuanhu_validate(self, "SilverLion", true) then
			local player = yuanhu_validate(self, "SilverLion", true)
			local card_id = card:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
		end
		if card:isKindOf("Armor") and yuanhu_validate(self, "Armor", true) then
			local player = yuanhu_validate(self, "Armor", true)
			local card_id = card:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. player:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.yuanhu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("YuanhuToChoose") then
			self.room:setPlayerFlag(p, "-YuanhuToChoose")
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:hasFlag("YuanhuToChoose") then
			self.room:setPlayerFlag(p, "-YuanhuToChoose")
		end
	end
end

sgs.ai_card_intention.YuanhuCard = -30

sgs.ai_cardneed.yuanhu = sgs.ai_cardneed.equip

local xueji_skill={}
xueji_skill.name="xueji"
table.insert(sgs.ai_skills,xueji_skill)
xueji_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local red_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Peach") and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			red_card = card
			break
		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = ("@XuejiCard=" .. card_id)
		local xueji_card = sgs.Card_Parse(card_str)

		assert(xueji_card)

		return xueji_card
	end
end

local function can_be_selected_as_target(self, card, who)
	-- validation of rule
	if self.player:getWeapon() and self.player:getWeapon():getEffectiveId() == card:getEffectiveId() then
		if self.player:distanceTo(who, sgs.weapon_range[self.player:getWeapon():getClassName()] - 1) > self.player:getAttackRange() then return false end
	elseif self.player:getOffensiveHorse() and self.player:getOffensiveHorse():getEffectiveId() == card:getEffectiveId() then
		if self.player:distanceTo(who, 1) > self.player:getAttackRange() then return false end
	elseif self.player:distanceTo(who) > self.player:getAttackRange() then
		return false
	end
	-- validation of strategy
	if self:cantbeHurt(who) or self:damageIsEffective(who) then return false end
	if self:isEnemy(who) then
		if not self.player:hasSkill("jueqing") then
			if who:hasSkill("guixin") and (self.room:getAliveCount() >= 4 or not who:faceUp()) then return false end
			if (who:hasSkill("ganglie") or who:hasSkill("neoganglie")) and (self.player:getHp() == 1 and self.player:getHandcardNum() <= 2) then return false end
			if who:hasSkill("jieming") then
				for _, enemy in ipairs(self.enemies) do
					if enemy:getHandcardNum() <= enemy:getMaxHp() - 2 and not enemy:hasSkill("manjuan") then return false end
				end
			end
			if who:hasSkill("fangzhu") then
				for _, enemy in ipairs(self.enemies) do
					if not enemy:faceUp() then return false end
				end
			end
		end
		return true
	elseif self:isFriend(who) then
		if who:hasSkill("yiji") and not self.player:hasSkill("jueqing") then
			local huatuo = self.room:findPlayerBySkillName("jijiu")
			if (huatuo and self:isFriend(huatuo) and huatuo:getHandcardNum() >= 3 and huatuo ~= self.player)
				or (who:getLostHp() == 0 and who:getMaxHp() >= 3) then
				return true
			end
		end
		if who:hasSkill("hunzi") and who:getMark("hunzi") == 0 and who == self.player:getNextAlive() and who:getHp() == 2 then return true end
		return false
	end
	return false
end

sgs.ai_skill_use_func.XuejiCard = function(card,use,self)
	if self.player:getLostHp() == 0 or self.player:hasUsed("XuejiCard") then return end
	self:sort(self.enemies)
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
		if can_be_selected_as_target(self, card, enemy) then
			to_use = true
			break
		end
	end
	if not to_use then
		for _, friend in ipairs(self.friends_noself) do
			if can_be_selected_as_target(self, card, friend) then
				to_use = true
				break
			end
		end
	end
	if to_use then
		use.card = card
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if can_be_selected_as_target(self, card, enemy) then
					use.to:append(enemy)
					if use.to:length() == self.player:getLostHp() then return end
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if can_be_selected_as_target(self, card, friend) then
					use.to:append(friend)
					if use.to:length() == self.player:getLostHp() then return end
				end
			end
			assert(use.to:length() > 0)
		end
	end
end

sgs.ai_use_value.XuejiCard = 3
sgs.ai_use_priority.XuejiCard = 2.2

sgs.ai_skill_use["@@bifa"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "handcard")
	if #self.enemies > 0 then
		for _, c in ipairs(cards) do
			if c:isKindOf("EquipCard") then return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName() end
		end
		for _, c in ipairs(cards) do
			if c:isKindOf("TrickCard") and not (c:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1) then
				return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName()
			end
		end
		for _, c in ipairs(cards) do
			if c:isKindOf("Slash") then
				return "@BifaCard=" .. c:getEffectiveId() .. "->" .. self.enemies[1]:objectName()
			end
		end
	end
end

sgs.ai_skill_cardask["@bifa-give"] = function(self, data)
	local card_type = data:toString()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf(card_type) and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_card_intention.BifaCard = 30

local songci_skill={}
songci_skill.name="songci"
table.insert(sgs.ai_skills, songci_skill)
songci_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("SongciCard") then return end
	return sgs.Card_Parse("@SongciCard=.")
end

sgs.ai_skill_use_func.SongciCard = function(card,use,self)
	self:sort(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		if friend:getMark("@songci") == 0 and friend:getHandcardNum() < friend:getHp() and not (friend:hasSkill("manjuan") and self.room:getCurrent() ~= friend) then
			if not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
				use.card = sgs.Card_Parse("@SongciCard=.")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	self:sort(self.enemies, "handcard", true)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("@songci") == 0 and enemy:getHandcardNum() > enemy:getHp() and not enemy:isNude() then
			if not ((self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getEquips():length() > 0)
					or (self:isEquip("SilverLion", enemy) and enemy:isWounded())) then
				use.card = sgs.Card_Parse("@SongciCard=.")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.SongciCard = 3
sgs.ai_use_priority.SongciCard = 2.5

sgs.ai_skill_invoke.cv_sunshangxiang = function(self, data)
	local lord = self.room:getLord()
	if lord:hasLordSkill("shichou") then
		return self:isFriend(lord)
	end
	return lord:getKingdom() == "shu"
end

sgs.ai_chaofeng.sp_sunshangxiang = sgs.ai_chaofeng.sunshangxiang

sgs.ai_skill_invoke.cv_caiwenji = function(self, data)
	local lord = self.room:getLord()
	if lord:hasLordSkill("xueyi") then
		return not self:isFriend(lord)
	end
	return lord:getKingdom() == "wei"
end

sgs.ai_chaofeng.sp_caiwenji = sgs.ai_chaofeng.caiwenji

sgs.ai_skill_invoke.cv_machao = function(self, data)
	local lord = self.room:getLord()
	if lord:hasSkill("xueyi") then
		return self:isFriend(lord)
	end
	if lord:hasLordSkill("shichou") then
		return not self:isFriend(lord)
	end

	return lord:getKingdom() == "qun"
end

sgs.ai_chaofeng.sp_machao = sgs.ai_chaofeng.machao

sgs.ai_skill_invoke.cv_diaochan = function(self, data)
	if math.random(0, 2) == 0 then return false
	elseif math.random(0, 3) == 0  then sgs.ai_skill_choice.cv_diaochan="tw_diaochan" return true
	else sgs.ai_skill_choice.cv_diaochan="sp_diaochan" return true end
end

sgs.ai_chaofeng.sp_diaochan = sgs.ai_chaofeng.diaochan

sgs.ai_skill_invoke.cv_pangde = sgs.ai_skill_invoke.cv_caiwenji

sgs.ai_skill_invoke.cv_jiaxu = sgs.ai_skill_invoke.cv_caiwenji

sgs.ai_skill_invoke.cv_yuanshu = function(self, data)
	if math.random(0, 2) == 0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_zhaoyun = function(self, data)
	if math.random(0, 2) == 0 then return true end
	return false
end

sgs.ai_skill_invoke.cv_daqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0  then sgs.ai_skill_choice.cv_daqiao="tw_daqiao" return true
	else sgs.ai_skill_choice.cv_daqiao="wz_daqiao" return true end
end

sgs.ai_skill_invoke.cv_xiaoqiao = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0  then sgs.ai_skill_choice.cv_xiaoqiao="wz_xiaoqiao" return true
	else sgs.ai_skill_choice.cv_xiaoqiao="heg_xiaoqiao" return true end
end

sgs.ai_skill_invoke.cv_zhouyu = function(self, data)
	if math.random(0, 3) >= 1 then return false
	elseif math.random(0, 4) == 0  then sgs.ai_skill_choice.cv_xiaoqiao="heg_zhouyu" return true
	else sgs.ai_skill_choice.cv_xiaoqiao="sp_heg_zhouyu" return true end
end
