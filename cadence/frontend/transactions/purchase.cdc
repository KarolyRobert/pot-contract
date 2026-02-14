import "NonFungibleToken"
import "FungibleToken"
import "GameNFT"
import "GameMarket"
import "GameToken"
import "FlowToken"
import "GameIdentity"

transaction(account:Address,listingID:UInt64,currency:String) {

    var price:UFix64 
    let collection:&GameNFT.Collection
    let price:@{FungibleToken.Vault}
    let store:&GameMarket.ListingCollection
    let gamer:auth (GameIdentity.Market) &GameIdentity.Gamer

    prepare(user: auth (BorrowValue) &Account) {

        let seller = getAccount(account)

        self.collection = user.capabilities.borrow<&GameNFT.Collection>(GameNFT.CollectionPublicPath) ?? panic("Collection")
        
        self.store = seller.capabilities.borrow<&GameMarket.ListingCollection>(GameMarket.MarketPublicPath) ?? panic("List")

        self.gamer = user.storage.borrow<auth (GameIdentity.Market) &GameIdentity.Gamer>(from: GameIdentity.GamerStoragePath) ?? panic("gamer")

        if currency == "flow" {
            let amount = self.store.getListingPrice(listingID: listingID, token: Type<@FlowToken.Vault>())
            let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &FlowToken.Vault>(from:/storage/flowTokenVault) ?? panic("Nincs collection")
            self.price <- vault.withdraw(amount: amount)
        }else{
            let amount = self.store.getListingPrice(listingID: listingID, token: Type<@GameToken.Fabatka>())
            let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from:GameToken.VaultStoragePath) ?? panic("Nincs collection")
            self.price <- vault.withdraw(amount: amount)
        }
       

    }

    execute {
        let goods <- self.store.purchase(id: listingID, payment: <- self.price,gamer:self.gamer)
        GameNFT.collect(loot:<- goods,collection:self.collection,fabatka:nil,flow:nil)
    }


}