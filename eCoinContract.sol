contract DepositableContract {
    function contractDepositor(address sender, uint amount) returns(bool success) {}
}

contract eCoin {

    /* using the pegged coin */

    /* this variable is the balance of the pegged coin,
       divided into millionths of units */
    mapping (address => uint) balance;

    /* send coin balance to other users or owned contracts */
    function coinTransfer(address receiver, uint amount) {
        if (balance[msg.sender] >= amount) {
            balance[msg.sender] -= amount;
            balance[receiver] += amount;
        }
    }

    /* deposit coin to contract with user balances */
    function depositToContract(address receiver, uint amount) {
        DepositableContract cont = DepositableContract(receiver);
        if (balance[msg.sender] >= amount &&
                cont.contractDepositor(msg.sender,amount)) {
            balance[msg.sender] -= amount;
            balance[receiver] += amount;
        }
    }

    /* issuing the pegged coin and covering positions */

    /* free ether collateral (fEthColl) is a balance of ether that is
       not locked up as collateral and can be freely deposited,
       withdrawn and sent to other accounts */
    mapping (address => uint) fEthColl;

    /* deposit ether to the contract */
    function depositEther() {
        fEfCthColl[msg.sender] += msg.value;
    }

    /* withdraw ether from the contract */
    function withdrawEther(uint withdrawAmountInWei) {
        if (fEthColl[msg.sender] >= withdrawAmountInWei) {
            fEthColl[msg.sender] -= withdrawAmountInWei;
            msg.sender.send(withdrawAmountInWei);
        }
    }

    /* send ether held in the contract as free collateral to other users */
    function sendFreeCollateral(address receiver, uint amount) {
        if (fEthColl[msg.sender] >= amount) {
            fEthColl[msg.sender] -= amount;
            fEthColl[receiver] += amount;
        }
    }

    /* address of the keeper DAO contract */
    address keeper;

    /* allows the keeper to designate a new keeper contract for upgrade purposes */
    function setKeeper(address newKeeper) {
        if (msg.sender == keeper) {
            keeper = newKeeper;
        }
    }

    /* variable indicating if the peg is holding or not.
       The peg is defined as holding if an open buy order
       exists on an open market that is bidding within at
       least 1% of the price of the underlying asset.
       New pegged coin can only be issued if the peg is holding */
    bool pegStatus;

    /* peg status update function */
    function setPegStatus(bool isPegHolding) {
        if (msg.sender == keeper) {
            pegStatus = isPegHolding;
        }
    }

    /* variable indicating the price of one millionth of the
       coin unit (one microunit), with the price given in wei */
    uint priceFeed;

    /* price feed update function */
    function setFeed(uint priceFeed) {
        if (msg.sender == keeper) {
            priceFeed = priceFeed;
        }
    }

    /* collateral requirement multiplier in percentage for issuing
       new pegged coins. If collReq = 300 then you need to lock up ether
       valued at 3 x the amount of pegged coin you wish to issue */
    uint collReq;

    /* collateral requirement update function */
    function setCollReq(uint newCollReq) {
        if (msg.sender == keeper) {
            collReq = newCollReq;
        }
    }

    /* an issue account is a struct that keeps track of the
       debt and locked collateral (lEthColl) of an issuer */
    struct IssueAccount {
        address account;
        uint lEthColl;
        uint debt;
    }

    /* the issue list assigns a number to each issue
       account to allow for iteration */
    mapping (uint => IssueAccount) issueList;

    /* each issuing address is given an incremented
       number for the issue list */
    mapping (address => uint) issueNum;

    /* keeps track of the total amount of created accounts */
    uint numAccounts;

    /* the total amount of debt that is backed by ether collateral */
    uint ethDebt;

    /* the maximum amount of ether backed debt that can be created */
    uint ethDebtCeiling;

    /* checks to see if the peg is holding, and if it is then
       checks to see if the issuer already has an issue account
       by checking their issueNum. If they have an issueNum then
       their IssueAccount has its debt and lEthColl values updated
       accordingly. If no issue account exists a new one is created
       by incrementing numAccounts */
    function issue(uint issueColl) {
        if (pegStatus && fEthColl[msg.sender] >= issueColl && ethDebt + issueColl < ethDebtCeiling) {
            uint value = issueColl/priceFeed/collReq*100;
            if (issueNum[msg.sender] > 0) {
                IssueAccount a = issueList[issueNum[msg.sender]];
                fEthColl[msg.sender] -= issueColl;
                a.lEthColl += issueColl;
                a.debt += value;
                balance[msg.sender] += value;
                ethDebt += value;
            } else {
                issueNum[msg.sender] = ++numAccounts;
                IssueAccount a = issueList[issueNum[msg.sender]];
                fEthColl[msg.sender] -= issueColl;
                a.account = msg.sender;
                a.lEthColl += issueColl;
                a.debt += value;
                balance[msg.sender] += value;
                ethDebt += value;
            }
        }
    }

    /* covers the issue account position completely if funds are avaiable */
    function cover() {
        IssueAccount a = issueList[issueNum[msg.sender]];
        if (balance[msg.sender] >= a.debt) {
            balance[msg.sender] -= a.debt;
            fEthColl[msg.sender] += a.lEthColl;
            a.lEthColl = 0;
            a.debt = 0;
            ethDebt -= a.debt;
        }
    }

    /* covers a partial amount of the issue account position and
       returns a proportional amount of the locked collateral */
    function partialCover(uint coverAmount) {
        IssueAccount a = issueList[issueNum[msg.sender]];
        if (balance[msg.sender] >= coverAmount
                && a.debt >= coverAmount) {
            fEthColl[msg.sender] += a.lEthColl * coverAmount / a.debt;
            a.lEthColl -= a.lEthColl * coverAmount / a.debt;
            a.debt -= coverAmount;
            balance[msg.sender] -= coverAmount;
            ethDebt -= coverAmount;
        }
    }

    /* the collateral/debt ratio, given in percentage, below which
       an issue account becomes vulnerable to a soft margin call
       (callable only by the keeper, up to 5% penalty) */
    uint forcedCoverRate;

    /* soft margin call ratio update function */
    function setForcedCoverRate(uint newRate) {
        if (msg.sender == keeper) {
            forcedCoverRate = newRate;
        }
    }

    /* forced covers can be performed by the keeper in order to
       maintain liquidity, to protect against a black swan event,
       or to prevent an issue account from being hard called */
    function forcedCover(address calledAccount, uint penalty) {
        IssueAccount a = issueList[issueNum[calledAccount]];
        if (penalty <= 105
                && msg.sender == keeper
                && a.lEthColl / priceFeed < a.debt * forcedCoverRate/100
                && balance[msg.sender] >= a.debt) {
            uint value = penalty/100*a.debt/priceFeed;
            balance[msg.sender] -= a.debt;
            fEthColl[msg.sender] += value;
            fEthColl[calledAccount] += a.lEthColl - value;
            ethDebt -= value;
            a.lEthColl = 0;
            a.debt = 0;
        }
    }

    /* the collateral/debt ratio, given in percentage, below which
       an issue account becomes vulnerable to a hard margin call */
    uint hardCallRate;

    /* hard margin call ratio update function */
    function setHardCallRate(uint newRate) {
        if (msg.sender == keeper) {
            hardCallRate = newRate;
        }
    }

    /* hard margin calls ensure that anyone can profit from resolving the
       debt of an issue account position with a low collateral ratio */
    function hardCall(address calledAccount) {
        IssueAccount a = issueList[issueNum[calledAccount]];
        if (a.lEthColl / priceFeed < a.debt * hardCallRate/100
                && balance[msg.sender] >= a.debt) {
            balance[msg.sender] -= a.debt;
            fEthColl[msg.sender] += a.lEthColl;
            ethDebt -= a.debt;
            a.lEthColl = 0;
            a.debt = 0;
        }
    }

    /* locally callable functions to get the status of a single
       account or all accounts by iterating on issueNum */
    function checkBalance(address owner) returns (uint amount) {
        return balance[owner];
    }

    function checkFreeCollateral(address owner) returns (uint amount) {
        return fEthColl[owner];
    }

    function lockedCollateralByAddress(address owner) returns (uint lockedCollateral) {
        IssueAccount a = issueList[issueNum[owner]];
        return a.lEthColl;
    }

    function debtByAddress(address owner) returns (uint debt) {
        IssueAccount a = issueList[issueNum[owner]];
        return a.debt;
    }

    function getNumAccounts() returns (uint num) {
        return numAccounts;
    }

    function issueNumByAddress(address owner) returns (uint num) {
        return issueNum[owner];
    }

    function addressByIssueNum(uint num) returns (address account) {
        IssueAccount a = issueList[num];
        return a.account;
    }

    function lockedCollateralByIssueNum(uint num) returns (uint lockedCollateral) {
        IssueAccount a = issueList[num];
        return a.lEthColl;
    }

    function debtByIssueNum(uint num) returns (uint debt) {
        IssueAccount a = issueList[num];
        return a.debt;
    }

    function checkPriceFeed() returns (uint feedprice) {
        return priceFeed;
    }

    function checkPegStatus() returns (bool status) {
        return pegStatus;
    }

    /* contract init values */
    function eCoin() {
        pegStatus = true;
        priceFeed = 200000000000;
        collReq = 200;
        forcedCoverRate = 270;
        hardCallRate = 140;
        keeper = msg.sender;
        numAccounts = 0;
    }
}
