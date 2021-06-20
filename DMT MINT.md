# ReadOnly
```
(get-mined-blocks (stacks-block-height uint)
(define-read-only (get-blocks-miners (stacks-block-height uint) (idx uint))
(has-mined (miner-id uint) (stacks-block-height uint))
(can-mine-tokens (miner principal) (miner-id uint) (stacks-block-height uint) (amount-ustx uint))
(get-miner-id (miner principal))
(can-claim-tokens (claimer principal) 
                  (claimer-stacks-block-height uint)
                  (random-sample uint)
                  (current-stacks-block uint))
(get-block-winner (stacks-block-height uint) (random-sample uint))
(get-random-uint-at-block (stacks-block uint))
(get-next-block-height)
(get-symbol)
(get-name)
(get-decimals)
(get-balance (user principal))
(get-total-supply)
(get-token-uri)
```
# Public
```
(claim-token-reward (mined-stacks-block-ht uint))
(mine-tokens (amount-ustx uint) (memo (optional (string-ascii 34)))
(transfer (amount uint) 
          (from principal) 
          (to principal) 
          (memo (optional (buff 34)))
)
```