// Redis DLL for MetaTrader 4
// Pure raw bytes interface - no string handling except for Redis connection URL

use std::os::raw::{c_int, c_uchar};
use std::sync::Mutex;
use std::slice;
use std::sync::atomic::{AtomicBool, Ordering};

use redis::{Client, Connection};
use lazy_static::lazy_static;

// Global Redis connection with thread-safe access
lazy_static! {
    static ref REDIS_CONNECTION: Mutex<Option<Connection>> = Mutex::new(None);
    static ref CONNECTION_IN_PROGRESS: AtomicBool = AtomicBool::new(false);
}

// Dummy unwind functions for Windows linking
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _Unwind_RaiseException() -> u32 {
    0
}

// Test function to verify raw bytes handling
#[no_mangle]
pub unsafe extern "stdcall" fn redis_test_byte_echo(input: *const c_uchar, input_len: c_int, output: *mut c_uchar, output_len: c_int) -> c_int {
    if input.is_null() || output.is_null() || input_len <= 0 || output_len <= 0 {
        return 0;
    }
    
    let input_slice = slice::from_raw_parts(input, input_len as usize);
    let output_slice = slice::from_raw_parts_mut(output, output_len as usize);
    
    let copy_len = std::cmp::min(input_len as usize, output_len as usize);
    
    output_slice[..copy_len].copy_from_slice(&input_slice[..copy_len]);
    
    copy_len as c_int
}

// Redis connect (renamed to avoid collision with Winsock 'connect')
#[no_mangle]
pub unsafe extern "stdcall" fn redis_connect(url_bytes: *const c_uchar, url_len: c_int) -> c_int {
    // Early validation to catch corrupted re-entrant calls
    if url_len < 0 || url_len > 1024 {
        eprintln!("🚫 Ignoring corrupted call: url_len={}", url_len);
        return 1;
    }
    
    if url_bytes.is_null() || url_len <= 0 {
        eprintln!("🚨 Invalid parameters: url_bytes={:?}, url_len={}", url_bytes, url_len);
        return 0;
    }
    
    // Check for low invalid pointers
    if (url_bytes as usize) < 0x1000 {
        eprintln!("🚫 Ignoring corrupted pointer: {:p}", url_bytes);
        return 1;
    }
    
    // Check if connection is already in progress
    if CONNECTION_IN_PROGRESS.load(Ordering::SeqCst) {
        eprintln!("🔄 Ignoring re-entrant call during connection");
        return 1;
    }
    
    eprintln!("📡 Starting connection: url_len={}, url_bytes={:p}", url_len, url_bytes);
    
    // Mark connection in progress
    CONNECTION_IN_PROGRESS.store(true, Ordering::SeqCst);
    
    // --- Create a local, owned copy of the URL data ---
    let url_vec = slice::from_raw_parts(url_bytes, url_len as usize).to_vec();
    
    // Only convert to string because redis-rs Client::open() requires it
    let url_str = match std::str::from_utf8(&url_vec) {
        Ok(s) => {
            eprintln!("✅ Parsed URL from local copy: '{}'", s);
            s
        }
        Err(_) => {
            eprintln!("❌ UTF-8 conversion failed on local copy");
            CONNECTION_IN_PROGRESS.store(false, Ordering::SeqCst);
            return 0;
        }
    };
    
    // Wrap the connection attempt in panic protection
    let result = std::panic::catch_unwind(|| {
        eprintln!("🔧 Creating Redis client...");
        
        // Real Redis connection
        match Client::open(url_str) {
            Ok(client) => {
                eprintln!("✅ Client created, establishing connection...");
                match client.get_connection() {
                    Ok(conn) => {
                        eprintln!("✅ Connection established successfully");
                        if let Ok(mut redis_conn) = REDIS_CONNECTION.lock() {
                            *redis_conn = Some(conn);
                            1
                        } else {
                            eprintln!("❌ Failed to store connection");
                            0
                        }
                    }
                    Err(e) => {
                        eprintln!("❌ Connection failed: {}", e);
                        0
                    }
                }
            }
            Err(e) => {
                eprintln!("❌ Client creation failed: {}", e);
                0
            }
        }
    });
    
    let final_result = match result {
        Ok(code) => {
            eprintln!("📋 Connection attempt completed with code: {}", code);
            code
        }
        Err(_) => {
            eprintln!("💥 Panic occurred during connection");
            0
        }
    };
    
    // Always clear the connection flag
    CONNECTION_IN_PROGRESS.store(false, Ordering::SeqCst);
    final_result
}

