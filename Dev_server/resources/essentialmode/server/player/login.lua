-- NO TOUCHY, IF SOMETHING IS WRONG CONTACT KANERSPS! --
-- NO TOUCHY, IF SOMETHING IS WRONG CONTACT KANERSPS! --
-- NO TOUCHY, IF SOMETHING IS WRONG CONTACT KANERSPS! --
-- NO TOUCHY, IF SOMETHING IS WRONG CONTACT KANERSPS! --

function LoadUser(identifier, source, new)
	db.retrieveUser(identifier, function(user)
		local group = groups[user.group]

		print("User being loaded: " .. tostring(user.identifier))

		Users[source] = Player(source, user.permission_level, user.money, user.dirty_money, user.bank, user.identifier, group)
	
		TriggerEvent('es:playerLoaded', source, Users[source])

		TriggerClientEvent('es:setPlayerDecorator', source, 'rank', Users[source]:getPermissions())
		TriggerClientEvent('es:setMoneyIcon', source,settings.defaultSettings.moneyIcon)

		if(new)then
			TriggerEvent('es:newPlayerLoaded', source, Users[source])
		end
	end)
end

function stringsplit(self, delimiter)
  local a = self:Split(delimiter)
  local t = {}

  for i = 0, #a - 1 do
     table.insert(t, a[i])
  end

  return t
end

AddEventHandler('es:getPlayers', function(cb)
	cb(Users)
end)

function registerUser(identifier, source)
	db.doesUserExist(identifier, function(exists)
		print("Does user exist? " .. tostring(exists))
		if exists then
			LoadUser(identifier, source, false)
		else
			db.createUser(identifier, function(r, user)
				LoadUser(identifier, source, true)
			end)
		end
	end)
end

AddEventHandler("es:setPlayerData", function(user, k, v, cb)
	if(Users[user])then
		if(Users[user][k])then

			if(k ~= "money") then
				Users[user][k] = v

				db.updateUser(Users[user]['identifier'], {[k] = v}, function(d)end)
			end

			if(k == "group")then
				Users[user].group = groups[v]
			end

			cb("Player data edited.", true)
		else
			cb("Column does not exist!", false)
		end
	else
		cb("User could not be found!", false)
	end
end)

AddEventHandler("es:setPlayerDataId", function(user, k, v, cb)
	db.updateUser(user, {[k] = v}, function(d)
		cb("Player data edited.", true)
	end)
end)

AddEventHandler("es:getPlayerFromId", function(user, cb)
	if(Users)then
		if(Users[user])then
			cb(Users[user])
		else
			cb(nil)
		end
	else
		cb(nil)
	end
end)

AddEventHandler("es:getPlayerFromIdentifier", function(identifier, cb)
	db.retrieveUser(identifier, function(user)
		cb(user)
	end)
end)

-- Function to update player money every 60 seconds.
local function savePlayerMoney()
	SetTimeout(60000, function()
		TriggerEvent("es:getPlayers", function(users)
			for k,v in pairs(users)do
				db.updateUser(v.identifier, {money = v.money}, function()end)
			end
		end)

		savePlayerMoney()
	end)
end

savePlayerMoney()