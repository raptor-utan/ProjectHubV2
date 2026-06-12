-- we don't know how to generate root <with-no-name> (class Root) :(

grant select on performance_schema.* to 'mysql.session'@localhost;

grant trigger on sys.* to 'mysql.sys'@localhost;

grant alter, alter routine, create, create routine, create tablespace, create temporary tables, create user, create view, delete, drop, event, execute, file, index, insert, lock tables, process, references, reload, replication client, replication slave, select, show databases, show view, shutdown, super, trigger, update, grant option on *.* to dbuser;

grant audit_abort_exempt, firewall_exempt, select, system_user on *.* to 'mysql.infoschema'@localhost;

grant audit_abort_exempt, authentication_policy_admin, backup_admin, clone_admin, connection_admin, firewall_exempt, persist_ro_variables_admin, session_variables_admin, shutdown, super, system_user, system_variables_admin on *.* to 'mysql.session'@localhost;

grant audit_abort_exempt, firewall_exempt, system_user on *.* to 'mysql.sys'@localhost;

grant alter, alter routine, application_password_admin, audit_abort_exempt, audit_admin, authentication_policy_admin, backup_admin, binlog_admin, binlog_encryption_admin, clone_admin, connection_admin, create, create role, create routine, create tablespace, create temporary tables, create user, create view, delete, drop, drop role, encryption_key_admin, event, execute, file, firewall_exempt, flush_optimizer_costs, flush_status, flush_tables, flush_user_resources, group_replication_admin, group_replication_stream, index, innodb_redo_log_archive, innodb_redo_log_enable, insert, lock tables, passwordless_user_admin, persist_ro_variables_admin, process, references, reload, replication client, replication slave, replication_applier, replication_slave_admin, resource_group_admin, resource_group_user, role_admin, select, sensitive_variables_observer, service_connection_admin, session_variables_admin, set_user_id, show databases, show view, show_routine, shutdown, super, system_user, system_variables_admin, table_encryption_admin, telemetry_log_admin, trigger, update, xa_recover_admin, grant option on *.* to root@localhost;

create table plango.active_sessions
(
    session_id    varchar(512)                        not null
        primary key,
    user_id       varchar(255)                        not null comment 'ユーザーID',
    last_activity timestamp default CURRENT_TIMESTAMP null comment '最終活動日時'
)
    comment 'ログイン中セッション管理';

create table project_hub.active_sessions
(
    session_id    text null,
    user_id       text null,
    last_activity text null
);

create table login_info.active_users_table
(
    jrc_user_code      varchar(10)                  not null comment '個人コード'
        primary key,
    login_time         datetime default (curdate()) null comment 'ログイン日時（自動ログアウト判定処理用）',
    identification_key varchar(40)                  null comment '識別キー（JWTトークンの代わり）'
);

create table plango.affiliation_categories
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    code          varchar(50)                          not null comment 'コード',
    name          varchar(255)                         not null comment '名称',
    display_order int        default 0                 not null comment '表示順',
    is_active     tinyint(1) default 1                 not null comment '有効フラグ',
    created_at    datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint code
        unique (code)
)
    comment '所属区分マスタ';

create table plango.ag_air_units
(
    id                bigint unsigned auto_increment
        primary key,
    serial_no         varchar(50)                        not null,
    model_name        varchar(100)                       not null,
    device_name       varchar(100)                       not null,
    order_no          varchar(50)                        not null,
    registered_at_raw varchar(50)                        null,
    registered_at     datetime                           null,
    created_at        datetime default CURRENT_TIMESTAMP not null,
    updated_at        datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_ag_air_units_serial
        unique (serial_no)
);

create index idx_ag_air_units_model
    on plango.ag_air_units (model_name);

create index idx_ag_air_units_order
    on plango.ag_air_units (order_no);

create table plango.ag_common_spec_groups
(
    id            bigint unsigned auto_increment
        primary key,
    title         varchar(255)                           not null,
    comment       varchar(500)                           null,
    file_count    int unsigned default '0'               not null,
    uploader_name varchar(100)                           not null,
    created_at    datetime     default CURRENT_TIMESTAMP not null,
    updated_at    datetime     default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.ag_common_specs
(
    id            bigint unsigned auto_increment
        primary key,
    group_id      bigint unsigned                    null,
    version       int unsigned                       not null,
    title         varchar(255)                       not null,
    comment       varchar(500)                       null,
    file_path     varchar(500)                       not null,
    original_name varchar(255)                       not null,
    mime_type     varchar(100)                       not null,
    file_size     bigint unsigned                    not null,
    uploader_name varchar(100)                       not null,
    created_at    datetime default CURRENT_TIMESTAMP not null,
    updated_at    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_common_specs_group
    on plango.ag_common_specs (group_id);

create table plango.ag_customer_specs
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    version        int unsigned                       not null,
    title          varchar(255)                       not null,
    comment        varchar(500)                       null,
    file_path      varchar(500)                       not null,
    original_name  varchar(255)                       not null,
    mime_type      varchar(100)                       not null,
    file_size      bigint unsigned                    not null,
    uploader_name  varchar(100)                       not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_customer_specs_project
    on plango.ag_customer_specs (project_id, sub_project_id);

create table plango.ag_datasheet_choice_sets
(
    id          int auto_increment
        primary key,
    code        varchar(50)                        not null,
    name        varchar(100)                       not null,
    description text                               null,
    created_at  datetime default CURRENT_TIMESTAMP not null,
    updated_at  datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint code
        unique (code)
);

create table plango.ag_datasheet_choice_items
(
    id         int auto_increment
        primary key,
    set_id     int                                not null,
    value      varchar(100)                       not null,
    label      varchar(100)                       not null,
    sort_order int      default 0                 not null,
    created_at datetime default CURRENT_TIMESTAMP not null,
    updated_at datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint fk_choice_items_set
        foreign key (set_id) references plango.ag_datasheet_choice_sets (id)
            on delete cascade
);

create table plango.ag_datasheet_formats
(
    id          int auto_increment
        primary key,
    target_type varchar(20)                          not null,
    code        varchar(50)                          not null,
    name        varchar(100)                         not null,
    description text                                 null,
    active_flag tinyint(1) default 1                 not null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_datasheet_format_code
        unique (code)
);

create table plango.ag_datasheet_fields
(
    id              int auto_increment
        primary key,
    format_id       int                                  not null,
    field_key       varchar(50)                          not null,
    field_label     varchar(100)                         not null,
    description     text                                 null,
    unit            varchar(50)                          null,
    standard        varchar(255)                         null,
    field_type      varchar(20)                          not null,
    judge_type      varchar(50)                          null,
    judge_rule_type varchar(20)                          null,
    judge_min_value varchar(50)                          null,
    judge_max_value varchar(50)                          null,
    note            text                                 null,
    required_flag   tinyint(1) default 0                 not null,
    sort_order      int        default 0                 not null,
    default_value   varchar(255)                         null,
    choice_set_id   int                                  null,
    choices_json    text                                 null,
    created_at      datetime   default CURRENT_TIMESTAMP not null,
    updated_at      datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_datasheet_field
        unique (format_id, field_key),
    constraint fk_datasheet_field_choice_set
        foreign key (choice_set_id) references plango.ag_datasheet_choice_sets (id)
            on delete set null,
    constraint fk_datasheet_field_format
        foreign key (format_id) references plango.ag_datasheet_formats (id)
            on delete cascade
);

create table plango.ag_datasheet_records
(
    id               int auto_increment
        primary key,
    project_id       varchar(50)                        not null,
    sub_project_id   varchar(50)                        not null,
    target_type      varchar(20)                        not null,
    target_serial_no varchar(50)                        not null,
    format_id        int                                not null,
    remark           text                               null,
    created_at       datetime default CURRENT_TIMESTAMP not null,
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    created_by       varchar(50)                        null,
    updated_by       varchar(50)                        null,
    constraint uq_datasheet_record
        unique (project_id, sub_project_id, target_type, target_serial_no),
    constraint fk_datasheet_record_format
        foreign key (format_id) references plango.ag_datasheet_formats (id)
);

create table plango.ag_datasheet_values
(
    id               int auto_increment
        primary key,
    record_id        int                                not null,
    field_id         int                                not null,
    field_key        varchar(50)                        not null,
    value_text       text                               null,
    judge            varchar(50)                        null,
    remark1          text                               null,
    remark2          text                               null,
    remark3          text                               null,
    remark4          text                               null,
    remark5          text                               null,
    recorded_by_id   varchar(50)                        null,
    recorded_by_name varchar(100)                       null,
    recorded_at      datetime                           null,
    created_at       datetime default CURRENT_TIMESTAMP not null,
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_datasheet_value
        unique (record_id, field_id),
    constraint fk_datasheet_value_field
        foreign key (field_id) references plango.ag_datasheet_fields (id)
            on delete cascade,
    constraint fk_datasheet_value_record
        foreign key (record_id) references plango.ag_datasheet_records (id)
            on delete cascade
);

create table plango.ag_dummy_panels
(
    id                bigint unsigned auto_increment
        primary key,
    serial_no         varchar(50)                        not null,
    model_name        varchar(100)                       not null,
    device_name       varchar(100)                       not null,
    order_no          varchar(50)                        not null,
    registered_at_raw varchar(50)                        null,
    registered_at     datetime                           null,
    created_at        datetime default CURRENT_TIMESTAMP not null,
    updated_at        datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint idx_ag_dummy_panels_serial_no
        unique (serial_no)
);

create index idx_ag_dummy_panels_model_name
    on plango.ag_dummy_panels (model_name);

create index idx_ag_dummy_panels_order_no
    on plango.ag_dummy_panels (order_no);

create table plango.ag_electric_design_list
(
    id                int unsigned auto_increment
        primary key,
    project_id        varchar(50)                          not null,
    sub_project_id    varchar(50)                          null,
    device_class      varchar(50)                          null,
    delivery_place    varchar(255)                         null,
    txrx_no           varchar(100)                         null,
    serial_no_main    varchar(100)                         null,
    sample_unit_flag  tinyint(1) default 0                 not null,
    serial_no_antenna varchar(100)                         null,
    antenna_type      varchar(100)                         null,
    system_config_no  varchar(100)                         null,
    frame_index       varchar(10)                          null,
    frame_body        varchar(50)                          null,
    frame_antenna     varchar(50)                          null,
    frame_1           varchar(50)                          null,
    frame_2           varchar(50)                          null,
    frame_3           varchar(50)                          null,
    frame_4           varchar(50)                          null,
    frame_5           varchar(50)                          null,
    frame_6           varchar(50)                          null,
    frame_7           varchar(50)                          null,
    frame_8           varchar(50)                          null,
    frame_9           varchar(50)                          null,
    frame_10          varchar(50)                          null,
    frame_11          varchar(50)                          null,
    power_voltage     varchar(20)                          null,
    power_su          varchar(10)                          null,
    power_freq        varchar(10)                          null,
    tx_power_main     varchar(20)                          null,
    freq_main_1       varchar(20)                          null,
    freq_main_2       varchar(20)                          null,
    ch1               varchar(20)                          null,
    ch2               varchar(20)                          null,
    ch3               varchar(20)                          null,
    ch4               varchar(20)                          null,
    ch5               varchar(20)                          null,
    ch6               varchar(20)                          null,
    ch7               varchar(20)                          null,
    ch8               varchar(20)                          null,
    ch9               varchar(20)                          null,
    ch10              varchar(20)                          null,
    ch11              varchar(20)                          null,
    ch12              varchar(20)                          null,
    ch13              varchar(20)                          null,
    delivery_deadline date                                 null,
    antenna_class_no  varchar(50)                          null,
    radio_class_no    varchar(50)                          null,
    tx_filter         varchar(50)                          null,
    created_at        datetime   default CURRENT_TIMESTAMP not null,
    updated_at        datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_design_project
    on plango.ag_electric_design_list (project_id, sub_project_id);

create index idx_ag_device
    on plango.ag_electric_design_list (device_class, delivery_place, txrx_no);

create table plango.ag_kosei_diagrams
(
    id                int auto_increment
        primary key,
    project_id        varchar(32)                          not null,
    sub_project_id    varchar(32)                          not null,
    file_type         varchar(16)                          not null,
    serial_no         varchar(32)                          not null,
    version           int                                  not null,
    title             varchar(255)                         not null,
    comment           text                                 null,
    file_path         text                                 not null,
    original_name     varchar(255)                         not null,
    mime_type         varchar(128)                         not null,
    file_size         bigint                               not null,
    uploader_name     varchar(255)                         not null,
    created_at        datetime   default CURRENT_TIMESTAMP not null,
    updated_at        datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    confirmed_flag    tinyint(1) default 0                 not null comment '確認済フラグ',
    confirmed_by_id   varchar(32)                          null comment '確認者社員ID',
    confirmed_by_name varchar(128)                         null comment '確認者名',
    confirmed_at      datetime                             null comment '確認日時',
    constraint uq_kosei_ver
        unique (project_id, sub_project_id, file_type, serial_no, version)
);

create table plango.ag_model_master
(
    id             bigint unsigned auto_increment
        primary key,
    series_name    varchar(50)                        not null,
    kind           varchar(50)                        not null,
    band           varchar(50)                        null,
    product_name   varchar(255)                       not null,
    customer_model varchar(255)                       null,
    info1          varchar(255)                       null,
    info2          varchar(255)                       null,
    mass_kg        decimal(7, 2)                      null,
    remark         text                               null,
    sort_order     int      default 0                 not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_model_master_series
    on plango.ag_model_master (series_name, kind, band);

create table plango.ag_packing_lists
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    version        int unsigned                       not null,
    title          varchar(255)                       not null,
    comment        varchar(500)                       null,
    file_path      varchar(500)                       not null,
    original_name  varchar(255)                       not null,
    mime_type      varchar(100)                       not null,
    file_size      bigint unsigned                    not null,
    uploader_name  varchar(100)                       not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_packing_lists_proj
    on plango.ag_packing_lists (project_id, sub_project_id);

create table plango.ag_process_sheets
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    version        int unsigned                       not null,
    title          varchar(255)                       not null,
    comment        varchar(500)                       null,
    file_path      varchar(500)                       not null,
    original_name  varchar(255)                       not null,
    mime_type      varchar(100)                       not null,
    file_size      bigint unsigned                    not null,
    uploader_name  varchar(100)                       not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_process_sheets_proj
    on plango.ag_process_sheets (project_id, sub_project_id);

create table plango.ag_progress_items
(
    id          int unsigned auto_increment
        primary key,
    target_code varchar(50)                          not null,
    code        varchar(50)                          not null,
    label       varchar(100)                         not null,
    description text                                 null,
    sort_order  int        default 0                 not null,
    active_flag tinyint(1) default 1                 not null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uniq_target_code
        unique (target_code, code)
);

create table plango.ag_progress_targets
(
    id          int unsigned auto_increment
        primary key,
    code        varchar(50)                          not null,
    label       varchar(100)                         not null,
    description text                                 null,
    sort_order  int        default 0                 not null,
    active_flag tinyint(1) default 1                 not null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint code
        unique (code)
);

create table plango.ag_progress_values
(
    id              bigint unsigned auto_increment
        primary key,
    project_id      varchar(50)                        not null,
    sub_project_id  varchar(50)                        not null,
    target_code     varchar(50)                        not null,
    target_key      varchar(100)                       not null,
    item_id         int unsigned                       not null,
    plan_date       date                               null,
    plan_text       text                               null,
    actual_date     date                               null,
    actual_text     text                               null,
    updated_at      datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    updated_by_id   varchar(50)                        null,
    updated_by_name varchar(100)                       null,
    constraint uniq_progress
        unique (project_id, sub_project_id, target_code, target_key, item_id)
);

create index idx_item_id
    on plango.ag_progress_values (item_id);

create table plango.ag_rack_diagrams
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    version        int unsigned                       not null,
    title          varchar(255)                       not null,
    comment        varchar(500)                       null,
    file_path      varchar(500)                       not null,
    original_name  varchar(255)                       not null,
    mime_type      varchar(100)                       not null,
    file_size      bigint unsigned                    not null,
    uploader_name  varchar(100)                       not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_rack_diagrams_proj
    on plango.ag_rack_diagrams (project_id, sub_project_id);

create index idx_ag_rack_diagrams_ver
    on plango.ag_rack_diagrams (project_id, sub_project_id, version);

create table plango.ag_rack_panels
(
    id               bigint unsigned auto_increment
        primary key,
    project_id       varchar(50)                          not null,
    sub_project_id   varchar(50)                          not null,
    rack_row_id      bigint unsigned                      not null,
    sample_rack_flag tinyint(1) default 0                 not null,
    dma_serial_no    varchar(100)                         null,
    dma_class_no     varchar(100)                         null,
    dmb_serial_no    varchar(100)                         null,
    dmb_class_no     varchar(100)                         null,
    ax_serial_no     varchar(100)                         null,
    ax_class_no      varchar(100)                         null,
    rst_serial_no    varchar(100)                         null,
    rst_class_no     varchar(100)                         null,
    ups1_serial_no   varchar(100)                         null,
    ups1_class_no    varchar(100)                         null,
    ups2_serial_no   varchar(100)                         null,
    ups2_class_no    varchar(100)                         null,
    created_at       datetime   default CURRENT_TIMESTAMP not null,
    updated_at       datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_ag_rack_panels_project_rack
        unique (project_id, sub_project_id, rack_row_id)
);

create index idx_ag_rack_panels_rack_row_id
    on plango.ag_rack_panels (rack_row_id);

create table plango.ag_ruibetu_master
(
    id                      bigint unsigned auto_increment
        primary key,
    file_type               enum ('rack', 'unit')                not null,
    file_serial_no          varchar(50)                          not null,
    sochi_kosei_no          varchar(255)                         null,
    buhin_kata_shiki_kikaku varchar(255)                         null,
    buhin_kata_shiki_maker  varchar(255)                         null,
    hinmei                  varchar(255)                         null,
    sochi_kata_shiki        varchar(255)                         null,
    seizou_kaisha           varchar(255)                         null,
    buhin_bango             varchar(255)                         null,
    keiyaku_ymd             date                                 null,
    seizou_ymd              date                                 null,
    shutoku_ymd             date                                 null,
    hosho_ymd               date                                 null,
    zumen_no                varchar(255)                         null,
    shutoku_kakaku          decimal(18, 2)                       null,
    shinraisei_kosei_kbn    varchar(50)                          null,
    kokan_tani_kbn          varchar(50)                          null,
    yobihin_kbn             varchar(50)                          null,
    shuri_kbn               varchar(50)                          null,
    flight_check_kbn        varchar(50)                          null,
    secchi_basho_kbn_code   varchar(50)                          null,
    bunrui                  varchar(50)                          null,
    saibunrui               varchar(50)                          null,
    catalog_kbn             varchar(50)                          null,
    asterisk                varchar(50)                          null,
    ruibetsu_code           varchar(50)                          null,
    hokyu_taisho_kbn        varchar(50)                          null,
    kokanji_kakunin_kbn     varchar(50)                          null,
    seizou_nendo            varchar(10)                          null,
    line_no                 int                                  null,
    confirmed_flag          tinyint(1) default 0                 not null,
    confirmed_by_id         varchar(50)                          null,
    confirmed_by_name       varchar(100)                         null,
    confirmed_at            datetime                             null,
    project_id              varchar(50)                          not null,
    sub_project_id          varchar(50)                          not null,
    source_filename         varchar(255)                         null,
    sheet_name              varchar(100)                         null,
    row_index               int                                  null,
    created_at              datetime   default CURRENT_TIMESTAMP not null,
    updated_at              datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ruibetu_main
    on plango.ag_ruibetu_master (file_serial_no, file_type, project_id, sub_project_id);

create table plango.ag_ruibetu_qr_logs
(
    id                      bigint auto_increment
        primary key,
    project_id              varchar(50)                        not null,
    sub_project_id          varchar(50)                        not null,
    file_type               enum ('rack', 'unit')              null,
    file_serial_no          varchar(50)                        null,
    employee_id             varchar(50)                        not null,
    employee_name           varchar(100)                       not null,
    qr_raw_text             text                               not null,
    hinmei                  varchar(255)                       null,
    buhin_kata_shiki_kikaku varchar(255)                       null,
    buhin_bango             varchar(255)                       null,
    matched                 tinyint(1)                         not null,
    matched_count           int                                not null,
    checked_at              datetime default CURRENT_TIMESTAMP not null
);

create table plango.ag_test_procedures
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        not null,
    version        int unsigned                       not null,
    title          varchar(255)                       not null,
    comment        varchar(500)                       null,
    file_path      varchar(500)                       not null,
    original_name  varchar(255)                       not null,
    mime_type      varchar(100)                       not null,
    file_size      bigint unsigned                    not null,
    uploader_name  varchar(100)                       not null,
    created_at     datetime default CURRENT_TIMESTAMP not null,
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_ag_test_procedures_proj
    on plango.ag_test_procedures (project_id, sub_project_id);

create table plango.area_capacities
(
    area                   varchar(100)         not null comment 'エリア'
        primary key,
    max_area               double               null comment '最大面積',
    is_active              tinyint(1) default 1 not null comment '有効フラグ',
    include_in_aggregation tinyint(1) default 1 not null comment '集計対象フラグ'
)
    comment 'エリア容量設定';

create table plango.attendance_boards
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    group_name           varchar(255)                         not null comment 'グループ名',
    affiliation_category varchar(255)                         null comment '所属区分',
    board_name           varchar(255)                         not null comment '掲示板名',
    sort_order           int        default 0                 not null comment '並び順',
    is_active            tinyint(1) default 1                 not null comment '有効フラグ',
    created_at           datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at           datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment '出退勤掲示板';

create index idx_attendance_boards_group_name
    on plango.attendance_boards (group_name);

create table plango.attendance_destinations
(
    id          int unsigned auto_increment
        primary key,
    employee_id varchar(32)                          not null,
    label       varchar(100)                         not null,
    sort_order  int        default 0                 not null,
    is_active   tinyint(1) default 1                 not null,
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create index idx_attdest_emp
    on plango.attendance_destinations (employee_id);

create table plango.attendance_schedules
(
    id               int unsigned auto_increment
        primary key,
    outlook_entry_id varchar(255)                                      null,
    employee_id      varchar(32)                                       not null,
    group_name       varchar(255)                                      null,
    title            varchar(255)                                      not null,
    description      text                                              null,
    start_at         datetime                                          not null,
    end_at           datetime                                          not null,
    all_day          tinyint(1)              default 0                 not null,
    color            varchar(20)                                       null,
    created_at       datetime                default CURRENT_TIMESTAMP not null,
    updated_at       datetime                default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    last_updated_by  enum ('outlook', 'web') default 'outlook'         not null
);

create index idx_schedules_employee
    on plango.attendance_schedules (employee_id, start_at);

create index idx_schedules_group
    on plango.attendance_schedules (group_name, start_at);

create table plango.attendance_status_colors
(
    id         int auto_increment
        primary key,
    code       varchar(50)                          not null,
    label      varchar(100)                         not null,
    bg_color   varchar(20)                          not null,
    text_color varchar(20)                          not null,
    sort_order int        default 0                 not null,
    is_active  tinyint(1) default 1                 not null,
    created_at datetime   default CURRENT_TIMESTAMP not null,
    updated_at datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint code
        unique (code)
);

create table plango.attendance_status_master
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    code       varchar(50)                           not null comment 'コード',
    label      varchar(100)                          not null comment 'ラベル',
    sort_order int         default 0                 not null comment '並び順',
    is_active  tinyint(1)  default 1                 not null comment '有効フラグ',
    created_at datetime    default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    color_code varchar(50) default 'none'            not null,
    constraint uq_attendance_status_code
        unique (code)
)
    comment '出退勤状態マスタ';

create table ifs_reference_data.backlog_task_date_table
(
    unique_project_id                         varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID'
        primary key,
    inspection_preparation_start_date         varchar(20) null comment '検査準備開始日（設計計画書の検査実施要領書出図日）',
    inspection_preparation_end_date           varchar(20) null comment '検査準備終了日（検査実施要領書の入検日）',
    inspection_start_date                     varchar(20) null comment '検査開始日（設計計画書の入検日）',
    inspection_end_date                       varchar(20) null comment '検査終了日（設計計画書のDVa完了日）',
    inspection_meeting_preparation_start_date varchar(20) null comment '立会検査準備開始日（設計計画書のDVa）',
    inspection_meeting_preparation_end_date   varchar(20) null comment '立会検査準備終了日（設計計画書の立会日－１日）',
    inspection_meeting_start_date             varchar(20) null comment '立会検査開始日（設計計画書の立会日）',
    inspection_meeting_end_date               varchar(20) null comment '立会検査終了日（設計計画書の出荷日）',
    shipping_preparation_start_date           varchar(20) null comment '出荷準備開始日（設計計画書のDVaまたは立会日～出荷ー１まで）',
    shipping_preparation_end_date             varchar(20) null comment '出荷準備終了日（設計計画書の出荷日）',
    shipping_start_date                       varchar(20) null comment '出荷開始日（設計計画書の出荷日）',
    shipping_end_date                         varchar(20) null comment '出荷終了日（設計計画書の出荷日）'
)
    comment '各工程情報を保存するテーブル';

create table ifs_reference_data.backlog_task_ids_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(100) null,
    summary           varchar(100) null,
    issue_id          int          null,
    parent            tinyint(1)   null,
    backlog_pj_id     int          not null
);

create table ifs_reference_data.backlog_users_table
(
    id            int          not null
        primary key,
    userId        varchar(50)  not null,
    name          varchar(100) not null,
    roleType      int          null,
    lang          varchar(10)  null,
    mailAddress   varchar(100) null,
    lastLoginTime datetime     null,
    constraint user_id
        unique (userId)
);

create table project_hub.blocks
(
    id         text null,
    page_id    text null,
    type       text null,
    content    text null,
    position   text null,
    created_at text null,
    updated_at text null
);

create table plango.blocks
(
    id         int auto_increment comment 'ID'
        primary key,
    page_id    int                                 not null comment 'ページID',
    type       varchar(50)                         not null comment '種別',
    content    text                                null comment '内容',
    position   int                                 not null comment '表示位置',
    created_at timestamp default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint blocks_ibfk_1
        foreign key (page_id) references plango.pages (id)
            on delete cascade
)
    comment 'ブロック管理';

create index page_id
    on plango.blocks (page_id);

create table ifs_reference_data.blue_prints_table
(
    id                   int auto_increment
        primary key,
    unique_project_id    varchar(20)          null comment 'ユニークプロジェクトID',
    blue_print_file_name varchar(100)         null comment '図面ファイル名',
    blue_print_kind_id   int                  null comment '図面種別ID',
    blue_print_dl_link   varchar(255)         null comment '図面ダウンロードリンク',
    downloaded           tinyint(1) default 0 null comment 'ダウンロード状況'
)
    comment '出図済み図面一覧';

create table ifs_reference_data.blueprint_kind_table
(
    blue_print_kind_id   int      not null comment '図面種別ID'
        primary key,
    blue_print_kind_name char(50) null comment '図面種別名'
)
    comment '図面種別定義テーブル';

create table ifs_reference_data.blue_print_alert_history_table
(
    id                 int auto_increment
        primary key,
    unique_project_id  varchar(20) not null comment 'ユニークプロジェクトID（プロジェクトID＋サブプロジェクトID）',
    blue_print_kind_id int         not null comment '図面種別ID',
    status             tinyint(1)  not null comment '出図状況',
    constraint blue_print_alert_history_table_blue_print_fk
        foreign key (blue_print_kind_id) references ifs_reference_data.blueprint_kind_table (blue_print_kind_id)
)
    comment '各案件ごとの出図図面一覧';

create table ifs_reference_data.blue_prints_alert_setting_table
(
    id                 int auto_increment
        primary key,
    subproject_type_id int not null comment 'サブプロジェクト種別',
    blue_print_kind_id int not null comment '図面種別ID',
    process_kind_id    int not null comment '工程ID',
    alert_offset_date  int not null comment 'アラートアクティベートのオフセット日数',
    constraint blue_prints_kind_id_fk
        foreign key (blue_print_kind_id) references ifs_reference_data.blueprint_kind_table (blue_print_kind_id)
)
    comment '図面出図におけるアラート出力オフセット設定';

create table plango.board_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    post_id         int      null comment '投稿ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment '掲示板添付ファイル';

create table plango.board_posts
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    project_id int      null comment 'プロジェクトID',
    title      text     null comment 'タイトル',
    content    text     null comment '内容',
    created_by text     null comment '作成者',
    created_at datetime null comment '作成日時',
    updated_at datetime null comment '更新日時'
)
    comment '掲示板投稿';

create table plango.categories
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    name        text null comment '名称',
    description text null comment '説明'
)
    comment 'カテゴリマスタ';

create table project_hub.comments
(
    unique_project_id text null,
    se_comment        text null,
    ig_comment        text null
);

create table plango.comments
(
    unique_project_id varchar(20)   not null comment 'ユニークプロジェクトID'
        primary key,
    se_comment        varchar(999)  null comment 'secomment',
    ig_comment        varchar(8999) null comment 'igcomment'
)
    comment 'プロジェクトコメント';

create table plango.company_calendar
(
    date        date       not null comment '日付'
        primary key,
    is_holiday  tinyint(1) null comment 'holidayフラグ',
    description text       null comment '説明'
)
    comment '会社カレンダー';

create table project_hub.completed_projects
(
    unique_project_id text null,
    complete          int  null
);

create table plango.completed_projects
(
    unique_project_id varchar(20) not null comment 'ユニークプロジェクトID'
        primary key,
    complete          tinyint(1)  not null comment 'complete'
)
    comment '完了プロジェクト';

create table plango.completed_projects_
(
    id                         int unsigned auto_increment
        primary key,
    unique_project_id          varchar(20) collate utf8mb4_unicode_ci as (concat(`project_id`, _utf8mb4'-', `sub_project_id`)),
    project_id                 text collate utf8mb4_unicode_ci         null,
    sub_project_id             text collate utf8mb4_unicode_ci         null,
    sub3_id                    varchar(3) collate utf8mb4_unicode_ci   null,
    order_number               text collate utf8mb4_unicode_ci         null,
    client_name                text collate utf8mb4_unicode_ci         null,
    project_title              text collate utf8mb4_unicode_ci         null,
    contract_deadline          date                                    null,
    inspection_date            date                                    null,
    inspection_completion_date date                                    null,
    shipping_approval_date     date                                    null,
    witness_date               date                                    null,
    shipping_date              date                                    null,
    progress                   int                                     null,
    area_used                  double                                  null,
    deployment_location        text collate utf8mb4_unicode_ci         null,
    business_trip_period       text collate utf8mb4_unicode_ci         null,
    technical_manager          text collate utf8mb4_unicode_ci         null,
    admin_manager              text collate utf8mb4_unicode_ci         null,
    person_in_charge           text collate utf8mb4_unicode_ci         null,
    worker                     text collate utf8mb4_unicode_ci         null,
    support_staff              text collate utf8mb4_unicode_ci         null,
    case_name                  text collate utf8mb4_unicode_ci         null,
    source_inspection          tinyint(1)                              null,
    witness_inspection         tinyint(1)                              null,
    equipment_configuration    text collate utf8mb4_unicode_ci         null,
    resource_registration      text collate utf8mb4_unicode_ci         null,
    cost_thousand_yen          int                                     null,
    man_hours                  double                                  null,
    used_man_hours             double                                  null,
    created_at                 datetime                                null,
    updated_at                 datetime                                null,
    comment                    text collate utf8mb4_unicode_ci         null,
    completed_at               datetime                                null,
    preparation_for_inspection text collate utf8mb4_unicode_ci         null,
    preparation_for_attendance text collate utf8mb4_unicode_ci         null,
    preparation_for_shipment   text collate utf8mb4_unicode_ci         null,
    updated_by                 text collate utf8mb4_unicode_ci         null,
    shipping_handover_date     date                                    null,
    business_trip_start_date   date                                    null,
    business_trip_end_date     date                                    null,
    acceptance_date            date                                    null,
    spec_issue_date            date                                    null,
    witness_start_date1        date                                    null,
    witness_end_date1          date                                    null,
    witness_start_date2        date                                    null,
    witness_end_date2          date                                    null,
    witness_start_date3        date                                    null,
    witness_end_date3          date                                    null,
    witness_start_date4        date                                    null,
    witness_end_date4          date                                    null,
    witness_start_date5        date                                    null,
    witness_end_date5          date                                    null,
    sales_manager              text collate utf8mb4_unicode_ci         null,
    electric_manager           text collate utf8mb4_unicode_ci         null,
    mechanical_manager         text collate utf8mb4_unicode_ci         null,
    production_manager         text collate utf8mb4_unicode_ci         null,
    logistics_manager          text collate utf8mb4_unicode_ci         null,
    manufacturing_manager      text collate utf8mb4_unicode_ci         null,
    quality_manager            text collate utf8mb4_unicode_ci         null,
    equipment_tech_manager     text collate utf8mb4_unicode_ci         null,
    jrcls_manager              text collate utf8mb4_unicode_ci         null,
    customer_manager           text collate utf8mb4_unicode_ci         null,
    owner_group_name           varchar(255) collate utf8mb4_unicode_ci null,
    complete                   tinyint(1) default 0                    not null
);

create index idx_completed_projects_owner_group
    on plango.completed_projects_ (owner_group_name);

create index idx_completed_projects_sub3_id
    on plango.completed_projects_ (sub3_id);

create table plango.completed_todos
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    project_id           int                  null comment 'プロジェクトID',
    title                text                 null comment 'タイトル',
    description          text                 null comment '説明',
    priority             int                  null comment '優先度',
    start_date           date                 null comment '開始日',
    due_date             date                 null comment '期限日',
    progress             int                  null comment '進捗率',
    department           text                 null comment 'department',
    affiliation_category text                 null comment '所属区分',
    completed_at         datetime             null comment '完了日時',
    completed_by         text                 null comment '完了者',
    original_created_at  datetime             null comment 'originalcreated日時',
    original_created_by  text                 null comment 'originalcreated者',
    assigned_to          text                 null comment 'assignedto',
    attachment           text                 null comment '添付ファイル',
    attachment_filename  text                 null comment '添付ファイルfilename',
    template_id          int                  null comment 'テンプレートID',
    original_progress    int                  null comment 'originalprogress',
    no_deadline_mail     tinyint(1) default 0 not null comment 'nodeadlineメール'
)
    comment '完了TODO';

create table plango.consumables_items
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    item_name            text       null comment '品名',
    item_code            text       null comment '品目コード',
    unit_price           int        null comment '単価',
    remark               text       null comment '備考',
    purchase_destination text       null comment 'purchasedestination',
    is_active            tinyint(1) null comment '有効フラグ',
    created_at           datetime   null comment '作成日時',
    updated_at           datetime   null comment '更新日時'
)
    comment '消耗品品目マスタ';

