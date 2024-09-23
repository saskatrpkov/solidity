// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;


contract Auction {
    address payable public beneficiray;
    uint public auctionEndTime;
    string private secretMessage;
    address public highestBidder;
    uint public highestBid;

    mapping (address=>uint) pendingReturns;
    bool isEnded;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint biddingTime, address payable beneficirayAddress, string memory secret) {
        beneficiray=beneficirayAddress;
        auctionEndTime=block.timestamp+biddingTime;
        secretMessage=secret;
    }

    function bid() external payable {
        if(isEnded){
            revert("Aukcija se zavrsila");
        }

        if(msg.value<=highestBid){
            revert("Trenutno postoji veca ponuda");
        }

        if(highestBid!=0){
            pendingReturns[highestBidder]+=highestBid;
        }   

        highestBid=msg.value;
        highestBidder=msg.sender;

        emit HighestBidIncreased(msg.sender, msg.value);
        
    }

    function withdraw() external returns (bool){
        uint amount=pendingReturns[msg.sender];
        if(amount>0){
            pendingReturns[msg.sender]=0;
            bool isTransactionSuccessful=payable(msg.sender).send(amount);
            if(!isTransactionSuccessful){
                pendingReturns[msg.sender]=amount;
                return false;
            }
        }
        return true;
    }

    function getSecretMessage() external view returns (string memory){
        require(isEnded,"Aukcija se jos uvek nije zavrsila");
        require(msg.sender==highestBidder,"Samo pobednik moze da dobije tajnu poruku");
        return secretMessage;
    }

    function auctionEnd() external {
        if(block.timestamp<auctionEndTime){
            revert("Aukcija jos uvek traje");
        }
        if(isEnded){
            revert("Auckija se vec zavrsila");
        }
        isEnded=true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiray.transfer(highestBid);
    }

}