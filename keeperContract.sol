contract FeedSource {
	function getFeed() returns (uint priceFeed) {}
	function getPeg() returns (bool pegFeed) {}
}

contract Keeper {
	
	mapping (address => uint) shares;

	function cointransfer(address receiver, uint amount) {
		if (shares[msg.sender] >= amount) {
			DelegateVoter v = voterList[msg.sender]
			if (v.votingStatus["setkeeper"]) {
				DelegateCampaign c = campaigns[v.voteAddresses["setKeeper"]];
				c.votes -= shares[msg.sender];
				v.votingStatus = false;
			}
			shares[msg.sender] -= amount;
			shares[receiver] += amount;
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
		if (permission[msg.sender] = "setforcedcoverrate") {
			dlr.setForcedCoverRate(newRate);
		}
	}


	function delegateSetHardCallRate(uint newRate) {
		if (permission[msg.sender] = "sethardcallrate") {
			dlr.setHardCallRate(newRate);
		}
	}

	function delegateSetFeedSource(address newFeed) {
		if (permission[msg.sender] = "setfeedsource") {
			feedSourceAddr = newFeed;
		}
	}

	function delegateWithDrawEther(address receiver, uint amount) {
		if (permission[msg.sender] = "withdrawether") {
			receiver.send(amount);
		}
	}
	function delegateWithDrawEDollar(address receiver, uint amount) {
		if (permission[msg.sender] = "withdrawedollar") {
			dlr.coinTransfer(receiver, amount);
		}
	}

	function delegateForcedCover(address calledAccount, uint modifier) {
		if (permission[msg.sender] = "forcedcover") {
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