create table plango.consumables_request_details
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    header_id            int  null comment 'ヘッダーID',
    item_id              int  null comment '品目ID',
    item_name            text null comment '品名',
    item_code            text null comment '品目コード',
    unit_price           int  null comment '単価',
    quantity             int  null comment '数量',
    total_price          int  null comment '合計金額',
    purchase_destination text null comment 'purchasedestination'
)
    comment '消耗品申請明細';

create table plango.consumables_request_headers
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    requester_id      text     null comment '申請者ID',
    requester_name    text     null comment '申請者名',
    requester_group   text     null comment '申請者グループ',
    requester_email   text     null comment '申請者メールアドレス',
    requester_dept_id text     null comment '申請者部門ID',
    requester_dept    text     null comment '申請者部門',
    requester_company text     null comment '申請者会社',
    requester_bu      text     null comment '申請者事業部',
    total_amount      int      null comment '合計金額',
    status            text     null comment '状態',
    created_at        datetime null comment '作成日時'
)
    comment '消耗品申請ヘッダー';

create table ifs_reference_data.design_plan_table
(
    unique_project_id         varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID'
        primary key,
    components_list_date      varchar(20) null comment '構成品目表出図日',
    drawing_release_date      varchar(20) null comment '図面出図日',
    inspection_guideline_date varchar(20) null comment '検査実施要領書出図日',
    dr_date                   varchar(20) null comment 'DR（打ち合わせ）予定日',
    dve_date                  varchar(20) null,
    incoming_inspection_date  varchar(20) null comment '入検日',
    inspection_meeting_date   varchar(20) null comment '立会日',
    dva_date                  varchar(20) null comment 'DVa予定日',
    ship_date                 varchar(20) null comment '出荷予定日',
    completion_documents_date varchar(20) null comment '完成図書出図予定日',
    years                     varchar(20) not null comment '年度'
)
    comment '設計計画書情報テーブル';

create table ifs_reference_data.device_used_history_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20) null comment 'プロジェクトID＋サブプロジェクトID',
    device_id         char(10) null comment '測定器ID',
    using_start_date  datetime null comment '利用開始日',
    using_end_date    datetime null comment '利用終了日'
);

create table ifs_reference_data.drawing_status_table
(
    unique_project_id  char(20) not null
        primary key,
    blue_print_kind_id char(20) null comment '図面種別ID',
    status_id          int      null
)
    comment '図面出図状態テーブル';

create table plango.duty_item_answer_files
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    year          int                     null comment '年',
    month         int                     null comment '月',
    group_name    varchar(255) default '' not null comment 'グループ名',
    item_id       int                     null comment '品目ID',
    employee_id   text                    null comment '従業員ID',
    version_no    int                     null comment '版番号',
    original_name text                    null comment '元ファイル名',
    stored_name   text                    null comment '保存ファイル名',
    stored_path   text                    null comment 'storedpath',
    uploaded_by   text                    null comment 'アップロード者',
    uploaded_at   datetime                null comment 'アップロード日時',
    note          text                    null comment '備考'
)
    comment '当番品目回答ファイル';

create table plango.duty_item_task_files
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    year          int                     null comment '年',
    month         int                     null comment '月',
    group_name    varchar(255) default '' not null comment 'グループ名',
    item_id       int                     null comment '品目ID',
    file_type     text                    null comment 'ファイル種別',
    original_name text                    null comment '元ファイル名',
    stored_name   text                    null comment '保存ファイル名',
    stored_path   text                    null comment 'storedpath',
    uploaded_by   text                    null comment 'アップロード者',
    uploaded_at   datetime                null comment 'アップロード日時',
    note          text                    null comment '備考'
)
    comment '当番品目タスクファイル';

create table plango.duty_items
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    name        text                    null comment '名称',
    description text                    null comment '説明',
    group_name  varchar(255) default '' not null comment 'グループ名',
    sort_order  int                     null comment '並び順',
    is_active   int                     null comment '有効フラグ',
    created_at  datetime                null comment '作成日時',
    updated_at  datetime                null comment '更新日時'
)
    comment '当番明細';

create table plango.duty_monthly_assignments
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    year        int                     null comment '年',
    month       int                     null comment '月',
    group_name  varchar(255) default '' not null comment 'グループ名',
    item_id     int                     null comment '品目ID',
    employee_id text                    null comment '従業員ID',
    note        text                    null comment '備考',
    created_at  datetime                null comment '作成日時',
    updated_at  datetime                null comment '更新日時'
)
    comment '当番月次割当管理';

create index idx_duty_assign_group_ym
    on plango.duty_monthly_assignments (group_name, year, month);

create table ifs_reference_data.dva_history_table
(
    unique_project_id varchar(50)  not null
        primary key,
    sub_project_name  varchar(100) null comment '件名',
    client_name       varchar(100) null comment '客先名',
    status            varchar(20)  null comment '状態',
    file_path         varchar(999) not null comment 'ファイルパス',
    control_number    varchar(20)  null comment '管理番号',
    completion_id     varchar(20)  null comment '整理番号'
);

