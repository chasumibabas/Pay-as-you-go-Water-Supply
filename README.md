# 💧 Pay-as-you-go Water Supply Smart Contract

A decentralized water utility management system built on Stacks blockchain using Clarity smart contracts. This system enables users to register water meters, add prepaid balances, and automatically deduct usage costs.

## ✨ Features

- 🏠 **Water Meter Registration**: Users can register multiple water meters with custom rates
- 💰 **Prepaid Balance System**: Add STX to your account balance for water usage
- 📊 **Usage Tracking**: Automatic recording of water consumption with cost calculation
- 📈 **Historical Data**: Track payment and usage history
- 🔐 **Owner Controls**: Contract owner can adjust rates and fees
- ⚡ **Meter Management**: Activate/deactivate meters and update rates

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testnet/mainnet deployment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/Pay-as-you-go-Water-Supply.git
cd Pay-as-you-go-Water-Supply
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
npm install
npm test
```

## 📋 Contract Functions

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-contract-owner` | Returns contract owner address | None |
| `get-base-rate` | Returns current base rate | None |
| `get-service-fee` | Returns service fee | None |
| `get-water-meter` | Get meter details | `meter-id: uint` |
| `get-user-balance` | Get user's prepaid balance | `user: principal` |
| `get-user-meters` | Get list of user's meters | `owner: principal` |
| `calculate-usage-cost` | Calculate cost for usage amount | `usage-amount: uint, rate-per-liter: uint` |
| `is-meter-owner` | Check if user owns a meter | `meter-id: uint, user: principal` |

### Public Functions

| Function | Description | Parameters | Access |
|----------|-------------|------------|----------|
| `register-meter` | Register a new water meter | `rate-per-liter: uint` | Any user |
| `add-balance` | Add STX to prepaid balance | `amount: uint` | Any user |
| `record-usage` | Record water usage | `meter-id: uint, usage-amount: uint` | Meter owner |
| `deactivate-meter` | Deactivate a meter | `meter-id: uint` | Meter owner |
| `activate-meter` | Reactivate a meter | `meter-id: uint` | Meter owner |
| `update-meter-rate` | Update meter rate | `meter-id: uint, new-rate: uint` | Meter owner |
| `withdraw-balance` | Withdraw STX from balance | `amount: uint` | Any user |
| `set-base-rate` | Update base rate | `new-rate: uint` | Contract owner |
| `set-service-fee` | Update service fee | `new-fee: uint` | Contract owner |

## 💡 Usage Examples

### 1. Register a Water Meter
```clarity
(contract-call? .pay-as-you-go-water-supply register-meter u100)
;; Registers meter with rate of 100 microSTX per liter
```

### 2. Add Prepaid Balance
```clarity
(contract-call? .pay-as-you-go-water-supply add-balance u1000000)
;; Adds 1 STX to your prepaid balance
```

### 3. Record Water Usage
```clarity
(contract-call? .pay-as-you-go-water-supply record-usage u1 u50)
;; Records 50 liters usage for meter #1
```

### 4. Check Your Balance
```clarity
(contract-call? .pay-as-you-go-water-supply get-user-balance tx-sender)
;; Returns your current prepaid balance
```

## 🔧 Configuration

### Default Settings
- **Base Rate**: 50 microSTX per liter
- **Service Fee**: 10 microSTX per transaction
- **Max Meters per User**: 10

### Error Codes
- `u100`: Owner only function
- `u101`: Not found
- `u102`: Insufficient balance
- `u103`: Already exists
- `u104`: Invalid amount
- `u105`: Meter not active
- `u106`: Unauthorized
- `u107`: Invalid rate
- `u108`: Insufficient funds

## 🏗️ Architecture

The contract uses several data maps to maintain state:

- **water-meters**: Stores meter information and ownership
- **user-balances**: Tracks prepaid balances
- **meter-owners**: Maps users to their meters
- **usage-history**: Records historical usage data
- **payment-history**: Tracks payment transactions

## 🔒 Security Features

- Ownership verification for meter operations
- Balance checks before deducting usage costs
- Input validation for all parameters
- Protected admin functions

## 🛠️ Development

### Testing
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

### Deployment
```bash
clarinet deploy --testnet
```

## 📈 Roadmap

- 🌊 Integration with IoT water sensors
- 📱 Mobile app for easy meter management  
- 🔔 Low balance notifications
- 📊 Advanced analytics dashboard
- 🌍 Multi-utility support (gas, electricity)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

Built with ❤️ on Stacks blockchain
