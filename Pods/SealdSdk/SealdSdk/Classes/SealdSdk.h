//
//  SealdSdk.h
//  SealdSdk
//
//  Created by Mehdi Kouhen on 22/02/2023.
//  Copyright © 2023 Seald SAS. All rights reserved.
//

#ifndef SealdSdk_h
#define SealdSdk_h

#import <SealdSdkInternals/SealdSdkInternals.h>
#import "Helpers.h"
#import "SealdEncryptionSession.h"

/**
 * This is the main class for the Seald SDK. It represents an instance of the Seald SDK.
 */
@interface SealdSdk : NSObject{
    SealdSdkInternalsMobile_sdkMobileSDK* sdkInstance;
}
/**
 * Initialize this Seald SDK Instance.
 * @param apiUrl The Seald server for this instance to use. This value is given on your Seald dashboard.
 * @param appId The ID given by the Seald server to your app. This value is given on your Seald dashboard.
 * @param dbPath The path where to store the local Seald database.
 * @param dbb64SymKey The encryption key with which to encrypt the local Seald database. This **must** be the Base64 string encoding of a cryptographically random buffer of 64 bytes.
 * @param instanceName An arbitrary name to give to this Seald instance. Can be useful for debugging when multiple instances are running in parallel, as it is added to logs.
 * @param logLevel The minimum level of logs you want. All logs of this level or above will be displayed. `-1`: Trace; `0`: Debug; `1`: Info; `2`: Warn; `3`: Error; `4`: Fatal; `5`: Panic; `6`: NoLevel; `7`: Disabled.
 * @param logNoColor Should be set to `NO` if you want to enable colors in the log output, `YES` if you don't.
 * @param encryptionSessionCacheTTL The duration of cache lifetime in seconds. `-1` to cache forever. Default to `0` (no cache).
 * @param keySize The Asymmetric key size for newly generated keys. Defaults to 4096. Warning: for security, it is extremely not recommended to lower this value.
 * @param error Error pointer.
 */
-(instancetype) initWithApiUrl:(NSString*)apiUrl
                         appId:(NSString*)appId
                        dbPath:(NSString*)dbPath
                   dbb64SymKey:(NSString*)dbb64SymKey
                  instanceName:(NSString*)instanceName
                      logLevel:(NSInteger)logLevel
                    logNoColor:(BOOL)logNoColor
     encryptionSessionCacheTTL:(NSTimeInterval)encryptionSessionCacheTTL
                       keySize:(NSInteger)keySize
                         error:(NSError**)error;
/**
 * Close the current SDK instance. This frees any lock on the current database. After calling close, the instance cannot be used anymore.
 * @param error Error pointer.
 */
-(void) closeWithError:(NSError**)error;

// Account
/**
 * Create a new Seald SDK Account for this Seald SDK instance.
 * This function can only be called if the current SDK instance does not have an account yet.
 * @param signupJwt The JWT to allow this SDK instance to create an account.
 * @param deviceName A name for the device to create. This is metadata, useful on the Seald Dashboard for recognizing this device.
 * @param displayName A name for the user to create. This is metadata, useful on the Seald Dashboard for recognizing this user.
 * @param expireAfter The duration during which the created device key will be valid without renewal, in seconds. Optional, defaults to 5 years.
 * @param error Error pointer.
 * @return An [AccountInfo] instance, containing the Seald ID of the newly created Seald user, and the device ID.
 */
-(SealdAccountInfo*) createAccountWithSignupJwt:(NSString*)signupJwt
                                     deviceName:(NSString*)deviceName
                                    displayName:(NSString*)displayName
                                    expireAfter:(NSTimeInterval)expireAfter
                                          error:(NSError**)error;
/**
 * Return information about the current account, or `nil` if there is none.
 * @return An [AccountInfo] instance, containing the Seald ID of the local Seald user, and the device ID, or `nil` if there is no local user.
 */
-(SealdAccountInfo*) getCurrentAccountInfo;
/**
 * Renew the keys of the current device, extending their validity.
 * If the current device has expired, you will need to call [renewKeys] before you are able to do anything else.
 * Warning: if the identity of the current device is stored externally, for example on SSKS,
 * you will want to re-export it and store it again, otherwise the previously stored identity will not be recognized anymore.
 * @param expireAfter The duration during which the renewed device key will be valid without further renewal, in seconds. Optional, defaults to 5 years.
 * @param error Error pointer.
 */
-(void) renewKeysWithExpireAfter:(NSTimeInterval)expireAfter
                           error:(NSError**)error;
/**
 * Create a new sub-identity, or new device, for the current user account.
 * After creating this new device, you will probably want to call -[SealdSDK massReencrypt],
 * so that the newly created device will be able to decrypt EncryptionSessions previously created for this account.
 * @param deviceName An optional name for the device to create. This is metadata, useful on the Seald Dashboard for recognizing this device. Optional.
 * @param expireAfter The duration during which the device key for the device to create will be valid without renewal. Optional, defaults to 5 years.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 * @return A CreateSubIdentityResponse instance, containing `deviceId` (the ID of the newly created device) and `backupKey` (the identity export of the newly created sub-identity).
 */
