import "Burner"

import "RandomBeaconHistory"
import "Xorshift128plus"


/// See an example implementation in the repository: https://github.com/onflow/random-coin-toss

access(all) contract RandomConsumer {

  
    access(all) event RandomnessRequested(requestUUID: UInt64, block: UInt64)
    access(all) event RandomnessSourced(requestUUID: UInt64, block: UInt64, randomSource: [UInt8])
    access(all) event RandomnessFulfilled(requestUUID: UInt64, randomResult: UInt64)
    access(all) event RandomnessFulfilledWithPRG(requestUUID: UInt64)
    access(all) event RevealResult(success:Bool,nfts:[UInt64],token:UFix64,block:UInt64,receiptID:UInt64)

    access(all) fun createConsumer(): @Consumer {
        return <-create Consumer()
    }


    access(all) entitlement Commit
    access(all) entitlement Reveal

    /// Interface to allow for a Request to be contained within another resource. The existing default implementations
    /// enable an implementing resource to simply list the conformance without any additional implementation aside from
    /// the inner Request resource. However, implementations should properly consider the optional when interacting
    /// with the inner resource outside of the default implementations. The post-conditions ensure that implementations
    /// cannot act dishonestly even if they override the default implementations.
    ///

    access(all) resource RevealOutcome {
        access(all) let success:Bool
        access(all) let nftIds:[UInt64]
        access(all) let tokenBalance:UFix64
        access(all) var result:@[AnyResource]?

        access(all) fun getResult():@[AnyResource] {
            let result <- self.result <- nil
            return <- result!
        }

        init(success:Bool,ids:[UInt64],balance:UFix64,result:@[AnyResource]){
            self.success = success
            self.nftIds = ids
            self.tokenBalance = balance
            self.result <- result
        }
    }

    access(all) fun createOutcome(success:Bool,ids:[UInt64],balance:UFix64,result:@[AnyResource]):@RevealOutcome {
        return <- create RevealOutcome(success:success,ids:ids,balance:balance,result: <- result)
    }

    access(all) resource interface RequestWrapper {
        /// The Request contained within the resource
        access(all) var request: @Request?
        

        
        access(all) view fun getData():{String:AnyStruct}

        access(contract) fun resolve():@RevealOutcome

        access(Reveal) fun reveal():@[AnyResource] {
            let result <- self.resolve()
            let block = getCurrentBlock().height
            emit RevealResult(success:result.success,nfts:result.nftIds,token:result.tokenBalance,block:block,receiptID:self.uuid)
            let loot <- result.getResult()
            destroy result
            return <- loot
        }

        /// Returns the block height of the Request contained within the resource
        ///
        /// @return The block height of the Request or nil if no Request is contained
        ///
        access(all) view fun getRequestBlock(): UInt64? {
            post {
                result == nil || result! == self.request?.block:
                "RandomConsumer.RequestWrapper.getRequestBlock(): Must return nil or the block height of RequestWrapper.request"
            }
            return self.request?.block ?? nil
        }

        /// Returns whether the Request contained within the resource can be fulfilled or not
        ///
        /// @return Whether the Request can be fulfilled
        ///
        access(all) view fun canFullfillRequest(): Bool {
            post {
                result == self.request?.canFullfill() ?? false:
                "RandomConsumer.RequestWrapper.canFullfillRequest(): Must return the result of RequestWrapper.request.canFullfill()"
            }
            return self.request?.canFullfill() ?? false
        }

        /// Pops the Request from the resource and returns it
        ///
        /// @return The Request that was contained within the resource
        ///
        access(Reveal) fun popRequest(): @Request {
            pre {
                self.request != nil: "RandomConsumer.RequestWrapper.popRequest(): Request must not be nil before popRequest"
            }
            post {
                self.request == nil:
                "RandomConsumer.RequestWrapper.popRequest(): Request must be nil after popRequest"
                result.uuid == before((self.request?.uuid)!):
                "RandomConsumer.RequestWrapper.popRequest(): Request uuid must match result uuid"
            }
            let req <- self.request <- nil
            return <- req!
        }

    }

    /// A resource representing a request for randomness
    ///
    access(all) resource Request {
        /// The block height at which the request was made
        access(all) let block: UInt64
        /// Whether the request has been fulfilled
        access(all) var fulfilled: Bool

        init(_ blockHeight: UInt64) {
            pre {
                getCurrentBlock().height <= blockHeight:
                "Requested randomness for block \(blockHeight) which has passed. Can only request randomness sourced from future block heights."
            }
            self.block = blockHeight
            self.fulfilled = false
        }

        /// Returns whether the request can be fulfilled as defined by whether it has already been fulfilled and the
        /// created block height has been surpassed.
        ///
        /// @param: True if it can be fulfilled, false otherwise
        ///
        access(all) view fun canFullfill(): Bool {
            return !self.fulfilled && getCurrentBlock().height > self.block
        }

        /// Returns the Flow's random source for the requested block height
        ///
        /// @return The random source for the requested block height containing at least 16 bytes (128 bits) of entropy
        ///
        access(contract) fun _fulfill(): [UInt8] {
            pre {
                !self.fulfilled:
                "RandomConsumer.Request.fulfill(): The random request has already been fulfilled."
                self.block < getCurrentBlock().height:
                "RandomConsumer.Request.fulfill(): Cannot fulfill random request before the eligible block height of \((self.block + 1).toString())"
            }
            self.fulfilled = true
            let res = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: self.block).value

            emit RandomnessSourced(requestUUID: self.uuid, block: self.block, randomSource: res)

            return res
        }
    }

    /// This resource enables the easy implementation of secure randomness, implementing the commit-reveal pattern and
    /// using a PRG to generate random numbers from the protocol's random source.
    ///
    access(all) resource Consumer {

        /* ----- COMMIT STEP ----- */
        //
        /// Requests randomness, returning a Request resource
        ///
        /// @return A Request resource
        ///
        access(Commit) fun requestRandomness(): @Request {
            post {
                result.block == getCurrentBlock().height:
                "Requested randomness for block height \(getCurrentBlock().height) but returned Request for randomness at block \(result.block)"
            }
            let currentHeight = getCurrentBlock().height
            let req <-create Request(currentHeight)
            emit RandomnessRequested(requestUUID: req.uuid, block: req.block)
            return <-req
        }

        /// Requests randomness sourced from a future block height, returning a Request resource
        ///
        /// @param at: The future block height for which randomness should be sourced
        ///
        /// @return A Request resource
        ///
        access(Commit) fun requestFutureRandomness(at blockHeight: UInt64): @Request  {
            post {
                blockHeight == result.block:
                "Requested randomness for block height \(blockHeight) but returned Request for randomness at block \(result.block)"
            }
            let req <-create Request(blockHeight)
            emit RandomnessRequested(requestUUID: req.uuid, block: req.block)
            return <-req
        }

        /* ----- REVEAL STEP ----- */
        //
        /// Fulfills a random request, returning a random number
        ///
        /// @param request: The Request to fulfill
        ///
        /// @return A random number
        ///
        access(Reveal) fun fulfillRandomRequest(_ request: @Request): UInt64 {
            let reqUUID = request.uuid

            // Create PRG from the provided request & generate a random number
            let prg = self._getPRGFromRequest(request: <-request)
            let res = prg.nextUInt64()

            emit RandomnessFulfilled(requestUUID: reqUUID, randomResult: res)
            return res
        }

        /// Fulfills a random request, returning a random number in the range [min, max] without bias. Developers may be
        /// tempted to use a simple modulo operation to generate random numbers in a range, but this can introduce bias
        /// when the range is not a multiple of the modulus. This function ensures that the random number is generated
        /// without bias using a variation on rejection sampling.
        ///
        /// @param request: The Request to fulfill
        /// @param min: The minimum value of the range
        /// @param max: The maximum value of the range
        ///
        /// @return A random number in the range [min, max]
        ///
        /* 
        access(Reveal) fun fulfillRandomInRange(request: @Request, min: UInt64, max: UInt64): UInt64 {
            pre {
                min < max:
                "RandomConsumer.Consumer.fulfillRandomInRange(): Cannot fulfill random number with the provided range! "
                .concat(" The min must be less than the max. Provided min of ")
                .concat(min.toString()).concat(" and max of ".concat(max.toString()))
            }
            let reqUUID = request.uuid

            // Create PRG from the provided request & generate a random number & generate a random number in the range
            let prg = self._getPRGFromRequest(request: <-request)
            let prgRef: &Xorshift128plus.PRG = &prg
            let res = RandomConsumer.getNumberInRange(prg: prgRef, min: min, max: max)

            emit RandomnessFulfilled(requestUUID: reqUUID, randomResult: res)

            return res
        }
*/
        /// Creates a PRG from a Request, using the request's block height source of randomness and UUID as a salt.
        /// This method fulfills the request, returning a PRG so that consumers can generate any number of random values
        /// using the request's source of randomness, seeded with the request's UUID as a salt.
        ///
        /// NOTE: The intention in exposing this method is for consumers to be able to generate several random values
        /// per request, and the returned PRG should be used in association to a single request. IOW, while the PRG is
        /// a storable object, it should be treated as ephemeral, discarding once all values have been generated
        /// corresponding to the fulfilled request.
        ///
        /// @param request: The Request to use for PRG creation
        ///
        /// @return A PRG object from which to generate random values in assocation with the fulfilled request
        ///
        access(Reveal) fun fulfillWithPRG(request: @Request): Xorshift128plus.PRG {
            let reqUUID = request.uuid
            let prg = self._getPRGFromRequest(request: <-request)

            emit RandomnessFulfilledWithPRG(requestUUID: reqUUID)

            return prg
        }

        /// Internal method to retrieve a PRG from a request. Doing so fulfills the request, and is intended for
        /// internal functionality serving a single random value.
        ///
        /// @param request: The Request to use for PRG creation
        ///
        /// @return A PRG object from which this Consumer can generate a single random value to fulfill the request
        ///
        access(self) fun _getPRGFromRequest(request: @Request): Xorshift128plus.PRG {
            let source = request._fulfill()
            let salt = request.uuid.toBigEndianBytes()
            Burner.burn(<-request)

            return Xorshift128plus.PRG(sourceOfRandomness: source, salt: salt)
        }
    }

    /// Returns the most significant bit of a UInt64
    ///
    /// @param x: The UInt64 to find the most significant bit of
    ///
    /// @return The most significant bit of x
    ///
    /* 
    access(self) view fun _mostSignificantBit(_ x: UInt64): UInt8 {
        var bits: UInt8 = 0
        var tmp: UInt64 = x
        while tmp > 0 {
            tmp = tmp >> 1
            bits = bits + 1
        }
        return bits
    }
*/
    /// Returns an authorized reference on the contract account's stored Consumer
    ///
    /* 
    access(self)
    fun borrowConsumer(): auth(Commit, Reveal) &Consumer {
        let path = /storage/consumer
        return self.account.storage.borrow<auth(Commit, Reveal) &Consumer>(from: path)
            ?? panic("Consumer not found - ensure the Consumer has been initialized at \(path)")
    }
*/
    init() {
     //   self.ConsumerStoragePath = StoragePath(identifier: "RandomConsumer_".concat(self.account.address.toString()))!

       // self.account.storage.save(<-create Consumer(), to: /storage/consumer)
    }
}