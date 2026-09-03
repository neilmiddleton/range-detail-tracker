func runAllTests(filter: String?) -> Never {
    func matches(_ name: String) -> Bool {
        filter == nil || name.contains(filter!)
    }

    if matches("ModelPersistenceTests") {
        for (name, method) in ModelPersistenceTests.allTests {
            TestRunner.shared.run(name) { try method(ModelPersistenceTests())() }
        }
    }

    TestRunner.shared.finish()
}
