// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// preparing for some functions to be restricted 
import "@openzeppelin/contracts/access/Ownable.sol";
// preparing safemath to rule out over- and underflow  
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// importing ERC721Enumerable token standard interface
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// // importing openzeppelin script to guard against re-entrancy
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// importing openzeppelin script to make contract pausable
import "@openzeppelin/contracts/security/Pausable.sol";



contract MonkeyContract is ERC721Enumerable, Ownable, Pausable {

    // using safemath for all uint256 numbers, 
    // use uint256 and (.add) and (.sub)
    using SafeMath for uint256;

    // STATE VARIABLES

    // MonkeyContract address
    address _monkeyContractAddress;  

    bool internal _notEntered = true; 
    // Only 12 monkeys can be created from scratch (generation 0)
    // uint256 public GEN0_Limit = 12;
    // uint256 public gen0amountTotal;  
   
    // STRUCT

    // this struct is the blueprint for new NFTs, they will be created from it
    struct CryptoMonkey {        
        uint strength;
        uint accountIndex;
        uint luckyNumber;
        string genes;
        uint256 birthtime;
        bool isLocked;
    }    

    // ARRAYS

    // This is an array that holds all CryptoMonkey NFTs. 
    // IMPORTANT: Their position in this array IS their Token ID.
    // They never get deleted here, array only grows and keeps track of them all.
    CryptoMonkey[] public cryptoMonkeys;
    // mapping(uint256 => CryptoMonkey) public cryptoMonkeys;

    // EVENTS

    // Creation event, emitted after successful NFT creation with these parameters
    event MonkeyCreated(
        address owner,
        uint256 tokenId,
        uint256 strength,
        uint256 accountIndex    
    );

    // event BreedingSuccessful (
    //     uint256 tokenId, 
   
    //     uint256 birthtime, 
    //     uint256 parent1Id, 
    //     uint256 parent2Id, 
     
    //     address owner
    // );
    
    // Constructor function
    // is setting _name, and _symbol   
    constructor() ERC721("Crypto Monkeys", "MONKEY") {
        
        _monkeyContractAddress = address(this); 

        // minting a placeholder Zero Monkey, that occupies Token ID 0
        _createMonkey(0, 0, 0, '', false, _msgSender());  

        // burning placeholder zero monkey
        burnNFT(0);
    }

    // Functions 
    function setCharacters(uint256 _tokenId, uint256 _strength, uint _accountIndex) public onlyOwner returns (uint256, uint256) {
        
        CryptoMonkey storage cryptoMonkey = cryptoMonkeys[_tokenId];
        
        cryptoMonkey.strength = _strength;
        cryptoMonkey.accountIndex = _accountIndex; 
       
        return (cryptoMonkey.strength, cryptoMonkey.accountIndex); 
    }

    // pausing funcionality from OpenZeppelin's Pausable
    function pause() public onlyOwner {
        _pause();
    }

    // unpausing funcionality from OpenZeppelin's Pausable
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // public function to show contract's own address
    function getMonkeyContractAddress() public view returns (address) {  
        return _monkeyContractAddress;
    }   

    // gives back all the main details on a NFT
    function getMonkeyDetails(uint256 tokenId)
        public
        view
        returns (
            // uint256 genes,
            uint256 birthtime,
            uint256 strength,
            uint256 accountIndex,
            // uint256 generation,
            address owner,
            address approvedAddress
        )
    {
        return (
            // allMonkeysArray[tokenId].genes,
            cryptoMonkeys[tokenId].birthtime,
            cryptoMonkeys[tokenId].strength,
            cryptoMonkeys[tokenId].accountIndex,
            // allMonkeysArray[tokenId].generation,
            ownerOf(tokenId),
            getApproved(tokenId)
        );
    }   

    function getMonkey(uint256 tokenId)
        public
        view
        returns (
            // uint256 genes,
            // uint256 birthtime,
            uint256 strength,
            uint256 accountIndex
            // uint256 generation,
            // address owner,
            // address approvedAddress
        )
    {
        return (
            // allMonkeysArray[tokenId].genes,
            // cryptoMonkeys[tokenId].birthtime,
            cryptoMonkeys[tokenId].strength,
            cryptoMonkeys[tokenId].accountIndex
            // allMonkeysArray[tokenId].generation,
            // ownerOf(tokenId),
            // getApproved(tokenId)
        );
    } 

    // gives back an array with the NFT tokenIds that the provided sender address owns
    // deleted NFTs are kept as entries with value 0 (token ID 0 is used by Zero Monkey)
    function findMonkeyIdsOfAddress(address owner) public view returns (uint256[] memory) {

        uint256 amountOwned = balanceOf(owner);             

        uint256[] memory ownedTokenIDs = new uint256[](amountOwned);

        for (uint256 indexToCheck = 0; indexToCheck < amountOwned; indexToCheck++ ) {
            
            uint256 foundNFT = tokenOfOwnerByIndex(owner, indexToCheck);

            ownedTokenIDs[indexToCheck] = foundNFT;                                  
        } 

        return ownedTokenIDs;        
    }      

    // used for creating gen0 monkeys 
    // function createGen0Monkey() public onlyOwner {
     
    //     _createMonkey(0, 0,  _msgSender());
        
    // }    
        
    // how to bind this to frontend inputs? maybe calling randomizing functions in contract first, whose data then get minted, paid at start of randomizing
    // make this a demo function with generation 99    
    function createDemoMonkey(               
        // uint256 _genes,
        address _owner
    ) public onlyOwner returns (uint256) {
        // uint256 newMonkey = _createMonkey(99, 99, 99, _genes, _owner);
        uint8 luckyNumber = _getRandom();
        uint256 newMonkey = _createMonkey(99, 99, luckyNumber, "RVN", false,  _owner);
        return newMonkey;
    }

    
    // used for creating monkeys (returns tokenId, could be used)
    function _createMonkey(
        uint _strength,
        uint _accountIndex,
        uint _luckyNumber,
        string memory _genes,
        bool _isLocked,
        address _owner
    ) private whenNotPaused returns (uint256) {
        // uses the CryptoMonkey struct as template and creates a newMonkey from it
            CryptoMonkey memory newMonkey = CryptoMonkey({                
            strength: uint (_strength),
            accountIndex: uint (_accountIndex),
            luckyNumber: uint8(_luckyNumber),
            // generation: uint256(_generation),
            genes: _genes,
            isLocked: _isLocked,
            birthtime: uint256(block.timestamp)
        });        
        
        // the push function also returns the length of the array, using that directly and saving it as the ID, starting with 0
        // allMonkeysArray.push(newMonkey);
        cryptoMonkeys.push(newMonkey);
        uint256 newMonkeyId = cryptoMonkeys.length.sub(1);

        // after creation, transferring to new owner, 
        // to address is calling user address, sender is 0 address
        _safeMint(_owner, newMonkeyId);    

        emit MonkeyCreated(_owner, newMonkeyId, _strength, _accountIndex);                    

        // This is the Token ID of the new NFT
        return newMonkeyId;
    } 

    // burning functionality, just to be called once from the constructor, to clear the zero monkey
    function burnNFT (        
        uint256 _tokenId
    ) private nonReentrant whenNotPaused{       
        
        require (_isApprovedOrOwner(_msgSender(), _tokenId) == true, "MonkeyContract: Can't burn this NFT without being owner, approved or operator");         

        // burning via openzeppelin
        _burn(_tokenId);       
    }

       
    // overriding ERC721's function, including whenNotPaused for added security
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyOwner whenNotPaused {
             
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    // overriding ERC721's function, including whenNotPaused for added security
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyOwner whenNotPaused {
       
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");        
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
    * @dev Returns a binary between 00000000-11111111
    */
    function _getRandom() internal view returns (uint8) {
        return uint8(block.timestamp % 255);
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
