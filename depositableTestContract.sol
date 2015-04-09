contract DepositedCoin {
	function sendCoin(address receiver, uint amount) {
      }
}

contract DepositableContract {
	address depositedCoinAddr;
	mapping (address => uint) balance;
	function depositCoin(address sender, uint amount) returns(bool success) {
		if (msg.sender == depositedCoinAddr) {
			balance[sender] += amount;
			return true;
		}
	}
	function withdrawCoin(address receiver, uint amount) {
		if (balance[msg.sender] >= amount) {
			DepositedCoin coinInstance;
			coinInstance = DepositedCoin(depositedCoinAddr);
			coinInstance.sendCoin(receiver, amount);
			balance[msg.sender] -= amount;
		}
	}
	function DepositableContract() {
		depositedCoinAddr = 0x5d7010d9955e5eeebaf4405584a86ca684c56d11;
	}
}

3579a85e… :withdrawCoin