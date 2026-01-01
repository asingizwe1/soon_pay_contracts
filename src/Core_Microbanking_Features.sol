// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title CoreMicroBank
 * @author Louis Asingizwe
 * @notice Custodial microbanking core with deposits, fees, loans, and yield
 * @dev Hackathon-grade, event-heavy, demo-friendly architecture
 */
contract CoreMicroBank {

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant FEE_BPS = 500; // 5%
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant BORROW_LIMIT_BPS = 5_000; // 50%
    uint256 public constant ANNUAL_INTEREST_BPS = 1_000; // 10% APR
AggregatorV3Interface public ugxUsdFeed;//store oracle address


    /*//////////////////////////////////////////////////////////////
                               OWNER
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               USER STRUCT
    //////////////////////////////////////////////////////////////*/

    struct User {
        uint256 depositBalance;     // usable collateral
        uint256 stakedBalance;      // optional future staking
        uint256 loanDebt;           // principal + interest
        uint256 lastAccrual;        // interest timestamp
        address agent;              // registering agent
        bool exists;
    }

    mapping(bytes32 => User) public users;

    /*//////////////////////////////////////////////////////////////
                         PROTOCOL ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    uint256 public protocolFeePool;     // USDT-equivalent
    uint256 public totalLiquidStaked;   // protocol staking

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRegistered(bytes32 indexed userId, address indexed agent, uint256 timestamp);

    event DepositRecorded(
        bytes32 indexed userId,
        address indexed agent,
        uint256 grossAmount,
        uint256 feeAmount,
        uint256 netAmount
    );

    event ProtocolFeeAccumulated(uint256 newFee, uint256 totalPool);

    event FeesConvertedToLiquid(
        uint256 usdtAmount,
        uint256 liquidAmount,
        uint256 priceUsed,
        uint256 timestamp
    );

    event LiquidStaked(uint256 amount, uint256 totalStaked);

    event LoanRequested(bytes32 indexed userId, uint256 amount);

    event LoanIssued(bytes32 indexed userId, uint256 amount, uint256 totalDebt);

    event InterestAccrued(
        bytes32 indexed userId,
        uint256 interestAmount,
        uint256 newDebt,
        uint256 timestamp
    );

    event LoanRepaid(bytes32 indexed userId, uint256 amount, uint256 remainingDebt);

    event WithdrawalProcessed(bytes32 indexed userId, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        //HelperConfig exists (we’ll come back to it)
         //network flexibility comes from.->allows aby network - Sepolia,local Anvil,anychain
         ugxUsdFeed = AggregatorV3Interface(_ugxUsdFeed); 
    }

    /*//////////////////////////////////////////////////////////////
                           USER REGISTRATION
    //////////////////////////////////////////////////////////////*/

    function registerUser(bytes32 userId) external {
        require(!users[userId].exists, "User exists");

        users[userId] = User({
            depositBalance: 0,
            stakedBalance: 0,
            loanDebt: 0,
            lastAccrual: block.timestamp,
            agent: msg.sender,
            exists: true
        });

        emit UserRegistered(userId, msg.sender, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              DEPOSITS
    //////////////////////////////////////////////////////////////*/

    function recordDeposit(bytes32 userId, uint256 amount) external {
        User storage u = users[userId];
        require(u.exists, "User not found");

        uint256 fee = (amount * FEE_BPS) / BPS_DENOMINATOR;
        uint256 net = amount - fee;

        u.depositBalance += net;
        protocolFeePool += fee;

        emit DepositRecorded(userId, msg.sender, amount, fee, net);
        emit ProtocolFeeAccumulated(fee, protocolFeePool);
    }

    /*//////////////////////////////////////////////////////////////
                        FEE CONVERSION (SIMULATED)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Simulates USDT → Liquid conversion & staking
     * @dev In production this would be Chainlink Automation
     */
    function convertFeesAndStake(uint256 mockLiquidPrice) external onlyOwner {
        require(protocolFeePool > 0, "No fees");

        uint256 usdtAmount = protocolFeePool;
        uint256 liquidAmount = usdtAmount / mockLiquidPrice;

        protocolFeePool = 0;
        totalLiquidStaked += liquidAmount;

        emit FeesConvertedToLiquid(
            usdtAmount,
            liquidAmount,
            mockLiquidPrice,
            block.timestamp
        );

        emit LiquidStaked(liquidAmount, totalLiquidStaked);
    }

    /*//////////////////////////////////////////////////////////////
                                LOANS
    //////////////////////////////////////////////////////////////*/

    function maxBorrowable(bytes32 userId) public view returns (uint256) {
        return (users[userId].depositBalance * BORROW_LIMIT_BPS) / BPS_DENOMINATOR;
    }

    function requestLoan(bytes32 userId, uint256 amount) external {
        User storage u = users[userId];
        require(u.exists, "User not found");

        _accrueInterest(userId);

        require(
            u.loanDebt + amount <= maxBorrowable(userId),
            "Exceeds borrow limit"
        );

        u.loanDebt += amount;

        emit LoanRequested(userId, amount);
        emit LoanIssued(userId, amount, u.loanDebt);
    }

    /*//////////////////////////////////////////////////////////////
                          INTEREST ACCRUAL
    //////////////////////////////////////////////////////////////*/

    function _accrueInterest(bytes32 userId) internal {
        User storage u = users[userId];

        uint256 elapsed = block.timestamp - u.lastAccrual;
        if (elapsed == 0 || u.loanDebt == 0) return;

        uint256 interest = (u.loanDebt * ANNUAL_INTEREST_BPS * elapsed)
            / (BPS_DENOMINATOR * 365 days);

        u.loanDebt += interest;
        u.lastAccrual = block.timestamp;

        emit InterestAccrued(userId, interest, u.loanDebt, block.timestamp);
    }

    function accrueInterest(bytes32 userId) external {
        _accrueInterest(userId);
    }

    /*//////////////////////////////////////////////////////////////
                             REPAYMENT
    //////////////////////////////////////////////////////////////*/

    function repayLoan(bytes32 userId, uint256 amount) external {
        User storage u = users[userId];
        require(u.exists, "User not found");

        _accrueInterest(userId);

        require(amount <= u.loanDebt, "Too much");

        u.loanDebt -= amount;

        emit LoanRepaid(userId, amount, u.loanDebt);
    }

    /*//////////////////////////////////////////////////////////////
                             WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    function withdraw(bytes32 userId, uint256 amount, address to) external {
        User storage u = users[userId];
        require(u.exists, "User not found");

        _accrueInterest(userId);

        require(u.loanDebt == 0, "Outstanding loan");
        require(amount <= u.depositBalance, "Insufficient balance");

        u.depositBalance -= amount;

        emit WithdrawalProcessed(userId, to, amount);
        // In real deployment: transfer USDT from contract vault


    /*//////////////////////////////////////////////////////////////
                            GETPRICEFEED
    //////////////////////////////////////////////////////////////*/
//“We normalize all deposits into USD-equivalent stable units using Chainlink Price Feeds.”
function getUGXtoUSD() public view returns (uint256) {
    (, int price,,,) = ugxUsdFeed.latestRoundData();
    return uint256(price);
}


    }
}
/**Chainlink Price Feeds
 * Price Feeds are READ-ONLY

They live on-chain

Your contract calls them

Frontend never calls Chainlink directly
 
 smartcontractkit/chainlink
 -AggregatorV3Interface
-Automation interfaces
-VRF (not needed for now)

 */




/**
 * Register user

Event: UserRegistered

Agent records deposit

Event: DepositRecorded

Event: ProtocolFeeAccumulated

After ~3 seconds

Call convertFeesAndStake()

Event: FeesConvertedToLiquid

Event: LiquidStaked

Request loan

Event: LoanRequested

Event: LoanIssued

Wait a few seconds

Call accrueInterest()

Event: InterestAccrued

Repay loan

Event: LoanRepaid

Withdraw

Event: WithdrawalProcessed

Your frontend can subscribe to events and visually show:

Fee chopping

Conversion

Staking

Loan growth
 * 
 */