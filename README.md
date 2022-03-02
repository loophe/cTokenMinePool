# MonkeyKing

This is an NFT asset interest-generating game based on the concept of the metaverse. The difference is that NFT assets can generate cash income, and the income comes from real assets. The income is credited to the user account by the administrator contract, and the account cash can choose to add assets or withdraw.


## Instuctions

The main point of this project is cTokenMinePool.sol and MonkeyContract.sol in ./contract. cTokenMinePool actually the operator contract of cToken from Compound protocol and NFT contract of MonkeyContract. 

I strongly recommend you setup brownie v1.17.2 and remix v0.22.0-dev first 

You should deploy your own [compound protocol](https://github.com/compound-finance/compound-protocol) on mainnet fork mode by above two or more. The tutoral is [here](https://github.com/Dapp-Learning-DAO/Dapp-Learning/blob/main/defi/Compound/contract/Compound%E5%90%88%E7%BA%A6%E9%83%A8%E7%BD%B2.md).

When complete deploying, copy cTokenDelegator & ComptrollerG1 address to replace the address in ./scripts/token.py, which is scripts of deploying and testing of cTokenMinePool.sol & MonkeyContract.sol, you can customize it to test more function.

## zToken

cTokenMinePool has its own ERC20 token named zToken, which usage just like accountSnapShot of Compound protocol. zToken is ledger of user who supply or borrow from Compound through cTokenMinePool. The difference between zToken and Compound cToken is that zToken must pair with monkey NFT, the borrowed unlying assets store in cTokenMinePool as while as cToken stored with it too. zToken and cToken have same total supply.

## Monkey NFT

What we expect of this metaverse game is that after supply and borrow from depolyed cToken contract, user account would have a created a monkey NFT. Monkey have six characters:
 ```````````   
    //Monkey characters
    struct CryptoMonkey {        
        uint strength;
        uint accountIndex;
        uint luckyNumber;
        string genes;
        uint256 birthtime;
        bool isLocked;
    } 
````````````
1. Strength character paired with accountIndex, store the amount of underlying token borrowed from cToken contract.
2. AccountIndex is like borrowIndex in cToken. Strength will grow more and more as block accumulating. The current strength can be calculate as stengthCharacterNew = stengthCharacter * accountIndex. AccountINdex always > 1 so the strength value will keep growing.
3. LuckyMumber is a random number that between 00000000-11111111.
4. Genes represent the kind of cTokenMinePool. As there are many kinds of earning method in real world assets, the kinds of cTokenMinePool varis.
5. Birthtime is the time of NFT get created.
6. IsLocked represent if the NFT can be transtered, or the strength character of the NFT can be changed by borrow or repay borrow.

***********************************************************

The mining earn show page, will become Dapp front-end lately (Currently only in Chinese) : www.zsharing.net:8080/