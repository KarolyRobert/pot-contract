
import "GameIdentity"

access(all) fun main(users:[Address]): {String:AnyStruct} {

    let result:{String:AnyStruct} = {}

    while users.length > 0 {
        let address = users.removeFirst()
        let account = getAccount(address)
        if let gamer = account.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) {
            let identity = gamer.getIdentity()
            result[address.toString()] =  {"address":address,"identity":identity}
        }else{
            result[address.toString()] = {"address":address,"identity":{"avatar":"default","id":0}}
        }
       
    }
    return result

}
