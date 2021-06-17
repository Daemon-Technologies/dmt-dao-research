;; error codes
(define-constant ERR-NO-WINNER u0)
(define-constant ERR-NO-SUCH-MINER u1)
(define-constant ERR-IMMATURE-TOKEN-REWARD u2)
(define-constant ERR-UNAUTHORIZED u3)
(define-constant ERR-ALREADY-CLAIMED u4)
(define-constant ERR-STACKING-NOT-AVAILABLE u5)
(define-constant ERR-CANNOT-STACK u6)
(define-constant ERR-INSUFFICIENT-BALANCE u7)
(define-constant ERR-ALREADY-MINED u8)
(define-constant ERR-ROUND-FULL u9)  ;; deprecated - this error is not used anymore
(define-constant ERR-NOTHING-TO-REDEEM u10)
(define-constant ERR-CANNOT-MINE u11)
(define-constant ERR-MINER-ALREADY-REGISTERED u12)
(define-constant ERR-MINING-ACTIVATION-THRESHOLD-REACHED u13)
(define-constant ERR-MINER-ID-NOT-FOUND u14)
(define-constant ERR-TOO-SMALL-COMMITMENT u15)


(define-constant TOKEN-REWARD-MATURITY u5)        ;; how long a miner must wait before claiming their minted tokens

;; How many uSTX are mined per reward cycle, and how many tokens are locked up in the same reward cycle.
(define-map tokens-per-cycle
    { reward-cycle: uint }
    { total-ustx: uint, total-tokens: uint }
)

(define-fungible-token dmttoken)

;; define initial token URI
(define-data-var token-uri (optional (string-utf8 256)) (some u"<link to token-uri>"))

;; set constant for contract owner, used for updating token-uri
(define-constant CONTRACT-OWNER tx-sender)

;; Mining configuration
(define-constant MINING-ACTIVATION-THRESHOLD u20)     ;; how many miners have to register to kickoff countdown to mining activation
(define-data-var mining-activation-threshold uint MINING-ACTIVATION-THRESHOLD) ;; variable used in place of constant for easier testing
(define-data-var mining-activation-threshold-reached bool false)  ;; variable used to track if mining is active
(define-data-var miners-nonce uint u0)               ;; variable used to generate unique miner-id's

;; Bind Stacks block height to a list of up to 128 miners (and how much they mined) per block,
;; and track whether or not the miner has come back to claim their tokens and who mined the least.
(define-map mined-blocks
    { stacks-block-height: uint }
    {
        miners-count: uint,
        least-commitment-idx: uint,
        least-commitment-ustx: uint,
        claimed: bool,
    }
)

(define-map blocks-miners
  { stacks-block-height: uint, idx: uint }
  { miner-id: uint, ustx: uint }
)

;; Maps miner address to uint miner-id
(define-map miners
    { miner: principal }
    { miner-id: uint }
)

;; Returns miner ID if it has been created
(define-read-only (get-miner-id (miner principal))
    (get miner-id (map-get? miners { miner: miner }))
)

;; Returns miners ID if it has been created, or creates and returns new
(define-private (get-or-create-miner-id (miner principal))
    (match (get miner-id (map-get? miners { miner: miner }))
        value value
        (let
            ((new-id (+ u1 (var-get miners-nonce))))
            (map-set miners
                { miner: miner }
                { miner-id: new-id}
            )
            (var-set miners-nonce new-id)
            new-id
        )
    )
)

(define-public (register-miner (memo (optional (buff 34))))
    (let
        (
            (new-id (+ u1 (var-get miners-nonce)))
            (threshold (var-get mining-activation-threshold))
        )
        (asserts! (is-none (map-get? miners { miner: tx-sender }))
            (err ERR-MINER-ALREADY-REGISTERED))

        (asserts! (<= new-id threshold)
            (err ERR-MINING-ACTIVATION-THRESHOLD-REACHED))

        (if (is-some memo)
            (print memo)
            none
        )

        (map-set miners
            { miner: tx-sender }
            { miner-id: new-id }
        )
        
        (var-set miners-nonce new-id)

        (if (is-eq new-id threshold)
            (let
                (
                    (first-stacking-block-val (+ block-height MINING-ACTIVATION-DELAY))
                )
                (var-set mining-activation-threshold-reached true)

                (ok true)
            )
            (ok true)
        )
    )
)

(define-read-only (get-coinbase-amount (miner-block-height uint))
    (let
        (
            ;; set a new variable to make things easier to read
            (activation-block-height (var-get first-stacking-block))
        )
        ;; determine if mining was active, return 0 if not
        (asserts! (>= miner-block-height activation-block-height) u0)
        u100
    )
)



