//
//  AIAPIService.swift
//  下班助手
//
//  AI API 服务类，负责与 AI 服务进行通信
//

import Foundation

/// AI API 服务类，负责与 AI 服务进行通信
class AIAPIService {
    static let shared = AIAPIService()

    private init() {}

    // OpenAI 格式的请求和响应
    struct OpenAIRequest: Codable {
        let model: String
        let messages: [OpenAIMessage]
        let temperature: Double
        let max_tokens: Int
        let top_p: Double
        let stream: Bool
        let thinking: ThinkingConfig?

        struct ThinkingConfig: Codable {
            let type: String
        }
    }

    struct OpenAIMessage: Codable {
        let role: String
        let content: String
        let reasoning_content: String?

        enum CodingKeys: String, CodingKey {
            case role
            case content
            case reasoning_content
        }

        init(role: String, content: String) {
            self.role = role
            self.content = content
            self.reasoning_content = nil
        }
    }

    struct OpenAIResponse: Codable {
        let id: String
        let object: String
        let created: Int
        let model: String
        let choices: [OpenAIChoice]
        let usage: OpenAIUsage
    }

    struct OpenAIChoice: Codable {
        let index: Int
        let message: OpenAIMessage
        let finish_reason: String
    }

    struct OpenAIUsage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }

    // Anthropic 格式的请求和响应
    struct AnthropicRequest: Codable {
        let model: String
        let messages: [AnthropicMessage]
        let system: String
        let temperature: Double
        let max_tokens: Int
        let top_p: Double
        let stream: Bool
    }

    struct AnthropicMessage: Codable {
        let role: String
        let content: String
    }

    struct AnthropicResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [AnthropicContent]
        let model: String
        let stop_reason: String?
        let stop_sequence: String?
        let usage: AnthropicUsage
    }

    struct AnthropicContent: Codable {
        let type: String
        let text: String
    }

    struct AnthropicUsage: Codable {
        let input_tokens: Int
        let output_tokens: Int
    }

    /// 获取关怀提醒内容
    /// - Parameters:
    ///   - config: AI 配置
    ///   - completion: 完成回调，返回结果或错误
    func getCareMessage(
        config: AIConfig,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard !config.apiKey.isEmpty else {
            completion(.failure(NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key 为空"])))
            return
        }

        let messages: [OpenAIMessage] = [
            OpenAIMessage(role: "user", content: "用一句话（15字内）提醒我休息、喝水或关注健康")
        ]

        switch config.serviceFormat {
        case .openAI:
            sendOpenAIRequest(config: config, messages: messages, isTest: false, completion: completion)
        case .anthropic:
            sendAnthropicRequest(config: config, messages: messages, isTest: false, completion: completion)
        }
    }

    /// 发送测试请求
    /// - Parameters:
    ///   - config: AI 配置
    ///   - completion: 完成回调，返回结果或错误
    func sendTestRequest(
        config: AIConfig,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard !config.apiKey.isEmpty else {
            completion(.failure(NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API Key 为空"])))
            return
        }

        let messages: [OpenAIMessage] = [
            OpenAIMessage(role: "system", content: "你是一个测试助手，只需要简短回应测试消息。"),
            OpenAIMessage(role: "user", content: config.serviceFormat.testPrompt)
        ]

        switch config.serviceFormat {
        case .openAI:
            sendOpenAIRequest(config: config, messages: messages, isTest: true, completion: completion)
        case .anthropic:
            sendAnthropicRequest(config: config, messages: messages, isTest: true, completion: completion)
        }
    }

    private func sendOpenAIRequest(
        config: AIConfig,
        messages: [OpenAIMessage],
        isTest: Bool = false,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let requestBody = OpenAIRequest(
            model: config.effectiveModel,
            messages: messages,
            temperature: 0.7,
            max_tokens: 50,
            top_p: 0.9,
            stream: false,
            thinking: OpenAIRequest.ThinkingConfig(type: "disabled")  // 禁用推理模式
        )

        guard let url = URL(string: config.effectiveBaseURL) else {
            completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL 无效"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("发送请求到: \(url)")
            print("请求体: \(requestBody)")
        } catch {
            completion(.failure(NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "请求编码失败"])))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }

            // 先记录原始响应
            if let responseStr = String(data: data, encoding: .utf8) {
                print("原始 JSON 响应: \(responseStr)")
            }

            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                print("完整响应: \(response)")

                if let choice = response.choices.first {
                    // 禁用推理模式后，直接使用content字段
                    let content = choice.message.content
                    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("解析到的内容: '\(trimmedContent)'")
                    print("finish_reason: \(choice.finish_reason)")

                    if isTest {
                        // 对于测试请求，只要解析成功就算成功
                        if trimmedContent.isEmpty {
                            print("警告: 测试响应内容为空，但连接成功")
                            completion(.success("连接成功"))
                        } else {
                            completion(.success(trimmedContent))
                        }
                    } else {
                        // 对于正常的关怀提醒
                        if trimmedContent.isEmpty {
                            print("警告: API 返回空内容，使用默认消息")
                            let defaultMessage = self.getDefaultCareMessage()
                            completion(.success(defaultMessage))
                        } else {
                            // 限制内容长度为20个字符
                            let limitedContent = String(trimmedContent.prefix(20))
                            completion(.success(limitedContent))
                        }
                    }
                } else {
                    print("警告: 未找到 choices")
                    completion(.failure(NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])))
                }
            } catch {
                print("解析 OpenAI 响应失败: \(error)")
                let responseStr = String(data: data, encoding: .utf8) ?? "无内容"
                print("响应内容: \(responseStr)")
                completion(.failure(error))
            }
        }.resume()
    }

    private func sendAnthropicRequest(
        config: AIConfig,
        messages: [OpenAIMessage],
        isTest: Bool = false,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let anthropicMessages = messages.map { message in
            AnthropicMessage(role: message.role, content: message.content)
        }

        let requestBody = AnthropicRequest(
            model: config.effectiveModel,
            messages: anthropicMessages,
            system: messages.first?.content ?? "直接回答",
            temperature: 0.3,
            max_tokens: 20,  // 限制为20个token
            top_p: 0.9,
            stream: false
        )

        guard let url = URL(string: config.effectiveBaseURL) else {
            completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL 无效"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("发送请求到: \(url)")
            print("请求体: \(requestBody)")
        } catch {
            completion(.failure(NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "请求编码失败"])))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }

            // 先记录原始响应
            if let responseStr = String(data: data, encoding: .utf8) {
                print("原始 JSON 响应: \(responseStr)")
            }

            do {
                let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                print("完整响应: \(response)")

                if let text = response.content.first?.text {
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("解析到的内容: '\(trimmedText)'")
                    print("stop_reason: \(response.stop_reason ?? "nil")")

                    if isTest {
                        // 对于测试请求，只要解析成功就算成功，即使内容为空
                        if trimmedText.isEmpty {
                            print("警告: 测试响应内容为空，但连接成功 (stop_reason: \(response.stop_reason ?? "nil"))")
                            completion(.success("连接成功"))
                        } else {
                            completion(.success(trimmedText))
                        }
                    } else {
                        // 对于正常的关怀提醒，检查内容是否为空
                        if trimmedText.isEmpty {
                            print("警告: API 返回了空内容 (stop_reason: \(response.stop_reason ?? "nil"))")
                            completion(.failure(NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "API 返回空内容"])))
                        } else {
                            // 限制内容长度为20个字符
                            let limitedContent = String(trimmedText.prefix(20))
                            completion(.success(limitedContent))
                        }
                    }
                } else {
                    print("警告: 未找到 content.text")
                    completion(.failure(NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])))
                }
            } catch {
                print("解析 Anthropic 响应失败: \(error)")
                let responseStr = String(data: data, encoding: .utf8) ?? "无内容"
                print("响应内容: \(responseStr)")
                completion(.failure(error))
            }
        }.resume()
    }

    /// 获取默认的关怀提醒消息
    /// - Returns: 随机选择的默认关怀消息
    func getDefaultCareMessage() -> String {
        let messages = [
            "工作辛苦了！记得喝水哦 💧",
            "该休息一下了！起来活动活动 🚶",
            "保持健康很重要！喝杯水再继续 💦",
            "休息是为了更好地工作！放松一下 😌",
            "眼睛累了吗？看看窗外的绿色 🌳",
            "记得补充水分！身体是革命的本钱 💧"
        ]

        return messages.randomElement() ?? "工作辛苦了！记得休息哦"
    }
}
