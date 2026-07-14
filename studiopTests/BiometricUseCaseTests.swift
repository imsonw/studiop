import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeBiometricRepository: BiometricRepository, @unchecked Sendable {
    var deviceToReturn = BiometricDevice(deviceID: "device-1", deviceName: "iPhone", isEnabled: true)
    var authSessionToReturn = AuthSession(
        user: User(id: 1, idEncode: "abc", name: "Jane", email: "jane@example.com"),
        token: "biometric-token"
    )
    var errorToThrow: Error?

    private(set) var lastEnable: (deviceID: String, deviceName: String)?
    private(set) var lastDisableDeviceID: String?
    private(set) var lastCheckStatusDeviceID: String?
    private(set) var lastBiometricLogin: (deviceID: String, biometricToken: String)?

    func enableBiometric(deviceID: String, deviceName: String) async throws {
        lastEnable = (deviceID, deviceName)
        if let errorToThrow { throw errorToThrow }
    }

    func disableBiometric(deviceID: String) async throws {
        lastDisableDeviceID = deviceID
        if let errorToThrow { throw errorToThrow }
    }

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice {
        lastCheckStatusDeviceID = deviceID
        if let errorToThrow { throw errorToThrow }
        return deviceToReturn
    }

    func loginWithBiometric(deviceID: String, biometricToken: String) async throws -> AuthSession {
        lastBiometricLogin = (deviceID, biometricToken)
        if let errorToThrow { throw errorToThrow }
        return authSessionToReturn
    }
}

struct BiometricUseCaseTests {
    @Test func enableBiometricForwardsDeviceInfo() async throws {
        let fake = FakeBiometricRepository()
        let useCase = EnableBiometricUseCase(repository: fake)

        try await useCase(deviceID: "device-1", deviceName: "iPhone 16")

        #expect(fake.lastEnable?.deviceID == "device-1")
        #expect(fake.lastEnable?.deviceName == "iPhone 16")
    }

    @Test func disableBiometricForwardsDeviceID() async throws {
        let fake = FakeBiometricRepository()
        let useCase = DisableBiometricUseCase(repository: fake)

        try await useCase(deviceID: "device-1")

        #expect(fake.lastDisableDeviceID == "device-1")
    }

    @Test func checkBiometricStatusReturnsDevice() async throws {
        let fake = FakeBiometricRepository()
        let useCase = CheckBiometricStatusUseCase(repository: fake)

        let result = try await useCase(deviceID: "device-1")

        #expect(fake.lastCheckStatusDeviceID == "device-1")
        #expect(result == fake.deviceToReturn)
    }

    @Test func biometricLoginReturnsSession() async throws {
        let fake = FakeBiometricRepository()
        let useCase = BiometricLoginUseCase(repository: fake)

        let result = try await useCase(deviceID: "device-1", biometricToken: "btok")

        #expect(fake.lastBiometricLogin?.deviceID == "device-1")
        #expect(fake.lastBiometricLogin?.biometricToken == "btok")
        #expect(result == fake.authSessionToReturn)
    }

    @Test func biometricLoginPropagatesError() async throws {
        let fake = FakeBiometricRepository()
        fake.errorToThrow = StubError()
        let useCase = BiometricLoginUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            _ = try await useCase(deviceID: "device-1", biometricToken: "btok")
        }
    }
}
