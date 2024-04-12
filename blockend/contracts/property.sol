// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
uint constant PERCENTAGE_TO_WEI = 1000000000000000000; 
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

    function calculateTax(bytes32 taxType, uint256 amount) public view returns (uint256) {
        return (amount * taxes[taxType].rate) / 100;
    }

    function collectTax(bytes32 taxType, uint256 amount) public {
        address taxCollector = taxes[taxType].collector;
        require(taxCollector != address(0), "Tax collector not set for this tax type");
        require(msg.sender == taxCollector, "Only the tax collector can collect tax");
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balanceOf(msg.sender), "Insufficient balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }
}
contract RentalProperty is PropertyToken {
    // Additional properties for rent functionality
    uint[] public whenPaidRent;
    uint public requiredRentAmount = 10000 * 10**9; // about $300 or 10000 gwei
    mapping(address => uint256) public investorLastWithdrawal;
    mapping(uint => uint) public investorsWithdrawnCount;
    uint public totalMintedTokens = 100;
    address payable rentCollector;
    constructor(string memory _name, string memory _symbol, address payable _rentCollec) PropertyToken(_name, _symbol, msg.sender) {
        rentCollector = _rentCollec;
    }

    function payRent() payable public {
        require(msg.value >= requiredRentAmount, "Not enough value");
        rentCollector.transfer(msg.value);
        whenPaidRent.push(block.timestamp);
    }

    function seeCollectedRent() public  view returns (uint){
        return rentCollector.balance;
    }

    function withdrawShareOfRent() public payable {
        require(super.balanceOf(msg.sender) != 0, "Sender is not an investor");
        uint portionOfRentToReceive = (requiredRentAmount / totalMintedTokens) * super.balanceOf(msg.sender);
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
    }

    function buyPropertyShares(uint numberOfShares) public {
        super._transfer(owner,msg.sender, (numberOfShares * PERCENTAGE_TO_WEI));
    }
}

contract OwnedProperty is PropertyToken {

    constructor(string memory _name, string memory _symbol) PropertyToken(_name, _symbol, msg.sender) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
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
            RentalProperty rentalProperty = new RentalProperty(name, symbol,rentCollector);
            properties[propertyCount] = rentalProperty;
            emit PropertyCreated(propertyCount, propertyType, address(rentalProperty));
        }
    }

    function invest(uint propertyId, uint256 amount) external {
        require(amount > 0, "Invalid investment amount");

        PropertyToken property = properties[propertyId];
        require(property.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        balances[propertyId][msg.sender] += amount;
        isInvestor[propertyId][msg.sender] = true;
    }

    function withdraw(uint propertyId, uint256 amount) external {
        require(isInvestor[propertyId][msg.sender], "Not an investor");
        require(balances[propertyId][msg.sender] >= amount, "Insufficient balance");

        PropertyToken property = properties[propertyId];
        require(property.transfer(msg.sender, amount), "Transfer failed");

        balances[propertyId][msg.sender] -= amount;
    }
}
