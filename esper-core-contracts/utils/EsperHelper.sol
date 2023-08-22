// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IXEsperToken.sol";
import "./interfaces/IDividends.sol";
import "./interfaces/IPlugin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EsperHelper is Ownable {
  IXEsperToken public xEsper;
  IDividends public dividends;

  struct DividendsRewards {
    address token;
    uint256 currentDistributionAmount;
    uint256 pendingDistributionAmount;
  }

  struct PendingRewardsUserInDividends {
    address token;
    uint256 amount;
  }

  constructor(address _xEsper, address _dividends) {
    xEsper = IXEsperToken(_xEsper);
    dividends = IDividends(_dividends);
  }

  function setContractsAddress(address _xEsper, address _dividends) external onlyOwner {
    xEsper = IXEsperToken(_xEsper);
    dividends = IDividends(_dividends);
  }

  function dividendsDistributedTokensRewards() public view returns (DividendsRewards[] memory) {
    uint256 l = dividends.distributedTokensLength();
    address[] memory _tokens = new address[](l);
    DividendsRewards[] memory _allDividendsRewards = new DividendsRewards[](l);
    for (uint256 i = 0; i < l; i++) {
      _tokens[i] = dividends.distributedToken(i);
      (uint256 currentDistributionAmount, , uint256 pendingAmount, , , , , ) = dividends.dividendsInfo(_tokens[i]);
      _allDividendsRewards[i] = DividendsRewards(_tokens[i], currentDistributionAmount, pendingAmount);
    }
    return _allDividendsRewards;
  }

  function userAllocationInDividendsPlugin(address _user)
    external
    view
    returns (
      uint256 userTotalAllocation,
      uint256 userManualAllocation,
      uint256 userRedeemAllocation
    )
  {
    userTotalAllocation = dividends.usersAllocation(_user);
    userManualAllocation = xEsper.usageAllocations(_user, address(dividends));
    uint256 l = xEsper.getUserRedeemsLength(_user);
    for (uint256 i = 0; i < l; i++) {
      (, , , , uint256 dividendsAllocation) = xEsper.getUserRedeem(_user, i);
      userRedeemAllocation += dividendsAllocation;
    }
  }

  function userPendingRewardsInDividendsPlugin(address _user)
    external
    view
    returns (PendingRewardsUserInDividends[] memory)
  {
    uint256 l = dividends.distributedTokensLength();
    PendingRewardsUserInDividends[] memory _allPendingRewards = new PendingRewardsUserInDividends[](l);
    for (uint256 i = 0; i < l; i++) {
      address _token = dividends.distributedToken(i);
      uint256 _pendingRewards = dividends.pendingDividendsAmount(_token, _user);
      _allPendingRewards[i] = PendingRewardsUserInDividends(_token, _pendingRewards);
    }
    return _allPendingRewards;
  }

  function deallocationFeePlugin(address _plugin) external view returns (uint256) {
    return xEsper.usagesDeallocationFee(_plugin);
  }

  function totalAllocationAtPlugin(address _plugin) external view returns (uint256) {
    return IPlugin(_plugin).totalAllocation();
  }

  // APR Calculation
  // oo

  // function getTokenPrice(
  //   address token,
  //   address UniPool,
  //   address wethAddress
  // ) external view returns (uint256 price) {
  //   uint256 token_in_pool = IERC20(token).balanceOf(UniPool);
  //   uint256 weth_in_pool = IERC20(wethAddress).balanceOf(UniPool);
  //   price = (weth_in_pool * getEtherPrice() * 1e10) / token_in_pool;
  // }
}
