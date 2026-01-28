import "GameNFT"
import "GameToken"
import "GameIdentity"
import "GameMarket"
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

            let marCap = user.capabilities.unpublish(GameMarket.MarketPublicPath)

            if let marc <- user.storage.load<@GameMarket.ListingCollection>(from: GameMarket.MarketStoragePath) {
                destroy marc
            }
          
            let gamerCap = user.capabilities.unpublish(GameIdentity.GamerPublicPath)

            if let gamer <- user.storage.load<@GameIdentity.Gamer>(from: GameIdentity.GamerStoragePath) {
                destroy gamer
            }
            

    }

    execute {
    }
}