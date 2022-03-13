// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./compoundLibary/Exponential.sol";
import "./compoundLibary/ErrorReporter.sol";
import "./zTokenInterfaces.sol";
// import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CTokenMinePool is ERC20, Ownable, Exponential, TokenErrorReporter{
   
    address public ComptrollerAddress;
    // address public PriceFeedAddress;
    address public cTokenAddress;
    address public UnderlyingAddress;
    address public MonkeyAddress;
    // uint public borrowIndex;
    // uint public accrualBlockNumber;

    bool internal _notEntered = true;

    // event DoneStuff(address from);
    event MyLog(string, uint256);

      
    Erc20 underlying = Erc20(UnderlyingAddress); 
    CErc20 cToken = CErc20(cTokenAddress);  
    Monkey monkey = Monkey(MonkeyAddress);  
    MathError mathErr;

    /**
     * @dev Constructor sets token that can be received
     */
    constructor (
        // IERC20 token,
        address _underlyingAddress,
        address _comptrollerAddress,
        // address _priceFeedAddress,  
        address _cTokenAddress,
        address _monkeyAddress)
        ERC20("zDai Token", "zDai")     
        {
        ComptrollerAddress = _comptrollerAddress;        
        cTokenAddress = _cTokenAddress;
        UnderlyingAddress = _underlyingAddress; 
        MonkeyAddress = _monkeyAddress;
        
        }

 
    struct MintLocalVars {       
       
        uint exchangeRateMantissa;       
        uint actualMintAmount;
    }

    function deposit(uint256 amount) public nonReentrant returns (bool) {       

        // Erc20 underlying = Erc20(UnderlyingAddress); 
        // CErc20 cToken = CErc20(cTokenAddress);   
        // MathError mathErr;   

        MintLocalVars memory vars;

        //Get msg.sender's currency
        underlying.transferFrom(_msgSender(), address(this), amount);     
        
        // Amount of current exchange rate from cToken to underlying
        vars.exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", vars.exchangeRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(cTokenAddress, amount);        

        // Mint cToken
        uint mintResultcToken = cToken.mint(amount);
        require(mintResultcToken == 0, "CErc20.mint Error");
        
        //uint256 amountZToken = amount / exchangeRateMantissa;
        (mathErr, vars.actualMintAmount) = divScalarByExpTruncate(amount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");        

        //Mint zToken
        _mint(_msgSender(), vars.actualMintAmount);

        return true;

    }

    function depositFor( address _to, uint amount) public nonReentrant returns (bool) 
    {
        // Erc20 underlying = Erc20(UnderlyingAddress); 
        // CErc20 cToken = CErc20(cTokenAddress);   
        // MathError mathErr;
        uint actualMintAmount;

        //Get msg.sender's currency
        underlying.transferFrom(_msgSender(), address(this), amount);        

        // Approve transfer on the ERC20 contract
        underlying.approve(cTokenAddress, amount);

         // Mint cToken
        uint mintResultcToken = cToken.mint(amount);
        require(mintResultcToken == 0, "CErc20.mint Error");

        // Amount of current exchange rate from cToken to underlying
        uint exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);
        
        //uint256 amountZToken = amount / exchangeRateMantissa;
        (mathErr, actualMintAmount) = divScalarByExpTruncate(amount, Exp({mantissa: exchangeRateMantissa}));
        require(mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");        

        //Mint zToken
        _mint(_to, actualMintAmount);

        return true;
    }

    struct SeizeLocalVars {
        // MathError mathErr;
        bool isTrue;
        uint error;
        uint exchangeRate;
        uint zTokenAmount;
        uint underlying;
        uint cashIncToken;
        uint256 monkeyId;
        uint strengthCharacter;
        uint accountIndex;
        uint marketIndex;
        // uint principalTimesIndex;
        // uint strengthCharacterNew; 
        uint accountBalance;
        uint totalStrength;
        uint underWaterScope;
    }

    function depositToSeize( address borrower, uint repayAmount ) public nonReentrant returns (MathError, uint)
    {
        SeizeLocalVars memory vars;

        //Check borrower's total monkey strength and account balance.
        vars.totalStrength = findAccountTotalStrength(borrower);
        (vars.accountBalance, vars.isTrue) = accountBalance(borrower);

        //Borrower should under water and scope reach the limit of (0.2 * totalStrength).
        (mathErr, vars.underWaterScope) = mulScalarTruncate(Exp({mantissa: 200000000000000000}), vars.totalStrength);

        require(!vars.isTrue, "Borrower's account still above water!");

        require(vars.accountBalance > vars.underWaterScope, "Borrower still not reach limit.");

        require(vars.accountBalance >= repayAmount, "Can not seize borrower that much.");
        
        //Get msg.sender's currency
        underlying.transferFrom(_msgSender(), address(this), repayAmount); 

        //Repay borrow amount instead of borrower.
        (mathErr, vars.strengthCharacter) = repayBorrowInternal( borrower, repayAmount );
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        } 

        //Transfer borrower's zToken as compensation to caller

        return (MathError.NO_ERROR, vars.strengthCharacter);

    }

    struct BorrowLocalVars {
        // MathError mathErr;
        bool isTrue;
        uint error;
        uint exchangeRate;
        uint zTokenAmount;
        uint underlying;
        uint cashIncToken;
        uint256 monkeyId;
        uint strengthCharacter;
        uint accountIndex;
        uint marketIndex;
        // uint principalTimesIndex;
        uint strengthCharacterNew;
        uint accountBalance; 
    }

    function borrowUnderlying(       
        uint _borrowTokenAmount
    ) public nonReentrant returns (MathError, uint) 
    {       
        
        // CErc20 cToken = CErc20(cTokenAddress); 
        
        // MathError mathErr;

        BorrowLocalVars memory vars; 

        /*Check user's balance of underlying in cToken contract.
         * underlying = zTokenAmount * exchangeRate
         * User's borrow amount should <= underlying and < cashIncToken
         * User can't borrow without supply in cToken contract.
         *  Note: exchangeRateCurrent can update marketIndex  
         */        
        
        vars.cashIncToken = cToken.getCash();         
        require(vars.cashIncToken > _borrowTokenAmount, "cToken contract do not have enough cash.");

        //check msg.sender's balance of monkey
        uint balMon = monkey.balanceOf(_msgSender());
        
        // If borrower do not have monkey NFT, then create one.
        if(balMon == 0)
        {
            vars.exchangeRate = cToken.exchangeRateCurrent();
            vars.zTokenAmount = balanceOf(_msgSender());
            (mathErr, vars.underlying) = mulScalarTruncate(Exp({mantissa:vars.exchangeRate}), vars.zTokenAmount);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            emit MyLog('', vars.underlying);

            require(vars.underlying >= _borrowTokenAmount, "Do not have enough supply balance.");

            // Borrow underlying assects from cToken contract.
            vars.error = cToken.borrow(_borrowTokenAmount);
            require(vars.error == 0, "CToken borrow failed.");

            //Create a new monkey
            vars.monkeyId = monkey.createDemoMonkey( _msgSender());
            require(vars.monkeyId > 0, "Create monkey NFT failed.");           

            /* Set new monkey's character value of strength and borrowIndex.
             * uint accountIndex = borrowIndex;
             * uint strengthCharacter = _borrowTokenAmount;
             */ 
            vars.strengthCharacter = _borrowTokenAmount;
            vars.accountIndex = cToken.borrowIndex();
            monkey.setCharacters(vars.monkeyId, vars.strengthCharacter, vars.accountIndex);

            emit MyLog("", vars.monkeyId);
            emit MyLog("", vars.strengthCharacter);
            emit MyLog("", vars.accountIndex);

            return (MathError.NO_ERROR, vars.strengthCharacter);

        }else
        // if(balMon > 0) // Otherwise add new borrow amount to account first monkey strenth character and update accountIndex value.
        {
            //Check user's balance
            (vars.accountBalance, vars.isTrue) = accountBalance(_msgSender());
            require(vars.isTrue, "Borrower has been under water.");
            require(vars.accountBalance >= _borrowTokenAmount, "Borrow amount have surpassed supply balance.");

            //Find Monkey's strength character and accountIdex.
            (mathErr, vars.monkeyId, vars.strengthCharacter, vars.marketIndex) = findFirstMonkey(_msgSender());

            //strenthCharacterNew = strenthCharacter + _borrowTokenAmount
            (mathErr, vars.strengthCharacterNew) = addUInt(vars.strengthCharacter,  _borrowTokenAmount);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            } 

            //Total mount of borrows can not surpass underlying amount in cToken contract.
            // require(vars.underlying >= vars.strengthCharacterNew, "Borrow amount have surpassed supply balance."); 

            // Borrow addtional underlying assects from cToken contract.
            vars.error = cToken.borrow(_borrowTokenAmount);
            require(vars.error == 0, "CToken borrow failed.");
          
            //Set monkey's new character value of strength and accuntIndex.
            (vars.strengthCharacter, vars.accountIndex) = monkey.setCharacters(vars.monkeyId, vars.strengthCharacterNew, vars.marketIndex);

            emit MyLog('', vars.monkeyId);
            emit MyLog('', vars.strengthCharacter);
            emit MyLog('', vars.accountIndex);

            return (MathError.NO_ERROR, vars.strengthCharacter);
        }     
    }

    function repayBorrow(uint _amount) public nonReentrant returns (MathError, uint)
    {
        //check msg.sender's balance of monkey
        uint balMon = monkey.balanceOf(_msgSender());
        require(balMon > 0, "Create a monkey NFT firstly!" );

        return repayBorrowInternal( _msgSender(), _amount );
    }

    struct RepayBorrowLocalVars {      
        uint256 error;
        uint256 monkeyId;
        uint strengthCharacter;
        uint accountIndex;
        uint marketIndex;      
        uint strengthCharacterNew; 
    }
    
    function repayBorrowInternal( address _account, uint _amount)
        internal
        returns (MathError, uint)
    {
        RepayBorrowLocalVars memory vars;

        //Update cToken borrowIndex
        vars.error = cToken.accrueInterest();
        require(vars.error == 0, "CToken accrueInterest failed.");

        //Find Monkey's strength character and accountIdex.
        (mathErr, vars.monkeyId, vars.strengthCharacter, vars.marketIndex) = findFirstMonkey(_account);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        require(vars.strengthCharacter >= _amount, "Not enough strength to repay borrow.");

        //strenthCharacterNew = strenthCharacter - _amount
        (mathErr, vars.strengthCharacterNew) = subUInt(vars.strengthCharacter, _amount);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }  

        //Repay borrow amount to cToken contract.
        require(underlying.approve(cTokenAddress, _amount), "Underlying approve failed.");
        vars.error = cToken.repayBorrow(_amount);
        require(vars.error == 0, "CErc20.repayBorrow Error");

        //Set monkey's new character value of strength and accuntIndex.
        (vars.strengthCharacter, vars.accountIndex) = monkey.setCharacters(vars.monkeyId, vars.strengthCharacterNew, vars.marketIndex);
        
        emit MyLog('', vars.monkeyId);
        emit MyLog('', vars.strengthCharacter);
        emit MyLog('', vars.accountIndex);

        return (MathError.NO_ERROR, vars.strengthCharacter);
    }

    struct RedeemLocalVars {    
        bool isTrue;     
        uint256 exchangeRateMantissa;       
        uint redeemAmount;
        uint accountBalance; 
        uint256 redeemResult;     
    }
    
    function withdraw(uint256 _amountCtoken) public nonReentrant returns (uint) {        
       
        // Create a reference to the corresponding cToken contract, like cDAI
        // CErc20 cToken = CErc20(cTokenAddress);
        // Erc20 underlying = Erc20(UnderlyingAddress);
        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math
        // MathError mathErr;

        RedeemLocalVars memory vars; 

        // Amount of current exchange rate from cToken to underlying
        vars.exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", vars.exchangeRateMantissa);
       
        (mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), _amountCtoken);       
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr));
        }    

        (vars.accountBalance, vars.isTrue) = accountBalance(_msgSender());
        require(vars.isTrue, "Borrower has been under water.");
        require(vars.accountBalance >= vars.redeemAmount, "User do not have enough balance to withdraw.");         
        
        // if (redeemType == true) {
            // Retrieve your asset based on a cToken amount            
        vars.redeemResult = cToken.redeem(_amountCtoken);
        // } else {
            // Retrieve your asset based on an amount of the asset
            // redeemResult = cToken.redeemUnderlying(amount);
        // }
        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        require(vars.redeemResult == 0, "cToken redeem failed!");

        emit MyLog("If this is not 0, there was an error", vars.redeemResult);

        /* Burn user's zToken and transfer fund back to user
         * Withdraw amount of underlying eq to exchangeRateCurrent * _amountCtoken.
         */        
        _burn(_msgSender(), _amountCtoken);   //Burn user's zToken (zToken amount eq to cToken amount )               

        //Transfer underlying amount to user   
        require(underlying.transfer(_msgSender(), vars.redeemAmount), "Transfer underlying token to user failed.");             

        return vars.redeemAmount;

    }

    struct TransferNFTLocalVars {
        uint256 error;        
        uint256 exchangeRateMantissa; 
        uint strengthCharacter;
        uint accountIndex;  
        uint marketIndex;   
        uint redeemAmount;
        // uint accountBalance;
        uint principalTimesIndex;
        uint strengthCharacterNew; 
        uint amountZToken;  
        uint transferAmount;   
    }

    function transferNFTAndzToken( address _to, uint256 _NFTId ) public nonReentrant returns (bool) 
    {
        // CErc20 cToken = CErc20(cTokenAddress);
        // Monkey monkey = Monkey(MonkeyAddress);
        // MathError mathErr;

        TransferNFTLocalVars memory vars;

        //Find account all monkeys' NFT IDs.
        // uint256[] memory NFTIds = monkey.findMonkeyIdsOfAddress(_msgSender());

        require(_to != address(0), "MonkeyContract: Transfer to the zero address not allowed, burn NFT instead");
        require(_to != address(this), "MonkeyContract: Can't transfer NFTs to this contract");

        //Get msg.sender's balance of zToken.
        // uint256 amountZToken = balanceOf(_msgSender());

        //Update cToken borrowIndex.
        vars.error = cToken.accrueInterest();
        require(vars.error == 0, "CToken accrueInterest failed.");
        vars.marketIndex = cToken.borrowIndex();


        //Search first monkey's strength
        (vars.strengthCharacter, vars.accountIndex) = monkey.getMonkey(_NFTId); 

        /*  Calculate new strength Character. 
         *  strengthCharacter = strength * marketIndex / accountIndex
         */
        (mathErr, vars.principalTimesIndex) = mulUInt(vars.strengthCharacter, vars.marketIndex);
        if (mathErr != MathError.NO_ERROR) {
            return false;
        }
        (mathErr, vars.strengthCharacterNew) = divUInt(vars.principalTimesIndex, vars.accountIndex);
        if (mathErr != MathError.NO_ERROR) {
            return false;
        }

        //Set monkey's new character value of strength and accuntIndex.
        (vars.strengthCharacter, vars.accountIndex) = monkey.setCharacters(_NFTId, vars.strengthCharacterNew, vars.marketIndex);

        emit MyLog('', _NFTId);
        emit MyLog('', vars.strengthCharacter);
        emit MyLog('', vars.accountIndex);

        /*  Calculate amount of zToken to transfer with.
         *  Amount of strengthCharacter eq to underlying amount.
         */ 
        vars.exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", vars.exchangeRateMantissa);
        
        //uint256 amountZToken = amount / exchangeRateMantissa;
        (mathErr, vars.transferAmount) = divScalarByExpTruncate(vars.strengthCharacter, Exp({mantissa: vars.exchangeRateMantissa}));
        require(mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED"); 

        //Transfer zToken total balance to address _to.
        require(transfer(_to, vars.transferAmount), "zToken transfer to recipient failed.");

        //Transfer each monkey NFT from msg.sender to address _to
        monkey.safeTransferFrom(_msgSender(), _to, _NFTId);        

        return true;
    }

    struct accountLocalVars {       
        uint256 exchangeRateMantissa;       
        uint accountBalance;
        uint256 accountCtokenBalance; 
        uint accountUnderlyingBalance;       
        uint accountTotalStrength;
    }

    function accountBalance( address _account ) internal returns (uint, bool)
    {
        // Create a reference to the corresponding cToken contract, like cDAI
        // CErc20 cToken = CErc20(cTokenAddress);        
        // MathError mathErr;

        accountLocalVars memory vars;

        //Calculate user's account underlying amount.
        vars.exchangeRateMantissa = cToken.exchangeRateCurrent();
        vars.accountCtokenBalance = balanceOf(_account);
        (mathErr, vars.accountUnderlyingBalance) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), vars.accountCtokenBalance);
        if (mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr)), true);
        }

        //Find Monkeys' total strength.
        vars.accountTotalStrength = findAccountTotalStrength(_account);             

        if (vars.accountUnderlyingBalance >= vars.accountTotalStrength)
        {
            //Calculate user's total balance of underlying.
            (mathErr, vars.accountBalance) = subUInt(vars.accountUnderlyingBalance, vars.accountTotalStrength);
            if (mathErr != MathError.NO_ERROR) {
                return (failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr)), true);
            }

            emit MyLog('', vars.accountBalance);
            
            return (vars.accountBalance, true);

        }else
        {
            //Calculate user's total balance of underlying.
            (mathErr, vars.accountBalance) = subUInt(vars.accountTotalStrength, vars.accountUnderlyingBalance);
            if (mathErr != MathError.NO_ERROR) {
                return (failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr)), true);
            }

            emit MyLog('', vars.accountBalance);

            return (vars.accountBalance, false);

        }       
        
    }
  

    struct findLocalVars {        
        uint256 monkeyId;
        uint strengthCharacter;
        uint accountIndex;
        uint marketIndex;
        uint principalTimesIndex;
        uint strengthCharacterNew; 
    }

    function findFirstMonkey( address _account) internal returns (MathError, uint, uint, uint)
    {
        // Monkey monkey = Monkey(MonkeyAddress);
        // CErc20 cToken = CErc20(cTokenAddress);
        // MathError mathErr;

        findLocalVars memory vars;

        //Find msg.sender's monkey Id
        uint256[] memory monkeyTokenIds = monkey.findMonkeyIdsOfAddress(_account);

        //Only count amount to first monkey
        vars.monkeyId = monkeyTokenIds[0];

        emit MyLog('', vars.monkeyId);

        //Search first monkey's strength
        (vars.strengthCharacter, vars.accountIndex) = monkey.getMonkey(vars.monkeyId); 
               
        //Update new borrowIndex from cToken contract.
        vars.marketIndex = cToken.borrowIndex();

        /*  Calculate new strength Character. 
         *  strengthCharacter = strength * marketIndex / accountIndex
         */
        (mathErr, vars.principalTimesIndex) = mulUInt(vars.strengthCharacter, vars.marketIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0, 0, 0);
        }
        (mathErr, vars.strengthCharacterNew) = divUInt(vars.principalTimesIndex, vars.accountIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0, 0, 0);
        }

        return (MathError.NO_ERROR, vars.monkeyId, vars.strengthCharacterNew, vars.marketIndex);

    }

    function accountTotalStrengthCurrent(address _account) public returns (uint)
    {
        //Update cToken borrowIndex.
        uint error = cToken.accrueInterest();
        require(error == 0, "CToken accrueInterest failed.");
        
        return findAccountTotalStrength( _account);
    }

    struct findAccountLocalVars {        
        uint256 monkeyId;
        uint256 amountOwned;
        uint strengthCharacters;
        uint accountIndexs;
        uint marketIndex;
        uint principalTimesIndexs;
        uint strengthCharactersNew;
        uint sumOfStrength; 
    }

    function findAccountTotalStrength(address _account) internal returns (uint)
    {
        // Monkey monkey = Monkey(MonkeyAddress);
        // CErc20 cToken = CErc20(cTokenAddress);
        // MathError mathErr;

        findAccountLocalVars memory vars;

        //Find msg.sender's monkey Id
        uint256[] memory NFTIds = monkey.findMonkeyIdsOfAddress(_account);

        // uint[] memory (strengthCharacters, accountIndexs) = monkey.getMonkey(monkeyTokenIds)
        // vars.amountOwned =monkey.balanceOf(_account);

        //Update new borrowIndex from cToken contract.
        vars.marketIndex = cToken.borrowIndex();

        for (uint256 i = 0; i< NFTIds.length; i++ ) 
        {                       
            //Search monkeys' strength
            (vars.strengthCharacters, vars.accountIndexs) = monkey.getMonkey(NFTIds[i]);

            /*  Calculate each monkey's new borrow amount to value of strength 
             *  strengthCharacterNew = strength * marketIndex / accountIndex
             */
            (mathErr, vars.principalTimesIndexs) = mulUInt(vars.strengthCharacters, vars.marketIndex);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr));
            }
            (mathErr, vars.strengthCharactersNew) = divUInt(vars.principalTimesIndexs, vars.accountIndexs);
            if (mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(mathErr));
            }

            vars.sumOfStrength += vars.strengthCharactersNew;

        }    

        emit MyLog('',vars.sumOfStrength);   

        return vars.sumOfStrength;

    }

    function enterMarket() public onlyOwner returns (bool)
    {
        Comptroller comptroller = Comptroller(ComptrollerAddress);

        // Enter the market so you can borrow another type of asset.
        address[] memory cTokens = new address[](1);
        cTokens[0] = cTokenAddress;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("Comptroller.enterMarkets failed.");
        }

        return true;
    }

    function transferUnderlying(uint _underlyingAmount) public onlyOwner returns (uint)
    {
        // Erc20 underlying = Erc20(UnderlyingAddress);

        require(underlying.transfer(_msgSender(), _underlyingAmount), "Transfer underlying token to owner failed.");

        uint amount = _underlyingAmount;

        return amount;
        
    }


        /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
    
}