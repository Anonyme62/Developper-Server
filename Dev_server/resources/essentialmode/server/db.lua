local port = 5984 -- Change to whatever port you have CouchDB running on

db = {}
exposedDB = {}

function db.firstRunCheck()
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/essentialmode", function(err, rText, headers)
		if err == 0 then
			print("First run detected, setting up.")
		else
			print("Setup already ran, continueing.")
		end
	end, "PUT", "")
end

function db.createUser(identifier, callback)
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/_uuids", function(err, rText, headers)
		PerformHttpRequest("http://127.0.0.1:" .. port .. "/essentialmode/" .. json.decode(rText).uuids[1], function(err, rText, headers)
			callback(rText, { identifier = identifier, money = 0, dirty_money = 0, bank = 0, group = "user", permission_level = 0 })
		end, "PUT", json.encode({ identifier = identifier, money = 0, dirty_money = 0, bank = 0, group = "user", permission_level = 0 }), {["Content-Type"] = 'application/json'})
	end, "GET", "")
end

function db.doesUserExist(identifier, callback)
	local qu = {selector = {["identifier"] = identifier}, fields = {"_rev"}}
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/essentialmode/_find", function(err, rText, headers)
		local t = json.decode(rText)

		if(#t.docs == 1)then
			callback(true)
		else
			callback(false)
		end
	end, "POST", json.encode(qu), {["Content-Type"] = 'application/json'})		
end

function db.retrieveUser(identifier, callback)
	local qu = {selector = {["identifier"] = identifier}, fields = {"_rev", "_id", "identifier", "bank", "money", "dirty_money", "group", "permission_level"}}
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/essentialmode/_find", function(err, rText, headers)
		local t = json.decode(rText)
		
		if(t.docs[1])then
			callback(t.docs[1])
		else
			callback(false)
		end
	end, "POST", json.encode(qu), {["Content-Type"] = 'application/json'})		
end

function db.updateUser(identifier, new, callback)
	db.retrieveUser(identifier, function(user)
		PerformHttpRequest("http://127.0.0.1:" .. port .. "/essentialmode/" .. user._id, function(err, rText, headers)
			callback((err or true))
		end, "PUT", json.encode({ _rev = user._rev, identifier = user.identifier, money = (new.money or user.money), dirty_money = (new.dirty_money or user.dirty_money), bank = (new.bank or user.bank), group = (new.group or user.group), permission_level = (new.permission_level or user.permission_level) }), {["Content-Type"] = 'application/json'})
	end)	
end

function db.performCheckRunning()
	PerformHttpRequest("http://127.0.0.1:" .. port .. "", function(err, rText, headers)
	end, "GET", "")
end

db.firstRunCheck()

function exposedDB.createDatabase(db, cb)
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/" .. db, function(err, rText, headers)
		if err == 0 then
			cb(true, 0)
		else
			cb(false, rText)
		end
	end, "PUT", "")
end

function exposedDB.createDocument(db, rows, cb)
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/_uuids", function(err, rText, headers)
		PerformHttpRequest("http://127.0.0.1:" .. port .. "/" .. db .. "/" .. json.decode(rText).uuids[1], function(err, rText, headers)
			if err == 0 then
				cb(true, 0)
			else
				cb(false, rText)
			end
		end, "PUT", json.encode(rows), {["Content-Type"] = 'application/json'})
	end, "GET", "")
end

function exposedDB.getDocumentByRow(db, row, value, callback)
	local qu = {selector = {[row] = value}}
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/" .. db .. "/_find", function(err, rText, headers)
		local t = json.decode(rText)

		if(err == 0)then
			if(t.docs[1])then
				callback(t.docs[1])
			else
				callback(false)
			end
		else
			callback(false, rText)
		end
	end, "POST", json.encode(qu), {["Content-Type"] = 'application/json'})		
end

function exposedDB.updateDocument(db, documentID, updates, callback)
	PerformHttpRequest("http://127.0.0.1:" .. port .. "/" .. db .. "/" .. documentID, function(err, rText, headers)
		local doc = json.decode(rText)

		if(doc)then
			for i in pairs(updates)do
				doc[i] = updates[i]
			end

			PerformHttpRequest("http://127.0.0.1:" .. port .. "/" .. db .. "/" .. doc._id, function(err, rText, headers)
				callback((err or true))
			end, "PUT", json.encode(doc), {["Content-Type"] = 'application/json'})
		end
	end, "GET", "", {["Content-Type"] = 'application/json'})	
end

AddEventHandler('es:exposeDBFunctions', function(cb)
	cb(exposedDB)
end)

-- Why the fuck is this required?
local theTestObject, jsonPos, jsonErr = json.decode('{"test":"tested"}')

exposedDB.createDatabase("testing", function(done, err)
	exposedDB.createDocument("testing", {username = "justatest", level = 10, permissions = 0}, function(done, err)
		exposedDB.getDocumentByRow("testing", "username", "justatest", function(done, err)
			exposedDB.updateDocument("testing", done._id, {level = 1000}, function(done, err)end)
		end)
	end)
end)