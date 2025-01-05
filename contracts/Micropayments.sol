// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract Micropayments {
//     // Token to be used for micropayments
//     IERC20 public token;

//     struct Payment {
//         address sender;
//         address receiver;
//         uint256 amount;
//         bool completed;
//     }

//     // Mapping of payment IDs to their details
//     mapping(uint256 => Payment) public payments;
//     uint256 public paymentCounter;

//     // Event emitted when a new payment is created
//     event PaymentCreated(uint256 indexed paymentId, address indexed sender, address indexed receiver, uint256 amount);
//     // Event emitted when a payment is completed
//     event PaymentCompleted(uint256 indexed paymentId, address indexed receiver, uint256 amount);
//     // Event emitted when a payment is refunded
//     event PaymentRefunded(uint256 indexed paymentId, address indexed sender, uint256 amount);

//     // Constructor to set the token address
//     constructor(address tokenAddress) {
//         token = IERC20(tokenAddress);
//     }

//     /**
//      * @dev Create a new micropayment.
//      * @param receiver The address of the recipient.
//      * @param amount The amount of tokens to send.
//      */
//     function createPayment(address receiver, uint256 amount) external {
//         require(receiver != address(0), "Receiver cannot be zero address");
//         require(amount > 0, "Amount must be greater than zero");

//         // Transfer tokens from sender to this contract
//         bool success = token.transferFrom(msg.sender, address(this), amount);
//         require(success, "Token transfer failed");

//         // Record the payment
//         payments[paymentCounter] = Payment({
//             sender: msg.sender,
//             receiver: receiver,
//             amount: amount,
//             completed: false
//         });

//         emit PaymentCreated(paymentCounter, msg.sender, receiver, amount);
//         paymentCounter++;
//     }

//     /**
//      * @dev Release the payment to the receiver.
//      * @param paymentId The ID of the payment to release.
//      */
//     function releasePayment(uint256 paymentId) external {
//         Payment storage payment = payments[paymentId];
//         require(!payment.completed, "Payment already completed");
//         require(payment.receiver == msg.sender, "Only receiver can claim the payment");

//         // Mark the payment as completed
//         payment.completed = true;

//         // Transfer tokens to the receiver
//         bool success = token.transfer(payment.receiver, payment.amount);
//         require(success, "Token transfer failed");

//         emit PaymentCompleted(paymentId, payment.receiver, payment.amount);
//     }

//     /**
//      * @dev Refund the payment back to the sender.
//      * @param paymentId The ID of the payment to refund.
//      */
//     function refundPayment(uint256 paymentId) external {
//         Payment storage payment = payments[paymentId];
//         require(!payment.completed, "Payment already completed");
//         require(payment.sender == msg.sender, "Only sender can request a refund");

//         // Mark the payment as completed
//         payment.completed = true;

//         // Transfer tokens back to the sender
//         bool success = token.transfer(payment.sender, payment.amount);
//         require(success, "Token transfer failed");

//         emit PaymentRefunded(paymentId, payment.sender, payment.amount);
//     }
// }



contract Micropayments {
    // -- 1. ENUM & STRUCTS --

    /// @dev Tracks the state of each payment
    enum PaymentStatus {
        Pending,   // Payment is created but neither released nor refunded
        Completed, // Payment has been successfully released
        Refunded   // Payment was refunded to the sender
    }

    struct Payment {
        address sender;
        address receiver;
        uint256 amount;
        PaymentStatus status; 
        uint256 deadline;  // optional: if you want to limit how long the payment can be claimed
    }

    // -- 2. STATE VARIABLES --

    // Token to be used for micropayments
    IERC20 public token;

    // Mapping of payment IDs to their details
    mapping(uint256 => Payment) public payments;
    uint256 public paymentCounter;

    // -- 3. EVENTS --

    /// @dev Emitted when a new payment is created
    event PaymentCreated(
        uint256 indexed paymentId,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 deadline
    );

    /// @dev Emitted when a payment is completed (tokens transferred to receiver)
    event PaymentCompleted(
        uint256 indexed paymentId,
        address indexed receiver,
        uint256 amount
    );

    /// @dev Emitted when a payment is refunded (tokens transferred back to sender)
    event PaymentRefunded(
        uint256 indexed paymentId,
        address indexed sender,
        uint256 amount
    );

    // -- 4. CONSTRUCTOR --

    /**
     * @dev Constructor to set the token address that will be used for micropayments.
     * @param tokenAddress The ERC20 token contract address.
     */
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(tokenAddress);
    }

    // -- 5. FUNCTIONS --

    /**
     * @dev Create a new micropayment.
     * @param receiver The address of the receiver.
     * @param amount The amount of tokens to send.
     * @param deadline (Optional) The timestamp by which the payment must be claimed. 
     *        Use 0 if you don't want to enforce a time-based condition.
     */
    function createPayment(
        address receiver, 
        uint256 amount,
        uint256 deadline
    ) external {
        require(receiver != address(0), "Receiver cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        // If you want to enforce a deadline in the future, uncomment:
        // require(deadline == 0 || deadline > block.timestamp, "Deadline must be in the future");

        // Transfer tokens from sender to this contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Record the payment
        payments[paymentCounter] = Payment({
            sender: msg.sender,
            receiver: receiver,
            amount: amount,
            status: PaymentStatus.Pending,
            deadline: deadline
        });

        emit PaymentCreated(paymentCounter, msg.sender, receiver, amount, deadline);

        // Increment paymentCounter for the next payment
        paymentCounter++;
    }

    /**
     * @dev Release the payment to the receiver if it is still pending.
     *      Optionally, you can enforce deadline logic here.
     * @param paymentId The ID of the payment to release.
     */
    function releasePayment(uint256 paymentId) external {
        Payment storage payment = payments[paymentId];
        require(payment.status == PaymentStatus.Pending, "Payment not pending");
        require(payment.receiver == msg.sender, "Only receiver can claim the payment");

        // Optional: if you want to ensure the deadline hasn't passed
        // if (payment.deadline != 0) {
        //     require(block.timestamp <= payment.deadline, "Deadline passed, cannot release");
        // }

        // Mark the payment as completed
        payment.status = PaymentStatus.Completed;

        // Transfer tokens to the receiver
        bool success = token.transfer(payment.receiver, payment.amount);
        require(success, "Token transfer failed");

        emit PaymentCompleted(paymentId, payment.receiver, payment.amount);
    }

    /**
     * @dev Refund the payment back to the sender if still pending.
     *      Optionally, you can allow immediate refunds or only after a deadline has passed.
     * @param paymentId The ID of the payment to refund.
     */
    function refundPayment(uint256 paymentId) external {
        Payment storage payment = payments[paymentId];
        require(payment.status == PaymentStatus.Pending, "Payment not pending");
        require(payment.sender == msg.sender, "Only sender can request a refund");

        // Optional: enforce that refunds can happen only after a certain time
        // if (payment.deadline != 0) {
        //     require(block.timestamp > payment.deadline, "Deadline not passed yet");
        // }

        // Mark the payment as refunded
        payment.status = PaymentStatus.Refunded;

        // Transfer tokens back to the sender
        bool success = token.transfer(payment.sender, payment.amount);
        require(success, "Token transfer failed");

        emit PaymentRefunded(paymentId, payment.sender, payment.amount);
    }
}
