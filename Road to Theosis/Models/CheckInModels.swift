import Foundation

struct CheckInAnswerOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let targetProgress: Double
}

struct CheckInTarget: Codable, Hashable {
    let sectionTitle: String
    let sinTitle: String
    let weight: Double
}

struct CheckInQuestion: Identifiable, Hashable {
    let id: String
    let shortTitle: String
    let prompt: String
    let detail: String
    let targets: [CheckInTarget]
}

struct CheckInChange: Codable, Hashable, Identifiable {
    let id: UUID
    let sectionTitle: String
    let sinTitle: String
    let targetProgress: Double
    let weight: Double

    init(
        id: UUID = UUID(),
        sectionTitle: String,
        sinTitle: String,
        targetProgress: Double,
        weight: Double
    ) {
        self.id = id
        self.sectionTitle = sectionTitle
        self.sinTitle = sinTitle
        self.targetProgress = targetProgress
        self.weight = weight
    }
}

struct CheckInResponse: Codable, Hashable, Identifiable {
    let id: UUID
    let questionID: String
    let questionShortTitle: String
    let questionPrompt: String
    let answerTitle: String
    let answerDetail: String
    let answerProgress: Double
    let changes: [CheckInChange]

    init(
        id: UUID = UUID(),
        questionID: String,
        questionShortTitle: String,
        questionPrompt: String,
        answerTitle: String,
        answerDetail: String,
        answerProgress: Double,
        changes: [CheckInChange]
    ) {
        self.id = id
        self.questionID = questionID
        self.questionShortTitle = questionShortTitle
        self.questionPrompt = questionPrompt
        self.answerTitle = answerTitle
        self.answerDetail = answerDetail
        self.answerProgress = answerProgress
        self.changes = changes
    }

    var primaryChange: CheckInChange? {
        changes.first
    }

    var summaryText: String {
        guard let primaryChange else {
            return "\(questionShortTitle): \(answerTitle)"
        }

        return "\(questionShortTitle): \(answerTitle) (\(primaryChange.sinTitle) \(SinFrequencyScale.percentage(for: primaryChange.targetProgress))%)"
    }
}

struct CheckInRecord: Codable, Hashable {
    let completedAt: Date
    let responses: [CheckInResponse]

    var summaryText: String {
        responses
            .map(\.summaryText)
            .joined(separator: " • ")
    }

    var allChanges: [CheckInChange] {
        responses.flatMap(\.changes)
    }

    func latestChange(for sectionTitle: String, sinTitle: String) -> CheckInChange? {
        responses
            .reversed()
            .compactMap { response in
                response.changes.last(where: { $0.sectionTitle == sectionTitle && $0.sinTitle == sinTitle })
            }
            .first
    }
}

struct CheckInQuestionPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let questionIDs: [String]
}

enum CheckInQuestionnaire {
    static let presets: [CheckInQuestionPreset] = [
        CheckInQuestionPreset(
            id: "full",
            title: "Full check-in",
            detail: "Use every available question.",
            questionIDs: defaultQuestionIDs
        ),
        CheckInQuestionPreset(
            id: "shortWeekly",
            title: "Short weekly check-in",
            detail: "A balanced weekly pass through the core areas.",
            questionIDs: ["prayer", "thoughts", "speech", "relationships", "discipline", "witness"]
        ),
        CheckInQuestionPreset(
            id: "prayerPurity",
            title: "Prayer and purity",
            detail: "Focus on devotion, trust, thoughts, and sexual purity.",
            questionIDs: ["prayer", "truth", "trust", "thoughts", "purity"]
        ),
        CheckInQuestionPreset(
            id: "relationshipsSpeech",
            title: "Relationships and speech",
            detail: "Focus on words, conflict, mercy, and love toward others.",
            questionIDs: ["speech", "relationships", "humility", "obedience", "witness"]
        )
    ]

    static var defaultQuestionIDs: [String] {
        questions.map(\.id)
    }

    static func questions(for enabledQuestionIDs: Set<String>) -> [CheckInQuestion] {
        let filteredQuestions = questions.filter { enabledQuestionIDs.contains($0.id) }
        return filteredQuestions.isEmpty ? questions : filteredQuestions
    }

    static let answerOptions: [CheckInAnswerOption] = [
        .init(title: "Very steady", detail: "This area has been stable and healthy.", targetProgress: 0.94),
        .init(title: "Mostly steady", detail: "Small drift, but the pattern stayed strong.", targetProgress: 0.80),
        .init(title: "Mixed", detail: "Some good days, some real drift.", targetProgress: 0.62),
        .init(title: "Often troubled", detail: "This area kept pulling against you.", targetProgress: 0.42),
        .init(title: "Deep struggle", detail: "This area needs immediate attention.", targetProgress: 0.20)
    ]

