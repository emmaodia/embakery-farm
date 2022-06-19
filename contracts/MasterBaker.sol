// SPDX-License-Identifier: GPL-3

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./BreadToken.sol";

contract MasterBaker is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // The explicit variable names aids in my understanding of what each varible is meant to do/can do
    struct PoolInfo {
        IERC20 lpToken;
        uint allocPoint; // How many BreadTokens to be distributed per block. Users will get a share of this allocated to their accBreadPerShare
        uint256 lastRewardBlock;
        uint256 accBreadPerShare;
    }

    BreadToken public bread;

    address public contractOwner;

    uint256 public breadPerBlock;

    PoolInfo[] public poolInfo;

    //mapping of users using integers to holds the addresses of each users that stakes in the pool
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    event Deposit(address _from, uint256 _poolId, uint256 _amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);

    constructor (
        BreadToken _bread,
        uint256 _breadPerBlock,
        uint256 _startBlock
    ) {
        bread = _bread;
        contractOwner = msg.sender;
        breadPerBlock = _breadPerBlock;
        startBlock = _startBlock;

        //staking Pool
        poolInfo.push(PoolInfo({
            lpToken: _bread,
            allocPoint: 1000,
            lastRewardBlock: _startBlock,
            accBreadPerShare: 0
        }));

        totalAllocPoint = 1000;
    }

    /*function to add the Liquidty token to the Pool. You can use DAI for example*/

    // the lpToken is the token contract for which a user wishes to provide liquidity, this could be USDC for example
    // this function can only be called by the contract owner who selects a token for which to provide liquidity
    function createLPpool(uint _allocPoint, IERC20 _lpToken ) public onlyOwner {
        require(_lpToken != bread, "Cannot create another bread pool");
        uint256 _lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            // token: "0x07865c6E87B9F70255377e024ace6630C1Eaa37F",
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accBreadPerShare: 0
        }));

    }


    // Deposit LP token to earn BREAD per block
    function depositToLPpool(uint _poolId, uint256 _amount) public {
        require(_poolId != 0, "You cannot stake BREAD");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        updateRewards(_poolId);

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount); // this is the amount the user has deposited to the lp stored in the user struct on memory. remember the address mapping to struct

        user.rewardDebt = user.amount.mul(pool.accBreadPerShare).div(1e12);

        //If a new user doesn't call this method, last user rewards are not updated
        // uint256 breadReward = breadPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
        // bread.mint(contractOwner, breadReward.div(10));

        emit Deposit(msg.sender, _poolId, _amount);
    }

    // Withdraw stake LP tokens from the contract

    function withdrawStakedLPtokens(uint _poolId, uint256 _amount) public {
        require(_poolId != 0, "You cannot stake BREAD");

        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];

        require(user.amount >= _amount, "You Shall NOT pass!");

        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        user.rewardDebt = user.amount.mul(pool.accBreadPerShare).div(1e12);

        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function updateRewards(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }   

        uint256 breadReward = breadPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
        SafeERC20.safeTransfer(bread, address(this), breadReward.div(10));

        pool.accBreadPerShare = pool.accBreadPerShare.add(breadReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
}