;; Produce the new tokens for the given claimant, who won the tokens at the given Stacks block height.
(define-private (mint-coinbase (recipient principal) (stacks-block-ht uint))
    (ft-mint? dmttoken (get-coinbase-amount stacks-block-ht) recipient)
)

;; Determine whether or not the given principal can claim the mined tokens at a particular block height,
;; given the miners record for that block height, a random sample, and the current block height.
(define-read-only (can-claim-tokens (claimer principal) 
                                    (claimer-stacks-block-height uint)
                                    (random-sample uint)
                                    (block { 
                                        miners-count: uint,
                                        least-commitment-idx: uint, 
                                        least-commitment-ustx: uint,
                                        claimed: bool
                                    })
                                    (current-stacks-block uint))
    (let (
        (claimer-id (unwrap! (get-miner-id claimer) (err ERR-MINER-ID-NOT-FOUND)))
        (reward-maturity (var-get token-reward-maturity))
        (maximum-stacks-block-height
            (if (>= current-stacks-block reward-maturity)
                (- current-stacks-block reward-maturity)
                u0))
    )
    (if (< claimer-stacks-block-height maximum-stacks-block-height)
        (begin
            (asserts! (not (get claimed block))
                (err ERR-ALREADY-CLAIMED))

            (match (get-block-winner claimer-stacks-block-height random-sample)
                winner-rec (if (is-eq claimer-id (get miner-id winner-rec))
                               (ok true)
                               (err ERR-UNAUTHORIZED))
                (err ERR-NO-WINNER))
        )
        (err ERR-IMMATURE-TOKEN-REWARD)))
)

;; Mark a batch of mined tokens as claimed, so no one else can go and claim them.
(define-private (set-tokens-claimed (claimed-stacks-block-height uint))
    (let (
      (miner-rec (unwrap!
          (map-get? mined-blocks { stacks-block-height: claimed-stacks-block-height })
          (err ERR-NO-WINNER)))
    )
    (begin
       (asserts! (not (get claimed miner-rec))
          (err ERR-ALREADY-CLAIMED))

       (map-set mined-blocks
           { stacks-block-height: claimed-stacks-block-height }
           (merge miner-rec { claimed: true })
       )
       (ok true)))
)

;; Determine whether or not the given miner can actually mine tokens right now.
;; * Stacking must be active for this smart contract
;; * No more than 31 miners must have mined already
;; * This miner hasn't mined in this block before
;; * The miner is committing a positive number of uSTX
;; * The miner has the uSTX to commit
(define-read-only (can-mine-tokens (miner principal) (miner-id uint) (stacks-block-height uint) (amount-ustx uint))
    (let
        (
            (block (get-mined-block-or-default stacks-block-height))
        )        
        (if (and (is-eq MAX-MINERS-COUNT (get miners-count block)) (<= amount-ustx (get least-commitment-ustx block)))
            (err ERR-TOO-SMALL-COMMITMENT)
            (begin
                (asserts! (is-some (get-reward-cycle stacks-block-height))
                    (err ERR-STACKING-NOT-AVAILABLE))

                (asserts! (not (has-mined miner-id stacks-block-height))
                    (err ERR-ALREADY-MINED))

                (asserts! (> amount-ustx u0)
                    (err ERR-CANNOT-MINE))

                (asserts! (>= (stx-get-balance miner) amount-ustx)
                    (err ERR-INSUFFICIENT-BALANCE))

                (ok true)
            )
        )
    )
)

;; Read the on-chain VRF and turn the lower 16 bytes into a uint, in order to sample the set of miners and determine
;; which one may claim the token batch for the given block height.
(define-read-only (get-random-uint-at-block (stacks-block uint))
    (let (
        (vrf-lower-uint-opt
            (match (get-block-info? vrf-seed stacks-block)
                vrf-seed (some (buff-to-uint-le (lower-16-le vrf-seed)))
                none))
    )
    vrf-lower-uint-opt)
)

