import "Meta"
import "GameNFT"

access(all) contract GameIdentity {

    access(all) entitlement Update
    access(all) entitlement NPC
    access(all) entitlement Market

    access(all) let GamerStoragePath: StoragePath
    access(all) let GamerPublicPath: PublicPath

    access(all) enum IdentityView:UInt8 {
        access(all) case farmer // loot,burn,craft
        access(all) case ranked // win,loose
        access(all) case trader // spend/earn marketplace
    }

    access(all) resource Gamer {
        access(all) var avatar:UInt64?
        access(all) var version:UInt64
        access(all) var view:{IdentityView:Bool}
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

        access(Update) fun setView(view:{IdentityView:Bool}) {
            self.view = view
        }

        access(self) view fun hasView(_ view:IdentityView):Bool {
            if let role = self.view[view] {
                return role
            }
            return false
        }

        access(all) view fun getIdentity():{String:AnyStruct} {
            let result:{String:AnyStruct} = {"avatar":"default","name":"unnamed","id":0}
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
            if self.hasView(IdentityView.farmer) {
                result["farm"] = self.farm.build()
            }
            if self.hasView(IdentityView.ranked) {
                result["rank"] = self.rank.build()
            }
            if self.hasView(IdentityView.trader) {
                result["trade"] = self.trade.build()
            }

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

        access(account) fun setRank(victory:Bool){
            let meta = self.rank.build()
            let rank = meta["rank"] as! {String:AnyStruct}
            if victory {
                rank["win"] = (rank["win"] as! Int) + 1
            }else{
                rank["lose"] = (rank["lose"] as! Int) + 1
            }
            meta["rank"] = rank
            self.rank.update(meta)
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

        init(){
            self.avatar = nil
            self.version = 0
            self.view = {}
            let zero:UFix64 = 0.0
            self.rank = Meta.MetaBuilder({
                "rank":{"win":0,"lose":0}
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
            self.quest = Meta.MetaBuilder({})
        }
    }

    access(account) fun createGamer():@Gamer {
        return <- create Gamer()
    }
    
    init() {
        self.GamerStoragePath = StoragePath(identifier: "Gamer_\(self.account.address.toString())")!
        self.GamerPublicPath = PublicPath(identifier: "Gamer_public_\(self.account.address.toString())")!
    }
}