
pragma solidity ^0.4.23;

import "./iov_token.sol";


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract IOVTokenVesting is DSAuth, DSMath {

  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogIOVClaimed(address indexed _recipient, uint256 _amountClaimed);

  event LogAddVestingAdmin(address whoAdded, address newAdmin);
  event LogRemoveVestingAdmin(address whoRemoved, address admin);

  //Allocation with vesting information
  struct Allocation {
    uint256  start;          // Start time of vesting contract
    uint256  cliff;          // Duration in seconds of the cliff in which tokens will begin to vest
    uint256  duration;       // Duration for vesting
    uint256  totalAllocated; // Total tokens allocated 
    uint256  amountClaimed;  // Total tokens claimed
  }

  IOVToken  public  IOV;
  mapping (address => Allocation) public beneficiaries;
  mapping (address => bool) public isVestingAdmin;  // community Admin accounts

  // constructor function
  constructor(IOVToken iov) public {
    assert(address(IOV) == address(0));
    IOV = iov;
  }

  // Contract admin related functions
  function addVestingAdmin(address admin) public auth returns (bool) {
      if(isVestingAdmin[admin] == false) {
          isVestingAdmin[admin] = true;
          emit LogAddVestingAdmin(msg.sender, admin);
      }
      return true;
  }

  function removeVestingAdmin(address admin) public auth returns (bool) {
      if(isVestingAdmin[admin] == true) {
          isVestingAdmin[admin] = false;
          emit LogRemoveVestingAdmin(msg.sender, admin);
      }
      return true;
  }

  modifier onlyVestingAdmin {
      require ( msg.sender == owner || isVestingAdmin[msg.sender] );
      _;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function totalUnClaimed() public view returns (uint256) {
    return IOV.balanceOf(this);
  }

  /**
  * @dev Allow the owner of the contract to assign a new allocation
  * @param _recipient The recipient of the allocation
  * @param _totalAllocated The total amount of IOV allocated to the receipient (after vesting)
  * @param _start Start time of vesting contract
  * @param _cliff Duration in seconds of the cliff in which tokens will begin to vest
  * @param _duration Duration for vesting
  */
  function setAllocation(address _recipient, uint256 _totalAllocated, uint256 _start, uint256 _cliff, uint256 _duration) public onlyVestingAdmin {
    require(beneficiaries[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_duration > _cliff);
    require(_recipient != address(0));
    
    beneficiaries[_recipient] = Allocation(_start, _cliff, _duration, _totalAllocated, 0);
    emit LogNewAllocation(_recipient, _totalAllocated);
  }

  /**
   * @notice Transfer a recipients available allocation to their address.
   * @param _recipient The address to withdraw tokens for
   */
  function transferTokens(address _recipient) public {
    require(beneficiaries[_recipient].amountClaimed < beneficiaries[_recipient].totalAllocated);
    require(now >= add(beneficiaries[_recipient].start, beneficiaries[_recipient].cliff));

    uint256 unreleased = releasableAmount(_recipient);

    require(unreleased > 0);

    IOV.transfer(_recipient, unreleased);

    beneficiaries[_recipient].amountClaimed = vestedAmount(_recipient);

    emit LogIOVClaimed(_recipient, unreleased);
  }


  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param _recipient The address which is being vested
   */
  function releasableAmount(address _recipient) public view returns (uint256) {
    return sub( vestedAmount(_recipient), beneficiaries[_recipient].amountClaimed );
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _recipient The address which is being vested
   */
  function vestedAmount(address _recipient) public view returns (uint256) {
    if( block.timestamp < add(beneficiaries[_recipient].start, beneficiaries[_recipient].cliff) ) {
      return 0;
    } else if( block.timestamp >= add( beneficiaries[_recipient].start, beneficiaries[_recipient].duration) ) {
      return beneficiaries[_recipient].totalAllocated;
    } else {
      return div( mul(beneficiaries[_recipient].totalAllocated, sub(block.timestamp, beneficiaries[_recipient].start)), beneficiaries[_recipient].duration );
    }
  }
}