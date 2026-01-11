import "GameNFT"
import "GameToken"
import "Random"


transaction() {

    prepare(user: auth (Capabilities, Storage ) &Account ) {
       
    
            let cap = user.capabilities.unpublish(GameNFT.CollectionPublicPath)

            if let col <- user.storage.load<@GameNFT.Collection>(from: GameNFT.CollectionStoragePath) {
                destroy col
            }

            let vcap = user.capabilities.unpublish(GameToken.VaultPublicPath)

            if let vault <- user.storage.load<@GameToken.Fabatka>(from: GameToken.VaultStoragePath) {
                destroy vault
            }

            let recCap = user.capabilities.unpublish(Random.ReceiptPublicPath)

            if let rec <- user.storage.load<@Random.ReceiptStore>(from: Random.ReceiptStoragePath) {
                destroy rec
            }
          
            

    }

    execute {
    }
}