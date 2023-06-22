//
//  ContentView.swift
//  seald-sdk-demo-app-ios-swift
//
//  Created by Mehdi Kouhen on 28/02/2023.
//  Copyright © 2023 Seald SAS. All rights reserved.
//

import SwiftUI
import SealdSdk
import JWT

struct TestCredentials {
    var apiURL: String
    var appId: String
    var JWTSharedSecretId: String
    var JWTSharedSecret: String
    var ssksUrl: String
    var ssksBackendAppId: String
    var ssksBackendAppKey: String
    var ssksTMRChallenge: String
}

func generateRandomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
    var randomString = ""
    for _ in 0..<length {
        let randomIndex = Int(arc4random_uniform(UInt32(letters.count)))
        let randomLetter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
        randomString += String(randomLetter)
    }
    return randomString
}

func generateRandomByteArray(length: Int) -> Data {
    return generateRandomString(length: length).data(using: .utf8)!
}

func runTests() async {
    let testCredentials = TestCredentials(
        apiURL: "https://api-dev.soyouz.seald.io/",
        appId: "00000000-0000-1000-a000-7ea300000018",
        JWTSharedSecretId: "00000000-0000-1000-a000-7ea300000019",
        JWTSharedSecret: "o75u89og9rxc9me54qxaxvdutr2t4t25ozj4m64utwemm0osld0zdb02j7gv8t7x",
        ssksUrl: "https://ssks.soyouz.seald.io/",
        ssksBackendAppId: "00000000-0000-0000-0000-000000000001",
        ssksBackendAppKey: "00000000-0000-0000-0000-000000000002",
        ssksTMRChallenge: "aaaaaaaa"
    )

    async let testSDK: () = sdkTests(testCredentials: testCredentials)
    async let testSsksPassword: () = ssksPasswordTests(testCredentials: testCredentials)
    async let testSsksTMR: () = ssksTMRTests(testCredentials: testCredentials)

    await testSDK
    await testSsksPassword
    await testSsksTMR
}

func ssksPasswordTests(testCredentials: TestCredentials) async {
    let rand = generateRandomString(length: 10)
    let userId = "user-\(rand)"
    let userPassword = userId
    let userIdentity = userId.data(using: .utf8)!
    
    let ssksPassword = SealdSsksPasswordPlugin(ssksURL: testCredentials.ssksUrl, appId: testCredentials.ssksBackendAppId)
    
    try! await ssksPassword.saveIdentityAsync(withUserId: userId, password: userPassword, identity: userIdentity)
    let retrieveResp = try! await ssksPassword.retrieveIdentityAsync(withUserId: userId, password: userPassword)
    assert(retrieveResp == userIdentity)
    
    let newPassword = "another password"
    try! await ssksPassword.changeIdentityPasswordAsync(withUserId: userId, currentPassword: userPassword, newPassword: newPassword)
    do {
        try await ssksPassword.retrieveIdentityAsync(withUserId: userId, password: userPassword)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("ssks password cannot find identity with this id/password combination"))
    }
    let retrieveRespNewPassword = try! await ssksPassword.retrieveIdentityAsync(withUserId: userId, password: newPassword)
    assert(retrieveRespNewPassword == userIdentity)
    
    // Test with raw keys
    let rawStorageKey = generateRandomString(length: 32);
    let rawEncryptionKey = generateRandomString(length: 64).data(using: .utf8)!
    
    try! await ssksPassword.saveIdentityAsync(withUserId: userId, rawStorageKey: rawStorageKey, rawEncryptionKey: rawEncryptionKey, identity: userIdentity)
    let retrieveRespRawKeys = try! await ssksPassword.retrieveIdentityAsync(withUserId: userId, rawStorageKey: rawStorageKey, rawEncryptionKey: rawEncryptionKey)
    assert(retrieveRespRawKeys == userIdentity)
    
    let emptyData = Data.init()
    try! await ssksPassword.saveIdentityAsync(withUserId: userId, rawStorageKey: rawStorageKey, rawEncryptionKey: rawEncryptionKey, identity: emptyData)

    do {
        try await ssksPassword.retrieveIdentityAsync(withUserId: userId, rawStorageKey: rawStorageKey, rawEncryptionKey: rawEncryptionKey)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("ssks password cannot find identity with this id/password combination"))
    }
}

