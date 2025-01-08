const xrpl = require('xrpl');

async function main() {
    // Connect to XRPL Testnet
    const client = new xrpl.Client('wss://s.altnet.rippletest.net:51233'); // Testnet URL
    await client.connect();
    console.log('Connected to XRPL Testnet');

    // Sender's Wallet (Replace with your actual secret)
    const senderWallet = xrpl.Wallet.fromSeed('sEdTMq936tKxw2NEfxYnC2uLKi8aSKJ'); // Replace with sender's secret

    // Recipient Address
    const recipientAddress = 'rUDD9BMkowLsvDTt5NmRYeBTF5YZ9jhH36'; // Replace with recipient's XRPL address

    try {
        // Step 1: Fetch account info for the sequence number
        const accountInfo = await client.request({
            command: 'account_info',
            account: senderWallet.classicAddress,
        });
        const currentSequence = accountInfo.result.account_data.Sequence;
        console.log('Fetched Account Sequence:', currentSequence);

        // Step 2: Fetch current ledger index for LastLedgerSequence
        const ledger = await client.request({ command: 'ledger_current' });
        const currentLedgerIndex = ledger.result.ledger_current_index;
        console.log('Current Ledger Index:', currentLedgerIndex);

        // Step 3: Fetch the current network fee
        const feeResponse = await client.request({ command: 'fee' });
        const fee = feeResponse.result.drops.open_ledger_fee;
        console.log('Network Fee (in drops):', fee);

        // Step 4: Create Payment Transaction
        const payment = {
            TransactionType: 'Payment',
            Account: senderWallet.classicAddress,
            Destination: recipientAddress,
            Amount: xrpl.xrpToDrops('10'), // Amount to send (10 XRP in drops)
            Sequence: currentSequence, // Add the sequence number
            LastLedgerSequence: currentLedgerIndex + 10, // Transaction valid for the next 10 ledgers
            Fee: fee, // Include the network fee
        };
        console.log('Payment Transaction:', payment);

        // Step 5: Sign the Transaction
        const signedTx = senderWallet.sign(payment);
        console.log('Signed Transaction:', signedTx);

        // Step 6: Submit the Signed Transaction
        const response = await client.submitAndWait(signedTx.tx_blob);

        // Step 7: Process Response
        console.log('Transaction Result:', response.result);
        console.log('Transaction Hash:', signedTx.hash);

        if (response.result.meta.TransactionResult === 'tesSUCCESS') {
            console.log('Transaction succeeded!');
        } else {
            console.log('Transaction failed:', response.result.meta.TransactionResult);
        }
    } catch (error) {
        console.error('Error sending payment:', error);
    try{
         // 1. Create PaymentChannelFund Transaction
        const paymentChannelFund = {
            TransactionType: "PaymentChannelFund",
            Account: senderWallet.address,
            Channel: channelID,
            Amount: "500000", // Additional amount in drops (1 XRP = 1,000,000 drops)
        };

        // 2. Submit the Transaction
        const response = await client.submitAndWait(paymentChannelFund, { wallet: senderWallet });

        console.log("Payment Channel Funded:", response);

        // 3. Check the Funded Channel
        const check = await client.request({
            command: "account_channels",
            account: senderWallet.address
        });
        console.log(check);

    } finally {
        // Disconnect from XRPL
        await client.disconnect();
        console.log('Disconnected from XRPL');
    }
}

// Execute the main function
main().catch(console.error);
