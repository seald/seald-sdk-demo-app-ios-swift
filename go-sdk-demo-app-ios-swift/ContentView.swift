//
//  ContentView.swift
//  go-sdk-demo-app-ios-swift
//
//  Created by Mehdi Kouhen on 28/02/2023.
//

import SwiftUI
import SealdSdk
import JWT

func runTests() {
    print("SDK DEMO START")
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    let sealdDir = "\(documentsDirectory)/seald-swift"
    
    print("Removing existing database...")
    let fileManager = FileManager.default
    try? fileManager.removeItem(atPath: sealdDir)
    print("Seald Database removed successfully")
    
    let seald = try! SealdSdk.init(apiUrl: "https://api-dev.soyouz.seald.io/", appId: "00000000-0000-1000-a000-7ea300000018", dbPath: sealdDir, dbb64SymKey: "V4olGDOE5bAWNa9HDCvOACvZ59hUSUdKmpuZNyl1eJQnWKs5/l+PGnKUv4mKjivL3BtU014uRAIF2sOl83o6vQ", instanceName: "seald-sdk-swift", logLevel: 255, encryptionSessionCacheTTL: 0, keySize: 0)
    
    let JWTSharedSecretId = "00000000-0000-1000-a000-7ea300000019"
    let JWTSharedSecret = "o75u89og9rxc9me54qxaxvdutr2t4t25ozj4m64utwemm0osld0zdb02j7gv8t7x"
    let algorithm = JWTAlgorithmFactory.algorithm(byName: "HS256")

    let now = Date()
    let exp = Calendar.current.date(byAdding: .day, value: 30, to: now)!

    let headers = ["typ" : "JWT"]
    let payload = ["iss" : JWTSharedSecretId,
                   "iat" : NSNumber(value: now.timeIntervalSince1970),
                   "exp" : NSNumber(value: exp.timeIntervalSince1970),
                   "join_team": true,
                   "scopes":"-1"] as [String : Any]
    let token = JWT.encodePayload(payload, withSecret: JWTSharedSecret, withHeaders: headers, algorithm: algorithm)
    print("JWT \(String(describing: token))")

    let userId = try! seald.createAccount(token, deviceName: "MyDeviceName", displayName: "MyName")
    print("userId \(userId)")

    let members = [userId]
    let groupId = try? seald.createGroup("amzingGroupName", members: members, admins: members) // TODO: try!
    print("groupId \(groupId)")

    let es1SDK1 = try! seald.createEncryptionSession(members, useCache: true)

    let encryptedMessage = try! es1SDK1.encryptMessage("coucou")
    print("encryptedMessage \(encryptedMessage)")

    let decryptedMessage = try! es1SDK1.decryptMessage(encryptedMessage)
    print("decryptedMessage \(decryptedMessage)")
    
    print("SDK DEMO END")
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear{
                runTests()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