// Authenticate - only converts bytes to string for redis-rs AUTH requirement
#[no_mangle]
pub unsafe extern "stdcall" fn redis_auth(username: *const c_uchar, username_len: c_int, password: *const c_uchar, password_len: c_int) -> c_int {
    if username.is_null() || username_len <= 0 || password.is_null() || password_len <= 0 {
        return 0;
    }
    
    let username_slice = slice::from_raw_parts(username, username_len as usize);
    let password_slice = slice::from_raw_parts(password, password_len as usize);
    
    // Only convert to strings because redis-rs AUTH needs them
    let username_str = match std::str::from_utf8(username_slice) {
        Ok(s) => s,
        Err(_) => return 0,
    };
    
    let password_str = match std::str::from_utf8(password_slice) {
        Ok(s) => s,
        Err(_) => return 0,
    };
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("AUTH").arg(username_str).arg(password_str).query::<String>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Disconnect from Redis
#[no_mangle]
pub unsafe extern "stdcall" fn redis_disconnect() -> c_int {
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if conn.is_some() {
            *conn = None;
            1
        } else {
            0
        }
    } else {
        0
    }
}

// Check if connected to Redis
#[no_mangle]
pub unsafe extern "stdcall" fn redis_is_connected() -> c_int {
    if let Ok(conn) = REDIS_CONNECTION.lock() {
        if conn.is_some() {
            1
        } else {
            0
        }
    } else {
        0
    }
}

