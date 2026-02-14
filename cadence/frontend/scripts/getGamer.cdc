import "GameToken"
import "FlowToken"
import "GameIdentity"

access(all) fun main(user:Address): {String:AnyStruct} {

    let result:{String:AnyStruct} = {}

    let account = getAccount(user)

    
    if let gamer = account.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
        if let fabatka = account.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
            if let flow = account.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenBalance) {
                return {
                    "fabatka":fabatka.balance,
                    "flow":flow.balance,
                    "identity":gamer.getIdentity()
                }
            }
        }
        return  gamer.getIdentity()   
    }else{
        return {"fabatka":0,"flow":0,"identity":{"avatar":"default","id":0}}
    }

}
