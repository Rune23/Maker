contract FeedSource {
	function getFeed() returns (uint priceFeed) {}
	function getPeg() returns (bool pegFeed) {}
}

contract DepositableContract {
    function contractDepositor(address sender, uint amount) returns(bool success) {}
}

contract Keeper {
	
	mapping (address => uint) shares;

	function coinTransfer(address receiver, uint amount) {
		if (shares[msg.sender] >= amount) {
			DelegateVoter v = voterList[msg.sender];
			if (v.votingStatus["setkeeper"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setKeeper"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setcollreq"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setcollreq"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setforcedcoverrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setforcedcoverrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["sethardcallrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["sethardcallrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["sethardcallrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["sethardcallrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setfeedsource"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setfeedsource"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["withdrawether"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["withdrawether"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["withdrawedollar"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["withdrawedollar"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["forcedcover"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["forcedcover"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			shares[msg.sender] -= amount;
			shares[receiver] += amount;
		}
	}

	function depositToContract(address receiver, uint amount) {
        DepositableContract cont = DepositableContract(receiver);
        if (shares[msg.sender] >= amount &&
                cont.contractDepositor(msg.sender,amount)) {
        	DelegateVoter v = voterlist[msg.sender];
        	if (v.votingStatus["setkeeper"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setKeeper"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setcollreq"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setcollreq"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setforcedcoverrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setforcedcoverrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["sethardcallrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["sethardcallrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["sethardcallrate"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["sethardcallrate"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["setfeedsource"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setfeedsource"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["withdrawether"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["withdrawether"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["withdrawedollar"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["withdrawedollar"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			if (v.votingStatus["forcedcover"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["forcedcover"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
            balance[msg.sender] -= amount;
            balance[receiver] += amount;
        }
    }

	address feedSourceAddr;

	eDollar dlr;

	FeedSource fdsrc;

	mapping (bytes => address) permission;

	uint primingDelay

	function setPegFromSource() {
		dlr.setPeg(fdsrc.getPeg());
	}

	function setFeedFromSource() {
		dlr.setFeed(fdsrc.getFeed());
	}

	function delegateSetKeeper(address newKeeper) {
		if (permission["setkeeper"] == msg.sender) {
			dlr.setKeeper(newKeeper);
		}
	}

	function delegateSetCollReq(uint newCollReq) {
		if (permission["setcollreq"] == msg.sender) {
			dlr.setcollreq(newCollReq);
		}
	}

	function delegateSetForcedCoverRate(uint newRate) {
		if (permission["setforcedcoverrate"] = msg.sender) {
			dlr.setForcedCoverRate(newRate);
		}
	}


	function delegateSetHardCallRate(uint newRate) {
		if (permission["sethardcallrate"] = msg.sender) {
			dlr.setHardCallRate(newRate);
		}
	}

	function delegateSetFeedSource(address newFeed) {
		if (permission["setfeedsource"] = msg.sender) {
			feedSourceAddr = newFeed;
		}
	}

	function delegateWithDrawEther(address receiver, uint amount) {
		if (permission["withdrawether"] = msg.sender) {
			receiver.send(amount);
		}
	}
	function delegateWithDrawEDollar(address receiver, uint amount) {
		if (permission["withdrawedollar"] = msg.sender) {
			dlr.coinTransfer(receiver, amount);
		}
	}

	function delegateForcedCover(address calledAccount, uint modifier) {
		if (permission["forcedcover"] = msg.sender) {
			dlr.forcedCover(calledAccount, modifier);
		}
	}

	struct DelegateCampaign {
		bytes permissionTarget;
		uint votes;
		uint primingBlock;
		bool primed;
	}

	mapping (address => DelegateCampaign) campaigns;

	struct DelegateVoter {
		mapping (bytes => address) voteAddresses;
		mapping (bytes => bool) votingStatus;
	}

	mapping (address => DelegateVoter) voterlist;

	function createCampaign(address nominee, bytes permission) {
		if (campaigns[nominee] == false) {
			DelegateCampaign d = campaigns[nominee];
			d.permissionTarget = permission;
		}
	}

	function voteForNominee(address nominee) {
		DelegateCampaign d = campaigns[nominee];
		DelegateVoter v = voterList[msg.sender];
		if (v.voteStatus[d.permissionTarget]) {
			DelegateCampaign c = campaigns[v.voteAddresses[d.permissionTarget]];
			c.votes -= shares[msg.sender] 
		}
		d.votes += shares[msg.sender];
		v.voteStatus[d.permissionTarget] = true;
		v.voteAddresses[d.permissionTarget] = nominee;
	}

	function primeNominee(address nominee) {
		DelegateCampaign d = campaigns[nominee];
		DelegateCampaign incumbent = campaigns[permission[d.permissionTarget]];
		if (d.votes > incumbent.votes && d.primed = false) {
			d.primed = true;
			d.primingBlock = block.number;
		}

	}

	function cancelPriming(address nominee) {
		DelegateCampaign d = campaigns[nominee];
		DelegateCampaign incumbent = campaigns[permission[d.permissionTarget]];
		if (incumbent.votes > d.votes) {
			d.primed = false;
		}
	}

	function executeDelegation(address nominee) {
		DelegateCampaign d = nominee;
		if (d.primed == true && block.number > d.primingBlock + primingDelay) {
			permission[d.permissionTarget] = nominee;
			d.primed = false; 
		}

	}


	
}