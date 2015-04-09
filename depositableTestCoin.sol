contract DepositableContract {
	function depositCoin(address sender, uint amount) returns(bool success) {}
}

contract DepositCoin {
	mapping (address => uint) balance;
	function depositToContract (address receiver, uint amount) {
		DepositableContract cont;
		cont = DepositableContract(receiver);
		if (balance[msg.sender] >= amount) {
			cont.depositCoin(msg.sender,amount);
			balance[msg.sender] -= amount;
			balance[receiver] += amount;
		}
	}
	function DepositCoin {
		balance[msg.sender] = 1000;
	}
}