// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LawsHandler {
    address private owner;

    struct Tax {
        uint256 rate; // Tax rate in percentage (e.g., 5 for 5% tax)
        address collector; // Address where collected tax is sent
    }

    mapping(bytes32 => Tax) public taxes; // Mapping from tax type to tax information

    event TaxRateChanged(bytes32 taxType, uint256 newTaxRate);
    event TaxCollectorChanged(bytes32 taxType, address newTaxCollector);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function setTaxRate(bytes32 taxType, uint256 rate, address collector) public onlyOwner {
        require(rate <= 100, "Tax rate cannot exceed 100%");
        taxes[taxType] = Tax(rate, collector);
        emit TaxRateChanged(taxType, rate);
    }

    function getTaxRate(bytes32 taxType) public view returns (uint256) {
        return taxes[taxType].rate;
    }

    function getTaxCollector(bytes32 taxType) public view returns (address) {
        return taxes[taxType].collector;
    }

    function calculateTax(bytes32 taxType, uint256 amount) public view returns (uint256) {
        return (amount * taxes[taxType].rate) / 100;
    }
}

contract PropertyToken is ERC20 {
    address public owner;
    uint256 private _totalSupply;

    constructor(string memory _name, string memory _symbol, address _owner) ERC20(_name, _symbol) {
        owner = _owner;
        _totalSupply = 100 * 10**18; // 100 tokens with 18 decimal places (representing 100%)
        _mint(owner, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}

contract RentalProperty is PropertyToken {
    uint public requiredRentAmount = 500; // about $300 or 10000 gwei
    mapping(address => uint256) public investorLastWithdrawal;
    mapping(uint => uint) public investorsWithdrawnCount;
    address payable rentCollector;
    address public taxPayer;
    bytes32 constant TAX_TYPE = "RENTAL";

    constructor(string memory _name, string memory _symbol, address payable _rentCollec, address _taxPayer) PropertyToken(_name, _symbol, msg.sender) {
        rentCollector = _rentCollec;
        taxPayer = _taxPayer;
    }

    function payRent() payable public {
        require(msg.value >= requiredRentAmount, "Not enough value");
        rentCollector.transfer(msg.value);
        whenPaidRent.push(block.timestamp);
    }

    function seeCollectedRent() public view returns (uint) {
        return rentCollector.balance;
    }

    function withdrawShareOfRent() public payable {
        require(super.balanceOf(msg.sender) != 0, "Sender is not an investor");
        uint portionOfRentToReceive = (requiredRentAmount / totalMintedTokens);
        uint lastWithdrawal = investorLastWithdrawal[msg.sender];
        
        // Update withdrawal count for the current investor
        uint withdrawnCount = investorsWithdrawnCount[lastWithdrawal];
        if (withdrawnCount == 0) {
            investorsWithdrawnCount[lastWithdrawal] = 1;
        } else {
            investorsWithdrawnCount[lastWithdrawal]++;
        }

        // Distribute rent and update last withdrawal time
        payable(msg.sender).transfer(portionOfRentToReceive);
        investorLastWithdrawal[msg.sender] = block.timestamp;

        // Check if all investors have withdrawn rent up to the oldest withdrawal time
        uint oldestWithdrawal = whenPaidRent[0];
        if (oldestWithdrawal == lastWithdrawal) {
            // Remove the oldest withdrawal time
            delete whenPaidRent[0];
            while (whenPaidRent.length > 0 && whenPaidRent[0] == oldestWithdrawal) {
                delete whenPaidRent[0];
            }
        }

        // Collect tax
        require(msg.sender == taxPayer, "Only the tax payer can collect tax");
        uint taxAmount = calculateTax(TAX_TYPE, portionOfRentToReceive);
        rentCollector.transfer(taxAmount);
    }

    function getBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account);
    }
}

contract OwnedProperty is PropertyToken {
    struct Mortgage {
        address mortageOwner;
        uint256 mortgageEndTime;
        uint requiredAmount;
        bool isPaid;
    }

    Mortgage public mortgage;

    constructor(string memory _name, string memory _symbol) PropertyToken(_name, _symbol, msg.sender) {
        owner = msg.sender;
    }

    function isMortgagePaid() public view returns (bool) {
        return mortgage.isPaid;
    }
}

contract PropertyManager {
    enum PropertyType { Owned, Rental }

    mapping(uint => PropertyToken) public properties;
    mapping(uint => mapping(address => uint256)) public balances;
    mapping(uint => mapping(address => bool)) public isInvestor;

    uint public propertyCount;

    event PropertyCreated(uint indexed propertyId, PropertyType propertyType, address indexed propertyAddress);

    function createProperty(PropertyType propertyType, string memory name, string memory symbol, address payable rentCollector) external {
        propertyCount++;
        if (propertyType == PropertyType.Owned) {
            OwnedProperty ownedProperty = new OwnedProperty(name, symbol);
            properties[propertyCount] = ownedProperty;
            emit PropertyCreated(propertyCount, propertyType, address(ownedProperty));
        } else if (propertyType == PropertyType.Rental) {
            RentalProperty rentalProperty = new RentalProperty(name, symbol, rentCollector, msg.sender);
            properties[propertyCount] = rentalProperty;
            emit PropertyCreated(propertyCount, propertyType, address(rentalProperty));
        }
    }

    function getPropertyOwner(uint propertyId) public view returns (address) {
        PropertyToken property = properties[propertyId];
        return property.getOwner();
    }

    function getRentalPropertyBalance(address account, uint propertyId) public view returns (uint256) {
        RentalProperty rentalProperty = RentalProperty(properties[propertyId]);
        return rentalProperty.getBalanceOf(account);
    }
}
