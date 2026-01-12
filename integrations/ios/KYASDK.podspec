Pod::Spec.new do |spec|
  spec.name         = "KYASDK"
  spec.version      = "1.0.0"
  spec.summary      = "iOS SDK for KYA Protocol"
  spec.description  = "Native iOS SDK for interacting with KYA Protocol smart contracts"
  
  spec.homepage     = "https://github.com/RahilBhavan/KYA"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "KYA Protocol" => "team@kya.protocol" }
  
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/RahilBhavan/KYA.git", :tag => "#{spec.version}" }
  
  spec.source_files = "KYASDK/**/*.{swift,h,m}"
  spec.public_header_files = "KYASDK/**/*.h"
  
  spec.dependency "web3swift", "~> 2.0"
  spec.dependency "WalletConnectSwift", "~> 1.0"
  
  spec.swift_version = "5.0"
end
