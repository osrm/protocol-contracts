// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAsset } from "./IPAsset.sol";
import { IPAssetRegistryFactory } from "./ip-assets/IPAssetRegistryFactory.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { IVersioned } from "./utils/IVersioned.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract FranchiseRegistry is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    ERC721Upgradeable
{
    event FranchiseRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId
    );
    error AlreadyRegistered();

    /// @custom:storage-location erc7201:story-protocol.franchise-registry.storage
    struct FranchiseStorage {
        uint256 franchiseIds;
        /// Franchise id => IPAssetRegistry address
        mapping(uint256 => address) ipAssetRegistries;
    }

    IPAssetRegistryFactory public immutable FACTORY;
    
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.franchise-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x5648324915b730d22cca7279385130ad43fd4829d795fb20e9ab398bfe537e8f;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);
    string private constant _VERSION = "0.1.0";

    constructor(address _factory) {
        _disableInitializers();
        if (_factory == address(0)) revert ZeroAddress("factory");
        FACTORY = IPAssetRegistryFactory(_factory);
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
        __ERC721_init("Story Protocol", "SP");
    }

    function _getFranchiseStorage() private pure returns (FranchiseStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function registerFranchise(
        string calldata name,
        string calldata symbol,
        string calldata description
    ) external returns (uint256, address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        address ipAssetRegistry = FACTORY.createFranchiseBlocks(
            ++$.franchiseIds,
            name,
            symbol,
            description
        );
        $.ipAssetRegistries[$.franchiseIds] = ipAssetRegistry;
        _safeMint(msg.sender, $.franchiseIds);
        emit FranchiseRegistered(msg.sender, $.franchiseIds, ipAssetRegistry);
        return ($.franchiseIds, ipAssetRegistry);
    }

    function ipAssetRegistryForId(
        uint256 franchiseId
    ) public view returns (address) {
        FranchiseStorage storage $ = _getFranchiseStorage();
        return $.ipAssetRegistries[franchiseId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}