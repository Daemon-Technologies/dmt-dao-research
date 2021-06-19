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
(define-constant ERR-TOO-MANY-MINERS u16)

(define-constant LONG-UINT-LIST (list
u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 
u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 u31 u32 
u33 u34 u35 u36 u37 u38 u39 u40 u41 u42 u43 u44 u45 u46 u47 u48
u49 u50 u51 u52 u53 u54 u55 u56 u57 u58 u59 u60 u61 u62 u63 u64
u65 u66 u67 u68 u69 u70 u71 u72 u73 u74 u75 u76 u77 u78 u79 u80
u81 u82 u83 u84 u85 u86 u87 u88 u89 u90 u91 u92 u93 u94 u95 u96
u97 u98 u99 u100 u101 u102 u103 u104 u105 u106 u107 u108 u109 u110 u111 u112
u113 u114 u115 u116 u117 u118 u119 u120 u121 u122 u123 u124 u125 u126 u127 u128 
))

(define-constant TOKEN-REWARD-MATURITY u5)      ;; how long a miner must wait before claiming their minted tokens
(define-constant ACTIVATION-HEIGHT u3000)       ;; The beginning height of the mining process
(define-constant MAX-MINERS-COUNT u128)               ;; maximum players in one cycle

(define-constant RTX_CUSTODIED_WALLET 'STKBS86JFA8BBJ1FF66QQEV855SQS6PWQ4TZ0ASQ)  ;; the custodied wallet address for the city
(define-data-var dmt-wallet principal RTX_CUSTODIED_WALLET)  ;; variable used in place of constant for easier testing

(define-data-var miners-nonce uint u0)          ;; variable used to generate unique miner-id's
(define-data-var latest-cycle-height uint u0)   ;; variable used to record latest cycle height. For example the latest block is 2008, then the latest-cycle-height is 2010
                                                ;; it will always be multiple of five

;; Bind Stacks block height to a list of up to 128 miners (and how much they mined) per block,
;; and track whether or not the miner has come back to claim their tokens and who mined the least.
(define-map mined-blocks
    { stacks-block-height: uint }
    {
        miners-count: uint,
        commitment-ustx: uint,
        winner-id: uint,
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

(define-map miners-block-commitment
    { miner-id: uint, stacks-block-height: uint }
    { committed: bool }
)

(define-read-only (get-mined-blocks (stacks-block-height uint))
    (is-some (map-get? mined-blocks
        { stacks-block-height: stacks-block-height }
    ))
)

(define-read-only (get-blocks-miners (stacks-block-height uint) (idx uint))
    (is-some (map-get? blocks-miners
        { stacks-block-height: stacks-block-height, idx: idx }
    ))
)

;; Determine if a given miner has already mined at given block height
(define-read-only (has-mined (miner-id uint) (stacks-block-height uint))
    (is-some (map-get? miners-block-commitment 
        { miner-id: miner-id, stacks-block-height: stacks-block-height }
    ))
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


;; Mine tokens.  The miner commits uSTX into this contract (which Stackers can claim later with claim-stacking-reward),
;; and in doing so, enters their candidacy to be able to claim the block reward (via claim-token-reward).  The miner must 
;; wait for a token maturity window in order to obtain the tokens.  Once that window passes, they can get the tokens.
;; This ensures that no one knows the VRF seed that will be used to pick the winner.
(define-public (mine-tokens (amount-ustx uint) (memo (optional (string-ascii 34))))
    (ok u1)
    ;;(begin
    ;;    (if (is-some memo)
    ;;        (print memo)
    ;;        none
    ;;    )

    ;;    (mine-tokens-at-block block-height (get-or-create-miner-id tx-sender) amount-ustx)
    ;;)
)

(define-private (mine-tokens-at-block (stacks-block-height uint) (miner-id uint) (amount-ustx uint))
    (begin
        (try! (can-mine-tokens tx-sender miner-id stacks-block-height amount-ustx))
        (try! (set-tokens-mined tx-sender miner-id stacks-block-height amount-ustx))
        (unwrap-panic (stx-transfer? amount-ustx tx-sender (var-get dmt-wallet)))
        (ok true)
    )
)

;; Determine whether or not the given miner can actually mine tokens right now.
;; * This miner hasn't mined this cycle before
;; * The miner is committing a positive number of uSTX
;; * The miner has the uSTX to commit
(define-read-only (can-mine-tokens (miner principal) (miner-id uint) (stacks-block-height uint) (amount-ustx uint))
    (let
        (
            (block (get-mined-block-or-default stacks-block-height))
        )        
        (if (is-eq MAX-MINERS-COUNT (get miners-count block))
            (err ERR-TOO-SMALL-COMMITMENT)
            (begin
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

;; Getter to obtain the list of miners and uSTX commitments at a given Stacks block height,
;; OR, an empty such structure.
(define-private (get-mined-block-or-default (stacks-block-height uint))
    (match (map-get? mined-blocks { stacks-block-height: stacks-block-height })
        block block
        { 
            miners-count: u0, 
            commitment-ustx: u0,
            winner-id: u0,
            claimed: false,
        })
)


;; Mark a miner as having mined in a given Stacks block and committed the given uSTX.
(define-private (set-tokens-mined (miner principal) (miner-id uint) (stacks-block-height uint) (commit-ustx uint))
    (let (
        (block (get-mined-block-or-default stacks-block-height))
        (increased-miners-count (+ (get miners-count block) u1))
        (new-idx increased-miners-count)
        (commitment-ustx (get commitment-ustx block))
    )
    (begin
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
                    commitment-ustx: (+ commitment-ustx commit-ustx),
                    winner-id: u0,
                    claimed: false
                }
            )
        )
            
        
        ;;TODO
        (map-set miners-block-commitment
            { miner-id: miner-id, stacks-block-height: stacks-block-height}
            { committed: true }
        )
        (if (> MAX-MINERS-COUNT (get miners-count block))
            (ok true)
            (err ERR-TOO-MANY-MINERS)
        )
    ))
)



(define-fungible-token resonancetoken u10000000)

;; define initial token URI
(define-data-var token-uri (optional (string-utf8 256)) (some u"<link to token-uri>"))

;;;;;;;;;;;;;;;;;;;;; SIP 010 ;;;;;;;;;;;;;;;;;;;;;;
;; testnet 
;; (impl-trait 'ST2EKQHV1XVFET0FP9VC4EBTFSCA1GVACD6QR3RXR.sip-010-trait-ft-standard.sip-010-trait)
;; mainnet
;;(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

(define-read-only (get-name)
    (ok "resonancetoken"))

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (is-eq from tx-sender)
            (err ERR-UNAUTHORIZED))

        (if (is-some memo)
            (print memo)
            none
        )

        (ft-transfer? resonancetoken amount from to)
    )
)

(define-read-only (get-symbol)
    (ok "RTX"))

;; minimal unit is 0

(define-read-only (get-decimals)
    (ok u2))

(define-read-only (get-balance (user principal))
    (ok (ft-get-balance resonancetoken user)))

(define-read-only (get-total-supply)
    (ok (ft-get-supply resonancetoken)))

(define-read-only (get-token-uri)
    (ok (var-get token-uri)))