

access(all) contract Utils {


    access(all) let qualitys:[String]

    access(self) view fun chance(_ currentLevel:Int,_ mul:UFix64):UFix64 {
        var i = 0
        var result = 1.0
        while i < currentLevel {
            result = result * mul
            i = i + 1
        }
        return result
    }

    access(all) view fun getGrowChance(level:Int,category:String,Event:&{String:AnyStruct},Consts:&{String:AnyStruct}):UFix64{
        let growName = Event["growth"]! as! &String // az aktuális eventhez tartozó növekedési lista
        let growMuls = (Consts["growth"] as! &{String:AnyStruct})[*growName] as! &{String:UFix64} // az aktuális növekedési szorzók, categóriák szerint
        return self.chance(level,growMuls[category]!) // a növekedési szorzó
    }

    access(all) view fun getCompozitChance(main:Int,seconder:Int,category:String,Event:&{String:AnyStruct},Consts:&{String:AnyStruct}):UFix64 {
        let iterations = main - ((seconder * 100) / 130)
        return self.getGrowChance(level: iterations, category: category, Event: Event, Consts: Consts)
    }

    access(all) view fun getNeedCount(base:Int,level:Int,category:String,Consts:&{String:AnyStruct}):Int {
        let divider = Consts["needDiv"] as! &{String:Int}[category]!
        let addition = Int(UFix64(level)/UFix64(divider))
        return base + addition
    }


    access(all) view fun pow(base:UFix64,exp:Int):UFix64 {
        if exp == 0 {
            return 1.0
        }

        var result: UFix64 = 1.0
        var e = 0

        while e < exp {
            result = result * base
            e = e + 1
        }

        return result
    }

    access(all) view fun getUpgradePrice(category:String,meta:{String:AnyStruct},Consts:&{String:AnyStruct}):UFix64 {
        let level = meta["level"] as! Int
        let quality = meta["quality"] as! String
        let zone = meta["zone"] as! Int
        let fabatka = Consts["fabatka"] as! &{String:AnyStruct}
        let prices = fabatka["upgrade"] as! &{String:UFix64}
        let levelMul = self.pow(base:*(fabatka["level"] as! &UFix64),exp:level)
        let qualityMul = self.pow(base:*(fabatka["quality"] as! &UFix64),exp:self.getQualityIndex(quality))
        let zoneMul = self.pow(base:*(fabatka["zone"] as! &UFix64),exp:zone)
        let basePrice = prices[category]!
        return basePrice * levelMul * qualityMul * zoneMul
    }

    // ez a függvény csak az avatár fejlesztésekor van hasnálva
    access(all) view fun getPrice(category:String,level:Int,quality:String,Consts:&{String:AnyStruct}):UFix64 {
        let fabatka = Consts["fabatka"] as! &{String:AnyStruct}
        let prices = fabatka["upgrade"] as! &{String:UFix64}
        let levelMul = self.pow(base:*(fabatka["level"] as! &UFix64),exp:level)
        let qualityMul = self.pow(base:*(fabatka["quality"] as! &UFix64),exp:self.getQualityIndex(quality))
        let basePrice = prices[category]!
        return basePrice * levelMul * qualityMul
    }


    access(all) view fun chooseIndex(_ array:[UFix64],_ r:UFix64):Int {
        var cum: UFix64 = 0.0

        var i = 0
        while i < array.length {
            cum = cum + array[i]
            if r < cum {
                return i
            }
            i = i + 1
        }

        return array.length - 1
    }

    access(all) fun chooseSome(pool:[String],source:[Int]):[String]{
        let result:[String] = []
        while source.length > 0 {
            let index = source.removeFirst()
            result.append(pool.remove(at: index))
        }
        return result
    }

    access(all) fun chooseMore(_ array:[String],_ indexes:[Int]):[String] {
        let result:[String] = []
        while indexes.length > 0{
            let index = indexes.removeFirst()
            result.append(array[index])
        }
        return result
    }

    access(all) view fun getIndex(_ array:[String],_ value:String):Int {
        var result = 0
        var i = 0
        for key in array {
            if key == value {
                result = i
            }
            i = i + 1
        }
        return result
    }

    access(all) view fun getQualityIndex(_ quality:String):Int {
        return self.getIndex(self.qualitys,quality)
    }

    access(all) view fun getNeedBase(quality:String,category:String):Int {
        if category == "charm" {
            return (self.getQualityIndex(quality) + 2) / 2
        }else{
            return self.getQualityIndex(quality) + 1
        }
    }

    init(){
        self.qualitys = ["common","uncommon","rare","epic","legendary"]
    }

}