//
//  CopilotUsageView.swift
//  GymMembershipApp
//
//  Created by AI Assistant on 08/07/2025.
//

import SwiftUI
import FirebaseAnalytics

struct CopilotUsageView: View {
    @StateObject private var vm = CopilotUsageViewModel()
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Copilot Usage")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            vm.loadUsageData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .onAppear {
                    vm.loadUsageData()
                    
                    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                        AnalyticsParameterScreenName: "CopilotUsageView",
                        AnalyticsParameterScreenClass: "CopilotUsageView"
                    ])
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        let coreContent = ScrollView {
            VStack(spacing: 24) {
                if let stats = vm.stats {
                    // Usage Statistics Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Usage Statistics")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            UsageStatCard(
                                title: "Total Interactions",
                                value: "\(stats.totalInteractions)",
                                icon: "message.circle"
                            )
                            
                            UsageStatCard(
                                title: "Total Time",
                                value: stats.formattedTotalDuration,
                                icon: "clock"
                            )
                            
                            UsageStatCard(
                                title: "This Week",
                                value: "\(stats.thisWeekInteractions)",
                                icon: "calendar.badge.plus"
                            )
                            
                            UsageStatCard(
                                title: "Satisfaction",
                                value: stats.formattedSatisfactionRate,
                                icon: "hand.thumbsup"
                            )
                        }
                        
                        if let mostUsed = stats.mostUsedFeature {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Most used feature: **\(mostUsed)**")
                                    .font(.footnote)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Recent Interactions Section
                if !vm.recentInteractions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Recent Interactions")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        
                        LazyVStack(spacing: 12) {
                            ForEach(vm.recentInteractions) { interaction in
                                InteractionRow(interaction: interaction)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bolt.circle")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Quick Actions")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            // Log a sample interaction
                            vm.logCopilotInteraction(
                                type: "workout_suggestion",
                                duration: 45,
                                satisfied: true,
                                feedback: "Helpful workout recommendations"
                            )
                        } label: {
                            HStack {
                                Image(systemName: "dumbbell")
                                Text("Request Workout Suggestion")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.blue)
                        
                        Button {
                            // Log a nutrition advice interaction
                            vm.logCopilotInteraction(
                                type: "nutrition_advice",
                                duration: 30,
                                satisfied: true,
                                feedback: "Great nutrition tips"
                            )
                        } label: {
                            HStack {
                                Image(systemName: "leaf")
                                Text("Get Nutrition Advice")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.green)
                        
                        Button {
                            // Log a form correction interaction
                            vm.logCopilotInteraction(
                                type: "form_correction",
                                duration: 60,
                                satisfied: true,
                                feedback: "Excellent form analysis"
                            )
                        } label: {
                            HStack {
                                Image(systemName: "eye")
                                Text("Analyze Exercise Form")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.purple)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding()
        }
        
        coreContent
            .loadingErrorEmpty(
                isLoading: vm.isLoading,
                errorMessage: vm.errorMessage,
                isEmpty: vm.stats == nil && vm.recentInteractions.isEmpty && !vm.isLoading && vm.errorMessage == nil,
                emptyMessage: "No copilot usage data available."
            )
    }
}

// MARK: - Supporting Views

struct UsageStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InteractionRow: View {
    let interaction: CopilotUsage
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on interaction type
            Image(systemName: iconForType(interaction.interactionType))
                .font(.title3)
                .foregroundColor(colorForType(interaction.interactionType))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(interaction.interactionType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                
                Text(interaction.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let feedback = interaction.feedback, !feedback.isEmpty {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(interaction.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: interaction.satisfied ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .foregroundColor(interaction.satisfied ? .green : .red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "workout_suggestion":
            return "dumbbell"
        case "nutrition_advice":
            return "leaf"
        case "form_correction":
            return "eye"
        default:
            return "brain.head.profile"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "workout_suggestion":
            return .blue
        case "nutrition_advice":
            return .green
        case "form_correction":
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    CopilotUsageView()
}