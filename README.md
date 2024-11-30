# RepStack - Enhanced DAO Reputation System

RepStack is a comprehensive reputation tracking system designed for Decentralized Autonomous Organizations (DAOs) built on the Stacks blockchain. It provides a sophisticated mechanism for measuring, tracking, and rewarding user participation and contributions within a DAO ecosystem.

## Features

### Core Functionality
- **User Reputation Tracking**: Dynamic scoring system based on multiple contribution factors
- **Proposal Management**: Create and track proposal lifecycle
- **Voting System**: Record and weight user votes
- **Community Kudos**: Peer-to-peer recognition system
- **Activity Decay**: Time-based score adjustment to encourage consistent participation

### Scoring Mechanisms
- **Weighted Contributions**: Different activities carry varying weights
- **Participation Bonuses**: Rewards for consistent voting and proposal creation
- **Success Multipliers**: Additional points for successful proposals
- **Dynamic Scoring**: Scores adjust based on activity frequency and quality

## Technical Specifications

### Data Structures

#### User Scores
```clarity
{
    reputation-score: uint,
    proposal-count: uint,
    vote-count: uint,
    last-action: uint,
    contribution-count: uint,
    successful-proposals: uint,
    vote-participation-rate: uint,
    community-kudos: uint
}
```

#### Contribution Weights
```clarity
{
    base-weight: uint,
    multiplier: uint,
    minimum-threshold: uint
}
```

### Key Parameters
- Maximum Proposal ID: 1,000,000
- Maximum Weight: 1,000
- Base Weights:
  - Proposals: 10 points
  - Votes: 5 points
  - Contributions: 15 points

## Usage

### Initialize User
```clarity
(contract-call? .repstack initialize-user)
```
Creates a new user profile with initial scores set to 0.

### Submit Proposal
```clarity
(contract-call? .repstack record-proposal proposal-id)
```
Records a new proposal and updates the proposer's reputation score.

### Cast Vote
```clarity
(contract-call? .repstack record-vote proposal-id)
```
Records a vote for a specific proposal and updates the voter's reputation score.

### Award Community Kudos
```clarity
(contract-call? .repstack award-community-kudos user-principal)
```
Allows users to recognize others' contributions through kudos awards.

### Check Reputation Score
```clarity
(contract-call? .repstack get-current-score user-principal)
```
Returns the current reputation score for a given user, including all bonuses and decay calculations.

## Reputation Calculation

The system uses a sophisticated scoring mechanism that takes into account:

1. **Base Activity Scores**
   - Proposal Creation: 10 points × multiplier
   - Voting: 5 points × multiplier
   - Other Contributions: 15 points × multiplier

2. **Bonus Factors**
   - Activity Bonus: 2x multiplier for users with >10 actions
   - Participation Rate Bonus: 50 points for >75% voting participation
   - Successful Proposal Bonus: 25 points per successful proposal

3. **Score Decay**
   - Scores decay over time to encourage consistent participation
   - Minimum score floor of 10% of original score
   - Decay factor calculated based on blocks passed

## Administrative Features

### Update Weight Parameters
```clarity
(contract-call? .repstack update-weight-parameters action base-weight multiplier minimum-threshold)
```
Allows contract owner to adjust scoring parameters for different activities.

## Security Considerations

- Owner-only administrative functions
- Input validation for all parameters
- Status transition restrictions
- Authorization checks for sensitive operations
- Protection against duplicate entries

## Best Practices for DAOs

1. **Regular Participation**
   - Vote on proposals consistently to maintain high participation rate
   - Submit quality proposals to earn successful proposal bonuses
   - Engage with community through kudos system

2. **Score Maintenance**
   - Maintain regular activity to prevent score decay
   - Focus on successful proposals for maximum point gains
   - Participate in voting to earn participation bonuses

3. **Community Engagement**
   - Use the kudos system to recognize valuable contributions
   - Monitor participation rates
   - Engage in both proposal creation and voting

## Technical Requirements

- Stacks Blockchain Network
- Clarity Smart Contract Support
- Compatible Web3 Wallet

## Error Codes

- 100: Owner-only operation
- 101: Entity not found
- 102: Unauthorized action
- 103: Invalid score
- 104: Invalid parameter
- 111: Invalid proposal ID
- 112: Invalid action

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
