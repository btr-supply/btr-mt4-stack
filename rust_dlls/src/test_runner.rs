use std::os::raw::{c_int, c_uchar};
use libloading::Library;
use std::fs;
use std::env;
use url::Url;

// Redis DLL Test Runner
// Environment variables (optional):
//   REDIS_URL - Redis connection URL (default: redis://127.0.0.1:6379)
//   REDIS_USER - Redis username (default: empty)
//   REDIS_PASSWORD - Redis password (default: empty)

// Test result tracking
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

// Dummy unwind functions needed for mingw32 cross-compilation
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _Unwind_RaiseException() -> u32 {
    0
}

// Function type definitions for DLL exports - raw bytes interface
type TestByteEchoFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *mut c_uchar, c_int) -> c_int;
type ConnectFn = unsafe extern "stdcall" fn(*const c_uchar, c_int) -> c_int;
type AuthFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *const c_uchar, c_int) -> c_int;
type SetFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *const c_uchar, c_int) -> c_int;
type SetExFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *const c_uchar, c_int, c_int) -> c_int;
type GetFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *mut c_uchar, c_int) -> c_int;
type MsetFn = unsafe extern "stdcall" fn(*const c_uchar, c_int) -> c_int;
type MgetFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *mut c_uchar, c_int) -> c_int;
type PublishFn = unsafe extern "stdcall" fn(*const c_uchar, c_int, *const c_uchar, c_int) -> c_int;
type DisconnectFn = unsafe extern "stdcall" fn() -> c_int;
type IsConnectedFn = unsafe extern "stdcall" fn() -> c_int;
type PingFn = unsafe extern "stdcall" fn() -> c_int;

// Simple .env file loader
fn load_env_file() {
    if let Ok(content) = fs::read_to_string("../.env") {
        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            
            if let Some(pos) = line.find('=') {
                let key = &line[..pos];
                let value = &line[pos + 1..];
                env::set_var(key, value);
                println!("🔧 Loaded env: {}={}", key, value);
            }
        }
    } else {
        println!("⚠️  No .env file found, using defaults");
    }
}

// Helper function to construct Redis URL with proper credential injection
fn construct_redis_url() -> String {
    let base_url = env::var("REDIS_URL").unwrap_or("redis://localhost:6379".to_string());
    let user = env::var("REDIS_USER").unwrap_or("".to_string());
    let password = env::var("REDIS_PASSWORD").unwrap_or("".to_string());
    
    if user.is_empty() || password.is_empty() {
        base_url
    } else {
        let url = url::Url::parse(&base_url).unwrap();
        format!("redis://{}:{}@{}:{}/", user, password, url.host_str().unwrap(), url.port().unwrap_or(6379))
    }
}

// Helper function to construct Redis URL without credentials (for auth testing)
fn construct_redis_url_no_auth() -> String {
    let base_url = env::var("REDIS_URL").unwrap_or("redis://localhost:6379".to_string());
    let url = url::Url::parse(&base_url).unwrap();
    format!("redis://{}:{}/", url.host_str().unwrap(), url.port().unwrap_or(6379))
}

// Helper function to build MSET payload
fn build_mset_payload(pairs: &[(&str, &str)]) -> Vec<u8> {
    let mut payload = Vec::new();
    for (key, value) in pairs {
        payload.extend_from_slice(&(key.len() as u32).to_be_bytes());
        payload.extend_from_slice(key.as_bytes());
        payload.extend_from_slice(&(value.len() as u32).to_be_bytes());
        payload.extend_from_slice(value.as_bytes());
    }
    payload
}

// Helper function to build MGET payload
fn build_mget_payload(keys: &[&str]) -> Vec<u8> {
    let mut payload = Vec::new();
    for key in keys {
        payload.extend_from_slice(&(key.len() as u32).to_be_bytes());
        payload.extend_from_slice(key.as_bytes());
    }
    payload
}

