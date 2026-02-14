import "GameNFT"
import "GameToken"
import "GameMarket"
import "Random"

transaction {

    prepare(acct:  auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {

        if acct.storage.borrow<&GameNFT.Collection>(from: GameNFT.CollectionStoragePath) != nil {
            log("Már van Collection!")
            return
        }
        
        let collection <- GameNFT.createEmptyCollection(nftType: Type<@GameNFT.BaseNFT>())
        acct.storage.save(<- collection, to: GameNFT.CollectionStoragePath)
        let collectionCap = acct.capabilities.storage.issue<&GameNFT.Collection>(GameNFT.CollectionStoragePath)
        acct.capabilities.publish(collectionCap, at: GameNFT.CollectionPublicPath)

        let vault <- GameToken.createEmptyVault(vaultType:Type<@GameToken.Fabatka>())
        acct.storage.save(<- vault, to: GameToken.VaultStoragePath)
        let vaultCap = acct.capabilities.storage.issue<&GameToken.Fabatka>(GameToken.VaultStoragePath)
        acct.capabilities.publish(vaultCap, at: GameToken.VaultPublicPath)

        let receiptStoreRes <- Random.createEmptyReceiptStore()
        acct.storage.save(<- receiptStoreRes, to: Random.ReceiptStoragePath)
        let receiptCap = acct.capabilities.storage.issue<&Random.ReceiptStore>(Random.ReceiptStoragePath)
        acct.capabilities.publish(receiptCap, at: Random.ReceiptPublicPath)

        let market <- GameMarket.createEmptyMarket()
        acct.storage.save(<- market, to: GameMarket.MarketStoragePath)
        let marketCap = acct.capabilities.storage.issue<&GameMarket.ListingCollection>(GameMarket.MarketStoragePath)
        acct.capabilities.publish(marketCap, at: GameMarket.MarketPublicPath)

    }

}

// flow transactions send cadence/transactions/CreateCollection.cdc --signer user1 --network emulator
