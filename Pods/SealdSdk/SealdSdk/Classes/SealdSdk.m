//
//  SealdSdk.m
//  SealdSdk
//
//  Created by Mehdi Kouhen on 22/02/2023.
//  Copyright © 2023 Seald SAS. All rights reserved.
//

#import "SealdSdk.h"

@implementation SealdSdk
-(instancetype) initWithApiUrl:(NSString*)apiUrl
                         appId:(NSString*)appId
                        dbPath:(NSString*)dbPath
                   dbb64SymKey:(NSString*)dbb64SymKey
                  instanceName:(NSString*)instanceName
                      logLevel:(NSInteger)logLevel
                    logNoColor:(BOOL)logNoColor
     encryptionSessionCacheTTL:(NSTimeInterval)encryptionSessionCacheTTL
                       keySize:(NSInteger)keySize
                         error:(NSError**)error
{
    if (keySize == 0){
        keySize = 4096;
    }
    self = [super init];
    if (self) {
        SealdSdkInternalsMobile_sdkInitializeOptions* initOpts = [[SealdSdkInternalsMobile_sdkInitializeOptions alloc] init];
        initOpts.apiURL = apiUrl;
        initOpts.appId = appId;
        initOpts.dbPath = dbPath;
        initOpts.databaseEncryptionKeyB64 = dbb64SymKey;
        initOpts.instanceName = instanceName;
        initOpts.logLevel = logLevel;
        initOpts.logNoColor = logNoColor;
        initOpts.encryptionSessionCacheTTL = (int64_t)(encryptionSessionCacheTTL * 1000);
        initOpts.keySize = keySize;
        
        sdkInstance = SealdSdkInternalsMobile_sdkInitialize(initOpts, error);
        if (*error != nil)
        {
            return nil;
        }
    }
    return self;
}

-(void) closeWithError:(NSError**)error
{
    [sdkInstance close:error];
}

// Account
-(SealdAccountInfo*) createAccountWithSignupJwt:(NSString*)signupJwt
                                     deviceName:(NSString*)deviceName
                                    displayName:(NSString*)displayName
                                    expireAfter:(NSTimeInterval)expireAfter
                                          error:(NSError**)error
{
    if (expireAfter == 0){
        expireAfter = 5 * 365 * 24 * 60 * 60;
    }
    SealdSdkInternalsMobile_sdkCreateAccountOptions* createAccountOpts = [[SealdSdkInternalsMobile_sdkCreateAccountOptions alloc] init];
    createAccountOpts.signupJWT = signupJwt;
    createAccountOpts.deviceName = deviceName;
    createAccountOpts.displayName = displayName;
    createAccountOpts.expireAfter = (int64_t)(expireAfter * 1000);

    SealdSdkInternalsMobile_sdkAccountInfo* accountInfo = [sdkInstance createAccount:createAccountOpts error:error];
    if (*error != nil)
    {
        return nil;
    }
    return [SealdAccountInfo fromMobileSdk:accountInfo];
}

-(SealdAccountInfo*) getCurrentAccountInfo
{
    SealdSdkInternalsMobile_sdkAccountInfo* accountInfo = [sdkInstance getCurrentAccountInfo];
    return [SealdAccountInfo fromMobileSdk:accountInfo];
}

-(void) renewKeysWithExpireAfter:(NSTimeInterval)expireAfter
                           error:(NSError**)error
{
    if (expireAfter == 0){
        expireAfter = 5 * 365 * 24 * 60 * 60;
    }
    [sdkInstance renewKeys:(int64_t)(expireAfter * 1000) error:error];
}

- (SealdCreateSubIdentityResponse*) createSubIdentityWithDeviceName:(NSString*)deviceName
                                                        expireAfter:(NSTimeInterval)expireAfter
                                                              error:(NSError**)error
{
    if (expireAfter == 0){
        expireAfter = 5 * 365 * 24 * 60 * 60;
    }
    SealdSdkInternalsMobile_sdkCreateSubIdentityOptions* createSubIdentityOpts = [[SealdSdkInternalsMobile_sdkCreateSubIdentityOptions alloc] init];
    createSubIdentityOpts.deviceName = deviceName;
    createSubIdentityOpts.expireAfter = (int64_t)(expireAfter * 1000);

    NSError* sdkError;
    SealdSdkInternalsMobile_sdkCreateSubIdentityResponse* createSubIdentityResponse = [sdkInstance createSubIdentity:createSubIdentityOpts error:&sdkError];
    if (sdkError) {
        *error = sdkError;
        return nil;
    }
    return [[SealdCreateSubIdentityResponse alloc] initWithDeviceId:createSubIdentityResponse.deviceId backupKey:createSubIdentityResponse.backupKey];
}

