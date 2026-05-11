import Foundation

struct KoreanGlossary {
    private let overrides: [String: String] = [
        "regression": "1) 회귀\n2) 퇴행\n3) 회귀 분석",
        "vindication": "1) 정당성 입증\n2) 결백 증명\n3) 옹호",
        "ensuing": "뒤이어 일어나는, 그 후의",
        "tyro": "초보자, 입문자",
        "abyss": "심연, 깊은 구렁",
        "serendipity": "뜻밖의 발견, 우연한 행운",
        "resilience": "회복력, 탄력성",
        "scrutiny": "정밀 조사, 면밀한 검토",
        "tenacity": "끈기, 집요함",
        "ephemeral": "순식간의, 덧없는"
    ]

    func meaning(for word: String) -> String? {
        let key = word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return overrides[key]
    }
}