create table plango.equipment
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    name              text                 null comment '名称',
    category_id       int                  null comment 'カテゴリID',
    asset_code        text                 null comment 'assetコード',
    location          text                 null comment '場所',
    manager_user_id   text                 null comment '管理者ユーザーID',
    owner_group_name  varchar(255)         null comment '所有グループ名',
    remarks           text                 null comment '備考',
    usage_notes       text                 null comment '使用notes',
    approval_required int                  null comment '承認要否',
    enabled           int                  null comment '有効状態',
    created_at        datetime             null comment '作成日時',
    updated_at        datetime             null comment '更新日時',
    item1             text                 null comment 'item1',
    item2             text                 null comment 'item2',
    item3             text                 null comment 'item3',
    item4             text                 null comment 'item4',
    item5             text                 null comment 'item5',
    item6             text                 null comment 'item6',
    item7             text                 null comment 'item7',
    item8             text                 null comment 'item8',
    item9             text                 null comment 'item9',
    item10            text                 null comment 'item10',
    is_shared         tinyint(1) default 0 not null comment 'sharedフラグ'
)
    comment '設備管理';

create table plango.equipment_categories
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    name        text null comment '名称',
    description text null comment '説明'
)
    comment '設備カテゴリ管理';

create table plango.equipment_permissions
(
    id           int unsigned auto_increment comment 'ID'
        primary key,
    equipment_id int      null comment '設備ID',
    role         text     null comment 'ロール',
    created_at   datetime null comment '作成日時'
)
    comment '設備権限管理';

create table plango.equipment_reservation_series
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    equipment_id      int      null comment '設備ID',
    created_by        text     null comment '作成者',
    title             text     null comment 'タイトル',
    description       text     null comment '説明',
    pattern_type      text     null comment '繰返しパターン種別',
    weekday           int      null comment '曜日',
    month_day         int      null comment '日付',
    start_date        date     null comment '開始日',
    end_date          date     null comment '終了日',
    start_time        text     null comment '開始時刻',
    end_time          text     null comment '終了時刻',
    all_day           int      null comment '終日フラグ',
    approval_required int      null comment '承認要否',
    status            text     null comment '状態',
    created_at        datetime null comment '作成日時'
)
    comment '設備予約繰返し予約';

create table plango.equipment_reservations
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    equipment_id      int        null comment '設備ID',
    series_id         int        null comment '繰返し予約ID',
    reserved_by       text       null comment '予約者',
    title             text       null comment 'タイトル',
    description       text       null comment '説明',
    start_datetime    datetime   null comment 'startdatetime',
    end_datetime      datetime   null comment 'enddatetime',
    all_day           tinyint(1) null comment '終日フラグ',
    approval_required tinyint(1) null comment '承認要否',
    status            text       null comment '状態',
    created_at        datetime   null comment '作成日時',
    updated_at        datetime   null comment '更新日時',
    approved_by       text       null comment '承認者',
    approved_at       datetime   null comment '承認日時',
    rejected_by       text       null comment '却下者',
    rejected_at       datetime   null comment '却下日時',
    cancelled_by      text       null comment '取消者',
    cancelled_at      datetime   null comment '取消日時',
    item1             text       null comment 'item1',
    item2             text       null comment 'item2',
    item3             text       null comment 'item3',
    item4             text       null comment 'item4',
    item5             text       null comment 'item5'
)
    comment '設備予約';

create table plango.estimate_pdfs
(
    id           int unsigned auto_increment comment 'ID'
        primary key,
    pjid         varchar(50) null comment 'プロジェクトID',
    subid        varchar(20) null comment 'サブプロジェクトID',
    amount_yen   int         null comment '金額（円）',
    file_name    text        null comment 'ファイル名',
    file_path    text        null comment 'ファイルパス',
    extracted_at datetime    null comment '抽出日時',
    source       text        null comment 'source',
    note         text        null comment '備考',
    constraint uq_estimate_pj_sub
        unique (pjid, subid)
)
    comment '見積PDF管理';

create table ifs_reference_data.external_users_table
(
    jrc_user_code    varchar(10)  not null
        primary key,
    jrc_user_name    varchar(50)  not null,
    jrc_mail_address varchar(255) null,
    jrc_group_id     int          not null,
    password         varchar(255) not null,
    system_admin     tinyint(1)   not null,
    admin            tinyint(1)   not null,
    standard         tinyint(1)   not null,
    guest            tinyint(1)   not null,
    created_at       datetime     not null,
    updated_at       datetime     not null
);

create table project_hub.gantt_details
(
    id                int  null,
    unique_project_id text null,
    process_kind_id   int  null,
    detail_comment    text null,
    update_by         text null,
    update_date       text null
);

create table plango.gantt_details
(
    id                int auto_increment comment 'ID'
        primary key,
    unique_project_id varchar(20) not null comment 'ユニークプロジェクトID',
    process_kind_id   int         not null comment '工程種別ID',
    detail_comment    mediumtext  null comment '詳細コメント',
    update_by         varchar(10) not null comment '更新者',
    update_date       varchar(30) not null comment '更新日'
)
    comment 'ガント詳細管理';

create table plango.group_board_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    post_id         int      null comment '投稿ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment 'グループ掲示板添付ファイル';

create table plango.group_board_posts
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    project_id int      null comment 'プロジェクトID',
    title      text     null comment 'タイトル',
    content    text     null comment '内容',
    created_by text     null comment '作成者',
    created_at datetime null comment '作成日時',
    updated_at datetime null comment '更新日時'
)
    comment 'グループ掲示板投稿';

create table ifs_reference_data.group_kind_table
(
    jrc_group_id   int      not null comment 'グループID'
        primary key,
    jrc_group_name char(50) null comment 'グループ名',
    jrc_group_code char(20) null comment 'グループコード'
)
    comment 'グループ種別定義テーブル';

create table plango.group_project_issue_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    issue_id        int      null comment '課題ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment 'グループプロジェクト課題添付ファイル';

create table plango.group_project_issues
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    project_id  int        null comment 'プロジェクトID',
    title       text       null comment 'タイトル',
    description text       null comment '説明',
    solution    text       null comment 'ソリューション',
    department  text       null comment 'department',
    assignee    text       null comment 'assignee',
    due_date    date       null comment '期限日',
    progress    int        null comment '進捗率',
    status      text       null comment '状態',
    priority    text       null comment '優先度',
    notes       text       null comment 'notes',
    completed   tinyint(1) null comment '完了',
    created_by  text       null comment '作成者',
    updated_by  text       null comment '更新者',
    created_at  datetime   null comment '作成日時',
    updated_at  datetime   null comment '更新日時'
)
    comment 'グループプロジェクト課題管理';

create table plango.group_project_todo_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    todo_id         int      null comment 'TODO ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment 'グループプロジェクトTODO添付ファイル';

create table plango.group_project_todos
(
    id           int unsigned auto_increment comment 'ID'
        primary key,
    project_id   int        null comment 'プロジェクトID',
    title        text       null comment 'タイトル',
    description  text       null comment '説明',
    assignee     text       null comment 'assignee',
    priority     text       null comment '優先度',
    due_date     date       null comment '期限日',
    progress     int        null comment '進捗率',
    is_completed tinyint(1) null comment '完了フラグ',
    created_by   text       null comment '作成者',
    created_at   datetime   null comment '作成日時',
    updated_at   datetime   null comment '更新日時',
    completed_at datetime   null comment '完了日時'
)
    comment 'グループプロジェクトTODO管理';

create table plango.group_projects
(
    id               int unsigned auto_increment comment 'ID'
        primary key,
    title            text                                null comment 'タイトル',
    category         text                                null comment 'カテゴリ',
    manager          text                                null comment 'manager',
    members          text                                null comment 'メンバー',
    status           text                                null comment '状態',
    owner_group_name varchar(255)                        null comment '所有グループ名',
    created_at       timestamp default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at       timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    creator          text                                null comment 'creator'
)
    comment 'グループプロジェクト管理';

create table ifs_reference_data.ifs_components_table
(
    other_demand_sequence           double       not null comment 'その他需要連番'
        primary key,
    unique_project_id               varchar(30) as (concat(`project_id`, _utf8mb4'-', `sub_project_id`)) stored,
    project_id                      varchar(50)  null comment 'プロジェクトID',
    activity_sequence               varchar(50)  null comment 'アクティビティ番号',
    site                            varchar(50)  null,
    digit_number                    varchar(50)  null comment '桁番号',
    item_name                       varchar(255) null comment '品名',
    standard_planned_item           varchar(50)  null,
    required_quantity               varchar(50)  null comment '要求数量',
    requested_quantity              varchar(50)  null comment '要求済み数量',
    allocated_quantity              varchar(50)  null,
    received_quantity               varchar(50)  null comment '入庫数量',
    shipped_quantity                varchar(50)  null comment '出庫数量',
    allocated_at_receipt            varchar(50)  null,
    receipt_date                    varchar(50)  null,
    shipment_date                   varchar(50)  null comment '出荷日',
    allocatable                     varchar(50)  null,
    desired_delivery_date           varchar(50)  null,
    arrangement_date                varchar(50)  null,
    shipping_flag                   varchar(50)  null comment '出荷フラグ',
    manufacturing_number            varchar(50)  null comment '製造番号',
    supply_option                   varchar(50)  null comment '手配区分（購買・在庫等）',
    shipment_info_id                varchar(50)  null comment '出荷情報ID',
    shipping_date                   varchar(50)  null comment '出荷日',
    shape_name                      varchar(50)  null comment '型名',
    assembly_sign                   varchar(50)  null comment '組込サイン（桁番号に紐づく）',
    power_source                    varchar(50)  null,
    power_source_name               varchar(50)  null,
    instruction_sign                varchar(50)  null,
    destination                     varchar(50)  null,
    shipping_item_list_sign         varchar(50)  null comment '出荷リストサイン',
    prior_shipment_sign             varchar(50)  null comment '出荷サイン',
    instruction_notes               varchar(999) null comment '手配についての備考',
    shipping_request_quantity       varchar(50)  null comment '出荷要求数量',
    registration_date_time          varchar(50)  null,
    registrant                      varchar(50)  null,
    update_date_time                varchar(50)  null comment '更新日時',
    updater                         varchar(50)  null comment '更新者',
    shipping_base                   varchar(50)  null,
    withdrawal_instruction_date     varchar(50)  null comment '払出完了日',
    withdrawn_instruction_amount    varchar(50)  null comment '払出数',
    withdrawal_destination          varchar(50)  null comment '払出先',
    withdrawal_instruction_reg_date varchar(50)  null comment '払出（入検）要求日',
    sub_project_id                  varchar(50)  null comment 'サブプロジェクトID',
    activity_name                   varchar(255) null comment '装置区分',
    parent_sub_project_id           varchar(50)  null
);

create table ifs_reference_data.ifs_projects_table
(
    unique_project_id       varchar(20)  not null comment 'ユニークプロジェクトID',
    project_id              varchar(20)  not null comment 'プロジェクトID',
    sub_project_id          varchar(20)  null comment 'サブプロジェクトID',
    sub_project_name        varchar(255) null comment '社内件名',
    department              varchar(50)  null comment '部門',
    parent_sub_project_id   varchar(20)  null comment '親サブプロジェクトID（SPJとか）',
    variety                 varchar(50)  null comment 'サブプロジェクト種別',
    sub_project_amount      varchar(50)  null comment 'サブプロジェクト金額',
    sub_project_cost        varchar(50)  null comment 'サブプロジェクトコスト',
    completion_request_date varchar(50)  null comment '完了要求日',
    completion_request      varchar(50)  null comment '完了要求',
    status                  varchar(20)  null comment '完了状態',
    variety_name            varchar(50)  null comment 'サブプロジェクト種別',
    project_name            varchar(50)  null comment 'プロジェクト名',
    accounting_completed    varchar(50)  null comment '完了状態',
    completion_date         varchar(50)  null comment '完了日',
    initial_completion_date varchar(50)  null comment '初回完了日時',
    primary key (unique_project_id, project_id)
)
    comment 'プロジェクト一覧テーブル';

create table plango.info_board_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    post_id         int      null comment '投稿ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment 'お知らせ掲示板添付ファイル';

create table plango.info_board_posts
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    title      text     null comment 'タイトル',
    content    text     null comment '内容',
    created_by text     null comment '作成者',
    created_at datetime null comment '作成日時',
    updated_at datetime null comment '更新日時'
)
    comment 'お知らせ掲示板投稿';

create table ifs_reference_data.information_equipment_assign_table
(
    information_device_id varchar(30)                        not null comment '識別ID',
    serial_number         varchar(50)                        null comment '製造番号',
    device_type_name      varchar(40)                        null comment '機器型名',
    device_name           varchar(50)                        null comment '機器名称',
    jrc_user_name         varchar(50)                        null comment '氏名',
    jrc_user_code         varchar(50)                        null comment '個人コード',
    department            varchar(50)                        null comment '事業部名',
    department2           varchar(50)                        null comment '部門名',
    jrc_group_id          int                                null comment 'グループID',
    place                 varchar(50)                        null comment '利用場所',
    building_number       varchar(50)                        null comment '建物番号',
    flore                 varchar(50)                        null comment 'フロア',
    device_variety_id     int                                null comment '機器種別ID',
    ip_address            varchar(50)                        null comment 'IPアドレス',
    using_for             varchar(50)                        null comment '利用用途',
    `order`               varchar(50)                        null comment '支払いオーダ',
    price_par_month       varchar(50)                        null comment '月額',
    check_date            varchar(50)                        null comment '棚卸日',
    update_date           datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '情報更新日時'
);

create table plango.inspection_areas
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    code       text null comment 'コード',
    name       text null comment '名称',
    sort_order int  null comment '並び順',
    is_active  int  null comment '有効フラグ'
)
    comment '検査エリア管理';

create table plango.inspection_locations
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    area_id           int      null comment 'エリアID',
    description       text     null comment '説明',
    pdf_filename      text     null comment 'PDFfilename',
    original_filename text     null comment 'originalfilename',
    created_at        datetime null comment '作成日時',
    updated_at        datetime null comment '更新日時'
)
    comment '検査場所管理';

create table plango.inspection_sheets
(
    id             int auto_increment comment 'ID'
        primary key,
    project_id     varchar(255)                          not null comment 'プロジェクトID',
    sub_project_id varchar(255)                          null comment 'サブプロジェクトID',
    customer_name  varchar(255)                          null comment '顧客名',
    item_name      varchar(255)                          null comment '品名',
    product_name   varchar(255)                          null comment 'product名',
    model_name     varchar(255)                          null comment '型名',
    order_no       varchar(255)                          null comment '手配no',
    quantity       varchar(50)                           null comment '数量',
    mouths         varchar(50)                           null comment 'mouths',
    system_name    varchar(255)                          null comment 'システム名',
    status         varchar(20) default 'not_inspected'   null comment '状態',
    inspector      varchar(255)                          null comment 'inspector',
    created_at     timestamp   default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at     timestamp   default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment '検査帳票管理';

create table plango.instrument_import_logs
(
    id            bigint auto_increment comment 'ID'
        primary key,
    imported_at   datetime                           not null comment '取込日時',
    file_name     varchar(255)                       not null comment 'ファイル名',
    inserted      int                                not null comment '登録件数',
    updated       int                                not null comment '更新件数',
    errors        int                                not null comment 'エラー件数',
    error_summary text                               null comment 'エラー概要',
    created_at    datetime default CURRENT_TIMESTAMP not null comment '作成日時'
)
    comment '計測器取込ログ';

create table plango.instrument_import_error_rows
(
    id            bigint auto_increment comment 'ID'
        primary key,
    import_log_id bigint                             not null comment '取込ログID',
    row_index     int                                not null comment '行index',
    management_no varchar(255)                       not null comment '管理番号',
    message       text                               not null comment 'メッセージ',
    created_at    datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    constraint instrument_import_error_rows_ibfk_1
        foreign key (import_log_id) references plango.instrument_import_logs (id)
)
    comment '計測器取込エラー行管理';

create index import_log_id
    on plango.instrument_import_error_rows (import_log_id);

create table plango.instrument_usage_headers
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    inspection_date date                               null comment '検査日',
    temperature     double                             null comment '温度',
    humidity        double                             null comment '湿度',
    env_device_id   int                                null comment 'envデバイスID',
    env_timestamp   datetime                           null comment 'envtimestamp',
    project_id      text                               null comment 'プロジェクトID',
    sub_project_id  text                               null comment 'サブプロジェクトID',
    subject         text                               null comment 'subject',
    created_by      text                               null comment '作成者',
    created_at      datetime default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at      datetime default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    case_name       text                               null comment '案件名',
    status          text                               null comment '状態',
    completed_by    text                               null comment '完了者',
    completed_at    datetime                           null comment '完了日時'
)
    comment '計測器使用ヘッダー';

create table plango.instrument_usage_items
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    header_id            int  null comment 'ヘッダーID',
    row_no               int  null comment '行番号',
    instrument_id        int  null comment '計測器ID',
    name                 text null comment '名称',
    model                text null comment 'model',
    maker                text null comment 'メーカー',
    management_no        text null comment '管理番号',
    calibration_valid_ym text null comment 'calibrationvalidym',
    remark               text null comment '備考',
    created_at           text null comment '作成日時',
    updated_at           text null comment '更新日時'
)
    comment '計測器使用明細';

create table plango.issue_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    issue_id        int      null comment '課題ID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment '課題添付ファイル';

create table plango.issues
(
    id                           int unsigned auto_increment comment 'ID'
        primary key,
    project_id                   int                  null comment 'プロジェクトID',
    title                        text                 null comment 'タイトル',
    description                  text                 null comment '説明',
    status                       text                 null comment '状態',
    priority                     text                 null comment '優先度',
    created_by                   text                 null comment '作成者',
    created_at                   datetime             null comment '作成日時',
    updated_at                   datetime             null comment '更新日時',
    measures                     text                 null comment 'measures',
    department                   text                 null comment 'department',
    affiliation_category         varchar(255)         null comment '所属区分',
    group_name                   varchar(255)         null comment 'グループ名',
    person_in_charge             text                 null comment '担当者',
    person_in_charge_employee_id varchar(32)          null comment '担当者従業員ID',
    person_in_charge_name        text                 null comment '担当者名',
    person_in_charge_free        text                 null comment 'personinchargefree',
    deadline                     date                 null comment '期限',
    progress                     int                  null comment '進捗率',
    updated_by                   text                 null comment '更新者',
    remarks                      text                 null comment '備考',
    disable_email_notification   tinyint(1) default 0 not null comment 'メール通知無効フラグ',
    overdue_notified_count       int        default 0 not null comment '期限超過通知回数',
    last_overdue_notified_at     datetime             null comment '最終期限超過通知日時'
)
    comment '課題管理';

create table plango.job_types
(
    id            int auto_increment comment 'ID'
        primary key,
    code          varchar(50)   not null comment 'コード',
    name          varchar(255)  not null comment '名称',
    display_order int default 0 null comment '表示順',
    constraint code
        unique (code)
)
    comment '職種種別管理';

create table ifs_reference_data.jrc_users_table
(
    jrc_user_code    char(10) not null comment '個人コード'
        primary key,
    jrc_user_name    char(50) null comment 'ユーザー名',
    jrc_mail_address char(50) null comment 'メールアドレス',
    jrc_group_id     int      null comment 'グループID',
    constraint jrc_users_table_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references ifs_reference_data.group_kind_table (jrc_group_id)
);

create table plango.labels
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    data_json  text     null comment 'データJSON',
    created_at datetime null comment '作成日時',
    updated_at datetime null comment '更新日時'
)
    comment 'ラベル管理';

create table plango.layouts
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    filename      text     null comment 'ファイル名',
    original_name text     null comment '元ファイル名',
    project       text     null comment 'プロジェクト',
    usage_text    text     null comment '使用text',
    remark        text     null comment '備考',
    created_at    datetime null comment '作成日時',
    updated_at    datetime null comment '更新日時'
)
    comment 'レイアウト管理';

