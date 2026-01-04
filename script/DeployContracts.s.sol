// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Mock_Liquid.sol";
import "../src/Core_MicroBanking_Features.sol";
import "../src/MockV3Aggregator.sol";

contract DeployContracts is Script {
    function run() external {
        // read private key from env
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        // optional: if you already have a UGX_USD feed address on the network
        address providedFeed = vm.envAddress("UGX_USD_FEED");

        vm.startBroadcast(deployerKey);

        // 1) Deploy MockLiquid token
        MockLiquid ml = new MockLiquid();
        console.log("MockLiquid deployed at:", address(ml));

        // 2) If no feed provided, deploy MockV3Aggregator with sample price.
        address feedAddr = providedFeed;
        if (feedAddr == address(0)) {
            // decimals 8, initial price = 3800 (e.g. 3800 UGX per USD) scaled by 1e8
            int256 initial = int256(3800) * int256(10 ** 8);
            MockV3Aggregator m = new MockV3Aggregator(8, initial);
            feedAddr = address(m);
            console.log("MockV3Aggregator deployed at:", feedAddr);
        } else {
            console.log("Using provided UGX_USD_FEED:", feedAddr);
        }

        // 3) Deploy CoreMicroBank(contract expects a price feed address)
        CoreMicroBank bank = new CoreMicroBank(feedAddr);
        console.log("CoreMicroBank deployed at:", address(bank));

        vm.stopBroadcast();
    }
}
