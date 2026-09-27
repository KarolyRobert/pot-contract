import "Meta"
import "GameNFT"

access(all) contract GameIdentity {

    access(all) entitlement Update
    access(all) entitlement NPC
    access(all) entitlement Market

    access(all) let GamerStoragePath: StoragePath
    access(all) let GamerPublicPath: PublicPath

    access(all) let RANK_SCALE:Meta.MetaBuilder

    access(all) resource Gamer {
        access(all) var avatar:UInt64?
        access(all) var version:UInt64
        access(all) let rank:Meta.MetaBuilder
        access(all) let farm:Meta.MetaBuilder
        access(all) let trade:Meta.MetaBuilder
        access(all) let quest:Meta.MetaBuilder

        access(account) fun setMain(_ id:UInt64) {
            self.avatar = id
        }

        access(Update) fun setAvatar(_ id:UInt64) {
            if let gamer = self.owner {
                let collection = gamer.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Gamer has no collection!")
                let avatar = collection.borrowNFT(id) as? &GameNFT.MetaNFT ?? panic("Not a metaNFT")
                if avatar.category != "avatar" {
                    panic("Not an avatar!")
                }
                let meta = avatar.meta.build()
                if let name = meta["name"] as? String {
                    self.setMain(id)
                }
            }
        }
   
        access(all) view fun getQuest():{String:AnyStruct} {
            return self.quest.build()
        }

        access(all) view fun getIdentity():{String:AnyStruct} {
            let result:{String:AnyStruct} = {
                "avatar":"default",
                "name":"unnamed",
                "id":0
            }
            if let avatar  = self.avatar {
                if let owner = self.owner {
                    if let collection = owner.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
                        if let nft = collection.borrowNFT(avatar) as? &GameNFT.MetaNFT {
                            let meta = nft.meta.build()
                            let name = meta["name"] as! String
                            result["avatar"] = nft.type
                            result["name"] = name
                            result["id"] = avatar
                        }
                    }
                }
            }
            result["farm"] = self.farm.build()
            result["rank"] = self.rank.build()
            result["trade"] = self.trade.build()
            result["quest"] = self.quest.build()
            result["rank_scale"] = GameIdentity.RANK_SCALE.build()
            return result
        }

        access(account) fun setLoot(lootToken:UFix64,lootNFT:Int) {
            let meta = self.farm.build()

            let loot = meta["loot"] as! {String: AnyStruct}
            loot["nft"] = (loot["nft"] as! Int) + lootNFT
            loot["token"] = (loot["token"] as! UFix64) + lootToken
            meta["loot"] = loot

            self.farm.update(meta)
        }

        access(account) fun setBurn(burnToken:UFix64,burnNFT:Int) {
            let meta = self.farm.build()
            let burn = meta["burn"] as! {String: AnyStruct}
            burn["token"] = (burn["token"] as! UFix64) + burnToken
            burn["nft"] = (burn["nft"] as! Int) + burnNFT
            meta["burn"] = burn
            self.farm.update(meta)
        }
      
        access(self) fun setWinrate(_ rankName:String,_ victory:Bool){
            var meta = self.rank.build()

            let rank = meta[rankName] as! {String:AnyStruct}
            if victory {
                rank["win"] = (rank["win"] as! Int) + 1
            }else{
                rank["lose"] = (rank["lose"] as! Int) + 1
            }
            meta[rankName] = rank
            self.rank.update(meta)
        }

        access(self) fun win(_ rankName:String,_ levelFactor:UFix64){
            let BASE = 25.0
            let RANK_SCALE = GameIdentity.RANK_SCALE.build()
            var SCALE = RANK_SCALE[rankName] as! Int
            let rank = self.rank.build()
            let rankPoint = rank[rankName] as! Int
            let factor = UFix64(SCALE) / UFix64(SCALE + rankPoint)
            let gain = Int(BASE * levelFactor * factor)
            let newRank = rankPoint + gain
            rank[rankName] = newRank
            if SCALE < newRank {
                RANK_SCALE[rankName] = newRank
                GameIdentity.RANK_SCALE.update(RANK_SCALE)
            }
            self.rank.update(rank)
        }

        access(self) fun lose(_ rankName:String,_ levelFactor:UFix64){
            let BASE = 25.0
            let RANK_SCALE = GameIdentity.RANK_SCALE.build()
            var SCALE = RANK_SCALE[rankName] as! Int
            let rank = self.rank.build()
            let rankPoint = rank[rankName] as! Int
            let factor = 1.0 + (UFix64(rankPoint) / UFix64(SCALE))
            let loss = Int(BASE * levelFactor * factor)
            var newRank = rankPoint - loss
            if newRank < 0 {
                newRank = 0
            }
            rank[rankName] = newRank
            self.rank.update(rank)
        }

        access(account) fun setWin(type:String,levelFactor:UFix64){
            switch type {
                case "avatar":
                    self.setWinrate("monster",true)
                    self.win("monsterRank",levelFactor)
                case "monster":
                    self.setWinrate("expedition",true)
                    self.win("hunterRank",levelFactor)
                case "pvp":
                    self.setWinrate("arena",true)
                    self.win("arenaRank",levelFactor)
            }
        }

        access(account) fun setLose(type:String,levelFactor:UFix64){
              switch type {
                case "avatar":
                    self.setWinrate("expedition",false)
                    self.lose("hunterRank",levelFactor)
                case "monster":
                    self.setWinrate("monster",false)
                    self.lose("monsterRank",levelFactor)
                case "pvp":
                    self.setWinrate("arena",false)
                    self.lose("arenaRank",levelFactor)
            }
        }

        access(account) fun setCraft(success: Bool) {
            let meta = self.farm.build()

            let craft = meta["craft"] as! {String: AnyStruct}
            if success {
                craft["success"] = (craft["success"] as! Int) + 1
            } else {
                craft["unsuccess"] = (craft["unsuccess"] as! Int) + 1
            }
            meta["craft"] = craft
            self.farm.update(meta)
        }

        access(account) fun setTrade(token:String,spend:UFix64,trade:UFix64) {
            let meta = self.trade.build()
            let role = meta[token] as! {String:AnyStruct}
            role["spend"] = (role["spend"] as! UFix64) + spend
            role["trade"] = (role["trade"] as! UFix64) + trade
            meta[token] = role
            self.trade.update(meta)
        }

        access(account) fun setProgress(progress:Int) {
            let meta = self.quest.build()
            let current = meta["progress"] as! Int
            if current < progress {
                meta["progress"] = progress
                self.quest.update(meta)
            }
        }

        init(){
            self.avatar = nil
            self.version = 0
          //  self.view = {IdentityView.farmer:true,IdentityView.ranked:true,IdentityView.trader:true}
            let zero:UFix64 = 0.0
            self.rank = Meta.MetaBuilder({
                "monster":{"win":0,"lose":0},
                "expedition":{"win":0,"lose":0},
                "arena":{"win":0,"lose":0},
                "monsterRank":0,
                "hunterRank":0,
                "arenaRank":0
            })
            self.farm = Meta.MetaBuilder({
                "craft":{"success":0,"unsuccess":0},
                "loot":{"token":zero,"nft":0},
                "burn":{"token":zero,"nft":0}
            })
            self.trade = Meta.MetaBuilder({
                "fabatka":{
                    "spend":zero,
                    "trade":zero
                },
                "flow":{
                    "spend":zero,
                    "trade":zero
                }
            })
            self.quest = Meta.MetaBuilder({
                "progress":0
            })
        }
    }

    access(account) fun createGamer():@Gamer {
        return <- create Gamer()
    }
    
    init() {
        self.GamerStoragePath = StoragePath(identifier: "Gamer_\(self.account.address.toString())")!
        self.GamerPublicPath = PublicPath(identifier: "Gamer_public_\(self.account.address.toString())")!
        self.RANK_SCALE = Meta.MetaBuilder({
            "monsterRank":1000,
            "hunterRank":1000,
            "arenaRank":1000
        })
    }
}