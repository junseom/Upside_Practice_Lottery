// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
        address public owner;
        uint256 constant price = 0.1 ether;

        uint public startTimestamp;
        uint16 public winningNumber;
        address[] public participants;
        address[] public winners;
        bool public isClaimed;
        uint256 public prize;

        mapping(uint16 => address[]) public guesses;

        constructor() {
            startTimestamp = block.timestamp;
        }

        function generateWinningNumber(bytes memory _seed) public {
            require(msg.sender == owner, "Owner only");

            bytes32 hash = keccak256(abi.encodePacked(_seed, winningNumber));
            winningNumber = uint16(uint256(hash));
        }

        function buy(uint16 _guess) public payable {
            require(block.timestamp < startTimestamp + 24 hours, "Sell phase only");
            require(msg.value == price, "Insufficient fund");

            for (uint256 i = 0; i < participants.length; i++) {
                require(participants[i] != msg.sender, "Duplicated");
            }
            
            participants.push(msg.sender);
            guesses[_guess].push(msg.sender);
        }

        function draw() public {
            require(block.timestamp >= startTimestamp + 24 hours, "Still sell phase");
            require(!isClaimed, "Already claim phase");

            bytes32 hash = keccak256(abi.encodePacked(block.timestamp, winningNumber));
            winningNumber = uint16(uint256(hash));

            winners = guesses[winningNumber];
            
            if (winners.length > 0) {
                prize = address(this).balance / winners.length;
            } else {
                prize = 0;
            }
        }

        function claim() public {
            require(block.timestamp >= startTimestamp + 24 hours, "Still sell phase");
            
            isClaimed = true;

            if (prize > 0) {
                for (uint i = 0; i < winners.length; i++) {
                    if (msg.sender == winners[i]) {
                        (bool success, ) = msg.sender.call{value: prize}("");
                        require(success, "Transfer faild");
                        break;
                    }
                }
            } else {
                isClaimed = false;
                startTimestamp += 24 hours;
                delete participants;
            }
        }

}  