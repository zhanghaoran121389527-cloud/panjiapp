import Foundation
import Observation

/// 盘玩记录表单状态与提交流程（线框 06 · 契约 3.10/3.11）。
/// 照片按选择顺序逐张上传（顺序即 photoUrls 下标）；失败张置灰可单独重试，重试只补失败张（08-states D）。
@MainActor
@Observable
final class RecordStore {
    enum PhotoState {
        case local(Data)
        case uploading(Data)
        case uploaded(String, Data)
        case failed(Data)
    }

    var photoStates: [PhotoState] = []
    var content = ""
    var method = ""
    var durationMinutes = 0                 // 0 = 未记录（线框 06：0/未动 = null）
    var recordedDate = BeijingDate.todayDate()
    private(set) var dateChanged = false
    private(set) var submitting = false
    var photoError = false                  // 「这张没传成功，点按重试」行内提示
    var saveError: String?

    private let session: SessionStore
    let itemId: String

    init(session: SessionStore, itemId: String) {
        self.session = session
        self.itemId = itemId
    }

    var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedContent.isEmpty && trimmedContent.count <= 500 && !submitting
    }

    /// 是否有未保存内容（关闭确认用）
    var hasUnsavedChanges: Bool {
        !trimmedContent.isEmpty || !photoStates.isEmpty || !method.isEmpty
            || durationMinutes > 0 || dateChanged
    }

    func addPhotos(_ dataList: [Data]) {
        photoStates.append(contentsOf: dataList.map(PhotoState.local))
    }

    func removePhoto(at index: Int) {
        guard photoStates.indices.contains(index) else { return }
        photoStates.remove(at: index)
        if photoStates.allSatisfy({ if case .failed = $0 { return false } else { return true } }) {
            photoError = false
        }
    }

    /// 提交：先补传所有未成功照片（顺序保持），全部就绪后创建记录（防连点：提交中禁用）。
    func submit() async -> RecordDTO? {
        guard canSubmit else { return nil }
        submitting = true
        saveError = nil
        defer { submitting = false }

        var hasFailure = false
        for index in photoStates.indices {
            switch photoStates[index] {
            case .local(let data), .failed(let data):
                photoStates[index] = .uploading(data)
                do {
                    let url = try await upload(data)
                    photoStates[index] = .uploaded(url, data)
                } catch APIError.authRequired {
                    session.signOut()
                    return nil
                } catch {
                    photoStates[index] = .failed(data)
                    hasFailure = true
                }
            case .uploading, .uploaded:
                continue
            }
        }
        if hasFailure {
            photoError = true
            return nil
        }

        var urls: [String] = []
        for state in photoStates {
            guard case .uploaded(let url, _) = state else {
                photoError = true
                return nil
            }
            urls.append(url)
        }

        do {
            let request = CreateRecordRequest(
                photoUrls: urls,
                content: trimmedContent,
                durationMinutes: durationMinutes > 0 ? durationMinutes : nil,
                method: Self.nilIfBlank(method),
                recordedDate: dateChanged ? BeijingDate.string(from: recordedDate) : nil)
            let response: RecordResponse = try await APIClient.shared.request(
                method: "POST", path: "/items/\(itemId)/records", body: request, token: session.token)
            return response.record
        } catch APIError.authRequired {
            session.signOut()
            return nil
        } catch let error as APIError {
            saveError = error.userMessage ?? "没保存成功，请重试"
            return nil
        } catch {
            saveError = "没保存成功，请重试"
            return nil
        }
    }

    /// 单张失败照片重试（线框 06：点击置灰缩略图重传该张）
    func retryPhoto(at index: Int) async {
        guard case .failed(let data) = photoStates[index] else { return }
        photoStates[index] = .uploading(data)
        photoError = false
        do {
            let url = try await upload(data)
            photoStates[index] = .uploaded(url, data)
        } catch APIError.authRequired {
            session.signOut()
        } catch {
            photoStates[index] = .failed(data)
            photoError = true
        }
    }

    func setRecordedDate(_ date: Date) {
        recordedDate = date
        dateChanged = true
    }

    private func upload(_ data: Data) async throws -> String {
        let mime = APIClient.mimeType(for: data)
        let response: UploadResponse = try await APIClient.shared.uploadImage(
            data: data,
            mimeType: mime,
            filename: "record.\(APIClient.fileExtension(for: mime))",
            token: session.token)
        return response.url
    }

    // MARK: 北京时间（裁决 A8/A13；统一使用 Features/Items/BeijingDate.swift）

    private static func nilIfBlank(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
