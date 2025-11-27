
import "ViewResolver"
import "MetadataViews"
import "FungibleToken" 


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
            return []
        }

         access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
         }

        init(balance:UFix64) {
            self.balance = balance
        }
    }

    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <- create GameToken.Fabatka(balance:0.0)
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
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