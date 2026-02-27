import "GameNFT"
import "GameToken"
import "FungibleToken"
import "GameContent"
import "GameIdentity"


access(all) contract GameManager {

    access(all) entitlement Mint
    access(all) entitlement Gamer
    access(all) entitlement Name
    access(all) entitlement Update
    access(all) entitlement GameEvent
    

    access(all) event createChestEvent(id:UInt64,winner:Address,type:String,gameId:String,hash:String)
    access(all) event setAvatarName(id:UInt64)

    

    access(all) resource Manager {
        
        access(Mint) fun createChest(winner:Address,defeated:Address,type:String,gameId:String,hash:String,meta:{String:AnyStruct}): @{GameNFT.INFT} {
            let user = getAccount(winner)
            let winGamer =  user.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Gamer!")
            winGamer.setRank(victory: true)

            if type == "monster" {
                let progress = meta["level"] as! Int
                winGamer.setProgress(progress:progress)
            }
            

            // TODO defeated gamer.setRank(victoty: false)

            let nft <- GameNFT.minter.mintMeta(category: "chest", type:type, meta: meta)
            emit createChestEvent(id:nft.id,winner:winner,type:type,gameId:gameId,hash:hash)
            return <- nft
        }

        access(Gamer) fun createGamer():@GameIdentity.Gamer {
            return <- GameIdentity.createGamer()
        }

        access(Name) fun setName(avatar:&GameNFT.MetaNFT,name:String) {
            if avatar.category == "avatar" {
                let meta = avatar.meta.build()
                if let currentName = meta["name"] as? String {
                    panic("Avatar has name! \(currentName)")
                }
                meta["name"] = name
                avatar.meta.update(meta)
                emit setAvatarName(id:avatar.id)
            }
        }

        access(Update) fun update(contentVersion:[String],auditVersion:[String],contents:{String:{String:AnyStruct}}) {
            GameContent.update(contentVersion:contentVersion,auditVersion:auditVersion,contents:contents)
        }

        access(GameEvent) fun setEvent(name:String){
            GameContent.setEvent(name)
        }
    
    }


    init() {
        let manager <- create Manager()
        self.account.storage.save(<- manager, to: /storage/Manager)
        let managerCb = self.account.capabilities.storage.issue<&GameManager.Manager>(/storage/Manager)
        self.account.capabilities.publish(managerCb, at: /public/Manager)
    }

}