

access(all) contract GameContent {


    access(account) var eventName:String
    access(all) let zoneSize:Int

    access(all) var currentVersion:Version
    access(all) let contentPaths: {String:StoragePath}


    access(all) struct Version {
        access(all) let content:[String]
        access(all) let audit:[String]
        init(content:[String],audit:[String]){
            self.content = content
            self.audit = audit
        }
    }

    access(all) resource OldVersions {
        access(all) let content:[[String]]
        access(all) let audit:[[String]]

        access(contract) fun addVersion(version:Version) {
            let lastContent:[String] = self.content.length > 0 ? self.content[self.content.length - 1] : []
            let lastAudit:[String] = self.audit.length > 0 ? self.audit[self.audit.length - 1] : []
            if lastContent != version.content {
                self.content.append(version.content)
            }
            if lastAudit != version.audit {
                self.audit.append(version.audit)
            }
        }
        init(){
            self.content = []
            self.audit = []
        }
    }

    access(contract) fun addKey(_ key:String,_ storage:StoragePath){
        self.contentPaths[key] = storage
    }

    access(account) fun update(contentVersion:[String],auditVersion:[String],contents:{String:{String:AnyStruct}}) {
        let newVersion = Version(content:contentVersion,audit:auditVersion)
        let vRef = self.account.storage.borrow<&OldVersions>(from: /storage/Versions) ?? panic("OldVersions anomaly!")
        vRef.addVersion(version:self.currentVersion)
        self.currentVersion = newVersion



        for key in contents.keys {
            let value = contents[key]!
            let first = (value[value.keys[0]] as! {String:AnyStruct})["zone"]
            var zones:{Int:{String:AnyStruct}} = {}
            if(first != nil){
                let zKeys = value.keys
                for zkey in zKeys {
                    let item = value[zkey] as! {String:AnyStruct}
                    let zone = item["zone"] as! Int
                    if zones[zone] == nil {
                        zones[zone] = {}
                    }
                    let currentZone = zones[zone]!
                    var itemValue:{String:AnyStruct} = {}
                    for ikey in item.keys {
                        if ikey != "zone" {
                            itemValue[ikey] = item[ikey]
                        }
                    }
                    currentZone[zkey] = itemValue
                    zones[zone] = currentZone
                }
            }



            if zones.keys.length > 0 {
                for z in zones.keys {
                    let storeKey = key.concat("_").concat(z.toString())
                    if self.contentPaths[storeKey] == nil {
                        self.addKey(storeKey,StoragePath(identifier: "/".concat(storeKey))!)
                        self.saveField(key: storeKey, value: zones[z]!)
                    }else{
                        self.updateField(key: storeKey, value: zones[z]!)
                    }
                }
            }else{
                if self.contentPaths[key] == nil {
                    self.addKey(key,StoragePath(identifier: "/".concat(key))!)
                    self.saveField(key: key, value: value)
                }else{
                    self.updateField(key: key, value: value)
                }
            }
        }
    }

    access(contract) fun saveField(key:String,value:{String:AnyStruct}) {
        log("update_content:".concat(key))
        let path = self.contentPaths[key] ?? panic("Missing content: ".concat(key))
        self.account.storage.save(value,to:path)
    }

    access(account) fun updateField(key:String,value:{String:AnyStruct}) {
        let path = self.contentPaths[key] ?? panic("Missing content: ".concat(key))
        let _ = self.account.storage.load<{String:AnyStruct}>(from:path) // obsolete
        self.account.storage.save(value,to:path)
    }

    access(all) view fun getContent(key:String):&{String:AnyStruct} {
        //self.account.storage.load<{String:AnyStruct}>(from: self.contentPaths[key]!) ?? panic("getContent anomaly!".concat(key))  //  computeUnitsUsed=1822 memoryEstimate=37617620 
        return self.account.storage.borrow<&{String:AnyStruct}>(from: self.contentPaths[key]!) ?? panic("getContent anomaly!".concat(key)) // computeUnitsUsed=1469 memoryEstimate=28226777 // computeUnitsUsed=1501 memoryEstimate=28545714
    }

    access(all) view fun getZoneContent(key:String,zone:Int):&{String:AnyStruct} {
        let storeKey = key.concat("_").concat(zone.toString())
        return self.getContent(key: storeKey)
    }

    access(all) view fun getCurrentEvent():&{String:AnyStruct} {
        return self.getContent(key:"events")[self.eventName] as! &{String:AnyStruct}
    }

    access(all) view fun getConsts():&{String:{String:AnyStruct}} {
        return self.getContent(key:"consts")["consts"] as! &{String:{String:AnyStruct}}
    }

    access(account) fun setEvent(_ name:String){
        self.eventName = name
    }


    init() {
        self.contentPaths = {}
        self.eventName = "default"
        self.zoneSize = 12
        self.currentVersion = Version(content:[],audit:[])
        let versions <- create OldVersions()
        self.account.storage.save(<- versions, to: /storage/Versions)
    }
}