;; Mark a miner as having mined in a given Stacks block and committed the given uSTX.
(define-private (set-tokens-mined (miner principal) (miner-id uint) (stacks-block-height uint) (commit-ustx uint) (commit-ustx-to-stackers uint) (commit-ustx-to-city uint))
    (let (
        (block (get-mined-block-or-default stacks-block-height))
        (increased-miners-count (+ (get miners-count block) u1))
        (new-idx increased-miners-count)
        (least-commitment-idx (get least-commitment-idx block))
        (least-commitment-ustx (get least-commitment-ustx block))
        
        (reward-cycle (unwrap! (get-reward-cycle stacks-block-height)
            (err ERR-STACKING-NOT-AVAILABLE)))

        (tokens-mined (default-to { total-ustx: u0, total-tokens: u0 } 
            (map-get? tokens-per-cycle { reward-cycle: reward-cycle }))
        )
    )
    (begin
        (if (> MAX-MINERS-COUNT (get miners-count block))
            (begin
                ;; list is not full - add new miner and calculate if he committed the least
                (map-set blocks-miners
                    { stacks-block-height: stacks-block-height, idx: new-idx }
                    { miner-id: miner-id, ustx: commit-ustx }
                )

                (map-set mined-blocks
                    { stacks-block-height: stacks-block-height }
                    {
                        miners-count: increased-miners-count,
                        least-commitment-idx: (if (or (is-eq new-idx u1) (< commit-ustx least-commitment-ustx)) new-idx least-commitment-idx),
                        least-commitment-ustx: (if (or (is-eq new-idx u1) (< commit-ustx least-commitment-ustx)) commit-ustx least-commitment-ustx),
                        claimed: false
                    }
                )
            )
            (begin
                ;; list is full - replace miner who committed the least with new one and calculate new miner who committed the least
                (map-set blocks-miners
                    { stacks-block-height: stacks-block-height, idx: least-commitment-idx }
                    { miner-id: miner-id, ustx: commit-ustx }
                )
                (let
                    (
                        (least-commitment (find-least-commitment stacks-block-height))
                    )
                    (map-set mined-blocks
                        { stacks-block-height: stacks-block-height }
                        {
                            miners-count: MAX-MINERS-COUNT,
                            least-commitment-idx: (get least-commitment-idx least-commitment),
                            least-commitment-ustx: (get least-commitment-ustx least-commitment),
                            claimed: false
                        }
                    )
                )
            )
        )
        (map-set miners-block-commitment
            { miner-id: miner-id, stacks-block-height: stacks-block-height}
            { committed: true }
        )
        (map-set tokens-per-cycle
            { reward-cycle: reward-cycle }
            { total-ustx: (+ commit-ustx-to-stackers (get total-ustx tokens-mined)), total-tokens: (get total-tokens tokens-mined) }
        )
        (map-set block-commit
            { stacks-block-height: stacks-block-height }
            {
                amount: (+ commit-ustx (get-block-commit-total stacks-block-height)),
                amount-to-stackers: (+ commit-ustx-to-stackers (get-block-commit-to-stackers stacks-block-height)),
                amount-to-city: (+ commit-ustx-to-city (get-block-commit-to-city stacks-block-height))
            }
        )
        (ok true)
    ))
)

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



;; Claim the block reward.  This mints and transfers out a miner's tokens if it is indeed the block winner for
;; the given Stacks block.  The VRF seed will be sampled at the target mined stacks block height _plus_ the 
;; maturity window, and if the miner (i.e. the caller of this function) both mined in the target Stacks block
;; and was later selected by the VRF as the winner, they will receive that block's token batch.
;; Note that this method actually mints the contract's tokens -- they do not exist until the miner calls
;; this method.
(define-public (claim-token-reward (mined-stacks-block-ht uint))
    (let (
        (random-sample (unwrap! (get-random-uint-at-block (+ mined-stacks-block-ht (var-get token-reward-maturity)))
                        (err ERR-IMMATURE-TOKEN-REWARD)))
        (block (unwrap! (map-get? mined-blocks { stacks-block-height: mined-stacks-block-ht })
                        (err ERR-NO-WINNER)))
    )
    (begin
        (try! (can-claim-tokens tx-sender mined-stacks-block-ht random-sample block block-height))
        (try! (set-tokens-claimed mined-stacks-block-ht))
        (unwrap-panic (mint-coinbase tx-sender mined-stacks-block-ht))

        (ok true)
    ))
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

;;;;;;;;;;;;;;;;;;;;; SIP 010 ;;;;;;;;;;;;;;;;;;;;;;
;; testnet: (impl-trait 'STR8P3RD1EHA8AA37ERSSSZSWKS9T2GYQFGXNA4C.sip-010-trait-ft-standard.sip-010-trait)
;; reuse sip10 contract 
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-read-only (get-name)
    (ok "dmttoken"))

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (is-eq from tx-sender)
            (err ERR-UNAUTHORIZED))

        (if (is-some memo)
            (print memo)
            none
        )

        (ft-transfer? dmttoken amount from to)
    )
)



(define-read-only (get-symbol)
    (ok "DMT"))

;; minimal unit is 0

(define-read-only (get-decimals)
    (ok u0))

(define-read-only (get-balance (user principal))
    (ok (ft-get-balance dmttoken user)))

(define-read-only (get-total-supply)
    (ok (ft-get-supply dmttoken)))

(define-read-only (get-token-uri)
    (ok (var-get token-uri)))