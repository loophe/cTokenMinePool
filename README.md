# MonkeyKing

This is an NFT asset interest-generating game based on the concept of the metaverse. The difference is that NFT assets can generate cash income, and the income comes from real assets. The income is credited to the user account by the administrator contract, and the account cash can choose to add assets or withdraw.


## Instuctions

I strongly recommend you setup brownie v1.17.2 and remix v0.22.0-dev first 

You should deploy your own [compound protocol](https://github.com/compound-finance/compound-protocol) on mainnet fork mode by above two or more. The tutoral is [here](https://github.com/Dapp-Learning-DAO/Dapp-Learning/blob/main/defi/Compound/contract/Compound%E5%90%88%E7%BA%A6%E9%83%A8%E7%BD%B2.md).

When complete deploying, copy cTokenDelegator & ComptrollerG1 address to replace the address in ./scripts/token.py, which is scripts of deploying and testing of cTokenMinePool.sol & MonkeyContract.sol, you can customize it to test more function.

***********************************************************

The mining earn show page, will become Dapp front-end lately (Currently only in Chinese) : www.zsharing.net:8080/