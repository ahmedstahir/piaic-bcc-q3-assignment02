// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct AccountHolder
{
    address _address;
    uint _balance;
}

contract CryptoBank
{
    address private ownerAddress;
    bool private isBankStarted;
    event LogString(string);
    event LogAddress(address);
    event LogUint(uint);
    AccountHolder[] private accountHolders;
    
    constructor()
    {
        ownerAddress = msg.sender;
    }
    
    function startBank() payable external ownerOnly startBankEnoughInitialDeposit
    {
        isBankStarted = true;
        emit LogString("Bank started.");
    }
    
    function closeBank() external bankStarted ownerOnly
    {
        isBankStarted = false;
        emit LogString("Bank closed.");
        selfdestruct(payable(ownerAddress));
    }
    
    function openAccount() payable external bankStarted accountDoesNotExist amountMoreThanZero
    {
        require(msg.sender != ownerAddress, "Owner cannot open an account.");
        
        uint bonus;
        
        if (accountHolders.length < 5)
            bonus = 1 ether;
        
        AccountHolder memory newAccount;
        newAccount._address = msg.sender;
        newAccount._balance = msg.value + bonus;
        
        accountHolders.push(newAccount);
        
        emit LogUint(newAccount._balance);
    }
    
    function depositFunds() payable external bankStarted amountMoreThanZero
    {
        AccountHolder storage account = getAccountHolder(msg.sender);

        // account holder already exists
        if (account._address != address(0))
            account._balance += msg.value;
    }
    
    function withdrawFunds(uint amountToWithdraw) external bankStarted accountExists
    {
        AccountHolder storage account = getAccountHolder(msg.sender);
        
        sendFunds(account, amountToWithdraw);
        
        account._balance -= amountToWithdraw;
    }
    
    function getAccountBalance() external view accountExists returns(uint)
    {
        return getAccountHolder(msg.sender)._balance;
    }
    
    function closeAccount() external payable bankStarted accountExists
    {
        for (uint i = 0; i < accountHolders.length; i++)
        {
            if (accountHolders[i]._address == msg.sender)
            {
                if (accountHolders[i]._balance > 0)
                    payable(accountHolders[i]._address).transfer(accountHolders[i]._balance);

                delete accountHolders[i];
                break;
            }
        }
    }
    
    function getTotalBankFunds() external view bankStarted ownerOnly returns(uint)
    {
        return address(this).balance;
    }
    
    function viewAllAccounts() external bankStarted ownerOnly
    {
        for (uint i = 0; i < accountHolders.length; i++)
        {
            emit LogAddress(accountHolders[i]._address);
            emit LogUint(accountHolders[i]._balance);
        }
    }

    modifier ownerOnly
    {
        require(msg.sender == ownerAddress, "Address is not owner's address.");
        _;
    }
    
    modifier bankStarted
    {
        require(isBankStarted, "Bank is not yet started.");
        _;
    }
    
    modifier startBankEnoughInitialDeposit
    {
        require(msg.value >= 50 ether, "Insufficient amount to start bank.");
        _;
    }
    
    modifier amountMoreThanZero
    {
        require(msg.value > 0 ether, "Amount must be more than zero.");
        _;
    }
    
    modifier accountDoesNotExist
    {
        require (!accountHolderExists(msg.sender), "Account already exists.");
        _;
    }
    
    modifier accountExists
    {
        require (accountHolderExists(msg.sender), "Account does not exist.");
        _;
    }
    
    modifier enoughAmountToWithdraw(AccountHolder storage account, uint amountToWithdraw)
    {
        require(amountToWithdraw <= account._balance, "Insufficient funds in your account.");
        _;
    }
    
    function getAccountHolder(address addressToCheck) private view returns(AccountHolder storage)
    {
        AccountHolder storage account = accountHolders[0];
        
        for (uint i = 0; i < accountHolders.length; i++)
        {
            if (accountHolders[i]._address == addressToCheck)
            {
                account = accountHolders[i];
                break;
            }
        }
        
        return account;
    }
    
    function accountHolderExists(address addressToCheck) private view returns(bool)
    {
        bool found;
        
        for (uint i = 0; i < accountHolders.length; i++)
        {
            if (accountHolders[i]._address == addressToCheck)
            {
                found = true;
                break;
            }
        }
        
        return found;
    }
    
    function sendFunds(AccountHolder storage account, uint amountToWithdraw) private enoughAmountToWithdraw(account, amountToWithdraw)
    {
        payable(account._address).transfer(amountToWithdraw);
    }
}
