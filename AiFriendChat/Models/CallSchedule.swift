// Models/CallSchedule.swift
struct CallSchedule: Codable, Identifiable {
    let id: String
    let phoneNumber: String
    let scheduledTime: Date
    let scenario: String
}