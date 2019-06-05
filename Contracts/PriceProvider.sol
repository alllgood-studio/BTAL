pragma solidity ^0.5.7;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

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

    constructor () internal {
        _owner = msg.sender;
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
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

/**
 * @title PriceReceiver
 * @dev The PriceReceiver interface to interact with crowdsale.
 */
interface PriceReceiver {
    function setETHPrice(uint256 newPrice) external;
    function setDecimals(uint256 newDecimals) external;
}

/**
 * @title PriceProvider
 * @dev The PriceProvider contract to query price from oraclizer.
 * @author https://grox.solutions
 */
contract PriceProvider is Ownable, usingOraclize {
    using SafeMath for uint256;

    enum State { Stopped, Active }

    uint256 public updateInterval = 86400;

    uint256 public decimals;

    string public url;

    mapping (bytes32 => bool) validIds;

    PriceReceiver public watcher;

    State public state = State.Stopped;

    event InsufficientFunds();

    modifier inActiveState() {
        require(state == State.Active);
        _;
    }

    modifier inStoppedState() {
        require(state == State.Stopped);
        _;
    }

    constructor(string memory _url, address newWatcher) public {
        url = _url;
        setWatcher(newWatcher);
    }

    function() external payable {}

    function start_update() external payable onlyOwner inStoppedState {
        state = State.Active;

        _update(updateInterval);
    }

    function stop_update() external onlyOwner inActiveState {
        state = State.Stopped;
    }

    function setWatcher(address newWatcher) public onlyOwner {
        require(newWatcher != address(0));
        watcher = PriceReceiver(newWatcher);
    }

    function setCustomGasPrice(uint256 gasPrice) external onlyOwner {
        oraclize_setCustomGasPrice(gasPrice);
    }

    function setUpdateInterval(uint256 newInterval) external onlyOwner {
        require(newInterval > 0);
        updateInterval = newInterval;
    }

    function setUrl(string calldata newUrl) external onlyOwner {
        require(bytes(newUrl).length > 0);
        url = newUrl;
    }

    function setDecimals(uint256 newDecimals) public onlyOwner {
        require(newDecimals != 0);
        decimals = newDecimals;
        watcher.setDecimals(newDecimals);
    }

    function __callback(bytes32 myid, string memory result, bytes memory proof) public {
        require(msg.sender == oraclize_cbAddress() && validIds[myid]);
        delete validIds[myid];

        uint256 newPrice = parseInt(result, decimals);
        require(newPrice > 0);

        if (state == State.Active) {
            watcher.setETHPrice(newPrice);
            _update(updateInterval);
        }
    }

    function _update(uint256 delay) internal {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit InsufficientFunds();
        } else {
            bytes32 queryId = oraclize_query(delay, "URL", url);
            validIds[queryId] = true;
        }
    }

    function withdraw(address payable receiver) external onlyOwner {
        require(receiver != address(0));
        receiver.transfer(address(this).balance);
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }
}
