# Trial NFT Utility on Ethereum

## Summary
Trial NFT contract is a novel utility of NFTs which aims to transform the web3 game ecosystem. The first web3 games required users to create their own wallets, buy ethereum on their own, deposit it into the wallet and mint a NFT from the game outside the game before they can start playing the game. The trend in web3 games now is to do free mints of "first generation NFTs" to incentivise their first players to try out the game. This gives game developers anxiety because they don't get good signal if users who minted the NFT actually minted to play the game or for enhancing their personal collection. 

Hence we propose trial NFTs as an interesting balance of benefits between the aforementioned "pay-to-play" and "free-to-play" models, and overall a win-win for both gamers and game developers. How this happens is gamers accumulate untradable in-game items tied to their trial "Character" NFT when they first onboard to play the trial mode of the game. This creates two significant incentive mechanisms. For a gamer, they develop an attachment to their trial character because they have earned items from time spent experiencing the free trial. Such emotions make them more likely to convert to paying customers. For game developers, they now have data points on how attractive the onboarding of their game is, a critical feedback loop that games value. 

## Overview
With our proposed solution, a user is able to seamlessly mint a trial NFT within the game (without leaving the game) after they login with their social. Doing so deposits a trial NFT to their provisioned non-custodial wallet without leaving the game interface, which grants them permission to experience a subset of key features of the actual game immediately after. During the trial, gamers accumulate in-game items that are ERC1155 tokens on L2 such as Optimism tied to their ERC721 Character on L1 Ethereum. The current proposed design is for the trial Character NFT (ERC721) and items (ERC1155) accumulated during the trial will be untradable until the trial is over. 

## Demo Links
* [Demo Video](https://www.loom.com/share/c483a9cd47fb424fa3abeb3667a1b999)
* [Demo Slides](https://docs.google.com/presentation/d/1xdhSzu3IvSJyWYuO4-tZhemz6vdH4HFUsvIN5w9DxSk/edit?usp=sharing)

## How we built this
* Main contract is written in `src/Distributor.sol` with solidity
* Frontend is built with HTML, eJS, neDB, link to repo here: [code for UI](https://github.com/Alt-Carbon-Labs/trial-nft-ui)

### Tech Description
The core functionality is built in the smart contract, which leverages Chainlink Custom Keepers as the key piece ensuring the "state" of the trial NFT is managed and maintained. When a trial NFT is minted, a trial expiry countdown begins based on the current block timestamp, and a owner-defined trial period (e.g. 7 days). When each new block on L1 Ethereum is mined ~every 12 seconds, Chainlink checks the trial expiry timestamp for all trial NFTs minted offchain using the function `checkUpkeep` in `src/Distributor.sol`. If trials have expired, it automatically triggers a `performUpkeep` function in `src/Distributor.sol` which updates the state of the trial NFT onchain as "expired", revoking access to the game trial and validity of items accumulated. This update in state will eventually be batched in the production version because of the possibility of having to update a large number of NFTs at once, to prevent the contract from running out of gas.

The frontend uses Ethers.js to facilitate interaction with the blockchain. Login with social, creation of wallet in the background and seamless interaction with the Ethereum blockchain is facilitated by Magic.Link's API and node provider service. 

# Instructions when setting up this project for the first time
```shell
forge install
forge build
forge test
```
This is a standard Foundry project

### Relevant Links
* [Demo Gamer Account Created with Social Login](https://goerli.etherscan.io/address/0xd6529d30e9eb83c09aedc3cb7636ec83909017ab)
* [Trial NFT Distributor Contract including Chainlink keeper functions](https://goerli.etherscan.io/address/0x4d08574fe6babf4e40929de324d2d7c065bb95ac#internaltx)
* [Custom Chainlink Keeper](https://automation.chain.link/goerli/34183205944246421736158067511315908412372819349760798217931501480994131518906)

### Closing Thoughts
* I'm aware the frontend code is super jank. I optimised for shipping something usable ASAP due to constraints -> I'm a fan of refactoring
* We built this because we are gamers ourselves who have been converted by game trials on many occcasions. We think this utility will resonate with other hardcore gamers like us, and even potentially extended to other use cases