- (void) importIdentity:(NSData*)identity
                  error:(NSError**)error
{
    [sdkInstance importIdentity:identity error:error];
}

- (NSData*) exportIdentityWithError:(NSError**)error
{
    return [sdkInstance exportIdentity:error];
}

- (void) pushJWT:(NSString*)jwt
           error:(NSError**)error
{
    [sdkInstance pushJWT:jwt error:error];
}

- (void) heartbeatWithError:(NSError**)error
{
    [sdkInstance heartbeat:error];
}

// Groups
-(NSString*) createGroup:(NSString*)groupName
                 members:(NSArray<NSString*>*)members
                  admins:(NSArray<NSString*>*)admins
                   error:(NSError**)error
{
    NSString* id = [sdkInstance createGroup:groupName members:arrayToStringArray(members) admins:arrayToStringArray(admins) error:error];
    return id;
}

- (void) addGroupMembersWithGroupId:(NSString*)groupId
                       membersToAdd:(NSArray<NSString*>*)membersToAdd
                        adminsToSet:(NSArray<NSString*>*)adminsToSet
                              error:(NSError**)error
{
    [sdkInstance addGroupMembers:groupId membersToAdd:arrayToStringArray(membersToAdd) adminsToSet:arrayToStringArray(adminsToSet) error:error];
}

- (void) removeGroupMembersWithGroupId:(NSString*)groupId
                       membersToRemove:(NSArray<NSString*>*)membersToRemove
                                 error:(NSError**)error
{
    [sdkInstance removeGroupMembers:groupId membersToRemove:arrayToStringArray(membersToRemove) error:error];
}

- (void) renewGroupKeyWithGroupId:(NSString*)groupId
                            error:(NSError**)error
{
    [sdkInstance renewGroupKey:groupId error:error];
}

- (void) setGroupAdminsWithGroupId:(NSString*)groupId
                       addToAdmins:(NSArray<NSString*>*)addToAdmins
                  removeFromAdmins:(NSArray<NSString*>*)removeFromAdmins
                             error:(NSError**)error
{
    [sdkInstance setGroupAdmins:groupId addToAdmins:arrayToStringArray(addToAdmins) removeFromAdmins:arrayToStringArray(removeFromAdmins) error:error];
}

// EncryptionSession
- (SealdEncryptionSession*) createEncryptionSessionWithRecipients:(NSArray<NSString*>*)recipients
                                                         useCache:(BOOL)useCache
                                                            error:(NSError**)error
{
    NSError* createError = nil;
    SealdSdkInternalsMobile_sdkMobileEncryptionSession* es = [sdkInstance createEncryptionSession:arrayToStringArray(recipients) useCache:useCache error:&createError];
    if (createError) {
        *error = createError;
        return nil;
    }
    return [[SealdEncryptionSession alloc] initWithEncryptionSession:es];
}

- (SealdEncryptionSession*) retrieveEncryptionSessionWithSessionId:(NSString*)sessionId
                                                          useCache:(BOOL)useCache
                                                             error:(NSError**)error
{
    NSError* retrieveError = nil;
    SealdSdkInternalsMobile_sdkMobileEncryptionSession* es = [sdkInstance retrieveEncryptionSession:sessionId useCache:useCache error:&retrieveError];
    if (retrieveError) {
        *error = retrieveError;
        return nil;
    }
    return [[SealdEncryptionSession alloc] initWithEncryptionSession:es];
}

- (SealdEncryptionSession*) retrieveEncryptionSessionFromMessage:(NSString*)message
                                                        useCache:(BOOL)useCache
                                                           error:(NSError**)error
{
    NSError* retrieveError = nil;
    SealdSdkInternalsMobile_sdkMobileEncryptionSession* es = [sdkInstance retrieveEncryptionSessionFromMessage:message useCache:useCache error:&retrieveError];
    if (retrieveError) {
        *error = retrieveError;
        return nil;
    }
    return [[SealdEncryptionSession alloc] initWithEncryptionSession:es];
}

