//
//  credentials.swift
//  SealdSDK demo app ios swift
//
//  Created by Mehdi on 21/02/2024.
//

import Foundation

// Seald account infos:
// First step with Seald: https://docs.seald.io/en/sdk/guides/1-quick-start.html
// Create a team here: https://www.seald.io/create-sdk
let testCredentials = TestCredentials(
    apiURL: "https://api.staging-0.seald.io/",
    appId: "50f5fe92-c35c-46bf-b2c1-552e42ef7dbd",
    JWTSharedSecretId: "c479dfe5-24ba-44eb-a6c6-4b43f000e03b",
    JWTSharedSecret: "MmJ44cpd82PnoP3phssfA4aARdWveyC2vCVe18dbwmjxGDfqbLOjKnooLuhJfn5i",
    ssksURL: "https://ssks.staging-0.seald.io/",
    ssksBackendAppKey: "a7971c1a-a590-42e5-8e4b-aa89f63b4326",
    ssksTMRChallenge: "aaaaaaaa"
)
