// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721TradableWithRoyalty.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: Abderrahmane Bouali for Lifestory

/**
 * @title LifePlanetNFT
 * LifePlanetNFT - a contract for Life nft.
 */
contract LifePlanetNFT is ERC721TradableWithRoyalty {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public cost = 0.27 ether; 
    uint256 public maxSupply = 5555;
    uint256 public maxOwnWhitelist = 2;
    uint256 public maxSupplyWhitelist = 200;
    uint256 public whitelistNumber = 0;
    mapping(uint256 => mapping(address => uint256)) public balanceWhitelist;
    
    string URIToken = "https://gateway.pinata.cloud/ipfs/QmU7EX2UTrgN8ykZdsYfmEeyHePgUSJwHJnwtwgzrvncY9?";
    string URIContract = "https://gateway.pinata.cloud/ipfs/Qme7ZBXFpJcjMSDTcFFQpYF9Y9jT7cN1yfpRaYF2UsPi4q";

    address payable private payments;


    // The key used to sign whitelist signatures.
    // We will check to ensure that the key that signed the signature
    // is the one that we expect.
    address public whitelistSigningKey = address(0xf11Ef1920a393A6d9C437B85e1c797be7F50A883);

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");
    
    // Event called when the cost changes
    event ChangedCost(uint256 _cost);

    /**
     * @dev Modifier to check if the sender is in the whitelist 
     * @param signature signature make by whitelistSigningKey
     */
    modifier requiresWhitelist(bytes calldata signature) {
        require(whitelistSigningKey != address(0), "LIFV: Whitelist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP712Base.getDomainSeperator(),
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == whitelistSigningKey, "Invalid Signature");
        _;
    }

    /**
     * @dev constructor of LifePlanetNFT 
     * @param _proxyRegistryOpenseaAddress address of the proxy contract of opensea
     * @param _royaltyBPS RoyaltyBPS
     * @param _payments Lifestory address 
     */
    constructor(address _proxyRegistryOpenseaAddress, address _payments, uint16 _royaltyBPS)
        ERC721TradableWithRoyalty(
            "Lifestory Planets",
            "LIFV",
            _payments,
            _royaltyBPS,
            _proxyRegistryOpenseaAddress
        )
    {
        payments = payable(_payments);
    }
    
    /**
     * @dev function to edit the address to verifiy signature for the whitelist 
     * @param newSigningKey public address on the new signer
     */
    function setWhitelistSigningAddress(address newSigningKey) public onlyOwner {
        whitelistSigningKey = newSigningKey;
    }

    /**
     * @dev Function mint for whitelisted
     * @dev Use the requiresWhitelist modifier to reject the call if a valid signature is not provided 
     * @param signature signature of whitelistSigningKey
     * @param _mintAmount mint amount 
     */
    function mintForWhitelisted(bytes calldata signature, uint256 _mintAmount) public payable requiresWhitelist(signature) {
        require(ERC721Tradable.totalSupply() + _mintAmount <= maxSupply, "LIFV: maximum supply of tokens has been exceeded");
        require(msg.value >= cost * _mintAmount,"LIFV: The amount sent is too low.");

        require(balanceWhitelist[whitelistNumber][msg.sender] + _mintAmount <= maxOwnWhitelist , "LIFV: You exceeded the maximum amount of tokens allowed for this whitelist.");
        require(ERC721Tradable.totalSupply() + _mintAmount <= maxSupplyWhitelist , "LIFV: maximum supply of tokens has been exceeded for this whitelist.");

        /// @notice Safely mint the NFTs
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);
            balanceWhitelist[whitelistNumber][msg.sender]++;
        }
    }

    /**
     * @dev Function mint
     * @param _mintAmount mint amount
     */
    function mint(uint256 _mintAmount) public payable {
        require(ERC721Tradable.totalSupply() + _mintAmount <= maxSupply, "LIFV: maximum supply of tokens has been exceeded");
        require(msg.value >= cost * _mintAmount,"LIFV: the amount sent is too low.");
        require(whitelistSigningKey == address(0), "LIFV: whitelist enabled");

        /// @notice Safely mint the NFTs
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, currentTokenId);
        }
    }

    /**
     * @dev Lifestory : Override function mintTo from Opensea contract ERC721Tradable.sol to avoid overtaking .
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) override public onlyOwner {
        require(ERC721Tradable.totalSupply() <= maxSupply, "LIFV: maximum supply of tokens has been exceeded");
        return ERC721Tradable.mintTo(_to);
    }

    /**
     * @dev Mints multiple tokens to an address with a tokenURI.
     * @dev Only the owner can run this function
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint256 _mintAmount) public onlyOwner {
        require(ERC721Tradable.totalSupply() + _mintAmount <= maxSupply, "LIFV: maximum supply of tokens has been exceeded");
        
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(_to, currentTokenId);
        }
    }
    
    /// @notice Withdraw proceeds from contract address to LIFESTORY address
    function withdraw() public payable onlyOwner {
        require(payable(payments).send(address(this).balance));
    }
    
    /** @notice Reset mint balance for whitelist
     */
    function changeWhitelist() public onlyOwner {
       whitelistNumber++;
    }

    /** @notice Overload function to change whitelist with new cost, new maxSupplyWhitelist and new maxOwnWhitelist
     *  @param _newCost New cost per NFT in Wei
     *  @param _newMaxSupplyWhitelist New maximum supply value for whitelist
     *  @param _newMaxOwnWhitelist New maximum value to own
     */
    function changeWhitelist(uint256 _newCost, uint256 _newMaxSupplyWhitelist, uint256 _newMaxOwnWhitelist) public onlyOwner {
        cost = _newCost;
        maxSupplyWhitelist = _newMaxSupplyWhitelist;
        maxOwnWhitelist = _newMaxOwnWhitelist;
        changeWhitelist();
        emit ChangedCost(cost);
    }

    /** @notice Update the maximum supply when enabling next whitelist
     *  @param _newMaxSupplyWhitelist New maximum supply value for whitelist
     */
    function setMaxSupplyWhitelist(uint256 _newMaxSupplyWhitelist) public onlyOwner {
        maxSupplyWhitelist = _newMaxSupplyWhitelist;
    }
    
    /** @notice Update the maximum you can own when whitelist is enabled
     *  @param _newMaxOwnWhitelist New maximum value to own
     */
    function setMaxOwnWhitelist(uint256 _newMaxOwnWhitelist) public onlyOwner {
        maxOwnWhitelist = _newMaxOwnWhitelist;
    }

    /** @notice Update COST
     *  @param _newCost New cost per NFT in Wei
     */
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
        emit ChangedCost(cost);
    }

    /** @notice Update URIToken
     *  @param _newURIToken New URI for the metadatas of NFTs
     */
    function setURIToken(string memory _newURIToken) public onlyOwner {
        URIToken = _newURIToken;
    }

    /** @notice Update URIContract
     *  @param _newURIContract New URI for the metadata of the contract
     */
    function setURIContract(string memory _newURIContract) public onlyOwner {
        URIContract = _newURIContract;
    }

    /** @notice Update payments address
     *  @param _newPayments New address to receive the recipe 
     */
    function setPayments(address _newPayments) public onlyOwner {
        payments = payable(_newPayments);
    }

    /** @notice Get base token uri for metadatas
     */
    function baseTokenURI() override public view returns (string memory) {
        return URIToken;
    }

    /** @notice Get contract metadatas uri 
     */
    function contractURI() public view returns (string memory) {
        return URIContract;
    }
}