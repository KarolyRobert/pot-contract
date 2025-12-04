
import "ViewResolver"
import "MetadataViews"
import "FungibleToken"
import "FungibleTokenMetadataViews"


access(all) contract GameToken: FungibleToken {

    access(all) var totalSupply:UFix64

    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath

    access(all) resource Fabatka: FungibleToken.Vault {
        
        access(all) var balance: UFix64

        access(contract) fun burnCallback() {
            GameToken.totalSupply = GameToken.totalSupply - self.balance    
        }

        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
             return { Type<@GameToken.Fabatka>(): true }
        }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @GameToken.Fabatka
            self.balance = self.balance + vault.balance
            destroy vault
        }

        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            self.balance = self.balance - amount
            return <-create GameToken.Fabatka(balance: amount)
        }

        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            let vault <- create GameToken.Fabatka(balance:0.0) as @{FungibleToken.Vault}
            return <- vault
        }

        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance > amount
        }

        access(all) view fun getViews(): [Type] {
            return GameToken.getContractViews(resourceType: nil)
        }

         access(all) fun resolveView(_ view: Type): AnyStruct? {
             return GameToken.resolveContractView(resourceType: nil, viewType: view)
         }

        init(balance:UFix64) {
            self.balance = balance
        }
    }

    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <- create GameToken.Fabatka(balance:0.0)
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [ 
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
         switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        // Change this to your own SVG image
                        url: "https://cloud.hobbyfork.com/images/token/Fabatka.png"
                    ),
                    mediaType: "image/png"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    // Change these to represent your own token
                    name: "Fabatka",
                    symbol: "TPTF",
                    description: "Fabatka is the standard currency of the heroes in The Power of Truth. Earned through quests and battles, it is used for crafting, upgrades, and special interactions.",
                    externalURL: MetadataViews.ExternalURL("https://cloud.hobbyfork.com/images/fabatka/Fabatka256.png"),
                    logos: medias,
                    socials: {}
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.VaultStoragePath,
                    receiverPath: self.VaultPublicPath,
                    metadataPath: self.VaultPublicPath,
                    receiverLinkedType: Type<&GameToken.Fabatka>(),
                    metadataLinkedType: Type<&GameToken.Fabatka>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-GameToken.createEmptyVault(vaultType: Type<@GameToken.Fabatka>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: GameToken.totalSupply
                )
        }
        return nil
    }

    access(account) fun createFabatka(balance:UFix64):@{FungibleToken.Vault} {
        self.totalSupply = self.totalSupply + balance
        return <- create GameToken.Fabatka(balance:balance)
    }

    init() {
        self.totalSupply = 0.0
        self.VaultStoragePath = StoragePath(identifier: "Fabatka_".concat(self.account.address.toString()))!
        self.VaultPublicPath = PublicPath(identifier: "Fabatka_public_".concat(self.account.address.toString()))!
    }
}