use dotenvy::from_path;
use sqlx::MySqlPool;
use sqlx::mysql::{MySqlConnectOptions, MySqlPoolOptions};
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::str::FromStr;

use crate::models::ApiSpecification;
use crate::services::api_spec_service::{TableAllowlistEntry, build_api_spec};

const DOTENV_FILE_NAME: &str = ".env";
const DEFAULT_DB_PORT: u16 = 3306;
const DEFAULT_DB_MAX_CONNECTIONS: u32 = 10;
const ALLOWED_SCHEMAS_ENV_NAME: &str = "PROJECT_HUB_ALLOWED_SCHEMAS";
const ALLOWED_TABLES_ENV_NAME: &str = "PROJECT_HUB_ALLOWED_TABLES";
const DEFAULT_SCHEMA_ENV_NAME: &str = "PROJECT_HUB_DEFAULT_SCHEMA";
const SQL_DIRECTORY_NAME: &str = "./sql";

#[derive(Clone, Debug)]
struct DatabaseConnectionParts {
    host: String,
    port: u16,
    username: String,
    password: String,
    database_name: String,
}

impl DatabaseConnectionParts {
    fn into_connect_options(self) -> MySqlConnectOptions {
        MySqlConnectOptions::new()
            .host(&self.host)
            .port(self.port)
            .username(&self.username)
            .password(&self.password)
            .database(&self.database_name)
    }

    fn with_percent_decoded_password(&self) -> Option<Self> {
        let decoded_password = decode_percent_encoded_value(&self.password)?;

        Some(Self {
            host: self.host.clone(),
            port: self.port,
            username: self.username.clone(),
            password: decoded_password,
            database_name: self.database_name.clone(),
        })
    }
}

enum DatabaseConnectConfig {
    Url(String),
    Parts(DatabaseConnectionParts),
}

#[derive(Clone)]
pub struct AppState {
    pub db: MySqlPool,
    pub api_spec: ApiSpecification,
    pub default_schema: String,
    pub allowed_schemas: Vec<String>,
}

fn load_project_env_file() {
    let Some(env_path) = resolve_env_file_path() else {
        return;
    };

    from_path(&env_path).unwrap_or_else(|error| {
        panic!(
            "Failed to load environment file {}: {error}",
            env_path.display()
        )
    });
}

fn resolve_env_file_path() -> Option<PathBuf> {
    let current_dir = env::current_dir().ok()?;
    resolve_env_file_path_from(&current_dir)
}

fn resolve_env_file_path_from(base_dir: &Path) -> Option<PathBuf> {
    let local_env_path = base_dir.join(DOTENV_FILE_NAME);
    if local_env_path.is_file() {
        return Some(local_env_path);
    }

    let parent_env_path = base_dir.parent()?.join(DOTENV_FILE_NAME);
    if parent_env_path.is_file() {
        return Some(parent_env_path);
    }

    None
}

fn is_safe_identifier(identifier: &str) -> bool {
    let mut chars = identifier.chars();
    match chars.next() {
        Some(first) if first.is_ascii_alphabetic() || first == '_' => {}
        _ => return false,
    }

    chars.all(|character| character.is_ascii_alphanumeric() || character == '_')
}

fn validate_configured_schema_name(schema_name: &str, config_name: &str) {
    assert!(
        is_safe_identifier(schema_name),
        "Invalid schema name in {config_name}: {schema_name}"
    );
}

fn validate_configured_table_name(table_name: &str, config_name: &str) {
    assert!(
        is_safe_identifier(table_name),
        "Invalid table name in {config_name}: {table_name}"
    );
}

fn parse_schema_list(value: &str) -> Vec<String> {
    let mut schemas = Vec::new();

    for schema_name in value
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        if schemas.iter().all(|existing| existing != schema_name) {
            schemas.push(schema_name.to_string());
        }
    }

    schemas
}

