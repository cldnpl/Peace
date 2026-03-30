import SwiftUI
import Combine

struct MoodReflectionSnapshot {
    let title: String
    let message: String
    let detailTitle: String
    let detailValue: String
    let detailMessage: String
    let dominantMoodLabel: String
    let trendLabel: String
    let energyLabel: String
    let consistencyLabel: String
    let premiumInsightTitle: String
    let premiumInsightMessage: String
    let premiumSuggestion: String
}

@MainActor
final class MoodJournalStore: ObservableObject {
    static let shared = MoodJournalStore()

    @Published private(set) var entries: [MoodEntry] = []

    private let storageKey = "mindmesh.mood.entries"

    private init() {
        load()
    }

    func saveEntry(mood: MoodLevel, note: String) {
        entries.removeAll { Calendar.current.isDateInToday($0.date) }
        entries.append(MoodEntry(mood: mood, note: note))
        entries.sort { $0.date < $1.date }
        persist()
    }

    func entry(for date: Date) -> MoodEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func recentEntries(lastDays: Int, from referenceDate: Date = .now) -> [MoodEntry] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -(lastDays - 1), to: referenceDate) else {
            return []
        }

        return entries
            .filter { $0.date >= Calendar.current.startOfDay(for: startDate) }
            .sorted { $0.date < $1.date }
    }

    func reflectionSnapshot(
        lastDays: Int = 7,
        minimumEntries: Int = 3,
        language: AppLanguage = AppLanguagePreferences.currentLanguage
    ) -> MoodReflectionSnapshot? {
        let recentEntries = recentEntries(lastDays: lastDays)
        guard recentEntries.count >= minimumEntries else { return nil }
        let t = AppStrings(language: language)

        let energyValues = recentEntries.map(\.mood.energyValue)
        let averageEnergy = energyValues.reduce(0, +) / Double(recentEntries.count)

        let firstHalf = Array(recentEntries.prefix(max(1, recentEntries.count / 2)))
        let secondHalf = Array(recentEntries.suffix(max(1, recentEntries.count / 2)))

        let firstAverage = firstHalf.map(\.mood.energyValue).reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.map(\.mood.energyValue).reduce(0, +) / Double(secondHalf.count)
        let trend = secondAverage - firstAverage
        let energySpread = (energyValues.max() ?? averageEnergy) - (energyValues.min() ?? averageEnergy)

        let dominantMood = recentEntries
            .reduce(into: [MoodLevel: Int]()) { counts, entry in
                counts[entry.mood, default: 0] += 1
            }
            .max { $0.value < $1.value }?
            .key ?? .neutral

        let title: String
        if trend > 0.12 {
            title = t.text(it: "Il tono si sta alleggerendo.", en: "The tone is getting lighter.", es: "El tono se está aligerando.", fr: "Le ton s'allège.", zh: "整体状态正在变轻。", ar: "النبرة أصبحت أخف.", da: "Tonen bliver lettere.", nb: "Tonen blir lettere.", sv: "Tonen lättar.")
        } else if trend < -0.12 {
            title = t.text(it: "Negli ultimi giorni c'e un po' piu attrito.", en: "The last few days have had a bit more friction.", es: "En los últimos días hay un poco más de fricción.", fr: "Ces derniers jours, il y a un peu plus de friction.", zh: "最近几天的阻力感更明显了一些。", ar: "هناك بعض الاحتكاك أكثر في الأيام الأخيرة.", da: "De sidste dage har haft lidt mere modstand.", nb: "De siste dagene har hatt litt mer friksjon.", sv: "De senaste dagarna har haft lite mer friktion.")
        } else if averageEnergy >= 0.72 {
            title = t.text(it: "La settimana regge bene.", en: "The week is holding up well.", es: "La semana está aguantando bien.", fr: "La semaine tient bien.", zh: "这一周整体撑得不错。", ar: "الأسبوع متماسك بشكل جيد.", da: "Ugen holder godt.", nb: "Uken holder seg godt.", sv: "Veckan håller ihop bra.")
        } else {
            title = t.text(it: "L'umore e abbastanza stabile.", en: "Your mood is fairly stable.", es: "Tu estado de ánimo es bastante estable.", fr: "Ton humeur est assez stable.", zh: "你的情绪整体比较稳定。", ar: "مزاجك مستقر إلى حد ما.", da: "Dit humør er forholdsvis stabilt.", nb: "Humøret ditt er ganske stabilt.", sv: "Ditt humör är ganska stabilt.")
        }

        let message = t.text(
            it: "Negli ultimi \(recentEntries.count) check-in torna spesso una voce \(dominantMood.label(in: language).lowercased()). Questo e il momento giusto per notare il ritmo, non per giudicarlo.",
            en: "Across your last \(recentEntries.count) check-ins, a \(dominantMood.label(in: language).lowercased()) tone comes back often. This is the right time to notice the rhythm, not judge it.",
            es: "En tus últimos \(recentEntries.count) check-ins vuelve a aparecer un tono \(dominantMood.label(in: language).lowercased()). Este es el momento de notar el ritmo, no de juzgarlo.",
            fr: "Dans tes \(recentEntries.count) derniers check-ins, une tonalité \(dominantMood.label(in: language).lowercased()) revient souvent. C'est le bon moment pour observer le rythme, pas pour le juger.",
            zh: "在最近的 \(recentEntries.count) 次记录里，\(dominantMood.label(in: language).lowercased()) 这种状态反复出现。现在更适合观察节奏，而不是评判自己。",
            ar: "في آخر \(recentEntries.count) تسجيلاتك، تظهر نبرة \(dominantMood.label(in: language).lowercased()) كثيراً. هذا وقت ملاحظة الإيقاع لا الحكم عليه.",
            da: "I dine seneste \(recentEntries.count) check-ins vender en \(dominantMood.label(in: language).lowercased()) tone ofte tilbage. Nu er det tid til at lægge mærke til rytmen, ikke dømme den.",
            nb: "I de siste \(recentEntries.count) innsjekkene dine kommer en \(dominantMood.label(in: language).lowercased()) tone ofte tilbake. Nå er tiden inne for å legge merke til rytmen, ikke dømme den.",
            sv: "I dina senaste \(recentEntries.count) check-ins återkommer en \(dominantMood.label(in: language).lowercased()) ton ofta. Nu är det läge att lägga märke till rytmen, inte döma den."
        )

        let detailTitle = t.text(it: "Registrazioni utili", en: "Useful entries", es: "Registros útiles", fr: "Entrées utiles", zh: "有效记录", ar: "تسجيلات مفيدة", da: "Nyttige registreringer", nb: "Nyttige registreringer", sv: "Användbara registreringar")
        let detailValue = "\(recentEntries.count)/7"

        let detailMessage: String
        if trend > 0.12 {
            detailMessage = t.text(it: "La seconda parte della settimana e piu leggera della prima.", en: "The second half of the week feels lighter than the first.", es: "La segunda parte de la semana se siente más ligera que la primera.", fr: "La seconde partie de la semaine semble plus légère que la première.", zh: "这周后半段比前半段更轻一些。", ar: "النصف الثاني من الأسبوع أخف من الأول.", da: "Den sidste del af ugen føles lettere end den første.", nb: "Den siste delen av uken føles lettere enn den første.", sv: "Den senare delen av veckan känns lättare än den första.")
        } else if trend < -0.12 {
            detailMessage = t.text(it: "Vale la pena proteggere un po' di spazio nei prossimi due giorni.", en: "It's worth protecting a bit of space over the next two days.", es: "Vale la pena proteger un poco de espacio en los próximos dos días.", fr: "Cela vaut la peine de préserver un peu d'espace dans les deux prochains jours.", zh: "接下来两天值得给自己留一点空白。", ar: "يجدر بك أن تحمي بعض المساحة خلال اليومين المقبلين.", da: "Det er værd at beskytte lidt plads de næste to dage.", nb: "Det er verdt å beskytte litt rom de neste to dagene.", sv: "Det är värt att skydda lite utrymme de kommande två dagarna.")
        } else {
            detailMessage = t.text(it: "Il tono cambia poco: segno utile, non noioso.", en: "The tone changes little: useful, not boring.", es: "El tono cambia poco: es una señal útil, no aburrida.", fr: "Le ton change peu : c'est utile, pas ennuyeux.", zh: "整体变化不大，这是一种有用的信号，不是无聊。", ar: "النبرة لا تتغير كثيراً: وهذه إشارة مفيدة، لا مملة.", da: "Tonen ændrer sig kun lidt: det er nyttigt, ikke kedeligt.", nb: "Tonen endrer seg lite: det er nyttig, ikke kjedelig.", sv: "Tonen förändras lite: det är användbart, inte tråkigt.")
        }

        let trendLabel: String
        if trend > 0.12 {
            trendLabel = t.text(it: "In lieve salita", en: "Gently rising", es: "En ligera subida", fr: "En légère hausse", zh: "略有上升", ar: "في ارتفاع طفيف", da: "Svagt stigende", nb: "Svakt stigende", sv: "Svagt stigande")
        } else if trend < -0.12 {
            trendLabel = t.text(it: "In lieve calo", en: "Gently falling", es: "En ligera bajada", fr: "En légère baisse", zh: "略有下降", ar: "في انخفاض طفيف", da: "Svagt faldende", nb: "Svakt fallende", sv: "Svagt fallande")
        } else {
            trendLabel = t.text(it: "Abbastanza stabile", en: "Fairly stable", es: "Bastante estable", fr: "Assez stable", zh: "比较稳定", ar: "مستقر إلى حد ما", da: "Forholdsvis stabil", nb: "Ganske stabil", sv: "Ganska stabil")
        }

        let energyLabel: String
        if averageEnergy >= 0.78 {
            energyLabel = t.text(it: "Energia alta", en: "High energy", es: "Energía alta", fr: "Énergie haute", zh: "能量较高", ar: "طاقة مرتفعة", da: "Høj energi", nb: "Høy energi", sv: "Hög energi")
        } else if averageEnergy >= 0.56 {
            energyLabel = t.text(it: "Energia moderata", en: "Moderate energy", es: "Energía moderada", fr: "Énergie modérée", zh: "中等能量", ar: "طاقة متوسطة", da: "Moderat energi", nb: "Moderat energi", sv: "Måttlig energi")
        } else {
            energyLabel = t.text(it: "Energia delicata", en: "Delicate energy", es: "Energía delicada", fr: "Énergie délicate", zh: "较脆弱的能量", ar: "طاقة هشة", da: "Sart energi", nb: "Skjør energi", sv: "Skör energi")
        }

        let consistencyLabel: String
        if energySpread < 0.18 {
            consistencyLabel = t.text(it: "Molto regolare", en: "Very steady", es: "Muy regular", fr: "Très régulier", zh: "非常稳定", ar: "منتظم جداً", da: "Meget stabil", nb: "Veldig jevn", sv: "Mycket jämn")
        } else if energySpread < 0.36 {
            consistencyLabel = t.text(it: "Abbastanza regolare", en: "Fairly steady", es: "Bastante regular", fr: "Assez régulier", zh: "比较稳定", ar: "منتظم إلى حد ما", da: "Forholdsvis stabil", nb: "Ganske jevn", sv: "Ganska jämn")
        } else {
            consistencyLabel = t.text(it: "Più variabile", en: "More variable", es: "Más variable", fr: "Plus variable", zh: "波动更大", ar: "أكثر تقلباً", da: "Mere svingende", nb: "Mer variabel", sv: "Mer varierande")
        }

        let premiumInsightTitle: String
        let premiumInsightMessage: String
        let premiumSuggestion: String

        switch (dominantMood, trend > 0.12, trend < -0.12) {
        case (.anxious, _, true):
            premiumInsightTitle = t.text(it: "C'è un attrito che torna spesso", en: "There's a recurring friction point", es: "Hay una fricción que vuelve a aparecer", fr: "Il y a une friction récurrente", zh: "有一种反复出现的阻力感", ar: "هناك احتكاك يتكرر كثيراً", da: "Der er en tilbagevendende modstand", nb: "Det er en friksjon som går igjen", sv: "Det finns en återkommande friktion")
            premiumInsightMessage = t.text(it: "La parte finale dei check-in sembra più tesa dell'inizio. Non è un picco isolato: è un segnale da prendere sul serio, ma senza allarme.", en: "The latter part of your check-ins feels more tense than the beginning. This isn't an isolated spike: it's a signal worth taking seriously, without panic.", es: "La parte final de tus check-ins parece más tensa que el inicio. No es un pico aislado: es una señal que vale la pena tomar en serio, sin alarmarse.", fr: "La fin de tes check-ins semble plus tendue que le début. Ce n'est pas un pic isolé : c'est un signal à prendre au sérieux, sans alarme.", zh: "你最近记录的后半段比前半段更紧绷。这不是一次孤立波动，而是一个值得认真看待、但不必惊慌的信号。", ar: "يبدو الجزء الأخير من تسجيلاتك أكثر توتراً من البداية. هذه ليست قفزة معزولة، بل إشارة تستحق الانتباه من دون هلع.", da: "Den sidste del af dine check-ins virker mere anspændt end begyndelsen. Det er ikke en enkeltstående top, men et signal værd at tage alvorligt uden alarm.", nb: "Den siste delen av innsjekkene dine virker mer anspent enn begynnelsen. Dette er ikke en isolert topp, men et signal det er verdt å ta på alvor uten alarm.", sv: "Den senare delen av dina check-ins känns mer spänd än början. Det här är ingen enstaka topp, utan en signal värd att ta på allvar utan att slå larm.")
            premiumSuggestion = t.text(it: "Nei prossimi due giorni prova a tenere leggero almeno un impegno e nota se il tono si abbassa.", en: "Over the next two days, try keeping at least one commitment light and notice whether the tone softens.", es: "Durante los próximos dos días, intenta mantener ligero al menos un compromiso y observa si el tono baja.", fr: "Dans les deux prochains jours, essaie de garder au moins un engagement léger et vois si le ton s'apaise.", zh: "接下来两天，尽量让至少一项安排变轻一些，看看整体状态会不会缓下来。", ar: "خلال اليومين المقبلين، حاول أن تُبقي التزاماً واحداً على الأقل خفيفاً ولاحظ إن كانت النبرة تهدأ.", da: "De næste to dage kan du prøve at holde mindst én aftale let og se, om tonen mildnes.", nb: "De neste to dagene kan du prøve å holde minst én forpliktelse lett og legge merke til om tonen mykner.", sv: "Under de kommande två dagarna, försök att hålla åtminstone ett åtagande lätt och se om tonen mjuknar.")
        case (.good, true, _), (.excellent, true, _):
            premiumInsightTitle = t.text(it: "Stai recuperando bene", en: "You're recovering well", es: "Te estás recuperando bien", fr: "Tu récupères bien", zh: "你正在恢复得不错", ar: "أنت تستعيد توازنك جيداً", da: "Du er ved at komme godt tilbage", nb: "Du henter deg godt inn", sv: "Du återhämtar dig bra")
            premiumInsightMessage = t.text(it: "L'energia media sale e il tono dominante resta positivo. È il momento in cui conviene consolidare il ritmo, non riempire tutto.", en: "Average energy is rising and the dominant tone stays positive. This is the moment to consolidate the rhythm, not fill every gap.", es: "La energía media sube y el tono dominante sigue siendo positivo. Es el momento de consolidar el ritmo, no de llenarlo todo.", fr: "L'énergie moyenne monte et le ton dominant reste positif. C'est le moment de consolider le rythme, pas de tout remplir.", zh: "平均能量在上升，而且主导状态依然偏积极。现在适合巩固节奏，而不是把空档塞满。", ar: "يرتفع متوسط الطاقة وتبقى النبرة الغالبة إيجابية. هذا وقت تثبيت الإيقاع لا ملء كل الفراغات.", da: "Den gennemsnitlige energi stiger, og den dominerende tone er stadig positiv. Nu gælder det om at fastholde rytmen, ikke fylde alt ud.", nb: "Gjennomsnittsenergien stiger, og den dominerende tonen holder seg positiv. Nå gjelder det å konsolidere rytmen, ikke fylle opp alt.", sv: "Den genomsnittliga energin stiger och den dominerande tonen förblir positiv. Nu är det läge att befästa rytmen, inte fylla varje lucka.")
            premiumSuggestion = t.text(it: "Proteggi le abitudini che hanno funzionato questa settimana e non aggiungere troppo rumore.", en: "Protect the habits that worked this week and don't add too much noise.", es: "Protege los hábitos que funcionaron esta semana y no añadas demasiado ruido.", fr: "Protège les habitudes qui ont fonctionné cette semaine et n'ajoute pas trop de bruit.", zh: "把这周有效的习惯保护住，不要再增加太多噪音。", ar: "احمِ العادات التي نجحت هذا الأسبوع ولا تضف كثيراً من الضجيج.", da: "Beskyt de vaner, der virkede denne uge, og tilføj ikke for meget støj.", nb: "Beskytt vanene som fungerte denne uken, og ikke legg til for mye støy.", sv: "Skydda vanorna som fungerade den här veckan och lägg inte till för mycket brus.")
        case (.neutral, _, _):
            premiumInsightTitle = t.text(it: "La base regge", en: "The base is holding", es: "La base se mantiene", fr: "La base tient", zh: "基础状态撑得住", ar: "الأساس متماسك", da: "Basen holder", nb: "Basen holder", sv: "Grunden håller")
            premiumInsightMessage = t.text(it: "Non emergono strappi forti. Il quadro è più di continuità che di picchi, e questo è utile perché rende leggibili i cambi veri.", en: "No sharp breaks stand out. The picture is more about continuity than spikes, and that's useful because it makes real shifts easier to read.", es: "No aparecen rupturas fuertes. El cuadro habla más de continuidad que de picos, y eso es útil porque hace más legibles los cambios reales.", fr: "Aucune cassure forte ne ressort. Le tableau parle plus de continuité que de pics, et c'est utile parce que cela rend les vrais changements plus lisibles.", zh: "目前看不出明显断裂。整体更像连续变化而不是尖峰，这反而有助于识别真正的变化。", ar: "لا تظهر انقطاعات حادة. الصورة أقرب إلى الاستمرارية منها إلى القمم، وهذا مفيد لأنه يجعل التغييرات الحقيقية أوضح.", da: "Der tegner sig ingen skarpe brud. Billedet handler mere om kontinuitet end om udsving, og det er nyttigt, fordi det gør reelle ændringer lettere at se.", nb: "Det er ingen tydelige brudd. Bildet handler mer om kontinuitet enn topper, og det er nyttig fordi det gjør reelle endringer lettere å lese.", sv: "Det syns inga skarpa brott. Bilden handlar mer om kontinuitet än toppar, och det är användbart eftersom verkliga förändringar blir lättare att se.")
            premiumSuggestion = t.text(it: "Continua a registrarti con costanza: con altri check-in il pattern diventa molto più nitido.", en: "Keep checking in consistently: with a few more entries, the pattern will become much clearer.", es: "Sigue registrándote con constancia: con algunos check-ins más, el patrón será mucho más claro.", fr: "Continue à te enregistrer avec régularité : avec quelques entrées de plus, le schéma deviendra bien plus net.", zh: "继续稳定记录，再多几次打卡，模式会清晰得多。", ar: "واصل التسجيل بانتظام: مع بعض الإدخالات الإضافية سيصبح النمط أوضح بكثير.", da: "Fortsæt med at registrere dig stabilt: med et par flere check-ins bliver mønstret langt tydeligere.", nb: "Fortsett å registrere jevnlig: med noen flere innsjekker blir mønsteret mye tydeligere.", sv: "Fortsätt checka in regelbundet: med några fler registreringar blir mönstret mycket tydligare.")
        default:
            premiumInsightTitle = t.text(it: "C'è un pattern leggibile", en: "There's a readable pattern", es: "Hay un patrón legible", fr: "Il y a un schéma lisible", zh: "这里有一个可读的模式", ar: "هناك نمط يمكن قراءته", da: "Der er et læsbart mønster", nb: "Det er et lesbart mønster", sv: "Det finns ett tydligt mönster")
            premiumInsightMessage = t.text(it: "Il tono dominante è \(dominantMood.label(in: language).lowercased()) e il ritmo generale è \(trendLabel.lowercased()). Non basta per una diagnosi, ma basta per orientarti meglio.", en: "The dominant tone is \(dominantMood.label(in: language).lowercased()) and the overall rhythm is \(trendLabel.lowercased()). That's not enough for a diagnosis, but it's enough to orient yourself better.", es: "El tono dominante es \(dominantMood.label(in: language).lowercased()) y el ritmo general es \(trendLabel.lowercased()). No basta para un diagnóstico, pero sí para orientarte mejor.", fr: "Le ton dominant est \(dominantMood.label(in: language).lowercased()) et le rythme général est \(trendLabel.lowercased()). Ce n'est pas suffisant pour un diagnostic, mais c'est assez pour mieux t'orienter.", zh: "主导状态是 \(dominantMood.label(in: language).lowercased())，整体节奏是 \(trendLabel.lowercased())。这当然不能构成诊断，但已经足够帮助你更好地判断方向。", ar: "النبرة الغالبة هي \(dominantMood.label(in: language).lowercased()) والإيقاع العام هو \(trendLabel.lowercased()). هذا لا يكفي للتشخيص، لكنه يكفي لتوجيهك بشكل أفضل.", da: "Den dominerende tone er \(dominantMood.label(in: language).lowercased()), og den overordnede rytme er \(trendLabel.lowercased()). Det er ikke nok til en diagnose, men nok til at hjælpe dig med at orientere dig bedre.", nb: "Den dominerende tonen er \(dominantMood.label(in: language).lowercased()), og den generelle rytmen er \(trendLabel.lowercased()). Det er ikke nok for en diagnose, men nok til å hjelpe deg å orientere deg bedre.", sv: "Den dominerande tonen är \(dominantMood.label(in: language).lowercased()) och den övergripande rytmen är \(trendLabel.lowercased()). Det räcker inte för en diagnos, men väl för att hjälpa dig orientera dig bättre.")
            premiumSuggestion = t.text(it: "Guarda soprattutto cosa succede nei giorni in cui senti più attrito o più slancio: lì si vede il pattern vero.", en: "Pay special attention to what happens on the days that feel heavier or more energized: that's where the real pattern shows up.", es: "Observa sobre todo qué pasa en los días en que sientes más fricción o más impulso: ahí aparece el patrón real.", fr: "Regarde surtout ce qui se passe les jours où tu sens plus de friction ou plus d'élan : c'est là que le vrai schéma apparaît.", zh: "重点看看那些阻力更大或动力更强的日子，真正的模式通常就藏在那里。", ar: "انتبه خصوصاً لما يحدث في الأيام التي تشعر فيها باحتكاك أكبر أو اندفاع أكبر: هناك يظهر النمط الحقيقي.", da: "Se især på, hvad der sker de dage, hvor du mærker mere modstand eller mere drivkraft: dér viser det egentlige mønster sig.", nb: "Se særlig på hva som skjer de dagene du kjenner mer friksjon eller mer driv: det er der det egentlige mønsteret viser seg.", sv: "Titta särskilt på vad som händer de dagar som känns tyngre eller mer drivna: det är där det verkliga mönstret syns.")
        }

        return MoodReflectionSnapshot(
            title: title,
            message: message,
            detailTitle: detailTitle,
            detailValue: detailValue,
            detailMessage: detailMessage,
            dominantMoodLabel: dominantMood.label(in: language),
            trendLabel: trendLabel,
            energyLabel: energyLabel,
            consistencyLabel: consistencyLabel,
            premiumInsightTitle: premiumInsightTitle,
            premiumInsightMessage: premiumInsightMessage,
            premiumSuggestion: premiumSuggestion
        )
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            entries = try JSONDecoder().decode([MoodEntry].self, from: data)
                .sorted { $0.date < $1.date }
        } catch {
            entries = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Unable to persist mood entries: \(error)")
        }
    }
}