// Ping Redis server
#[no_mangle]
pub unsafe extern "stdcall" fn redis_ping() -> c_int {
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("PING").query::<String>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Set key-value pair - raw bytes interface
#[no_mangle]
pub unsafe extern "stdcall" fn redis_set(key_bytes: *const c_uchar, key_len: c_int, value_bytes: *const c_uchar, value_len: c_int) -> c_int {
    if key_bytes.is_null() || key_len <= 0 || value_bytes.is_null() || value_len <= 0 {
        return 0;
    }
    
    let key_slice = slice::from_raw_parts(key_bytes, key_len as usize);
    let value_slice = slice::from_raw_parts(value_bytes, value_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("SET").arg(key_slice).arg(value_slice).query::<String>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Set key-value pair with expiration - raw bytes interface
#[no_mangle]
pub unsafe extern "stdcall" fn redis_set_ex(key_bytes: *const c_uchar, key_len: c_int, value_bytes: *const c_uchar, value_len: c_int, expire_seconds: c_int) -> c_int {
    if key_bytes.is_null() || key_len <= 0 || value_bytes.is_null() || value_len <= 0 || expire_seconds <= 0 {
        return 0;
    }
    
    let key_slice = slice::from_raw_parts(key_bytes, key_len as usize);
    let value_slice = slice::from_raw_parts(value_bytes, value_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("SETEX").arg(key_slice).arg(expire_seconds).arg(value_slice).query::<String>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Get value by key - raw bytes interface with caller-allocated buffer
#[no_mangle]
pub unsafe extern "stdcall" fn redis_get(key_bytes: *const c_uchar, key_len: c_int, value_buffer: *mut c_uchar, buffer_len: c_int) -> c_int {
    if key_bytes.is_null() || key_len <= 0 || value_buffer.is_null() || buffer_len <= 0 {
        return 0;
    }
    
    let key_slice = slice::from_raw_parts(key_bytes, key_len as usize);
    let output_slice = slice::from_raw_parts_mut(value_buffer, buffer_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("GET").arg(key_slice).query::<Vec<u8>>(connection) {
                Ok(data) => {
                    let copy_len = std::cmp::min(data.len(), buffer_len as usize);
                    output_slice[..copy_len].copy_from_slice(&data[..copy_len]);
                    copy_len as c_int
                }
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Multi-set operation - raw bytes interface
#[no_mangle]
pub unsafe extern "stdcall" fn redis_mset(payload_bytes: *const c_uchar, payload_len: c_int) -> c_int {
    if payload_bytes.is_null() || payload_len <= 0 {
        return 0;
    }
    
    let payload_slice = slice::from_raw_parts(payload_bytes, payload_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            // Parse the payload to extract key-value pairs
            let mut offset = 0;
            let mut cmd = redis::cmd("MSET");
            
            while offset < payload_slice.len() {
                if offset + 4 > payload_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Read key length (4 bytes, big-endian)
                let key_len = u32::from_be_bytes([
                    payload_slice[offset],
                    payload_slice[offset + 1],
                    payload_slice[offset + 2],
                    payload_slice[offset + 3],
                ]) as usize;
                offset += 4;
                
                // Check if we have enough bytes for the key
                if offset + key_len > payload_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Extract key
                let key = &payload_slice[offset..offset + key_len];
                offset += key_len;
                
                // Check if we have enough bytes for value length
                if offset + 4 > payload_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Read value length (4 bytes, big-endian)
                let value_len = u32::from_be_bytes([
                    payload_slice[offset],
                    payload_slice[offset + 1],
                    payload_slice[offset + 2],
                    payload_slice[offset + 3],
                ]) as usize;
                offset += 4;
                
                // Check if we have enough bytes for the value
                if offset + value_len > payload_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Extract value
                let value = &payload_slice[offset..offset + value_len];
                offset += value_len;
                
                cmd.arg(key).arg(value);
            }
            
            match cmd.query::<String>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Multi-get operation - raw bytes interface
#[no_mangle]
pub unsafe extern "stdcall" fn redis_mget(keys_bytes: *const c_uchar, keys_len: c_int, response_buffer: *mut c_uchar, buffer_len: c_int) -> c_int {
    if keys_bytes.is_null() || keys_len <= 0 || response_buffer.is_null() || buffer_len <= 0 {
        return 0;
    }
    
    let keys_slice = slice::from_raw_parts(keys_bytes, keys_len as usize);
    let output_slice = slice::from_raw_parts_mut(response_buffer, buffer_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            // Parse keys from payload
            let mut offset = 0;
            let mut cmd = redis::cmd("MGET");
            
            while offset < keys_slice.len() {
                if offset + 4 > keys_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Read key length (4 bytes, big-endian)
                let key_len = u32::from_be_bytes([
                    keys_slice[offset],
                    keys_slice[offset + 1],
                    keys_slice[offset + 2],
                    keys_slice[offset + 3],
                ]) as usize;
                offset += 4;
                
                // Check bounds
                if offset + key_len > keys_slice.len() {
                    return 0; // Invalid payload
                }
                
                // Extract key
                let key = &keys_slice[offset..offset + key_len];
                offset += key_len;
                
                cmd.arg(key);
            }
            
            match cmd.query::<Vec<Option<Vec<u8>>>>(connection) {
                Ok(results) => {
                    let mut response_offset = 0;
                    
                    for result in results {
                        if response_offset + 4 > buffer_len as usize {
                            break; // Buffer too small
                        }
                        
                        match result {
                            Some(value) => {
                                let value_len = value.len() as u32;
                                let len_bytes = value_len.to_be_bytes();
                                
                                // Write value length
                                output_slice[response_offset..response_offset + 4].copy_from_slice(&len_bytes);
                                response_offset += 4;
                                
                                // Write value data
                                let copy_len = std::cmp::min(value.len(), buffer_len as usize - response_offset);
                                output_slice[response_offset..response_offset + copy_len].copy_from_slice(&value[..copy_len]);
                                response_offset += copy_len;
                            }
                            None => {
                                // Write 0 length for null value
                                output_slice[response_offset..response_offset + 4].copy_from_slice(&[0, 0, 0, 0]);
                                response_offset += 4;
                            }
                        }
                    }
                    
                    response_offset as c_int
                }
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}

// Publish message to channel - raw bytes interface
#[no_mangle]
pub unsafe extern "stdcall" fn redis_publish(channel_bytes: *const c_uchar, channel_len: c_int, message_bytes: *const c_uchar, message_len: c_int) -> c_int {
    if channel_bytes.is_null() || channel_len <= 0 || message_bytes.is_null() || message_len <= 0 {
        return 0;
    }
    
    let channel_slice = slice::from_raw_parts(channel_bytes, channel_len as usize);
    let message_slice = slice::from_raw_parts(message_bytes, message_len as usize);
    
    if let Ok(mut conn) = REDIS_CONNECTION.lock() {
        if let Some(ref mut connection) = *conn {
            match redis::cmd("PUBLISH").arg(channel_slice).arg(message_slice).query::<i64>(connection) {
                Ok(_) => 1,
                Err(_) => 0,
            }
        } else {
            0
        }
    } else {
        0
    }
}
