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
 * @title BTLToken interface
 */
interface BTLToken {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function released() external view returns (bool);
    function isAdmin(address account) external view returns (bool);
}

interface Crowdsale {
    function wallet() external view returns (address payable);
}

/**
 * @title Exchange contract
 */
contract Exchange {
    using SafeMath for uint256;

    BTLToken public BTL;

    mapping (address => bool) private _enlisted;

    uint256 private _balance;

    Crowdsale crowdsale;

    enum State {Stopped, Active}

    State public state = State.Stopped;

    modifier inActiveState() {
        require(state == State.Active && !BTL.released());
        _;
    }

    modifier inStoppedState() {
        require(state == State.Stopped);
        _;
    }

    modifier onlyAdmin() {
        require(BTL.isAdmin(msg.sender));
        _;
    }

    event Exchanged(address user, uint256 tokenAmount, uint256 weiAmount);

    constructor(address BTLAddr) public {
        require(BTLAddr != address(0));

        BTL = BTLToken(BTLAddr);
    }

    function receiveApproval(address payable from, uint256 amount, address token, bytes calldata extraData) external {
        require(token == address(BTL));
        exchange(from, amount);
    }

    function exchange(address payable from, uint256 amount) public inActiveState {
        BTL.transferFrom(from, address(this), amount);

        uint256 weiAmount = _balance * amount / (100000000 * 10**18);

        from.transfer(weiAmount);

        emit Exchanged(from, amount, weiAmount);
    }

    function() external payable inStoppedState {
        _balance += msg.value;
    }

    function finish() public onlyAdmin {
        require(BTL.released());
        state = State.Stopped;
        crowdsale.wallet().transfer(address(this).balance);
        state = State.Stopped;
    }

    function setCrowdsale(address addr) public onlyAdmin {
        require(addr != address(0));
        crowdsale = Crowdsale(addr);
    }

    function getDeposit(address addr) public view returns(bool) {
        return _enlisted[addr];
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = BTLToken(ERC20Token).balanceOf(address(this));
        BTLToken(ERC20Token).transfer(recipient, amount);

    }

}
