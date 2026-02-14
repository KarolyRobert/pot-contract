import "GameNFT"
import "GameContent"
import "NonFungibleToken"
import "FungibleToken"
import "FlowToken"
import "GameToken"
import "GameIdentity"


access(all) contract GameMarket {

    access(all) entitlement CreateListing
    access(all) entitlement RemoveListing

    access(all) event ListingLevelNFT(action:String,seller:Address,listing:UInt64,flow:UFix64,fabatka:UFix64,nft:UInt64,category:String,type:String,level:Int)
    access(all) event ListingAvatarNFT(action:String,seller:Address,listing:UInt64,flow:UFix64,fabatka:UFix64,nft:UInt64,category:String,type:String,level:Int,skills:[String])
    access(all) event ListingCharmNFT(action:String,seller:Address,listing:UInt64,flow:UFix64,fabatka:UFix64,nft:UInt64,category:String,type:String,subtype:String,level:Int)
    access(all) event ListingPackNFT(action:String,seller:Address,listing:UInt64,flow:UFix64,fabatka:UFix64,nft:UInt64,category:String,type:String,size:Int)
    access(all) event ListingStack(action:String,seller:Address,listing:UInt64,flow:UFix64,fabatka:UFix64,nft:UInt64,category:String,type:String,size:Int)

    access(all) event DelistingNFT(action:String,seller:Address,listing:UInt64,category:String,type:String)
    access(all) event PurchaseNFT(action:String,seller:Address,listing:UInt64,category:String,type:String)

    access(all) let MarketStoragePath: StoragePath
    access(all) let MarketPublicPath: PublicPath

    access(contract) var lastID:UInt64

    access(all) resource interface IListing {
        access(all) let id:UInt64
        access(all) let type:String
        access(all) let offers:{Type:Offer}
        access(all) let createdAt:UFix64
        access(all) var soldAt:UFix64?
        access(all) var resolved:Bool
        access(all) var historyData:{String:AnyStruct}?
        access(all) var historyContent:{UInt64:{String:AnyStruct}}?

        access(all) view fun getData():{String:AnyStruct}
        access(all) view fun getContent():{UInt64:{String:AnyStruct}}
        access(all) view fun getPrice(token:Type):UFix64
        access(contract) fun resolve(sold:Bool,currency:String?,value:UFix64?):@[AnyResource]
    }

    access(all) struct Royalty {
        access(all) let royalty:UFix64
        access(all) let address:Address

        init(royalty:UFix64,address:Address) {
            self.royalty = royalty
            self.address = address
        }
    }

    access(all) struct Offer {
        access(all) let price:UFix64
        access(all) let royalty:Royalty

        init(token:String,price:UFix64,royalty:Royalty){
            self.price = price
            self.royalty = royalty
        }
    }

    access(all) resource NFTListing:IListing {
        access(all) let id:UInt64
        access(all) let type:String
        access(all) var listed:@{GameNFT.INFT}?
        access(all) let offers:{Type:Offer}
        access(all) let createdAt:UFix64
        access(all) var soldAt:UFix64?
        access(all) var resolved:Bool
        access(all) var historyData:{String:AnyStruct}?
        access(all) var historyContent:{UInt64:{String:AnyStruct}}?

        access(all) view fun getData():{String:AnyStruct} {
            if self.resolved {
                return self.historyData!
            }

            let nftData = ((&self.listed as &{NonFungibleToken.NFT}?) as! &{GameNFT.INFT}).getData()
            let offersData:{String:UFix64} = {}
            let offerTypes = self.offers.keys
            for offerType in offerTypes {
                let price = self.offers[offerType]!.price
                switch(offerType){
                    case Type<@FlowToken.Vault>():
                        offersData["flow"] = price
                        break
                    case Type<@GameToken.Fabatka>():
                        offersData["fabatka"] = price
                        break
                }  
            }
            return {
                "id":self.id,
                "type":self.type,
                "nft":nftData,
                "offers":offersData,
                "createdAt":self.createdAt
            }
        }

        access(all) view fun getContent():{UInt64:{String:AnyStruct}} {
            if self.resolved {
                return self.historyContent!
            }
            var result:{UInt64:{String:AnyStruct}} = {}
            if let nftRef = (&self.listed as &{GameNFT.INFT}?) as? &GameNFT.PackNFT {
                result = nftRef.getContent()
            }
            return result
        }

        access(all) view fun getPrice(token:Type):UFix64 {
            if let offer = self.offers[token] {
                return offer.price
            }
            return 0.0
        }

        access(all) view fun getNFT():&{GameNFT.INFT} {
            if(!self.resolved){
                return (&self.listed)!  
            }
            panic("Resolved!")
           
        }

        access(self) fun onResolve(sold:Bool,currency:String?,value:UFix64?) {
            if sold {
                let now = getCurrentBlock().timestamp
                let data = self.getData()
                let soldData:{String:AnyStruct} = {}
                soldData["soldAt"] = now
                soldData[currency!] = value!
                data["sold"] = soldData
                self.soldAt = now
                self.historyData = data
                self.historyContent = self.getContent()
                self.resolved = true
            }
            
        }

        access(contract) fun resolve(sold:Bool,currency:String?,value:UFix64?):@[AnyResource] {
            self.onResolve(sold:sold,currency:currency,value:value)
            let result:@[AnyResource] <- []
            let nft <- self.listed <- nil
            switch(self.type){
                case "nft":
                    result.append(<-nft)
                    return <- result
                case "stack":
                    if let stackNFT <- nft as? @GameNFT.PackNFT {
                        let pack <- stackNFT.unpack()
                        let keys = pack.keys
                        while keys.length > 0 {
                            let key = keys.removeFirst()
                            let nft <- pack.remove(key: key)!
                            result.append(<- nft)
                        }
                        destroy pack
                        destroy stackNFT
                        return <- result
                    }
            }
            panic("Illegal listing type!")
        }

        init(type:String,offers:{Type:Offer},listed:@{GameNFT.INFT}){
            post {
                GameMarket.lastID == before(GameMarket.lastID) + 1
                self.id == GameMarket.lastID
            }
            GameMarket.lastID = GameMarket.lastID + 1
            self.id = GameMarket.lastID
            self.type = type
            self.offers = offers
            self.listed <- listed
            self.createdAt = getCurrentBlock().timestamp
            self.soldAt = nil
            self.resolved = false
            self.historyData = nil
            self.historyContent = nil
        }
    }

    access(contract) fun createRoyalityOffers(offers:{String:UFix64}):{Type:Offer} {
        let consts = GameContent.getConsts()
        let policy = consts["policy"] as! &{String:AnyStruct}
        let royaltys = policy["royalty"] as! &{String:AnyStruct}
        let addr = policy["address"] as! &String
        let address = Address.fromString(*addr) ?? panic("Invalid royalty address!")
        let offerTypes = offers.keys
        if offerTypes.length > 0 {
            let royaltyOffers:{Type:Offer} = {}
            while offerTypes.length > 0 {
                let token = offerTypes.removeFirst()
                var tokenType:Type? = nil
                let price = offers[token]!
                var royaltyValue:&UFix64? = nil
                switch(token){
                    case "flow":
                        tokenType = Type<@FlowToken.Vault>()
                        royaltyValue = royaltys["flow"] as! &UFix64
                        break
                    case "fabatka":
                        tokenType = Type<@GameToken.Fabatka>()
                        royaltyValue = royaltys["fabatka"] as! &UFix64
                        break
                    default:
                        panic("Unsupported offer!")
                }
                if royaltyValue != nil && tokenType != nil {
                    let royalty = Royalty(royalty:*royaltyValue!,address:address)
                    let offer = Offer(token:token,price:price,royalty:royalty)
                    royaltyOffers[tokenType!] = offer
                    continue
                }
                panic("Missing royalty!")
            }
            return royaltyOffers
        }
        panic("Empty offers!")
    }

    access(self) fun emitListing(address:Address,listing:&{GameMarket.IListing}) {
        let emitNFT = fun () {

            let nft_listing = listing as! &NFTListing
            let offerKeys = nft_listing.offers.keys
            var flow:UFix64 = 0.0
            var fabatka:UFix64 = 0.0
            for type in offerKeys {
                if type == Type<@FlowToken.Vault>() {
                    let offer = nft_listing.offers[type]!
                    flow = offer.price
                }
                if type == Type<@GameToken.Fabatka>() {
                    let offer = nft_listing.offers[type]!
                    fabatka = offer.price
                }
            }
            let nft = nft_listing.getNFT()
            let nftData = nft.getData()

            let emitLevel = fun () {
                let meta = nftData["meta"] as! {String:AnyStruct}
                let level = meta["level"] as! Int
                emit ListingLevelNFT(action:"create",seller:address,listing:listing.id,flow:flow,fabatka:fabatka,nft:nft.id,category:nft.category,type:nft.type,level:level)
            }

            let emitCharm = fun () {
                let meta = nftData["meta"] as! {String:AnyStruct}
                let level = meta["level"] as! Int
                let subType = meta["type"] as! String
                emit ListingCharmNFT(action:"create",seller:address,listing:listing.id,flow:flow,fabatka:fabatka,nft:nft.id,category:nft.category,type:nft.type,subtype:subType,level:level)
            }

            let emitAvatar = fun () {
                let meta = nftData["meta"] as! {String:AnyStruct}
                let level = meta["level"] as! Int
                let nftSkills = meta["skills"] as! [{String:AnyStruct}]
                let skills:[String] = []
                for skill in nftSkills {
                    let skillName = skill["type"] as! String
                    skills.append(skillName)
                }
                emit ListingAvatarNFT(action:"create",seller:address,listing:listing.id,flow:flow,fabatka:fabatka,nft:nft.id,category:nft.category,type:nft.type,level:level,skills:skills)
            }
            let emitPack = fun () {
                let meta = nftData["meta"] as! {String:AnyStruct}
                let size = meta["size"] as! Int
                emit ListingPackNFT(action:"create",seller:address,listing:listing.id,flow:flow,fabatka:fabatka,nft:nft.id,category:nft.category,type:nft.type,size:size)
            }

            let emitStack = fun () {
                let meta = nftData["meta"] as! {String:AnyStruct}
                let size = meta["size"] as! Int
                let content = meta["content"] as! {String:AnyStruct}
                let category = content["category"] as! String
                let type = content["type"] as! String
                emit ListingStack(action:"create",seller:address,listing:listing.id,flow:flow,fabatka:fabatka,nft:nft.id,category:category,type:type,size:size)
            }

            switch(nft.category){
                case "item":
                    emitLevel()
                    break
                case "spell":
                    emitLevel()
                    break
                case "charm":
                    emitCharm()
                    break
                case "chest":
                    emitLevel()
                    break
                case "avatar":
                    emitAvatar()
                    break
                case "pack":
                    if(nft.type == "stack"){
                        emitStack()
                    }else{
                        emitPack()
                    }
                    break
                default:
                    panic("Illegal nft listing!")
            }
        }

        switch(listing.type){
            case "nft":
                emitNFT()
                break
            case "stack":
                emitNFT()
                break
        }
    }

    access(contract) fun createListingNFT(address:Address,type:String,sell:@[{GameNFT.INFT}]):@{GameNFT.INFT} {
         switch(type){
            case "nft":
                if sell.length == 1 {
                    let nft <- sell.removeFirst()
                    if nft.getType() == Type<@GameNFT.BaseNFT>() {
                        panic("Invalid Listing! BaseNFT listing not allowed!")
                    }
                    destroy sell
                    return <- nft
                }else{
                    panic("More then one nft!")
                }
            case "stack":
                let typeData = (&sell[0] as &{GameNFT.INFT}).getData() // as &{NonFungibleToken.NFT}) as! &{GameNFT.INFT}.getData()
                let stackCategory = typeData["category"] as! String
                let stackType = typeData["type"] as! String
                let stackRecord:@{UInt64: {GameNFT.INFT}} <- {}
                while sell.length > 0 {
                    // let id = keys.removeFirst()
                    let nft <- sell.removeFirst()
                    if let item <- nft as? @GameNFT.BaseNFT {
                        if item.category == stackCategory && item.type == stackType {
                            stackRecord[item.id] <-! item
                        }else {
                            panic("Illegal stack!")
                        }
                    }else{
                        panic("Illegal stack!")
                    }  
                }
                destroy sell
                let stack <- GameNFT.minter.mintPack(type: "stack", packed: <- stackRecord)
                return  <- stack
            default:
                panic("Illegal listing type!")
        }
    }

    access(all) resource ListingCollection {
        access(all) var revision:UInt64
        access(all) var listings:@{UInt64:{GameMarket.IListing}}
        access(all) var historyWindow:UFix64

        access(self) fun cleanExpired() {
            let now = getCurrentBlock().timestamp
            let ids = self.listings.keys
            for id in ids {
                let listingRef = (&self.listings[id] as &{GameMarket.IListing}?)!
                if(listingRef.resolved){
                     let expiredAt = listingRef.soldAt! + self.historyWindow
                     if expiredAt < now {
                        let listing <- self.listings.remove(key: id)
                        destroy listing
                     }
                }
            }
        }

        access(self) fun onRevision() {
            self.revision = self.revision + 1
        }

        access(CreateListing) fun nftListing(type:String,offers:{String:UFix64},sell:@[{GameNFT.INFT}]) {

            let owner = self.owner ?? panic("Must have Collection in storage!")

            let royaltyOffers = GameMarket.createRoyalityOffers(offers:offers)
            let listed <- GameMarket.createListingNFT(address:owner.address,type: type, sell:<- sell)
            let nftRef = &listed as &{GameNFT.INFT}
       
            let listing <- create NFTListing(type:type,offers:royaltyOffers,listed:<- listed)
            let listingRef = &listing as &{GameMarket.IListing}
            let id = listing.id

            GameMarket.emitListing(address:owner.address,listing:listingRef)
           
            self.listings[id] <-! listing
        }

        

        access(self) view fun getListingProps(type:String,data:{String:AnyStruct}):{String:String} {
             let nftData = data["nft"] as! {String:AnyStruct}
                var nftCategory = nftData["category"] as! String
                var nftType = nftData["type"] as! String
                if type == "stack" {
                    let stackMeta = nftData["meta"] as! {String:AnyStruct}
                    let stackContent = stackMeta["content"] as! {String:AnyStruct}
                    nftCategory = stackContent["category"] as! String
                    nftType = stackContent["type"] as! String
                }
            return {"category":nftCategory,"type":nftType}
        }



        access(RemoveListing) fun removeListing(id:UInt64):@[AnyResource] {
            let owner = self.owner ?? panic("Must have Collection in storage!")

            if let listing <- self.listings.remove(key: id) {
                let data = listing.getData()
                let props = self.getListingProps(type: listing.type, data: data)
                let result <- listing.resolve(sold:false,currency:nil,value:nil)

                destroy listing

                emit DelistingNFT(action:"delete",seller:owner.address,listing:id,category:props["category"]!,type:props["type"]!)
                return <- result
            }
            panic("Missing listing!")
        }

        access(RemoveListing) fun cleanResolved() {
            let keys = self.listings.keys
            while keys.length > 0 {
                let key = keys.removeFirst()
                if let listing = &self.listings[key] as &{GameMarket.IListing}? {
                    if listing.resolved {
                        let resolved <- self.listings.remove(key: key)!
                        destroy resolved
                    }
                }
            }
        }

        access(CreateListing) fun priceUpdate(id:UInt64,offers:{String:UFix64}) {
            if let listing = &self.listings[id] as &{GameMarket.IListing}? {

                let type = listing.type
                let delisted <- self.removeListing(id: id)
                let sell:@[{GameNFT.INFT}] <-[]
                while delisted.length > 0 {
                    let res <- delisted.removeFirst()
                    if let nft <- res as? @{GameNFT.INFT} {
                        sell.append( <- nft)
                    }else{
                        panic("Listing \(id.toString()) not an NFT listing!")
                    }
                }
                destroy delisted
                self.nftListing(type: type, offers: offers, sell: <- sell)
               
            }
        }

        access(all) fun purchase(id:UInt64,payment:@{FungibleToken.Vault},gamer: auth(GameIdentity.Market) &GameIdentity.Gamer):@[AnyResource] {

            self.onRevision()

            let seller = self.owner ?? panic("Must have Collection in storage!")
            let sellerGamer = seller.capabilities.borrow<&GameIdentity.Gamer>(GameIdentity.GamerPublicPath) ?? panic("Missing Seller Identity!")
          
            if let listing = &self.listings[id] as &{GameMarket.IListing}? {
                if listing.resolved { panic("Listing sold!") }
                let paymentType = payment.getType()
                let offer = listing.offers[paymentType] ?? panic("Unsuported payment!")
                let amount = payment.balance
                let listingData = listing.getData()
                let props = self.getListingProps(type: listing.type, data: listingData)
                
                if amount == offer.price {
                    let royalty = offer.royalty
                    let royaltyPrecent = royalty.royalty
                    let royaltyValue = amount * royaltyPrecent
                    let receiveAmount = amount - royaltyValue
                    let royalityAccount = getAccount(royalty.address)
                    let royaltyAmount <- payment.withdraw(amount: royaltyValue)
                    let soldValue = payment.balance
                    switch(paymentType){
                        case Type<@FlowToken.Vault>():
                            let sellerVault = seller.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenReceiver) ?? panic("Missing seller vault!")
                            let royaltyVault = royalityAccount.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenReceiver) ?? panic("Missing royalty vault")
                            royaltyVault.deposit(from: <- royaltyAmount)
                            sellerVault.deposit(from: <- payment)
                            sellerGamer.setTrade(token: "flow", spend: 0.0, trade: soldValue)
                            gamer.setTrade(token: "flow", spend: amount, trade: 0.0)
                            let result <- listing.resolve(sold:true,currency:"flow",value:soldValue)
                            emit PurchaseNFT(action:"delete",seller:seller.address,listing:id,category:props["category"]!,type:props["type"]!)
                            return <- result
                        case Type<@GameToken.Fabatka>():
                            let sellerVault = seller.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Missing seller vault!")
                            let royaltyVault = royalityAccount.capabilities.borrow<&GameToken.Fabatka>(GameToken.VaultPublicPath) ?? panic("Missing royalty vault")
                            royaltyVault.deposit(from: <- royaltyAmount)
                            sellerVault.deposit(from: <- payment)
                            sellerGamer.setTrade(token: "fabatka", spend: 0.0, trade: soldValue)
                            gamer.setTrade(token: "fabatka", spend: amount, trade: 0.0)
                            let result <- listing.resolve(sold:true,currency:"fabatka",value:soldValue)
                            emit PurchaseNFT(action:"delete",seller:seller.address,listing:id,category:props["category"]!,type:props["type"]!)
                            return <- result
                        default:
                            panic("Unsupported payment!")                               
                    }
                    
                }
                panic("Different amount!") 
            }
            panic("Missing listing!")
        }

        access(all) view fun getListingPrice(listingID:UInt64,token:Type):UFix64 {
            let listing = (&self.listings[listingID] as &{GameMarket.IListing}?)!
            return listing.getPrice(token: token)
        }

        access(all) view fun getListingData(listingID:UInt64):{String:AnyStruct} {
            let listing = (&self.listings[listingID] as &{GameMarket.IListing}?)!
            return listing.getData()
        }

        access(all) view fun getListingContent(listingID:UInt64):{UInt64:{String:AnyStruct}} {
            let listing = (&self.listings[listingID] as &{GameMarket.IListing}?)!
            return listing.getContent()
        }

        access(self) view fun getData(all:Bool):{UInt64:{String:AnyStruct}} {
            let result:{UInt64:{String:AnyStruct}} = {}
            let keys = self.listings.keys
            for id in keys {
                let listing = &self.listings[id] as &{GameMarket.IListing}?
                if !listing!.resolved || all {
                    result[id] = self.getListingData(listingID: id)
                }
            }
            return result 
        }

        access(all) view fun isPurchaseable(id:UInt64):Bool {
            if let listing = &self.listings[id] as &{GameMarket.IListing}? {
                return !listing.resolved
            }
            return false
        }

        access(all) view fun getListings():{UInt64:{String:AnyStruct}} {
            return self.getData(all:true)
        }

        access(all) view fun getStore():{UInt64:{String:AnyStruct}} {
            return self.getData(all:false)
        }

        access(all) view fun getRevision():UInt64 {
            return self.revision
        }

        init(){
            self.listings <- {}
            self.revision = 0
            self.historyWindow = 129600.0
        }
    }

    access(all) fun createEmptyMarket():@GameMarket.ListingCollection {
        return <- create GameMarket.ListingCollection()
    }

    init() {
        self.lastID = 0  
        self.MarketStoragePath = StoragePath(identifier: "Market_\(self.account.address.toString())")!
        self.MarketPublicPath = PublicPath(identifier: "Market_public\(self.account.address.toString())")!
    }
}