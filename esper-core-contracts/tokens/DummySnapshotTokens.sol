// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ERC20Snapshot.sol";

contract DummySnapshotTokens is Ownable, ReentrancyGuard, ERC20("ST Receipt", "stRECEIPT"), ERC20Snapshot {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Allocate(address indexed userAddress, uint256 amount);
  event Deallocate(address indexed userAddress, uint256 amount);
  event UpdateDeallocationCooldown(uint256 newDuration);

  function snapshot() external onlyOwner {
    ERC20Snapshot._snapshot();
  }

  function allocate(address userAddress, uint256 amount) external nonReentrant {
    _mint(userAddress, amount);

    emit Allocate(userAddress, amount);
  }

  function deallocate(address userAddress, uint256 amount) external nonReentrant {
    _burn(userAddress, amount);

    emit Deallocate(userAddress, amount);
  }

  /**
   * @dev Hook override to forbid transfers except from minting and burning
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Snapshot) {
    require(from == address(0) || to == address(0), "transfer: not allowed");
    ERC20Snapshot._beforeTokenTransfer(from, to, amount);
  }

  // id 0 is invalidated
  function currentSnapshotId() external view returns (uint256) {
    return _currentSnapshotId.current() + 1;
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    /* solhint-disable not-rely-on-time */
    return block.timestamp;
  }
}