// Helper function to parse MGET response
fn parse_mget_response(buffer: &[u8]) -> Result<Vec<Option<String>>, &'static str> {
    let mut values = Vec::new();
    let mut offset = 0;
    
    while offset + 4 <= buffer.len() {
        let len_bytes = match buffer[offset..offset + 4].try_into() {
            Ok(bytes) => bytes,
            Err(_) => return Err("Failed to read length bytes"),
        };
        let len = u32::from_be_bytes(len_bytes) as usize;
        offset += 4;
        
        if len == 0 {
            // NULL value
            values.push(None);
        } else if offset + len <= buffer.len() {
            let value_data = &buffer[offset..offset + len];
            let value_str = String::from_utf8_lossy(value_data).to_string();
            values.push(Some(value_str));
            offset += len;
        } else {
            return Err("Incomplete value data");
        }
    }
    
    Ok(values)
}

// Macro to safely load DLL symbols with error handling
macro_rules! load_symbol {
    ($lib:expr, $results:expr, $symbol_name:expr, $symbol_type:ty) => {
        match unsafe { $lib.get::<$symbol_type>($symbol_name.as_bytes()) } {
            Ok(symbol) => symbol,
            Err(e) => {
                $results.fail(&format!("Failed to load '{}' symbol: {}", $symbol_name, e));
                return;
            }
        }
    };
}

fn main() {
    println!("=== Redis DLL Test Runner (Raw Bytes) ===");
    
    // Load environment variables from .env file
    load_env_file();
    
    let mut results = TestResults::new();

    let lib_path = "../Libraries/redis_client.dll";

    let lib = match unsafe { Library::new(lib_path) } {
        Ok(l) => {
            results.pass(&format!("DLL loaded successfully from: {}", lib_path));
            l
        },
        Err(e) => {
            results.fail(&format!("Failed to load DLL: {}", e));
            println!("\n=== Tests aborted due to DLL loading failure ===");
            std::process::exit(1);
        }
    };
    
    // Test 1: DLL Exports
    println!("\n--- Test 1: DLL Exports ---");
    test_dll_exports(&lib, &mut results);
    
    // Test 2: Byte Echo Function
    println!("\n--- Test 2: Byte Echo Function ---");
    test_byte_echo(&lib, &mut results);
    
    // Test 3: Connection Functions
    println!("\n--- Test 3: Connection Functions ---");
    test_connection_functions(&lib, &mut results);
    
    // Test 4: Auth Function (separate from connection)
    println!("\n--- Test 4: Auth Function ---");
    test_auth_function(&lib, &mut results);
    
    // Test 5: Redis Operations
    println!("\n--- Test 5: Redis Operations ---");
    test_redis_operations(&lib, &mut results);
    
    // Final summary
    let all_passed = results.summary();
    
    if all_passed {
        println!("\n🎉 All tests completed successfully! 🎉");
        std::process::exit(0);
    } else {
        println!("\n💥 Some tests failed! 💥");
        std::process::exit(1);
    }
}

fn test_dll_exports(lib: &Library, results: &mut TestResults) {
    let exports = [
        "redis_test_byte_echo", "redis_connect", "redis_auth", "redis_disconnect", "redis_is_connected", "redis_ping",
        "redis_set", "redis_set_ex", "redis_get", "redis_mset", "redis_mget", "redis_publish"
    ];
    
    for export in &exports {
        match unsafe { lib.get::<*const ()>(export.as_bytes()) } {
            Ok(_) => results.pass(&format!("Export found: {}", export)),
            Err(_) => results.fail(&format!("Export missing: {}", export)),
        }
    }
}

