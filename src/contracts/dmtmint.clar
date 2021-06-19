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

(define-map mined-blocks
    { stacks-block-height: uint }
    {
        miners-count: uint,
        commitment-ustx: uint,
        winner-id: uint,
        claimed: bool,
    }
)

;; Maps miner address to uint miner-id
(define-map miners
    { miner: principal }
    { miner-id: uint }
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