fn read_allowed_schemas(default_schema: &str) -> Vec<String> {
    validate_configured_schema_name(default_schema, DEFAULT_SCHEMA_ENV_NAME);

    let allowed_schemas = match read_optional_env_var(ALLOWED_SCHEMAS_ENV_NAME) {
        Some(value) => {
            let schemas = parse_schema_list(&value);
            assert!(
                !schemas.is_empty(),
                "{ALLOWED_SCHEMAS_ENV_NAME} must contain at least one schema name"
            );
            schemas
        }
        None => vec![default_schema.to_string()],
    };

    for schema_name in &allowed_schemas {
        validate_configured_schema_name(schema_name, ALLOWED_SCHEMAS_ENV_NAME);
    }

    assert!(
        allowed_schemas
            .iter()
            .any(|schema_name| schema_name == default_schema),
        "Default schema {default_schema} must be included in {ALLOWED_SCHEMAS_ENV_NAME}"
    );

    allowed_schemas
}

fn read_allowed_tables(
    default_schema: &str,
    allowed_schemas: &[String],
) -> Vec<TableAllowlistEntry> {
    if let Some(value) = read_optional_env_var(ALLOWED_TABLES_ENV_NAME) {
        let allowed_tables = parse_table_list(&value, default_schema, allowed_schemas);
        assert!(
            !allowed_tables.is_empty(),
            "{ALLOWED_TABLES_ENV_NAME} must contain at least one table name"
        );
        return allowed_tables;
    }

    let sql_directory_path = PathBuf::from(format!("{}", SQL_DIRECTORY_NAME));
    let directory_entries = fs::read_dir(&sql_directory_path).unwrap_or_else(|error| {
        panic!(
            "Failed to read SQL directory {}: {error}",
            sql_directory_path.display()
        )
    });
    let allowed_schema_names = allowed_schemas
        .iter()
        .map(String::as_str)
        .collect::<Vec<_>>();
    let mut allowed_tables = BTreeSet::new();

    for directory_entry in directory_entries {
        let entry = directory_entry.unwrap_or_else(|error| {
            panic!(
                "Failed to enumerate SQL directory {}: {error}",
                sql_directory_path.display()
            )
        });
        let file_path = entry.path();

        if !file_path.is_file()
            || file_path.extension().and_then(|value| value.to_str()) != Some("sql")
        {
            continue;
        }

        let file_stem = file_path
            .file_stem()
            .and_then(|value| value.to_str())
            .unwrap_or_default()
            .to_string();
        let file_contents = fs::read_to_string(&file_path).unwrap_or_else(|error| {
            panic!("Failed to read SQL file {}: {error}", file_path.display())
        });

        for entry in
            parse_allowed_tables_from_sql(&file_contents, &file_stem, &allowed_schema_names)
        {
            allowed_tables.insert(entry);
        }
    }

    allowed_tables.into_iter().collect()
}

fn parse_table_list(
    value: &str,
    default_schema: &str,
    allowed_schemas: &[String],
) -> Vec<TableAllowlistEntry> {
    let mut allowed_tables = Vec::new();
    let mut seen_tables = BTreeSet::new();

    for raw_entry in value
        .split(|character| matches!(character, ',' | ';' | '\n' | '\r'))
        .map(str::trim)
        .filter(|entry| !entry.is_empty())
    {
        let entry = parse_table_entry(raw_entry, default_schema, allowed_schemas);

        if seen_tables.insert((entry.schema_name.clone(), entry.table_name.clone())) {
            allowed_tables.push(entry);
        }
    }

    allowed_tables
}

fn parse_table_entry(
    raw_entry: &str,
    default_schema: &str,
    allowed_schemas: &[String],
) -> TableAllowlistEntry {
    let (schema_name, table_name) = match raw_entry.split_once('.') {
        Some((schema_name, table_name)) => {
            let schema_name = normalize_identifier(schema_name).unwrap_or_else(|| {
                panic!("Invalid schema.table entry in {ALLOWED_TABLES_ENV_NAME}: {raw_entry}")
            });
            let table_name = normalize_identifier(table_name).unwrap_or_else(|| {
                panic!("Invalid schema.table entry in {ALLOWED_TABLES_ENV_NAME}: {raw_entry}")
            });

            (schema_name, table_name)
        }
        None => {
            let table_name = normalize_identifier(raw_entry).unwrap_or_else(|| {
                panic!("Invalid table entry in {ALLOWED_TABLES_ENV_NAME}: {raw_entry}")
            });

            (default_schema.to_string(), table_name)
        }
    };

    validate_configured_schema_name(&schema_name, ALLOWED_TABLES_ENV_NAME);
    validate_configured_table_name(&table_name, ALLOWED_TABLES_ENV_NAME);
    assert!(
        allowed_schemas
            .iter()
            .any(|allowed_schema| allowed_schema == &schema_name),
        "Schema {schema_name} in {ALLOWED_TABLES_ENV_NAME} must be included in {ALLOWED_SCHEMAS_ENV_NAME}"
    );

    TableAllowlistEntry {
        schema_name,
        table_name,
    }
}