create table plango.learning_courses
(
    id              int unsigned auto_increment
        primary key,
    title           varchar(255)                          not null,
    description     text                                  null,
    schedule_at     datetime                              null,
    location        varchar(255)                          null,
    capacity        int                                   null,
    status          varchar(20) default 'open'            not null,
    created_by_id   varchar(32)                           null,
    created_by_name varchar(255)                          null,
    created_at      datetime    default CURRENT_TIMESTAMP not null,
    updated_at      datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.learning_applications
(
    id            int unsigned auto_increment
        primary key,
    course_id     int unsigned                         not null,
    employee_id   varchar(32)                          not null,
    employee_name varchar(255)                         not null,
    comment       text                                 null,
    attended      tinyint(1) default 0                 not null,
    attended_at   datetime                             null,
    created_at    datetime   default CURRENT_TIMESTAMP not null,
    constraint fk_learning_app_course
        foreign key (course_id) references plango.learning_courses (id)
            on delete cascade
);

create table plango.learning_materials
(
    id               int unsigned auto_increment
        primary key,
    title            varchar(255)                       not null,
    category         varchar(100)                       null,
    description      text                               null,
    file_path        varchar(500)                       not null,
    original_name    varchar(255)                       not null,
    mime_type        varchar(100)                       not null,
    file_size        int unsigned                       not null,
    uploaded_by_id   varchar(32)                        null,
    uploaded_by_name varchar(255)                       null,
    created_at       datetime default CURRENT_TIMESTAMP not null,
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.learning_course_materials
(
    id            int unsigned auto_increment
        primary key,
    course_id     int unsigned                       not null,
    material_id   int unsigned                       not null,
    display_order int      default 0                 not null,
    note          varchar(255)                       null,
    created_at    datetime default CURRENT_TIMESTAMP not null,
    constraint uq_course_material
        unique (course_id, material_id),
    constraint fk_lcm_course
        foreign key (course_id) references plango.learning_courses (id)
            on delete cascade,
    constraint fk_lcm_material
        foreign key (material_id) references plango.learning_materials (id)
            on delete cascade
);

create table plango.learning_tools
(
    id                int unsigned auto_increment
        primary key,
    title             varchar(255)                       not null,
    category          varchar(100)                       null,
    description       text                               null,
    file_path         varchar(500)                       not null,
    original_name     varchar(255)                       not null,
    mime_type         varchar(100)                       not null,
    file_size         int unsigned                       not null,
    doc_file_path     varchar(1024)                      null,
    doc_original_name varchar(255)                       null,
    doc_mime_type     varchar(255)                       null,
    doc_file_size     bigint                             null,
    uploaded_by_id    varchar(32)                        null,
    uploaded_by_name  varchar(255)                       null,
    created_at        datetime default CURRENT_TIMESTAMP not null,
    updated_at        datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP
);

create table plango.learning_tweets
(
    id            int unsigned auto_increment
        primary key,
    employee_id   varchar(32)                        not null,
    employee_name varchar(255)                       not null,
    message       text                               not null,
    created_at    datetime default CURRENT_TIMESTAMP not null,
    file_path     varchar(512)                       null,
    original_name varchar(255)                       null,
    mime_type     varchar(255)                       null,
    file_size     bigint                             null
);

create table plango.ledger_layouts
(
    id            int auto_increment comment 'ID'
        primary key,
    ledger_code   varchar(16)                          not null comment '台帳コード',
    type_no       varchar(8)                           not null comment '種別no',
    name          varchar(255)                         not null comment '名称',
    description   text                                 null comment '説明',
    columns_json  json                                 not null comment '列定義JSON',
    template_path varchar(512)                         null comment 'テンプレートパス',
    active_flag   tinyint(1) default 1                 not null comment '有効フラグ',
    created_at    datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    created_by    varchar(64)                          null comment '作成者',
    updated_at    datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    updated_by    varchar(64)                          null comment '更新者',
    constraint uq_ledger_layouts_code
        unique (ledger_code)
)
    comment '台帳レイアウト管理';

create table plango.ledger_entries
(
    id               int auto_increment comment 'ID'
        primary key,
    ledger_layout_id int                                not null comment '台帳レイアウトID',
    group_id         int                                not null comment 'グループID',
    control_no       varchar(64)                        not null comment '管理番号',
    title            varchar(255)                       null comment 'タイトル',
    data_json        json                               not null comment 'データJSON',
    issue_date       date                               null comment '発行日',
    created_at       datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    created_by       varchar(64)                        null comment '作成者',
    updated_at       datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    updated_by       varchar(64)                        null comment '更新者',
    constraint uq_control_no
        unique (control_no),
    constraint fk_le_layout
        foreign key (ledger_layout_id) references plango.ledger_layouts (id)
)
    comment '台帳登録データ管理';

create index idx_layout_group
    on plango.ledger_entries (ledger_layout_id, group_id);

create table plango.ledger_group_settings
(
    id               int auto_increment comment 'ID'
        primary key,
    group_id         int                                  not null comment 'グループID',
    group_name       varchar(255)                         not null comment 'グループ名',
    ledger_layout_id int                                  not null comment '台帳レイアウトID',
    dept_code        varchar(8)                           not null comment 'deptコード',
    group_code       varchar(8)                           not null comment 'グループコード',
    active_flag      tinyint(1) default 1                 not null comment '有効フラグ',
    created_at       datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    created_by       varchar(64)                          null comment '作成者',
    updated_at       datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    updated_by       varchar(64)                          null comment '更新者',
    group_code1      varchar(8)                           null comment 'グループcode1',
    group_code2      varchar(8)                           null comment 'グループcode2',
    group_code3      varchar(8)                           null comment 'グループcode3',
    group_code4      varchar(8)                           null comment 'グループcode4',
    group_code5      varchar(8)                           null comment 'グループcode5',
    constraint uq_group_layout
        unique (group_id, ledger_layout_id),
    constraint fk_lgs_layout
        foreign key (ledger_layout_id) references plango.ledger_layouts (id)
            on delete cascade
)
    comment '台帳グループ設定';

create table plango.ledger_numbering_counters
(
    id          int auto_increment comment 'ID'
        primary key,
    group_id    int                                  not null comment 'グループID',
    ledger_code varchar(16)                          not null comment '台帳コード',
    year1       char                                 not null comment 'year1',
    group_code  varchar(8) default ''                not null comment 'グループコード',
    current_seq int        default 0                 not null comment '現在連番',
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint uq_counter
        unique (group_id, ledger_code, year1, group_code)
)
    comment '台帳採番カウンタ管理';

create table plango.login_logs
(
    id           int auto_increment comment 'ID'
        primary key,
    employee_id  varchar(50)  not null comment '従業員ID',
    name         varchar(255) not null comment '名称',
    group_name   varchar(255) null comment 'グループ名',
    company_name varchar(255) null comment '会社名',
    login_at     datetime     not null comment 'ログイン日時'
)
    comment 'ログインログ';

create index idx_login_logs_employee_id
    on plango.login_logs (employee_id);

create index idx_login_logs_login_at
    on plango.login_logs (login_at);

create table plango.mail_lists
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    owner_employee_id text null comment '所有者従業員ID',
    name              text null comment '名称',
    to_list           text null comment 'toリスト',
    cc_list           text null comment 'ccリスト',
    bcc_list          text null comment 'bccリスト',
    created_at        text null comment '作成日時',
    updated_at        text null comment '更新日時'
)
    comment 'メールリスト管理';

create table plango.manual_attachment_views
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    attachment_id int      null comment '添付ファイルID',
    user_id       text     null comment 'ユーザーID',
    downloaded_at datetime null comment 'ダウンロード日時'
)
    comment 'マニュアル添付ファイル閲覧管理';

create table plango.manual_attachments
(
    id             int unsigned auto_increment comment 'ID'
        primary key,
    manual_id      int      null comment 'マニュアルID',
    file_path      text     null comment 'ファイルパス',
    file_name      text     null comment 'ファイル名',
    original_name  text     null comment '元ファイル名',
    created_at     datetime null comment '作成日時',
    download_count int      null comment 'ダウンロード回数'
)
    comment 'マニュアル添付ファイル';

create table plango.manual_views
(
    id        int unsigned auto_increment comment 'ID'
        primary key,
    manual_id int      null comment 'マニュアルID',
    user_id   text     null comment 'ユーザーID',
    viewed_at datetime null comment '閲覧日時'
)
    comment 'マニュアル閲覧管理';

create table plango.manuals
(
    id               int unsigned auto_increment comment 'ID'
        primary key,
    title            text                 null comment 'タイトル',
    category         text                 null comment 'カテゴリ',
    description      text                 null comment '説明',
    file_path        text                 null comment 'ファイルパス',
    file_name        text                 null comment 'ファイル名',
    original_name    text                 null comment '元ファイル名',
    posted_at        datetime             null comment '掲載日時',
    created_at       datetime             null comment '作成日時',
    created_by       text                 null comment '作成者',
    owner_group_name varchar(255)         null comment '所有グループ名',
    is_shared        tinyint(1) default 1 not null comment 'sharedフラグ',
    updated_at       datetime             null comment '更新日時',
    updated_by       text                 null comment '更新者',
    status           text                 null comment '状態',
    view_count       int                  null comment '閲覧回数',
    download_count   int                  null comment 'ダウンロード回数'
)
    comment 'マニュアル管理';

create table ifs_reference_data.measuring_device_kind_table
(
    device_id                   char(10)                                                  not null comment '計測器管理番号'
        primary key,
    device_name                 varchar(100)                                              null comment '計測器名称',
    device_type_name            varchar(100)                                              null comment '計測器型名',
    device_maker                varchar(100)                                              null comment '計測器メーカ',
    proofreading_date           date                                                      null comment '校正年月日',
    expiration_date             date                                                      null comment '校正有効期限',
    external_rental             tinyint(1)                                                null comment '0=社内レンタル、1=外部レンタル',
    lending_destination         varchar(100)                                              null comment '貸出先',
    remarks                     text                                                      null comment '備考',
    lending                     tinyint(1) default (ifnull(`lending_destination`, false)) null comment '1=貸出中',
    update_date                 datetime   default (now())                                null on update CURRENT_TIMESTAMP,
    calibration_certificate     varchar(255)                                              null comment '校正証明書ファイルパス',
    traceability_system_diagram varchar(255)                                              null comment 'トレーサビリティ体系図ファイルパス'
)
    comment '計測器一覧テーブル';

create table ifs_reference_data.device_assign_table
(
    jrc_user_code char(10)    not null comment '個人コード'
        primary key,
    device_id     varchar(10) null comment '測定器ID',
    constraint device_assign_table_measuring_device_kind_table_device_id_fk
        foreign key (device_id) references ifs_reference_data.measuring_device_kind_table (device_id)
)
    comment '機器割り当て用テーブル';

create table plango.measuring_instrument_usage_history
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    instrument_id        int      null comment '計測器ID',
    usage_type           text     null comment '使用種別',
    project_category     text     null comment 'プロジェクトカテゴリ',
    borrower_employee_id text     null comment 'borroweremployeeID',
    borrower_name        text     null comment 'borrower名',
    borrower_department  text     null comment 'borrowerdepartment',
    user_employee_id     text     null comment 'ユーザーemployeeID',
    user_name            text     null comment 'ユーザー名',
    user_department      text     null comment 'ユーザーdepartment',
    loan_start_date      date     null comment '貸出開始日',
    loan_end_date        date     null comment 'loanend日',
    planned_end_date     date     null comment 'plannedend日',
    status               text     null comment '状態',
    created_at           datetime null comment '作成日時',
    updated_at           datetime null comment '更新日時',
    usage_location       text     null comment '使用場所',
    calibration_result   text     null comment 'calibration結果',
    attachment_path      text     null comment '添付ファイルpath',
    calibration_comment  text     null comment 'calibrationcomment'
)
    comment '計測器使用履歴';

create table plango.measuring_instruments
(
    id                          int unsigned auto_increment comment 'ID'
        primary key,
    management_no               text                 null comment '管理番号',
    management_company_name     text                 null comment '管理会社名',
    item_name                   text                 null comment '品名',
    serial_no                   text                 null comment '製造番号',
    maker_info                  text                 null comment 'メーカー情報',
    model_name                  text                 null comment '型名',
    instrument_category         text                 null comment '計測器カテゴリ',
    management_class_1          text                 null comment '管理class1',
    management_class_2          text                 null comment '管理class2',
    operation_class_1           text                 null comment 'operationclass1',
    operation_class_2           text                 null comment 'operationclass2',
    performance                 text                 null comment 'performance',
    accessories                 text                 null comment 'accessories',
    instructions                text                 null comment 'instructions',
    asset_category              text                 null comment 'assetカテゴリ',
    owner_department            text                 null comment 'ownerdepartment',
    fixed_asset_ref             text                 null comment 'fixedassetref',
    purchase_order_no           text                 null comment 'purchase手配no',
    storage_department          text                 null comment 'storagedepartment',
    storage_location            text                 null comment 'storage場所',
    budget_order_no             text                 null comment 'budget手配no',
    manager_primary             text                 null comment 'managerprimary',
    manager_secondary           text                 null comment 'managersecondary',
    extension_number            text                 null comment 'extensionnumber',
    calibration_required        text                 null comment '校正要否',
    calibration_type            text                 null comment '校正種別',
    calibration_agency_type     text                 null comment 'calibrationagency種別',
    calibration_performed_date  date                 null comment '校正実施日',
    calibration_interval_months int                  null comment '校正周期（月）',
    calibration_next_due_date   date                 null comment '次回校正期限日',
    overdue_notified            tinyint(1) default 0 not null comment '期限超過通知済フラグ',
    overdue_notified_at         datetime             null comment '期限超過通知日時',
    calibration_responsible     text                 null comment 'calibrationresponsible',
    calibration_agency          text                 null comment 'calibrationagency',
    status                      text                 null comment '状態',
    created_at                  datetime             null comment '作成日時',
    updated_at                  datetime             null comment '更新日時',
    acquisition_date            date                 null comment 'acquisition日',
    acquisition_price           double               null comment 'acquisitionprice',
    loan_status                 text                 null comment '貸出状態',
    loan_start_date             date                 null comment '貸出開始日',
    loan_due_date               date                 null comment '貸出期限日',
    loan_project_category       text                 null comment 'loanプロジェクトカテゴリ',
    loan_borrower_id            text                 null comment 'loanborrowerID',
    loan_borrower_name          text                 null comment 'loanborrower名',
    loan_user_id                text                 null comment 'loanユーザーID',
    loan_user_name              text                 null comment 'loanユーザー名'
)
    comment '計測器管理';

create table plango.notices
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    notice_date date     null comment '通知日',
    importance  text     null comment 'importance',
    title       text     null comment 'タイトル',
    content     text     null comment '内容',
    created_at  datetime null comment '作成日時',
    updated_at  datetime null comment '更新日時'
)
    comment '通知管理';

create table ifs_reference_data.nulab_accounts_table
(
    id        int auto_increment
        primary key,
    user_id   varchar(50)  not null,
    nulab_id  varchar(100) null,
    name      varchar(100) null,
    unique_id varchar(100) null,
    constraint nulab_accounts_table_ibfk_1
        foreign key (user_id) references ifs_reference_data.backlog_users_table (userId)
            on delete cascade
);

create index user_id
    on ifs_reference_data.nulab_accounts_table (user_id);

create table plango.outsourcing_costs
(
    id             bigint auto_increment comment 'ID'
        primary key,
    expense_month  varchar(7)                         not null comment '費用計上月',
    external_id    varchar(50)                        not null comment '外注先ID',
    external_name  varchar(100)                       not null comment '外注先名',
    amount_yen     bigint                             not null comment '金額（円）',
    project_id     varchar(50)                        not null comment 'プロジェクトID',
    sub_project_id varchar(50)                        not null comment 'サブプロジェクトID',
    created_at     datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment '外注費用管理';

create index idx_outsrc_month
    on plango.outsourcing_costs (expense_month);

create index idx_outsrc_pj
    on plango.outsourcing_costs (project_id, sub_project_id);

create table plango.overtime_alert_logs
(
    id                  int unsigned auto_increment comment 'ID'
        primary key,
    employee_id         text     null comment '従業員ID',
    alert_type          text     null comment 'アラート種別',
    period_start        text     null comment 'periodstart',
    period_end          text     null comment 'periodend',
    first_exceeded_date text     null comment 'firstexceeded日',
    last_notified_date  text     null comment '最終通知日',
    notify_count        int      null comment '通知回数',
    created_at          datetime null comment '作成日時',
    updated_at          datetime null comment '更新日時'
)
    comment '時間外アラートログ';

create table plango.overtime_overlimit_requests
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    employee_id       text     null comment '従業員ID',
    year              int      null comment '年',
    month             int      null comment '月',
    chk_2m_140h       int      null comment 'chk2m140h',
    chk_1m_45_80h     int      null comment 'chk1m4580h',
    chk_holiday_3days int      null comment 'chkholiday3days',
    chk_15days_streak int      null comment 'chk15daysstreak',
    chk_1m_night_15h  int      null comment 'chk1mnight15h',
    chk_year_360_720h int      null comment 'chkyear360720h',
    note              text     null comment '備考',
    status            text     null comment '状態',
    proxy_employee_id text     null comment 'proxyemployeeID',
    created_at        datetime null comment '作成日時'
)
    comment '時間外上限超過申請';

create table plango.overtime_plans
(
    id                     int unsigned auto_increment comment 'ID'
        primary key,
    employee_id            text     null comment '従業員ID',
    date                   date     null comment '日付',
    planned_normal_minutes int      null comment 'plannednormalminutes',
    planned_early_minutes  int      null comment 'plannedearlyminutes',
    planned_night_minutes  int      null comment 'plannednightminutes',
    note                   text     null comment '備考',
    created_at             datetime null comment '作成日時',
    updated_at             datetime null comment '更新日時'
)
    comment '時間外予定';

create table plango.overtime_requests
(
    id                            int unsigned auto_increment comment 'ID'
        primary key,
    employee_id                   text                                null comment '従業員ID',
    group_code                    text                                null comment 'グループコード',
    group_name                    text                                null comment 'グループ名',
    date                          date                                null comment '日付',
    start_time                    text                                null comment '開始時刻',
    end_time                      text                                null comment '終了時刻',
    duration_minutes              int                                 null comment '時間（分）',
    duration_hours_exact          double                              null comment '時間（実数）',
    duration_hours_round_0_25     double                              null comment 'duration時間round025',
    duration_hours_0_017          double                              null comment 'duration時間0017',
    weekday_minutes               int                                 null comment 'weekdayminutes',
    holiday_minutes               int                                 null comment 'holidayminutes',
    night_minutes                 int                                 null comment 'nightminutes',
    weekday_normal_minutes        int                                 null comment 'weekdaynormalminutes',
    weekday_early_minutes         int                                 null comment 'weekdayearlyminutes',
    weekday_night_minutes         int                                 null comment 'weekdaynightminutes',
    holiday_normal_minutes        int                                 null comment 'holidaynormalminutes',
    holiday_early_minutes         int                                 null comment 'holidayearlyminutes',
    holiday_night_minutes         int                                 null comment 'holidaynightminutes',
    status                        text                                null comment '状態',
    reason                        text                                null comment 'reason',
    comment                       text                                null comment 'comment',
    category                      text                                null comment 'カテゴリ',
    proxy_employee_id             text                                null comment 'proxyemployeeID',
    approver_id                   text                                null comment 'approverID',
    approver_comment              text                                null comment 'approvercomment',
    approved_at                   timestamp                           null comment '承認日時',
    created_at                    timestamp default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at                    timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    actual_start_time             text                                null comment '実績開始時刻',
    actual_end_time               text                                null comment '実績終了時刻',
    actual_duration_minutes       int                                 null comment '実績時間（分）',
    actual_weekday_normal_minutes int                                 null comment 'actualweekdaynormalminutes',
    actual_weekday_early_minutes  int                                 null comment 'actualweekdayearlyminutes',
    actual_weekday_night_minutes  int                                 null comment 'actualweekdaynightminutes',
    actual_holiday_normal_minutes int                                 null comment 'actualholidaynormalminutes',
    actual_holiday_early_minutes  int                                 null comment 'actualholidayearlyminutes',
    actual_holiday_night_minutes  int                                 null comment 'actualholidaynightminutes',
    actual_recorded_at            timestamp                           null comment '実績記録日時',
    actual_comment                text                                null comment 'actualcomment',
    daikyu_planned_date           date                                null comment 'daikyuplanned日'
)
    comment '時間外申請';

