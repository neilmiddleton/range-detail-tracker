func runAllTests(filter: String?) -> Never {
    func matches(_ name: String) -> Bool {
        filter == nil || name.contains(filter!)
    }

    if matches("ModelPersistenceTests") {
        for (name, method) in ModelPersistenceTests.allTests {
            TestRunner.shared.run(name) { try method(ModelPersistenceTests())() }
        }
    }

    if matches("ScoringRuleTests") {
        for (name, method) in ScoringRuleTests.allTests {
            TestRunner.shared.run(name) { try method(ScoringRuleTests())() }
        }
    }

    if matches("ProgressionRuleTests") {
        for (name, method) in ProgressionRuleTests.allTests {
            TestRunner.shared.run(name) { try method(ProgressionRuleTests())() }
        }
    }

    if matches("FairnessRankingTests") {
        for (name, method) in FairnessRankingTests.allTests {
            TestRunner.shared.run(name) { try method(FairnessRankingTests())() }
        }
    }

    if matches("DraftDetailGeneratorTests") {
        for (name, method) in DraftDetailGeneratorTests.allTests {
            TestRunner.shared.run(name) { try method(DraftDetailGeneratorTests())() }
        }
    }

    if matches("SessionStoreTests") {
        for (name, method) in SessionStoreTests.allTests {
            TestRunner.shared.run(name) { try method(SessionStoreTests())() }
        }
    }

    TestRunner.shared.finish()
}
