use std::collections::HashMap;

pub struct JsonRequest {
    tablet_name: String,
    search_mode: String,
    selector: HashMap<String, String>,
    values: Option<Vec<HashMap<String, String>>>,
}