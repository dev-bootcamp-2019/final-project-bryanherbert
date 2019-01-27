# Design Pattern Decisions

## Circuit Breaker

I implemented a circuit breaker with the setStopped() function. This function can only be called by the owner of the FundMarketplace contract and all investor and manager functionality is disabled in the event of an attack or a bug detection. The only exception is the withdrawFunds() function which allows investors to recover their fees.

## Push Over Pull Payments

## Upgradable Design

## Mortal

## Fail Early and Fail Loud