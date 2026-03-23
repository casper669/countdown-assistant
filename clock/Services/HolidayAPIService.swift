//
//  HolidayAPIService.swift
//  下班助手
//
//  节假日 API 服务，负责从第三方 API 获取节假日数据
//

import Foundation

/// 节假日 API 服务，负责从第三方 API 获取节假日数据
class HolidayAPIService {
    static let shared = HolidayAPIService()

    private let baseURL = "https://api.jiejiariapi.com"

    private init() {}

    /// 获取全年节假日数据
    /// - Parameters:
    ///   - year: 年份
    ///   - completion: 完成回调，返回节假日数组或错误
    func fetchYearHolidays(year: Int, completion: @escaping (Result<[Holiday], Error>) -> Void) {
        let urlString = "\(baseURL)/v1/holidays/\(year)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }

            do {
                // API 返回的是字典格式: {"2026-01-01": {"date": "2026-01-01", "name": "元旦", "isOffDay": true}}
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] {
                    var holidays: [Holiday] = []

                    for (_, info) in json {
                        if let date = info["date"] as? String,
                           let name = info["name"] as? String,
                           let isOffDay = info["isOffDay"] as? Bool {
                            let holiday = Holiday(name: name, date: date, isOffDay: isOffDay)
                            holidays.append(holiday)
                        }
                    }

                    completion(.success(holidays))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -1)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