- (SealdCreateSubIdentityResponse*) createSubIdentityWithDeviceName:(NSString*)deviceName
                                                        expireAfter:(NSTimeInterval)expireAfter
                                                              error:(NSError**)error;
/**
 * Load an identity export into the current SDK instance.
 * This function can only be called if the current SDK instance does not have an account yet.
 * @param identity The identity export that this SDK instance should import.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 */
- (void) importIdentity:(NSData*)identity
                  error:(NSError**)error;
/**
 * Export the current device as an identity export.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 * @return The identity export of the current identity of this SDK instance.
 */
- (NSData*) exportIdentityWithError:(NSError**)error;
/**
 * Push a given JWT to the Seald server, for example to add a connector to the current account.
 * @param jwt The JWT to push
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 */
- (void) pushJWT:(NSString*)jwt
           error:(NSError**)error;
/**
 * Just call the Seald server, without doing anything.
 * This may be used for example to verify that the current instance has a valid identity.
 * @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 */
- (void) heartbeatWithError:(NSError**)error;

// Groups
/**
 * Create a group, and returns the created group's ID.
 * [admins] must also be members.
 * [admins] must include yourself.
 * @param groupName A name for the group. This is metadata, useful on the Seald Dashboard for recognizing this user.
 * @param members The Seald IDs of the members to add to the group. Must include yourself.
 * @param admins The Seald IDs of the members to also add as group admins. Must include yourself.
 * @return The ID of the created group.
 */
-(NSString*) createGroup:(NSString*)groupName
                 members:(NSArray<NSString*>*)members
                  admins:(NSArray<NSString*>*)admins
                   error:(NSError**)error;
/**
 * Add members to a group.
 * Can only be done by a group administrator.
 * Can also specify which of these newly added group members should also be admins.
 * @param groupId The group in which to add members.
 * @param membersToAdd The Seald IDs of the members to add to the group.
 * @param adminsToSet The Seald IDs of the newly added members to also set as group admins.
 */
- (void) addGroupMembersWithGroupId:(NSString*)groupId
                       membersToAdd:(NSArray<NSString*>*)membersToAdd
                        adminsToSet:(NSArray<NSString*>*)adminsToSet
                              error:(NSError**)error;
/**
 * Remove members from the group.
 * Can only be done by a group administrator.
 * You should call [renewGroupKey] after this.
 * @param groupId The group from which to remove members.
 * @param membersToRemove The Seald IDs of the members to remove from the group.
 */
- (void) removeGroupMembersWithGroupId:(NSString*)groupId
                       membersToRemove:(NSArray<NSString*>*)membersToRemove
                                 error:(NSError**)error;
/**
 * Renew the group's private key.
 * Can only be done by a group administrator.
 * Should be called after removing members from the group.
 * @param groupId The group for which to renew the private key.
 */
- (void) renewGroupKeyWithGroupId:(NSString*)groupId
                            error:(NSError**)error;
/**
 * Add some existing group members to the group admins, and/or removes admin status from some existing group admins.
 * Can only be done by a group administrator.
 * @param groupId The group for which to set admins.
 * @param addToAdmins The Seald IDs of existing group members to add as group admins.
 * @param removeFromAdmins The Seald IDs of existing group members to remove from group admins.
 */
- (void) setGroupAdminsWithGroupId:(NSString*)groupId
                       addToAdmins:(NSArray<NSString*>*)addToAdmins
                  removeFromAdmins:(NSArray<NSString*>*)removeFromAdmins
                             error:(NSError**)error;

// EncryptionSession
/**
 * Create an encryption session, and returns the associated [EncryptionSession] instance,
 * with which you can then encrypt / decrypt multiple messages.
 * Warning : if you want to be able to retrieve the session later,
 * you must put your own UserId in the [recipients] argument.
 * @param recipients The Seald IDs of users who should be able to retrieve this session.
 * @param useCache Whether or not to use the cache (if enabled globally).
 * @param error The error that occurred while creating the session, if any.
 * @return The created [EncryptionSession], or null if an error occurred.
 */
- (SealdEncryptionSession*) createEncryptionSessionWithRecipients:(NSArray<NSString*>*)recipients
                                                         useCache:(BOOL)useCache
                                                            error:(NSError**)error;
/**
 * Retrieve an encryption session with the [sessionId], and returns the associated
 * [EncryptionSession] instance, with which you can then encrypt / decrypt multiple messages.
 * @param sessionId The ID of the session to retrieve.
 * @param useCache Whether or not to use the cache (if enabled globally).
 * @param error The error that occurred while retrieving the session, if any.
 * @return The retrieved [EncryptionSession], or null if an error occurred.
 */
