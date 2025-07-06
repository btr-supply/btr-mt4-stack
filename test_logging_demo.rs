// Demo of the improved test logging system

struct TestResults {
    passed: u32,
    failed: u32,
    failed_tests: Vec<String>,
}

impl TestResults {
    fn new() -> Self {
        TestResults {
            passed: 0,
            failed: 0,
            failed_tests: Vec::new(),
        }
    }
    
    fn pass(&mut self, test_name: &str) {
        self.passed += 1;
        println!("✅ {}", test_name);
    }
    
    fn fail(&mut self, test_name: &str) {
        self.failed += 1;
        self.failed_tests.push(test_name.to_string());
        println!("❌ {}", test_name);
    }
    
    fn assert_condition(&mut self, condition: bool, test_name: &str) {
        if condition {
            self.pass(test_name);
        } else {
            self.fail(test_name);
        }
    }
    
    fn summary(&self) -> bool {
        let total = self.passed + self.failed;
        println!("\n=== Test Summary ===");
        println!("Total tests: {}", total);
        println!("Passed: {}", self.passed);
        println!("Failed: {}", self.failed);
        
        if self.failed > 0 {
            println!("\nFailed tests:");
            for test in &self.failed_tests {
                println!("  • {}", test);
            }
            false
        } else {
            true
        }
    }
}

fn main() {
    println!("=== Logging Demo ===");
    let mut results = TestResults::new();
    
    // Test some conditions
    results.assert_condition(true, "This test should pass");
    results.assert_condition(false, "This test should fail");
    results.assert_condition(true, "Another passing test");
    results.assert_condition(false, "Another failing test");
    
    // Final summary
    let all_passed = results.summary();
    
    if all_passed {
        println!("\n🎉 All tests completed successfully! 🎉");
    } else {
        println!("\n💥 Some tests failed! 💥");
    }
} 