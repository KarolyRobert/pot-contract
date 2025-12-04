import "Random"

access(all) fun main():{String:AnyStruct} {

   
// //type:String,gameId:String,hash:String,level:Int,wLevel:Int,chestEvent:String,class:String
    fun toChest(_ chest:String):{String:AnyStruct} {
        fun toInt(_ s: String): Int {
            var result: Int = 0
            for c in s.utf8 {
                let digit: Int = Int(c) - 48
                result = result * 10 + digit
            }
            return result
        }
        let parts = chest.split(separator: "|")
        return {
            "type":parts[0],
            "gameID":parts[1],
            "hash":parts[2],
            "meta":{
                "level":toInt(parts[3]),
                "wLevel":toInt(parts[4]),
                "event":parts[5],
                "class":parts[6]
            }
        }
    }

    return toChest("monster|gameID|sdfdfdg|3456753|45|default|mob")
}