contract DepositorCoin {
	function sendCoin(address receiver, uint amount) {
      }
}

contract DepositableContract {
	address depositorCoinAddr;
	mapping (address => uint) balance;
	function contractDepositor(address sender, uint amount) returns(bool success) {
		if (msg.sender == depositorCoinAddr) {
			balance[sender] += amount;
			return true;
		}
	}
	function withdrawCoin(address receiver, uint amount) {
		if (balance[msg.sender] >= amount) {
			DepositorCoin coinInstance;
			coinInstance = DepositorCoin(depositorCoinAddr);
			coinInstance.coinTransfer(receiver, amount);
			balance[msg.sender] -= amount;
		}
	}
	function DepositableContract() {
		depositedCoinAddr = 0x5d7010d9955e5eeebaf4405584a86ca684c56d11;
	}
}