pragma solidity ^0.4.23;

import './iov_token.sol';

contract IOVCommunityDistribution is DSAuth, DSMath {
    IOVToken  public  IOV;                           // The IOV token itself

    mapping (address => bool) public isCommunityAdmin;  // community Admin accounts

    event LogAddCommunityAdmin(address whoAdded, address newAdmin);
    event LogRemoveCommunityAdmin(address whoRemoved, address admin);

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
            i += 1;
        }
        return(i);
    }
}