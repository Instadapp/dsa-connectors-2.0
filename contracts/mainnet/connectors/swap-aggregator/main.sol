//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";

contract SwapAggregatorConnector is Helpers, Events {
    struct RouterInfo {
        address router;
        address allowanceHolder;
    }

    mapping(string => RouterInfo) public routers;

    address public chief;
    address public master;

    modifier onlyChiefOrMaster() {
        require(msg.sender == chief || msg.sender == master, "Not authorized");
        _;
    }

    modifier onlyMaster() {
        require(msg.sender == master, "Not authorized");
        _;
    }

    constructor(address _chief, address _master) {
        chief = _chief;
        master = _master;
    }

    function updateChief(address _newChief) external onlyMaster {
        require(_newChief != address(0), "Invalid chief address");
        chief = _newChief;
    }

    function setRouter(
        string calldata connectorName,
        address router,
        address allowanceHolder
    ) external onlyChiefOrMaster {
        routers[connectorName] = RouterInfo(router, allowanceHolder);
    }

    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        string calldata connectorName,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(
            routers[connectorName].router != address(0),
            "Connector not enabled"
        );
        RouterInfo memory info = routers[connectorName];

        Helpers.SwapData memory swapData = Helpers.SwapData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        swapData = _swap(swapData, info.router, info.allowanceHolder, setId);

        _eventName = "LogSwap(address,address,uint256,uint256,address,address,uint256)";
        _eventParam = abi.encode(
            address(swapData.buyToken),
            address(swapData.sellToken),
            swapData._buyAmt,
            swapData._sellAmt,
            info.router,
            info.allowanceHolder,
            setId
        );
    }
}

contract ConnectV2SwapAggregator is SwapAggregatorConnector {
    string public name = "Insta-Swap-Aggregator-v1.0";
    constructor(
        address _chief,
        address _master
    ) SwapAggregatorConnector(_chief, _master) {}
}