fn parse_allowed_tables_from_sql(
    sql_text: &str,
    file_stem: &str,
    allowed_schemas: &[&str],
) -> Vec<TableAllowlistEntry> {
    let mut allowed_tables = Vec::new();

    for line in sql_text.lines() {
        let trimmed_line = line.trim_start();
        let lowercase_line = trimmed_line.to_ascii_lowercase();
        if !lowercase_line.starts_with("create table ") {
            continue;
        }

        let raw_identifier = &trimmed_line["create table ".len()..];
        let raw_identifier = raw_identifier
            .strip_prefix("if not exists ")
            .unwrap_or(raw_identifier);
        let table_identifier = raw_identifier
            .split_whitespace()
            .next()
            .unwrap_or_default()
            .trim_end_matches('(')
            .trim_matches('`');

        let Some((schema_name, table_name)) =
            resolve_table_identifier(table_identifier, file_stem, allowed_schemas)
        else {
            continue;
        };

        allowed_tables.push(TableAllowlistEntry {
            schema_name,
            table_name,
        });
    }

    allowed_tables
}

fn resolve_table_identifier(
    table_identifier: &str,
    file_stem: &str,
    allowed_schemas: &[&str],
) -> Option<(String, String)> {
    if table_identifier.is_empty() {
        return None;
    }

    if let Some((schema_name, table_name)) = table_identifier.split_once('.') {
        let schema_name = normalize_identifier(schema_name)?;
        let table_name = normalize_identifier(table_name)?;

        if allowed_schemas
            .iter()
            .any(|allowed_schema| allowed_schema == &schema_name)
        {
            return Some((schema_name, table_name));
        }

        return None;
    }

    let table_name = normalize_identifier(table_identifier)?;
    let file_schema_name = normalize_identifier(file_stem)?;

    if allowed_schemas
        .iter()
        .any(|allowed_schema| allowed_schema == &file_schema_name)
    {
        return Some((file_schema_name, table_name));
    }

    None
}

fn normalize_identifier(identifier: &str) -> Option<String> {
    let normalized = identifier.trim_matches('`').trim();
    if normalized.is_empty() || !is_safe_identifier(normalized) {
        return None;
    }

    Some(normalized.to_string())
}

fn from_hex_digit(value: u8) -> Option<u8> {
    match value {
        b'0'..=b'9' => Some(value - b'0'),
        b'a'..=b'f' => Some(value - b'a' + 10),
        b'A'..=b'F' => Some(value - b'A' + 10),
        _ => None,
    }
}

fn decode_percent_encoded_value(value: &str) -> Option<String> {
    let bytes = value.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    let mut changed = false;

    while index < bytes.len() {
        if bytes[index] == b'%' && index + 2 < bytes.len() {
            let high = from_hex_digit(bytes[index + 1]);
            let low = from_hex_digit(bytes[index + 2]);

            if let (Some(high), Some(low)) = (high, low) {
                decoded.push((high << 4) | low);
                index += 3;
                changed = true;
                continue;
            }
        }

        decoded.push(bytes[index]);
        index += 1;
    }

    if !changed {
        return None;
    }

    String::from_utf8(decoded)
        .ok()
        .filter(|decoded| decoded != value)
}

