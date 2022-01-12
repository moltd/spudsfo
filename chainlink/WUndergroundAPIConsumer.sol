// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract WUndergroundAPIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 public precipRate;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the weather target data 
     */
    function requestPrecipRate() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        // My personal Weather Station
        request.add("get", "https://api.weather.com/v2/pws/observations/current?stationId=KCASANRA779&format=json&units=e&apiKey=95cf2dc233d24a4a8f2dc233d2ba4a9f");
        
        // Set the path to find the desired data in the API response, where the response format is:      
       
        // {"observations":
        //   {"imperial":
        //    {"precipRate": xxx.xx
        //    }
        //   }
        //  }
        request.add("path", "observations.imperial.precipRate");
      
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _precipRate) public recordChainlinkFulfillment(_requestId)
    {
        precipRate = _precipRate;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}

