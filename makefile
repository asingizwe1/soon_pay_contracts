#    ||||||||||||||| TAKE NOTE ||||||||||||
# Ensure .env is loaded by your shell environment before running make (export or use envsubst)
# the above is done using command below
# export $(grep -v '^#' .env | xargs)
# $ source .env
#
# target:
# <TAB>command
# <TAB>command
#
# Makefiles are extremely strict: dont leave spaces or tabs

# export PRIVATE_KEY=0xcc2bb02cbd14fd9d307a9fbff86aed2178ee21a07743d1e682d82f698389043e



# echo "$PRIVATE_KEY" | cat -A
# cc2bb02cbd14fd9d307a9fbff86aed2178ee21a07743d1e682d82f698389043e^M$
# It literally means your .env line ends with a hidden \r character at the end.
# forge create --private-key expects strict hex characters only.

# If your key ends with \r, it becomes:

# cc2bb02cbd14fd9d307a9fbff86aed2178ee21a07743d1e682d82f698389043e\r


# \r is not valid hex, so Foundry cannot decode it → Failed to decode private key

#FIX THE decode issue
# sed -i 's/\r$//' .env
# Then reload:
# source .env

# default network args (local anvil)
#NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast


# shortcut: SEPOLIA network args (manually switch if needed)
NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# Export in your shell before running make
# export $(grep -v '^#' .env | xargs)

# Deploy the contracts using Foundry script
deploy:
	@echo "Deploying contracts..."
	@forge script script/DeployContracts.s.sol:DeployContracts $(NETWORK_ARGS)


# Quick target to deploy only the MockLiquid (example)
deploy-mockliquid:
	@forge create src/Mock_Liquid.sol:MockLiquid $(NETWORK_ARGS)


# Convenience: run the script locally against anvil
deploy-local:
	@forge script script/DeployContracts.s.sol:DeployContracts --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast


# Example: run tests
test:
	@forge test
# asingizwe1@DESKTOP-JMR591K:/mnt/f/SOON_PAY_HACKATHON/soon_pay_contracts$ make deploy-mockliquid
# [⠑] Compiling...
# No files changed, compilation skipped
# Deployer: 0xECB2885C73CBe2e739E10EBCdd3b12Dc54d25D4E
# Deployed to: 0x90785d92456F2618a65040d8556daC8fbf38bF27
# Transaction hash: 0x191456555659c3346adfcfb2359aa05e0bc414972d043459d42527468cd15dcb
# Starting contract verification...
# Waiting for sourcify to detect contract deployment...
# Start verifying contract `0x90785d92456F2618a65040d8556daC8fbf38bF27` deployed on sepolia
# Compiler version: 0.8.33

# Submitting verification for [src/Mock_Liquid.sol:MockLiquid] 0x90785d92456F2618a65040d8556daC8fbf38bF27.
# Submitted contract for verification:
#         Response: `OK`
#         GUID: `kwazbhdzyjjdri9bkwt9d24rj32qgkrwvtky3zvjbuhjxclnmv`
#         URL: https://sepolia.etherscan.io/address/0x90785d92456f2618a65040d8556dac8fbf38bf27   
# Contract verification status:
# Response: `OK`
# Details: `Pass - Verified`
# Contract successfully verified
# asingizwe1@DESKTOP-JMR591K:/mnt/f/SOON_PAY_HACKATHON/soon_pay_contracts$ 

# make deploy > deploy.log 2>&1
# This will:

# save all terminal output