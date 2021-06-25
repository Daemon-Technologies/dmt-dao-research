# DMT Dao Schedule

- [Docs](https://docs.google.com/document/d/1-QDv8wXhCe1JKuzKTdsPBm4vNV98p5ArBbxV4r5gct4/edit?ts=60458341)
- [FrontEnd](https://docs.google.com/document/u/1/d/18V4TMDimBv38EbWFSlUy8d0A4V87Rxw9s-agT5Gtt0I/edit?ts=60a72d38)



![DMT-DAO](https://user-images.githubusercontent.com/37820916/119911527-03805200-bf8c-11eb-8d58-d3060aec8f49.png)

- Contract to do:

  - DMT Token:
    - Has a property ‘authorized minter’ (that can be updated)
    - Only allows minting from authorized address (the minting contract) This is the main contract that cannot ever be changed
  - DMT Minting Contract:
    - Accepts STX and hold STX
    - Allows an admin to transfer STX
    - Contains the bonding curve function
  - STX Stacking Contract:
    - Probably not viable in Stacks 2.0, because the same contract cannot stack at different intervals
      - Should probably just be more centralized at first
      - Internally have ~8 wallets, which each stack for 8 cycles
        - At any point, there is one “cold” wallet that isn’t stacking. Transfer STX to that and then Stack with it, to the same BTC address
    - Will be viable in Stacks 2.1
  - Contract to hold BTC earned from Stacking
    - At first will need to be an internal wallet
    - Could be a Clarity contract if it held wrapped BTC
  - Pay out some amount of BTC from Stacking to DMT holders
  - Use some amount of the BTC from Stacking to buy more STX on open market to add to DAO
  - STX Redemption contract 
  - 


## Schedule
- [x] Clarinet project building
  - [x] Clarinet check
  - [x] Clarinet test
  - [x] Before 5.21 Friday
- [x] DMT Token Contract (mocknet)
  - [x] [src-20 trait contract](https://github.com/Daemon-Technologies/DMT-DAO/tree/main/src/contracts/src-20-trait.clar)
    - [x] transfer
    - [x] name
    - [x] symbol
    - [x] decimals 
    - [x] balance-of 
    - [x] total-supply 
    - [x] support memo in new src-20 standard
  - [x] support basic function
    - [x] supply 
    - [x] balance_of 
    - [x] transfer 
- [x] DMT Minting Contract (mocknet)
  - [x] [DMT Minting Contract](https://github.com/Daemon-Technologies/DMT-DAO/tree/main/src/contracts/dmt-token.clar)
    - 200~300 lines
    - Bonding curve details(need to list every input and output in details)
- [ ] STX Stacking Contract:
  - [ ] discuss a centralized way
  - [ ] manually stacking for each cycles.
- [ ] STX Redemption contract 
  - [ ] Should have detailed discusstion.



# Stacks Related Material

## Infrastructure

[fungible tokenen.clar standard](https://github.com/stacksgov/Stacks-Grants/issues/44):

- [Hank's pr](https://github.com/stacksgov/sips/pull/5)

## Mining

[Multi-UTXOs](https://github.com/blockstack/stacks-blockchain/issues/2645)

[Mining-Monitor](https://stxmining.club/)

## Stacking

[Stacking-Monitor](https://stacking.club/)

## Clarity

#### Official Documentation:

- [OverView](https://docs.stacks.co/write-smart-contracts/overview)
- [Tutorial Demo 1](https://docs.stacks.co/write-smart-contracts/hello-world-tutorial)
- [Tutorial Demo 2](https://docs.stacks.co/write-smart-contracts/counter-tutorial)
- [Tutorial Demo 3](https://docs.stacks.co/build-apps/guides/transaction-signing)
- [Tutorial Demo 4](https://docs.stacks.co/build-apps/tutorials/public-registry)


#### Developing tools

[Clarinet](https://github.com/lgalabru/clarinet):

- Clarity Runtime Packaged
- Terminal Line Command

[Clarity-js-sdk](https://github.com/blockstack/clarity-js-sdk):

- Javascript SDK for interacting with Clarity smart contracts
- [create-clarity-starter](https://github.com/blockstack/clarity-js-sdk/blob/master/packages/create-clarity-starter/README.md)


#### Relevant Projects

[Clarity-Bitcoin](https://github.com/jcnelson/clarity-bitcoin)
- Clarity library for parsing Bitcoin transactions and block headers, and verifying that Bitcoin transactions were sent on the Bitcoin chain.

## Projects:

[Arkadiko]( https://github.com/stacksgov/Stacks-Grants/issues/72) :

- Stable Coin
- Lending Protocol
- Competitor: Maker Dao
- Testnet Contract Address: https://explorer.stacks.co/txid/0xce16e01a0b6b3017ce948a10939bb8f08717da5529aadd602da7cac06a884d2d?chain=testnet

[PoX-Lite Challenge](https://github.com/unclemantis/pox-lite#challenge):

- A PoX Lite Smart Contract in Clarity which simulates PoX.
  - A fungible token
  - Can only be minted when other people send to the contract their Stacks (STX) tokens.

[daoOS](https://github.com/stacksgov/Stacks-Grants/issues/65):

- Allowing members to sign up, be approved by the existing organization
- Members will be able to post ideas, and these ideas can be fleshed out, budgets and milestones can be set
- Members can then commit STX to projects they want to contribute to, when the full budget is met, they can begin working towards the milestones
- When a milestone is met, the project owner can post it and have STX released on approval of a majority of anyone who staked STX to that project. This continues until the project has reached completion.

- Source code and introduction: https://github.com/syvita/daoos

[Boom Wallet](https://boom.money/):

- NFT Wallet
  - NFT issue
  - NFT Transfer
  - NFT Market

[Swapr](https://swapr.finance/):

- developed by psq
- Dex on Stacks 2.0
- [native token contract](https://github.com/psq/flexr/blob/master/contracts/flexr-token.clar)
- [oracle supported](https://github.com/psq/flexr/blob/master/contracts/oracle.clar)

[TokenSoft](https://github.com/tokensoft/tokensoft_token_stacks):

- xbtc token

[CityCoin](https://github.com/citycoins/citycoin)
- Miami Coin 



## Development Work

### Smart Contract

- DMT Token Contract
  - **transfer**
  - **balance-of**
- DMT Minting Contract(contains core part of POX Lite Contract)
  - **mine-tokens**: Mine tokens.  The miner commits uSTX into this contract (which Stackers can claim later with claim-stacking-reward), and in doing so, enters their candidacy to be able to claim the block reward (via claim-token-reward).
  - **claim-token-reward**: Claim the block reward. This mints and transfers out a miner's tokens if it is indeed the block winner for the given Stacks block.
  - **stack-tokens**: Stack the contract's tokens.
  - **get-entitled-stacking-reward**: Determine how many uSTX a Stacker is allowed to claim, given the reward cycle they Stacked in and the current block height.
  - **claim-stacking-reward**: Claim a Stacking reward.  Once a reward cycle passes, a Stacker can call this method to obtain any uSTX that were committed to the contract during that reward cycle (proportional to how many tokens they locked up).
  - **get-block-winner**: determine which miner won the token batch at a particular Stacks block height, given a sampling value.
  - **get-tokens-per-cycle**: Getter for getting how many uSTX are committed and tokens are Stacked per reward cycle.
  - **get-stacked-in-cycle**:  Getter for getting how many tokens are Stacked by the given principal in the given reward cycle.
  - **get-miners-at-block**: Getter for getting the list of miners and uSTX committments for a given block.
- Voting Contract - Pending...

### Frontend

- Landing Page
- Dapp
  - Connection with chrome-extension wallet
  - Basic info of the dapp
  - User interfaces
    - mine
    - stack
    - claim-token-reward
    - claim-stacking-reward



## Project Process

### Mining

The mining process is like buying a lottery ticket. **Every 5 blocks is a round.** Assuming that the system will start mining at block 1, and the end of each round is on the 6th, 11th, 16th, etc. If the user deposits into the contract during a round, it will be automatically placed in the next round of calculation . For example, if the user deposit into the contract on the 3rd block, it will be confirmed on the 11th block whether he has mined a block and how much he has mined. 

**The user only needs to call the contract(`mine`) once in each round, not each block. When each round is over, the user can claim his rewards.**

The probability of success in each round of mining is calculated as follows:

We assume that the total STX amount in each round is Ni, and i represents the i-th round. Assuming that the user deposits 100 STX to enter the contract before the i-th round, the average computing power of the user for each block in the i-th round is 20 STX. That is, the probability of a user's mining success in each block (5 blocks in a round) is about 100/Ni.

### Stacking

It works as before.



## Timeline

### 2021.06.15 - 2021.06.19: 

- [x] Connection with the chrome-extension wallet, make sure that we can call the wallet through our dapp.
- [x] Call the smart contract through the chrome-extension wallet.
- [x] Implement the smart contract V1 and deploy it on the testnet.

- [x] [mainnet CONTRACT deploy](https://explorer.stacks.co/txid/0x88461aa9445df11e35e23cf4883e42e47490c9d2a1a493bac4897916adb4f0cb?chain=mainnet)

### 2021.6.21 -
- DMT Wallet Setting in Smart Contract 
  - [x] Variable Setting for DMT Wallet 
- Multi-Mining Test
  - [ ] Testnet Contract deployment
  - [x] Mainnet Test : Two miners compete one block, and only one miner will win/claim the block reward. And this process can be verified by Frontend API. [random sample => winner id] 
- [x] Minimum Mining Amount Variable
  - 50 STX => 10 STX / block 
  - block reward => 10 RTX / block 
- Token Contract Split
  - If RTX token wanna be used for DAO in the future, it would better to be splitted from Mint Contract
  - Under discussion(arkadiko/citycoin)
- Test for Multi-Claim
- Frontend integration/contract upgrade of readonly function
  - winner query
  - mining status query  



