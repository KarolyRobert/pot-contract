import "NonFungibleToken"
import "MetadataViews"
import "GameContent"
import "GameToken"
import "FlowToken"
import "Meta"

access(all) contract GameNFT: NonFungibleToken {

    access(all) event EquipAvatar(avatarID:UInt64)

    access(all) entitlement Equip

    access(contract) var mintedCount:UInt64

    /// Standard Paths
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
  

    access(account) let minter: @Minter

    access(all) resource interface INFT:NonFungibleToken.NFT {
        access(all) let id:UInt64
        access(all) let category:String
        access(all) let type:String

        access(all) view fun getData():{String:AnyStruct}

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "RoGeR NFT",
                        description: "Something useful in The Power of Truth game.",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://cloud.hobbyfork.com/images/\(self.category)/\(self.type).png"
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Initial Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return GameNFT.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>())
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return GameNFT.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>())
            }
            return nil
        }
    }

    access(all) resource BaseNFT: INFT{
        access(all) let id:UInt64
        access(all) let category:String
        access(all) let type:String

        access(all) view fun getData():{String:AnyStruct} {
            return {
                "id":self.id,
                "category":self.category,
                "type":self.type
            }
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-GameNFT.createEmptyCollection(nftType: Type<@GameNFT.BaseNFT>())
        }

        init(category:String,type:String){

            post {
                GameNFT.mintedCount == before(GameNFT.mintedCount) + 1
                self.id == GameNFT.mintedCount
            }

            GameNFT.mintedCount = GameNFT.mintedCount + 1
            self.id = GameNFT.mintedCount
            self.category = category
            self.type = type
        }

    }

    access(all) resource PackNFT: INFT {
        access(all) let id:UInt64
        access(all) let category:String
        access(all) let type:String
        access(account) var packed: @{UInt64: {GameNFT.INFT}}

        access(all) view fun getData():{String:AnyStruct} {
            let result:{String:AnyStruct} = {
                "id":self.id,
                "category":self.category,
                "type":self.type
            }
            let keys = self.packed.keys
            let meta:{String:AnyStruct} = {}
            meta["size"] = keys.length
            switch(self.type){
                case "box":
                    break
                case "stack":
                    let nftType = (&self.packed[keys[0]] as &{GameNFT.INFT}?)!.getData()
                    let category = nftType["category"] as! String
                    let type = nftType["type"] as! String
                    meta["content"] = {"category":category,"type":type}
                    break
            }
            result["meta"] = meta
            return result
        }

        access(all) view fun getContent():{UInt64:{String:AnyStruct}} {
            let result:{UInt64:{String:AnyStruct}} = {}
            let ids = self.packed.keys
            for id in ids {
                result[id] = (&self.packed[id] as &{GameNFT.INFT}?)!.getData()
            }
            return result
        }

        access(account) fun unpack():@{UInt64: {GameNFT.INFT}} {
            let packed:@{UInt64: {GameNFT.INFT}} <- self.packed <- {}
            return <- packed 
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-GameNFT.createEmptyCollection(nftType: Type<@GameNFT.PackNFT>())
        }

        init(category:String,type:String,packed:@{UInt64: {GameNFT.INFT}}){
            post {
                GameNFT.mintedCount == before(GameNFT.mintedCount) + 1
                self.id == GameNFT.mintedCount
            }
            GameNFT.mintedCount = GameNFT.mintedCount + 1
            self.id = GameNFT.mintedCount
            self.category = category
            self.type = type
            self.packed <- packed
        }
    }

    access(all) resource MetaNFT: INFT {
        access(all) let id:UInt64
        access(all) let category:String
        access(all) let type:String
        access(all) let meta:Meta.MetaBuilder
        access(account) var changeBlock:UInt64

        access(all) view fun getData():{String:AnyStruct} {
            let meta = self.meta.build()
            let result:{String:AnyStruct} = {
                "id":self.id,
                "category":self.category,
                "type":self.type
            }
            var resultMeta:{String:AnyStruct} = {}
            switch(self.category){
                case "item":
                    resultMeta["level"] = meta["level"]
                    resultMeta["needs"] = meta["needs"]
                    resultMeta["fate"] = meta["fate"]
                    break
                case "spell":
                    resultMeta["level"] = meta["level"]
                    resultMeta["needs"] = meta["needs"]
                    resultMeta["fate"] = meta["fate"]
                    break
                case "avatar":
                    resultMeta["level"] = meta["level"]
                    resultMeta["class"] = meta["class"]
                    resultMeta["subClass"] = meta["subClass"]
                    resultMeta["charm"] = meta["charm"]
                    resultMeta["skills"] = meta["skills"]
                    resultMeta["items"] = meta["items"]
                    resultMeta["spells"] = meta["spells"]
                    if let name = meta["name"] as? String {
                        resultMeta["name"] = name
                    }
                    break
                case "charm":
                    resultMeta["level"] = meta["level"]
                    resultMeta["type"] = meta["type"]
                    resultMeta["needs"] = meta["needs"]
                    break
                case "chest": // "level":10,"wLevel":2,"event":"default","class":"elit"
                    resultMeta["level"] = meta["level"]
                    resultMeta["wLevel"] = meta["wLevel"]
                    resultMeta["event"] = meta["event"]
                    resultMeta["class"] = meta["class"]
                    if let charm = meta["charm"] as? {String:AnyStruct} {
                        resultMeta["charm"] = charm
                    }
                    break
            }

            result["meta"] = resultMeta

            return result
        }
      
        access(all) view fun getMeta():{String:AnyStruct} {
            return self.meta.build()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-GameNFT.createEmptyCollection(nftType: Type<@GameNFT.MetaNFT>())
        }

        init(category:String,type:String,meta:{String:AnyStruct}){
            post {
                GameNFT.mintedCount == before(GameNFT.mintedCount) + 1
                self.id == GameNFT.mintedCount
            }
            GameNFT.mintedCount = GameNFT.mintedCount + 1
            self.id = GameNFT.mintedCount
            self.category = category
            self.type = type
            self.meta = Meta.MetaBuilder(meta)
            self.changeBlock = getCurrentBlock().height
        }
    }



    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @{GameNFT.INFT}
            self.ownedNFTs[nft.id] <-! nft
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let nft <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("NFT not found")
            return <- nft
        }

        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
             return &self.ownedNFTs[id] // as &{NonFungibleToken.NFT} 
        }

        access(NonFungibleToken.Withdraw) fun unpack(packID: UInt64) {
            let pack <- self.withdraw(withdrawID: packID) as! @GameNFT.PackNFT
            let content <- pack.unpack()
            let keys = content.keys
            while keys.length > 0 {
                let key = keys.removeFirst()
                let nft <- content.remove(key: key)!
                self.deposit(token: <- nft)
            }
            destroy content
            destroy pack
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {
                Type<@GameNFT.BaseNFT>(): true,
                Type<@GameNFT.MetaNFT>(): true,
                Type<@GameNFT.PackNFT>(): true
            }
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@GameNFT.BaseNFT>() || type == Type<@GameNFT.MetaNFT>() || type == Type<@GameNFT.PackNFT>()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <-GameNFT.createEmptyCollection(nftType: Type<@GameNFT.BaseNFT>())
        }

        access(all) view fun getData():{UInt64:{String:AnyStruct}} {
            let keys = self.ownedNFTs.keys
            let result:{UInt64:{String:AnyStruct}} = {}
            for id in keys {
                result[id] = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?) as! &{GameNFT.INFT}.getData()
            }
            return result
        }

        access(all) view fun getPackContent(_ id:UInt64):{UInt64:{String:AnyStruct}} {
            return ((&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?) as! &GameNFT.PackNFT).getContent()
        }

        access(all) view fun getLoot(_ ids:[UInt64]):{UInt64:{String:AnyStruct}} {
            let result:{UInt64:{String:AnyStruct}} = {}
            for id in ids {
                result[id] = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?) as! &{GameNFT.INFT}.getData()
            }
            return result
        }

        access(all) view fun getAvatar(avatarId:UInt64):{UInt64:{String:AnyStruct}} {
            let result:{UInt64:{String:AnyStruct}} = {}

            let avatarRef = (&self.ownedNFTs[avatarId] as &{NonFungibleToken.NFT}?) ?? panic("Avatar not found!")
            let avatar = avatarRef as! &GameNFT.MetaNFT
            let avatarData = avatar.getData()
            let avatarMeta = avatarData["meta"] as! {String:AnyStruct}
            let items = avatarMeta["items"] as! {String:UInt64}
            let spells = avatarMeta["spells"] as! {Int:UInt64}
            
            result[avatarData["id"] as! UInt64] = avatarData
            for class in items.keys {
                let id = items[class]!
                if let itemRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                    let item = itemRef as! &GameNFT.MetaNFT
                    let data = item.getData()
                    result[data["id"] as! UInt64] = data
                }
            }
            for index in spells.keys {
                let id = spells[index]!
                if let spellRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                    let spell = spellRef as! &GameNFT.MetaNFT
                    let data = spell.getData()
                    result[data["id"] as! UInt64] = data
                }
            }
            return result
        }

        access(all) view fun getGear(avatarId:UInt64):{String:AnyStruct} {
            let block = getCurrentBlock().height
            let gear = self.getAvatar(avatarId: avatarId)
            return {
                "type":"gear",
                "blockHeight":block,
                "gear":gear
            }
        }

        access(Equip) fun setAvatarEquipment(avatarId:UInt64,equipment:{String:AnyStruct}) {
            
            let consts = GameContent.getConsts()
            let zoneSize = consts["zoneSize"] as! &Int

            if let avatarRef = &self.ownedNFTs[avatarId] as &{NonFungibleToken.NFT}? {
                if let avatar = avatarRef as? &GameNFT.MetaNFT {
                    if avatar.category == "avatar" {
                        let currentMeta = avatar.meta.build()
                        let currentItems = currentMeta["items"] as! {String:UInt64}
                        let currentSpells = currentMeta["spells"] as! {Int:UInt64}
                        let newCharm = equipment["charm"] as! UInt64
                        let newItems = equipment["items"] as! {String:UInt64}
                        let newSpells = equipment["spells"] as! {Int:UInt64}
                        let level = currentMeta["level"] as! Int
                        let zone = level / *zoneSize
                        let avatarClass = currentMeta["class"] as! String

                        if let charmRef = &self.ownedNFTs[newCharm] as &{NonFungibleToken.NFT}? {
                            if let talizman = charmRef as?  &GameNFT.MetaNFT {
                                if talizman.category == "charm" {
                                    currentMeta["charm"] = newCharm
                                }
                            }
                        }else{
                            currentMeta["charm"] = newCharm
                        }

                        for class in currentItems.keys {
                            if let iid = newItems[class] {
                                if let itemRef = &self.ownedNFTs[iid] as &{NonFungibleToken.NFT}? {
                                    if let item = itemRef as? &GameNFT.MetaNFT {
                                        if item.category == "item" {
                                            let itemMeta = item.meta.build()
                                            let itemClass = itemMeta["class"] as! String
                                            let useFor = itemMeta["useFor"] as! [String]
                                            let itemZone = itemMeta["zone"] as! Int
                                            if class == itemClass && itemZone <= zone && useFor.contains(avatarClass) {
                                                currentItems[class] = iid
                                            }
                                        } 
                                    }
                                }else{
                                    currentItems[class] = iid
                                }
                            } 
                        }

                        let sids:{UInt64:Bool} = {}

                        for index in currentSpells.keys {
                            var set:Bool = false
                            let sid = newSpells[index]! 
                            if sids[sid] == true {
                                currentSpells[index] = 0
                            }else{
                                sids[sid] = true
                                if let spellRef =  &self.ownedNFTs[sid] as &{NonFungibleToken.NFT}? {
                                    if let spell = spellRef as? &GameNFT.MetaNFT {
                                        if spell.category == "spell" {
                                            currentSpells[index] = sid
                                            set = true
                                        }
                                    }
                                }else{
                                    currentSpells[index] = sid
                                    set = true
                                }
                                if !set {
                                    currentSpells[index] = 0
                                }
                            } 
                        }

                        currentMeta["items"] = currentItems
                        currentMeta["spells"] = currentSpells
                        avatar.meta.update(currentMeta)
                        emit EquipAvatar(avatarID:avatarId)
                    }
                }
            }
        }

        init(){
            self.ownedNFTs <- {}
        }
    }

    access(all) resource Minter {

        /// Only the Minter can create NFTs
        access(all) fun mintBase(category:String,type:String): @{INFT} {//@GameNFT.BaseNFT {
            return <-create GameNFT.BaseNFT(category:category,type:type)
        }

        access(all) fun mintMeta(category:String,type:String,meta:{String:AnyStruct}): @{INFT} {   //@GameNFT.MetaNFT{NonFungibleToken.NFT} {
            return <-create GameNFT.MetaNFT(category:category,type:type,meta:meta)
        }

        access(all) fun mintPack(type:String,packed:@{UInt64: {GameNFT.INFT}}): @PackNFT {
            return <-create GameNFT.PackNFT(category:"pack",type:type,packed: <- packed)
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let collectionData = MetadataViews.NFTCollectionData(
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&GameNFT.Collection>(),
                    publicLinkedType: Type<&GameNFT.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-GameNFT.createEmptyCollection(nftType: Type<@GameNFT.BaseNFT>())
                    })
                )
                return collectionData
            case Type<MetadataViews.NFTCollectionDisplay>():
                let logo = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://cloud.hobbyfork.com/images/collection/logo.png"
                    ),
                    mediaType: "image/png"
                )
                let banner = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://cloud.hobbyfork.com/images/collection/banner.jpg"
                    ),
                    mediaType: "image/jpeg"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "The Power of Truth",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://cloud.hobbyfork.com/the_power_of_truth"),
                    squareImage: logo,
                    bannerImage: banner,
                    socials: {} 
                )
        }
        return nil
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }

    access(all) fun collect(loot:@[AnyResource],collection:&GameNFT.Collection?,fabatka:&GameToken.Fabatka?,flow:&FlowToken.Vault?){
        while loot.length > 0 {
            let res <- loot.removeFirst()
            if let base <- res as? @GameNFT.BaseNFT{
                collection!.deposit(token: <- base)
            }else if let meta <- res as? @GameNFT.MetaNFT{
                collection!.deposit(token: <- meta)
            }else if let pack <- res as? @GameNFT.PackNFT{
                collection!.deposit(token: <- pack)
            }else if let token <- res as? @GameToken.Fabatka {
                fabatka!.deposit(from:<-token)
            }else if let flowToken <- res as? @FlowToken.Vault {
                flow!.deposit(from: <- flowToken)
            }else{
                panic("Unexpected result!")
            }
        }
        destroy loot
    }

    init(){
        self.mintedCount = 0
        self.CollectionStoragePath = StoragePath(identifier: "PotNFT_\(self.account.address.toString())")!
        self.CollectionPublicPath = PublicPath(identifier: "PotNFT_public_\(self.account.address.toString())")!
        self.minter <- create Minter()
    }
}