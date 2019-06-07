BTL Token smart contracts
•	Standard : ERC20
•	Name : Bital Token
•	Ticker : BTL
•	Decimals : 18
•	Crowdsales : 1
Smart-contracts description
Initial supply, 250 000 000 tokens are minted at deploying of contract. Additional minting is available untill 1 000 000 000 emission of tokens is reached.
There is not possible to transfer any tokens until “release” function is called, except Admins, who can transfer tokens any time.
Crowdsale defines: minimum amount of investment, endtime, whitelist, hardcap, bonus percent. There is reserving system which accumulates “reserveLimit” to Exchange contract, so approved accounts can exchange their tokens to ETH after reserveLimit is reached.
Token price defines in USD, so Admins should provide current price by calling setETHPrice or via PriceProvider.
Admins can modify every contract variables, so for current information see “Read Contract”.
Contracts contains
1.	BTLToken
2.	CrowdSale
3.	Exchange
4.	PriceProvider
How to manage contract
To start working with contract you should follow next steps:
1.	Compile it in Remix with enabled optimization flag and compiler 0.5.7
2.	Deploy bytecode with MyEtherWallet or with Metamask extension in Remix.
First, Token contract.
Second, Crowdsale. To activate crowdsale one needs to call “setCrowdsale” function at Token contract.
Third, Exchange. To activate exchange one needs to call “setExchangeAddr” function at Crowdsale contract and “registerContract” at Token.
Do not forget that only Admins and unlocked wallets can transfer BTL, when tokens are not released. To start presale you need to send tokens to presale address and make it to be transfer agent.
To allow address change eth/usd rate you need to make address (wallet or contract) be Provider by calling setPriceProvider.
How to invest
To purchase tokens investor should send ETH to corresponding crowdsale contract. If whitelist is activated only enlisted wallets are allowed to purchase tokens.
Wallets with ERC20 support
1.	MyEtherWallet - https://www.myetherwallet.com/
2.	Parity
3.	Mist/Ethereum wallet
4.	Metamask
EXODUS not support ERC20, but have way to export key into MyEtherWallet - http://support.exodus.io/article/128-how-do-i-receive-unsupported-erc20-tokens
Investor must not use other wallets, coinmarkets or stocks. Can lose money.
