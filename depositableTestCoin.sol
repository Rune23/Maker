contract DepositableContract {
    function contractDepositor(address sender, uint amount) returns(bool success) {}
}

contract TestCoin {
    mapping (address => uint) balance;
    function coinTransfer(address receiver, uint amount) {
        if (balance[msg.sender] >= amount) {
            balance[msg.sender] -= amount;
            balance[receiver] += amount;
        }
    }
    function depositToContract (address receiver, uint amount) {
        DepositableContract cont;
        cont = DepositableContract(receiver);
        if (balance[msg.sender] >= amount) {
            bool succ;
            succ = cont.contractDepositor(msg.sender,amount);
            if (succ) {
                balance[msg.sender] -= amount;
                balance[receiver] += amount;
            }
        }
    }
    function TestCoin() {
        balance[msg.sender] = 1000;
    }
}
