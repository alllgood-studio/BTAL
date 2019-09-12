pragma solidity 0.5.7;

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

/**
 * @title Crowdsale interface
 */
interface Crowdsale {
    function reserved() external view returns (uint256);
    function reserveLimit() external view returns (uint256);
    function reserveTrigger() external view returns (uint256);
    function isEnlisted(address account) external view returns (bool);
}

/**
 * @title Exchange contract
 */
contract Exchange {
    using SafeMath for uint256;

    BTLToken public BTL;
    Crowdsale public crowdsale;

    address payable private _reserveAddress;

    uint256 private _balance;

    modifier inActiveState() {
        require(
            crowdsale.reserved() >= crowdsale.reserveLimit()
            && !BTL.released()
            );
        _;
    }

    modifier onlyAdmin() {
        require(BTL.isAdmin(msg.sender), "Caller has no permission");
        _;
    }

    event Exchanged(address user, uint256 tokenAmount, uint256 weiAmount);
    event BalanceIncreased(address user, uint256 amount);

    constructor(address BTLAddr, address crowdsaleAddr, address payable reserveAddress) public {
        require(BTLAddr != address(0) && crowdsaleAddr != address(0) && reserveAddress != address(0));

        BTL = BTLToken(BTLAddr);
        crowdsale = Crowdsale(crowdsaleAddr);
        _reserveAddress = reserveAddress;
        _balance = address(this).balance;
    }

    function() external payable {
        acceptETH();
    }

    function acceptETH() public payable {
        _balance += msg.value;
        BalanceIncreased(msg.sender, msg.value);
    }

    function receiveApproval(address payable from, uint256 amount, address token, bytes calldata extraData) external {
        require(token == address(BTL));
        exchange(from, amount);
    }

    function exchange(address payable account, uint256 amount) public inActiveState {
        require(crowdsale.isEnlisted(account));
        BTL.transferFrom(account, address(this), amount);
        BTL.transfer(_reserveAddress, amount);

        uint256 weiAmount = getETHAmount(amount);

        account.transfer(weiAmount);

        emit Exchanged(account, amount, weiAmount);
    }

    function finish() public onlyAdmin {
        require(BTL.released());
        _reserveAddress.transfer(address(this).balance);
    }

    function setCrowdsaleAddr(address addr) public onlyAdmin {
        require(addr != address(0));
        require(isContract(addr));
        crowdsale = Crowdsale(addr);
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = BTLToken(ERC20Token).balanceOf(address(this));
        require(amount > 0);
        BTLToken(ERC20Token).transfer(recipient, amount);

    }

    function enlisted(address addr) public view returns(bool) {
        if (addr == address(this)) {
            return true;
        }
        return crowdsale.isEnlisted(addr);
    }

    function getETHAmount(uint256 tokenAmount) public view returns(uint256) {
        return tokenAmount.mul(_balance).div(crowdsale.reserveTrigger());
    }

    function reserveAddress() public view returns(address payable) {
        return _reserveAddress;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}