    static let questions: [CheckInQuestion] = [
        .init(
            id: "prayer",
            shortTitle: "Prayer",
            prompt: "How steady was your prayer life?",
            detail: "Think about the last stretch of days, not your ideal self.",
            targets: [
                .init(sectionTitle: "Sins Against God", sinTitle: "Neglect of Prayer", weight: 1.0),
                .init(sectionTitle: "Sins Against God", sinTitle: "Neglect of God's Word", weight: 0.72),
                .init(sectionTitle: "Sins Against God", sinTitle: "Quenching the Holy Spirit", weight: 0.62),
                .init(sectionTitle: "Sins Against God", sinTitle: "No Concern for the Lost", weight: 0.45)
            ]
        ),
        .init(
            id: "truth",
            shortTitle: "Truth",
            prompt: "How faithful were you to Scripture and doctrine?",
            detail: "This covers what shaped your thinking and how often you stayed anchored in truth.",
            targets: [
                .init(sectionTitle: "Sins Against God", sinTitle: "Neglect of God's Word", weight: 1.0),
                .init(sectionTitle: "Sins Against God", sinTitle: "Heresies / False Doctrine", weight: 0.78),
                .init(sectionTitle: "Sins Against God", sinTitle: "Unbelief / No Trust in God", weight: 0.48)
            ]
        ),
        .init(
            id: "trust",
            shortTitle: "Trust",
            prompt: "How much did fear, worry, or hopelessness press in?",
            detail: "Use this to check whether fear was normal or repeatedly pulling you off-center.",
            targets: [
                .init(sectionTitle: "Sins Against God", sinTitle: "Unbelief / No Trust in God", weight: 0.92),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Anxiety / Worry / Fearful", weight: 1.0),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Depression", weight: 0.65)
            ]
        ),
        .init(
            id: "thoughts",
            shortTitle: "Thoughts",
            prompt: "How guarded were your thoughts and eyes?",
            detail: "This is about what you entertained, not only what you acted on.",
            targets: [
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Lust / Pornography", weight: 1.0),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Evil Thoughts", weight: 0.85),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Vanity", weight: 0.45)
            ]
        ),
        .init(
            id: "speech",
            shortTitle: "Speech",
            prompt: "How guarded was your speech?",
            detail: "Consider honesty, tone, gossip, criticism, and careless words together.",
            targets: [
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Lying / Deceit", weight: 0.96),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Gossip / Backbiting", weight: 1.0),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Slander", weight: 0.92),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Profanity", weight: 0.80),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Coarse Joking / Foolish Talk", weight: 0.78),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Criticism", weight: 0.68)
            ]
        ),
        .init(
            id: "relationships",
            shortTitle: "Relationships",
            prompt: "How peaceful and merciful were your relationships?",
            detail: "Think about patience, forgiveness, and whether conflict ruled your reactions.",
            targets: [
                .init(sectionTitle: "Sins Against Others", sinTitle: "Strife / Argumentative", weight: 1.0),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Hatred / Wrath / Resentment", weight: 0.90),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Unforgiving", weight: 0.94),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Unmerciful", weight: 0.86),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Not Loving Your Neighbour", weight: 0.74),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Abuse", weight: 0.78)
            ]
        ),
        .init(
            id: "purity",
            shortTitle: "Purity",
            prompt: "How steady was your sexual purity and self-control?",
            detail: "Be honest about temptation, indulgence, and where your mind actually went.",
            targets: [
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Sexual Immorality", weight: 1.0),
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Adultery", weight: 0.96),
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Fornication", weight: 0.92),
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Homosexuality", weight: 0.90),
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Whoremongers", weight: 0.82),
                .init(sectionTitle: "Sexual Immorality", sinTitle: "Lasciviousness", weight: 0.85)
            ]
        ),
        .init(
            id: "humility",
            shortTitle: "Humility",
            prompt: "How humble was your heart?",
            detail: "Consider pride, vanity, self-promotion, and how quickly you yielded to correction.",
            targets: [
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Pride", weight: 1.0),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Vanity", weight: 0.92),
                .init(sectionTitle: "Sins of the Tongue", sinTitle: "Boasting", weight: 0.88),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Haughtiness", weight: 0.84)
            ]
        ),
        .init(
            id: "discipline",
            shortTitle: "Discipline",
            prompt: "How disciplined were you with work, time, and effort?",
            detail: "This checks sloth, delay, passivity, and how often you delayed obedience.",
            targets: [
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Sloth", weight: 1.0),
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Passivity", weight: 0.92),
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Procrastination", weight: 0.94),
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Chronic Lateness", weight: 0.86),
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Workaholic", weight: 0.58)
            ]
        ),
        .init(
            id: "contentment",
            shortTitle: "Contentment",
            prompt: "How content and restrained were you?",
            detail: "This looks at appetite, consumption, greed, and the urge to grab more.",
            targets: [
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Greed / Covetousness", weight: 1.0),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Gluttony", weight: 0.94),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Drunkenness / Revellings", weight: 0.92),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Selfishness", weight: 0.74)
            ]
        ),
        .init(
            id: "allegiance",
            shortTitle: "Allegiance",
            prompt: "How aligned were you with Godly truth and obedience?",
            detail: "Consider anything that pulled your loyalty away from God.",
            targets: [
                .init(sectionTitle: "Sins Against God", sinTitle: "Idolatry / Abomination", weight: 0.98),
                .init(sectionTitle: "Sins Against God", sinTitle: "Blasphemy", weight: 0.92),
                .init(sectionTitle: "Sins Against God", sinTitle: "Occult Involvement / Witchcraft", weight: 0.92),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Lawlessness / Unrighteousness / Ungodly / Unholy / Uncleanness", weight: 0.80)
            ]
        ),
        .init(
            id: "obedience",
            shortTitle: "Obedience",
            prompt: "How responsive were you to conviction and authority?",
            detail: "This covers repentance, honor, and what happened when you knew better.",
            targets: [
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Disobedient to Parents", weight: 0.96),
                .init(sectionTitle: "Family & Responsibility", sinTitle: "Not Honoring Your Father and Mother", weight: 0.92),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Stealing", weight: 0.82),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Hypocrisy", weight: 0.84),
                .init(sectionTitle: "Sins Against God", sinTitle: "Covenant Breaking / Defilement / Unrepentance", weight: 1.0),
                .init(sectionTitle: "False Character & Behavior", sinTitle: "Inventors of Evil Things", weight: 0.80)
            ]
        ),
        .init(
            id: "witness",
            shortTitle: "Witness",
            prompt: "How open were you to loving others and speaking about God?",
            detail: "This checks concern for the lost, mercy, and whether love shaped your posture.",
            targets: [
                .init(sectionTitle: "Sins Against God", sinTitle: "No Concern for the Lost", weight: 1.0),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Not Loving Your Neighbour", weight: 0.92),
                .init(sectionTitle: "Inner Heart / Mental Sins", sinTitle: "Maliciousness / Malignity", weight: 0.86),
                .init(sectionTitle: "Sins Against Others", sinTitle: "Unmerciful", weight: 0.78)
            ]
        )
    ]

    static func response(
        for question: CheckInQuestion,
        selectedOptionIndex: Int,
        sections: [SinSection]
    ) -> CheckInResponse? {
        guard answerOptions.indices.contains(selectedOptionIndex) else {
            return nil
        }

        let option = answerOptions[selectedOptionIndex]
        let changes = question.targets.compactMap { target -> CheckInChange? in
            guard let currentProgress = currentProgress(for: target, in: sections) else {
                return nil
            }

            let adjustedProgress = clamped(
                currentProgress + ((option.targetProgress - currentProgress) * target.weight)
            )

            return CheckInChange(
                sectionTitle: target.sectionTitle,
                sinTitle: target.sinTitle,
                targetProgress: adjustedProgress,
                weight: target.weight
            )
        }

        return CheckInResponse(
            questionID: question.id,
            questionShortTitle: question.shortTitle,
            questionPrompt: question.prompt,
            answerTitle: option.title,
            answerDetail: option.detail,
            answerProgress: option.targetProgress,
            changes: changes
        )
    }

    static func summaryText(for responses: [CheckInResponse]) -> String {
        responses
            .map { "\($0.questionShortTitle): \($0.answerTitle)" }
            .joined(separator: " • ")
    }

    static func progressLabel(for question: CheckInQuestion, sections: [SinSection]) -> String {
        guard let firstTarget = question.targets.first,
              let currentProgress = currentProgress(for: firstTarget, in: sections) else {
            return "No current reading"
        }

        return "\(SinFrequencyScale.label(for: currentProgress)) now"
    }

    private static func currentProgress(for target: CheckInTarget, in sections: [SinSection]) -> Double? {
        guard let section = sections.first(where: { $0.title == target.sectionTitle }),
              let item = section.items.first(where: { $0.title == target.sinTitle }) else {
            return nil
        }

        return item.progress
    }

    private static func clamped(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}
