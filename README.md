# MonkeyKing

This is an NFT asset interest-generating game based on the concept of the metaverse. The difference is that NFT assets can generate cash income, and the income comes from real assets. The income is credited to the user account by the administrator contract, and the account cash can choose to add assets or withdraw.


## Instuctions

The main point of this project is cTokenMinePool.sol and MonkeyContract.sol in ./contract. cTokenMinePool actually the operator contract of cToken from Compound protocol and NFT contract of MonkeyContract. 

I strongly recommend you setup brownie v1.17.2 and remix v0.22.0-dev first 

Before starting this project, you should firstly deploy [forked compound protocol](https://github.com/loophe/compoundForked) on [mainnet fork mode](https://github.com/loophe/cTokenMinePool#mainnet-fork-mode) by above two or more. 

When complete deploying, copy cTokenDelegator & ComptrollerG1 address to replace the address in ./scripts/token.py, which is scripts of deploying and testing of cTokenMinePool.sol & MonkeyContract.sol, you can customize it to test more function.

## zToken

cTokenMinePool has its own ERC20 token named zToken, which usage just like accountSnapShot of Compound protocol. zToken is ledger of users who supply to Compound through cTokenMinePool. The difference between zToken and Compound cToken is that zToken must pair with monkey NFT. The borrowed unlying assets store in cTokenMinePool as while as cToken stored with it too, but zToken transfered to the user's account as ledger of supplyment. zToken and cToken have same total supply.

## Monkey NFT

What we expect of this metaverse game is that after supply and borrow from depolyed cToken contract, user account would have a created a monkey NFT. 

Each monkey have six characters:
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
2. AccountIndex is like borrowIndex in cToken. Strength will grow  as block accumulating. The current strength can be calculate as stengthCharacterNew = stengthCharacter * marketIndex / accountIndex. marketIndex/accountIndex > 1 so the strength value will keep growing.
3. LuckyMumber is a random number that between 00000000-11111111.
4. Genes represent the kind of eraning module. As there are many kinds of assets could generate interests in real world, the kinds of eraning module varis.
5. Birthtime is the time of NFT get created.
6. IsLocked represent if the NFT can be transtered, or the strength character of the NFT can be changed by borrow or repay borrow.

## Mainnet-fork mode

Start ganache-cli mainnet-fork mode and keep it running untill all the tests finished. The commond line as follow:
```````````
ganache-cli \
  -f https://eth-mainnet.alchemyapi.io/v2/${YOUR_API_TOKEN_HERE}\
  -i 1 \
  -u 0x9759A6Ac90977b93B58547b4A71c78317f391A28
`````````````````````


***********************************************************

## The mining earn show page 

It will become Dapp front-end lately (Currently only in Chinese) : www.zsharing.net:8080/