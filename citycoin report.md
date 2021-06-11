# CityCoin Report

[Product Requirements](https://github.com/citycoins/citycoin/blob/main/citycoin-prd.md)

[Smart Contract Source Code](https://github.com/citycoins/citycoin/blob/main/contracts/citycoin.clar)

## Overview

In order to create a smart contract that simulates Proof of Transfer (PoX) to reward CityCoin holders and contribute to a general fund for the respective city. 

As miners compete to mint new CityCoins, a portion of the Stacks tokens that miners spend are deposited into a custodied wallet on the Stacks blockchain, and available for the city leaders to take control of at any time.

There are no time restrictions for city leaders to take control of the funds, nor any usage restrictions for city leaders to decide how the funds should be spent.

This enables a global market in which participants can show support for a city while simultaneously contributing to its local economy.

## Stakeholder Identification

**City Leaders:** provide a new source of funding and encourage constituent participation in designated use of funds.

**Citizens:** provide a method to invest directly in the city through mining of the CityCoin, purchase of the CityCoin, and holding/Stacking of the CityCoin.

**Corporations:** provide a method to invest directly in the city through mining of the CityCoin, purchase of the CityCoin, and holding/Stacking of the CityCoin.

**External Supporters:** provide a method to invest directly in the city through mining of the CityCoin, purchase of the CityCoin, and holding/Stacking of the CityCoin.

## Functionalities

Every city will have its own contract, all of them are copied from [CityCoin contract](https://github.com/citycoins/citycoin/blob/main/contracts/citycoin.clar).

### Mining

Mining process works as POX, the user will send STX to the contract created for the city and burn these tokens for mining.

**Maturity window: 100 Stacks blocks**: which means that only after 100 blocks, then the user can claim his/her rewards.

**Reward Cycle: 500 Stacks blocks**

STX spent by miners will be distributed:
- **70% to CityCoin holders** who lock up their CityCoins through Stacking.
- **30% to the city's wallet** overseen by a trusted third party custodian(just like tax).
- **Note:** if there are no Stackers locking up their CityCoins, then 100% of the miner bid goes to the city's wallet.

#### Reference points for DMT Dao

- It uses Stacks Web Wallet to connect to the citycoin dapp. We can see how it works. We will not only use Stacks Web Wallet but also the chrome-plugin wallet.
- It makes a miner **can choose to submit for one or multiple blocks at a given rate**. They modify the POX Lite Contract as follows, we will also allow users to submit for multiple blocks:

```lisp
;; Mine tokens.  The miner commits uSTX into this contract (which Stackers can claim later with claim-stacking-reward),
;; and in doing so, enters their candidacy to be able to claim the block reward (via claim-token-reward).  The miner must 
;; wait for a token maturity window in order to obtain the tokens.  Once that window passes, they can get the tokens.
;; This ensures that no one knows the VRF seed that will be used to pick the winner.
(define-public (mine-tokens (amount-ustx uint) (memo (optional (buff 34))))
    (begin
        (if (is-some memo)
            (print memo)
            none
        )
        (mine-tokens-at-block block-height (get-or-create-miner-id tx-sender) amount-ustx)
    )
)

(define-public (mine-tokens-over-30-blocks (amount-ustx uint))
    (let
        ((miner-id (get-or-create-miner-id tx-sender)))

        (asserts! (>= (stx-get-balance tx-sender) (* u30 amount-ustx))
            (err ERR-INSUFFICIENT-BALANCE))

        (try! (mine-tokens-at-block block-height miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u1) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u2) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u3) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u4) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u5) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u6) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u7) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u8) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u9) miner-id amount-ustx))

        (try! (mine-tokens-at-block (+ block-height u10) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u11) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u12) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u13) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u14) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u15) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u16) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u17) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u18) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u19) miner-id amount-ustx))

        (try! (mine-tokens-at-block (+ block-height u20) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u21) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u22) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u23) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u24) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u25) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u26) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u27) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u28) miner-id amount-ustx))
        (try! (mine-tokens-at-block (+ block-height u29) miner-id amount-ustx))
        (ok true)
    )
)

(define-private (mine-tokens-at-block (stacks-block-height uint) (miner-id uint) (amount-ustx uint))
    (let (
        (rc (unwrap! (get-reward-cycle stacks-block-height)
            (err ERR-STACKING-NOT-AVAILABLE)))
        (total-stacked (get total-tokens (map-get? tokens-per-cycle { reward-cycle: rc })))
        (total-stacked-ustx (default-to u0 total-stacked))
        (stacked-something (not (is-eq total-stacked-ustx u0)))
        (amount-ustx-to-stacker
            (if stacked-something
                (/ (* SPLIT_STACKER_PERCENTAGE amount-ustx) u100)
                u0
            )
        )
        (amount-ustx-to-city
            (if stacked-something
                (/ (* SPLIT_CITY_PERCENTAGE amount-ustx) u100)
                amount-ustx
            )
        )
    )
    (begin
        (try! (can-mine-tokens tx-sender miner-id stacks-block-height amount-ustx))
        (try! (set-tokens-mined tx-sender miner-id stacks-block-height amount-ustx amount-ustx-to-stacker amount-ustx-to-city))

        ;; check if stacking is active
        (if stacked-something
            ;; transfer with split if active
            (begin
                (unwrap-panic (stx-transfer? amount-ustx-to-stacker tx-sender (as-contract tx-sender)))
                (unwrap-panic (stx-transfer? amount-ustx-to-city tx-sender (var-get city-wallet)))
            )
            ;; transfer to custodied wallet if not active
            (unwrap-panic (stx-transfer? amount-ustx-to-city tx-sender (var-get city-wallet)))
        )

        (ok true)
    ))
)
```

- **the claim rewards works as POX Lite**. No special modification.

### Stacking

**the stacking process works as POX Lite**. No special modification.

