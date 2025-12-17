//
//  ProjectBillingEditView.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ProjectBillingEditViewModel: ObservableObject {
    @Published var billingModel: BillingModel
    @Published var rate: String
    @Published var budget: String
    @Published var useBudget: Bool
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showingSuccessAlert = false

    private let apiClient = APIClient.shared
    private let project: Project
    private let onSave: () -> Void

    init(project: Project, onSave: @escaping () -> Void) {
        self.project = project
        self.onSave = onSave
        self.billingModel = project.billingModel
        self.rate = project.rate != nil ? String(format: "%.2f", project.rate!) : ""
        self.budget = project.budget != nil ? String(format: "%.2f", project.budget!) : ""
        self.useBudget = project.budget != nil && project.budget! > 0
    }

    var rateLabel: String {
        switch billingModel {
        case .hourly:
            return "Hourly Rate"
        case .fixed:
            return "Project Price"
        case .retainer:
            return "Monthly Fee"
        case .milestone:
            return "Milestone Amount"
        case .taskBased:
            return "Task Rate"
        case .notBillable:
            return "Rate (Optional)"
        }
    }

    var billingModelDescription: String {
        switch billingModel {
        case .hourly:
            return "Bill by the hour. Rate applies to all time entries."
        case .fixed:
            return "Fixed price project. Total project cost regardless of hours."
        case .retainer:
            return "Monthly retainer fee. Predictable recurring billing."
        case .milestone:
            return "Bill based on milestone completion."
        case .taskBased:
            return "Bill per task completed."
        case .notBillable:
            return "No billing. Internal or pro-bono work."
        }
    }

    var canSave: Bool {
        // For billable models, rate is required
        if billingModel != .notBillable && rate.isEmpty {
            return false
        }
        return true
    }

    func saveChanges() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        errorMessage = nil

        struct UpdateBillingRequest: Codable {
            let billingModel: String
            let rate: Double?
            let budget: Double?

            enum CodingKeys: String, CodingKey {
                case billingModel = "billing_model"
                case rate
                case budget
            }
        }

        do {
            let rateValue = rate.isEmpty ? nil : Double(rate)
            let budgetValue = useBudget && !budget.isEmpty ? Double(budget) : nil

            let request = UpdateBillingRequest(
                billingModel: billingModel.rawValue,
                rate: rateValue,
                budget: budgetValue
            )

            let _: Project = try await apiClient.patch("/projects/\(project.id)", body: request)

            showingSuccessAlert = true
            onSave()
            isSaving = false
            return true

        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
}

// MARK: - ProjectBillingEditView

struct ProjectBillingEditView: View {
    let project: Project
    let onSave: () -> Void

    @StateObject private var viewModel: ProjectBillingEditViewModel
    @Environment(\.dismiss) private var dismiss

    init(project: Project, onSave: @escaping () -> Void) {
        self.project = project
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: ProjectBillingEditViewModel(project: project, onSave: onSave))
    }

    var body: some View {
        Form {
            // Project Information (Read-only)
            Section {
                HStack {
                    Text("Project")
                        .foregroundColor(.alphaSecondaryText)
                    Spacer()
                    Text(project.name)
                        .foregroundColor(.alphaPrimaryText)
                }

                if let client = project.client {
                    HStack {
                        Text("Client")
                            .foregroundColor(.alphaSecondaryText)
                        Spacer()
                        Text(client.name)
                            .foregroundColor(.alphaPrimaryText)
                    }
                }
            } header: {
                Text("Project Information")
            }

            // Billing Configuration
            Section {
                // Billing Model Picker
                Picker("Billing Model", selection: $viewModel.billingModel) {
                    ForEach([BillingModel.hourly, .fixed, .retainer, .milestone, .taskBased, .notBillable], id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }

                // Description
                Text(viewModel.billingModelDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.alphaSecondaryText)

                // Rate Field
                HStack {
                    Text(viewModel.rateLabel)
                    Spacer()
                    TextField("0.00", text: $viewModel.rate)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                // Budget Toggle
                Toggle("Set Budget", isOn: $viewModel.useBudget)

                // Budget Field (conditional)
                if viewModel.useBudget {
                    HStack {
                        Text("Budget Amount")
                        Spacer()
                        TextField("0.00", text: $viewModel.budget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            } header: {
                Text("Billing Configuration")
            } footer: {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.alphaError)
                }
            }
        }
        .navigationTitle("Edit Billing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        let success = await viewModel.saveChanges()
                        if success {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Billing configuration updated successfully")
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView()
            }
        }
    }
}

// MARK: - Preview

#Preview("Project Billing Edit") {
    NavigationStack {
        ProjectBillingEditView(project: .preview, onSave: {})
    }
}
