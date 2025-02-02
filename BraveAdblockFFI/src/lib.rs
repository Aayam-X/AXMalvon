// src/lib.rs
use adblock::Engine; // adjust according to the crate's API
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

// Create a static engine instance (or initialize on demand)
static mut ENGINE: Option<AdblockEngine> = None;

#[no_mangle]
pub extern "C" fn init_adblock_engine(filter_data: *const c_char) {
    // filter_data is a JSON or other serialized string of filter lists
    let c_str = unsafe {
        assert!(!filter_data.is_null());
        CStr::from_ptr(filter_data)
    };
    let filter_str = c_str.to_str().unwrap_or("");

    // Initialize the engine with filter data (this is pseudocode – see the crate’s docs)
    unsafe {
        ENGINE = Some(AdblockEngine::new(filter_str));
    }
}

#[no_mangle]
pub extern "C" fn should_block_url(url: *const c_char) -> bool {
    let c_str = unsafe {
        assert!(!url.is_null());
        CStr::from_ptr(url)
    };
    let url_str = c_str.to_str().unwrap_or("");

    // Check if URL should be blocked. This depends on the API provided by brave_adblock.
    // For example, assuming a function `engine.should_block(url)`:
    let result = unsafe {
        if let Some(engine) = &ENGINE {
            engine.should_block(url_str)
        } else {
            false
        }
    };
    result
}