create table plango.page_views
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    page_name   text     null comment 'ページ名',
    view_count  int      null comment '閲覧回数',
    last_viewed datetime null comment '最終閲覧日時'
)
    comment 'ページ閲覧管理';

create table project_hub.pages
(
    id         text null,
    title      text null,
    icon       text null,
    parent_id  text null,
    type       text null,
    created_at text null,
    updated_at text null
);

create table plango.partial_shipment
(
    unique_project_id   varchar(10) not null comment 'ユニークプロジェクトID'
        primary key,
    partial_ship_date_1 date        null comment '分納出荷date1',
    partial_ship_date_2 date        null comment '分納出荷date2',
    partial_ship_date_3 date        null comment '分納出荷date3',
    partial_ship_date_4 date        null comment '分納出荷date4',
    partial_ship_date_5 date        null comment '分納出荷date5',
    partial_ship_date_6 date        null comment '分納出荷date6',
    partial_ship_date_7 date        null comment '分納出荷date7',
    partial_ship_date_8 date        null comment '分納出荷date8',
    partial_ship_date_9 date        null comment '分納出荷date9'
)
    comment '分納出荷管理';

create table project_hub.partial_shipment
(
    unique_project_id   text null,
    partial_ship_date_1 text null,
    partial_ship_date_2 text null,
    partial_ship_date_3 text null,
    partial_ship_date_4 text null,
    partial_ship_date_5 text null,
    partial_ship_date_6 text null,
    partial_ship_date_7 text null,
    partial_ship_date_8 text null,
    partial_ship_date_9 text null
);

create table plango.pending_projects
(
    id                      bigint unsigned auto_increment comment 'ID'
        primary key,
    pending_code            varchar(50)                           null comment '受注見込コード',
    project_id              varchar(50)                           not null comment 'プロジェクトID',
    sub_project_id          varchar(50)                           null comment 'サブプロジェクトID',
    sub3_id                 varchar(3)                            null comment 'サブ3ID',
    owner_group_name        varchar(255)                          null comment '所有グループ名',
    client_name             text                                  not null comment '顧客名',
    project_title           text                                  not null comment 'プロジェクトtitle',
    sales_manager           text                                  null comment 'salesmanager',
    person_in_charge        text                                  null comment '担当者',
    admin_manager           text                                  null comment 'adminmanager',
    worker                  text                                  null comment 'worker',
    expected_amount_yen     bigint                                null comment '見込金額（円）',
    order_probability_level varchar(10)                           null comment '手配probabilityレベル',
    expected_order_date     date                                  null comment '受注予定日',
    inspection_date         date                                  null comment '検査日',
    witness_start_date1     date                                  null comment '立会startdate1',
    witness_end_date1       date                                  null comment '立会enddate1',
    witness_start_date2     date                                  null comment '立会startdate2',
    witness_end_date2       date                                  null comment '立会enddate2',
    witness_start_date3     date                                  null comment '立会startdate3',
    witness_end_date3       date                                  null comment '立会enddate3',
    shipping_date           date                                  null comment '出荷日',
    status                  varchar(20) default 'pending'         not null comment '状態',
    note                    text                                  null comment '備考',
    created_at              datetime    default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at              datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    created_by              text                                  null comment '作成者',
    updated_by              text                                  null comment '更新者'
)
    comment '受注見込プロジェクト管理';

create index idx_pending_projects_owner_group
    on plango.pending_projects (owner_group_name);

create index idx_pending_projects_project_id
    on plango.pending_projects (project_id);

create index idx_pending_projects_status
    on plango.pending_projects (status);

create index idx_pending_projects_sub3
    on plango.pending_projects (sub3_id);

create table ifs_reference_data.pending_table
(
    id            int auto_increment
        primary key,
    ask_date      datetime     null comment '質問日時',
    asker         varchar(100) null comment '質問者',
    feedback_text text         null comment '要望内容',
    responder     varchar(100) null comment '回答者',
    response_text text         null comment '回答内容',
    response_date datetime     null comment '回答日時'
);

create table plango.personal_todos
(
    id                  int unsigned auto_increment comment 'ID'
        primary key,
    user_id             text     null comment 'ユーザーID',
    title               text     null comment 'タイトル',
    description         text     null comment '説明',
    due_date            date     null comment '期限日',
    priority            int      null comment '優先度',
    status              text     null comment '状態',
    progress            int      null comment '進捗率',
    attachment          text     null comment '添付ファイル',
    attachment_filename text     null comment '添付ファイルfilename',
    created_at          datetime null comment '作成日時',
    updated_at          datetime null comment '更新日時',
    completed_at        datetime null comment '完了日時'
)
    comment '個人TODO管理';

create table plango.plm_documents
(
    id             bigint unsigned auto_increment
        primary key,
    project_id     varchar(50)                        not null,
    sub_project_id varchar(50)                        null,
    recid          varchar(100)                       not null,
    parent_class   varchar(100)                       not null,
    class_name     varchar(100)                       null,
    record_name    varchar(255)                       null,
    file_name      varchar(255)                       not null,
    stored_path    text                               not null,
    mime_type      varchar(100)                       null,
    file_size      bigint                             null,
    downloaded_at  datetime default CURRENT_TIMESTAMP not null,
    downloaded_by  varchar(32)                        null,
    constraint uq_plm_doc_proj_sub_fname
        unique (project_id, sub_project_id, file_name(191))
);

create index idx_plm_doc_proj_sub
    on plango.plm_documents (project_id, sub_project_id);

create table ifs_reference_data.process_kind_table
(
    process_kind_id      int         not null comment '工程区分ID'
        primary key,
    process_kind_name    char(50)    null comment '工程区分名',
    process_kind_name_en varchar(50) null comment '工程名称の英語名'
)
    comment '工程区分定義テーブル';

create table ifs_reference_data.production_process_table
(
    unique_project_id        char(20) not null
        primary key,
    process_kind_id          int      null,
    start_date               datetime null,
    end_date                 datetime null,
    plan_man_hours           int      null,
    actual_man_hours         int      null,
    incoming_inspection_date datetime null,
    shipment_date            datetime null,
    inspection_meeting_date  datetime null
);

create table ifs_reference_data.project_assign_table
(
    id                int auto_increment
        primary key,
    unique_project_id char(20)   null comment 'プロジェクトID＋サブプロジェクトID',
    jrc_user_code     char(20)   null comment '個人コード',
    inspection_ready  tinyint(1) null comment '検査可能判定'
);

create table plango.project_chat_messages
(
    id                 int unsigned auto_increment comment 'ID'
        primary key,
    project_id         varchar(255)                         not null comment 'プロジェクトID',
    sub_project_id     varchar(255)                         null comment 'サブプロジェクトID',
    sender_employee_id varchar(32)                          not null comment '送信者従業員ID',
    sender_name        varchar(255)                         not null comment '送信者名',
    message            text                                 not null comment 'メッセージ',
    created_at         datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at         datetime                             null comment '更新日時',
    updated_by         varchar(255)                         null comment '更新者',
    is_deleted         tinyint(1) default 0                 not null comment '削除フラグ',
    deleted_at         datetime                             null comment '削除日時',
    deleted_by         varchar(255)                         null comment '削除者'
)
    comment 'プロジェクトチャットメッセージ管理';

create index idx_project_chat_project
    on plango.project_chat_messages (project_id, sub_project_id, created_at);

create index idx_project_chat_sender
    on plango.project_chat_messages (sender_employee_id, created_at);

create table ifs_reference_data.project_full_merged_tmp
(
    unique_project_id                         varchar(20)    null comment 'ユニークプロジェクトID',
    project_id                                longtext       not null,
    sub_project_id                            longtext       null,
    sub_project_name                          longtext       null,
    department                                longtext       null,
    parent_sub_project_id                     longtext       null,
    variety                                   longtext       null,
    sub_project_amount                        longtext       null,
    sub_project_cost                          longtext       null,
    completion_request_date                   longtext       null,
    completion_request                        longtext       null,
    status                                    longtext       null,
    variety_name                              longtext       null,
    project_name                              longtext       null,
    accounting_completed                      longtext       null,
    completion_date                           longtext       null,
    initial_completion_date                   longtext       null,
    inspection_preparation_start_date         longtext       null,
    inspection_preparation_end_date           longtext       null,
    inspection_start_date                     longtext       null,
    inspection_end_date                       longtext       null,
    inspection_meeting_preparation_start_date longtext       null,
    inspection_meeting_preparation_end_date   longtext       null,
    inspection_meeting_start_date             longtext       null,
    inspection_meeting_end_date               longtext       null,
    shipping_preparation_start_date           longtext       null,
    shipping_preparation_end_date             longtext       null,
    shipping_start_date                       longtext       null,
    shipping_end_date                         longtext       null,
    client_name                               longtext       null,
    contract_deadline                         longtext       null,
    shipping_approval_date                    longtext       null,
    progress                                  longtext       null,
    area_used                                 longtext       null,
    deployment_location                       longtext       null,
    business_trip_start_date                  longtext       null,
    business_trip_end_date                    longtext       null,
    technical_manager                         longtext       null,
    admin_manager                             longtext       null,
    person_in_charge                          longtext       null,
    worker                                    longtext       null,
    support_staff                             longtext       null,
    case_name                                 longtext       null,
    man_hours                                 longtext       null,
    used_man_hours                            longtext       null,
    comment                                   longtext       null,
    components_list_date                      longtext       null,
    drawing_release_date                      longtext       null,
    inspection_guideline_date                 longtext       null,
    dr_date                                   longtext       null,
    dve_date                                  longtext       null,
    incoming_inspection_date                  longtext       null,
    inspection_meeting_date                   longtext       null,
    dva_date                                  longtext       null,
    ship_date                                 longtext       null,
    completion_documents_date                 longtext       null,
    years                                     longtext       null,
    jrc_user_code                             longtext       null,
    inspection_ready                          longtext       null,
    complete                                  longtext       null,
    se_comment                                longtext       null,
    ig_comment                                longtext       null,
    partial_ship_date_1                       longtext       null,
    partial_ship_date_2                       longtext       null,
    partial_ship_date_3                       longtext       null,
    partial_ship_date_4                       longtext       null,
    partial_ship_date_5                       longtext       null,
    partial_ship_date_6                       longtext       null,
    partial_ship_date_7                       longtext       null,
    partial_ship_date_8                       longtext       null,
    partial_ship_date_9                       longtext       null,
    responsible                               varchar(50)    null,
    sum_man_hours                             decimal(47, 4) null
);

create table plango.project_ifs_items
(
    id                          bigint unsigned auto_increment comment 'ID'
        primary key,
    project_id                  varchar(20)                         not null comment 'プロジェクトID',
    sub_project_id              varchar(20)                         null comment 'サブプロジェクトID',
    site                        varchar(50)                         null comment 'site',
    row_no                      varchar(50)                         not null comment '行番号',
    item_code                   varchar(100)                        null comment '品目コード',
    item_name                   varchar(255)                        null comment '品名',
    requested_date              date                                null comment 'requested日',
    requested_qty               decimal(18, 4)                      null comment 'requestedqty',
    order_method                varchar(50)                         null comment '手配method',
    order_progress              varchar(50)                         null comment '手配progress',
    status                      varchar(50)                         null comment '状態',
    supply_option               varchar(50)                         null comment 'supplyoption',
    standard_item               varchar(100)                        null comment 'standard品目',
    model_name                  varchar(255)                        null comment '型名',
    serial_no                   varchar(100)                        null comment '製造番号',
    assembly_sign               varchar(50)                         null comment 'assemblysign',
    power_name                  varchar(255)                        null comment 'power名',
    paint_color                 varchar(255)                        null comment 'paintcolor',
    instruction_sign_name       varchar(255)                        null comment 'instructionsign名',
    destination                 varchar(255)                        null comment 'destination',
    destination_name            varchar(255)                        null comment 'destination名',
    shipping_item_sign          varchar(50)                         null comment '出荷品目sign',
    previous_send_sign_name     varchar(255)                        null comment 'previoussendsign名',
    instruction                 text                                null comment '指示内容',
    shipping_flag               varchar(10)                         null comment '出荷flag',
    expense_type                varchar(50)                         null comment 'expense種別',
    planned_cost                decimal(18, 4)                      null comment 'planned費用',
    supplier_code               varchar(50)                         null comment '仕入先コード',
    supplier_name               varchar(255)                        null comment '仕入先名',
    supplier_planned_unit_price decimal(18, 4)                      null comment 'supplierplannedunitprice',
    order_date                  date                                null comment '手配日',
    ordered_qty                 decimal(18, 4)                      null comment 'orderedqty',
    allocated_qty               decimal(18, 4)                      null comment 'allocatedqty',
    received_date               date                                null comment 'received日',
    received_qty                decimal(18, 4)                      null comment 'receivedqty',
    issued_date                 date                                null comment 'issued日',
    issued_qty                  decimal(18, 4)                      null comment 'issuedqty',
    issue_instruction_date      date                                null comment '課題instruction日',
    issue_instruction_qty       decimal(18, 4)                      null comment '課題instructionqty',
    issue_destination           varchar(255)                        null comment '課題destination',
    slip_number                 varchar(100)                        null comment 'slipnumber',
    issue_instruction_reg_date  date                                null comment '課題instructionreg日',
    transport_instruction_date  date                                null comment 'transportinstruction日',
    transport_type              varchar(50)                         null comment 'transport種別',
    transport_instruction_qty   decimal(18, 4)                      null comment 'transportinstructionqty',
    transport_dest_name         varchar(255)                        null comment 'transportdest名',
    export_flag                 varchar(10)                         null comment 'exportflag',
    transport_slip_number       varchar(100)                        null comment 'transportslipnumber',
    transport_reg_date          date                                null comment 'transportreg日',
    shipping_request_count      decimal(18, 4)                      null comment '出荷申請count',
    shipping_request_qty        decimal(18, 4)                      null comment '出荷申請qty',
    shipping_instruction_qty    decimal(18, 4)                      null comment '出荷instructionqty',
    shipping_status             varchar(50)                         null comment '出荷状態',
    shipping_date               date                                null comment '出荷日',
    shipped_qty                 decimal(18, 4)                      null comment 'shippedqty',
    shipping_base               varchar(50)                         null comment '出荷base',
    shipping_info_id            varchar(100)                        null comment '出荷お知らせID',
    arrival_request_date        date                                null comment 'arrival申請日',
    has_extra_instruction       varchar(10)                         null comment 'hasextrainstruction',
    purchase_request_number     varchar(100)                        null comment 'purchase申請number',
    purchase_order_number       varchar(100)                        null comment 'purchase手配number',
    manufacturing_order_number  varchar(100)                        null comment 'manufacturing手配number',
    product_serial_id           varchar(100)                        null comment 'productserialID',
    created_at_ifs              date                                null comment 'createdatIFS',
    created_by_ifs              varchar(100)                        null comment 'createdbyIFS',
    updated_at_ifs              date                                null comment 'updatedatIFS',
    updated_by_ifs              varchar(100)                        null comment 'updatedbyIFS',
    model_type                  varchar(255)                        null comment 'model種別',
    created_at                  timestamp default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at                  timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint uq_project_ifs
        unique (project_id, sub_project_id, row_no)
)
    comment 'IFSプロジェクト品目';

create index idx_project_ifs_project
    on plango.project_ifs_items (project_id, sub_project_id);

create table plango.project_manage_table
(
    unique_project_id        varchar(20)  not null comment 'ユニークプロジェクトID'
        primary key,
    client_name              varchar(255) null comment '顧客名',
    contract_deadline        date         null comment 'contractdeadline',
    shipping_approval_date   date         null comment '出荷approval日',
    progress                 int          null comment '進捗率',
    area_used                float        null comment 'エリアused',
    deployment_location      varchar(255) null comment 'deployment場所',
    business_trip_start_date date         null comment '業務tripstart日',
    business_trip_end_date   date         null comment '業務tripend日',
    technical_manager        varchar(255) null comment 'technicalmanager',
    admin_manager            varchar(255) null comment 'adminmanager',
    person_in_charge         varchar(255) null comment '担当者',
    worker                   varchar(255) null comment 'worker',
    support_staff            varchar(255) null comment 'supportstaff',
    case_name                varchar(255) null comment '案件名',
    source_inspection        tinyint(1)   null comment 'source検査',
    equipment_configuration  text         null comment '設備configuration',
    resource_registration    tinyint(1)   null comment 'resourceregistration',
    cost_thousand_yen        int          null comment '費用thousandyen',
    man_hours                int          null comment 'man時間',
    used_man_hours           float        null comment 'usedman時間',
    comment                  text         null comment 'comment'
)
    comment 'プロジェクト管理';

create table project_hub.project_manage_table
(
    unique_project_id        text null,
    client_name              text null,
    contract_deadline        text null,
    shipping_approval_date   text null,
    progress                 text null,
    area_used                text null,
    deployment_location      text null,
    business_trip_start_date text null,
    business_trip_end_date   text null,
    technical_manager        text null,
    admin_manager            text null,
    person_in_charge         text null,
    worker                   text null,
    support_staff            text null,
    case_name                text null,
    source_inspection        text null,
    equipment_configuration  text null,
    resource_registration    text null,
    cost_thousand_yen        text null,
    man_hours                text null,
    used_man_hours           text null,
    comment                  text null
);

create table plango.project_management
(
    id                         int unsigned auto_increment
        primary key,
    unique_project_id          varchar(20) as (concat(`project_id`, _utf8mb4'-', `sub_project_id`)) stored,
    project_id                 text         null,
    sub_project_id             text         null,
    sub3_id                    varchar(3)   null,
    order_number               text         null,
    client_name                text         null,
    project_title              text         null,
    contract_deadline          date         null,
    inspection_date            date         null,
    inspection_completion_date date         null,
    shipping_approval_date     date         null,
    witness_date               date         null,
    shipping_date              date         null,
    progress                   int          null,
    area_used                  double       null,
    deployment_location        text         null,
    business_trip_period       text         null,
    technical_manager          text         null,
    admin_manager              text         null,
    person_in_charge           text         null,
    worker                     text         null,
    support_staff              text         null,
    case_name                  text         null,
    source_inspection          tinyint(1)   null,
    witness_inspection         tinyint(1)   null,
    equipment_configuration    text         null,
    resource_registration      text         null,
    cost_thousand_yen          int          null,
    man_hours                  double       null,
    used_man_hours             double       null,
    comment                    text         null,
    created_at                 datetime     null,
    updated_at                 datetime     null,
    preparation_for_inspection text         null,
    preparation_for_attendance text         null,
    preparation_for_shipment   text         null,
    updated_by                 text         null,
    shipping_handover_date     date         null,
    witness_start_date1        date         null,
    witness_end_date1          date         null,
    witness_start_date2        date         null,
    witness_end_date2          date         null,
    witness_start_date3        date         null,
    witness_end_date3          date         null,
    witness_start_date4        date         null,
    witness_end_date4          date         null,
    witness_start_date5        date         null,
    witness_end_date5          date         null,
    business_trip_start_date   date         null,
    business_trip_end_date     date         null,
    acceptance_date            date         null,
    spec_issue_date            date         null,
    sales_manager              text         null,
    electric_manager           text         null,
    mechanical_manager         text         null,
    production_manager         text         null,
    logistics_manager          text         null,
    manufacturing_manager      text         null,
    quality_manager            text         null,
    equipment_tech_manager     text         null,
    jrcls_manager              text         null,
    customer_manager           text         null,
    owner_group_name           varchar(255) null
);

