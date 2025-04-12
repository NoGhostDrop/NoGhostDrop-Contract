// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct AirdropInfo {
    address creator; // 생성자
    uint256 totalAmount; // 에어드랍 총량
    uint256 totalClaims; // 클레임 총량
    mapping(address => bool) claimed; // 중복 확인용
}

contract Airdrop {
    mapping (address => AirdropInfo) airdrops;
    address relayer;

    event Claimed(address indexed token, address indexed user, uint256 amount);

    modifier onlyRelayer() {
        require(relayer == msg.sender, "Not a valid relayer");
        _;
    }

    constructor(address _relayer) {
        relayer = _relayer; // 관리자 주소
    }

    
    function createAirdrop(
        address token,
        uint256 amount
    ) external payable {
        require(msg.value > 0, "Value must be greater than 0");
        payable(relayer).transfer(msg.value);

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        AirdropInfo storage airdrop = airdrops[token];

        if (airdrop.creator == address(0)) {
            airdrop.creator = msg.sender;
            airdrop.totalClaims = 0;
            airdrop.totalAmount = amount;
        } else {
            require(airdrop.creator == msg.sender, "Only original creator can top up");
            airdrop.totalAmount += amount;
        }
    }

    function claim(address token, address to, uint256 amount) external onlyRelayer() {
        AirdropInfo storage airdrop = airdrops[token];
        require(!airdrop.claimed[to], "Already claimed");
        require(airdrop.totalClaims + amount <= airdrop.totalAmount, "Out of tokens");

        airdrop.claimed[to] = true;
        airdrop.totalClaims += amount;

        IERC20(token).transfer(to, amount);

        emit Claimed(token, to, amount);
    }

    function getAirdropInfo(address token) external view returns (
        address creator,
        uint256 totalAmount,
        uint256 totalClaims
    ) {
        AirdropInfo storage airdrop = airdrops[token];
        return (
            airdrop.creator,
            airdrop.totalAmount,
            airdrop.totalClaims
        );
    }

    function withdraw(address token) external {
        AirdropInfo storage airdrop = airdrops[token];
        require(msg.sender == airdrop.creator, "Only creator can withdraw");

        uint256 remaining = airdrop.totalAmount - airdrop.totalClaims;
        require(remaining > 0, "No tokens to withdraw");

        airdrop.totalAmount = airdrop.totalClaims; // 더 이상 withdraw 못하게

        IERC20(token).transfer(msg.sender, remaining);
    }
}