fn read_database_connect_config() -> DatabaseConnectConfig {
    if let Some(database_url) = read_optional_env_var("PROJECT_HUB_DATABASE_URL")
        .or_else(|| read_optional_env_var("DATABASE_URL"))
    {
        return DatabaseConnectConfig::Url(database_url);
    }

    let host = read_required_env_var("DB_HOST");
    let port = read_optional_env_var("DB_PORT")
        .map(|value| {
            value
                .parse::<u16>()
                .unwrap_or_else(|_| panic!("Invalid DB_PORT value: {value}"))
        })
        .unwrap_or(DEFAULT_DB_PORT);
    let username = read_required_env_var("DB_USER");
    let password = read_optional_env_var("DB_PASSWORD").unwrap_or_default();
    let database_name = read_required_env_var("DB_NAME");

    DatabaseConnectConfig::Parts(DatabaseConnectionParts {
        host,
        port,
        username,
        password,
        database_name,
    })
}

fn read_optional_env_var(name: &str) -> Option<String> {
    env::var(name).ok().filter(|value| !value.trim().is_empty())
}

fn read_required_env_var(name: &str) -> String {
    read_optional_env_var(name).unwrap_or_else(|| panic!("Missing required env var: {name}"))
}

async fn generate_pool() -> MySqlPool {
    let connect_config = read_database_connect_config();

    match connect_config {
        DatabaseConnectConfig::Url(database_url) => MySqlPoolOptions::new()
            .max_connections(DEFAULT_DB_MAX_CONNECTIONS)
            .connect_with(
                MySqlConnectOptions::from_str(&database_url)
                    .unwrap_or_else(|error| panic!("Invalid database URL: {error}")),
            )
            .await
            .expect("Failed to connect to database"),
        DatabaseConnectConfig::Parts(connection_parts) => {
            match MySqlPoolOptions::new()
                .max_connections(DEFAULT_DB_MAX_CONNECTIONS)
                .connect_with(connection_parts.clone().into_connect_options())
                .await
            {
                Ok(pool) => pool,
                Err(primary_error) => {
                    let Some(decoded_connection_parts) =
                        connection_parts.with_percent_decoded_password()
                    else {
                        panic!("Failed to connect to database: {primary_error}");
                    };

                    MySqlPoolOptions::new()
                        .max_connections(DEFAULT_DB_MAX_CONNECTIONS)
                        .connect_with(decoded_connection_parts.into_connect_options())
                        .await
                        .unwrap_or_else(|fallback_error| {
                            panic!(
                                "Failed to connect to database. Original DB_PASSWORD and percent-decoded DB_PASSWORD both failed. primary_error={primary_error}; fallback_error={fallback_error}"
                            )
                        })
                }
            }
        }
    }
}

async fn resolve_default_schema(pool: &MySqlPool) -> String {
    if let Some(schema_name) = read_optional_env_var(DEFAULT_SCHEMA_ENV_NAME) {
        validate_configured_schema_name(&schema_name, DEFAULT_SCHEMA_ENV_NAME);
        return schema_name;
    }

    let current_schema = sqlx::query_scalar::<_, Option<String>>("SELECT DATABASE()")
        .fetch_one(pool)
        .await
        .expect("Failed to resolve current database schema");

    let schema_name = current_schema
        .filter(|value| !value.trim().is_empty())
        .expect("Database connection does not have a default schema");

    validate_configured_schema_name(&schema_name, DEFAULT_SCHEMA_ENV_NAME);
    schema_name
}

/// アプリケーション起動時に共有する状態を初期化する。
pub async fn build_app_state() -> AppState {
    load_project_env_file();

    let db = generate_pool().await;
    let default_schema = resolve_default_schema(&db).await;
    let allowed_schemas = read_allowed_schemas(&default_schema);
    let allowed_tables = read_allowed_tables(&default_schema, &allowed_schemas);
    let api_spec = build_api_spec(&db, &allowed_schemas, &allowed_tables, &default_schema)
        .await
        .expect("Failed to build API specification");

    AppState {
        db,
        api_spec,
        default_schema,
        allowed_schemas,
    }
}

#[cfg(test)]
mod tests {
    use super::{
        decode_percent_encoded_value, parse_allowed_tables_from_sql, parse_schema_list,
        parse_table_list, resolve_env_file_path_from,
    };
    use std::fs;
    use std::path::PathBuf;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn create_temp_directory(prefix: &str) -> PathBuf {
        let unique_suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("System time should be after UNIX_EPOCH")
            .as_nanos();
        let directory = std::env::temp_dir().join(format!("{prefix}-{unique_suffix}"));

        fs::create_dir_all(&directory).expect("Temporary directory should be created");
        directory
    }

