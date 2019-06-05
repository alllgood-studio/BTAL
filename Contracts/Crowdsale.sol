pragma solidity ^0.5.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title token interface
 */
interface BTLToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function lock(address account, uint256 amount, uint256 time) external;
    function release() external;
    function hardcap() external view returns(uint256);
    function isAdmin(address account) external view returns (bool);
}

/**
 * @title exchange interface
 */
interface Exchange {
    function finish() external;
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    BTLToken private _token;

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender));
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyAdmin {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function addListToWhitelist(address[] memory accounts) public onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisteds.add(accounts[i]);
            emit WhitelistedAdded(accounts[i]);
        }
    }

    function removeWhitelisted(address account) public onlyAdmin {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

/**
 * @title PriceReceiver interface
 * @dev Inherit from PriceReceiver to use the PriceProvider contract.
 */
contract PriceReceiver {

    address public ethPriceProvider;

    function setETHPrice(uint256 newPrice) external;

    function setDecimals(uint256 newDecimals) external;

    function setEthPriceProvider(address provider) external;

}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @title Crowdsale contract
 */
contract Crowdsale is ReentrancyGuard, PriceReceiver, WhitelistedRole {
    using SafeMath for uint256;

    // The token being sold
    BTLToken private _token;

    // Address where funds are collected
    address payable private _wallet;
    address payable private _reserveAddr;
    address private _teamAddr;
    Exchange private _exchange;

    // Amount of wei raised
    uint256 private _weiRaised;
    uint256 private _tokensPurchased;
    uint256 private _reserved;
    uint256 private _reserveLimit;

    // Price of 1 ether in USD Cents
    uint256 private _currentETHPrice;
    uint256 private _decimals;

    // How many token units a buyer gets per 1 USD
    uint256 private _rate;

    // Bonus percent (5% = 5)
    uint256 private _bonusPercent;

    // Minimum amount of wei to invest
    uint256 private _minimum = 0.1 ether;

    // Limit of emission of crowdsale
    uint256 private _hardcap;

    // ending time (UNIX)
    uint256 private _endTime;

    enum State {OFF, ON}

    State public reserve = State.OFF;
    State public whiteList = State.OFF;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensSent(address indexed sender, address indexed beneficiary, uint256 amount);
    event NewETHPrice(uint256 oldValue, uint256 newValue, uint256 decimals);

    modifier active() {
        require(block.timestamp <= _endTime);
        _;
    }

    modifier onlyAdmin() {
        require(_token.isAdmin(msg.sender));
        _;
    }

    /**
     * @param rate Number of token units a buyer gets per wei
     * @param initialETHPrice Price of Ether in USD Cents
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     */
    constructor (uint256 rate, uint256 initialETHPrice, address payable wallet, BTLToken token) public {
        require(rate != 0, "Rate is 0");
        require(initialETHPrice != 0, "Initial ETH price is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(address(token) != address(0), "Token is the zero address");

        _rate = rate;
        _currentETHPrice = initialETHPrice;
        _wallet = wallet;
        _token = token;
    }

    /**
     * @dev fallback function
     */
    function() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev token purchase
     * This function has a non-reentrancy guard
     * Can be called only before end time
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable nonReentrant active {
        require(beneficiary != address(0), "New parameter value is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than 0.5 ether");

        if (whiteList == State.ON) {
            require(isWhitelisted(msg.sender), "Sender is not whitelisted");
        }

        uint256 weiAmount = msg.value;

        uint256 tokens = weiToTokens(weiAmount);

        if (_tokensPurchased.add(tokens) > _hardcap) {
            weiAmount = tokensToWei((_hardcap.sub(_tokensPurchased)).div(100 + _bonusPercent).mul(100));
            tokens = _hardcap.sub(_tokensPurchased);
            msg.sender.transfer(msg.value.sub(weiAmount));
        }

        if (_tokensPurchased.add(tokens) > 100000000 * (10**18) && reserve == State.OFF) {
            reserve = State.ON;
            _wallet.transfer(tokensToWei((100000000 * (10**18)) - _tokensPurchased));
            refund(weiAmount.sub(tokensToWei((100000000 * (10**18)) - _tokensPurchased)));
        } else {
            refund(weiAmount);
        }

        uint256 bonus = tokens.mul(_bonusPercent).div(100);
        _token.mint(beneficiary, tokens + bonus);

        _tokensPurchased += tokens + bonus;
        _weiRaised = _weiRaised.add(weiAmount);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    }

    function sendTokens(address recipient, uint256 amount) public onlyAdmin {
        require(recipient != address(0));
        _token.mint(recipient, amount);

        emit TokensSent(msg.sender, recipient, amount);
    }

    function sendTokensToList(address[] memory recipients, uint256 amount) public onlyAdmin {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Recipient is the zero address");
            _token.mint(recipients[i], amount);
            emit TokensSent(msg.sender, recipients[i], amount);
        }
    }

    function sendTokensPerWei(address recipient, uint256 weiAmount) public onlyAdmin {
        require(recipient != address(0));
        _token.mint(recipient, weiToTokens(weiAmount));

        emit TokensSent(msg.sender, recipient, weiToTokens(weiAmount));
    }

    function refund(uint256 weiAmount) internal {
        address payable recipient;
        if (reserve == State.OFF) {
            recipient = _wallet;
        } else {
            uint256 usdAmount = weiToUSD(weiAmount);

            if (_reserved.add(usdAmount) >= _reserveLimit) {
                _wallet.transfer(weiAmount - USDToWei(_reserveLimit - _reserved));
                weiAmount = USDToWei(_reserveLimit - _reserved);
                _reserved = _reserveLimit;
            } else {
                _reserved = _reserved.add(usdAmount);
                recipient = _reserveAddr;
            }

        }

        recipient.transfer(weiAmount);
    }

    function finishSale() public onlyAdmin {
        require(_tokensPurchased == _hardcap || block.timestamp >= _endTime);

        _token.mint(_wallet, _token.hardcap().sub(_tokensPurchased));
        _token.lock(_teamAddr, _token.balanceOf(_teamAddr), 31536000);
        _token.release();
        _exchange.finish();
    }

    /**
     * @dev Calculate amount of tokens to recieve for a given amount of wei
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function weiToTokens(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).mul(_rate).div(_decimals).div(1 ether);
    }

    /**
     * @dev Calculate amount of wei needed to by given amount of tokens
     * @param tokenAmount amount of tokens
     * @return wei amount that one need to send to buy the specified tokenAmount
     */
    function tokensToWei(uint256 tokenAmount) public view returns(uint256) {
        return tokenAmount.mul(1 ether).mul(_decimals).div(_rate).div(_currentETHPrice);
    }

    /**
     * @dev Calculate amount of USD for a given amount of wei
     * @param weiAmount amount of tokens
     * @return USD amount
     */
    function weiToUSD(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).div(_decimals).div(1 ether);
    }

    /**
     * @dev Calculate amount of wei for given amount of USD
     * @param USDAmount amount of USD
     * @return wei amount
     */
    function USDToWei(uint256 USDAmount) public view returns(uint256) {
        return USDAmount.mul(1 ether).mul(_decimals).div(_currentETHPrice);
    }

    /**
     * @dev Function to change the rate.
     * Available only to the admin and owner.
     * @param newRate new value.
     */
    function setRate(uint256 newRate) external onlyAdmin {
        require(newRate != 0, "New parameter value is 0");

        _rate = newRate;
    }

    /**
     * @dev Function to change the PriceProvider address.
     * Available only to the admin and owner.
     * @param provider new address.
     */
    function setEthPriceProvider(address provider) external onlyAdmin {
        require(provider != address(0), "New parameter value is the zero address");

        ethPriceProvider = provider;
    }

    /**
     * @dev Function to change the address to receive ether.
     * Available only to the admin and owner.
     * @param newWallet new address.
     */
    function setWallet(address payable newWallet) external onlyAdmin {
        require(newWallet != address(0), "New parameter value is the zero address");

        _wallet = newWallet;
    }

    /**
     * @dev Function to change the ETH Price.
     * Available only to the admin and owner and to the PriceProvider.
     * @param newPrice amount of USD Cents for 1 ether.
     */
    function setETHPrice(uint256 newPrice) external {
        require(newPrice != 0, "New parameter value is 0");
        require(msg.sender == ethPriceProvider || _token.isAdmin(msg.sender), "Sender has no permission");

        emit NewETHPrice(_currentETHPrice, newPrice, _decimals);
        _currentETHPrice = newPrice;
    }

    /**
     * @dev Function to change the USD decimals.
     * Available only to the admin and owner and to the PriceProvider.
     * @param newDecimals amount of numbers after decimal point.
     */
    function setDecimals(uint256 newDecimals) external {
        require(newDecimals != 0, "New parameter value is 0");
        require(msg.sender == ethPriceProvider || _token.isAdmin(msg.sender), "Sender has no permission");

        _decimals = newDecimals;
    }

    /**
     * @dev Function to change the end time.
     * Available only to the admin and owner.
     * @param newTime amount of numbers after decimal point.
     */
    function setEndTime(uint256 newTime) external onlyAdmin {
        require(newTime != 0, "New parameter value is 0");

        _endTime = newTime;
    }

    /**
     * @dev Function to change the bonus percent.
     * Available only to the admin and owner.
     * @param newPercent amount of numbers after decimal point.
     */
    function setBonusPercent(uint256 newPercent) external onlyAdmin {
        require(newPercent != 0, "New parameter value is 0");

        _bonusPercent = newPercent;
    }

    /**
     * @dev Function to change the hardcap.
     * Available only to the admin and owner.
     * @param newCap new hardcap value.
     */
    function setHardCap(uint256 newCap) external onlyAdmin {
        require(newCap != 0, "New parameter value is 0");

        _hardcap = newCap;
    }

    /**
     * @dev Function to change activate/deactivate whitelist.
     * Available only to the admin and owner.
     */
    function switchWhitelist() external onlyAdmin {
        if (whiteList == State.OFF) {
            whiteList = State.ON;
        } else {
            whiteList = State.OFF;
        }
    }

    /**
    * @dev Allows to any owner of the contract withdraw needed ERC20 token from this contract (promo or bounties for example).
    * @param ERC20Token Address of ERC20 token.
    * @param recipient Account to receive tokens.
    */
    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = BTLToken(ERC20Token).balanceOf(address(this));
        BTLToken(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (BTLToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the price of 1 ether in USD Cents.
     */
    function currentETHPrice() public view returns (uint256 price, uint256 decimals) {
        return(_currentETHPrice, _decimals);
    }

    /**
     * @return minimum amount of wei to invest.
     */
    function minimum() public view returns (uint256) {
        return _minimum;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the reserved amount of ETH in USD.
     */
    function reserved() public view returns (uint256) {
        return _reserved;
    }

    /**
     * @return the reserved limit in USD.
     */
    function reserveLimit() public view returns (uint256) {
        return _reserveLimit;
    }

}