func ssksTMRTests(testCredentials: TestCredentials) async {
    let ssksBackend = SSKSBackend(keyStorageURL: testCredentials.ssksUrl, appId: testCredentials.ssksBackendAppId, appKey: testCredentials.ssksBackendAppKey)
    
    let rawTMRSymKey = generateRandomString(length: 64).data(using: .utf8)!
    
    let rand = generateRandomString(length: 10)
    let userId = "user-\(rand)"
    let userEM = "user-\(rand)@test.com"
    let userIdentity = generateRandomByteArray(length: 10)

    let authFactor = SealdSsksAuthFactor(value: userEM, type: "EM")

    let authSession = try! await ssksBackend.challengeSend(userId: userId, authFactor: authFactor, createUser: true, forceAuth: true)
    
    let ssksTMR = SealdSsksTMRPlugin(ssksURL: testCredentials.ssksUrl, appId: testCredentials.ssksBackendAppId)
    
    try! await ssksTMR.saveIdentityAsync(authSession.session_id, authFactor: authFactor, challenge: testCredentials.ssksTMRChallenge, rawTMRSymKey: rawTMRSymKey, identity: userIdentity)
    
    let retrieveResp = try! await ssksTMR.retrieveIdentityAsync(authSession.session_id, authFactor: authFactor, challenge: testCredentials.ssksTMRChallenge, rawTMRSymKey: rawTMRSymKey)
    assert(!retrieveResp.shouldRenewKey)
    assert(retrieveResp.identity == userIdentity)
    
    // If initial key has been saved without being fully authenticated, you should renew the user's private key, and save it again.
    // sdk.renewKeys(Duration.ofDays(365 * 5))

    let identitySecondKey =  generateRandomByteArray(length: 10) // should be the result of: sdk.exportIdentity()
    try! await ssksTMR.saveIdentityAsync(authSession.session_id, authFactor: authFactor, challenge: testCredentials.ssksTMRChallenge, rawTMRSymKey: rawTMRSymKey, identity: identitySecondKey)
    let secondChallenge = try! await ssksBackend.challengeSend(userId: userId, authFactor: authFactor, createUser: true, forceAuth: true)
    assert(secondChallenge.must_authenticate)
    let retrievedSecondKey = try! await ssksTMR.retrieveIdentityAsync(secondChallenge.session_id, authFactor: authFactor, challenge: testCredentials.ssksTMRChallenge, rawTMRSymKey: rawTMRSymKey)
    assert(!retrievedSecondKey.shouldRenewKey)
    assert(retrievedSecondKey.identity == identitySecondKey)

    let ssksTMRInst2 = SealdSsksTMRPlugin(ssksURL: testCredentials.ssksUrl, appId: testCredentials.ssksBackendAppId)
    let thirdChallenge = try! await ssksBackend.challengeSend(userId: userId, authFactor: authFactor, createUser: true, forceAuth: true)
    assert(thirdChallenge.must_authenticate)
    let inst2Retrieve = try! await ssksTMRInst2.retrieveIdentityAsync(thirdChallenge.session_id, authFactor: authFactor, challenge: testCredentials.ssksTMRChallenge, rawTMRSymKey: rawTMRSymKey)
    assert(!inst2Retrieve.shouldRenewKey)
    assert(inst2Retrieve.identity == identitySecondKey)
}

