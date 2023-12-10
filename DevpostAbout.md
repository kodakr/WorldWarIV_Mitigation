## Inspiration
The world is currently at World war III.
The inspiration behind WorldWar4Mitigation stems from recognizing the recurring pattern where conflicts arise due to disagreements, ultimately leading to wars. The goal was to create a solution that addresses this core issue (and at a root directory) by providing a transparent and decentralized decision-making platform accessible to all, aiming to prevent future conflicts and promote peace.

## What it does
WorldWar4Mitigation (each deployed instance ) introduces a blockchain-based decentralized consensus-reaching system that allows participants (strictly members only) to partake in exerting their opinion towards a potential consensus. It eliminates centralized control and manipulation, enabling fair decision-making in various scenarios, from personal choices to critical governance matters.

## How we built it
The project was built using Solidity for smart contract development and hacking tool Foundry for integration testing. We leveraged:
- Chainlink's Verifiable Random Function (VRFv2) 
    - For secure and Unique ID generation allowing every deployed instance to be uniquely Identified. 
- Chainlink CCIP
    - For wider accessibility allowing all potential users to participate from the comfort of their chain.
- Potential for Chainlink Automation.
    

## Challenges we ran into
- Designing a one contract fits all structure. This requires a great skill form developer. Product demands Malleability, Robustness etc to serve ubiquitously at all tiers.
- implementing a powerful `function voteSortingAlgorithm()` which efficiently sorts vote to reach a "winner" or "inconclusive" state (without external inflence and irrespective of number of votes).
- Ensuring robust security and tamper-proof functionality of the consensus-reaching system. As this project would be needing audit sponsorship.
- Exploring and integrating Chainlink's functionalities (CCIP and VRFv2)
- High Ethereum gas fees. Hence why we've chosen Avalanche.

## Accomplishments that we're proud of
- Successfully developing a versatile, transparent, and tamper-proof decentralized decision-making platform with archive for future enquiryies and investigations.
- succesfully Integrating Chainlink's backend services.
- Implementing robust security measures to prevent manipulation and ensure fairness in the voting process.

## What we learned
- The significant solution provided by Chainlink Services to blockchain development
- Deeper insights into blockchain development and smart contract architecture.
- Understanding the significance, importance and difficulty of decentralization in decision-making systems.
- Practical implementation, utilization and Chainlink backend services.

## What's next for WorldWarIV_Mitigation
- Refinement and expansion of the platform's functionalities to cater to diverse decision-making scenarios.
    - eg: consider a scenario where each deployed instance is not just a CCIPReceiver but both CCIPReceiver and CCIPSender allowing all CCIP voters to receive voting feedback on their CCIP sender contract (a custom voting.sol Template may be made for this).
    - Perhaps at V2.0 of this project, Chainlink automation would be included to this innovation. possibly drasticall restricting admin role. Wow awesome!
- Community outreach and adoption efforts to encourage widespread utilization of the platform for fair and transparent decision-making on a global scale.

This project intends to scale in bits and within the decade will be utilized ubiquitously. That is utilized across all hierarchy of situations ranging from  National Presidential elections to family trivial issues. Would be the go-to platform for all forms of decision or consensus-reaching mechanism by government, companies, schools, institutions, individuals etc.

<div style="padding:56.25% 0 0 0;position:relative;"><iframe src="https://player.vimeo.com/video/893018733?badge=0&amp;autopause=0&amp;player_id=0&amp;app_id=58479" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" style="position:absolute;top:0;left:0;width:100%;height:100%;" title="Library _ Loom - 9 December 2023"></iframe></div><script src="https://player.vimeo.com/api/player.js"></script>

