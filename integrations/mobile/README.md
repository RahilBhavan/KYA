# KYA Protocol - Mobile SDKs

Mobile SDKs for iOS and Android to interact with KYA Protocol.

## React Native SDK

See [react-native/README.md](./react-native/README.md) for React Native SDK documentation.

## iOS SDK

Native Swift SDK for iOS applications.

### Installation

```ruby
pod 'KYASDK', :git => 'https://github.com/RahilBhavan/KYA.git'
```

### Usage

```swift
import KYASDK

let client = KYAClient(
    rpcUrl: "https://sepolia.base.org",
    agentRegistryAddress: "0x..."
)

client.createAgent(
    name: "MyAgent",
    description: "My first AI agent",
    category: "Trading"
) { result in
    switch result {
    case .success(let agent):
        print("Agent created: \(agent.tokenId)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Android SDK

Native Kotlin SDK for Android applications.

### Installation

```gradle
dependencies {
    implementation 'com.kya.protocol:sdk:1.0.0'
}
```

### Usage

```kotlin
import com.kya.protocol.sdk.KYAClient

val client = KYAClient(
    rpcUrl = "https://sepolia.base.org",
    agentRegistryAddress = "0x..."
)

lifecycleScope.launch {
    client.createAgent(
        name = "MyAgent",
        description = "My first AI agent",
        category = "Trading"
    ).onSuccess { agent ->
        println("Agent created: ${agent.tokenId}")
    }.onFailure { error ->
        println("Error: ${error.message}")
    }
}
```

## Features

- Native wallet integration
- Offline transaction signing
- Push notifications
- Mobile-optimized UI components
