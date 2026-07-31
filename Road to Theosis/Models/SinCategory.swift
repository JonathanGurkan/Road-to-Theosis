import SwiftUI

struct SinSwipeActions {
    let victoryTitle: String
    let victoryIcon: String
    let stumbleTitle: String
    let stumbleIcon: String
}

struct SinCategory: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    var tint: Color
    let watchword: String
    var progress: Double

    static func item(
        _ title: String,
        _ detail: String,
        icon: String,
        tint: Color,
        watchword: String,
        progress: Double
    ) -> SinCategory {
        SinCategory(
            title: title,
            detail: detail,
            icon: icon,
            tint: tint,
            watchword: watchword,
            progress: progress
        )
    }

    var swipeActions: SinSwipeActions {
        switch title {
        case "Idolatry / Abomination":
            return .init(victoryTitle: "Choose God", victoryIcon: "cross.fill", stumbleTitle: "Divided", stumbleIcon: "heart.slash")
        case "Blasphemy":
            return .init(victoryTitle: "Reverent", victoryIcon: "text.bubble.fill", stumbleTitle: "Irreverent", stumbleIcon: "exclamationmark.bubble.fill")
        case "Neglect of God's Word":
            return .init(victoryTitle: "Read Word", victoryIcon: "book.fill", stumbleTitle: "Missed Word", stumbleIcon: "book.closed.fill")
        case "Quenching the Holy Spirit":
            return .init(victoryTitle: "Yield", victoryIcon: "wind", stumbleTitle: "Resisted", stumbleIcon: "hand.raised.slash.fill")
        case "Unbelief / No Trust in God":
            return .init(victoryTitle: "Trust God", victoryIcon: "shield.fill", stumbleTitle: "Doubted", stumbleIcon: "questionmark.circle.fill")
        case "Heresies / False Doctrine":
            return .init(victoryTitle: "Hold Faith", victoryIcon: "checkmark.seal.fill", stumbleTitle: "Strayed", stumbleIcon: "triangle.fill")
        case "Occult Involvement / Witchcraft":
            return .init(victoryTitle: "Renounce", victoryIcon: "sun.max.fill", stumbleTitle: "False", stumbleIcon: "sparkles")
        case "Neglect of Prayer":
            return .init(victoryTitle: "Prayed", victoryIcon: "hands.sparkles.fill", stumbleTitle: "No Prayer", stumbleIcon: "moon.zzz.fill")
        case "Sexual Immorality":
            return .init(victoryTitle: "Purity", victoryIcon: "heart.circle.fill", stumbleTitle: "Impure", stumbleIcon: "heart.slash.fill")
        case "Adultery":
            return .init(victoryTitle: "Keep Faith", victoryIcon: "ring.fill", stumbleTitle: "Wavered", stumbleIcon: "heart.slash.circle.fill")
        case "Fornication":
            return .init(victoryTitle: "Covenant", victoryIcon: "person.2.fill", stumbleTitle: "Chastity", stumbleIcon: "person.2.slash.fill")
        case "Homosexuality":
            return .init(victoryTitle: "Holiness", victoryIcon: "figure.stand", stumbleTitle: "Misordered", stumbleIcon: "person.3.fill")
        case "Whoremongers":
            return .init(victoryTitle: "Dignity", victoryIcon: "person.crop.circle.badge.checkmark", stumbleTitle: "Used", stumbleIcon: "building.2.fill")
        case "Lasciviousness":
            return .init(victoryTitle: "Modesty", victoryIcon: "eye.circle.fill", stumbleTitle: "Shameless", stumbleIcon: "eye.fill")
        case "Lust / Pornography":
            return .init(victoryTitle: "Guard Eyes", victoryIcon: "eye.slash.fill", stumbleTitle: "Looked", stumbleIcon: "play.rectangle.fill")
        case "Slander":
            return .init(victoryTitle: "Protect", victoryIcon: "bubble.left.and.bubble.right.fill", stumbleTitle: "Slandered", stumbleIcon: "bubble.left.fill")
        case "Criticism":
            return .init(victoryTitle: "Grace", victoryIcon: "leaf.fill", stumbleTitle: "Judged", stumbleIcon: "exclamationmark.bubble.fill")
        case "Boasting":
            return .init(victoryTitle: "Thanks", victoryIcon: "hands.clap.fill", stumbleTitle: "Boasted", stumbleIcon: "crown.fill")
        case "Gossip / Backbiting":
            return .init(victoryTitle: "Keep Quiet", victoryIcon: "lock.fill", stumbleTitle: "Gossiped", stumbleIcon: "person.crop.circle.badge.exclamationmark")
        case "Perjury":
            return .init(victoryTitle: "Tell Truth", victoryIcon: "checkmark.circle.fill", stumbleTitle: "Falsehood", stumbleIcon: "doc.text.fill")
        case "Speaking Obscenities":
            return .init(victoryTitle: "Clean", victoryIcon: "text.bubble.fill", stumbleTitle: "Corrupt", stumbleIcon: "text.quote")
        case "Lying / Deceit":
            return .init(victoryTitle: "Honest", victoryIcon: "eye.fill", stumbleTitle: "Hid Truth", stumbleIcon: "eye.slash.fill")
        case "Calling People a Fool":
            return .init(victoryTitle: "Bless", victoryIcon: "message.fill", stumbleTitle: "Insulted", stumbleIcon: "hand.raised.fill")
        case "Coarse Joking / Foolish Talk":
            return .init(victoryTitle: "Sober", victoryIcon: "quote.bubble.fill", stumbleTitle: "Crude", stumbleIcon: "theatermasks.fill")
        case "Profanity":
            return .init(victoryTitle: "Tamed", victoryIcon: "checkmark.bubble.fill", stumbleTitle: "Careless", stumbleIcon: "hand.raised.fill")
        case "Murder":
            return .init(victoryTitle: "Life", victoryIcon: "heart.fill", stumbleTitle: "Hatred", stumbleIcon: "cross.fill")
        case "Abuse":
            return .init(victoryTitle: "Mercy", victoryIcon: "bandage.fill", stumbleTitle: "Harm", stumbleIcon: "exclamationmark.triangle.fill")
        case "Dissension / Debate":
            return .init(victoryTitle: "Peace", victoryIcon: "leaf.fill", stumbleTitle: "Conflict", stumbleIcon: "arrow.triangle.2.circlepath")
        case "Sedition / Rebellion to Authority":
            return .init(victoryTitle: "Order", victoryIcon: "flag.fill", stumbleTitle: "Rebelled", stumbleIcon: "flag.slash.fill")
        case "Not Loving Your Neighbour":
            return .init(victoryTitle: "Love", victoryIcon: "person.2.fill", stumbleTitle: "Loveless", stumbleIcon: "person.crop.circle.badge.xmark")
        case "Unforgiving":
            return .init(victoryTitle: "Forgive", victoryIcon: "arrow.uturn.backward.circle.fill", stumbleTitle: "Held Debt", stumbleIcon: "slash.circle.fill")
        case "Unmerciful":
            return .init(victoryTitle: "Mercy", victoryIcon: "heart.circle.fill", stumbleTitle: "Merciless", stumbleIcon: "heart.slash.circle.fill")
        case "Prejudice / Bigotry":
            return .init(victoryTitle: "Justly", victoryIcon: "scale.3d", stumbleTitle: "Partiality", stumbleIcon: "person.crop.circle.badge.xmark")
        case "Hatred / Wrath / Resentment":
            return .init(victoryTitle: "Peace", victoryIcon: "leaf.fill", stumbleTitle: "Anger", stumbleIcon: "flame")
        case "Strife / Argumentative":
            return .init(victoryTitle: "Gentle", victoryIcon: "hand.thumbsup.fill", stumbleTitle: "Argued", stumbleIcon: "hand.raised.slash.fill")
        case "Depression":
            return .init(victoryTitle: "Hope", victoryIcon: "sun.max.fill", stumbleTitle: "Despair", stumbleIcon: "cloud.drizzle.fill")
        case "Envy / Emulations":
            return .init(victoryTitle: "Thanks", victoryIcon: "gift.fill", stumbleTitle: "Envied", stumbleIcon: "eye.circle.fill")
        case "Vanity":
            return .init(victoryTitle: "Humility", victoryIcon: "sparkles", stumbleTitle: "Vanity", stumbleIcon: "sparkles")
        case "Pride":
            return .init(victoryTitle: "Humble", victoryIcon: "arrow.down.circle.fill", stumbleTitle: "Pride", stumbleIcon: "crown")
        case "Greed / Covetousness":
            return .init(victoryTitle: "Content", victoryIcon: "house.fill", stumbleTitle: "Grasped", stumbleIcon: "banknote.fill")
        case "Maliciousness / Malignity":
            return .init(victoryTitle: "Goodwill", victoryIcon: "heart.text.square.fill", stumbleTitle: "Malice", stumbleIcon: "skull.fill")
        case "Evil Thoughts":
            return .init(victoryTitle: "Guard", victoryIcon: "brain.head.profile", stumbleTitle: "Unclean", stumbleIcon: "xmark.circle.fill")
        case "Foolishness / Without Understanding":
            return .init(victoryTitle: "Wisdom", victoryIcon: "lightbulb.fill", stumbleTitle: "Foolish", stumbleIcon: "questionmark.diamond.fill")
        case "Without Natural Affection":
            return .init(victoryTitle: "Compassion", victoryIcon: "heart.fill", stumbleTitle: "Cold", stumbleIcon: "heart.slash")
        case "Implacable":
            return .init(victoryTitle: "Peace", victoryIcon: "checkmark.seal.fill", stumbleTitle: "Stubborn", stumbleIcon: "bolt.horizontal.circle.fill")
        case "Anxiety / Worry / Fearful":
            return .init(victoryTitle: "Entrust", victoryIcon: "shield.lefthalf.filled", stumbleTitle: "Fearful", stumbleIcon: "exclamationmark.triangle.fill")
        case "Negativism":
            return .init(victoryTitle: "Hope", victoryIcon: "plus.circle.fill", stumbleTitle: "Negative", stumbleIcon: "minus.circle.fill")
        case "Bitterness":
            return .init(victoryTitle: "Release", victoryIcon: "drop.circle.fill", stumbleTitle: "Bitter", stumbleIcon: "drop.fill")
        case "Haughtiness":
            return .init(victoryTitle: "Lowly", victoryIcon: "arrow.down.circle.fill", stumbleTitle: "Haughty", stumbleIcon: "arrow.up.circle.fill")
        case "Divorce":
            return .init(victoryTitle: "Covenant", victoryIcon: "heart.text.square.fill", stumbleTitle: "Hardened", stumbleIcon: "heart.slash.circle")
        case "No Concern for the Lost":
            return .init(victoryTitle: "Pray", victoryIcon: "map.fill", stumbleTitle: "Away", stumbleIcon: "map.fill")
        case "Chronic Lateness":
            return .init(victoryTitle: "On Time", victoryIcon: "clock.fill", stumbleTitle: "Late", stumbleIcon: "clock.badge.exclamationmark.fill")
        case "Passivity":
            return .init(victoryTitle: "Act", victoryIcon: "play.circle.fill", stumbleTitle: "Passive", stumbleIcon: "pause.circle.fill")
        case "Sloth":
            return .init(victoryTitle: "Rise", victoryIcon: "figure.walk", stumbleTitle: "Sloth", stumbleIcon: "moon.zzz.fill")
        case "Procrastination":
            return .init(victoryTitle: "Do Today", victoryIcon: "checkmark.circle.fill", stumbleTitle: "Delayed", stumbleIcon: "hourglass.bottomhalf.filled")
        case "Disobedient to Parents":
            return .init(victoryTitle: "Honor", victoryIcon: "house.fill", stumbleTitle: "Dishonor", stumbleIcon: "house.fill")
        case "Workaholic":
            return .init(victoryTitle: "Balance", victoryIcon: "briefcase.fill", stumbleTitle: "Overworked", stumbleIcon: "briefcase.fill")
        case "Not Honoring Your Father and Mother":
            return .init(victoryTitle: "Honor", victoryIcon: "heart.text.square.fill", stumbleTitle: "No Honor", stumbleIcon: "person.crop.circle.badge.xmark")
        case "Gluttony":
            return .init(victoryTitle: "Temperance", victoryIcon: "fork.knife", stumbleTitle: "Excess", stumbleIcon: "fork.knife")
        case "Drunkenness / Revellings":
            return .init(victoryTitle: "Sober", victoryIcon: "cup.and.saucer.fill", stumbleTitle: "Drunken", stumbleIcon: "wineglass.fill")
        case "Covenant Breaking / Defilement / Unrepentance":
            return .init(victoryTitle: "Repent", victoryIcon: "arrow.uturn.left.circle.fill", stumbleTitle: "No Repent", stumbleIcon: "seal.fill")
        case "Inventors of Evil Things":
            return .init(victoryTitle: "Create", victoryIcon: "hammer.fill", stumbleTitle: "Misused", stumbleIcon: "wrench.and.screwdriver.fill")
        case "Stealing":
            return .init(victoryTitle: "Honest", victoryIcon: "hand.raised.fill", stumbleTitle: "Stole", stumbleIcon: "handbag.fill")
        case "Hypocrisy":
            return .init(victoryTitle: "Sincere", victoryIcon: "face.smiling.fill", stumbleTitle: "Masked", stumbleIcon: "theatermasks.fill")
        case "Selfishness":
            return .init(victoryTitle: "Serve", victoryIcon: "person.2.fill", stumbleTitle: "Self", stumbleIcon: "person.crop.circle.fill")
        case "Lawlessness / Unrighteousness / Ungodly / Unholy / Uncleanness":
            return .init(victoryTitle: "Holiness", victoryIcon: "checkmark.shield.fill", stumbleTitle: "Unholy", stumbleIcon: "xmark.shield.fill")
        default:
            return .init(victoryTitle: "Practice", victoryIcon: "checkmark.circle.fill", stumbleTitle: "Missed", stumbleIcon: "exclamationmark.triangle")
        }
    }

    static let sample: [SinSection] = [
        .section(
            title: "Sins Against God",
            subtitle: "Attitudes and actions that turn the heart away from God.",
            tint: .purple,
            isExpanded: true,
            items: [
                .item("Idolatry / Abomination", "Placing anything above God", icon: "flame.fill", tint: .purple, watchword: "Worship", progress: 0.74),
                .item("Blasphemy", "Speaking against God with contempt", icon: "bolt.fill", tint: .red, watchword: "Reverence", progress: 0.61),
                .item("Neglect of God's Word", "Ignoring Scripture and instruction", icon: "book.fill", tint: .blue, watchword: "Scripture", progress: 0.56),
                .item("Quenching the Holy Spirit", "Resisting the Spirit's leading", icon: "wind", tint: .teal, watchword: "Yielding", progress: 0.43),
                .item("Unbelief / No Trust in God", "Refusing to trust God's care", icon: "questionmark.circle.fill", tint: .indigo, watchword: "Trust", progress: 0.52),
                .item("Heresies / False Doctrine", "Teaching or believing what distorts the gospel", icon: "triangle.fill", tint: .orange, watchword: "Truth", progress: 0.38),
                .item("Occult Involvement / Witchcraft", "Seeking power apart from God", icon: "sparkles", tint: .cyan, watchword: "Holiness", progress: 0.29),
                .item("Neglect of Prayer", "Failing to keep communion with God", icon: "hands.sparkles.fill", tint: .green, watchword: "Prayer", progress: 0.48)
            ]
        ),
        .section(
            title: "Sexual Immorality",
            subtitle: "Desires and practices that distort purity and covenant faithfulness.",
            tint: .pink,
            items: [
                .item("Sexual Immorality", "Sexual sin in general", icon: "heart.slash.fill", tint: .pink, watchword: "Purity", progress: 0.71),
                .item("Adultery", "Unfaithfulness in marriage", icon: "ring.fill", tint: .red, watchword: "Faithfulness", progress: 0.54),
                .item("Fornication", "Sexual sin outside marriage", icon: "person.2.slash.fill", tint: .orange, watchword: "Covenant", progress: 0.58),
                .item("Homosexuality", "Sexual sin outside God's design", icon: "person.3.fill", tint: .purple, watchword: "Holiness", progress: 0.22),
                .item("Whoremongers", "Sexual exploitation and impurity", icon: "building.2.fill", tint: .brown, watchword: "Dignity", progress: 0.31),
                .item("Lasciviousness", "Shameless sensuality", icon: "eye.fill", tint: .pink, watchword: "Self-control", progress: 0.49),
                .item("Lust / Pornography", "Ungoverned desire and sexualized images", icon: "play.rectangle.fill", tint: .gray, watchword: "Guarded", progress: 0.67)
            ]
        ),
        .section(
            title: "Sins of the Tongue",
            subtitle: "Speech that harms, distorts, or dishonors others.",
            tint: .cyan,
            items: [
                .item("Slander", "Speaking to damage someone's reputation", icon: "bubble.left.fill", tint: .cyan, watchword: "Truth", progress: 0.42),
                .item("Criticism", "Judging harshly or without grace", icon: "exclamationmark.bubble.fill", tint: .blue, watchword: "Grace", progress: 0.59),
                .item("Boasting", "Self-exaltation and bragging", icon: "crown.fill", tint: .yellow, watchword: "Humility", progress: 0.36),
                .item("Gossip / Backbiting", "Speaking behind someone's back", icon: "person.crop.circle.badge.exclamationmark", tint: .mint, watchword: "Love", progress: 0.65),
                .item("Perjury", "Intentionally lying or speaking falsely", icon: "doc.text.fill", tint: .orange, watchword: "Integrity", progress: 0.28),
                .item("Speaking Obscenities", "Dirty, crude, or corrupt speech", icon: "text.quote", tint: .purple, watchword: "Clean Speech", progress: 0.55),
                .item("Lying / Deceit", "Hiding the truth or misleading others", icon: "eye.slash.fill", tint: .indigo, watchword: "Honesty", progress: 0.62),
                .item("Calling People a Fool", "Insulting or demeaning others", icon: "message.fill", tint: .yellow, watchword: "Kindness", progress: 0.39),
                .item("Coarse Joking / Foolish Talk", "Sexually crude or reckless humor", icon: "quote.bubble.fill", tint: .orange, watchword: "Sobriety", progress: 0.51),
                .item("Profanity", "Careless or vulgar language", icon: "hand.raised.fill", tint: .gray, watchword: "Speech", progress: 0.77)
            ]
        ),
        .section(
            title: "Sins Against Others",
            subtitle: "Actions and attitudes that wound, divide, or refuse mercy.",
            tint: .red,
            items: [
                .item("Murder", "Taking life or hating life in the heart", icon: "cross.fill", tint: .red, watchword: "Life", progress: 0.15),
                .item("Abuse", "Mental or physical harm", icon: "bandage.fill", tint: .orange, watchword: "Mercy", progress: 0.22),
                .item("Dissension / Debate", "Causing needless conflict", icon: "arrow.triangle.2.circlepath", tint: .yellow, watchword: "Peace", progress: 0.53),
                .item("Sedition / Rebellion to Authority", "Rejecting rightful authority", icon: "flag.fill", tint: .brown, watchword: "Order", progress: 0.33),
                .item("Not Loving Your Neighbour", "Withholding active love", icon: "person.2.fill", tint: .pink, watchword: "Love", progress: 0.64),
                .item("Unforgiving", "Keeping accounts of wrongs", icon: "slash.circle.fill", tint: .indigo, watchword: "Forgiveness", progress: 0.49),
                .item("Unmerciful", "Withholding compassion", icon: "heart.slash.circle.fill", tint: .mint, watchword: "Mercy", progress: 0.37),
                .item("Prejudice / Bigotry", "Judging people unfairly", icon: "person.crop.circle.badge.xmark", tint: .teal, watchword: "Justice", progress: 0.41),
                .item("Hatred / Wrath / Resentment", "Inner hostility toward others", icon: "flame", tint: .red, watchword: "Peace", progress: 0.57),
                .item("Strife / Argumentative", "Always looking for a fight", icon: "hand.raised.slash.fill", tint: .orange, watchword: "Gentleness", progress: 0.63)
            ]
        ),
        .section(
            title: "Inner Heart / Mental Sins",
            subtitle: "Thought patterns, inner motives, and settled attitudes.",
            tint: .indigo,
            items: [
                .item("Depression", "Season of heaviness or despair", icon: "cloud.drizzle.fill", tint: .blue, watchword: "Hope", progress: 0.46),
                .item("Envy / Emulations", "Resenting what others have", icon: "eye.circle.fill", tint: .green, watchword: "Contentment", progress: 0.52),
                .item("Vanity", "Empty self-focus", icon: "sparkles", tint: .purple, watchword: "Humility", progress: 0.48),
                .item("Pride", "Self-exaltation", icon: "crown", tint: .orange, watchword: "Humility", progress: 0.69),
                .item("Greed / Covetousness", "Grasping after more", icon: "banknote.fill", tint: .yellow, watchword: "Contentment", progress: 0.66),
                .item("Maliciousness / Malignity", "Wishing harm on others", icon: "skull.fill", tint: .red, watchword: "Goodness", progress: 0.24),
                .item("Evil Thoughts", "Unclean or destructive thoughts", icon: "brain.head.profile", tint: .gray, watchword: "Guarded", progress: 0.58),
                .item("Foolishness / Without Understanding", "Living without discernment", icon: "questionmark.diamond.fill", tint: .teal, watchword: "Wisdom", progress: 0.44),
                .item("Without Natural Affection", "Coldness toward others", icon: "heart.slash", tint: .pink, watchword: "Compassion", progress: 0.19),
                .item("Implacable", "Unforgiving or stubbornly unsettled", icon: "bolt.horizontal.circle.fill", tint: .cyan, watchword: "Peace", progress: 0.35),
                .item("Anxiety / Worry / Fearful", "A lack of trust in God", icon: "exclamationmark.triangle.fill", tint: .orange, watchword: "Trust", progress: 0.62),
                .item("Negativism", "Expecting the worst", icon: "minus.circle.fill", tint: .brown, watchword: "Hope", progress: 0.57),
                .item("Bitterness", "Stubborn hurt and resentment", icon: "drop.fill", tint: .indigo, watchword: "Forgiveness", progress: 0.45),
                .item("Haughtiness", "Overbearing pride", icon: "arrow.up.circle.fill", tint: .purple, watchword: "Humility", progress: 0.50)
            ]
        ),
        .section(
            title: "Family & Responsibility",
            subtitle: "Neglect of duties, relationships, and faithful stewardship.",
            tint: .green,
            items: [
                .item("Divorce", "Breaking covenant relationships", icon: "heart.slash.circle", tint: .red, watchword: "Faithfulness", progress: 0.26),
                .item("No Concern for the Lost", "Withholding compassion for others", icon: "map.fill", tint: .blue, watchword: "Mission", progress: 0.31),
                .item("Chronic Lateness", "Repeatedly disregarding time", icon: "clock.badge.exclamationmark.fill", tint: .orange, watchword: "Diligence", progress: 0.61),
                .item("Passivity", "Failing to act when responsibility calls", icon: "pause.circle.fill", tint: .gray, watchword: "Action", progress: 0.55),
                .item("Sloth", "Neglecting prayer, work, and duty", icon: "moon.zzz.fill", tint: .indigo, watchword: "Diligence", progress: 0.72),
                .item("Procrastination", "Delaying what should be done now", icon: "hourglass.bottomhalf.filled", tint: .yellow, watchword: "Steadfastness", progress: 0.68),
                .item("Disobedient to Parents", "Rejecting parental authority", icon: "house.fill", tint: .teal, watchword: "Honor", progress: 0.32),
                .item("Workaholic", "Letting work consume life", icon: "briefcase.fill", tint: .brown, watchword: "Balance", progress: 0.54),
                .item("Not Honoring Your Father and Mother", "Failing to show honor", icon: "heart.text.square.fill", tint: .pink, watchword: "Honor", progress: 0.29)
            ]
        ),
        .section(
            title: "False Character & Behavior",
            subtitle: "Patterns of excess, insincerity, and willful corruption.",
            tint: .orange,
            items: [
                .item("Gluttony", "Misusing appetite", icon: "fork.knife", tint: .orange, watchword: "Self-Control", progress: 0.41),
                .item("Drunkenness / Revellings", "Loss of restraint", icon: "wineglass.fill", tint: .pink, watchword: "Sobriety", progress: 0.37),
                .item("Covenant Breaking / Defilement / Unrepentance", "Stubbornly refusing repentance", icon: "seal.fill", tint: .red, watchword: "Repentance", progress: 0.18),
                .item("Inventors of Evil Things", "Creative misuse of gifts", icon: "hammer.fill", tint: .purple, watchword: "Goodness", progress: 0.23),
                .item("Stealing", "Taking what is not yours", icon: "handbag.fill", tint: .green, watchword: "Honesty", progress: 0.47),
                .item("Hypocrisy", "Presenting a false face", icon: "face.smiling.fill", tint: .yellow, watchword: "Sincerity", progress: 0.55),
                .item("Selfishness", "Living only for self", icon: "person.crop.circle.fill", tint: .blue, watchword: "Love", progress: 0.66),
                .item("Lawlessness / Unrighteousness / Ungodly / Unholy / Uncleanness", "Rejecting God's order and purity", icon: "xmark.shield.fill", tint: .gray, watchword: "Holiness", progress: 0.34)
            ]
        )
    ]
}