    #[test]
    fn resolve_env_file_path_prefers_local_file() {
        let base_dir = create_temp_directory("projecthubv2-local-env");
        let child_dir = base_dir.join("child");

        fs::create_dir_all(&child_dir).expect("Child directory should be created");
        fs::write(base_dir.join(".env"), "DB_HOST=parent").expect("Parent env should be written");
        fs::write(child_dir.join(".env"), "DB_HOST=child").expect("Local env should be written");

        let resolved_path =
            resolve_env_file_path_from(&child_dir).expect("A local env file should be resolved");

        assert_eq!(resolved_path, child_dir.join(".env"));

        fs::remove_dir_all(&base_dir).expect("Temporary directory should be removed");
    }

    #[test]
    fn resolve_env_file_path_falls_back_to_parent_file() {
        let base_dir = create_temp_directory("projecthubv2-parent-env");
        let child_dir = base_dir.join("child");

        fs::create_dir_all(&child_dir).expect("Child directory should be created");
        fs::write(base_dir.join(".env"), "DB_HOST=parent").expect("Parent env should be written");

        let resolved_path =
            resolve_env_file_path_from(&child_dir).expect("A parent env file should be resolved");

        assert_eq!(resolved_path, base_dir.join(".env"));

        fs::remove_dir_all(&base_dir).expect("Temporary directory should be removed");
    }

    #[test]
    fn parse_schema_list_trims_values_and_deduplicates() {
        let schemas = parse_schema_list(" alpha ,beta,alpha,, gamma ");

        assert_eq!(schemas, vec!["alpha", "beta", "gamma"]);
    }

    #[test]
    fn decode_percent_encoded_value_decodes_url_encoded_password() {
        let decoded = decode_percent_encoded_value("secret%40value");

        assert_eq!(decoded, Some("secret@value".to_string()));
    }

    #[test]
    fn decode_percent_encoded_value_returns_none_when_not_encoded() {
        let decoded = decode_percent_encoded_value("plain-password");

        assert_eq!(decoded, None);
    }

    #[test]
    fn parse_allowed_tables_from_sql_uses_file_stem_for_unqualified_names() {
        let tables = parse_allowed_tables_from_sql(
            "create table sample_table\n(\n    id int\n);\n",
            "plango",
            &["plango"],
        );

        assert_eq!(tables.len(), 1);
        assert_eq!(tables[0].schema_name, "plango");
        assert_eq!(tables[0].table_name, "sample_table");
    }

    #[test]
    fn parse_allowed_tables_from_sql_accepts_qualified_names_from_aggregate_sql() {
        let tables = parse_allowed_tables_from_sql(
            "create table ifs_reference_data.sample_table\n(\n    id int\n);\ncreate table other_schema.ignored_table\n(\n    id int\n);\n",
            "system_database",
            &["ifs_reference_data"],
        );

        assert_eq!(tables.len(), 1);
        assert_eq!(tables[0].schema_name, "ifs_reference_data");
        assert_eq!(tables[0].table_name, "sample_table");
    }

    #[test]
    fn parse_table_list_accepts_qualified_and_unqualified_entries() {
        let tables = parse_table_list(
            "ifs_reference_data.sample_table, users",
            "plango",
            &["ifs_reference_data".to_string(), "plango".to_string()],
        );

        assert_eq!(tables.len(), 2);
        assert_eq!(tables[0].schema_name, "ifs_reference_data");
        assert_eq!(tables[0].table_name, "sample_table");
        assert_eq!(tables[1].schema_name, "plango");
        assert_eq!(tables[1].table_name, "users");
    }

    #[test]
    fn parse_table_list_deduplicates_entries() {
        let tables = parse_table_list(
            "plango.users, users, plango.users",
            "plango",
            &["plango".to_string()],
        );

        assert_eq!(tables.len(), 1);
        assert_eq!(tables[0].schema_name, "plango");
        assert_eq!(tables[0].table_name, "users");
    }
}
