use std::collections::HashMap;
use actix_web::web;
use sqlx::{FromRow, MySqlPool};
use crate::{ProjectSearchQuery, TableColumns};

pub async fn fetch_data_with_params<R, Q>(pool: &MySqlPool, params: web::Query<HashMap<String, String>>) -> Vec<R>
where
    R: for<'r> FromRow<'r, sqlx::mysql::MySqlRow> + Send + Unpin  + 'static,
    Q: TableColumns + 'static,

{
    let mut raw_query = String::from("SELECT * FROM ifs_projects_table where 1 = 1");
    let mut bind_values: Vec<String> = Vec::new();
    for &column in Q::COLUMNS{
        let value = params.get(column).cloned().unwrap_or_default();

        if !value.is_empty(){
            let query_string = format!(" AND {} = ?", column);
            raw_query.push_str(&query_string);
            bind_values.push(value.clone());

        }
    }
    println!("{:?}", &raw_query);
    let mut query = sqlx::query_as::<sqlx::MySql, R>(&raw_query);

    for value in bind_values{
        query = query.bind(value);
    }
    let result = query.fetch_all(pool).await.expect("Failed to fetch projects");
    result
}