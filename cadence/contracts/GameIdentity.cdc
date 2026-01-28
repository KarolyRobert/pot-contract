import "Meta"
import "GameNFT"

access(all) contract GameIdentity {

    access(all) entitlement Avatar

    access(all) let GamerStoragePath: StoragePath
    access(all) let GamerPublicPath: PublicPath

    access(all) resource Gamer {
        access(all) var avatar:UInt64?
        access(all) var name:String
        access(all) var victory:UInt64
        access(all) var defeat:UInt64
        access(all) let meta:Meta.MetaBuilder


        access(Avatar) fun setAvatar(nft:&GameNFT.MetaNFT) {
            if(nft.category == "avatar"){
                self.avatar = nft.id
                let meta = self.meta.build()
                meta["avatar"] = nft.type
                self.meta.update(meta)
            }
        }

        access(all) view fun getIcon():{String:AnyStruct} {
            let meta = self.meta.build()
            let type = meta["avatar"] as! String
            return {"avatar":type,"id":self.avatar ?? 0}
        }

        access(account) fun setCraft(success:Bool) {
            let meta = self.meta.build()
            if(success){
                let craft_success = meta["craft_success"] as! Int
                meta["craft_success"] = craft_success + 1
            }else{
                let craft_unsuccess = meta["craft_unsuccess"] as! Int
                meta["craft_unsuccess"] = craft_unsuccess + 1
            }
        }

        access(account) fun win() {
            self.victory = self.victory + 1
        }

        access(account) fun lose() {
            self.defeat = self.defeat + 1
        }

        init(){
            self.name = "unnamed"
            self.avatar = nil
            self.victory = 0
            self.defeat = 0
            self.meta = Meta.MetaBuilder({
                "craft_success":0,
                "craft_unsuccess":0,
                "avatar":"default"
            })
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