@MainActor
final class EmotionViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var selectedMood: MoodLevel? = nil
    @Published var noteText = ""
    @Published var showSuccess = false

    private let store: MoodJournalStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: MoodJournalStore = .shared) {
        self.store = store
        self.entries = store.entries
        self.selectedMood = store.entries.last?.mood

        store.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] entries in
                self?.entries = entries
                if let todayMood = entries.last(where: { Calendar.current.isDateInToday($0.date) })?.mood {
                    self?.selectedMood = todayMood
                }
            }
            .store(in: &cancellables)
    }

    func weekData(language: AppLanguage) -> [(day: String, entry: MoodEntry?)] {
        let calendar = Calendar.current
        let days = language.weekdaySymbolsMondayFirst
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let mondayOffset = (todayWeekday == 1 ? -6 : -(todayWeekday - 2))

        return days.enumerated().map { index, day in
            guard let date = calendar.date(byAdding: .day, value: mondayOffset + index, to: today) else {
                return (day, nil)
            }
            return (day, store.entry(for: date))
        }
    }

    var hasLoggedToday: Bool {
        entries.contains { Calendar.current.isDateInToday($0.date) }
    }

    func weekBarData(language: AppLanguage) -> [(day: String, height: Double, color: Color)] {
        weekData(language: language).map { item in
            if let entry = item.entry {
                return (item.day, entry.mood.energyValue, entry.mood.color)
            } else {
                return (item.day, 0.05, Color.mmSurface)
            }
        }
    }

    var loggedDaysThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    func logMood() {
        guard let mood = selectedMood else { return }
        store.saveEntry(mood: mood, note: noteText)
        noteText = ""
        withAnimation {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showSuccess = false
            }
        }
    }
}
