pragma solidity ^0.4.23;

import './iov_token.sol';

contract IOVCommunityDistribution is DSAuth, DSMath {
    IOVToken  public  IOV;                           // The IOV token itself
    uint256   public  TOTAL_COMMUNITY_SUPPLY;        // Total IOV amount for community distribution
    uint256   public  AVAILABLE_COMMUNITY_SUPPLY;    // Remain tokens for community distribution
    mapping (address => uint256) public  _userDistributionAmount; // the distribution amount for each user

    mapping (address => bool) public isCommunityAdmin;  // community Admin accounts

    event LogAddCommunityAdmin(address whoAdded, address newAdmin);
    event LogRemoveCommunityAdmin(address whoRemoved, address admin);

    constructor(
        uint256  _distributionSupply
    ) public {
        TOTAL_COMMUNITY_SUPPLY       = _distributionSupply;  // 30% for community distribution
        AVAILABLE_COMMUNITY_SUPPLY   = _distributionSupply - 5*10**6*10**8; // 
    }

    function initialize(IOVToken iov) public auth {
        assert(address(IOV) == address(0));
        assert(iov.authority() == DSAuthority(0));

        IOV = iov;
    }

    function addCommunityAdmin(address admin) public auth returns (bool) {
        if(isCommunityAdmin[admin] == false) {
            isCommunityAdmin[admin] = true;
            emit LogAddCommunityAdmin(msg.sender, admin);
        }
        return true;
    }

    function removeCommunityAdmin(address admin) public auth returns (bool) {
        if(isCommunityAdmin[admin] == true) {
            isCommunityAdmin[admin] = false;
            emit LogRemoveCommunityAdmin(msg.sender, admin);
        }
        return true;
    }


    modifier onlyCommunityAdmin {
        require ( msg.sender == owner || isCommunityAdmin[msg.sender] );
        _;
    }

    function multiSend(address[] dests, uint256[] values) public onlyCommunityAdmin returns(uint256){
        uint256 i = 0;
        while (i < dests.length) {
            IOV.push(dests[i], values[i]);

            _userDistributionAmount[dests[i]] = add(_userDistributionAmount[dests[i]], values[i]);
            AVAILABLE_COMMUNITY_SUPPLY = sub(AVAILABLE_COMMUNITY_SUPPLY, values[i]);
            
            i += 1;
        }
        return(i);
    }
}