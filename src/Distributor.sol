// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.8.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.0/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract Distributor is ERC721, ERC721Enumerable, Ownable, AutomationCompatibleInterface {
    using Counters for Counters.Counter;

    uint256 private constant TRIAL_PERIOD = 15;
    
    struct Character {
        uint256 id;
        bool isTrialActive;
        uint256 expiryTimestamp;
    }

    event CharCreated(Character char);
    event CharUpdated(Character char);

    address[] private s_watchList;
    mapping(address => Character) internal s_characters;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Character", "CHAR") {
    }

    event NFTExpired(address indexed account, string message);

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmb5Ua5Qtoo3tSry7nxDf3X4mvFLZM9HY7BTrS1s5MzH7g/";
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        s_watchList.push(msg.sender);

        s_characters[msg.sender] = Character ({
                id: tokenId,
                isTrialActive: true,
                expiryTimestamp: block.timestamp + TRIAL_PERIOD
            });
            
        emit CharCreated(s_characters[msg.sender]);
    }

    function getExpiredAddresses()
        public
        view 
        returns (address[] memory expiredAddresses)
    {
        address[] memory watchList = s_watchList;
        address[] memory needsExpiry = new address[](watchList.length);
        uint256 count = 0;
        
        Character memory character;
        for (uint256 idx = 0; idx < watchList.length; idx++) {
            character = s_characters[watchList[idx]];
            if (
                block.timestamp >= character.expiryTimestamp && character.isTrialActive == true
            ) {
                needsExpiry[count] = watchList[idx];
                count++;
            }
        }
        if (count != watchList.length) {
            assembly {
                mstore(needsExpiry, count)
            }
        }
        return needsExpiry;
    }

    /**
     * @notice Get list of addresses that have trials expired and return payload compatible with Chainlink Automation Network
     * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need update
     */
    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address[] memory needsExpiry = getExpiredAddresses();
        upkeepNeeded = needsExpiry.length > 0;
        performData = abi.encode(needsExpiry);
        return (upkeepNeeded, performData);
    }

    /**
     * @notice Called by Chainlink Automation Node to update trial status
     * @param performData The abi encoded list of addresses to update trial status
     */
    function performUpkeep(
        bytes calldata performData
    ) external override  {
        address[] memory needsExpiry = abi.decode(performData, (address[]));
        makeExpire(needsExpiry);
    }

    /**
     * @notice update Character trial status to expired
     */
    function makeExpire(address[] memory needsExpiry) public {
        Character memory updateCharacter;
        for (uint256 idx = 0; idx < needsExpiry.length; idx++) {
            updateCharacter = s_characters[needsExpiry[idx]];

            s_characters[needsExpiry[idx]] = Character({
                id: updateCharacter.id,
                isTrialActive: false,
                expiryTimestamp: updateCharacter.expiryTimestamp
            });
            emit CharUpdated(s_characters[needsExpiry[idx]]);
        }
    }
    
    /**
     * @notice assumes each wallet can only own one trial NFT
     */
    function getCharacter(address ownerAddress)
        public
        view
        returns(Character memory character)
        {
            return s_characters[ownerAddress];
        }



    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
