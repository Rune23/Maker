contract eCoin {

      /* using the pegged coin */

      /* this variable is the balance of the pegged coin, divided into millionths of units */
      mapping (address => uint) balance;

      /* send coin balance to other users */
      function sendCoin(address receiver, uint amount) {
            if (balance[msg.sender] >= amount) {
                  balance[msg.sender] -= amount;
                  balance[receiver] += amount;
            }
      }

      /* issuing the pegged coin and covering positions */

      /* free collateral (fColl) is a balance of ether that is not locked up as collateral and can be freely deposited, withdrawn and sent to other accounts */
      mapping (address => uint) fColl;

      /* deposit ether to the contract */
      function depositEther () {
            fColl[msg.sender] += msg.value;
      }

      /* withdraw ether from the contract */
      function withdrawEther (uint withdrawAmountInWei) {
            if (fColl[msg.sender] >= withdrawAmountInWei) {
                  fColl[msg.sender] -= withdrawAmountInWei;
                  msg.sender.send(withdrawAmountInWei);
            }
      }

      /* send ether held in the contract as free collateral to other users */
      function sendFreeCollateral(address receiver, uint amount) {
            if (fColl[msg.sender] >= amount) {
                  fColl[msg.sender] -= amount;
                  fColl[receiver] += amount;
            }
      }

      /* address of the guardian DAO contract */
      address guardian;

      /* allows the guardian to designate a new guardian contract for upgrade purposes */
      function setGuardian (address newGuardian) {
            if (msg.sender == guardian) {
                  guardian = newGuardian;
            }
      }

      /* variable indicating if the peg is holding or not. The peg is defined as holding if an open buy order exists on an open market
       that is bidding within at least 1% of the price of the underlying asset. New pegged coin can only be issued if the peg is holding */
      bool pegStatus;

      /* peg status update function */
      function setPegStatus (bool isPegHolding) {
            if (msg.sender == guardian) {
                  pegStatus = isPegHolding;
            }
      }

      /* variable indicating the price of one millionth of the coin unit (one microunit), with the price given in wei */
      uint priceFeed;

      /* price feed update function */
      function setFeed (uint priceFeed) {
            if (msg.sender == guardian) {
                  priceFeed = priceFeed;
            }
      }

      /* collateral requirement multiplier in percentage for issuing new pegged coins. If collReq = 300 then you need to lock up ether
       valued at 3 x the amount of pegged coin you wish to issue */
      uint collReq;

      /* collateral requirement update function */
      function setCollReq (uint newCollReq) {
            if (msg.sender == guardian) {
                  collReq = newCollReq;
            }
      }

      /* an issue account is a struct that keeps track of the debt and locked collateral (lColl) of an issuer */
      struct IssueAccount {
            address account;
            uint lColl;
            uint debt;
      }

      /* the issue list assigns a number to each issue account to allow for iteration */
      mapping (uint => IssueAccount) issueList;

      /* each issuing address is given an incremented number for the issue list */
      mapping (address => uint) issueNum;

      /* keeps track of the total amount of created accounts */
      uint numAccounts;

      /* checks to see if the peg is holding, and if it is then checks to see if the issuer already has an issue account by checking their issueNum. If they have an
      issueNum then their IssueAccount has its debt and lColl values updated accordingly. If no issue account exists a new one is created by incrementing 
      numAccounts */
      function issue (uint issueColl) {
            if (pegStatus == true) {
                  if (fColl[msg.sender] >= issueColl) {
                        if (issueNum[msg.sender] > 0) {
                              IssueAccount a = issueList[issueNum[msg.sender]];
                              fColl[msg.sender] -= issueColl;
                              a.lColl += issueColl;
                              a.debt += issueColl/priceFeed/collReq*100;
                              balance[msg.sender] += issueColl/priceFeed/collReq*100;
                        } else {
                              issueNum[msg.sender] = numAccounts ++;
                              IssueAccount b = issueList[issueNum[msg.sender]];
                              fColl[msg.sender] -= issueColl;
                              b.account = msg.sender;
                              b.lColl += issueColl;
                              b.debt += issueColl/priceFeed/collReq*100;
                              balance[msg.sender] += issueColl/priceFeed/collReq*100;
                        }
                  }
            }
      }

      /* covers the issue account position completely if funds are avaiable */
      function cover () {
            IssueAccount a = issueList[issueNum[msg.sender]];
            if (balance[msg.sender] >= a.debt) {
                  balance[msg.sender] -= a.debt;
                  fColl[msg.sender] += a.lColl;
                  a.lColl = 0;
                  a.debt = 0;
            }
      }

      /* covers a partial amount of the issue account position and returns a proportional amount of the locked collateral */
      function partialCover (uint coverAmount) {
            IssueAccount a = issueList[issueNum[msg.sender]];
            if (balance[msg.sender] >= coverAmount) {
                  if (a.debt >= coverAmount) {
                        fColl[msg.sender] += a.lColl * coverAmount / a.debt;
                        a.lColl -= a.lColl * coverAmount / a.debt;
                        a.debt -= coverAmount;
                        balance[msg.sender] -= coverAmount;
                  }
            }
      }

      /* enables the guardian to force positions to cover at the price feed for liquidity purposes */
      function forcedCover (address targetAccount) {
            IssueAccount a = issueList[issueNum[targetAccount]];
            if (msg.sender == guardian) {
                  if (balance[msg.sender] >= a.debt) {
                        balance[msg.sender] -= a.debt;
                        fColl[msg.sender] += a.debt/priceFeed;
                        fColl[targetAccount] += a.lColl - a.debt/priceFeed;
                        a.lColl = 0;
                        a.debt = 0;
                  }
            }
      }

      /* the collateral/debt ratio, given in percentage, below which an issue account becomes vulnerable to a soft margin call
       (callable only by the guardian DAO, up to 5% penalty) */
      uint softCallRate;

      /* soft margin call ratio update function */
      function setSoftCallRate (uint newRate) {
            if (msg.sender == guardian) {
                  softCallRate = newRate;
            }
      }

      /* a soft margin call, done by the guardian DAO in periods of medium to high risk of a black swan event, and to protect issue accounts from hard margin calls */
      function softCall (address calledAccount, uint penalty) {
            IssueAccount a = issueList[issueNum[calledAccount]];
            if (penalty <= 105){
                  if (msg.sender == guardian) {
                        if (a.lColl / priceFeed < a.debt * softCallRate/100) {
                              if (balance[msg.sender] >= a.debt) {      
                                    balance[msg.sender] -= a.debt;
                                    fColl[msg.sender] += penalty/100*a.debt/priceFeed;
                                    fColl[calledAccount] += a.lColl - penalty/100*a.debt/priceFeed;
                                    a.lColl = 0;
                                    a.debt = 0;      
                              }
                        }
                  }
            }
      }

      /* the collateral/debt ratio, given in percentage, below which an issue account becomes vulnerable to a hard margin call
       (callable by anyone, 10% penalty) */
      uint hardCallRate;

      /* hard margin call ratio update function */
      function setHardCallRate (uint newRate) {
            if (msg.sender == guardian) {
                  hardCallRate = newRate;
            }
      }

      /* hard margin calls ensure that anyone can profit from resolving the debt of an issue account position with a low collateral ratio */
      function hardCall (address calledAccount) {
            IssueAccount a = issueList[issueNum[calledAccount]];    
            if (a.lColl / priceFeed < a.debt * hardCallRate/100) {
                  if (balance[msg.sender] >= a.debt) {      
                        balance[msg.sender] -= a.debt;
                        fColl[msg.sender] += 110/100*a.debt/priceFeed;
                        fColl[calledAccount] += a.lColl - 110/100*a.debt/priceFeed;
                        a.lColl = 0;
                        a.debt = 0;      
                  }
            }   
      }

      /* locally callable functions to get the status of a single account or all accounts by iterating on issueNum */

      function checkBalance(address owner) returns (uint amount) {
            return balance[owner];
      }

      function checkFreeCollateral(address owner) returns (uint amount) {
            return fColl[owner];
      }

      function lockedCollateralByAddress (address owner) returns (uint lockedCollateral) {
            IssueAccount a = issueList[issueNum[owner]];
            return a.lColl;
      }

      function debtByAddress (address owner) returns (uint debt) {
            IssueAccount a = issueList[issueNum[owner]];
            return a.debt;
      }

      function getNumAccounts () returns (uint num) {
            return numAccounts;
      }

      function issueNumByAddress (address owner) returns (uint num) {
            return issueNum[owner];
      }

      function addressByIssueNum (uint num) returns (address account) {
            IssueAccount a = issueList[num];
            return a.account;
      }

      function lockedCollateralByIssueNum (uint num) returns (uint lockedCollateral) {
            IssueAccount a = issueList[num];
            return a.lColl;
      }

      function debtByIssueNum (uint num) returns (uint debt) {
            IssueAccount a = issueList[num];
            return a.debt;
      }

      function checkPriceFeed() returns (uint feedprice) {
            return priceFeed;
      }

      function checkPegStatus () returns (bool status) {
            return pegStatus;
      }

      /* contract init values */
      function eCoin() {
            pegStatus = true;
            priceFeed = 200000000000;
            collReq = 300;
            softCallRate = 200;
            hardCallRate = 150;
            guardian = msg.sender;
            numAccounts = 1;
      }
}