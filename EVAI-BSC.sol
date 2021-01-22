// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

//--------------------------------------
//  EVAI contract
//
// Symbol      : EV
// Name        : EVAI
// Total supply: 1000000000
// Decimals    : 8
//--------------------------------------

abstract contract ERC20Interface {
    function balanceOf(address tokenOwner)
        external
        view
        virtual
        returns (uint256);

    function allowance(address tokenOwner, address spender)
        external
        view
        virtual
        returns (uint256);

    function transfer(address to, uint256 tokens)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 tokens)
        external
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external virtual returns (bool);

    function burn(uint256 tokens) external virtual returns (bool success);

    function operationProfit(uint256 _profit) external virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Burn(address from, address, uint256 value);
    event Profit(address from, uint256 profit, uint256 totalProfit);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
        return c;
    }
}

contract Evaitoken is ERC20Interface, SafeMath {
    uint256 public immutable initialSupply;
    uint256 public totalSupply;
    uint256 public totalProfit;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint8 public constant decimals = 8;
    address public owner;
    address public newOwner = address(0);
    string public constant name = "EVAI";
    string public constant symbol = "Ev";

    event OwnerProposed(address newOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        totalSupply = initialSupply = 1000000000 * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This is not an owner");
        _;
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool)
    {
        require(spender != address(0), "Approve from the zero address");
        require(
            (tokens == 0) || (allowed[msg.sender][spender] == 0),
            "To Prevent Race condition"
        );
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        allowed[msg.sender][spender] = safeAdd(
            allowed[msg.sender][spender],
            addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        allowed[msg.sender][spender] = safeSub(
            allowed[msg.sender][spender],
            subtractedValue
        );
        return true;
    }

    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool)
    {
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool) {
        require(from != address(0), "TransferFrom from the zero address");
        require(to != address(0), "TransferFrom to the zero address");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function operationProfit(uint256 _profit)
        external
        override
        onlyOwner
        returns (bool)
    {
        totalProfit = safeAdd(totalProfit, _profit);
        emit Profit(msg.sender, _profit, totalProfit);
        return true;
    }

    function burn(uint256 tokens) external override onlyOwner returns (bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        totalSupply = safeSub(totalSupply, tokens);
        emit Burn(msg.sender, address(0), tokens);
        return true;
    }

    function proposeOwner(address proposedOwner)
        public
        onlyOwner
        returns (bool)
    {
        require(
            proposedOwner != address(0) &&
                proposedOwner != owner &&
                proposedOwner == address(proposedOwner),
            "proposedOwner is not valid"
        );
        emit OwnerProposed(proposedOwner);
        newOwner = proposedOwner;
        return true;
    }

    function setOwner() public returns (bool) {
        require(
                newOwner == msg.sender,
            "Function should be called by valid proposed owner"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = msg.sender;
        newOwner = address(0);
        return true;
    }
}