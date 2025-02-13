const fetch = require("node-fetch");

 async function getNativeSymbol(chainId) {
    if(chainId === 1337) {
        return 'ETH'
    }
    
    const url = "https://chainid.network/chains.json";
    
    try {
        const response = await fetch(url);
        if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);
        
        const chains = await response.json();
        const chainData = chains.find(chain => chain.chainId === chainId);
        
        if (chainData && chainData.nativeCurrency) {
            return chainData.nativeCurrency.symbol;
        } else {
            throw new Error("Chain ID not found.");
        }
    } catch (error) {
        console.error("Error fetching chain data:", error);
        return null;
    }
}

module.exports = getNativeSymbol