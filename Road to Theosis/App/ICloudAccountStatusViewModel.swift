import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class ICloudAccountStatusViewModel {
    enum Status: Equatable {
        case archived
        case checking
        case available
        case noAccount
        case restricted
        case temporarilyUnavailable
        case couldNotDetermine
        case error(String)

        var title: String {
            switch self {
            case .archived:
                return "iCloud Archived"
            case .checking:
                return "Checking iCloud"
            case .available:
                return "iCloud Available"
            case .noAccount:
                return "No iCloud Account"
            case .restricted:
                return "iCloud Restricted"
            case .temporarilyUnavailable:
                return "iCloud Temporarily Unavailable"
            case .couldNotDetermine:
                return "iCloud Status Unknown"
            case .error:
                return "iCloud Check Failed"
            }
        }

        var subtitle: String {
            switch self {
            case .archived:
                return "CloudKit calls are disabled for this personal-profile build."
            case .checking:
                return "Looking for the device iCloud account."
            case .available:
                return "This device can use iCloud sync."
            case .noAccount:
                return "Sign in to iCloud in Settings to enable sync."
            case .restricted:
                return "This device is not allowed to use iCloud."
            case .temporarilyUnavailable:
                return "iCloud is signed in but not ready right now."
            case .couldNotDetermine:
                return "The app could not determine iCloud availability."
            case .error(let message):
                return message
            }
        }

        var canEnableSync: Bool {
            self == .available
        }
    }

    private let container: CKContainer?
    private(set) var status: Status = AppPersistence.isICloudSyncArchived ? .archived : .checking

    init(container: CKContainer? = nil) {
        self.container = AppPersistence.isICloudSyncArchived ? nil : (container ?? .default())
    }

    func refresh() async {
        guard !AppPersistence.isICloudSyncArchived else {
            status = .archived
            return
        }

        status = .checking

        do {
            let accountStatus = try await currentAccountStatus()
            status = Status(accountStatus)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func monitorAccountChanges() async {
        guard !AppPersistence.isICloudSyncArchived else { return }

        for await _ in NotificationCenter.default.notifications(named: .CKAccountChanged) {
            await refresh()
        }
    }

    private func currentAccountStatus() async throws -> CKAccountStatus {
        guard let container else { return .couldNotDetermine }

        return try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { accountStatus, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: accountStatus)
                }
            }
        }
    }
}

private extension ICloudAccountStatusViewModel.Status {
    init(_ accountStatus: CKAccountStatus) {
        switch accountStatus {
        case .available:
            self = .available
        case .noAccount:
            self = .noAccount
        case .restricted:
            self = .restricted
        case .temporarilyUnavailable:
            self = .temporarilyUnavailable
        case .couldNotDetermine:
            self = .couldNotDetermine
        @unknown default:
            self = .couldNotDetermine
        }
    }
}
