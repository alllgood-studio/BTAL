pragma solidity 0.5.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
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
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
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

contract AdminRole is Ownable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender) || isOwner(msg.sender), "Sender has no permission");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return(_admins.has(account) || isOwner(account));
    }

    function addAdmin(address account) public onlyOwner {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyOwner {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * See https://eips.ethereum.org/EIPS/eip-20
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyOwner {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

interface Crowdsale {
    function endTime() external view returns(uint256);
    function whitelisted(address account) external view returns(bool);
    function reserved() external view returns(uint256);
    function reserveLimit() external view returns(uint256);
}

/**
 * @title LockableToken
 */
contract LockableToken is ERC20Mintable, AdminRole {

    bool private _released;

    // variables to store info about locked addresses
    mapping (address => bool) private _unlocked;
    mapping (address => Lock) private _locked;
    struct Lock {
        uint256 amount;
        uint256 time;
    }

    modifier canTransfer(address from, uint256 value) {
        if (
            !Crowdsale(msg.sender).whitelisted(from)
            && Crowdsale(msg.sender).reserved() != Crowdsale(msg.sender).reserveLimit()
        ) {
            require(_released || isOwner(msg.sender) || _unlocked[msg.sender]);
            if (_locked[from].amount > 0 && block.timestamp < _locked[from].time) {
                require(value <= _locked[from].amount);
            }
        }
        _;
    }

    /**
     * @dev Allows to lock an amount of tokens of specific addresses.
     * Available only to the owner and admin.
     * @param account address.
     * @param amount amount of tokens.
     * @param time period (Unix time).
     */
    function lock(address account, uint256 amount, uint256 time) external onlyAdmin {
        require(account != address(0) && amount != 0);
        _locked[account] = Lock(amount, time);
    }

    function unlock(address account) external onlyAdmin {
        require(account != address(0));
        if (_locked[account].amount > 0) {
            delete _locked[account];
        }
        _unlocked[account] = true;
    }

    function release() external onlyAdmin {
        require(block.timestamp >= Crowdsale(msg.sender).endTime());
        _released = true;
    }

    /**
     * @dev modified internal transfer function that prevents any transfer of locked tokens.
     * @param from address The address which you want to send tokens from
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal canTransfer(from, value) {
        super._transfer(from, to, value);
    }

    /**
     * @return true if tokens are released.
     */
    function released() external view returns(bool) {
        return _released;
    }

}


/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

/**
 * @title The main project contract.
 */
contract BTLToken is ERC20Mintable {

    // name of the token
    string private _name = "Bital Token";
    // symbol of the token
    string private _symbol = "BTL";
    // decimals of the token
    uint8 private _decimals = 18;

    // initial supply
    uint256 public constant INITIAL_SUPPLY = 250000000 * (10 ** 18);

    //
    mapping (address => bool) private _contracts;

    //
    uint256 private _hardcap = 1000000000 * (10 ** 18);

    /**
     * @dev constructor function that is called once at deployment of the contract.
     * @param recipient Address to receive initial supply.
     * @param initialOwner Address of owner of the contract.
     */
    constructor(address recipient, address initialOwner) public Ownable(initialOwner) {

        _mint(recipient, INITIAL_SUPPLY);

    }

    /**
     * @dev Allows to send tokens (via Approve and TransferFrom) to other smart contract.
     * @param spender Address of smart contracts to work with.
     * @param amount Amount of tokens to send.
     * @param extraData Any extra data.
     */
    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function addContract(address addr) external onlyOwner {
        require(addr != address(0));
        uint size;
        assembly { size := extcodesize(addr) }
        require(size > 0);
        _contracts[addr] = true;
    }

    function deleteContract(address addr) external onlyOwner {
        require(addr != address(0));
        _contracts[addr] = false;
    }

    /**
     * @dev modified transfer function that allows to safely send tokens to exchange contract.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

    /**
     * @dev modified transferFrom function that allows to safely send tokens to exchange contract.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            ApproveAndCallFallBack(to).receiveApproval(msg.sender, value, address(this), new bytes(0));
        } else {
            super.transferFrom(from, to, value);
        }

        return true;
    }

    /**
     * @dev Allows to any owner of the contract withdraw needed ERC20 token from this contract (promo or bounties for example).
     * @param ERC20Token Address of ERC20 token.
     * @param recipient Account to receive tokens.
     */
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return true if the address is registered as contract
     */
    function contracts(address addr) public view returns (bool) {
        return _contracts[addr];
    }

    /**
     * @return emission limit
     */
    function hardcap() public view returns(uint256) {
        return _hardcap;
    }

}