create table project_hub.project_management
(
    unique_project_id        text null,
    client_name              text null,
    contract_deadline        text null,
    shipping_approval_date   text null,
    progress                 text null,
    area_used                text null,
    deployment_location      text null,
    business_trip_start_date text null,
    business_trip_end_date   text null,
    technical_manager        text null,
    admin_manager            text null,
    person_in_charge         text null,
    worker                   text null,
    support_staff            text null,
    case_name                text null,
    man_hours                text null,
    used_man_hours           text null,
    comment                  text null,
    created_at               text null,
    updated_at               text null
);

create index idx_project_management_owner_group
    on plango.project_management (owner_group_name);

create index idx_project_management_sub3_id
    on plango.project_management (sub3_id);

create table plango.project_order_components
(
    id                    int auto_increment comment 'ID'
        primary key,
    project_id            varchar(255)                        not null comment 'プロジェクトID',
    sub_project_id        varchar(255)                        not null comment 'サブプロジェクトID',
    order_number          varchar(255)                        not null comment '手配番号',
    order_row_no          varchar(50)                         null comment '手配行番号',
    contract_detail_no    varchar(50)                         null comment '契約明細番号',
    contract_type         varchar(50)                         null comment 'contract種別',
    new_case_status       varchar(50)                         null comment 'newcase状態',
    ifs_status            varchar(50)                         null comment 'IFS状態',
    shipping_status       varchar(50)                         null comment '出荷状態',
    is_completed          tinyint(1)                          null comment '完了フラグ',
    tehai_name            varchar(255)                        null comment 'tehai名',
    model_name            varchar(255)                        null comment '型名',
    dept_code             varchar(50)                         null comment 'deptコード',
    item_type_code        varchar(50)                         null comment '品目種別コード',
    component_row_no      varchar(50)                         null comment '構成品行no',
    component_type        varchar(50)                         null comment '構成品種別',
    on_hold               tinyint(1)                          null comment 'onhold',
    is_cancelled          tinyint(1)                          null comment 'cancelledフラグ',
    requested_date        date                                null comment 'requested日',
    stock_code            varchar(100)                        null comment 'stockコード',
    item_name             varchar(255)                        null comment '品名',
    expense_type          varchar(50)                         null comment 'expense種別',
    prev_quantity         decimal(18, 4)                      null comment 'prevquantity',
    quantity              decimal(18, 4)                      null comment '数量',
    unit_price            decimal(18, 5)                      null comment '単価',
    planned_material_cost decimal(18, 5)                      null comment 'plannedmaterial費用',
    actual_material_cost  decimal(18, 5)                      null comment 'actualmaterial費用',
    supplier_code         varchar(100)                        null comment '仕入先コード',
    supplier_name         varchar(255)                        null comment '仕入先名',
    instruction           text                                null comment '指示内容',
    contract_row_no       varchar(50)                         null comment 'contract行no',
    document_no           varchar(255)                        null comment '文書番号',
    construction_code     varchar(255)                        null comment 'constructionコード',
    created_at            timestamp default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at            timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    inspection_date       date                                null comment '検査日',
    inspector_id          varchar(50)                         null comment '検査者ID',
    inspector_name        varchar(255)                        null comment '検査者名',
    shipment_date         date                                null comment '出荷日',
    shipper_id            varchar(50)                         null comment '出荷者ID',
    shipper_name          varchar(255)                        null comment '出荷者名',
    remark                text                                null comment '備考',
    inspection_packages   int                                 null comment '検査packages',
    appearance_check      varchar(10)                         null comment 'appearancecheck',
    care_mark             varchar(10)                         null comment 'caremark',
    receiver_id           varchar(20)                         null comment 'receiverID',
    receiver_name         varchar(100)                        null comment 'receiver名',
    last_updated_at       timestamp                           null comment '最終更新日時',
    last_updated_by       varchar(50)                         null comment '最終更新者',
    last_updated_by_name  varchar(100)                        null comment 'lastupdatedby名',
    constraint uq_pm_order_component
        unique (project_id, sub_project_id, contract_detail_no, component_row_no)
)
    comment 'プロジェクト手配構成品';

create table plango.inspection_photos
(
    id                 int auto_increment comment 'ID'
        primary key,
    component_id       int                                null comment '構成品ID',
    filename           varchar(255)                       not null comment 'ファイル名',
    original_name      varchar(255)                       not null comment '元ファイル名',
    mime_type          varchar(100)                       not null comment 'MIME種別',
    file_size          int                                not null comment 'ファイルサイズ',
    created_at         datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    created_by         varchar(50)                        null comment '作成者',
    ifs_project_id     varchar(50)                        null comment 'IFSプロジェクトID',
    ifs_sub_project_id varchar(50)                        null comment 'IFSsubプロジェクトID',
    ifs_row_no         varchar(50)                        null comment 'IFS行no',
    constraint fk_inspection_photos_component
        foreign key (component_id) references plango.project_order_components (id)
            on delete cascade
)
    comment '検査写真管理';

create index idx_dept
    on plango.project_order_components (dept_code);

create index idx_order_number
    on plango.project_order_components (order_number);

create index idx_poc_proj_sub_component
    on plango.project_order_components (project_id, sub_project_id, component_row_no);

create index idx_poc_proj_sub_contract_component
    on plango.project_order_components (project_id, sub_project_id, contract_detail_no, component_row_no);

create index idx_project
    on plango.project_order_components (project_id, sub_project_id);

create table plango.projects
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    page_id    int  null comment 'ページID',
    start_date date null comment '開始日',
    end_date   date null comment '終了日'
)
    comment 'プロジェクト管理';

create table project_hub.qa
(
    id            text null,
    question      text null,
    answer        text null,
    created_at    text null,
    answered_at   text null,
    questioner_id text null,
    answerer_id   text null
);

create table plango.qa
(
    id            int auto_increment comment 'ID'
        primary key,
    question      text                                not null comment '質問',
    answer        text                                null comment '回答',
    created_at    timestamp default CURRENT_TIMESTAMP null comment '作成日時',
    answered_at   timestamp                           null comment '回答日時',
    questioner_id varchar(255)                        not null comment '質問者ID',
    answerer_id   varchar(255)                        null comment '回答者ID',
    topic_id      int                                 null
)
    comment 'Q&A管理';

create table plango.qa_attachments
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    qa_id       int                                 null comment 'Q&AID',
    file_name   text                                null comment 'ファイル名',
    file_path   text                                null comment 'ファイルパス',
    file_type   text                                null comment 'ファイル種別',
    file_size   int                                 null comment 'ファイルサイズ',
    uploaded_at timestamp default CURRENT_TIMESTAMP not null comment 'アップロード日時'
)
    comment 'Q&A添付ファイル';

create table plango.qa_topics
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    title      text     null comment 'タイトル',
    category1  text     null comment 'category1',
    category2  text     null comment 'category2',
    creator_id text     null comment 'creatorID',
    created_at datetime null comment '作成日時'
)
    comment 'Q&Aトピック管理';

create table ifs_reference_data.reference_number_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20)              null,
    reference_number  varchar(50)              null,
    about_text        varchar(255)             null,
    project_name      varchar(255)             null,
    add_date          datetime default (now()) null on update CURRENT_TIMESTAMP,
    jrc_user_name     varchar(20)              null,
    jrc_user_code     varchar(20)              null
)
    comment '管理番号・整理番号テーブル';

create table ifs_reference_data.required_drawing_types_table
(
    id                   int auto_increment
        primary key,
    sub_project_type     varchar(10) null comment 'サブプロジェクト種別',
    required_drawing_ids varchar(30) null comment '図面種別ID'
)
    comment '各サブプロジェクト種別ごとに必須な図面種別設定テーブル';

create table ifs_reference_data.shipment_authorization_history_table
(
    id                int auto_increment
        primary key,
    unique_project_id varchar(20)  null,
    filename          varchar(200) null,
    number_of_files   int          null,
    revision          varchar(10)  null,
    added_date        datetime     null,
    comment           text         null
)
    comment '出荷承認依頼履歴テーブル';

create table plango.shipping_master
(
    id                    int auto_increment comment 'ID'
        primary key,
    print_flag            tinyint(1) default 1                 not null comment '印刷フラグ',
    jrc_logo_flag         tinyint(1) default 0                 not null comment 'jrclogoflag',
    project_id            varchar(255)                         not null comment 'プロジェクトID',
    sub_project_id        varchar(255)                         null comment 'サブプロジェクトID',
    tag_no                varchar(255)                         not null comment 'タグ番号',
    display_order         int                                  null comment '表示順',
    case_no               varchar(255)                         null comment 'caseno',
    customer              varchar(255)                         null comment 'customer',
    product_name          varchar(255)                         null comment 'product名',
    ship_to               varchar(255)                         null comment '出荷to',
    description_1         varchar(255)                         null comment 'description1',
    description_2         varchar(255)                         null comment 'description2',
    model_name            varchar(255)                         null comment '型名',
    remarks               text                                 null comment '備考',
    serial_no             varchar(255)                         null comment '製造番号',
    unique_no             varchar(255)                         null comment 'uniqueno',
    quantity              int                                  null comment '数量',
    split_no              int                                  null comment 'splitno',
    divides_by            int                                  null comment 'divides者',
    workplace_name        varchar(255)                         null comment 'workplace名',
    shipping_label        varchar(255)                         null comment '出荷ラベル',
    qr_data               varchar(1024)                        null comment 'QRデータ',
    factory_worker_at     datetime                             null comment 'factoryworker日時',
    factory_worker_id     varchar(255)                         null comment 'factoryworkerID',
    factory_worker_name   varchar(255)                         null comment 'factoryworker名',
    factory_manager_at    datetime                             null comment 'factorymanager日時',
    factory_manager_id    varchar(255)                         null comment 'factorymanagerID',
    factory_manager_name  varchar(255)                         null comment 'factorymanager名',
    logistics_at          datetime                             null comment 'logistics日時',
    logistics_id          varchar(255)                         null comment 'logisticsID',
    logistics_name        varchar(255)                         null comment 'logistics名',
    site_at               datetime                             null comment 'site日時',
    site_id               varchar(255)                         null comment 'siteID',
    site_name             varchar(255)                         null comment 'site名',
    label_printed_at      datetime                             null comment 'ラベルprinted日時',
    label_printed_by_id   varchar(255)                         null comment 'ラベルprintedbyID',
    label_printed_by_name varchar(255)                         null comment 'ラベルprintedby名',
    label_print_count     int        default 0                 not null comment 'ラベル印刷回数',
    component_id          int                                  null comment '構成品ID',
    component_row_no      varchar(255)                         null comment '構成品行no',
    created_at            timestamp  default CURRENT_TIMESTAMP null comment '作成日時',
    updated_at            timestamp  default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint uq_shipping_master_component
        unique (component_id),
    constraint uq_shipping_master_tag
        unique (project_id, sub_project_id, tag_no)
)
    comment '出荷マスタ';

create table plango.skill_business_types
(
    id            int auto_increment comment 'ID'
        primary key,
    name          varchar(255)  not null comment '名称',
    description   text          null comment '説明',
    display_order int default 0 null comment '表示順',
    job_type_id   int           null comment '職種ID',
    constraint name
        unique (name),
    constraint fk_sbt_job_type
        foreign key (job_type_id) references plango.job_types (id)
)
    comment 'スキル業務種別管理';

create table plango.skill_evaluation_levels
(
    id            int auto_increment comment 'ID'
        primary key,
    level_code    varchar(10)   not null comment 'レベルコード',
    label         varchar(255)  not null comment 'ラベル',
    description   text          null comment '説明',
    display_order int default 0 null comment '表示順',
    constraint level_code
        unique (level_code)
)
    comment 'スキル評価レベル管理';

create table plango.skills
(
    id                        int auto_increment comment 'ID'
        primary key,
    group_name                varchar(255)  not null comment 'グループ名',
    skill_code                varchar(50)   null comment 'スキルコード',
    name                      varchar(255)  not null comment '名称',
    description               text          null comment '説明',
    business_type_id          int           null comment '業務種別ID',
    default_required_level_id int           null comment 'defaultrequiredレベルID',
    display_order             int default 0 null comment '表示順',
    job_type_id               int           null comment '職種ID',
    constraint fk_skills_business_type
        foreign key (business_type_id) references plango.skill_business_types (id),
    constraint fk_skills_job_type
        foreign key (job_type_id) references plango.job_types (id),
    constraint fk_skills_required_level
        foreign key (default_required_level_id) references plango.skill_evaluation_levels (id)
)
    comment 'スキル管理';

create table plango.solution_portal_categories
(
    id          int auto_increment comment 'ID'
        primary key,
    name        varchar(255)                         not null comment '名称',
    description text                                 null comment '説明',
    sort_order  int        default 0                 not null comment '並び順',
    is_active   tinyint(1) default 1                 not null comment '有効フラグ',
    created_at  timestamp  default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at  timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment 'ソリューションポータルカテゴリ管理';

create table plango.solution_portal_links
(
    id              int auto_increment comment 'ID'
        primary key,
    category_id     int                                  not null comment 'カテゴリID',
    title           varchar(255)                         not null comment 'タイトル',
    url             text                                 not null comment 'url',
    description     text                                 null comment '説明',
    icon_type       varchar(50)                          not null comment 'icon種別',
    open_in_new_tab tinyint(1) default 1                 not null comment 'openinnewtab',
    visible_role    varchar(50)                          null comment '表示対象ロール',
    sort_order      int        default 0                 not null comment '並び順',
    is_active       tinyint(1) default 1                 not null comment '有効フラグ',
    created_at      timestamp  default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at      timestamp  default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    click_count     int        default 0                 not null comment 'クリック回数',
    constraint fk_solution_portal_links_category
        foreign key (category_id) references plango.solution_portal_categories (id)
            on update cascade
)
    comment 'ソリューションポータルリンク管理';

create table plango.solution_portal_stats
(
    page_name  varchar(100)  not null comment 'ページ名'
        primary key,
    view_count int default 0 not null comment '閲覧回数'
)
    comment 'ソリューションポータル統計管理';

create table ifs_reference_data.status_kind_table
(
    status_id   int      not null comment '汎用ステータスID'
        primary key,
    status_name char(50) null comment 'ステータス名称'
)
    comment '汎用状態定義テーブル';

create table plango.sub3_group_access
(
    id         int auto_increment comment 'ID'
        primary key,
    sub3_id    varchar(3)   not null comment 'サブ3ID',
    group_name varchar(255) not null comment 'グループ名',
    constraint uq_sub3_group
        unique (sub3_id, group_name)
)
    comment 'サブ3グループアクセス管理';

create index idx_sub3_group_access_group_name
    on plango.sub3_group_access (group_name);

create index idx_sub3_group_access_sub3_id
    on plango.sub3_group_access (sub3_id);

create table plango.sub3_master
(
    sub3_id     varchar(3)                           not null comment 'サブ3ID'
        primary key,
    name        varchar(100)                         not null comment '名称',
    description text                                 null comment '説明',
    active      tinyint(1) default 1                 not null comment '有効フラグ',
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment 'サブ3マスタ';

create table project_hub.subproject_bind
(
    id           int  null,
    jrc_group_id int  null,
    variety      text null
);

create table plango.subproject_bind
(
    id           int auto_increment comment 'ID'
        primary key,
    jrc_group_id int         not null comment 'グループID',
    variety      varchar(10) not null comment 'サブプロジェクト種別',
    constraint subproject_bind_group_kind_table_jrc_group_id_fk
        foreign key (jrc_group_id) references ifs_reference_data.group_kind_table (jrc_group_id)
)
    comment 'サブプロジェクト紐付け管理';

create table plango.system_assignments
(
    id             int unsigned auto_increment comment 'ID'
        primary key,
    system_id      int          null comment 'システムID',
    group_name     varchar(255) null comment 'グループ名',
    role_id        int          null comment 'ロールID',
    employee_id    text         null comment '従業員ID',
    effective_from date         null comment '適用開始日',
    effective_to   date         null comment '適用終了日',
    note           text         null comment '備考',
    created_at     datetime     null comment '作成日時',
    updated_at     datetime     null comment '更新日時',
    version_id     int          null comment 'バージョンID'
)
    comment 'システム割当管理';

create table plango.system_groups
(
    id               int unsigned auto_increment comment 'ID'
        primary key,
    name             text         null comment '名称',
    owner_group_name varchar(255) null comment '所有グループ名',
    description      text         null comment '説明',
    display_order    int          null comment '表示順',
    is_active        tinyint(1)   null comment '有効フラグ',
    created_at       datetime     null comment '作成日時',
    updated_at       datetime     null comment '更新日時'
)
    comment 'システムグループ管理';

create table plango.system_manual_document_versions
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    document_id   int                  null comment '文書ID',
    version_no    int                  null comment '版番号',
    version_label text                 null comment '版ラベル',
    change_log    text                 null comment '変更履歴',
    file_path     text                 null comment 'ファイルパス',
    file_name     text                 null comment 'ファイル名',
    mime_type     text                 null comment 'MIME種別',
    file_size     int                  null comment 'ファイルサイズ',
    uploaded_by   text                 null comment 'アップロード者',
    uploaded_at   datetime             null comment 'アップロード日時',
    is_deleted    tinyint(1) default 0 not null comment '削除フラグ'
)
    comment 'システムマニュアル文書版管理';

create table plango.system_manual_documents
(
    id          int unsigned auto_increment comment 'ID'
        primary key,
    title       text                                 null comment 'タイトル',
    description text                                 null comment '説明',
    category    text                                 null comment 'カテゴリ',
    created_by  text                                 null comment '作成者',
    created_at  datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_by  text                                 null comment '更新者',
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    is_deleted  tinyint(1) default 0                 not null comment '削除フラグ'
)
    comment 'システムマニュアル文書管理';

create table ifs_reference_data.system_processes_table
(
    process_id           int auto_increment comment 'プロセスID'
        primary key,
    process_ip_address   varchar(50) null comment '起動用IPアドレス',
    process_port_number  varchar(50) null comment '起動用ポート番号',
    process_name         varchar(50) null comment 'プロセス名称',
    process_alive_status tinyint(1)  null comment 'プロセス生存状態'
)
    comment '各マイクロサービスの起動情報設定テーブル';

create table plango.system_roles
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    name          text null comment '名称',
    display_order int  null comment '表示順',
    is_active     int  null comment '有効フラグ'
)
    comment 'システムロール管理';

create table plango.system_versions
(
    id         int unsigned auto_increment comment 'ID'
        primary key,
    title      text         null comment 'タイトル',
    group_name varchar(255) null comment 'グループ名',
    year       int          null comment '年',
    base_date  date         null comment 'base日',
    note       text         null comment '備考',
    created_at datetime     null comment '作成日時'
)
    comment 'システム版管理';

create table plango.task_attachments
(
    id              int unsigned auto_increment comment 'ID'
        primary key,
    task_id         int      null comment 'タスクID',
    filename        text     null comment 'ファイル名',
    stored_filename text     null comment '保存ファイル名',
    file_size       int      null comment 'ファイルサイズ',
    file_path       text     null comment 'ファイルパス',
    uploaded_at     datetime null comment 'アップロード日時'
)
    comment 'タスク添付ファイル';

create table plango.task_confirmations
(
    id           int unsigned auto_increment comment 'ID'
        primary key,
    task_id      int        null comment 'タスクID',
    employee_id  text       null comment '従業員ID',
    confirmed    tinyint(1) null comment '確認フラグ',
    confirmed_at datetime   null comment '確認日時'
)
    comment 'タスク確認管理';

create table project_hub.tasks
(
    task_id           int  null,
    unique_project_id text null,
    process_kind_id   int  null,
    task_name         text null,
    task_comment      text null,
    task_status       int  null,
    jrc_user_code     text null,
    dead_line         text null
);

create table plango.tasks
(
    task_id           int  null,
    unique_project_id text null,
    process_kind_id   int  null,
    task_name         text null,
    task_comment      text null,
    task_status       int  null,
    jrc_user_code     text null,
    dead_line         text null
);

create table plango.tasks_
(
    id           int unsigned auto_increment
        primary key,
    title        text       null,
    description  text       null,
    created_at   datetime   null,
    created_by   text       null,
    is_completed tinyint(1) null,
    completed_at datetime   null,
    is_deleted   tinyint(1) null,
    target_group text       null,
    deadline     date       null
);