- (SealdEncryptionSession*) retrieveEncryptionSessionWithSessionId:(NSString*)sessionId
                                                          useCache:(BOOL)useCache
                                                             error:(NSError**)error;
/**
 * Retrieve an encryption session from a seald message, and returns the associated
 * [EncryptionSession] instance, with which you can then encrypt / decrypt multiple messages.
 * @param message Any message belonging to the session to retrieve.
 * @param useCache Whether or not to use the cache (if enabled globally).
 * @param error The error that occurred while retrieving the session, if any.
 * @return The retrieved [EncryptionSession], or null if an error occurred.
 */
- (SealdEncryptionSession*) retrieveEncryptionSessionFromMessage:(NSString*)message
                                                        useCache:(BOOL)useCache
                                                           error:(NSError**)error;

// Connectors
/**
 * Get all the info for the given connectors to look for, updates the local cache of connectors,
 * and returns a slice with the corresponding SealdIds. SealdIds are not de-duped and can appear for multiple connector values.
 * If one of the connectors is not assigned to a Seald user, this will return a ErrorGetSealdIdsUnknownConnector error,
 * with the details of the missing connector.
 *
 * @param connectorTypeValues An Array of ConnectorTypeValue instances.
 * @param error An error pointer to fill in case of an error.
 * @return An Array of NSString with the Seald IDs of the users corresponding to these connectors.
 */
- (NSArray<NSString*>*) getSealdIdsFromConnectors:(NSArray<SealdConnectorTypeValue*>*)connectorTypeValues
                                            error:(NSError**)error;
/**
 * List all connectors know locally for a given sealdId.
 *
 * @param sealdId The Seald ID for which to list connectors
 * @param error An error pointer to fill in case of an error.
 * @return An Array of Connector instances.
 */
- (NSArray<SealdConnector*>*) getConnectorsFromSealdId:(NSString *)sealdId
                                                 error:(NSError**)error;
/**
 * Add a connector to the current identity.
 * If no preValidationToken is given, the connector will need to be validated before use.
 *
 * @param value The value of the connector to add.
 * @param connectorType The type of the connector.
 * @param preValidationToken Given by your server to authorize the adding of a connector.
 * @param error An error pointer to fill in case of an error.
 * @return The created Connector.
 */
- (SealdConnector*) addConnectorWithValue:(NSString*)value
                            connectorType:(NSString*)connectorType
                       preValidationToken:(SealdPreValidationToken*)preValidationToken
                                    error:(NSError**)error;
/**
 * Validate an added connector that was added without a preValidationToken.
 *
 * @param connectorId The ID of the connector to validate.
 * @param challenge The challenge.
 * @param error An error pointer to fill in case of an error.
 * @return The modified Connector.
 */
- (SealdConnector*) validateConnector:(NSString*)connectorId
                            challenge:(NSString*)challenge
                                error:(NSError**)error;
/**
 * Remove a connector belonging to the current account.
 *
 * @param connectorId The ID of the connector to remove.
 * @param error An error pointer to fill in case of an error.
 * @return The modified Connector.
 */
- (SealdConnector*) removeConnector:(NSString*)connectorId
                              error:(NSError**)error;
/**
 * List connectors associated to the current account.
 *
 * @param error An error pointer to fill in case of an error.
 * @return The array of connectors associated to the current account.
 */
- (NSArray<SealdConnector*>*) listConnectorsWithError:(NSError**)error;
/**
 * Retrieve a connector by its `connectorId`, then updates the local cache of connectors.
 *
 * @param connectorId The ID of the connector to retrieve.
 * @param error An error pointer to fill in case of an error.
 * @return The Connector.
 */
- (SealdConnector*) retrieveConnector:(NSString*)connectorId
                                error:(NSError**)error;

// Reencrypt
/**
 * Retrieve, re-encrypt, and add missing keys for a certain device.
 *
 * @param deviceId The ID of the device for which to re-rencrypt.
 * @param options A [MassReencryptOptions] instance, or `nil` to use default options.
 * @param error An `NSError` object that will be populated if an error occurs while executing the operation.
 * @return A [MassReencryptResponse] instance, containing the number of re-encrypted keys, and the number of keys for which re-encryption failed.
 */
- (SealdMassReencryptResponse*) massReencryptWithDeviceId:(NSString*)deviceId
                                                  options:(SealdMassReencryptOptions*)options
                                                    error:(NSError**)error;
/**
 * List which of the devices of the current account are missing keys,
 * so you can call [SealdSdk.massReencrypt] for them.
 *
 * @param forceLocalAccountUpdate Whether to update the local account
 * @param error If an error occurs, upon return contains an NSError object that describes the problem.
 * @return An [NSArray] of [DeviceMissingKeys] instances, containing the ID of the device, and the number of keys missing for this device.
 */
- (NSArray<SealdDeviceMissingKeys*>*) devicesMissingKeysWithForceLocalAccountUpdate:(BOOL)forceLocalAccountUpdate
                                                                              error:(NSError**)error;
@end

#endif /* SealdSdk_h */

