import CommonCrypto
import CryptoKit
import Foundation
import Security

/// Errors that can occur during encryption operations
enum EncryptionError: Error {
    case notInitialized
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case keychainError(OSStatus)
    case exportFailed
    case importFailed
}

/// Manages encryption/decryption for all user data
/// Each user has their own unique encryption key
@MainActor
class EncryptionManager: ObservableObject {
    static let shared = EncryptionManager()
    
    @Published private(set) var isInitialized = false
    @Published private(set) var hasMasterKey = false
    
    var masterKey: SymmetricKey?
    private let keyIdentifier = "com.mindgrowee.encryption.master"
    private let saltIdentifier = "com.mindgrowee.encryption.salt"
    private let versionIdentifier = "com.mindgrowee.encryption.version"

    // KDF version: 1 = HKDF (legacy), 2 = PBKDF2
    private static let currentKDFVersion: UInt8 = 2
    private static let pbkdf2Iterations: UInt32 = 600_000

    private init() {}
    
    // MARK: - Setup
    
    /// Initialize encryption with a user password
    /// Called on first app launch or when creating new encryption
    func setupEncryption(password: String) throws {
        // Generate random salt
        let salt = Data.random(count: 32)

        // Derive master key from password using PBKDF2 (v2)
        let key = deriveKeyPBKDF2(from: password, salt: salt)

        // Store salt in keychain
        try storeInKeychain(data: salt, identifier: saltIdentifier)

        // Store KDF version
        try storeInKeychain(data: Data([Self.currentKDFVersion]), identifier: versionIdentifier)

        // Generate and encrypt data encryption key (DEK)
        let dek = SymmetricKey(size: .bits256)
        let encryptedDEK = try encryptDEK(dek, with: key)

        // Store encrypted DEK
        try storeInKeychain(data: encryptedDEK, identifier: keyIdentifier)

        // Set master key
        masterKey = key
        isInitialized = true
        hasMasterKey = true

        Logger.shared.info("Encryption initialized successfully")
    }
    
    /// Unlock encryption with existing password
    func unlock(password: String) throws {
        guard let salt = loadFromKeychain(identifier: saltIdentifier) else {
            throw EncryptionError.notInitialized
        }

        // Determine KDF version (default to 1 for legacy setups)
        let version: UInt8
        if let versionData = loadFromKeychain(identifier: versionIdentifier), let v = versionData.first {
            version = v
        } else {
            version = 1 // Legacy HKDF
        }

        let key: SymmetricKey
        if version >= 2 {
            key = deriveKeyPBKDF2(from: password, salt: salt)
        } else {
            key = deriveKeyHKDF(from: password, salt: salt)
        }

        // Verify key by trying to load DEK
        guard let encryptedDEK = loadFromKeychain(identifier: keyIdentifier) else {
            throw EncryptionError.invalidKey
        }

        // Try to decrypt (will fail if wrong password)
        _ = try decryptDEK(encryptedDEK, with: key)

        masterKey = key
        isInitialized = true
        hasMasterKey = true

        // Migrate from v1 to v2 if needed
        if version < Self.currentKDFVersion {
            try migrateKDF(password: password, salt: salt, currentKey: key)
        }

        Logger.shared.info("Encryption unlocked successfully")
    }
    
    /// Check if encryption is already set up
    func checkExistingSetup() -> Bool {
        return loadFromKeychain(identifier: saltIdentifier) != nil &&
               loadFromKeychain(identifier: keyIdentifier) != nil
    }
    
    // MARK: - Key Derivation

    /// Derive encryption key from password using PBKDF2 (v2, secure for passwords)
    private func deriveKeyPBKDF2(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        var derivedKeyData = Data(repeating: 0, count: 32)

        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        Self.pbkdf2Iterations,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            fatalError("PBKDF2 key derivation failed")
        }

