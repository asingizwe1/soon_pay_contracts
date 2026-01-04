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
