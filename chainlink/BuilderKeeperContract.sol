// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and

import "@chainlink/contracts/src/v0.7/KeeperCompatible.sol";
import "https://github.com/moltd/spudsfo/edit/master/chainlink/AccuweatherConsumer.sol"; // get weather data from AccuWeather 
import "https://github.com/ckraczkowsky91/smb-smart-contract-ethereum/blob/master/SmartInvoice.sol";

contract BuilderKeeperContract is KeeperCompatibleInterface {
    /**
    * Public counter variable
    */
    uint public daysMissed;
    uint public precipRate24;
    
    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public lastTimeStamp;
    unit private monthTime = 259200; // Month in epoch seconds.
    
    /**
     * Third party contracts used to bring use case to life
     */
    AccuweatherConsumer internal accuWeatherFeed;
    SmartInvoice internal invoiceEvent;
    
    
    /** LINK, Oracle and JobIDs for AccuWeather */
    string internal accuW_Link = "0xa36085F69e2889c224210F603D836748e7dC0088";
    string internal accuW_Oracle = "0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd";
    string internal accuW_jobID = "7c276986e23b4b1c990d8659bca7a9d0"; // location-current-conditions
    struct result {
        string jobid;
        string LINK;
        string jobsite_LAT;
        string jobsite_LONG;
        string units;
    }
        
    
    
    /* Payment from and Payment to detail */
    string internal builderAccount;
    string internal customerAccount = "0xTBD";


    /** JobSite LONG / LAT **/
    uint internal jobsite_LAT = 37;
    uint internal jobsite_LONG = -122; 

    constructor(uint updateInterval) {
    
      // Realitically for our use case we only need to this contract unkeep once every 24 hours, but for the test instance we will do every 15 seconds
  
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      daysMissed = 0;
      
      accuWeatherFeed = AccuweatherConsumer(accuW_Link, accuW_Oracle);
      invoiceEvent = SmartInvoice(250); /* Our fixed amount to pay when keeper upkeep is required */
    }

    function getWeatherPrecipRate() {
         result = accuWeatherFeed.requestLocationCurrentConditions(
            accuW_jobID,
            accuW_Link,
            jobsite_LAT,
            jobsite_LONG,
            units);
            
         return result.preciptationPast24Hours;
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
   
        uint precipRate24 = getWeatherPrecipRate();
        upkeepNeeded = ((getWeatherPrecipRate()) > 1.5); // abstract 1.5 to checkData parameter.
      
        // upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
    
        lastTimeStamp = block.timestamp;
        
        // Reset daysMissed count after 30 days)
        if (lastTimeStamp > 30 days) {
            daysMissed = 0;
        }
        
        if (lastTimeStamp > 1 days) {
            daysMissed = daysMissed + 1; // exceeded the rain threshold, in a month
        }
        
        if (daysMissed > 3) {
            invoiceEvent.withdraw();
        }
        
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
}