// Connectors
- (NSArray<NSString*>*) getSealdIdsFromConnectors:(NSArray<SealdConnectorTypeValue*>*)connectorTypeValues
                                            error:(NSError **)error
{
    NSError* getError = nil;
    SealdSdkInternalsMobile_sdkStringArray* res = [sdkInstance getSealdIdsFromConnectors:[SealdConnectorTypeValue toMobileSdkArray:connectorTypeValues] error:&getError];
    if (getError) {
        *error = getError;
        return nil;
    }
    return stringArrayToArray(res);
}

- (NSArray<SealdConnector*>*) getConnectorsFromSealdId:(NSString*)sealdId
                                            error:(NSError **)error
{
    NSError* getError = nil;
    SealdSdkInternalsMobile_sdkConnectorsArray* res = [sdkInstance getConnectorsFromSealdId:sealdId error:&getError];
    if (getError) {
        *error = getError;
        return nil;
    }
    return [SealdConnector fromMobileSdkArray:res];
}

- (SealdConnector*) addConnectorWithValue:(NSString*)value
                            connectorType:(NSString*)connectorType
                       preValidationToken:(SealdPreValidationToken*)preValidationToken
                                    error:(NSError**)error
{
    NSError* addError = nil;
    SealdSdkInternalsMobile_sdkConnector* res = [sdkInstance addConnector:value connectorType:connectorType preValidationToken:[preValidationToken toMobileSdk] error:&addError];
    if (addError) {
        *error = addError;
        return nil;
    }
    return [SealdConnector fromMobileSdk:res];
}

- (SealdConnector*) validateConnector:(NSString*)connectorId
                            challenge:(NSString*)challenge
                                error:(NSError**)error
{
    NSError* validateError = nil;
    SealdSdkInternalsMobile_sdkConnector* res = [sdkInstance validateConnector:connectorId challenge:challenge error:&validateError];
    if (validateError) {
        *error = validateError;
        return nil;
    }
    return [SealdConnector fromMobileSdk:res];
}

- (SealdConnector*) removeConnector:(NSString*)connectorId
                              error:(NSError**)error
{
    NSError* removeError = nil;
    SealdSdkInternalsMobile_sdkConnector* res = [sdkInstance removeConnector:connectorId error:&removeError];
    if (removeError) {
        *error = removeError;
        return nil;
    }
    return [SealdConnector fromMobileSdk:res];
}

- (NSArray<SealdConnector*>*) listConnectorsWithError:(NSError**)error
{
    NSError* listError = nil;
    SealdSdkInternalsMobile_sdkConnectorsArray* res = [sdkInstance listConnectors:&listError];
    if (listError) {
        *error = listError;
        return nil;
    }
    return [SealdConnector fromMobileSdkArray:res];
}

- (SealdConnector*) retrieveConnector:(NSString*)connectorId
                                error:(NSError**)error
{
    NSError* retrieveError = nil;
    SealdSdkInternalsMobile_sdkConnector* res = [sdkInstance retrieveConnector:connectorId error:&retrieveError];
    if (retrieveError) {
        *error = retrieveError;
        return nil;
    }
    return [SealdConnector fromMobileSdk:res];
}

// Reencrypt
- (SealdMassReencryptResponse*) massReencryptWithDeviceId:(NSString*)deviceId
                                                  options:(SealdMassReencryptOptions*)options
                                                    error:(NSError**)error
{
    SealdSdkInternalsMobile_sdkMassReencryptOptions *mobileOptions = options != nil ? [options toMobileSdk] : [[SealdMassReencryptOptions new] toMobileSdk];
    
    NSError* reencryptError = nil;
    SealdSdkInternalsMobile_sdkMassReencryptResponse *mobileResponse = [sdkInstance massReencrypt:deviceId options:mobileOptions error:&reencryptError];
    if (reencryptError) {
        *error = reencryptError;
        return nil;
    }
    return [SealdMassReencryptResponse fromMobileSdk:mobileResponse];
}

- (NSArray<SealdDeviceMissingKeys*>*) devicesMissingKeysWithForceLocalAccountUpdate:(BOOL)forceLocalAccountUpdate
                                                                              error:(NSError**)error
{
    NSError* devicesMissingKeysError = nil;
    SealdSdkInternalsMobile_sdkDevicesMissingKeysArray *mobileResponse = [sdkInstance devicesMissingKeys:forceLocalAccountUpdate error:&devicesMissingKeysError];
    if (devicesMissingKeysError) {
        *error = devicesMissingKeysError;
        return nil;
    }
    return [SealdDeviceMissingKeys fromMobileSdkArray:mobileResponse];
}
@end
