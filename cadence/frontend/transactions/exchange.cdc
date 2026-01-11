import "GameContent"
import "GameNFT"
import "GameToken"
import "FungibleToken"
import "NonFungibleToken"
import "Exchange"


transaction(epoch:UInt64,buy:[UInt8],sell:[UInt64]) {

    prepare(user: auth (BorrowValue) &Account) {

        let collection = user.storage.borrow<auth (NonFungibleToken.Withdraw)  &GameNFT.Collection>(from:GameNFT.CollectionStoragePath) ?? panic("Collection")
        let vault = user.storage.borrow<auth (FungibleToken.Withdraw) &GameToken.Fabatka>(from: GameToken.VaultStoragePath) ?? panic("vault")
     
        let consts = GameContent.getConsts()
        let time = getCurrentBlock().timestamp
        let npc = Exchange.getNPC(epoch:epoch,time:UInt64(time))

        if npc != nil {
            let fabatka = GameContent.getConsts()["fabatka"] as! &{String:AnyStruct}
            let sellPrice = Exchange.getSellPrice(npc:npc!,buy:buy,fabatka:fabatka) // mennyibe kerül

            let sellArray:@[GameNFT.MetaNFT] <- []
            let sellGoods:[Exchange.SellGood] = []
            while sell.length > 0 {
                let sellId = sell.removeFirst()
                let sellNFT <- collection.withdraw(withdrawID: sellId) as! @GameNFT.MetaNFT
                let meta = sellNFT.getMeta()
                let category = sellNFT.category
                sellGoods.append(Exchange.SellGood(category:category,meta:meta))
                sellArray.append(<-sellNFT)
            }
            let buyPrice = Exchange.getBuyPrice(npc: npc!, sell: sellGoods, fabatka: fabatka)

            let price <- GameToken.createEmptyVault(vaultType:Type<@GameToken.Fabatka>()) as! @GameToken.Fabatka
            if sellPrice > buyPrice {
                let allPrice = sellPrice - buyPrice
                let amount <- vault.withdraw(amount: allPrice) as! @GameToken.Fabatka
                price.deposit(from: <- amount)
            }
            let goods <- Exchange.exchange(epoch: epoch, buy: buy, sell: <- sellArray, price: <- price)

            while goods.length > 0 {
                let res <- goods.removeFirst()
                if let base <- res as? @GameNFT.BaseNFT{
                    collection.deposit(token: <- base)
                }else if let token <- res as? @GameToken.Fabatka {
                    vault.deposit(from:<-token)
                }else{
                    panic("Unexpected result!")
                }
            }
            destroy goods

        }else{
            panic("Epoch expired!")
        }

    }



}