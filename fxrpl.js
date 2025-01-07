const xrpl = require("xrpl");

//Fund a Payment Channel
async function main() {
    // 1. Connect to XRPL Testnet
    const client = new xrpl.Client("wss://s.altnet.rippletest.net:51233");
    await client.connect();

    console.log("Connected to XRPL Testnet");

    // 2. Define Sender Wallet (Use Testnet Credentials)
    const senderWallet = xrpl.Wallet.fromSeed("sEdTwC646CCrQo8UWj9HcWUgWsgNW2s");
    console.log(`Sender Address: ${senderWallet.address}`);

    // 3,Get the Channel ID from the payment channel you  created previously
    const channels = await client.request({
        command: "account_channels",
        account: senderWallet.address
    });
    console.log(channels);
    
    // 4. Define the Payment Channel ID
    const channelID = "Your_Channel_ID_Here"; // Replace with the channel ID you get front above

    // 5. Create PaymentChannelFund Transaction
    const paymentChannelFund = {
        TransactionType: "PaymentChannelFund",
        Account: senderWallet.address,
        Channel: channelID,
        Amount: "500000", // Additional amount in drops (1 XRP = 1,000,000 drops)
    };

    // 6. Submit the Transaction
    const response = await client.submitAndWait(paymentChannelFund, { wallet: senderWallet });

    console.log("Payment Channel Funded:", response);

    // 7. Check the Funded Channel
    const check = await client.request({
        command: "account_channels",
        account: senderWallet.address
    });
    console.log(check);

    // 8. Disconnect from XRPL
    await client.disconnect();
    console.log("Disconnected from XRPL Testnet");
}

main().catch(console.error);
