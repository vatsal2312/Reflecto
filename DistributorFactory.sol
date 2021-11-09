// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DividendDistributor.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeMath.sol";

contract DistributorFactory {
    using SafeMath for uint256;
    address _token;

    struct structDistributors {
        DividendDistributor distributorAddress;
        uint256 index;
        string tokenName;
        bool exists;
    }

    mapping(address => structDistributors) public distributorsMapping;
    address[] public distributorsArrayOfKeys;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
    }

    function addDistributor(
        address _router,
        address _BEP_TOKEN,
        address _wbnb
    ) external onlyToken returns (bool) {
        require(
            !distributorsMapping[_BEP_TOKEN].exists,
            "Reflecto/Distributor already exists"
        );

        IBEP20 BEP_TOKEN = IBEP20(_BEP_TOKEN);
        DividendDistributor distributor = new DividendDistributor(
            _router,
            _BEP_TOKEN,
            _wbnb
        );

        distributorsArrayOfKeys.push(_BEP_TOKEN);
        distributorsMapping[_BEP_TOKEN].distributorAddress = distributor;
        distributorsMapping[_BEP_TOKEN].index =
            distributorsArrayOfKeys.length -
            1;
        distributorsMapping[_BEP_TOKEN].tokenName = BEP_TOKEN.name();
        distributorsMapping[_BEP_TOKEN].exists = true;

        // set shares
        if (distributorsArrayOfKeys.length > 0) {
            address firstDistributerKey = distributorsArrayOfKeys[0];

            uint256 shareholdersCount = distributorsMapping[firstDistributerKey]
                .distributorAddress
                .getShareholders()
                .length;

            for (uint256 i = 0; i < shareholdersCount; i++) {
                address shareholderAddress = distributorsMapping[
                    firstDistributerKey
                ].distributorAddress.getShareholders()[i];

                uint256 shareholderAmount = distributorsMapping[
                    firstDistributerKey
                ].distributorAddress.getShareholderAmount(shareholderAddress);

                distributor.setShare(shareholderAddress, shareholderAmount);
            }
        }

        return true;
    }

    function getShareholderAmount(address _BEP_TOKEN, address shareholder)
        external
        view
        returns (uint256)
    {
        return
            distributorsMapping[_BEP_TOKEN]
                .distributorAddress
                .getShareholderAmount(shareholder);
    }

    function deleteDistributor(address _BEP_TOKEN)
        external
        onlyToken
        returns (bool)
    {
        require(
            distributorsMapping[_BEP_TOKEN].exists,
            "Reflecto/Distributor not found"
        );

        structDistributors memory deletedDistributer = distributorsMapping[
            _BEP_TOKEN
        ];
        // if index is not the last entry
        if (deletedDistributer.index != distributorsArrayOfKeys.length - 1) {
            // delete distributorsArrayOfKeys[deletedDistributer.index];
            // last strucDistributer
            address lastAddress = distributorsArrayOfKeys[
                distributorsArrayOfKeys.length - 1
            ];
            distributorsArrayOfKeys[deletedDistributer.index] = lastAddress;
            distributorsMapping[lastAddress].index = deletedDistributer.index;
        }
        delete distributorsMapping[_BEP_TOKEN];
        distributorsArrayOfKeys.pop();
        return true;
    }

    function getDistributorsAddresses() public view returns (address[] memory) {
        return distributorsArrayOfKeys;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        uint256 arrayLength = distributorsArrayOfKeys.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            distributorsMapping[distributorsArrayOfKeys[i]]
                .distributorAddress
                .setShare(shareholder, amount);
        }
    }

    function process(uint256 gas) external onlyToken {
        uint256 arrayLength = distributorsArrayOfKeys.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            distributorsMapping[distributorsArrayOfKeys[i]]
                .distributorAddress
                .process(gas);
        }
    }

    function deposit() external payable onlyToken {
        uint256 arrayLength = distributorsArrayOfKeys.length;
        uint256 valuePerToken = msg.value.div(arrayLength);

        for (uint256 i = 0; i < arrayLength; i++) {
            distributorsMapping[distributorsArrayOfKeys[i]]
                .distributorAddress
                .deposit{value: valuePerToken}();
        }
    }

    function getDistributor(address _BEP_TOKEN)
        public
        view
        returns (DividendDistributor)
    {
        return distributorsMapping[_BEP_TOKEN].distributorAddress;
    }

    function getTotalDistributers() public view returns (uint256) {
        return distributorsArrayOfKeys.length;
    }

    function setDistributionCriteria(
        address _BEP_TOKEN,
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyToken {
        distributorsMapping[_BEP_TOKEN]
            .distributorAddress
            .setDistributionCriteria(_minPeriod, _minDistribution);
    }
}