fn test_byte_echo(lib: &Library, results: &mut TestResults) {
    let echo_fn = load_symbol!(lib, results, "redis_test_byte_echo", TestByteEchoFn);
    
    let test_string = "Hello Raw Bytes!";
    let test_bytes = test_string.as_bytes();
    let mut output_buffer = vec![0u8; 256];
    
    unsafe {
        let result = echo_fn(test_bytes.as_ptr(), test_bytes.len() as c_int, output_buffer.as_mut_ptr(), 256);
        
        if result > 0 {
            let output_str = String::from_utf8_lossy(&output_buffer[..result as usize]);
            if test_string == output_str {
                results.pass(&format!("Byte echo test passed: '{}' -> '{}'", test_string, output_str));
            } else {
                results.fail(&format!("Byte echo test failed: expected '{}', got '{}'", test_string, output_str));
            }
        } else {
            results.fail(&format!("Byte echo test failed: return code {}", result));
        }
    }
}

fn test_connection_functions(lib: &Library, results: &mut TestResults) {
    let connect_fn = load_symbol!(lib, results, "redis_connect", ConnectFn);
    let is_connected_fn = load_symbol!(lib, results, "redis_is_connected", IsConnectedFn);
    let ping_fn = load_symbol!(lib, results, "redis_ping", PingFn);
    let disconnect_fn = load_symbol!(lib, results, "redis_disconnect", DisconnectFn);
    
    unsafe {
        // Test connection with credentials in URL (via redis_connect)
        let redis_url = construct_redis_url();
        let conn_bytes = redis_url.as_bytes();
        
        println!("🔍 Environment variables:");
        println!("  REDIS_URL: {:?}", env::var("REDIS_URL"));
        println!("  REDIS_USER: {:?}", env::var("REDIS_USER"));
        println!("  REDIS_PASSWORD: {:?}", env::var("REDIS_PASSWORD"));
        println!("📡 Constructed Redis URL: {}", redis_url);
        println!("📏 URL bytes length: {}", conn_bytes.len());
        
        let connect_result = connect_fn(conn_bytes.as_ptr(), conn_bytes.len() as c_int);
        println!("📋 Connect function returned: {}", connect_result);
        results.assert_condition(connect_result == 1, "Redis connection");
        
        // Test is_connected
        let connected = is_connected_fn();
        results.assert_condition(connected == 1, "Connection state check");
        
        // Test ping (only if connected)
        if connected == 1 {
            let ping_result = ping_fn();
            results.assert_condition(ping_result == 1, "Ping test");
        } else {
            results.fail("Ping test (skipped - not connected)");
        }
        
        // Test disconnect
        let disconnect_result = disconnect_fn();
        results.assert_condition(disconnect_result == 1, "Disconnect");
        
        // Test is_connected after disconnect
        let connected_after = is_connected_fn();
        results.assert_condition(connected_after == 0, "Connection state after disconnect");
    }
}

fn test_auth_function(lib: &Library, results: &mut TestResults) {
    let connect_fn = load_symbol!(lib, results, "redis_connect", ConnectFn);
    let auth_fn = load_symbol!(lib, results, "redis_auth", AuthFn);
    let disconnect_fn = load_symbol!(lib, results, "redis_disconnect", DisconnectFn);
    let ping_fn = load_symbol!(lib, results, "redis_ping", PingFn);
    
    unsafe {
        // Only test auth if credentials are provided
        if let (Ok(username), Ok(password)) = (env::var("REDIS_USER"), env::var("REDIS_PASSWORD")) {
            // Connect using URL without credentials
            let redis_url_no_auth = construct_redis_url_no_auth();
            let conn_bytes = redis_url_no_auth.as_bytes();
            
            println!("🔐 Testing authentication separately from connection:");
            println!("  Connection URL (no auth): {}", redis_url_no_auth);
            println!("  Username: '{}' ({} bytes)", username, username.len());
            println!("  Password: '{}' ({} bytes)", password, password.len());
            
            let connect_result = connect_fn(conn_bytes.as_ptr(), conn_bytes.len() as c_int);
            
            if connect_result == 1 {
                // Now test auth function
                let username_bytes = username.as_bytes();
                let password_bytes = password.as_bytes();
                
                let auth_result = auth_fn(
                    username_bytes.as_ptr(), username_bytes.len() as c_int,
                    password_bytes.as_ptr(), password_bytes.len() as c_int
                );
                
                println!("📋 Auth function returned: {}", auth_result);
                results.assert_condition(auth_result == 1, "Redis authentication");
                
                // Test that auth worked by trying a ping
                if auth_result == 1 {
                    let ping_result = ping_fn();
                    results.assert_condition(ping_result == 1, "Ping after auth");
                } else {
                    results.fail("Ping after auth (skipped - auth failed)");
                }
                
                // Disconnect
                disconnect_fn();
            } else {
                results.fail("Connection for auth test (without credentials in URL)");
            }
        } else {
            println!("🔐 Skipping auth function test - no credentials provided");
            results.pass("Auth function test (skipped - no credentials)");
        }
    }
}