create table plango.th_devices
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    serial_number text null comment 'serialnumber',
    name          text null comment '名称',
    location      text null comment '場所',
    enabled       int  null comment '有効状態'
)
    comment '温湿度デバイス管理';

create table plango.th_measurements
(
    id            int unsigned auto_increment comment 'ID'
        primary key,
    device_id     int    null comment 'デバイスID',
    timestamp     text   null comment 'タイムスタンプ',
    temperature_c double null comment '温度（℃）',
    humidity_rh   double null comment '湿度（%RH）'
)
    comment '温湿度測定値管理';

create table plango.todo_template_groups
(
    id          int auto_increment comment 'ID'
        primary key,
    name        varchar(255)                         not null comment '名称',
    description text                                 null comment '説明',
    sort_order  int        default 0                 not null comment '並び順',
    is_active   tinyint(1) default 1                 not null comment '有効フラグ',
    created_at  datetime   default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment 'TODOテンプレートグループ管理';

create table plango.todo_templates
(
    id                   int unsigned auto_increment comment 'ID'
        primary key,
    name                 text          null comment '名称',
    group_id             int           null comment 'グループID',
    description          text          null comment '説明',
    default_priority     int           null comment '既定優先度',
    default_department   text          null comment '既定部門',
    applicable_case_name text          null comment '適用案件名',
    sort_order           int default 0 null comment '並び順',
    is_active            tinyint(1)    null comment '有効フラグ',
    created_at           datetime      null comment '作成日時',
    updated_at           datetime      null comment '更新日時',
    constraint fk_todo_templates_group
        foreign key (group_id) references plango.todo_template_groups (id)
            on update cascade on delete set null
)
    comment 'TODOテンプレート管理';

create table plango.todos
(
    id                    int unsigned auto_increment comment 'ID'
        primary key,
    project_id            int                           null comment 'プロジェクトID',
    title                 text                          null comment 'タイトル',
    description           text                          null comment '説明',
    priority              int                           null comment '優先度',
    due_date              date                          null comment '期限日',
    start_date            date                          null comment '開始日',
    progress              int                           null comment '進捗率',
    department            text                          null comment 'department',
    affiliation_category  text                          null comment '所属区分',
    created_at            datetime                      null comment '作成日時',
    updated_at            datetime                      null comment '更新日時',
    created_by            text                          null comment '作成者',
    assigned_to           text                          null comment 'assignedto',
    attachment            text                          null comment '添付ファイル',
    attachment_filename   text                          null comment '添付ファイルfilename',
    template_id           int                           null comment 'テンプレートID',
    status                varchar(20) default 'backlog' not null comment '状態',
    no_deadline_mail      tinyint(1)  default 0         not null comment 'nodeadlineメール',
    deadline_notified_at  datetime                      null comment 'deadlinenotified日時',
    deadline_notify_count int         default 0         not null comment 'deadlinenotifycount',
    cc_assignees_json     text                          null comment 'ccassigneesjson'
)
    comment 'TODO管理';

create index idx_todos_deadline_overdue
    on plango.todos (due_date, progress, no_deadline_mail, deadline_notify_count);

create table plango.travel_costs
(
    id             bigint auto_increment comment 'ID'
        primary key,
    expense_month  varchar(7)                         not null comment '費用計上月',
    project_id     varchar(50)                        not null comment 'プロジェクトID',
    sub_project_id varchar(50)                        not null comment 'サブプロジェクトID',
    amount_yen     bigint                             not null comment '金額（円）',
    created_at     datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at     datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時'
)
    comment '旅費費用管理';

create index idx_travel_month
    on plango.travel_costs (expense_month);

create index idx_travel_pj
    on plango.travel_costs (project_id, sub_project_id);

create table ifs_reference_data.update_history
(
    id             int auto_increment
        primary key,
    process_id     int         not null comment 'プロセスID',
    process_name   varchar(20) null comment 'プロセス名称',
    update_date    datetime    null comment '更新日時',
    update_comment text        null comment '更新コメント'
)
    comment 'システム全体の変更履歴情報（公開用）';

create table plango.update_project_info
(
    id                 int auto_increment comment 'ID'
        primary key,
    unique_project_id  varchar(20)  not null comment 'プロジェクトID＋サブプロジェクトID',
    update_column_name varchar(99)  not null comment '更新対象列名',
    update_value       varchar(999) not null comment '更新値',
    update_date        datetime     not null comment '更新日時',
    update_by          varchar(10)  not null comment '個人コード（更新者）'
)
    comment 'ProjectHub側で入力された更新情報記録テーブル';

create table project_hub.update_project_info
(
    id                 int  null,
    unique_project_id  text null,
    update_column_name text null,
    update_value       text null,
    update_date        text null,
    update_by          text null
);

create table plango.usage_format_templates
(
    id               int auto_increment comment 'ID'
        primary key,
    name             varchar(100)                           not null comment '名称',
    code             varchar(50)                            not null comment 'コード',
    file_type        enum ('excel', 'word')                 not null comment 'ファイル種別',
    language         enum ('ja', 'en')                      not null comment 'language',
    description      text                                   null comment '説明',
    file_path        varchar(255)                           not null comment 'ファイルパス',
    placeholder_type enum ('usage_list', 'instrument_list') not null comment 'プレースホルダ種別',
    active           tinyint(1) default 1                   not null comment '有効フラグ',
    created_at       datetime   default CURRENT_TIMESTAMP   not null comment '作成日時',
    updated_at       datetime   default CURRENT_TIMESTAMP   not null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint idx_usage_format_templates_code
        unique (code)
)
    comment '使用formatテンプレート管理';

create table plango.usage_format_placeholders
(
    id            int auto_increment comment 'ID'
        primary key,
    template_id   int                                not null comment 'テンプレートID',
    placeholder   varchar(100)                       not null comment 'プレースホルダ',
    source_type   enum ('header', 'item', 'static')  not null comment '参照元種別',
    source_column varchar(100)                       null comment '参照元列名',
    note          text                               null comment '備考',
    created_at    datetime default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at    datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint usage_format_placeholders_ibfk_1
        foreign key (template_id) references plango.usage_format_templates (id)
)
    comment '使用formatプレースホルダ管理';

create index template_id
    on plango.usage_format_placeholders (template_id);

create table plango.user_affiliation_histories
(
    id                   bigint auto_increment comment 'ID'
        primary key,
    employee_id          varchar(50)                         not null comment '従業員ID',
    company_name         varchar(255)                        null comment '会社名',
    department_name      varchar(255)                        null comment '部門名',
    business_unit        varchar(255)                        null comment '事業部',
    affiliation_category varchar(255)                        null comment '所属区分',
    group_name           varchar(255)                        null comment 'グループ名',
    group_code           varchar(100)                        null comment 'グループコード',
    department_id        varchar(100)                        null comment '部門ID',
    start_at             datetime                            not null comment '開始日時',
    end_at               datetime                            null comment '終了日時',
    created_at           timestamp default CURRENT_TIMESTAMP null comment '作成日時'
)
    comment 'ユーザー所属履歴';

create index idx_uah_employee_id
    on plango.user_affiliation_histories (employee_id);

create index idx_uah_employee_period
    on plango.user_affiliation_histories (employee_id, start_at);

create index idx_uah_group_code
    on plango.user_affiliation_histories (group_code);

create index idx_uah_group_name
    on plango.user_affiliation_histories (group_name);

create table plango.user_api_tokens
(
    id          int unsigned auto_increment
        primary key,
    employee_id varchar(32)                        not null,
    api_token   varchar(255)                       not null,
    description varchar(255)                       null,
    created_at  datetime default CURRENT_TIMESTAMP not null,
    updated_at  datetime default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    constraint uq_user_token
        unique (employee_id, api_token)
);

create table ifs_reference_data.user_auth_level_table
(
    jrc_user_code varchar(10) not null comment '個人コード'
        primary key,
    system_admin  tinyint(1)  not null comment 'システム管理ユーザー',
    admin         tinyint(1)  null comment '管理ユーザー',
    standard      tinyint(1)  not null comment '標準ユーザー',
    guest         tinyint(1)  not null comment 'ゲストユーザー'
)
    comment 'ユーザー権限設定テーブル';

create table plango.user_job_types
(
    employee_id varchar(32)                          not null comment '従業員ID',
    job_type_id int                                  not null comment '職種ID',
    is_primary  tinyint(1) default 0                 null comment '主担当フラグ',
    created_at  datetime   default CURRENT_TIMESTAMP not null,
    updated_at  datetime   default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    primary key (employee_id, job_type_id)
)
    comment 'ユーザー職種種別管理' collate = utf8mb4_unicode_ci;

create index idx_user_job_types_job_type_id
    on plango.user_job_types (job_type_id);

create table plango.user_requests
(
    id                   bigint unsigned auto_increment comment 'ID'
        primary key,
    employee_id          varchar(32)                           not null comment '従業員ID',
    user_name            varchar(255)                          not null comment 'ユーザー名',
    user_email           varchar(255)                          null comment 'ユーザーメールアドレス',
    company_name         varchar(255)                          null comment '会社名',
    business_unit        varchar(255)                          null comment '事業部',
    department_name      varchar(255)                          null comment '部門名',
    affiliation_category varchar(255)                          null comment '所属区分',
    group_name           varchar(255)                          not null comment 'グループ名',
    comment              text                                  null comment 'comment',
    requester_name       varchar(255)                          not null comment '申請者名',
    requester_email      varchar(255)                          not null comment '申請者メールアドレス',
    status               varchar(20) default 'pending'         not null comment '状態',
    created_at           datetime    default CURRENT_TIMESTAMP not null comment '作成日時',
    updated_at           datetime    default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '更新日時',
    processed_by         varchar(32)                           null comment '処理者',
    processed_at         datetime                              null comment '処理日時',
    reject_reason        text                                  null comment '却下理由'
)
    comment 'ユーザー申請';

create index idx_user_requests_emp
    on plango.user_requests (employee_id);

create index idx_user_requests_status
    on plango.user_requests (status);

create table plango.user_skill_history
(
    id          bigint auto_increment comment 'ID'
        primary key,
    employee_id varchar(20)                                        not null comment '従業員ID',
    skill_id    int                                                not null comment 'スキルID',
    level_id    int                                                null comment 'レベルID',
    changed_by  varchar(20)                                        not null comment '変更者',
    change_type enum ('self', 'manager') default 'self'            not null comment '変更種別',
    changed_at  datetime                 default CURRENT_TIMESTAMP not null comment '変更日時',
    batch_id    bigint                                             null comment 'バッチID'
)
    comment 'ユーザースキル履歴';

create index idx_user_skill_history_batch
    on plango.user_skill_history (batch_id);

create index idx_user_skill_history_emp
    on plango.user_skill_history (employee_id, changed_at);

create index idx_user_skill_history_skill
    on plango.user_skill_history (skill_id, changed_at);

create table plango.user_skill_self_batches
(
    id          bigint auto_increment comment 'ID'
        primary key,
    employee_id varchar(20)                        not null comment '従業員ID',
    saved_at    datetime default CURRENT_TIMESTAMP not null comment '保存日時'
)
    comment 'ユーザースキル自己一括保存管理';

create index idx_user_skill_self_batches_emp
    on plango.user_skill_self_batches (employee_id, saved_at);

create table plango.user_skills
(
    id                   int auto_increment comment 'ID'
        primary key,
    employee_id          varchar(32) not null comment '従業員ID',
    skill_id             int         not null comment 'スキルID',
    self_level_id        int         null comment '自己評価レベルID',
    manager_level_id     int         null comment '管理者評価レベルID',
    self_updated_at      datetime    null comment '自己updated日時',
    manager_updated_at   datetime    null comment 'managerupdated日時',
    manager_evaluator_id varchar(32) null comment '管理者評価者ID',
    comment              text        null comment 'comment',
    constraint uq_user_skill
        unique (employee_id, skill_id)
)
    comment 'ユーザースキル管理';

create index fk_user_skills_manager_level
    on plango.user_skills (manager_level_id);

create index fk_user_skills_self_level
    on plango.user_skills (self_level_id);

create index fk_user_skills_skill
    on plango.user_skills (skill_id);

create table plango.users
(
    employee_id                 varchar(32)          not null comment '従業員ID'
        primary key,
    password                    text                 null comment 'パスワード',
    is_admin                    tinyint(1)           null comment '管理者フラグ',
    name                        text                 null comment '名称',
    group_name                  text                 null comment 'グループ名',
    group_code                  text                 null comment 'グループコード',
    department_id               text                 null comment '部門ID',
    email                       text                 null comment 'メールアドレス',
    role                        text                 null comment 'ロール',
    is_overtime_approver        tinyint(1)           null comment '時間外approverフラグ',
    is_first_login              tinyint(1)           null comment 'firstログインフラグ',
    login_count                 int                  null comment 'ログインcount',
    last_login_at               datetime             null comment '最終ログイン日時',
    is_overtime_viewer          tinyint(1)           null comment '時間外viewerフラグ',
    internal_phone              text                 null comment 'internalphone',
    external_phone              text                 null comment 'externalphone',
    internal_fax                text                 null comment 'internalfax',
    external_fax                text                 null comment 'externalfax',
    internal_mobile             text                 null comment 'internalmobile',
    external_mobile             text                 null comment 'externalmobile',
    company_name                text                 null comment '会社名',
    department_name             text                 null comment '部門名',
    business_unit               text                 null comment '事業部',
    is_duty_manager             tinyint(1)           null comment '当番managerフラグ',
    affiliation_category        text                 null comment '所属区分',
    is_active                   tinyint(1) default 1 not null comment '有効フラグ',
    is_consumables_manager      tinyint(1)           null comment '消耗品managerフラグ',
    is_effort_manager           tinyint(1) default 0 null comment 'effortmanagerフラグ',
    is_skillmap_manager         tinyint(1) default 0 not null comment 'skillmapmanagerフラグ',
    is_qa_manager               tinyint(1) default 0 null comment 'Q&Amanagerフラグ',
    is_notice_manager           tinyint(1) default 0 not null comment '通知managerフラグ',
    is_solution_portal_manager  tinyint(1) default 0 not null comment 'ソリューションポータルmanagerフラグ',
    is_subid_manager            tinyint(1) default 0 not null comment 'subidmanagerフラグ',
    is_rate_manager             tinyint(1) default 0 not null comment '単価managerフラグ',
    is_weekly_report_manager    tinyint(1) default 0 not null comment 'weeklyreportmanagerフラグ',
    is_company_calendar_manager tinyint(1) default 0 not null comment '会社カレンダーmanagerフラグ',
    is_user_manager             tinyint(1) default 0 not null comment 'ユーザーmanagerフラグ',
    is_group_docs_manager       tinyint(1) default 0 not null comment 'グループdocsmanagerフラグ',
    is_manual_docs_manager      tinyint(1) default 0 not null comment 'マニュアルdocsmanagerフラグ',
    is_system_video_manager     tinyint(1) default 0 not null comment 'システム動画managerフラグ'
)
    comment 'ユーザー管理';

create table plango.videos
(
    id             int unsigned auto_increment comment 'ID'
        primary key,
    title          text        null comment 'タイトル',
    description    text        null comment '説明',
    category       text        null comment 'カテゴリ',
    filename       text        null comment 'ファイル名',
    upload_date    datetime    null comment 'アップロード日',
    status         text        null comment '状態',
    created_by     varchar(32) null comment '作成者',
    view_count     int         null comment '閲覧回数',
    last_viewed_at datetime    null comment '最終閲覧日時',
    updated_at     datetime    null comment '更新日時',
    file_deleted   tinyint(1)  null comment 'ファイルdeleted'
)
    comment '動画管理';

create table plango.view_history
(
    id                int unsigned auto_increment comment 'ID'
        primary key,
    user_id           varchar(32) null comment 'ユーザーID',
    video_id          int         null comment '動画ID',
    viewed_at         datetime    null comment '閲覧日時',
    view_duration     int         null comment '閲覧duration',
    completion_status text        null comment '完了状態'
)
    comment '閲覧履歴';

create table plango.witness_result_files
(
    id               bigint auto_increment comment 'ID'
        primary key,
    project_id       varchar(50)                        not null comment 'プロジェクトID',
    sub_project_id   varchar(50)                        null comment 'サブプロジェクトID',
    witness_no       int                                not null comment '立会no',
    file_name_orig   varchar(255)                       not null comment '元ファイル名',
    file_name_saved  varchar(255)                       not null comment '保存ファイル名',
    file_path        varchar(512)                       not null comment 'ファイルパス',
    file_size        bigint                             null comment 'ファイルサイズ',
    content_type     varchar(100)                       null comment 'コンテンツ種別',
    comment          varchar(500)                       null comment 'comment',
    uploaded_at      datetime default CURRENT_TIMESTAMP not null comment 'アップロード日時',
    uploaded_by_name varchar(100)                       null comment 'アップロード者名',
    uploaded_by_emp  varchar(20)                        null comment 'アップロード者社員番号'
)
    comment '立会結果ファイル';

create index idx_wrf_proj_sub
    on plango.witness_result_files (project_id, sub_project_id);

create index idx_wrf_proj_sub_no
    on plango.witness_result_files (project_id, sub_project_id, witness_no);

create table plango.work_hour_rates
(
    id         bigint auto_increment comment 'ID'
        primary key,
    year       int                                 not null comment '年',
    month      tinyint                             not null comment '月',
    group_name varchar(255)                        not null comment 'グループ名',
    rate       decimal(10, 2)                      not null comment '単価',
    note       varchar(255)                        null comment '備考',
    updated_at timestamp default CURRENT_TIMESTAMP null on update CURRENT_TIMESTAMP comment '更新日時',
    constraint uq_work_hour_rates
        unique (year, month),
    constraint uq_work_hour_rates_year_month_group
        unique (year, month, group_name)
)
    comment '作業時間単価管理';

create table ifs_reference_data.work_item_kind_table
(
    id          int auto_increment comment '自動生成の一意のID'
        primary key,
    item_number varchar(10) not null comment '作業種別番号',
    item_name   varchar(50) not null comment '作業種別名'
)
    comment '作業種別マスタ';

create table plango.work_raw_actuals
(
    id              bigint auto_increment comment 'ID'
        primary key,
    status          varchar(20)                         null comment '状態',
    work_date       date                                null comment '作業日',
    employee_no     varchar(20)                         null comment 'employeeno',
    employee_name   varchar(50)                         null comment '従業員名',
    employee_type   varchar(20)                         null comment 'employee種別',
    start_time      varchar(10)                         null comment '開始時刻',
    end_time        varchar(10)                         null comment '終了時刻',
    work_hours      decimal(6, 2)                       null comment '作業時間',
    mf_order        varchar(50)                         null comment 'mf手配',
    order_no        varchar(50)                         null comment '手配no',
    product_name    varchar(100)                        null comment 'product名',
    work_code       varchar(20)                         null comment '作業コード',
    work_name       varchar(100)                        null comment '作業名',
    customer_code   varchar(50)                         null comment 'customerコード',
    customer_name   varchar(100)                        null comment '顧客名',
    manage_type     varchar(50)                         null comment '管理種別',
    remarks         text                                null comment '備考',
    board_name      varchar(100)                        null comment '掲示板名',
    idle_flag       varchar(50)                         null comment 'idleflag',
    support_section varchar(100)                        null comment 'supportsection',
    approver        varchar(50)                         null comment 'approver',
    approve_date    varchar(20)                         null comment '承認日',
    approve_time    varchar(20)                         null comment '承認時刻',
    model_type      varchar(50)                         null comment 'model種別',
    business_type   varchar(50)                         null comment '業務種別',
    created_at      timestamp default CURRENT_TIMESTAMP null comment '作成日時'
)
    comment '作業実績生データ';

create table plango.work_raw_actuals_import_logs
(
    id            bigint unsigned auto_increment comment 'ID'
        primary key,
    file_path     varchar(512)  not null comment 'ファイルパス',
    file_mtime    datetime      not null comment 'ファイル更新日時',
    imported_at   datetime      not null comment '取込日時',
    rows_inserted int default 0 not null comment '登録行数',
    status        varchar(16)   not null comment '状態',
    message       text          null comment 'メッセージ',
    trigger_type  varchar(16)   not null comment '起動種別'
)
    comment '作業生データ実績取込ログ';

create index idx_work_raw_actuals_import_logs_1
    on plango.work_raw_actuals_import_logs (file_path, file_mtime);

create index idx_work_raw_actuals_import_logs_2
    on plango.work_raw_actuals_import_logs (imported_at);

create table ifs_reference_data.work_time_record_table
(
    id                      int auto_increment
        primary key,
    unique_project_id       varchar(20) not null comment 'プロジェクトID＋サブプロジェクトID',
    jrc_user_code           varchar(10) not null comment 'ユーザーコード',
    process_kind_id         int         not null comment '検査準備、検査、立会検査準備、立会、出荷準備、出荷を表すID',
    start_date              datetime    null comment '開始日時',
    end_date                datetime    null comment '終了日時',
    item_number             varchar(10) null comment '工程種別ID（work_item_kind_tableに準ずる）',
    one_time_bind_user_code varchar(20) null comment '担当者以外で一時的に作業を行った人員のユーザーコード'
)
    comment '作業時間記録用テーブル';

create definer = dbuser@`%` view ifs_reference_data.test_view as
select `i`.`unique_project_id`                                                                                     AS `unique_project_id`,
       coalesce(`ifs_reference_data`.`u`.`project_id`, `i`.`project_id`)                                           AS `project_id`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_id`,
                `i`.`sub_project_id`)                                                                              AS `sub_project_id`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_name`,
                `i`.`sub_project_name`)                                                                            AS `sub_project_name`,
       coalesce(`ifs_reference_data`.`u`.`department`, `i`.`department`)                                           AS `department`,
       coalesce(`ifs_reference_data`.`u`.`parent_sub_project_id`,
                `i`.`parent_sub_project_id`)                                                                       AS `parent_sub_project_id`,
       coalesce(`ifs_reference_data`.`u`.`variety`, `i`.`variety`)                                                 AS `variety`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_amount`,
                `i`.`sub_project_amount`)                                                                          AS `sub_project_amount`,
       coalesce(`ifs_reference_data`.`u`.`sub_project_cost`,
                `i`.`sub_project_cost`)                                                                            AS `sub_project_cost`,
       coalesce(`ifs_reference_data`.`u`.`completion_request_date`,
                `i`.`completion_request_date`)                                                                     AS `completion_request_date`,
       coalesce(`ifs_reference_data`.`u`.`completion_request`,
                `i`.`completion_request`)                                                                          AS `completion_request`,
       coalesce(`ifs_reference_data`.`u`.`status`, `i`.`status`)                                                   AS `status`,
       coalesce(`ifs_reference_data`.`u`.`variety_name`,
                `i`.`variety_name`)                                                                                AS `variety_name`,
       coalesce(`ifs_reference_data`.`u`.`project_name`,
                `i`.`project_name`)                                                                                AS `project_name`,
       coalesce(`ifs_reference_data`.`u`.`accounting_completed`,
                `i`.`accounting_completed`)                                                                        AS `accounting_completed`,
       coalesce(`ifs_reference_data`.`u`.`completion_date`,
                `i`.`completion_date`)                                                                             AS `completion_date`,
       coalesce(`ifs_reference_data`.`u`.`initial_completion_date`,
                `i`.`initial_completion_date`)                                                                     AS `initial_completion_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_preparation_start_date`,
                `b`.`inspection_preparation_start_date`)                                                           AS `inspection_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_preparation_end_date`,
                `b`.`inspection_preparation_end_date`)                                                             AS `inspection_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_start_date`,
                `b`.`inspection_start_date`)                                                                       AS `inspection_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_end_date`,
                `b`.`inspection_end_date`)                                                                         AS `inspection_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_preparation_start_date`,
                `b`.`inspection_meeting_preparation_start_date`)                                                   AS `inspection_meeting_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_preparation_end_date`,
                `b`.`inspection_meeting_preparation_end_date`)                                                     AS `inspection_meeting_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_start_date`,
                `b`.`inspection_meeting_start_date`)                                                               AS `inspection_meeting_start_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_end_date`,
                `b`.`inspection_meeting_end_date`)                                                                 AS `inspection_meeting_end_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_preparation_start_date`,
                `b`.`shipping_preparation_start_date`)                                                             AS `shipping_preparation_start_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_preparation_end_date`,
                `b`.`shipping_preparation_end_date`)                                                               AS `shipping_preparation_end_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_start_date`,
                `b`.`shipping_start_date`)                                                                         AS `shipping_start_date`,
       coalesce(`ifs_reference_data`.`u`.`shipping_end_date`,
                `b`.`shipping_end_date`)                                                                           AS `shipping_end_date`,
       coalesce(`ifs_reference_data`.`u`.`client_name`, `p`.`client_name`)                                         AS `client_name`,
       coalesce(`ifs_reference_data`.`u`.`contract_deadline`,
                `p`.`contract_deadline`)                                                                           AS `contract_deadline`,
       coalesce(`ifs_reference_data`.`u`.`shipping_approval_date`,
                `p`.`shipping_approval_date`)                                                                      AS `shipping_approval_date`,
       coalesce(`ifs_reference_data`.`u`.`progress`, `p`.`progress`)                                               AS `progress`,
       coalesce(`ifs_reference_data`.`u`.`area_used`, `p`.`area_used`)                                             AS `area_used`,
       coalesce(`ifs_reference_data`.`u`.`deployment_location`,
                `p`.`deployment_location`)                                                                         AS `deployment_location`,
       coalesce(`ifs_reference_data`.`u`.`business_trip_start_date`,
                `p`.`business_trip_start_date`)                                                                    AS `business_trip_start_date`,
       coalesce(`ifs_reference_data`.`u`.`business_trip_end_date`,
                `p`.`business_trip_end_date`)                                                                      AS `business_trip_end_date`,
       coalesce(`ifs_reference_data`.`u`.`technical_manager`,
                `p`.`technical_manager`)                                                                           AS `technical_manager`,
       coalesce(`ifs_reference_data`.`u`.`admin_manager`,
                `p`.`admin_manager`)                                                                               AS `admin_manager`,
       coalesce(`ifs_reference_data`.`u`.`person_in_charge`,
                `p`.`person_in_charge`)                                                                            AS `person_in_charge`,
       coalesce(`ifs_reference_data`.`u`.`worker`, `p`.`worker`)                                                   AS `worker`,
       coalesce(`ifs_reference_data`.`u`.`support_staff`,
                `p`.`support_staff`)                                                                               AS `support_staff`,
       coalesce(`ifs_reference_data`.`u`.`case_name`, `p`.`case_name`)                                             AS `case_name`,
       coalesce(`ifs_reference_data`.`u`.`man_hours`, `p`.`man_hours`)                                             AS `man_hours`,
       coalesce(`ifs_reference_data`.`u`.`used_man_hours`,
                `p`.`used_man_hours`)                                                                              AS `used_man_hours`,
       coalesce(`ifs_reference_data`.`u`.`comment`, `p`.`comment`)                                                 AS `comment`,
       coalesce(`ifs_reference_data`.`u`.`components_list_date`,
                `d`.`components_list_date`)                                                                        AS `components_list_date`,
       coalesce(`ifs_reference_data`.`u`.`drawing_release_date`,
                `d`.`drawing_release_date`)                                                                        AS `drawing_release_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_guideline_date`,
                `d`.`inspection_guideline_date`)                                                                   AS `inspection_guideline_date`,
       coalesce(`ifs_reference_data`.`u`.`dr_date`, `d`.`dr_date`)                                                 AS `dr_date`,
       coalesce(`ifs_reference_data`.`u`.`dve_date`, `d`.`dve_date`)                                               AS `dve_date`,
       coalesce(`ifs_reference_data`.`u`.`incoming_inspection_date`,
                `d`.`incoming_inspection_date`)                                                                    AS `incoming_inspection_date`,
       coalesce(`ifs_reference_data`.`u`.`inspection_meeting_date`,
                `d`.`inspection_meeting_date`)                                                                     AS `inspection_meeting_date`,
       coalesce(`ifs_reference_data`.`u`.`dva_date`, `d`.`dva_date`)                                               AS `dva_date`,
       coalesce(`ifs_reference_data`.`u`.`ship_date`, `d`.`ship_date`)                                             AS `ship_date`,
       coalesce(`ifs_reference_data`.`u`.`completion_documents_date`,
                `d`.`completion_documents_date`)                                                                   AS `completion_documents_date`,
       coalesce(`ifs_reference_data`.`u`.`years`, `d`.`years`)                                                     AS `years`,
       coalesce(`ifs_reference_data`.`u`.`jrc_user_code`,
                `a`.`jrc_user_code`)                                                                               AS `jrc_user_code`,
       coalesce(`ifs_reference_data`.`u`.`inspection_ready`,
                `a`.`inspection_ready`)                                                                            AS `inspection_ready`,
       coalesce(`ifs_reference_data`.`u`.`complete`, `c`.`complete`)                                               AS `complete`,
       coalesce(`ifs_reference_data`.`u`.`se_comment`,
                `comment`.`se_comment`)                                                                            AS `se_comment`,
       coalesce(`ifs_reference_data`.`u`.`ig_comment`,
                `comment`.`ig_comment`)                                                                            AS `ig_comment`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_1`,
                `partial_ship`.`partial_ship_date_1`)                                                              AS `partial_ship_date_1`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_2`,
                `partial_ship`.`partial_ship_date_2`)                                                              AS `partial_ship_date_2`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_3`,
                `partial_ship`.`partial_ship_date_3`)                                                              AS `partial_ship_date_3`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_4`,
                `partial_ship`.`partial_ship_date_4`)                                                              AS `partial_ship_date_4`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_5`,
                `partial_ship`.`partial_ship_date_5`)                                                              AS `partial_ship_date_5`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_6`,
                `partial_ship`.`partial_ship_date_6`)                                                              AS `partial_ship_date_6`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_7`,
                `partial_ship`.`partial_ship_date_7`)                                                              AS `partial_ship_date_7`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_8`,
                `partial_ship`.`partial_ship_date_8`)                                                              AS `partial_ship_date_8`,
       coalesce(`ifs_reference_data`.`u`.`partial_ship_date_9`,
                `partial_ship`.`partial_ship_date_9`)                                                              AS `partial_ship_date_9`,
       (select `ifs_reference_data`.`jrc_users_table`.`jrc_user_name`
        from `ifs_reference_data`.`jrc_users_table`
        where (`ifs_reference_data`.`jrc_users_table`.`jrc_user_code` =
               `a`.`jrc_user_code`))                                                                               AS `responsible`,
       (select (sum((unix_timestamp(`ifs_reference_data`.`work_time_record_table`.`end_date`) -
                     unix_timestamp(`ifs_reference_data`.`work_time_record_table`.`start_date`))) / 3600)
        from `ifs_reference_data`.`work_time_record_table`
        where (`ifs_reference_data`.`work_time_record_table`.`unique_project_id` =
               `i`.`unique_project_id`))                                                                           AS `sum_man_hours`
from ((((((((`ifs_reference_data`.`ifs_projects_table` `i` left join `ifs_reference_data`.`update_project_latest_view` `u`
             on ((`i`.`unique_project_id` = `ifs_reference_data`.`u`.`unique_project_id`))) left join `ifs_reference_data`.`backlog_task_date_table` `b`
            on ((`i`.`unique_project_id` = `b`.`unique_project_id`))) left join `plango`.`project_management` `p`
           on ((`i`.`unique_project_id` = `p`.`unique_project_id`))) left join `ifs_reference_data`.`design_plan_table` `d`
          on ((`i`.`unique_project_id` = `d`.`unique_project_id`))) left join `ifs_reference_data`.`project_assign_table` `a`
         on ((`i`.`unique_project_id` = `a`.`unique_project_id`))) left join `plango`.`completed_projects` `c`
        on ((`i`.`unique_project_id` = `c`.`unique_project_id`))) left join `plango`.`comments` `comment`
       on ((`i`.`unique_project_id` = `comment`.`unique_project_id`))) left join `plango`.`partial_shipment` `partial_ship`
      on ((`i`.`unique_project_id` = `partial_ship`.`unique_project_id`)))
where (`i`.`status` = '未完了');

-- comment on column ifs_reference_data.test_view.unique_project_id not supported: ユニークプロジェクトID

create definer = dbuser@`%` view ifs_reference_data.update_project_latest_view as
select `upi`.`unique_project_id`                                                                                      AS `unique_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'project_id')
                    then `upi`.`update_value` end))                                                                   AS `project_id`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_id')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_name')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_name`,
       max((case
                when (`upi`.`update_column_name` = 'department')
                    then `upi`.`update_value` end))                                                                   AS `department`,
       max((case
                when (`upi`.`update_column_name` = 'parent_sub_project_id')
                    then `upi`.`update_value` end))                                                                   AS `parent_sub_project_id`,
       max((case
                when (`upi`.`update_column_name` = 'variety')
                    then `upi`.`update_value` end))                                                                   AS `variety`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_amount')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_amount`,
       max((case
                when (`upi`.`update_column_name` = 'sub_project_cost')
                    then `upi`.`update_value` end))                                                                   AS `sub_project_cost`,
       max((case
                when (`upi`.`update_column_name` = 'completion_request_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_request_date`,
       max((case
                when (`upi`.`update_column_name` = 'completion_request')
                    then `upi`.`update_value` end))                                                                   AS `completion_request`,
       max((case
                when (`upi`.`update_column_name` = 'status')
                    then `upi`.`update_value` end))                                                                   AS `status`,
       max((case
                when (`upi`.`update_column_name` = 'variety_name')
                    then `upi`.`update_value` end))                                                                   AS `variety_name`,
       max((case
                when (`upi`.`update_column_name` = 'project_name')
                    then `upi`.`update_value` end))                                                                   AS `project_name`,
       max((case
                when (`upi`.`update_column_name` = 'accounting_completed')
                    then `upi`.`update_value` end))                                                                   AS `accounting_completed`,
       max((case
                when (`upi`.`update_column_name` = 'completion_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_date`,
       max((case
                when (`upi`.`update_column_name` = 'initial_completion_date')
                    then `upi`.`update_value` end))                                                                   AS `initial_completion_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_start_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_end_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_preparation_start_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_preparation_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_preparation_end_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_preparation_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_start_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_end_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'client_name')
                    then `upi`.`update_value` end))                                                                   AS `client_name`,
       max((case
                when (`upi`.`update_column_name` = 'contract_deadline')
                    then `upi`.`update_value` end))                                                                   AS `contract_deadline`,
       max((case
                when (`upi`.`update_column_name` = 'shipping_approval_date')
                    then `upi`.`update_value` end))                                                                   AS `shipping_approval_date`,
       max((case
                when (`upi`.`update_column_name` = 'progress')
                    then `upi`.`update_value` end))                                                                   AS `progress`,
       max((case
                when (`upi`.`update_column_name` = 'area_used')
                    then `upi`.`update_value` end))                                                                   AS `area_used`,
       max((case
                when (`upi`.`update_column_name` = 'deployment_location')
                    then `upi`.`update_value` end))                                                                   AS `deployment_location`,
       max((case
                when (`upi`.`update_column_name` = 'business_trip_start_date')
                    then `upi`.`update_value` end))                                                                   AS `business_trip_start_date`,
       max((case
                when (`upi`.`update_column_name` = 'business_trip_end_date')
                    then `upi`.`update_value` end))                                                                   AS `business_trip_end_date`,
       max((case
                when (`upi`.`update_column_name` = 'technical_manager')
                    then `upi`.`update_value` end))                                                                   AS `technical_manager`,
       max((case
                when (`upi`.`update_column_name` = 'admin_manager')
                    then `upi`.`update_value` end))                                                                   AS `admin_manager`,
       max((case
                when (`upi`.`update_column_name` = 'person_in_charge')
                    then `upi`.`update_value` end))                                                                   AS `person_in_charge`,
       max((case
                when (`upi`.`update_column_name` = 'worker')
                    then `upi`.`update_value` end))                                                                   AS `worker`,
       max((case
                when (`upi`.`update_column_name` = 'support_staff')
                    then `upi`.`update_value` end))                                                                   AS `support_staff`,
       max((case
                when (`upi`.`update_column_name` = 'case_name')
                    then `upi`.`update_value` end))                                                                   AS `case_name`,
       max((case
                when (`upi`.`update_column_name` = 'man_hours')
                    then `upi`.`update_value` end))                                                                   AS `man_hours`,
       max((case
                when (`upi`.`update_column_name` = 'used_man_hours')
                    then `upi`.`update_value` end))                                                                   AS `used_man_hours`,
       max((case
                when (`upi`.`update_column_name` = 'comment')
                    then `upi`.`update_value` end))                                                                   AS `comment`,
       max((case
                when (`upi`.`update_column_name` = 'components_list_date')
                    then `upi`.`update_value` end))                                                                   AS `components_list_date`,
       max((case
                when (`upi`.`update_column_name` = 'drawing_release_date')
                    then `upi`.`update_value` end))                                                                   AS `drawing_release_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_guideline_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_guideline_date`,
       max((case
                when (`upi`.`update_column_name` = 'dr_date')
                    then `upi`.`update_value` end))                                                                   AS `dr_date`,
       max((case
                when (`upi`.`update_column_name` = 'dve_date')
                    then `upi`.`update_value` end))                                                                   AS `dve_date`,
       max((case
                when (`upi`.`update_column_name` = 'incoming_inspection_date')
                    then `upi`.`update_value` end))                                                                   AS `incoming_inspection_date`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_meeting_date')
                    then `upi`.`update_value` end))                                                                   AS `inspection_meeting_date`,
       max((case
                when (`upi`.`update_column_name` = 'dva_date')
                    then `upi`.`update_value` end))                                                                   AS `dva_date`,
       max((case
                when (`upi`.`update_column_name` = 'ship_date')
                    then `upi`.`update_value` end))                                                                   AS `ship_date`,
       max((case
                when (`upi`.`update_column_name` = 'completion_documents_date')
                    then `upi`.`update_value` end))                                                                   AS `completion_documents_date`,
       max((case
                when (`upi`.`update_column_name` = 'years')
                    then `upi`.`update_value` end))                                                                   AS `years`,
       max((case
                when (`upi`.`update_column_name` = 'jrc_user_code')
                    then `upi`.`update_value` end))                                                                   AS `jrc_user_code`,
       max((case
                when (`upi`.`update_column_name` = 'inspection_ready')
                    then `upi`.`update_value` end))                                                                   AS `inspection_ready`,
       max((case
                when (`upi`.`update_column_name` = 'complete')
                    then `upi`.`update_value` end))                                                                   AS `complete`,
       max((case
                when (`upi`.`update_column_name` = 'se_comment')
                    then `upi`.`update_value` end))                                                                   AS `se_comment`,
       max((case
                when (`upi`.`update_column_name` = 'ig_comment')
                    then `upi`.`update_value` end))                                                                   AS `ig_comment`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_1')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_1`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_2')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_2`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_3')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_3`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_4')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_4`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_5')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_5`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_6')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_6`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_7')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_7`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_8')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_8`,
       max((case
                when (`upi`.`update_column_name` = 'partial_ship_date_9')
                    then `upi`.`update_value` end))                                                                   AS `partial_ship_date_9`
from `plango`.`update_project_info` `upi`
where `upi`.`update_date` in (select max(`plango`.`update_project_info`.`update_date`)
                              from `plango`.`update_project_info`
                              where ((`plango`.`update_project_info`.`update_column_name` =
                                      `upi`.`update_column_name`) and
                                     (`plango`.`update_project_info`.`unique_project_id` = `upi`.`unique_project_id`)))
group by `upi`.`unique_project_id`;

-- comment on column ifs_reference_data.update_project_latest_view.unique_project_id not supported: プロジェクトID＋サブプロジェクトID

