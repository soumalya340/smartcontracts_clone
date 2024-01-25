// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../accessmaster/interfaces/IAccessMaster.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a creator role that allows for token minting (creation)
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the creator and pauser
 * roles, as well as the default admin role, which will let it grant both creator
 * roles to other accounts.
 */

// collection URI override

contract FusionSeries is Context, ERC1155Supply {

    string public name;
    string public symbol;

    address public tradeHub;
    address public accessMasterAddress;

    uint256 public Counter;
    uint8 public version = 1;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    IACCESSMASTER flowRoles;

    modifier onlyOperator() {
        require(
            flowRoles.isOperator(_msgSender()),
            "FusionSeries: Unauthorized!"
        );
        _;
    }

    modifier onlyCreator() {
        require(
            flowRoles.isCreator(_msgSender()),
            "FusionSeries: Unauthorized!"
        );
        _;
    }

    event FusionSeriesAssetCreated(
        uint256 indexed tokenID,
        address indexed creator,
        uint256 indexed amount,
        string metadataUri
    );
    event FusionSeriesAssetDestroyed(uint indexed tokenId, address ownerOrApproved);

    // tradeHub should be there
    /**
     * @dev Grants `FLOW_ADMIN_ROLE`, `FLOW_CREATOR_ROLE` and `FLOW_OPERATOR_ROLE` to the
     * account that deploys the contract.
     *
     */
    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        address tradeHubAddress,
        address flowContract
    ) ERC1155(baseURI) {
        name = _name;
        symbol = _symbol;
        tradeHub = tradeHubAddress;
        flowRoles = IACCESSMASTER(flowContract);
        accessMasterAddress = flowContract;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC1155-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     *
     * Requirements:
     *
     * - the caller must have the `FLOW_CREATOR_ROLE`.
     */
    function createAsset(
        uint256 amount,
        bytes memory data,
        string memory _uri
    ) public onlyCreator returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        Counter++;
        uint256 currentTokenID = Counter;
        _mint(_msgSender(), currentTokenID, amount, data);
        _tokenURIs[currentTokenID] = _uri;
        setApprovalForAll(tradeHub, true);
        emit FusionSeriesAssetCreated(currentTokenID, _msgSender(), amount,_uri);
        return currentTokenID;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC1155-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * Requirements:
     *
     * - the caller must have the `FLOW_CREATOR_ROLE`.
     */
    function delegateAssetCreation(
        address creator,
        uint256 amount,
        bytes memory data,
        string memory _uri
    ) public onlyOperator returns (uint256) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        Counter++;
        uint256 currentTokenID = Counter;
        _mint(creator, currentTokenID, amount, data);
        _tokenURIs[currentTokenID] = _uri;
        setApprovalForAll(tradeHub, true);
        emit FusionSeriesAssetCreated(currentTokenID, _msgSender(), amount,_uri);
        return currentTokenID;
    }

    /**
     * @notice Burns `tokenId`. See {ERC721-_burn}.
     *
     * @dev Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function destroyAsset(uint256 tokenId, uint256 amount) public {
        require(
            balanceOf(_msgSender(), tokenId) == amount,
            "FusionSeries: Caller is not token owner or approved"
        );
        _burn(_msgSender(), tokenId, amount);
        emit FusionSeriesAssetDestroyed(tokenId, _msgSender());
    }

    /// @dev  ONLY Operator can set the Base URI
    function setURI(string memory newuri) external onlyOperator {
        _setURI(newuri);
    }

    /** Getter Functions **/

    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}