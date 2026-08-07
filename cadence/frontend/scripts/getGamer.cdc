import "GameToken"
import "FlowToken"
import "GameIdentity"

access(all) fun main(user:Address): {String:AnyStruct} {

    let account = getAccount(user)

    if let gamer = account.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
        if let fabatka = account.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) {
            if let flow = account.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenBalance) {
                return {
                    "type":"gamerState",
                    "fabatka":fabatka.balance,
                    "flow":flow.balance,
                    "identity":gamer.getIdentity()
                }
            }
        } 
    }
    return {"type":"error","error":"Missing Identity!"}
    

}
