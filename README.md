# BTL Token smart contracts

*	_Standard_ : [ERC20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)
* _[Name](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#name)_ : Bital Token
*	_[Ticker](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#symbol)_ : BTL
*	_[Decimals](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#decimals)_ : 18
*	_Crowdsales_ : 1

## Smart-contracts description

Initial supply, 250 000 000 tokens are minted at deploying of contract. Additional minting is available untill 1 000 000 000 emission of tokens is reached.
There is not possible to transfer any tokens until “release” function is called, except Admins, who can transfer tokens any time.
Crowdsale defines: minimum amount of investment, endtime, whitelist, hardcap, bonus percent. There is reserving system which accumulates “reserveLimit” to Exchange contract, so approved accounts can exchange their tokens to ETH after reserveLimit is reached.
Token price defines in USD, so Admins should provide current price by calling setETHPrice or via PriceProvider.
Admins can modify every contract variables, so for current information see “Read Contract”.

### Contracts contains

1.	BTLToken
2.	CrowdSale
3.	Exchange
4.	PriceProvider

### How to manage contract

To start working with contract you should follow next steps:
1.	Compile it in Remix with enabled optimization flag and compiler 0.5.7
2.	Deploy bytecode with MyEtherWallet or with Metamask extension in Remix.

First, Token contract.
Second, Crowdsale. To activate crowdsale one needs to call “setCrowdsale” function at Token contract.
Third, Exchange. To activate exchange one needs to call “setExchangeAddr” function at Crowdsale contract and “registerContract” at Token.
Do not forget that only Admins and unlocked wallets can transfer BTL, when tokens are not released. To start presale you need to send tokens to presale address and make it to be transfer agent.
To allow address change eth/usd rate you need to make address (wallet or contract) be Provider by calling setPriceProvider.

### How to invest

To purchase tokens investor should send ETH to corresponding crowdsale contract. If whitelist is activated only enlisted wallets are allowed to purchase tokens.

### Wallets with ERC20 support

1.	MyEtherWallet - https://www.myetherwallet.com/
2.	Parity
3.	Mist/Ethereum wallet
4.	Metamask

EXODUS not support ERC20, but have way to export key into MyEtherWallet - http://support.exodus.io/article/128-how-do-i-receive-unsupported-erc20-tokens
Investor must not use other wallets, coinmarkets or stocks. Can lose money.

## Ropsten network configuration

### Links

1. BTLToken - https://ropsten.etherscan.io/address/0xd2139363ab97172691b2faf0681df734c9dc0a9f
2. Crowdsale - https://ropsten.etherscan.io/address/0xa1e18794af4f293282192161d90de18c7c07df81
3. Exchange - https://ropsten.etherscan.io/address/0xd409ff26e76b4d3268e7e283f5f853743ecb4627

### Crowdsale

Address = 0x53f76de718e865caf4081c3b31e271d4881cb7da

Rate = 40 000000000000000000

InitialETHPrice = 25000

Decimals = 2

Wallet = 0xd9696d997a1eec755c3afc119f34a9323231771f

TeamAddr = 0x04FFCd14fa3544dB6c34Ca966Be1DEB5ECdF89b6

Exchange = 0xd409ff26e76b4d3268e7e283f5f853743ecb4627

EndTime = 1560124800 (10 Juny 2019, 0:00 UTC)

HardCap = 10000 000000000000000000

Minimum = 50000000000000000

ReserveLimit = 100

ReserveTrigger = 1500 000000000000000000

#### Purchasers

* 0.1 ETH => rejected txn, address is not whitelisted https://ropsten.etherscan.io/tx/0x9b84b7d0d9cb28a73e39fba1188a679b518550bc92242a35b23e31a80190e752

* Add an account to whitelist https://ropsten.etherscan.io/tx/0x8fab0864f699e52741a8a351b56a9def469a885bebbb1c2aca2252bb5394d97e

* 0.1 ETH => 1,000 tokens https://ropsten.etherscan.io/tx/0xe98f68b24eb1bae70403bc15967e4ca6add158820374ef168778655780356094

* 0.1 ETH => 1,000 tokens, 0.05 ETH reserved https://ropsten.etherscan.io/tx/0x4a3811483809ad221911f72cc46b7a77633c381a794ba6423ea61d419636357f

* 0.3 ETH => 3,000 tokens https://ropsten.etherscan.io/tx/0x4a3811483809ad221911f72cc46b7a77633c381a794ba6423ea61d419636357f

* ETHPrice changed from $200 to $300 https://ropsten.etherscan.io/tx/0x4a3811483809ad221911f72cc46b7a77633c381a794ba6423ea61d419636357f

* Exchange of 1000 tokens => reverted, refund hasn’t started yet https://ropsten.etherscan.io/tx/0x8b8c84254937d5624dcd1744bb1c2a5eb6840dfc41658c488d07e7154718f304

* 0.1 ETH => 3,600 tokens https://ropsten.etherscan.io/tx/0x401b572a28c6c1029809a78f24116302b528fed3619686ae66a61bd43ac3699a

* Exchange of 1000 tokens => reverted, address is not a participant of private sale https://ropsten.etherscan.io/tx/0x2d05c5c4b8d796029d117056fc59c18e3ee1a40debf63d4851d218277446bcf9

* Adding an address to private sale https://ropsten.etherscan.io/tx/0x997b16db6b1cad81031da608cad2f3ab16e771bdbd9b782aeae612b539005d87

* Exchange of 1000 tokens => 0.23 ETH https://ropsten.etherscan.io/tx/0x26218ee26a7344cf11f3ad49f36b262f17fb4c3a91fee192463e014094979f5f

* 0.5 ETH => remaining tokens, ETH change is given back, because hardcap is already reached https://ropsten.etherscan.io/tx/0xa7640e0d3debc4bf32f0124771f82cfd96be7d20e453cbce8e788b60dafad4a4

* 0.1 ETH +> reverted, hardcap is reached https://ropsten.etherscan.io/tx/0xbd9f97f30b27948f4e61176e50ab9a159951550a56db5bd53c57214839ac0fa4

* Token transfer => reverted, crowdsale is not finished yet https://ropsten.etherscan.io/tx/ 0x22f3b9bf51874c322e8625b6372978de093c50c8962c06b152fa890ebedf80c9

* FinishSale https://ropsten.etherscan.io/tx/0xe5d968babc7196889432ce75cae76c144894b27a1421826630c5c5c3493a9ef9

* Token transfer => success, all tokens are released https://ropsten.etherscan.io/tx/0xa0517246de5e4334e14d8d9d0c4aa1f446e0eab3e8df1a05bd6b67218d181bc1

* Token transfer => reverted, team address is locked for 1 year https://ropsten.etherscan.io/tx/0x22f3b9bf51874c322e8625b6372978de093c50c8962c06b152fa890ebedf80c9
