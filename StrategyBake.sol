/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return payable(account);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
}

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. TOKENs to distribute per block.
        uint256 lastRewardBlock; // Last block number that TOKENs distribution occurs.
        uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
        bool exists; //
    }

interface dRewards {
    // function userInfo(uint256,address) external returns (UserInfo calldata);
    // function deposit(uint256 _pid, uint256 _amount) external;
    // function withdraw(uint256 _pid, uint256 _amount) external;
   
    function poolInfoMap(address) external returns(PoolInfo calldata);
    function poolUserInfoMap(address,address) external returns(UserInfo calldata);
    
    function stake(address _pair, uint256 _amount) external;
    function unstake(address _pair, uint256 _amount) external;
    function pendingToken(address _pair, address _user) external returns (uint256);
}


interface UniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] calldata amounts);
}

contract StrategyBakeWar {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5);
    address constant public pool = address(0x52c26308Fe70fd188c7eFAAD11663e5B3ead42C9);
     address constant public _pair = address(0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5);
    address constant public output = address(0x42dbD44a8883D4363B395F77547812DC7dB806d5);
    address constant public unirouter = address(0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F);
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); 

    address constant public yfam = address(0xB4A413232c01330C84da47A848DbCE7FDE96B0f0);

    
    uint public strategyfee = 0;
    uint public fee = 400;
    uint public burnfee = 500;
    uint public callfee = 100;
    uint constant public max = 1000;

    uint public withdrawalFee = 0;
    uint constant public withdrawalMax = 10000;
    
    address public governance;
    address public strategyDev;
    address public controller;
    address public burnAddress = 0x5207fDa92936F2740009909bE84E53A18B72c36c;

    string public getName;

    address[] public swap2YFAMRouting;
    address[] public swap2TokenRouting;
    
    
    constructor() public {
        governance = msg.sender;
        controller = 0x03C98C5eB82dB2528efEDE442ecAa1FB728CD25C;
        getName = string(
            abi.encodePacked("xyz:Strategy:", 
                abi.encodePacked(IERC20(want).name(),"DF Token"
                )
            ));
        swap2YFAMRouting = [output,yfam];
        swap2TokenRouting = [output,wbnb,want];
        doApprove();
        strategyDev = tx.origin;
    }

    function doApprove () public{
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, uint(-1));
    }
    
    
    function deposit() public {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(pool, 0);
            IERC20(want).safeApprove(pool, _want);
            dRewards(pool).stake(_pair, _want);
        }
        
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        
        uint _fee = 0;
        if (withdrawalFee>0){
            _fee = _amount.mul(withdrawalFee).div(withdrawalMax);        
            IERC20(want).safeTransfer(Controller(controller).rewards(), _fee);
        }
        
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        
        
        balance = IERC20(want).balanceOf(address(this));
        
        address _vault = Controller(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        UserInfo memory user = dRewards(pool).poolUserInfoMap(_pair,address(this));
        dRewards(pool).unstake(_pair,user.amount);
    }
    
    function harvest() public {
        require(!Address.isContract(msg.sender),"!contract");
        dRewards(pool).stake(_pair,0);
        
        doswap();
        dosplit();
        deposit();
    }
    
    function getNumOfRewards() public returns (uint256 pending) {
        pending = dRewards(pool).pendingToken(_pair,address(this));
    }

    function doswap() internal {
        uint256 _2token = IERC20(output).balanceOf(address(this)).mul(90).div(100); //90%
        uint256 _2yfam = IERC20(output).balanceOf(address(this)).mul(10).div(100);  //10%
        if(_2token > 1000)
        {
            UniswapRouter(unirouter).swapExactTokensForTokens(_2token, 0, swap2TokenRouting, address(this), now.add(1800));
        }
        if(_2yfam > 1000)
        {
            UniswapRouter(unirouter).swapExactTokensForTokens(_2yfam, 0, swap2YFAMRouting, address(this), now.add(1800));
        }
    }
    function dosplit() internal{
        uint b = IERC20(yfam).balanceOf(address(this));
        uint _fee = b.mul(fee).div(max);
        uint _callfee = b.mul(callfee).div(max);
        uint _burnfee = b.mul(burnfee).div(max);
        IERC20(yfam).safeTransfer(Controller(controller).rewards(), _fee); //4%  3% team +1% insurance
        IERC20(yfam).safeTransfer(msg.sender, _callfee); //call fee 1%
        IERC20(yfam).safeTransfer(burnAddress, _burnfee); //burn fee 5%

        if (strategyfee >0){
            uint _strategyfee = b.mul(strategyfee).div(max);
            IERC20(yfam).safeTransfer(strategyDev, _strategyfee);
        }
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        dRewards(pool).unstake(_pair,_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _withdrew = _after.sub(_before);
        return _withdrew;
        
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfPool() public payable returns (uint) {
        UserInfo memory user = dRewards(pool).poolUserInfoMap(_pair,address(this));
        return user.amount;
    }
    
    
    function balanceOf() public payable returns (uint) {
        return balanceOfWant()
              .add(balanceOfPool());
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
    function setFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        fee = _fee;
    }
    function setStrategyFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        strategyfee = _fee;
    }
    function setCallFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        callfee = _fee;
    }
    function setBurnFee(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        burnfee = _fee;
    }
    function setBurnAddress(address _burnAddress) public{
        require(msg.sender == governance, "!governance");
        burnAddress = _burnAddress;
    }

    function setWithdrawalFee(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee <=100,"fee >= 1%"); //max:1%
        withdrawalFee = _withdrawalFee;
    }
}