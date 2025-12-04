import "NonFungibleToken"
import "MetadataViews"
import "GameContent"
import "Meta"

access(all) contract GameNFT: NonFungibleToken {

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
                            url: "https://cloud.hobbyfork.com/images/".concat(self.category).concat("/").concat(self.type).concat(".png")
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
/* 
        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
*/
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

    access(all) resource MetaNFT: INFT {
        access(all) let id:UInt64
        access(all) let category:String
        access(all) let type:String
        access(all) let meta:Meta.MetaBuilder

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
                    break
                case "spell":
                    resultMeta["level"] = meta["level"]
                    resultMeta["needs"] = meta["needs"]
                    break
                case "avatar":
                    resultMeta["level"] = meta["level"]
                    resultMeta["subClass"] = meta["subClass"]
                    resultMeta["charm"] = meta["charm"]
                    resultMeta["skills"] = meta["skills"]
                    resultMeta["items"] = meta["items"]
                    resultMeta["spells"] = meta["spells"]
                    break
                case "charm":
                    resultMeta["level"] = meta["level"]
                    resultMeta["type"] = meta["type"]
                    break
                case "chest": // "level":10,"wLevel":2,"event":"default","class":"elit"
                    resultMeta["level"] = meta["level"]
                    resultMeta["wLevel"] = meta["wLevel"]
                    resultMeta["event"] = meta["event"]
                    resultMeta["class"] = meta["class"]
                    break
            }

            result["meta"] = resultMeta

            return result
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
        }
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @{GameNFT.INFT}
            log("deposit:")
            log(nft.getData())
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

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {
                Type<@GameNFT.BaseNFT>(): true,
                Type<@GameNFT.MetaNFT>(): true
            }
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@GameNFT.BaseNFT>() || type == Type<@GameNFT.MetaNFT>()
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



        access(Equip) fun setAvatarEquipment(avatarId:UInt64,equipment:{String:AnyStruct}) {
           
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
                        let zone = level / GameContent.zoneSize
                        let avatarClass = currentMeta["class"] as! String

                        if let talizmanRef = &self.ownedNFTs[newCharm] as &{NonFungibleToken.NFT}? {
                            if let talizman = talizmanRef as?  &GameNFT.MetaNFT {
                                if talizman.category == "charm" {
                                    currentMeta["charm"] = newCharm
                                }
                            }
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
                                }
                                if !set {
                                    currentSpells[index] = 0
                                }
                            } 
                        }

                        currentMeta["items"] = currentItems
                        currentMeta["spells"] = currentSpells
                        avatar.meta.update(currentMeta)
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


    init(){
        self.mintedCount = 0
        self.CollectionStoragePath = StoragePath(identifier: "PotNFT_".concat(self.account.address.toString()))!
        self.CollectionPublicPath = PublicPath(identifier: "PotNFT_public_".concat(self.account.address.toString()))!
        self.minter <- create Minter()
        
    }
}