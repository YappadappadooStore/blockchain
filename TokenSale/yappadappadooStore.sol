/*
    This contract represents work in progress on implementation of beta yappadappadooStore API specifications.
    It will be extended with a number of new features and existing logic will be thoroughly revised & tested.
*/

pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;

import "./yappadappadoo.sol";

contract yappadappadooStore is SafeMath {
    
    struct Config {
        uint currentChange;
        uint yappadappadooComission;
    }
    
    struct Item {
        bytes16 itemId;
        address itemOwnerWallet;
        uint unitPriceInUSD;
    }
    
    struct Purchase {
        uint256 date;
        bytes16 itemId;
        uint units;
        uint unitPriceInFLI;
        uint unitPriceInETH;
        bytes encryptedTaxInformation;
    }
    
    struct Vote {
        uint256 date;
        bytes16 voteId;
        bytes16 itemId;
        address voter;
        uint voteValue;
        string voteText;
        bool blocked;
    }
    
    Config config;
    mapping(bytes16 => Item) items;
    mapping(bytes16 => Purchase[]) itemPurchases;
    mapping(bytes16 => Vote) votes;
    mapping(bytes16 => Vote[]) itemVotes;
    mapping(address => Vote[]) voterVotes;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    function itemPurchase(bytes16 itemId, uint units, uint price, bytes encryptedTaxInfo) public returns (bool success) {
        if (items[itemId].itemOwnerWallet == address(0)) return false;
        if (safeMul(units, safeMul(items[itemId].unitPriceInUSD, config.currentChange)) != price) return false;
        
        FlintToken(0xEB1e2c19bd833b7f33F9bd0325B74802DF187935 /* token contract address here */).transferFrom(msg.sender, items[itemId].itemOwnerWallet, safeSub(price, config.yappadappadooComission));
        FlintToken(0xEB1e2c19bd833b7f33F9bd0325B74802DF187935 /* token contract address here */).transferFrom(msg.sender, owner, config.yappadappadooComission);
        
        itemPurchases[itemId].push(Purchase({date: now, 
                                            itemId: itemId, 
                                            units: units, 
                                            unitPriceInFLI: safeMul(items[itemId].unitPriceInUSD, config.currentChange), 
                                            unitPriceInETH: 0, // not sure about this, exchange rate will be floating and not known
                                            encryptedTaxInformation: encryptedTaxInfo}));
    }

    function updateItem(bytes16 itemId, uint unitPriceInUSD) public {
        items[itemId] = Item({itemId: itemId, itemOwnerWallet: msg.sender, unitPriceInUSD : unitPriceInUSD});
    }

    function getPurchasesOfItem(bytes16 itemId) public view returns (Purchase[]) {
        return itemPurchases[itemId];
    }

    function getPurchasesByDate(bytes16[] list, uint256 fromDate, uint256 toDate) public view returns (Purchase[100] result, uint count) {
        for (uint i = 0; i < list.length; i++) {
            for (uint j = 0; j < itemPurchases[list[i]].length; j++) {
                if (count < 100 && itemPurchases[list[i]][j].date >= fromDate && itemPurchases[list[i]][j].date <= toDate) {
                    result[count] = itemPurchases[list[i]][j];
                    count++;
                }
            }
        }
    }

    function updateConfig(Config c) public {
        require (msg.sender == owner);
        config = c;
    }

    function vote(Vote v) public payable returns (bool success) {
        if (items[v.itemId].itemOwnerWallet == address(0)) return false;
        
        for (uint i = 0; i < voterVotes[msg.sender].length; i++) {
            if (voterVotes[msg.sender][i].itemId == v.itemId) {
               return false; 
            }
        }
        
        voterVotes[msg.sender].push(v);
        itemVotes[v.itemId].push(v);
        
        if (msg.value > 0) items[v.itemId].itemOwnerWallet.transfer(msg.value);
    }

    function blockVote(bytes16 voteId) public {
        require (msg.sender == owner);
        votes[voteId].blocked = true;
    }
    
    function unblockVote(bytes16 voteId) public {
        require (msg.sender == owner);
        votes[voteId].blocked = false;
    }

    function updateVote(Vote v) public {
        for (uint i = 0; i < voterVotes[msg.sender].length; i++) {
            if (voterVotes[msg.sender][i].voteId == v.voteId) {
                v.blocked = voterVotes[msg.sender][i].blocked;
                voterVotes[msg.sender][i] = v; 
            }
        }
    }

    function getItemVotes(bytes16 itemId) public view returns (Vote[]) {
        return itemVotes[itemId];
    }

    function getVoterVotes(address voterId) public view returns (Vote[]) {
        return voterVotes[voterId];
    }
    
}