import "GameNFT"
import "GameContent"
import "Random"
import "RandomConsumer"
import "Utils"
import "GameToken"
import "GameIdentity"


access(all) contract Chest {

    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        access(all) let id:UInt64
        access(all) var request: @RandomConsumer.Request? 
        access(contract) var chest: @{GameNFT.INFT}?
       

        access(contract) fun getChest():@GameNFT.MetaNFT {
            let nft <- self.chest <- nil
            return <- nft! as! @GameNFT.MetaNFT
        }

        access(all) view fun getData():{String:AnyStruct} {
            return {
                "type":"chest_open",
                "nft":self.chest?.getData()
            }
        }

     

        access(contract) fun resolve():@RandomConsumer.RevealOutcome {
            /* 
            pre {
                receipt.request != nil: "Chest.revealChests: Cannot reveal the chest! The provided receipt has already been revealed."
                receipt.getRequestBlock()! <= getCurrentBlock().height:
                "Chest.revealChests: Cannot reveal the chest! The provided receipt was committed for block height ".concat(receipt.getRequestBlock()!.toString())
                .concat(" which is greater than the current block height of ")
                .concat(getCurrentBlock().height.toString())
                .concat(". The reveal can only happen after the committed block has passed.")
            }*/
            fun normalize(_ array:[UFix64]):[UFix64] {
                var sum:UFix64 = 0.0
                for v in array {
                    sum = sum + v
                }
                let result:[UFix64] = []
                for v in array {
                    result.append(v / sum)
                }
                return result
            }

            view fun modifyChance(array:[UFix64],dif:Int,chestEvent:&{String:AnyStruct}):[UFix64]{
                let difMul = *(chestEvent["difMul"] as! &UFix64)
                let base:Fix64 = (Fix64(dif) * Fix64(difMul))
                let main = Fix64(array[0]) + base < 0.0 ? 0.0 : UFix64(Fix64(array[0]) + base)        
                let seconder = Fix64(array[1]) + (base/2.0) < 0.0 ? 0.0 : UFix64(Fix64(array[1]) + (base/2.0))
                let aid = UFix64(Fix64(array[2]) + (Fix64(array[0]) - Fix64(main)) + (Fix64(array[1]) - Fix64(seconder)))
                let sum = main + seconder + aid
                return [
                    main / sum,
                    seconder / sum,
                    aid / sum
                ]
            }

            /*
                 The charm impact on category = level%.  
             */
            view fun applyCharm(chestCharm:{String:AnyStruct}?,lootChance:[UFix64],lootType:[String]):[UFix64] {
                if let charm = chestCharm {
                    let category = charm["category"] as! String
                    let bonus = Fix64(charm["level"] as! Int) / 100.0 // max 20% bonus
                    var main = Fix64(lootChance[0])
                    var seconder = Fix64(lootChance[1])
                    var need = Fix64(lootChance[2])
                    if category == lootType[0] { // item or spell
                        main = main + bonus
                        seconder = seconder - (bonus / 2.0) < 0.0 ? 0.0 : seconder - (bonus / 2.0)
                        need = need - (bonus / 2.0) < 0.0 ? 0.0 : need - (bonus / 2.0)
                    }else{
                        seconder = seconder + bonus
                        main = main - (bonus / 2.0) < 0.0 ? 0.0 : main - (bonus / 2.0)
                        need = need - (bonus / 2.0) < 0.0 ? 0.0 : need - (bonus / 2.0)
                    }
                    let sum = main + seconder + need
                    return [
                        UFix64(main / sum),
                        UFix64(seconder / sum),
                        UFix64(need / sum)
                    ]
                }
                return lootChance
            }
            let content:{String:&{String:AnyStruct}} = {}

            let needContent = fun(_ need:[String],_ z:Int?){
                if let zone = z {
                    for key in need {
                        if content[key] == nil {
                            content[key] = GameContent.getZoneContent(key:key,zone:zone)
                        }
                    }
                }else{
                    for key in need {
                        if content[key] == nil {
                            content[key] = GameContent.getContent(key:key)
                        }
                    }
                }
            }
           
            let owner = self.owner ?? panic("Receipt must be in storage for reveal")
            let gamer = owner.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Seller Identity!")

            let rng = Random.getRNG(request: <-self.popRequest())
          
            let result:@[AnyResource] <- []        
        

            let chest <- self.getChest()
            let chestId = chest.id
            let chestMeta = chest.meta.build()
            let chestLevel = chestMeta["level"] as! Int
            let wLevel = chestMeta["wLevel"] as! Int
            let chestClass = chestMeta["class"] as! String

            /*
            The charm bonus for category is precent of his level (max 20%),
            the quality of item is multiply half of level (max 10x),
            the multiply of item of spell in the same zone is half of level (max 10x)
             */
            var chestCharm:{String:AnyStruct}? = nil
            if let charm = chestMeta["charm"] as? {String:AnyStruct} {
                chestCharm = charm
            }

            let dif = chestLevel - wLevel
           
            needContent(["events","consts"],nil)
            let zoneSize = (content["consts"]!["consts"] as! &{String:AnyStruct}["zoneSize"]) as! &Int
            let zone = chestLevel / *zoneSize

            let mintItem = fun ():@{GameNFT.INFT}{
                needContent(["items","aids"],zone)
                let items = content["items"]!
                let byQuality:{String:[String]} = {}
                let keys = items.keys
            
                let QChance = (content["consts"]!["consts"] as! &{String:AnyStruct}["qualityClass"] as! &{String:AnyStruct})[chestClass] as! &[UFix64]

                var charmQuality = ""
                var charmMultiply = 0
                var charmItem = ""
                if chestCharm != nil {
                    charmQuality = chestCharm!["quality"] as! String
                    charmMultiply = chestCharm!["level"] as! Int / 2
                    if chestCharm!["category"] as! String == "item" && chestCharm!["zone"] as! Int == zone {
                        charmItem = chestCharm!["type"] as! String
                    }
                }
             
            
                for key in keys { // only the exist qualitys of zone
                    let item = items[key] as! &{String:AnyStruct}
                    let qualiyt = *(item["quality"] as! &String)
                    if byQuality[qualiyt] == nil {
                        byQuality[qualiyt] = []
                    }
                    if charmItem == key {
                        var multiply = charmMultiply
                        while multiply > 0 {
                            multiply = multiply - 1
                            byQuality[qualiyt]!.append(key)
                        }
                    }else{
                        byQuality[qualiyt]!.append(key)
                    }
                }
              
                let qualityKeys = byQuality.keys
                let qualitys:[String] = []
                var qualityChance:[UFix64] = []
                for key in qualityKeys { // only the chance of qualitys
                    let index = Utils.getQualityIndex(key)
                    if charmQuality == key { // multiply chance of quality
                        var multiply = charmMultiply
                        while multiply > 0 {
                            multiply = multiply - 1
                            qualitys.append(key)
                            qualityChance.append(QChance[index])
                        }
                    }else{
                        qualitys.append(key)
                        qualityChance.append(QChance[index])
                    }
                }

                qualityChance = normalize(qualityChance)

                let qualityIndex = Utils.chooseIndex(qualityChance,rng.random())

                let quality = qualitys[qualityIndex]

                let types = byQuality[quality]!



                let type = types[rng.nextInt(max: types.length)]
                let chainItem = items[type] as! &{String:AnyStruct}
                let itemClass = *(chainItem["class"] as! &String)
                let useFor = *(chainItem["useFor"] as! &[String])
                
                // aids sorsolás
                let aids = (content["aids"]!)
                let aidNames = aids.keys
                let quality_pos = Utils.getQualityIndex(quality) + 1

                let fateBase = quality_pos * 100
                let fate = fateBase + rng.nextInt(max: fateBase)
                
                let needs = Utils.chooseMore(*aidNames,rng.intArray(length:quality_pos,max:aidNames.length))
            
                
                return <- GameNFT.minter.mintMeta(
                    category: "item",
                    type:type,
                    meta:{
                        "level":0,
                        "class":itemClass,
                        "useFor":useFor,
                        "quality":quality,
                        "zone":zone,
                        "needs":needs,
                        "fate":fate
                    })
            }


            let mintAvatar = fun():@{GameNFT.INFT}{
                needContent(["avatars","skills"],nil)
                let subClasses:[String] = ["Explorer","Collector","Scholar"]
                let subClass = subClasses[rng.nextInt(max:3)]
                let avatars = content["avatars"]! 
                let types = avatars.keys

                let type = types[rng.nextInt(max: types.length)]
                let classes = *((avatars[type] as! &{String:[String]})["class"]!)
                let class =  classes[rng.nextInt(max: classes.length)]

                let skills = content["skills"]!
                let skilltypes = skills.keys
                

                let validClass = [class,subClass]
                let skillPool = skilltypes.filter(view fun(element:String):Bool {
                    return validClass.contains(*(skills[element] as! &{String:AnyStruct}["class"] as! &String))
                })
             
                let skillNames:[String] = Utils.chooseSome(pool:skillPool,source:rng.descIntArray(length:4,max:skillPool.length))

                let avatarSkills = skillNames.map(fun(name:String):{String:AnyStruct} {
                    return {"type":name,"level":0}
                })
            
                return <- GameNFT.minter.mintMeta(
                    category: "avatar",
                    type:type,
                    meta:{
                        "level":0,
                        "class":class,
                        "subClass":subClass,
                        "skills":avatarSkills,
                        "charm":0 as UInt64,
                        "items":{
                            "weapon":0 as UInt64,
                            "armor":0 as UInt64,
                            "helmet":0 as UInt64,
                            "boots":0 as UInt64,
                            "ring":0 as UInt64,
                            "neck":0 as UInt64
                        },
                        "spells":{
                            0:0 as UInt64,
                            1:0 as UInt64,
                            2:0 as UInt64,
                            3:0 as UInt64,
                            4:0 as UInt64,
                            5:0 as UInt64,
                            6:0 as UInt64,
                            7:0 as UInt64
                        }
                    })
            }

            let mintSpell = fun():@{GameNFT.INFT}{
                needContent(["spells","alcs"],zone)
                let spells = content["spells"]!
                let types = *spells.keys

                if chestCharm != nil {
                    if chestCharm!["category"] as! String == "spell" && chestCharm!["zone"] as! Int == zone {
                        let charmSpell = chestCharm!["type"] as! String
                        var multiply = (chestCharm!["level"] as! Int / 2) - 1
                        while multiply > 0 {
                            multiply = multiply - 1
                            types.append(charmSpell)
                        }
                    }
                }


                let type = types[rng.nextInt(max: types.length)]

                let alcNames = (content["alcs"]!).keys
                let needs:[String] = []
                var i = 0
                while i < 3 {
                    let aid = alcNames[rng.nextInt(max: alcNames.length)]
                    needs.append(aid)
                    i = i + 1
                }

                let fate = rng.nextInt(max: 1000)

                return <- GameNFT.minter.mintMeta(
                    category: "spell",
                    type:type,
                    meta:{
                        "level":0,
                        "quality":"rare",
                        "zone":zone,
                        "needs":needs,
                        "fate":fate
                    })
            }

            let mintNeed = fun ():@{GameNFT.INFT}{
                needContent(["aids","alcs"], zone)
                var types:[String] = []
                var category:String = ""
                if rng.random() > 0.5 {
                    types = *(content["aids"]!).keys
                    category = "aid"
                }else{
                    types = *(content["alcs"]!).keys
                    category = "alc"
                }

                let type = types[rng.nextInt(max: types.length)]

                return <- GameNFT.minter.mintBase(
                    category:category,
                    type:type
                )
            }
                
           
        
        
            let loot:[UInt64] = []
            
            // a ládára vonatkozó event objektum.
            let chestEvent = content["events"]![chestMeta["event"] as! String] as! &{String:AnyStruct}
    
            var lootChance = *((content["consts"]!["consts"] as! &{String:AnyStruct}["loot"] as! &{String:[UFix64]})[*(chestEvent["lootChance"] as! &String)]!)
       
            lootChance = modifyChance(array:lootChance,dif:dif,chestEvent:chestEvent)

        
            // fabatka
            let fabatkaConsts = content["consts"]!["consts"] as! &{String:AnyStruct}["fabatka"] as! &{String:AnyStruct} //consts["fabatka"] as! &{String:AnyStruct}
            let fabatkaMul = *(fabatkaConsts["level"] as! &UFix64)
            let base = *(fabatkaConsts["base"] as! &UFix64)

            let fabatka = base * Utils.pow(base:fabatkaMul,exp:chestLevel) //*(fabatkaConsts["base"] as! &UFix64) * (UFix64(chestLevel + 1) * fabatkaMul)

            result.append(<- GameToken.createFabatka(balance:fabatka))

        
            let lootCount = *(chestEvent["lootCount"] as! &Int)
           
            gamer.setLoot(lootToken:fabatka,lootNFT:lootCount)
        
            var lootType:[String] = []
            switch(chest.type) {
                case "avatar":
                    lootType = ["avatar","item","need"]
                    break
                case "monster":
                    lootType = ["item","spell","need"]
                    break
                case "pvp":
                    lootType = ["spell","item","need"]
            }

            lootChance = applyCharm(chestCharm:chestCharm,lootChance:lootChance,lootType:lootType)

            var i = 0
            while i < lootCount {
                let lType = lootType[Utils.chooseIndex(lootChance,rng.random())]
                var nft:@{GameNFT.INFT}? <- nil
                switch(lType){
                    case "avatar":
                        nft <-! mintAvatar()
                        break
                    case "spell":
                        nft <-! mintSpell()
                        break
                    case "item":
                        nft <-! mintItem()
                        break
                    case "need":
                        nft <-! mintNeed()
                        break
                }
                i = i + 1
                let minted <-nft!
                loot.append(minted.id)
                result.append(<- minted)
            }

            destroy chest
            
            //emit ChestReveal(chestID:chestId,loot:loot,fabatka:fabatka,commitBlock:commitBlock,receiptID:receiptID)
            return <- RandomConsumer.createOutcome(success:true,ids:loot,balance:fabatka,result: <- result)
        }

        init(chest: @{GameNFT.INFT}, request: @RandomConsumer.Request) {
            self.id = chest.id
            self.chest <- chest
            self.request <- request
        }
    }

    access(all) fun commitChest(chest:@{GameNFT.INFT}):@Receipt {
        pre {
            chest.category == "chest" : "Not chest!"
        }
      
        let id = chest.id
        let request <- Random.request()
        let receipt <- create Receipt(
            chest: <- chest,
            request: <- request
        )
       // emit ChestCommit(chestID:id,commitBlock:receipt.getRequestBlock()!, receiptID: receipt.uuid)
        return <- receipt
    }
 
}