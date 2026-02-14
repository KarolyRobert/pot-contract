import "GameNFT"
import "GameToken"
import "GameContent"
import "Random"
import "RandomConsumer"
import "Utils"
import "Burner"
import "GameIdentity"


access(all) contract Avatar {

    access(all) event AvatarCommit(avatarID:UInt64,consumedID:UInt64,price:UFix64,receiptID:UInt64)
    //access(all) event AvatarReveal(avatarID:UInt64, commitBlock: UInt64, receiptID: UInt64)
   
    access(all) resource Receipt : RandomConsumer.RequestWrapper {
       // access(all) let id:UInt64
        access(all) var request: @RandomConsumer.Request? 
        access(contract) var avatar:@{GameNFT.INFT}?
        access(contract) var sacrifice:@{GameNFT.INFT}?
        access(contract) var price:@GameToken.Fabatka?
        access(contract) let options:[Int]

        access(contract) fun getAvatar():@GameNFT.MetaNFT {
            let nft <- self.avatar <- nil
            return <- nft! as! @GameNFT.MetaNFT
        }

        access(contract) fun getPrice():@GameToken.Fabatka {
            let token <- self.price <- nil
            return <- token!
        }

        access(contract) fun getSacrifice():@GameNFT.MetaNFT {
            let nft <- self.sacrifice <- nil
            return <- nft! as! @GameNFT.MetaNFT
        }

        access(all) view fun getData():{String:AnyStruct} {
            return {
                "type":"avatar_upgrade",
                "nft":self.avatar?.getData(),
                "sacrifice":self.sacrifice?.getData(),
                "options":self.options
            }
        }

        access(contract) fun resolve():@RandomConsumer.RevealOutcome {

            let owner = self.owner ?? panic("Receipt must be in storage for reveal")
            let gamer = owner.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Seller Identity!")
         
            let result:@[AnyResource] <- []
            let avatar <- self.getAvatar()
            let avatarID = avatar.id
            let price <- self.getPrice()
            let avatarMeta = avatar.meta.build()
            let sacrifice <- self.getSacrifice()
            let sacrificeMeta = sacrifice.meta.build()
            let options = self.options
            let rng = Random.getRNG(request: <-self.popRequest())

            let currentEvent = GameContent.getCurrentEvent()
            let consts = GameContent.getConsts()
        
            var validation:String = "invalid"

            let main = avatarMeta["level"] as! Int
            let needPrice = Utils.getPrice(category: "avatar", level: main, quality: "common", Consts: consts)

            if needPrice == price.balance {
            // avatar upgrade
                if(avatar.type == sacrifice.type){
                    let seconder = sacrificeMeta["level"] as! Int
                    if main >= seconder {
                        // avatar upgrade
                        validation = "valid"
                        let chance = Utils.getCompozitChance(main: main, seconder: seconder, category:"avatar", Event:currentEvent, Consts: consts)//self.chance(main: main, seconder: seconder, mul: growMuls["avatar"]!)
                        if chance > rng.random() {
                            gamer.setCraft(success: true)
                            avatarMeta["level"] = main + 1
                        }else {
                            gamer.setCraft(success: false)
                            avatarMeta["fate"] = (avatarMeta["fate"] as! Int) + 1
                        }
                    }else{
                        validation = "error"
                    }
                }else if (avatarMeta["class"] as! String) != (sacrificeMeta["class"] as! String) && (avatarMeta["subClass"] as! String) !=  (sacrificeMeta["subClass"] as! String) && options.length == 0 {
                    validation = "error"
                }

                var avatarSkills = avatarMeta["skills"] as! [{String: AnyStruct}]
                var sacrificeSkills = sacrificeMeta["skills"] as! [{String: AnyStruct}]

                // skill switch
                if(validation != "error"){
                    if options.length > 0 {
                        let skills = GameContent.getContent(key:"skills")
                        
                        for i in options {
                            if(validation != "error"){
                                let skillType = sacrificeSkills[i]["type"] as! String
                                let skillContent = skills[skillType] as! &{String:String}
                                let skillClass = skillContent["class"]!

                                if skillClass == (avatarMeta["class"] as! String) || skillClass == (avatarMeta["subClass"] as! String) { // csak támogatott class-ra cserélünk
                                    for current in avatarSkills { // csak ha még nincs
                                        if (current["type"] as! String) == skillType {
                                            
                                            validation = "error"
                                        }
                                    }
                                
                                    if validation != "error" && (avatarSkills[i]["level"] as! Int) == (sacrificeSkills[i]["level"] as! Int){
                                        validation = "valid"
                                    
                                        let temp = avatarSkills[i]
                                        avatarSkills[i] = sacrificeSkills[i]
                                        sacrificeSkills[i] = temp
                                    }else{
                                        
                                        validation = "error"
                                    }
                                }else{
                                    
                                    validation = "error"
                                }
                            }
                        }
                        if validation != "error" {
                            avatarMeta["skills"] = avatarSkills
                        }
                    }
                }

                // skill upgrade
                if validation != "error" {
                    var i = 0
                    while i < 4 {
                        if((avatarSkills[i]["type"] as! String) == (sacrificeSkills[i]["type"] as! String)){
                            validation = "valid"
                            let alevel = avatarSkills[i]["level"] as! Int
                            let slevel = avatarSkills[i]["level"] as! Int
                            let main = alevel > slevel ? alevel : slevel
                            let seconder = alevel > slevel ? slevel : alevel
                            let chance = Utils.getCompozitChance(main: main, seconder: seconder, category:"skill", Event:currentEvent, Consts: consts)
                            if chance > rng.random() {
                                gamer.setCraft(success: true)
                                avatarSkills[i]["level"] = main + 1
                            }else{
                                gamer.setCraft(success: false)
                            }
                        }
                        i = i + 1
                    }
                    if(validation == "valid"){
                        avatarMeta["skills"] = avatarSkills
                    }
                }
            }else{
                validation = "error"
            }

            let emitResult:[UInt64] = []
            let successResolve:Bool = validation == "valid"
            var resultToken:UFix64 = 0.0
            if successResolve {
                gamer.setBurn(burnToken: needPrice, burnNFT: 1)
                avatar.meta.update(avatarMeta)
                emitResult.append(avatar.id)
                result.append(<-avatar)
                Burner.burn(<- price)
                destroy sacrifice
            }else{
                emitResult.append(avatar.id)
                result.append(<-avatar)
                emitResult.append(sacrifice.id)
                result.append(<-sacrifice)
                resultToken = price.balance
                result.append(<-price)
            }
            
            return <- RandomConsumer.createOutcome(success:successResolve,ids:emitResult,balance:resultToken,result: <- result)
        }

        
        init(avatar: @{GameNFT.INFT},sacrifice:@{GameNFT.INFT},options:[Int],price:@GameToken.Fabatka,request: @RandomConsumer.Request) {
            self.avatar <- avatar
            self.sacrifice <- sacrifice
            self.options = options
            self.price <- price
            self.request <- request
        }
    }

    access(all) fun commitUpgrade(avatar:@{GameNFT.INFT},sacrifice:@{GameNFT.INFT},options:[Int],price:@GameToken.Fabatka):@Receipt {
        pre {
            avatar.category == "avatar": "Only avatars accepted"
            sacrifice.category == "avatar": "Only avatars can be sacrificed"
        }

        let request <- Random.request()
        let avatarId = avatar.id
        let consumedId = sacrifice.id
        let consumedToken = price.balance
        let receipt <- create Receipt(avatar:<-avatar,sacrifice:<-sacrifice,options:options,price:<-price,request:<-request)
        emit AvatarCommit(avatarID:avatarId,consumedID:consumedId,price:consumedToken,receiptID:receipt.uuid)
        return <-receipt
    }

}