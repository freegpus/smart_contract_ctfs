// SPDX-License-Identifier: MIT
//Based off the Hypebears hack - https://blocksecteam.medium.com/when-safemint-becomes-unsafe-lessons-from-the-hypebears-security-incident-2965209bda2a

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract ExclusiveNFT is ERC721("ExclusiveNFT", "XN"), ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;

    address public proxyRegistryAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    string private baseURI;
    string private blindURI;
    uint256 public mintLimit = 1;
    uint256 private constant TOTAL_NFT = 10000;
    uint256 public mintPrice = 0.4 ether;
    bool public reveal;
    bool public mintActive = true;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public addressMinted;
    address whitelistSigner;
    uint256 public partnerMintAmount = 100;
    mapping(address => uint256) public partnerMintAvailableBy;

    constructor() {
        partnerMintAvailableBy[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = 50;
        partnerMintAvailableBy[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = 49;
        partnerMintAvailableBy[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC] = 1;
    }


    function revealNow() external onlyOwner {
        reveal = true;
    }

    function setMintActive(bool _isActive) external onlyOwner {
        mintActive = _isActive;
    }

    function setURIs(string memory _blindURI, string memory _URI) external onlyOwner {
        blindURI = _blindURI;
        baseURI = _URI;
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function addToWhitelist(address _newAddress) external onlyOwner {
        whitelist[_newAddress] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addMultipleToWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeMultipleFromWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function canMint(address _address) public view returns (bool, string memory) {
        if (addressMinted[_address]) {
            return (false, "Already minted an NFT");
        }
        return (true, "");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 amount1 = balance * 70 / 100;
        uint256 amount2 = balance - amount1;
        payable(0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB).transfer(amount1);
        payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148).transfer(amount2);
    }

    function updateMintLimit(uint256 _newLimit) public onlyOwner {
        mintLimit = _newLimit;
    }

    function updateMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function addPartnerMint(address account, uint256 amount) public onlyOwner {
        partnerMintAmount += amount;
        require(totalSupply().add(partnerMintAmount) <= TOTAL_NFT, "Can't add partner more than available");
        partnerMintAvailableBy[account] += amount;
    }

    function mintNFT(uint256 _numOfTokens) public payable {
        require(mintActive, 'Not active');
        require(_numOfTokens <= mintLimit, "Can't mint more than limit per tx");
        require(mintPrice.mul(_numOfTokens) <= msg.value, "Insufficient payable value");
        require(totalSupply().add(_numOfTokens).add(partnerMintAmount) <= TOTAL_NFT, "Can't mint more than 10000");
        (bool success, string memory reason) = canMint(msg.sender);
        require(success, reason);

        for(uint i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        addressMinted[msg.sender] = true;
    }

    function partnersMintMultiple(address[] memory _to) public {
        uint256 amount = _to.length;
        require(partnerMintAmount >= amount, "Can't mint more than total available for partners");
        require(partnerMintAvailableBy[msg.sender] >= amount, "Can't mint more than available for msg.sender");
        for(uint256 i = 0; i < amount; i++){
            _safeMint(_to[i],totalSupply() + 1);
        }
        partnerMintAmount -= amount;
        partnerMintAvailableBy[msg.sender] -= amount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!reveal) {
            return string(abi.encodePacked(blindURI));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        }
    }

    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function updateProxy(address _proxy) external onlyOwner {
        proxyRegistryAddress = _proxy;
    }

}