func sdkTests(testCredentials: TestCredentials) async {
    // Seald account infos:
    // First step with Seald: https://docs.seald.io/en/sdk/guides/1-quick-start.html
    // Create a team here: https://www.seald.io/create-sdk

    
    // The Seald SDK uses a local database that will persist on disk.
    // When instantiating a SealdSDK, it is highly recommended to set a symmetric key to encrypt this database.
    // This demo will use a fixed key. It should be generated at signup, and retrieved from your backend at login.
    let databaseEncryptionKeyB64 = "V4olGDOE5bAWNa9HDCvOACvZ59hUSUdKmpuZNyl1eJQnWKs5/l+PGnKUv4mKjivL3BtU014uRAIF2sOl83o6vQ"
    
    // Find database Path
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    let sealdDir = "\(documentsDirectory)/seald-swift"
    
    // Delete local database from previous run
    let fileManager = FileManager.default
    try? fileManager.removeItem(atPath: sealdDir)
    
    // Seald uses JWT to manage licenses and identity.
    // JWTs should be generated by your backend, and sent to the user at signup.
    // The JWT secretId and secret can be generated from your administration dashboard. They should NEVER be on client side.
    // However, as this is a demo without a backend, we will use them on the frontend.
    // JWT documentation: https://docs.seald.io/en/sdk/guides/jwt.html
    // identity documentation: https://docs.seald.io/en/sdk/guides/4-identities.html
    let jwtBuilder = JWTBuilder(JWTSharedSecretId: testCredentials.JWTSharedSecretId, JWTSharedSecret: testCredentials.JWTSharedSecret)

    
    // let's instantiate 3 SealdSDK. They will correspond to 3 users that will exchange messages.
    let sdk1 = try! SealdSdk.init(apiUrl: testCredentials.apiURL, appId: testCredentials.appId, dbPath: "\(sealdDir)/sdk1", dbb64SymKey: databaseEncryptionKeyB64, instanceName: "User1", logLevel: -1, logNoColor: true, encryptionSessionCacheTTL: 0, keySize: 4096)
    let sdk2 = try! SealdSdk.init(apiUrl: testCredentials.apiURL, appId: testCredentials.appId, dbPath: "\(sealdDir)/sdk2", dbb64SymKey: databaseEncryptionKeyB64, instanceName: "User2", logLevel: -1, logNoColor: true, encryptionSessionCacheTTL: 0, keySize: 4096)
    let sdk3 = try! SealdSdk.init(apiUrl: testCredentials.apiURL, appId: testCredentials.appId, dbPath: "\(sealdDir)/sdk3", dbb64SymKey: databaseEncryptionKeyB64, instanceName: "User3", logLevel: -1, logNoColor: true, encryptionSessionCacheTTL: 0, keySize: 4096)
    
    // retrieve info about current user before creating a user should return null
    let retrieveNoAccount = sdk1.getCurrentAccountInfo()
    assert(retrieveNoAccount?.deviceId == nil)

    
    // Create the 3 accounts. Again, the signupJWT should be generated by your backend
    let user1AccountInfo = try! await sdk1.createAccountAsync(withSignupJwt: jwtBuilder.signupJWT(), deviceName: "MyDeviceName", displayName: "User1", expireAfter: 5 * 365 * 24 * 60 * 60)
    let user2AccountInfo = try! await sdk2.createAccountAsync(withSignupJwt: jwtBuilder.signupJWT(), deviceName: "MyDeviceName", displayName: "User2", expireAfter: 5 * 365 * 24 * 60 * 60)
    let user3AccountInfo = try! await sdk3.createAccountAsync(withSignupJwt: jwtBuilder.signupJWT(), deviceName: "MyDeviceName", displayName: "User3", expireAfter: 5 * 365 * 24 * 60 * 60)

    // retrieve info about current user:
    let retrieveAccountInfo = await sdk1.getCurrentAccountInfoAsync()
    assert(retrieveAccountInfo != nil)
    assert(retrieveAccountInfo?.userId == user1AccountInfo.userId)
    assert(retrieveAccountInfo?.deviceId == user1AccountInfo.deviceId)
    
    // Create group: https://docs.seald.io/sdk/guides/5-groups.html
    let groupName = "group-1"
    let groupMembers = [user1AccountInfo.userId]
    let groupAdmins = [user1AccountInfo.userId]
    let groupId = try! await sdk1.createGroupAsync(withGroupName: groupName, members: groupMembers, admins: groupAdmins)
    
    // Manage group members and admins
    try! await sdk1.addGroupMembersAsync(withGroupId: groupId, membersToAdd: [user2AccountInfo.userId], adminsToSet: []) // Add user2 as group member
    try! await sdk1.addGroupMembersAsync(withGroupId: groupId, membersToAdd: [user3AccountInfo.userId], adminsToSet: [user3AccountInfo.userId]) // user1 adds user3 as group member and group admin
    try! await sdk3.removeGroupMembersAsync(withGroupId: groupId, membersToRemove: [user2AccountInfo.userId]) // user3 can remove user2
    try! await sdk3.setGroupAdminsAsyncWithGroupId(groupId, addToAdmins: [], removeFromAdmins: [user1AccountInfo.userId]) // user3 can remove user1 from admins
    
    // Create encryption session: https://docs.seald.io/sdk/guides/6-encryption-sessions.html
    let recipients = [user1AccountInfo.userId, user2AccountInfo.userId, groupId]
    let es1SDK1 = try! await sdk1.createEncryptionSessionAsync(withRecipients: recipients, useCache: true) // user1, user2, and group as recipients

    // The SealdEncryptionSession object can encrypt and decrypt for user1
    let initialString = "a message that needs to be encrypted!"
    let encryptedMessage = try! await es1SDK1.encryptMessageAsync(initialString)
    let decryptedMessage = try! await es1SDK1.decryptMessageAsync(encryptedMessage)
    assert(initialString == decryptedMessage)

    // user1 can retrieve the EncryptionSession from the encrypted message
    let es1SDK1RetrieveFromMess = try! await sdk1.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: true)
    let decryptedMessageFromMess = try! await es1SDK1RetrieveFromMess.decryptMessageAsync(encryptedMessage)
    assert(initialString == decryptedMessageFromMess)
    
    // Create a test file on disk that we will encrypt/decrypt
    let filename = "testfile.txt"
    let fileContent = "File clear data."
    let filePath = "\(sealdDir)/\(filename)"
    try! fileContent.write(toFile: filePath, atomically: true, encoding: .utf8)

    // Encrypt the test file. Resulting file will be written alongside the source file, with `.seald` extension added
    let encryptedFileURI = try! await es1SDK1.encryptFileAsync(fromURI: filePath)
    
    // User1 can retrieve the encryptionSession directly from the encrypted file
    let es1SDK1FromFile = try! await sdk1.retrieveEncryptionSessionAsync(fromFile: encryptedFileURI, useCache: true)
    
    // The retrieved session can decrypt the file.
    // The decrypted file will be named with the name it had at encryption. Any renaming of the encrypted file will be ignored.
    // NOTE: In this example, the decrypted file will have `(1)` suffix to avoid overwriting the original clear file.
    let decryptedFileURI = try! await es1SDK1FromFile.decryptFileAsync(fromURI: encryptedFileURI)
    assert(decryptedFileURI.hasSuffix("testfile (1).txt"))
    let decryptedFileContent = try! String(contentsOfFile: decryptedFileURI, encoding: .utf8)
    assert(fileContent == decryptedFileContent)

    // user2 and user3 can retrieve the encryptionSession (from the encrypted message or the session ID).
    let es1SDK2 = try! await sdk2.retrieveEncryptionSessionAsync(withSessionId: es1SDK1.sessionId, useCache: true)
    let decryptedMessageSDK2 = try! await es1SDK2.decryptMessageAsync(encryptedMessage)
    assert(initialString == decryptedMessageSDK2)

    let es1SDK3FromGroup = try! await sdk3.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: true)
    let decryptedMessageSDK3 = try! await es1SDK3FromGroup.decryptMessageAsync(encryptedMessage)
    assert(initialString == decryptedMessageSDK3)

    // user3 removes all members of "group-1". A group without member is deleted.
    try! await sdk3.removeGroupMembersAsync(withGroupId: groupId, membersToRemove: [user1AccountInfo.userId, user3AccountInfo.userId])

    // user3 could retrieve the previous encryption session only because "group-1" was set as recipient.
    // As the group was deleted, it can no longer access it.
    // user3 still has the encryption session in its cache, but we can disable it.
    do {
        let _ = try await sdk3.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: false)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("status: 404"))
    }
    
    // user2 adds user3 as recipient of the encryption session.
    let respAdd = try! await es1SDK2.addRecipientsAsync([user3AccountInfo.userId])
    assert(respAdd.count == 1)
    assert((respAdd[user3AccountInfo.deviceId]!).success)

    // user3 can now retrieve it.
    let es1SDK3 = try! await sdk3.retrieveEncryptionSessionAsync(withSessionId: es1SDK1.sessionId, useCache: false)
    let decryptedMessageAfterAdd = try! await es1SDK3.decryptMessageAsync(encryptedMessage)
    assert(initialString == decryptedMessageAfterAdd)

    // user1 revokes user3 from the encryption session.
    // TODO: used to be user2 instead of user1 which does the revoke, but not possible until https://gitlab.tardis.seald.io/seald/go-seald-sdk/-/issues/83
    let respRevoke = try! await es1SDK1.revokeRecipientsAsync([user3AccountInfo.userId])
    assert(respRevoke.count == 1)
    assert((respRevoke[user3AccountInfo.userId]!).success)

    // user3 cannot retrieve the session anymore
    do {
        let _ = try await sdk3.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: false)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("status: 404"))
    }

    // user1 revokes all other recipients from the session
    let respRevokeOther = try! await es1SDK1.revokeOthersAsync()
    assert(respRevokeOther.count == 2) // revoke user2 and group
    assert((respRevokeOther[groupId]!).success)
    assert((respRevokeOther[user2AccountInfo.userId]!).success)

    // user2 cannot retrieve the session anymore
    do {
        let _ = try await sdk2.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: false)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("status: 404"))
    }

    // user1 revokes all. It can no longer retrieve it.
    let respRevokeAll = try! await es1SDK1.revokeAllAsync()
    assert(respRevokeAll.count == 1)
    assert(respRevokeAll[user1AccountInfo.userId]!.success)

    do {
        let _ = try await sdk1.retrieveEncryptionSessionAsync(fromMessage: encryptedMessage, useCache: false)
        assert(false, "expected error")
    } catch {
        assert(error.localizedDescription.contains("status: 404"))
    }
    
    // Create additional data for user1
    let es2SDK1 = try! await sdk1.createEncryptionSessionAsync(withRecipients: [user1AccountInfo.userId], useCache: true)
    let anotherMessage = "nobody should read that!"
    let secondEncryptedMessage = try! await es2SDK1.encryptMessageAsync(anotherMessage)

    // user1 can renew its key, and still decrypt old messages
    try! sdk1.renewKeysWithExpire(after: TimeInterval( 5 * 365 * 24 * 60 * 60))
    let es2SDK1AfterRenew = try! await sdk1.retrieveEncryptionSessionAsync(withSessionId: es2SDK1.sessionId, useCache: false)
    let decryptedMessageAfterRenew = try! await es2SDK1AfterRenew.decryptMessageAsync(secondEncryptedMessage)
    assert(anotherMessage == decryptedMessageAfterRenew)

    // CONNECTORS https://docs.seald.io/en/sdk/guides/jwt.html#adding-a-userid

    // we can add a custom userId using a JWT
    let customConnectorJWTValue = "user1-custom-id"
    let addConnectorJWT = jwtBuilder.connectorJWT(customUserId: customConnectorJWTValue, appId: testCredentials.appId)
    try! await sdk1.pushJWTAsync(withJWT: addConnectorJWT)

    // we can list a user connectors
    let connectors = try! await sdk1.listConnectorsAsync()
    assert(connectors.count == 1)
    assert(connectors[0].state == "VO")
    assert(connectors[0].type == "AP")
    assert(connectors[0].sealdId == user1AccountInfo.userId)
    assert(connectors[0].value == "\(customConnectorJWTValue)@\(testCredentials.appId)")

    // Retrieve connector by its id
    let retrieveConnector = try! await sdk1.retrieveConnectorAsync(withConnectorId: connectors[0].connectorId)
    assert(retrieveConnector.sealdId == user1AccountInfo.userId)
    assert(retrieveConnector.state == "VO")
    assert(retrieveConnector.type == "AP")
    assert(retrieveConnector.value == "\(customConnectorJWTValue)@\(testCredentials.appId)")

    // Retrieve connectors from a user id.
    let connectorsFromSealdId = try! await sdk1.getConnectorsAsyncFromSealdId(sealdId: user1AccountInfo.userId)
    assert(connectorsFromSealdId.count == 1)
    assert(connectorsFromSealdId[0].state == "VO")
    assert(connectorsFromSealdId[0].type == "AP")
    assert(connectorsFromSealdId[0].sealdId == user1AccountInfo.userId)
    assert(connectorsFromSealdId[0].value == "\(customConnectorJWTValue)@\(testCredentials.appId)")

    // Get sealdId of a user from a connector
    let sealdIds = try! await sdk2.getSealdIdsAsyncFromConnectors(connectorTypeValues: [SealdConnectorTypeValue(type: "AP", value: "\(customConnectorJWTValue)@\(testCredentials.appId)")])
    assert(sealdIds.count == 1)
    assert(sealdIds[0] == user1AccountInfo.userId)

    // user1 can remove a connector
    try! await sdk1.removeConnectorAsync(withConnectorId: connectors[0].connectorId)

    // verify that only one connector left
    let connectorListAfterRevoke = try! await sdk1.listConnectorsAsync()
    assert(connectorListAfterRevoke.count == 0)

    // user1 can export its identity
    let exportIdentity = try! await sdk1.exportIdentityAsync()

    // We can instantiate a new SealdSDK, import the exported identity
    let sdk1Exported = try! SealdSdk(apiUrl: testCredentials.apiURL, appId: testCredentials.appId, dbPath: "\(sealdDir)/sdk1Exported", dbb64SymKey: databaseEncryptionKeyB64, instanceName: "sdk1Exported", logLevel: -1, logNoColor: true, encryptionSessionCacheTTL: TimeInterval( 5 * 365 * 24 * 60 * 60), keySize: 4096)
    try! await sdk1Exported.importIdentityAsync(withIdentity: exportIdentity)

    // SDK with imported identity can decrypt
    let es2SDK1Exported = try! await sdk1Exported.retrieveEncryptionSessionAsync(fromMessage: secondEncryptedMessage, useCache: true)
    let clearMessageExportedIdentity = try! await es2SDK1Exported.decryptMessageAsync(secondEncryptedMessage)
    assert(anotherMessage == clearMessageExportedIdentity)

    // user1 can create sub identity
    let subIdentity = try! await sdk1.createSubIdentityAsync(withDeviceName: "SUB-deviceName", expireAfter: TimeInterval( 5 * 365 * 24 * 60 * 60))
    assert(subIdentity.deviceId != "")

    // first device needs to reencrypt for the new device
    try! await sdk1.massReencryptAsync(withDeviceId: subIdentity.deviceId, options: SealdMassReencryptOptions())
    // We can instantiate a new SealdSDK, import the sub-device identity
    let sdk1SubDevice = try! SealdSdk(apiUrl: testCredentials.apiURL, appId: testCredentials.appId, dbPath: "\(sealdDir)/sdk1SubDevice", dbb64SymKey: databaseEncryptionKeyB64, instanceName: "sdk1SubDevice", logLevel: -1, logNoColor: true, encryptionSessionCacheTTL: TimeInterval( 5 * 365 * 24 * 60 * 60), keySize: 4096)
    try! await sdk1SubDevice.importIdentityAsync(withIdentity: subIdentity.backupKey)

    // sub device can decrypt
    let es2SDK1SubDevice = try! await sdk1SubDevice.retrieveEncryptionSessionAsync(fromMessage: secondEncryptedMessage, useCache: false)
    let clearMessageSubdIdentity = try! await es2SDK1SubDevice.decryptMessageAsync(secondEncryptedMessage)
    assert(anotherMessage == clearMessageSubdIdentity)

    // users can send heartbeat
    try! await sdk1.heartbeatAsync()

    // close SDKs
    try! await sdk1.closeAsync()
    try! await sdk2.closeAsync()
    try! await sdk3.closeAsync()
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
            .task{
                await runTests()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