        return SymmetricKey(data: derivedKeyData)
    }

    /// Derive encryption key from password using PBKDF2 for export operations
    static func deriveExportKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        var derivedKeyData = Data(repeating: 0, count: 32)

        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        pbkdf2Iterations,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            fatalError("PBKDF2 key derivation failed")
        }

        return SymmetricKey(data: derivedKeyData)
    }

    /// Legacy HKDF key derivation (v1, kept for backward compatibility)
    private func deriveKeyHKDF(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: .init(data: passwordData),
            salt: salt,
            info: Data("mindgrowee_v1".utf8),
            outputByteCount: 32
        )
    }

    /// Legacy HKDF for export (v1, kept for backward compatibility during import)
    static func deriveExportKeyHKDF(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: .init(data: passwordData),
            salt: salt,
            info: Data("mindgrowee_export".utf8),
            outputByteCount: 32
        )
    }

    // MARK: - KDF Migration

    /// Migrate from legacy HKDF (v1) to PBKDF2 (v2)
    private func migrateKDF(password: String, salt: Data, currentKey: SymmetricKey) throws {
        // Derive new key with PBKDF2
        let newKey = deriveKeyPBKDF2(from: password, salt: salt)

        // Load and decrypt DEK with old key
        guard let encryptedDEK = loadFromKeychain(identifier: keyIdentifier) else {
            throw EncryptionError.invalidKey
        }
        let dek = try decryptDEK(encryptedDEK, with: currentKey)

        // Re-encrypt DEK with new key
        let newEncryptedDEK = try encryptDEK(dek, with: newKey)

        // Store updated encrypted DEK and version
        try storeInKeychain(data: newEncryptedDEK, identifier: keyIdentifier)
        try storeInKeychain(data: Data([Self.currentKDFVersion]), identifier: versionIdentifier)

        // Update master key to new derivation
        masterKey = newKey

        Logger.shared.info("Migrated encryption from HKDF (v1) to PBKDF2 (v2)")
    }
    
    // MARK: - Data Encryption Key (DEK) Management
    
    /// Encrypt a DEK with the master key
    private func encryptDEK(_ dek: SymmetricKey, with masterKey: SymmetricKey) throws -> Data {
        let dekData = dek.withUnsafeBytes { Data($0) }
        let sealedBox = try AES.GCM.seal(dekData, using: masterKey)
        return sealedBox.combined!
    }
    
    /// Decrypt a DEK with the master key
    private func decryptDEK(_ encryptedDEK: Data, with masterKey: SymmetricKey) throws -> SymmetricKey {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedDEK)
        let dekData = try AES.GCM.open(sealedBox, using: masterKey)
        return SymmetricKey(data: dekData)
    }
    
    // MARK: - Encryption/Decryption
    
    /// Encrypt any Codable object
    func encrypt<T: Codable>(_ value: T) throws -> EncryptedRecord {
        guard let key = masterKey else {
            throw EncryptionError.notInitialized
        }
        
        // Encode to JSON
        let jsonData = try JSONEncoder().encode(value)
        
        // Encrypt with AES-256-GCM
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        
        return EncryptedRecord(
            id: UUID(),
            encryptedData: sealedBox.ciphertext,
            nonce: Data(sealedBox.nonce),
            tag: sealedBox.tag,
            keyID: keyIdentifier,
            createdAt: Date()
        )
    }
    
    /// Decrypt an EncryptedRecord back to the original type
    func decrypt<T: Codable>(_ record: EncryptedRecord, as type: T.Type) throws -> T {
        guard let key = masterKey else {
            throw EncryptionError.notInitialized
        }
        
        // Reconstruct sealed box
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: record.nonce),
            ciphertext: record.encryptedData,
            tag: record.tag
        )
        
        // Decrypt
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        // Decode from JSON
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
    
    /// Encrypt raw data
    func encryptData(_ data: Data) throws -> EncryptedRecord {
        guard let key = masterKey else {
            throw EncryptionError.notInitialized
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        return EncryptedRecord(
            id: UUID(),
            encryptedData: sealedBox.ciphertext,
            nonce: Data(sealedBox.nonce),
            tag: sealedBox.tag,
            keyID: keyIdentifier,
            createdAt: Date()
        )
    }
    
    /// Decrypt to raw data
    func decryptData(_ record: EncryptedRecord) throws -> Data {
        guard let key = masterKey else {
            throw EncryptionError.notInitialized
        }
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: record.nonce),
            ciphertext: record.encryptedData,
            tag: record.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Export/Import
    
    /// Export all encrypted data with password protection
    func exportEncryptedData(password: String, records: [EncryptedExportRecord]) throws -> Data {
        // Generate export key from password using PBKDF2
        let exportSalt = Data.random(count: 32)
        let exportKey = Self.deriveExportKey(from: password, salt: exportSalt)

        // Create export container
        var exportRecords: [ExportRecord] = []

        for record in records {
            let encryptedData = try encryptExportRecord(record, with: exportKey)
            exportRecords.append(encryptedData)
        }

        let container = EncryptedExportContainer(
            version: 2,
            salt: exportSalt.base64EncodedString(),
            createdAt: Date(),
            records: exportRecords
        )

        return try JSONEncoder().encode(container)
    }

    /// Import encrypted data from export
    func importEncryptedData(data: Data, password: String) throws -> [EncryptedExportRecord] {
        let container = try JSONDecoder().decode(EncryptedExportContainer.self, from: data)

        guard let salt = Data(base64Encoded: container.salt) else {
            throw EncryptionError.importFailed
        }

        // Use appropriate KDF based on export version
        let exportKey: SymmetricKey
        if container.version >= 2 {
            exportKey = Self.deriveExportKey(from: password, salt: salt)
        } else {
            exportKey = Self.deriveExportKeyHKDF(from: password, salt: salt)
        }

        var records: [EncryptedExportRecord] = []

        for exportRecord in container.records {
            let record = try decryptExportRecord(exportRecord, with: exportKey)
            records.append(record)
        }

        return records
    }
    
    private func encryptExportRecord(_ record: EncryptedExportRecord, with key: SymmetricKey) throws -> ExportRecord {
        let data = try JSONEncoder().encode(record)
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        return ExportRecord(
            id: record.id.uuidString,
            table: record.table,
            data: sealedBox.combined!.base64EncodedString()
        )
    }
    
    private func decryptExportRecord(_ exportRecord: ExportRecord, with key: SymmetricKey) throws -> EncryptedExportRecord {
        guard let data = Data(base64Encoded: exportRecord.data) else {
            throw EncryptionError.importFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try JSONDecoder().decode(EncryptedExportRecord.self, from: decryptedData)
    }
    
    // MARK: - Keychain Helpers
    
    private func storeInKeychain(data: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    private func loadFromKeychain(identifier: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    // MARK: - Reset
    
    /// Remove all encryption keys (for logout/reset)
    func reset() {
        let identifiers = [keyIdentifier, saltIdentifier, versionIdentifier]
        
        for identifier in identifiers {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: identifier
            ]
            SecItemDelete(query as CFDictionary)
        }
        
        masterKey = nil
        isInitialized = false
        hasMasterKey = false
        
        Logger.shared.info("Encryption reset")
    }
}

// MARK: - Supporting Types

/// Represents an encrypted record in the database
struct EncryptedRecord: Codable {
    let id: UUID
    let encryptedData: Data
    let nonce: Data
    let tag: Data
    let keyID: String
    let createdAt: Date
}

/// Record for export/import
struct EncryptedExportRecord: Codable {
    let id: UUID
    let table: String
    let encryptedData: Data
    let nonce: Data
    let tag: Data
    let createdAt: Date
}

/// Export container format
struct EncryptedExportContainer: Codable {
    let version: Int
    let salt: String
    let createdAt: Date
    let records: [ExportRecord]
}

/// Individual export record
struct ExportRecord: Codable {
    let id: String
    let table: String
    let data: String
}

// MARK: - Data Extension

extension Data {
    /// Generate random data of specified count
    static func random(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
}

// MARK: - Preview Helpers

extension EncryptionManager {
    /// Setup with a test key for previews
    func setupForPreview() {
        masterKey = SymmetricKey(size: .bits256)
        isInitialized = true
        hasMasterKey = true
    }
}