fn test_redis_operations(lib: &Library, results: &mut TestResults) {
    let connect_fn = load_symbol!(lib, results, "redis_connect", ConnectFn);
    let set_fn = load_symbol!(lib, results, "redis_set", SetFn);
    let set_ex_fn = load_symbol!(lib, results, "redis_set_ex", SetExFn);
    let get_fn = load_symbol!(lib, results, "redis_get", GetFn);
    let mset_fn = load_symbol!(lib, results, "redis_mset", MsetFn);
    let mget_fn = load_symbol!(lib, results, "redis_mget", MgetFn);
    let publish_fn = load_symbol!(lib, results, "redis_publish", PublishFn);
    
    unsafe {
        // Connect with credentials
        let redis_url = construct_redis_url();
        let conn_bytes = redis_url.as_bytes();
        let connect_result = connect_fn(conn_bytes.as_ptr(), conn_bytes.len() as c_int);
        
        if connect_result != 1 {
            results.fail("Redis connection for operations");
            println!("⚠️  Skipping Redis operations tests - connection failed");
            return;
        }
        
        // Test SET
        let key = "test_key";
        let value = "test_value";
        let key_bytes = key.as_bytes();
        let value_bytes = value.as_bytes();
        
        let set_result = set_fn(
            key_bytes.as_ptr(), key_bytes.len() as c_int,
            value_bytes.as_ptr(), value_bytes.len() as c_int
        );
        results.assert_condition(set_result == 1, "Redis SET operation");
        
        // Test SETEX
        let key_ex = "test_key_ex";
        let value_ex = "test_value_ex";
        let key_ex_bytes = key_ex.as_bytes();
        let value_ex_bytes = value_ex.as_bytes();
        
        let set_ex_result = set_ex_fn(
            key_ex_bytes.as_ptr(), key_ex_bytes.len() as c_int,
            value_ex_bytes.as_ptr(), value_ex_bytes.len() as c_int,
            60
        );
        results.assert_condition(set_ex_result == 1, "Redis SETEX operation");
        
        // Test GET
        let mut get_buffer = vec![0u8; 1024];
        let get_result = get_fn(
            key_bytes.as_ptr(), key_bytes.len() as c_int,
            get_buffer.as_mut_ptr(), get_buffer.len() as c_int
        );
        
        if get_result > 0 {
            let retrieved_value = String::from_utf8_lossy(&get_buffer[..get_result as usize]);
            if retrieved_value == value {
                results.pass(&format!("Redis GET operation: Retrieved '{}' (expected: '{}')", retrieved_value, value));
            } else {
                results.fail(&format!("Redis GET operation: Retrieved '{}' (expected: '{}')", retrieved_value, value));
            }
        } else {
            results.fail("Redis GET operation: No data returned");
        }
        
        // Test PUBLISH
        let channel = "test_channel";
        let message = "Hello Redis!";
        let channel_bytes = channel.as_bytes();
        let message_bytes = message.as_bytes();
        
        let publish_result = publish_fn(
            channel_bytes.as_ptr(), channel_bytes.len() as c_int,
            message_bytes.as_ptr(), message_bytes.len() as c_int
        );
        results.assert_condition(publish_result == 1, "Redis PUBLISH operation");
        
        // Test binary data
        let binary_key = "binary_key";
        let binary_data = vec![0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE, 0xFD, 0xFC];
        let binary_key_bytes = binary_key.as_bytes();
        
        let binary_set_result = set_fn(
            binary_key_bytes.as_ptr(), binary_key_bytes.len() as c_int,
            binary_data.as_ptr(), binary_data.len() as c_int
        );
        results.assert_condition(binary_set_result == 1, "Redis binary SET operation");
        
        // Test binary GET
        let mut binary_get_buffer = vec![0u8; 1024];
        let binary_get_result = get_fn(
            binary_key_bytes.as_ptr(), binary_key_bytes.len() as c_int,
            binary_get_buffer.as_mut_ptr(), binary_get_buffer.len() as c_int
        );
        
        if binary_get_result > 0 {
            let retrieved_data = &binary_get_buffer[..binary_get_result as usize];
            if retrieved_data == binary_data {
                results.pass(&format!("Redis binary GET operation: Retrieved {} bytes correctly", binary_get_result));
            } else {
                results.fail(&format!("Redis binary GET operation: Data mismatch (got {} bytes)", binary_get_result));
            }
        } else {
            results.fail("Redis binary GET operation: No data returned");
        }
        
        // Test binary PUBLISH
        let binary_channel = "binary_channel";
        let binary_channel_bytes = binary_channel.as_bytes();
        
        let binary_publish_result = publish_fn(
            binary_channel_bytes.as_ptr(), binary_channel_bytes.len() as c_int,
            binary_data.as_ptr(), binary_data.len() as c_int
        );
        results.assert_condition(binary_publish_result == 1, "Redis binary PUBLISH operation");
        
        // Test MSET using helper function
        println!("Testing MSET operation...");
        let mset_pairs = [("mtest_key1", "mtest_value1"), ("mtest_key2", "mtest_value2")];
        let mset_payload = build_mset_payload(&mset_pairs);
        let mset_result = mset_fn(mset_payload.as_ptr(), mset_payload.len() as c_int);
        results.assert_condition(mset_result == 1, "Redis MSET operation");
        
        // Test MGET using helper functions
        println!("Testing MGET operation...");
        let mget_keys = ["mtest_key1", "mtest_key2"];
        let mget_payload = build_mget_payload(&mget_keys);
        let mut mget_buffer = vec![0u8; 1024];
        let mget_result = mget_fn(
            mget_payload.as_ptr(), mget_payload.len() as c_int,
            mget_buffer.as_mut_ptr(), mget_buffer.len() as c_int
        );
        
        if mget_result > 0 {
            match parse_mget_response(&mget_buffer[..mget_result as usize]) {
                Ok(values) => {
                    let expected_values = ["mtest_value1", "mtest_value2"];
                    let mut all_correct = true;
                    for (i, (actual, expected)) in values.iter().zip(expected_values.iter()).enumerate() {
                        match actual {
                            Some(val) if val == expected => {
                                println!("    Value {}: '{}' ✓", i + 1, val);
                            }
                            Some(val) => {
                                println!("    Value {}: '{}' (expected: '{}') ✗", i + 1, val, expected);
                                all_correct = false;
                            }
                            None => {
                                println!("    Value {}: NULL (expected: '{}') ✗", i + 1, expected);
                                all_correct = false;
                            }
                        }
                    }
                    if all_correct {
                        results.pass("Redis MGET operation: All values retrieved correctly");
                    } else {
                        results.fail("Redis MGET operation: Some values incorrect");
                    }
                }
                Err(e) => {
                    results.fail(&format!("Redis MGET operation: Failed to parse response: {}", e));
                }
            }
        } else {
            results.fail("Redis MGET operation: No data returned");
        }
    }
} 