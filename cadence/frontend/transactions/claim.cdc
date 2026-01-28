import "GameManager"
import "GameNFT"
import "GameToken"
import "GameMarket"
import "Random"
import "GameIdentity"

transaction(chests:[String]) {

    let manager: auth (GameManager.Mint,GameManager.Gamer) &GameManager.Manager
    let collection:&GameNFT.Collection
    let winner:Address

    prepare(user: auth (BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue ) &Account, admin: auth (Storage, BorrowValue ) &Account) {
       
        self.manager = admin.storage.borrow< auth (GameManager.Mint,GameManager.Gamer) &GameManager.Manager>(from:/storage/Manager) ?? panic("Only the owner can call this function")
        self.winner = user.address

        if let collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) {
            self.collection = collection
        }else{
            let collectionRes <- GameNFT.createEmptyCollection(nftType: Type<@GameNFT.BaseNFT>())
            user.storage.save(<- collectionRes, to: GameNFT.CollectionStoragePath)
            let collectionCap = user.capabilities.storage.issue<&GameNFT.Collection>(GameNFT.CollectionStoragePath)
            user.capabilities.publish(collectionCap, at: GameNFT.CollectionPublicPath)

            let vaultRes <- GameToken.createEmptyVault(vaultType:Type<@GameToken.Fabatka>())
            user.storage.save(<- vaultRes, to: GameToken.VaultStoragePath)
            let vaultCap = user.capabilities.storage.issue<&GameToken.Fabatka>(GameToken.VaultStoragePath)
            user.capabilities.publish(vaultCap, at: GameToken.VaultPublicPath)

            let receiptStoreRes <- Random.createEmptyReceiptStore()
            user.storage.save(<- receiptStoreRes, to: Random.ReceiptStoragePath)
            let receiptCap = user.capabilities.storage.issue<&Random.ReceiptStore>(Random.ReceiptStoragePath)
            user.capabilities.publish(receiptCap, at: Random.ReceiptPublicPath)

            let market <- GameMarket.createEmptyMarket()
            user.storage.save(<- market, to: GameMarket.MarketStoragePath)
            let marketCap = user.capabilities.storage.issue<&GameMarket.ListingCollection>(GameMarket.MarketStoragePath)
            user.capabilities.publish(marketCap, at: GameMarket.MarketPublicPath)

            let gamer <- self.manager.createGamer()
            user.storage.save(<- gamer, to:GameIdentity.GamerStoragePath)
            let gamerCap = user.capabilities.storage.issue<&GameIdentity.Gamer>(GameIdentity.GamerStoragePath)
            user.capabilities.publish(gamerCap, at: GameIdentity.GamerPublicPath)

            self.collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath)!
        }
  
       
    }

    execute {
       
        fun toChest(_ chest:String):{String:AnyStruct} {
            fun toInt(_ s: String): Int {
                var result: Int = 0
                for c in s.utf8 {
                    let digit: Int = Int(c) - 48
                    result = result * 10 + digit
                }
                return result
            }
            let parts = chest.split(separator: "|")
            return {
                "type":parts[0],
                "gameId":parts[1],
                "hash":parts[2],
                "meta":{
                    "level":toInt(parts[3]),
                    "wLevel":toInt(parts[4]),
                    "event":parts[5],
                    "class":parts[6]
                }
            }
        }
        for cString in chests {
            let chest = toChest(cString)
            let chestRes <- self.manager.createChest(
                winner:self.winner,
                type:chest["type"] as! String,
                gameId:chest["gameId"] as! String,
                hash:chest["hash"] as! String,
                meta:chest["meta"] as! {String:AnyStruct}
            ) as! @GameNFT.MetaNFT
            self.collection.deposit(token: <- chestRes)
        }
    }
}